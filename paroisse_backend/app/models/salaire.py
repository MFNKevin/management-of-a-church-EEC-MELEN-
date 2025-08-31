from sqlalchemy import Column, Integer, Float, Date, ForeignKey, DateTime
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database import Base

class Salaire(Base):
    __tablename__ = "Salaire"

    salaire_id = Column(Integer, primary_key=True, index=True)
    employe_id = Column(Integer, ForeignKey("Employe.employe_id"), nullable=False)
    utilisateur_id = Column(Integer, ForeignKey("Utilisateur.utilisateur_id"), nullable=False)  # ← AJOUT ICI

    montant = Column(Float, nullable=False)
    date_paiement = Column(Date, nullable=False)
    created_at = Column(DateTime, default=func.now())
    deleted_at = Column(DateTime, nullable=True)

    employe = relationship("Employe")
    utilisateur = relationship("Utilisateur")  # ← Optionnel si besoin d’accès
