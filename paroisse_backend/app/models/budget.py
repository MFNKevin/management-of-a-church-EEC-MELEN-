from sqlalchemy import Column, Integer, String, Float, DateTime, Enum, ForeignKey
from sqlalchemy.sql import func
from app.database import Base


class Budget(Base):
    __tablename__ = "Budget"

    budget_id = Column(Integer, primary_key=True, index=True)
    intitule = Column(String(100), nullable=False)
    annee = Column(Integer, nullable=False)
    montantTotal = Column(Float, nullable=False)
    montantApprouve = Column(Float, nullable=True)
    statut = Column(Enum('Proposé','Approuvé','Rejeté'), default='Proposé')
    dateSoumission = Column(DateTime, nullable=False, default=func.now())
    utilisateur_id = Column(Integer, ForeignKey("Utilisateur.utilisateur_id"), nullable=False)
    commissionfinanciere_id = Column(Integer, nullable=True)
    souscommissionfinanciere_id = Column(Integer, nullable=True)
    
    sous_categorie = Column(String(100), nullable=False)  # Don, Offrande, etc.
    categorie = Column(Enum('Recette', 'Depense'), nullable=False)
    montant_reel = Column(Float, default=0.0)  # Montant réel mis à jour dynamiquement

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    deleted_at = Column(DateTime, nullable=True)
   

