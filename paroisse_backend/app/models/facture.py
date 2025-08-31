# app/models/facture.py

from typing import Optional
from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base
from datetime import datetime

class Facture(Base):
    __tablename__ = "Facture"

    facture_id = Column(Integer, primary_key=True, index=True)
    numero = Column(String(100), nullable=False, unique=True)
    montant = Column(Float, nullable=False)
    date_facture = Column(DateTime, nullable=False, default=func.now())
    description = Column(String(255), nullable=True)
    utilisateur_id = Column(Integer, ForeignKey("Utilisateur.utilisateur_id"), nullable=False)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, onupdate=func.now())

    deleted_at = Column(DateTime, nullable=True, default=None)

    utilisateur = relationship("Utilisateur")

    achats = relationship("Achat", back_populates="facture")
    