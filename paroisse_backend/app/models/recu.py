from sqlalchemy import Column, Float, Integer, String, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base

class Recu(Base):
    __tablename__ = "Recu"

    recu_id = Column(Integer, primary_key=True, index=True)
    date_emission = Column(DateTime, default=func.now())
    montant = Column(Integer, nullable=False)
    description = Column(String(255), nullable=True)
    utilisateur_id = Column(Integer, ForeignKey("Utilisateur.utilisateur_id"), nullable=False)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, onupdate=func.now())

    deleted_at = Column(DateTime, nullable=True)

    utilisateur = relationship("Utilisateur", back_populates="recus")
    