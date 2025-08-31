from sqlalchemy import Column, Integer, Float, DateTime, ForeignKey, String, Text
from sqlalchemy.orm import relationship
from app.database import Base
from datetime import datetime
from sqlalchemy.sql import func

class Don(Base):
    __tablename__ = "don"  # généralement en minuscules pour la table

    don_id = Column(Integer, primary_key=True, index=True)
    donateur = Column(String(255), nullable=False)  # ajout du champ donateur (nom du donateur)
    montant = Column(Float, nullable=False)
    type = Column(String(50), nullable=False)  # si tu souhaites garder ce champ (ex: type de don)
    date_don = Column(DateTime, default=datetime.utcnow, nullable=False)
    commentaire = Column(Text, nullable=True)  # commentaire optionnel

    utilisateur_id = Column(Integer, ForeignKey("Utilisateur.utilisateur_id"), nullable=False)

    created_at = Column(DateTime, server_default=func.now(), nullable=False)
    updated_at = Column(DateTime, onupdate=func.now())
    deleted_at = Column(DateTime, nullable=True, default=None)

    utilisateur = relationship("Utilisateur")
