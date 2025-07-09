# Future Self Backend API

This is the backend API for the Future Self application - an AI-powered personal development companion.

## 🏗️ Architecture

- **Framework**: FastAPI (Python)
- **Database**: Supabase (PostgreSQL)
- **AI Integration**: Ollama with Mistral LLM
- **Authentication**: Supabase Auth
- **Background Tasks**: Celery with Redis

## 🚀 Quick Start

### Prerequisites

- Python 3.9+
- pip or conda
- Git

### Installation

1. **Clone and navigate to backend directory**:
   ```bash
   cd backend
   ```

2. **Create and activate virtual environment**:
   ```bash
   # Using venv
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   
   # Or using conda
   conda create -n future-self python=3.9
   conda activate future-self
   ```

3. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

4. **Set up environment variables**:
   ```bash
   cp env.example .env
   # Edit .env with your actual values
   ```

5. **Start development server**:
   ```bash
   python start_dev.py
   ```

The API will be available at:
- **API Base**: http://localhost:8000
- **Documentation**: http://localhost:8000/api/v1/docs
- **Health Check**: http://localhost:8000/health

## 📝 Environment Setup

Copy `env.example` to `.env` and configure the following:

### Required Variables
```env
# Supabase Configuration
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_KEY=your_supabase_service_key

# Security
SECRET_KEY=your_super_secret_jwt_key_here
```

### Optional Variables
```env
# Development settings
ENVIRONMENT=development
DEBUG=True

# External APIs
OPENAI_API_KEY=your_openai_api_key
OLLAMA_BASE_URL=http://localhost:11434

# Redis (for background tasks)
REDIS_URL=redis://localhost:6379/0
```

## 🏛️ Project Structure

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py                 # FastAPI application
│   ├── core/
│   │   ├── __init__.py
│   │   └── config.py          # Configuration management
│   └── api/
│       ├── __init__.py
│       └── v1/
│           ├── __init__.py
│           ├── router.py      # Main API router
│           └── endpoints/
│               ├── __init__.py
│               ├── auth.py    # Authentication endpoints
│               ├── users.py   # User management
│               ├── onboarding.py  # Onboarding process
│               ├── chat.py    # Chat functionality
│               └── health.py  # Health checks
├── requirements.txt
├── env.example
├── start_dev.py              # Development server script
└── README.md
```

## 🛠️ Development

### Running Tests
```bash
pytest
```

### Code Formatting
```bash
black app/
```

### Type Checking
```bash
mypy app/
```

## 📊 API Endpoints

### Health & System
- `GET /` - Root endpoint
- `GET /health` - Basic health check
- `GET /api/v1/health/` - Detailed health check
- `GET /api/v1/health/ping` - Simple ping

### Authentication
- `POST /api/v1/auth/register` - User registration
- `POST /api/v1/auth/login` - User login
- `POST /api/v1/auth/logout` - User logout
- `POST /api/v1/auth/refresh` - Refresh token
- `GET /api/v1/auth/me` - Get current user

### User Management
- `GET /api/v1/users/profile` - Get user profile
- `PUT /api/v1/users/profile` - Update user profile
- `DELETE /api/v1/users/account` - Delete user account

### Onboarding
- `GET /api/v1/onboarding/questions` - Get onboarding questions
- `GET /api/v1/onboarding/progress` - Get user progress
- `POST /api/v1/onboarding/submit` - Submit complete onboarding
- `POST /api/v1/onboarding/save-step/{step_number}` - Save individual step
- `GET /api/v1/onboarding/data` - Get saved onboarding data

### Chat & AI
- `POST /api/v1/chat/send` - Send message to AI
- `GET /api/v1/chat/history` - Get chat history
- `GET /api/v1/chat/daily-message` - Get daily message
- `POST /api/v1/chat/daily-message/{id}/read` - Mark message as read
- `POST /api/v1/chat/voice/upload` - Upload voice message
- `GET /api/v1/chat/voice/{id}` - Get voice message
- `WebSocket /api/v1/chat/ws` - Real-time chat
- `DELETE /api/v1/chat/history` - Clear chat history

## 🔄 Development Workflow

1. **Make changes** to the code
2. **Test locally** using the development server
3. **Run tests** to ensure functionality
4. **Format code** using Black
5. **Type check** using mypy
6. **Commit changes** following conventional commits

## 📚 Next Steps

1. **Set up Supabase** project and configure database schema
2. **Implement authentication** using Supabase Auth
3. **Create database models** for onboarding and chat data
4. **Integrate AI services** (Ollama/OpenAI)
5. **Implement real-time chat** functionality
6. **Add background task processing** for daily messages

## 🤝 Contributing

1. Follow the existing code structure
2. Add appropriate type hints
3. Write tests for new features
4. Update documentation as needed
5. Follow conventional commit messages

## 📄 License

This project is part of the Future Self application development. 