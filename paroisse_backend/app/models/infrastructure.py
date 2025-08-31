from sqlalchemy import Column, ForeignKey, Integer, String, Text, Date, Float, Enum, DateTime
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base
from enum import Enum as PyEnum


class EtatInfrastructureEnum(PyEnum):
    bon = "bon"
    usage_limite = "usage_limite"
    endommage = "endommage"
    en_reparation = "en_reparation"
    hors_service = "hors_service"


class Infrastructure(Base):
    __tablename__ = "Infrastructure"

    infrastructure_id = Column(Integer, primary_key=True, index=True)
    nom = Column(String(255), nullable=False)
    description = Column(Text)
    etat = Column(Enum(EtatInfrastructureEnum), default=EtatInfrastructureEnum.bon)
    date_acquisition = Column(Date, nullable=True)
    valeur = Column(Float, nullable=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    deleted_at = Column(DateTime, nullable=True)

    prets = relationship("Pret", back_populates="infrastructure", cascade="all, delete-orphan")
    maintenances = relationship("Maintenance", back_populates="infrastructure", cascade="all, delete-orphan")  # pluriel ici
