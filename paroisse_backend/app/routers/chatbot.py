from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel

from app.chatbot.chatbot_engine import repondre_question
from app.database import get_db
from app.permissions.chatbot import ALLOWED_ROLES
from app.utils.security import get_current_user

router = APIRouter(prefix="/chatbot", tags=["Chatbot"])

class ChatMessage(BaseModel):
    message: str

class ChatResponse(BaseModel):
    reponse: str

# Dépendance à définir selon ton contexte d'authentification

@router.post("/", response_model=ChatResponse)
async def discuter(
    msg: ChatMessage,
    db: Session = Depends(get_db),
    user_role: str = Depends(get_current_user)
):
    if user_role not in ALLOWED_ROLES:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Rôle non autorisé")
    reponse = repondre_question(msg.message, db)
    return ChatResponse(reponse=reponse)
