import httpx
import json
import time
import asyncio
from typing import Dict, List, Optional, Any
from datetime import datetime

from app.schemas.chat import AIGenerationRequest, AIGenerationResponse
from app.core.exceptions import ValidationError


class OllamaService:
    """Service for integrating with local Ollama server for AI response generation"""
    
    def __init__(self):
        self.base_url = "http://localhost:11434"  # Default Ollama server
        self.model_name = "mistral:7b"  # Using Mistral model
        self.max_retries = 3
        self.timeout = 120  # 2 minutes timeout for generation
        self.max_context_length = 4096  # Max tokens for context
        
        # Response generation settings
        self.generation_params = {
            "temperature": 0.8,  # Balance creativity and consistency
            "top_p": 0.9,
            "top_k": 40,
            "repeat_penalty": 1.1,
            "max_tokens": 1000,  # Max response length
            "stop": ["Human:", "User:", "<|endoftext|>"]
        }
    
    async def generate_response(self, request: AIGenerationRequest) -> AIGenerationResponse:
        """Generate AI response using Ollama"""
        start_time = time.time()
        
        try:
            # Format the conversation for Ollama
            formatted_prompt = self._format_conversation_prompt(
                system_prompt=request.system_prompt,
                conversation_history=request.conversation_history,
                user_message=request.user_message,
                user_context=request.user_context
            )
            
            # Generate response
            response_content = await self._call_ollama(formatted_prompt)
            
            # Calculate generation time
            generation_time = int((time.time() - start_time) * 1000)
            
            # Estimate token count (rough approximation)
            token_count = self._estimate_token_count(response_content)
            
            return AIGenerationResponse(
                content=response_content.strip(),
                token_count=token_count,
                model_used=self.model_name,
                generation_time_ms=generation_time,
                metadata={
                    "temperature": self.generation_params["temperature"],
                    "max_tokens": self.generation_params["max_tokens"]
                }
            )
            
        except Exception as e:
            # Handle errors gracefully with fallback response
            fallback_response = self._get_fallback_response(request.user_message)
            
            return AIGenerationResponse(
                content=fallback_response,
                token_count=self._estimate_token_count(fallback_response),
                model_used="fallback",
                generation_time_ms=int((time.time() - start_time) * 1000),
                metadata={"error": str(e), "fallback_used": True}
            )
    
    async def _call_ollama(self, prompt: str) -> str:
        """Make API call to Ollama server"""
        payload = {
            "model": self.model_name,
            "prompt": prompt,
            "stream": False,
            "options": {
                "temperature": self.generation_params["temperature"],
                "top_p": self.generation_params["top_p"],
                "top_k": self.generation_params["top_k"],
                "repeat_penalty": self.generation_params["repeat_penalty"],
                "stop": self.generation_params["stop"]
            }
        }
        
        last_error = None
        
        for attempt in range(self.max_retries):
            try:
                async with httpx.AsyncClient(timeout=self.timeout) as client:
                    response = await client.post(
                        f"{self.base_url}/api/generate",
                        json=payload,
                        headers={"Content-Type": "application/json"}
                    )
                    
                    if response.status_code == 200:
                        result = response.json()
                        return result.get("response", "").strip()
                    else:
                        last_error = f"Ollama server error: {response.status_code} - {response.text}"
                        
            except httpx.TimeoutException:
                last_error = "Request to Ollama timed out"
            except httpx.ConnectError:
                last_error = "Could not connect to Ollama server. Make sure Ollama is running."
            except Exception as e:
                last_error = f"Unexpected error: {str(e)}"
            
            # Wait before retry (exponential backoff)
            if attempt < self.max_retries - 1:
                await asyncio.sleep(2 ** attempt)
        
        # If all retries failed, raise the last error
        raise Exception(last_error)
    
    def _format_conversation_prompt(
        self, 
        system_prompt: str, 
        conversation_history: List[Dict[str, str]], 
        user_message: str,
        user_context: Dict[str, Any]
    ) -> str:
        """Format the conversation for Ollama input"""
        
        # Start with system prompt
        prompt_parts = [
            f"<SYSTEM>\n{system_prompt}\n</SYSTEM>",
            ""
        ]
        
        # Add conversation history (last few messages for context)
        if conversation_history:
            prompt_parts.append("<CONVERSATION_HISTORY>")
            
            # Only include recent messages to stay within context limits
            recent_history = conversation_history[-6:]  # Last 6 messages
            
            for msg in recent_history:
                role = msg.get("role", "")
                content = msg.get("content", "")
                
                if role == "user":
                    prompt_parts.append(f"Human: {content}")
                elif role == "assistant":
                    prompt_parts.append(f"Future Self: {content}")
            
            prompt_parts.extend(["</CONVERSATION_HISTORY>", ""])
        
        # Add current user message
        prompt_parts.extend([
            "<CURRENT_INTERACTION>",
            f"Human: {user_message}",
            "Future Self:"
        ])
        
        full_prompt = "\n".join(prompt_parts)
        
        # Ensure we don't exceed context length
        if len(full_prompt) > self.max_context_length * 3:  # Rough character limit
            # Truncate conversation history if needed
            truncated_prompt = "\n".join([
                f"<SYSTEM>\n{system_prompt}\n</SYSTEM>",
                "",
                "<CURRENT_INTERACTION>",
                f"Human: {user_message}",
                "Future Self:"
            ])
            return truncated_prompt
        
        return full_prompt
    
    def _estimate_token_count(self, text: str) -> int:
        """Rough estimation of token count (approximate 1.3 tokens per word)"""
        words = len(text.split())
        return int(words * 1.3)
    
    def _get_fallback_response(self, user_message: str) -> str:
        """Generate a fallback response when AI service is unavailable"""
        fallback_responses = [
            "I'm experiencing some technical difficulties right now, but I'm here with you. Sometimes the most important conversations happen in the quiet moments. What's really on your heart today?",
            
            "It seems I'm having trouble connecting to my deeper wisdom right now, but that doesn't mean our conversation has to stop. Often the best insights come from simply being present with whatever you're feeling. Can you tell me more about what's happening in your world?",
            
            "I'm temporarily unable to access my full capabilities, but I want you to know that I'm still here for you. Even when technology fails, the connection between who you are now and who you're becoming remains strong. What would you like to explore together?",
            
            "I'm encountering some technical challenges at the moment, but perhaps this is an invitation for you to connect with your own inner wisdom. What does your intuition tell you about the situation you're facing?",
            
            "While I'm experiencing some connectivity issues, I believe every interaction has meaning. Sometimes the most profound insights come not from external advice, but from the questions we ask ourselves. What question feels most important for you right now?"
        ]
        
        # Simple hash to consistently choose a fallback based on message
        import hashlib
        message_hash = int(hashlib.md5(user_message.encode()).hexdigest()[:8], 16)
        return fallback_responses[message_hash % len(fallback_responses)]
    
    async def check_ollama_health(self) -> Dict[str, Any]:
        """Check if Ollama server is running and accessible"""
        try:
            async with httpx.AsyncClient(timeout=10) as client:
                # Check if server is running
                response = await client.get(f"{self.base_url}/api/tags")
                
                if response.status_code == 200:
                    models = response.json().get("models", [])
                    has_mistral = any(self.model_name in model.get("name", "") for model in models)
                    
                    return {
                        "status": "healthy",
                        "server_accessible": True,
                        "mistral_available": has_mistral,
                        "available_models": [model.get("name") for model in models],
                        "recommended_action": "pull_mistral" if not has_mistral else "ready"
                    }
                else:
                    return {
                        "status": "error",
                        "server_accessible": False,
                        "error": f"Server returned {response.status_code}"
                    }
                    
        except httpx.ConnectError:
            return {
                "status": "error",
                "server_accessible": False,
                "error": "Could not connect to Ollama server",
                "recommended_action": "start_ollama"
            }
        except Exception as e:
            return {
                "status": "error",
                "server_accessible": False,
                "error": str(e)
            }
    
    async def pull_mistral_model(self) -> Dict[str, Any]:
        """Pull the Mistral model if it's not available"""
        try:
            async with httpx.AsyncClient(timeout=300) as client:  # 5 minute timeout for model pull
                response = await client.post(
                    f"{self.base_url}/api/pull",
                    json={"name": self.model_name},
                    headers={"Content-Type": "application/json"}
                )
                
                if response.status_code == 200:
                    return {
                        "status": "success",
                        "message": f"Successfully pulled {self.model_name}"
                    }
                else:
                    return {
                        "status": "error",
                        "message": f"Failed to pull model: {response.text}"
                    }
                    
        except Exception as e:
            return {
                "status": "error",
                "message": f"Error pulling model: {str(e)}"
            }
    
    def update_generation_params(self, **kwargs):
        """Update generation parameters"""
        for key, value in kwargs.items():
            if key in self.generation_params:
                self.generation_params[key] = value
    
    def get_model_info(self) -> Dict[str, Any]:
        """Get information about the current model configuration"""
        return {
            "model_name": self.model_name,
            "base_url": self.base_url,
            "generation_params": self.generation_params,
            "max_context_length": self.max_context_length,
            "timeout": self.timeout
        } 