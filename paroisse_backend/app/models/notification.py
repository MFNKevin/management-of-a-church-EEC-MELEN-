from sqlalchemy import Column, Integer, String, Text, Boolean, DateTime, Enum, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database import Base
import enum

class TypeNotificationEnum(str, enum.Enum):
    info = "info"
    success = "success"
    warning = "warning"
    error = "error"
    confirmation = "confirmation"
    question = "question"

class Notification(Base):
    __tablename__ = "Notification"

    notification_id = Column(Integer, primary_key=True, index=True)
    titre = Column(String(255), nullable=False)
    message = Column(Text, nullable=False)
    type = Column(Enum(TypeNotificationEnum), nullable=False)
    utilisateur_id = Column(Integer, ForeignKey("Utilisateur.utilisateur_id"), nullable=True)
    est_lue = Column(Boolean, default=False)
    email_envoye = Column(Boolean, default=False)
    email_envoye_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())    
    updated_at = Column(DateTime, onupdate=func.now())

    deleted_at = Column(DateTime, nullable=True)

    utilisateur = relationship("Utilisateur", back_populates="notifications")
