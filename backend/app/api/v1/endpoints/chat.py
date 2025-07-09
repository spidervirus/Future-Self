from fastapi import APIRouter, HTTPException, Depends, WebSocket, WebSocketDisconnect, status
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime
import json
import asyncio

from app.database.connection import get_db
from app.core.auth import get_current_user
from app.models.auth import User
from app.models.chat import Conversation, ChatMessage, MessageRole as DBMessageRole
from app.services.ai_context_service import AIContextService
from app.services.ollama_service import OllamaService
from app.schemas.chat import (
    SendMessageRequest,
    MessageResponse,
    ChatResponse,
    ConversationSummary,
    ConversationDetail,
    ConversationListResponse,
    ChatHistoryRequest,
    ChatHistoryResponse,
    ConversationCreate,
    ConversationUpdate,
    ConversationStarter,
    WebSocketMessage,
    WebSocketResponse,
    AIGenerationRequest,
    DailyMessage,
    ErrorResponse
)
from app.core.exceptions import NotFoundError, ValidationError


router = APIRouter()

# Initialize services
ai_context_service = AIContextService()
ollama_service = OllamaService()

# WebSocket connection manager
class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []
        self.user_connections: dict = {}
    
    async def connect(self, websocket: WebSocket, user_id: str):
        await websocket.accept()
        self.active_connections.append(websocket)
        self.user_connections[user_id] = websocket
    
    def disconnect(self, websocket: WebSocket, user_id: str):
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)
        if user_id in self.user_connections:
            del self.user_connections[user_id]
    
    async def send_personal_message(self, message: str, user_id: str):
        if user_id in self.user_connections:
            await self.user_connections[user_id].send_text(message)

manager = ConnectionManager()


@router.post("/send", response_model=ChatResponse)
async def send_message(
    request: SendMessageRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Send a message to the Future Self AI"""
    try:
        # Get or create conversation
        conversation = None
        is_new_conversation = False
        
        if request.conversation_id:
            conversation = db.query(Conversation).filter(
                Conversation.id == request.conversation_id,
                Conversation.user_id == current_user.id
            ).first()
            
            if not conversation:
                raise HTTPException(
                    status_code=404,
                    detail="Conversation not found"
                )
        else:
            # Create new conversation
            conversation = Conversation(
                user_id=current_user.id,
                title=f"Chat started {datetime.utcnow().strftime('%Y-%m-%d %H:%M')}"
            )
            db.add(conversation)
            db.flush()  # Get the ID
            is_new_conversation = True
        
        # Save user message
        user_message = ChatMessage(
            conversation_id=conversation.id,
            role=DBMessageRole.USER,
            content=request.content,
            message_metadata=json.dumps(request.metadata) if request.metadata else None
        )
        db.add(user_message)
        db.flush()
        
        # Get conversation history for context
        recent_messages = db.query(ChatMessage).filter(
            ChatMessage.conversation_id == conversation.id
        ).order_by(ChatMessage.created_at.desc()).limit(10).all()
        
        # Reverse to get chronological order
        recent_messages.reverse()
        
        # Format conversation history for AI
        conversation_history = []
        for msg in recent_messages[:-1]:  # Exclude the just-added user message
            conversation_history.append({
                "role": msg.role.value,
                "content": msg.content
            })
        
        # Generate personalized system prompt
        system_prompt = ai_context_service.generate_system_prompt(db, str(current_user.id))
        
        # Get user context for personalization
        user_context = ai_context_service.generate_conversation_context(
            db, str(current_user.id), [msg["content"] for msg in conversation_history[-3:]]
        )
        
        # Prepare AI generation request
        ai_request = AIGenerationRequest(
            user_message=request.content,
            conversation_history=conversation_history,
            user_context=user_context,
            system_prompt=system_prompt
        )
        
        # Generate AI response
        ai_response = await ollama_service.generate_response(ai_request)
        
        # Save AI message
        ai_message = ChatMessage(
            conversation_id=conversation.id,
            role=DBMessageRole.ASSISTANT,
            content=ai_response.content,
            token_count=str(ai_response.token_count) if ai_response.token_count else None,
            message_metadata=json.dumps(ai_response.metadata) if ai_response.metadata else None
        )
        db.add(ai_message)
        
        # Update conversation title if it's new and we have a good first message
        if is_new_conversation and len(request.content) > 10:
            # Create a simple title from the first message
            title_preview = request.content[:50]
            if len(request.content) > 50:
                title_preview += "..."
            conversation.title = title_preview
        
        db.commit()
        
        # Create response objects
        user_msg_response = MessageResponse(
            id=str(user_message.id),
            conversation_id=str(conversation.id),
            role=user_message.role.value,
            content=user_message.content,
            message_type=request.message_type,
            metadata=request.metadata,
            token_count=None,
            created_at=user_message.created_at
        )
        
        ai_msg_response = MessageResponse(
            id=str(ai_message.id),
            conversation_id=str(conversation.id),
            role=ai_message.role.value,
            content=ai_message.content,
            message_type="text",
            metadata=ai_response.metadata,
            token_count=ai_message.token_count,
            created_at=ai_message.created_at
        )
        
        return ChatResponse(
            user_message=user_msg_response,
            ai_message=ai_msg_response,
            conversation_id=str(conversation.id),
            is_new_conversation=is_new_conversation
        )
        
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Error processing message: {str(e)}"
        )


@router.get("/conversations", response_model=ConversationListResponse)
async def get_conversations(
    limit: int = 20,
    offset: int = 0,
    include_archived: bool = False,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get list of user's conversations"""
    
    query = db.query(Conversation).filter(Conversation.user_id == current_user.id)
    
    if not include_archived:
        query = query.filter(Conversation.is_archived == False)
    
    total_count = query.count()
    
    conversations = query.order_by(
        Conversation.updated_at.desc()
    ).offset(offset).limit(limit).all()
    
    # Convert to response format with message counts
    conversation_summaries = []
    for conv in conversations:
        message_count = db.query(ChatMessage).filter(
            ChatMessage.conversation_id == conv.id
        ).count()
        
        # Get last message timestamp
        last_message = db.query(ChatMessage).filter(
            ChatMessage.conversation_id == conv.id
        ).order_by(ChatMessage.created_at.desc()).first()
        
        last_message_at = last_message.created_at if last_message else conv.created_at
        
        conversation_summaries.append(ConversationSummary(
            id=str(conv.id),
            title=conv.title,
            summary=conv.summary,
            message_count=message_count,
            last_message_at=last_message_at,
            is_archived=conv.is_archived,
            created_at=conv.created_at
        ))
    
    return ConversationListResponse(
        conversations=conversation_summaries,
        total_count=total_count,
        has_more=offset + limit < total_count
    )


@router.get("/conversations/{conversation_id}", response_model=ConversationDetail)
async def get_conversation_detail(
    conversation_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get detailed conversation with all messages"""
    
    conversation = db.query(Conversation).filter(
        Conversation.id == conversation_id,
        Conversation.user_id == current_user.id
    ).first()
    
    if not conversation:
        raise HTTPException(status_code=404, detail="Conversation not found")
    
    # Get all messages for this conversation
    messages = db.query(ChatMessage).filter(
        ChatMessage.conversation_id == conversation_id
    ).order_by(ChatMessage.created_at.asc()).all()
    
    message_responses = []
    for msg in messages:
        metadata = None
        if msg.message_metadata:
            try:
                metadata = json.loads(msg.message_metadata)
            except:
                metadata = None
        
        message_responses.append(MessageResponse(
            id=str(msg.id),
            conversation_id=str(msg.conversation_id),
            role=msg.role.value,
            content=msg.content,
            message_type="text",  # Default to text for now
            metadata=metadata,
            token_count=msg.token_count,
            created_at=msg.created_at
        ))
    
    return ConversationDetail(
        id=str(conversation.id),
        title=conversation.title,
        summary=conversation.summary,
        is_archived=conversation.is_archived,
        created_at=conversation.created_at,
        updated_at=conversation.updated_at,
        messages=message_responses
    )


@router.get("/history", response_model=ChatHistoryResponse)
async def get_chat_history(
    conversation_id: Optional[str] = None,
    limit: int = 50,
    offset: int = 0,
    include_system_messages: bool = False,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get chat history for user or specific conversation"""
    
    query = db.query(ChatMessage).join(Conversation).filter(
        Conversation.user_id == current_user.id
    )
    
    if conversation_id:
        query = query.filter(ChatMessage.conversation_id == conversation_id)
    
    if not include_system_messages:
        query = query.filter(ChatMessage.role != DBMessageRole.SYSTEM)
    
    total_count = query.count()
    
    messages = query.order_by(
        ChatMessage.created_at.desc()
    ).offset(offset).limit(limit).all()
    
    message_responses = []
    for msg in messages:
        metadata = None
        if msg.message_metadata:
            try:
                metadata = json.loads(msg.message_metadata)
            except:
                metadata = None
        
        message_responses.append(MessageResponse(
            id=str(msg.id),
            conversation_id=str(msg.conversation_id),
            role=msg.role.value,
            content=msg.content,
            message_type="text",
            metadata=metadata,
            token_count=msg.token_count,
            created_at=msg.created_at
        ))
    
    return ChatHistoryResponse(
        messages=message_responses,
        conversation_id=conversation_id,
        total_count=total_count,
        has_more=offset + limit < total_count
    )


@router.post("/conversations", response_model=ConversationSummary)
async def create_conversation(
    request: ConversationCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create a new conversation"""
    
    conversation = Conversation(
        user_id=current_user.id,
        title=request.title or f"New Chat - {datetime.utcnow().strftime('%Y-%m-%d %H:%M')}"
    )
    db.add(conversation)
    db.flush()
    
    # Add initial message if provided
    if request.initial_message:
        initial_msg = ChatMessage(
            conversation_id=conversation.id,
            role=DBMessageRole.USER,
            content=request.initial_message
        )
        db.add(initial_msg)
    
    db.commit()
    
    return ConversationSummary(
        id=str(conversation.id),
        title=conversation.title,
        summary=conversation.summary,
        message_count=1 if request.initial_message else 0,
        last_message_at=conversation.created_at,
        is_archived=conversation.is_archived,
        created_at=conversation.created_at
    )


@router.put("/conversations/{conversation_id}", response_model=ConversationSummary)
async def update_conversation(
    conversation_id: str,
    request: ConversationUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update conversation details"""
    
    conversation = db.query(Conversation).filter(
        Conversation.id == conversation_id,
        Conversation.user_id == current_user.id
    ).first()
    
    if not conversation:
        raise HTTPException(status_code=404, detail="Conversation not found")
    
    if request.title is not None:
        conversation.title = request.title
    
    if request.is_archived is not None:
        conversation.is_archived = request.is_archived
    
    db.commit()
    
    # Get message count for response
    message_count = db.query(ChatMessage).filter(
        ChatMessage.conversation_id == conversation.id
    ).count()
    
    # Get last message timestamp
    last_message = db.query(ChatMessage).filter(
        ChatMessage.conversation_id == conversation.id
    ).order_by(ChatMessage.created_at.desc()).first()
    
    last_message_at = last_message.created_at if last_message else conversation.created_at
    
    return ConversationSummary(
        id=str(conversation.id),
        title=conversation.title,
        summary=conversation.summary,
        message_count=message_count,
        last_message_at=last_message_at,
        is_archived=conversation.is_archived,
        created_at=conversation.created_at
    )


@router.delete("/conversations/{conversation_id}")
async def delete_conversation(
    conversation_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Delete a conversation and all its messages"""
    
    conversation = db.query(Conversation).filter(
        Conversation.id == conversation_id,
        Conversation.user_id == current_user.id
    ).first()
    
    if not conversation:
        raise HTTPException(status_code=404, detail="Conversation not found")
    
    # Delete all messages first (should cascade, but being explicit)
    db.query(ChatMessage).filter(
        ChatMessage.conversation_id == conversation_id
    ).delete()
    
    # Delete conversation
    db.delete(conversation)
    db.commit()
    
    return {"message": "Conversation deleted successfully"}


@router.get("/starter", response_model=ConversationStarter)
async def get_conversation_starter(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get a personalized conversation starter"""
    
    starter_message = ai_context_service.get_conversation_starter(db, str(current_user.id))
    
    # Get user context for suggested topics
    user_context = ai_context_service.generate_conversation_context(db, str(current_user.id))
    
    suggested_topics = []
    if user_context.get("current_goals"):
        suggested_topics.extend([
            "Let's talk about your goals",
            "How are you progressing on your aspirations?"
        ])
    
    suggested_topics.extend([
        "What's on your mind today?",
        "Tell me about something you're grateful for",
        "What challenge are you facing right now?",
        "Share a recent win with me"
    ])
    
    return ConversationStarter(
        message=starter_message,
        suggested_topics=suggested_topics[:4],  # Limit to 4 suggestions
        context=user_context
    )


@router.get("/health/ollama")
async def check_ollama_health():
    """Check Ollama service health"""
    return await ollama_service.check_ollama_health()


@router.websocket("/ws")
async def websocket_endpoint(
    websocket: WebSocket,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """WebSocket endpoint for real-time chat"""
    await manager.connect(websocket, str(current_user.id))
    
    # Send connection confirmation
    connection_response = WebSocketResponse(
        type="connected",
        content="Connected to Future Self",
        metadata={"user_id": str(current_user.id)}
    )
    await websocket.send_text(connection_response.model_dump_json())
    
    try:
        while True:
            # Receive message from client
            data = await websocket.receive_text()
            
            try:
                message_data = json.loads(data)
                ws_message = WebSocketMessage(**message_data)
                
                if ws_message.type == "message":
                    # Send typing indicator immediately
                    typing_response = WebSocketResponse(
                        type="ai_typing",
                        content="Future Self is thinking...",
                        conversation_id=ws_message.conversation_id
                    )
                    await websocket.send_text(typing_response.model_dump_json())
                    
                    # Process the message through the AI service
                    await process_websocket_message(websocket, ws_message, current_user, db)
                
                elif ws_message.type == "typing":
                    # Handle user typing indicator (could broadcast to other connected devices)
                    typing_response = WebSocketResponse(
                        type="user_typing",
                        content="User is typing...",
                        conversation_id=ws_message.conversation_id,
                        metadata={"user_id": str(current_user.id)}
                    )
                    # For now, just acknowledge typing
                    pass
                
                elif ws_message.type == "stop_typing":
                    # Handle stop typing
                    stop_typing_response = WebSocketResponse(
                        type="user_stopped_typing",
                        conversation_id=ws_message.conversation_id
                    )
                    pass
                
            except json.JSONDecodeError:
                error_response = WebSocketResponse(
                    type="error",
                    content="Invalid JSON format",
                    metadata={"error_code": "INVALID_JSON"}
                )
                await websocket.send_text(error_response.model_dump_json())
            except Exception as e:
                error_response = WebSocketResponse(
                    type="error",
                    content=f"Processing error: {str(e)}",
                    metadata={"error_code": "PROCESSING_ERROR"}
                )
                await websocket.send_text(error_response.model_dump_json())
                
    except WebSocketDisconnect:
        manager.disconnect(websocket, str(current_user.id))


async def process_websocket_message(
    websocket: WebSocket,
    ws_message: WebSocketMessage,
    current_user: User,
    db: Session
):
    """Process a WebSocket message through the AI service"""
    try:
        # Get or create conversation
        conversation = None
        is_new_conversation = False
        
        if ws_message.conversation_id:
            conversation = db.query(Conversation).filter(
                Conversation.id == ws_message.conversation_id,
                Conversation.user_id == current_user.id
            ).first()
            
            if not conversation:
                # Create new conversation if ID not found
                conversation = Conversation(
                    user_id=current_user.id,
                    title=f"Chat started {datetime.utcnow().strftime('%Y-%m-%d %H:%M')}"
                )
                db.add(conversation)
                db.flush()
                is_new_conversation = True
        else:
            # Create new conversation
            conversation = Conversation(
                user_id=current_user.id,
                title=f"Chat started {datetime.utcnow().strftime('%Y-%m-%d %H:%M')}"
            )
            db.add(conversation)
            db.flush()
            is_new_conversation = True
        
        # Save user message
        user_message = ChatMessage(
            conversation_id=conversation.id,
            role=DBMessageRole.USER,
            content=ws_message.content,
            message_metadata=json.dumps(ws_message.metadata) if ws_message.metadata else None
        )
        db.add(user_message)
        db.flush()
        
        # Send user message confirmation
        user_msg_response = WebSocketResponse(
            type="user_message",
            content=ws_message.content,
            message_id=str(user_message.id),
            conversation_id=str(conversation.id),
            metadata={"is_new_conversation": is_new_conversation}
        )
        await websocket.send_text(user_msg_response.model_dump_json())
        
        # Get conversation history for context
        recent_messages = db.query(ChatMessage).filter(
            ChatMessage.conversation_id == conversation.id
        ).order_by(ChatMessage.created_at.desc()).limit(10).all()
        
        # Reverse to get chronological order
        recent_messages.reverse()
        
        # Format conversation history for AI
        conversation_history = []
        for msg in recent_messages[:-1]:  # Exclude the just-added user message
            conversation_history.append({
                "role": msg.role.value,
                "content": msg.content
            })
        
        # Generate personalized system prompt
        system_prompt = ai_context_service.generate_system_prompt(db, str(current_user.id))
        
        # Get user context for personalization
        user_context = ai_context_service.generate_conversation_context(
            db, str(current_user.id), [msg["content"] for msg in conversation_history[-3:]]
        )
        
        # Prepare AI generation request
        ai_request = AIGenerationRequest(
            user_message=ws_message.content,
            conversation_history=conversation_history,
            user_context=user_context,
            system_prompt=system_prompt
        )
        
        # Generate AI response
        ai_response = await ollama_service.generate_response(ai_request)
        
        # Save AI message
        ai_message = ChatMessage(
            conversation_id=conversation.id,
            role=DBMessageRole.ASSISTANT,
            content=ai_response.content,
            token_count=str(ai_response.token_count) if ai_response.token_count else None,
            message_metadata=json.dumps(ai_response.metadata) if ai_response.metadata else None
        )
        db.add(ai_message)
        
        # Update conversation title if it's new and we have a good first message
        if is_new_conversation and len(ws_message.content) > 10:
            title_preview = ws_message.content[:50]
            if len(ws_message.content) > 50:
                title_preview += "..."
            conversation.title = title_preview
        
        db.commit()
        
        # Send AI response
        ai_msg_response = WebSocketResponse(
            type="ai_message",
            content=ai_response.content,
            message_id=str(ai_message.id),
            conversation_id=str(conversation.id),
            metadata={
                "token_count": ai_response.token_count,
                "model_used": ai_response.model_used,
                "generation_time_ms": ai_response.generation_time_ms
            }
        )
        await websocket.send_text(ai_msg_response.model_dump_json())
        
    except Exception as e:
        db.rollback()
        error_response = WebSocketResponse(
            type="error",
            content=f"Error processing message: {str(e)}",
            metadata={"error_code": "MESSAGE_PROCESSING_ERROR"}
        )
        await websocket.send_text(error_response.model_dump_json())


@router.delete("/history")
async def clear_chat_history(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Clear all chat history for the user"""
    
    # Delete all messages for user's conversations
    db.query(ChatMessage).join(Conversation).filter(
        Conversation.user_id == current_user.id
    ).delete(synchronize_session=False)
    
    # Delete all conversations
    db.query(Conversation).filter(
        Conversation.user_id == current_user.id
    ).delete()
    
    db.commit()
    
    return {"message": "All chat history cleared successfully"} 