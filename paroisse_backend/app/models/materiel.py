from sqlalchemy import Column, Integer, String, Text, Date, Enum, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base
import enum

class EtatMaterielEnum(enum.Enum):
    neuf = "neuf"
    bon = "bon"
    use = "usé"
    hors_service = "hors_service"

class Materiel(Base):
    __tablename__ = "Materiel"

    materiel_id = Column(Integer, primary_key=True, index=True)
    nom = Column(String(100), nullable=False)
    description = Column(Text, nullable=True)    
    date_acquisition = Column(Date, nullable=False)
    etat = Column(Enum(EtatMaterielEnum), nullable=False, default=EtatMaterielEnum.bon)
    localisation = Column(String(255), nullable=True)
    seuil_min = Column(Integer, default=10, nullable=False)


    utilisateur_id = Column(Integer, ForeignKey("Utilisateur.utilisateur_id"), nullable=False)
    utilisateur = relationship("Utilisateur")

    prets = relationship("Pret", back_populates="materiel", cascade="all, delete-orphan", foreign_keys="Pret.materiel_id")

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    deleted_at = Column(DateTime, nullable=True)
