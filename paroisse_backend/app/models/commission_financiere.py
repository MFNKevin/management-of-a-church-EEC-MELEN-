from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base

class CommissionFinanciere(Base):
    __tablename__ = "CommissionFinanciere"

    commission_id = Column(Integer, primary_key=True, index=True)
    nom = Column(String(100), nullable=False)
    description = Column(String(255), nullable=True)
    created_at = Column(DateTime, default=func.now())
    deleted_at = Column(DateTime, nullable=True)

    membres = relationship("MembreCommission", back_populates="commission")

class MembreCommission(Base):
    __tablename__ = "MembreCommission"

    membre_commission_id = Column(Integer, primary_key=True, index=True)
    commission_id = Column(Integer, ForeignKey("CommissionFinanciere.commission_id"), nullable=False)
    utilisateur_id = Column(Integer, ForeignKey("Utilisateur.utilisateur_id"), nullable=False)
    role = Column(String(100), nullable=True)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, onupdate=func.now())
    deleted_at = Column(DateTime, nullable=True)

    commission = relationship("CommissionFinanciere", back_populates="membres")
    utilisateur = relationship("Utilisateur")  # Relation vers Utilisateur pour nom/prenom
