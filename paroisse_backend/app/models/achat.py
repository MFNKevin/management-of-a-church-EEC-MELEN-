from sqlalchemy import Column, Integer, String, Float, Date, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base

class Achat(Base):
    __tablename__ = "Achat"

    achat_id = Column(Integer, primary_key=True, index=True)
    libelle = Column(String(255), nullable=False)
    montant = Column(Float, nullable=False)
    date_achat = Column(Date, nullable=False)
    fournisseur = Column(String(255), nullable=True)
    facture_id = Column(Integer, ForeignKey("Facture.facture_id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())


    deleted_at = Column(DateTime, nullable=True, default=None)

    facture = relationship("Facture", back_populates="achats")

    utilisateur_id = Column(Integer, ForeignKey("Utilisateur.utilisateur_id"), nullable=False)
    utilisateur = relationship("Utilisateur")

    