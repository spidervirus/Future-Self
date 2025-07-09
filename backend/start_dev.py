#!/usr/bin/env python3
"""
Development startup script for Future Self Backend
"""

import uvicorn
import os
import sys
from pathlib import Path

# Add the backend directory to Python path
backend_dir = Path(__file__).parent
sys.path.insert(0, str(backend_dir))

def main():
    """Start the development server"""
    print("🚀 Starting Future Self Backend Development Server...")
    print("📁 Backend directory:", backend_dir)
    print("🌐 Server will be available at: http://localhost:8000")
    print("📖 API Documentation: http://localhost:8000/api/v1/docs")
    print("🔄 Auto-reload enabled for development")
    print("-" * 50)
    
    # Change to backend directory
    os.chdir(backend_dir)
    
    # Start the server with development settings
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        reload_dirs=[str(backend_dir / "app")],
        log_level="info"
    )

if __name__ == "__main__":
    main() 