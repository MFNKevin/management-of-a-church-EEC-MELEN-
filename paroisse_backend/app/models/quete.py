from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base

class Quete(Base):
    __tablename__ = "Quete"

    quete_id = Column(Integer, primary_key=True, index=True)
    libelle = Column(String(255), nullable=False)
    montant = Column(Float, nullable=False)
    date_quete = Column(DateTime, nullable=False, default=func.now())
    utilisateur_id = Column(Integer, ForeignKey("Utilisateur.utilisateur_id"), nullable=False)

    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, onupdate=func.now())
    deleted_at = Column(DateTime, nullable=True, default=None)

    utilisateur = relationship("Utilisateur")
   