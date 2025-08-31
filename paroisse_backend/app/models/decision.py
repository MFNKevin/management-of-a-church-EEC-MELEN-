from sqlalchemy import Column, Integer, String, Text, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from app.database import Base
from sqlalchemy.sql import func
from datetime import datetime

class Decision(Base):
    __tablename__ = "Decision"
    decision_id = Column(Integer, primary_key=True, index=True)
    titre = Column(String(200), nullable=False)
    description = Column(Text)
    reunion_id = Column(Integer, ForeignKey("Reunion.reunion_id"), nullable=False)
    auteur_id = Column(Integer, ForeignKey("Utilisateur.utilisateur_id"), nullable=False)

    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, onupdate=func.now())
    date_valide = Column(DateTime, default=None)
    deleted_at = Column(DateTime, nullable=True)

    reunion = relationship("Reunion", back_populates="decisions")
    auteur = relationship("Utilisateur", backref="decisions", lazy="joined")
