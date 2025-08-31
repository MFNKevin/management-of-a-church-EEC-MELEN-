from sqlalchemy import Column, Integer, String, Date, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from app.database import Base
from sqlalchemy.sql import func


class Pret(Base):
    __tablename__ = "pret"

    pret_id = Column(Integer, primary_key=True, index=True)
    beneficiaire = Column(String(255), nullable=False)
    numero_cni = Column(String(50), nullable=False)
    email = Column(String(100), nullable=False)
    telephone = Column(String(20), nullable=False)
    date_pret = Column(Date, nullable=False)
    date_retour_prevue = Column(Date, nullable=False)
    date_retour_effective = Column(Date, nullable=True)
    etat_retour = Column(String(255), nullable=True)

    materiel_id = Column(Integer, ForeignKey("Materiel.materiel_id"), nullable=True)
    infrastructure_id = Column(Integer, ForeignKey("Infrastructure.infrastructure_id"), nullable=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    deleted_at = Column(DateTime, nullable=True)

    materiel = relationship("Materiel", back_populates="prets")
    infrastructure = relationship("Infrastructure", back_populates="prets")
