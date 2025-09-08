from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import Dict, Any
from database import get_db
from auth.auth import get_current_user
from models import User, AIChatHistory
from services.ai_service import AIService
from schemas import UserResponse
import os
from dotenv import load_dotenv
import logging

load_dotenv()
logger = logging.getLogger(__name__)

router = APIRouter(prefix="/ai", tags=["ai_chat"])

# Initialize AI service
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
DATABASE_PATH = "hotel_booking.db"

if not OPENAI_API_KEY:
    logger.error("OPENAI_API_KEY not found in environment variables")
    raise Exception("OpenAI API key is required")

ai_service = AIService(OPENAI_API_KEY, DATABASE_PATH)

@router.post("/chat")
async def chat_with_ai(
    request: Dict[str, str],
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Send a message to AI and get response
    """
    try:
        message = request.get("message", "").strip()
        if not message:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Message cannot be empty"
            )
        
        # Get AI response
        result = await ai_service.chat_with_ai(current_user.id, message)
        
        if not result["success"]:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=result["message"]
            )
        
        return {
            "success": True,
            "message": "AI response generated successfully",
            "data": {
                "user_message": message,
                "ai_response": result["response"],
                "timestamp": "now"
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in AI chat: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error occurred"
        )

@router.get("/chat/history")
async def get_ai_chat_history(
    limit: int = 20,
    offset: int = 0,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get AI chat history for current user (optional - can be used for debugging)
    """
    try:
        history = db.query(AIChatHistory)\
                   .filter(AIChatHistory.user_id == current_user.id)\
                   .order_by(AIChatHistory.created_at.desc())\
                   .offset(offset)\
                   .limit(limit)\
                   .all()
        
        return {
            "success": True,
            "message": "Chat history retrieved successfully",
            "data": [
                {
                    "id": chat.id,
                    "message": chat.message,
                    "ai_response": chat.ai_response,
                    "created_at": chat.created_at.isoformat()
                }
                for chat in history
            ]
        }
        
    except Exception as e:
        logger.error(f"Error getting AI chat history: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error occurred"
        )