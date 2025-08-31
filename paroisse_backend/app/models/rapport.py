from sqlalchemy import Column, Integer, String, Text, Date, DateTime, ForeignKey, Enum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base
import enum

class RapportTypeEnum(enum.Enum):
    financier = "financier"
    administratif = "administratif"
    audit = "audit"
    materiel = "materiel"

class Rapport(Base):
    __tablename__ = "Rapport"

    rapport_id = Column(Integer, primary_key=True, index=True)
    titre = Column(String(255), nullable=False)
    contenu = Column(Text, nullable=False)
    date_rapport = Column(Date, nullable=False)
    type = Column(Enum(RapportTypeEnum), default=RapportTypeEnum.financier, nullable=False)

    utilisateur_id = Column(Integer, ForeignKey("Utilisateur.utilisateur_id"), nullable=False)
    utilisateur = relationship("Utilisateur")

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    deleted_at = Column(DateTime, nullable=True)
