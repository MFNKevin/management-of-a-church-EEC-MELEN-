from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base

class SousCommissionFinanciere(Base):
    __tablename__ = "SousCommissionFinanciere"

    sous_commission_id = Column(Integer, primary_key=True, index=True)
    nom = Column(String(100), nullable=False)
    description = Column(String(255), nullable=True)
    created_at = Column(DateTime, default=func.now())
    deleted_at = Column(DateTime, nullable=True)

    membres = relationship("MembreSousCommission", back_populates="sous_commission")


class MembreSousCommission(Base):
    __tablename__ = "MembreSousCommission"

    membre_sous_commission_id = Column(Integer, primary_key=True, index=True)
    sous_commission_id = Column(Integer, ForeignKey("SousCommissionFinanciere.sous_commission_id"), nullable=False)

    utilisateur_id = Column(Integer, ForeignKey("Utilisateur.utilisateur_id"), nullable=False)  # facultatif    
    role = Column(String(100), nullable=True)

    created_at = Column(DateTime, default=func.now())
    deleted_at = Column(DateTime, nullable=True)

    sous_commission = relationship("SousCommissionFinanciere", back_populates="membres")
    utilisateur = relationship("Utilisateur", backref="membre_sous_commission", lazy="joined")
