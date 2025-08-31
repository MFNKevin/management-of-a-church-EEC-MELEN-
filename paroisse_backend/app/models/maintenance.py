# app/models/maintenance.py

from sqlalchemy import Column, Integer, String, Text, Date, Float, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base

class Maintenance(Base):
    __tablename__ = "Maintenance"

    maintenance_id = Column(Integer, primary_key=True, index=True)
    description = Column(Text, nullable=False)
    date_maintenance = Column(Date, nullable=False)
    cout = Column(Float, nullable=True)

    infrastructure_id = Column(Integer, ForeignKey("Infrastructure.infrastructure_id"), nullable=False)
    utilisateur_id = Column(Integer, ForeignKey("Utilisateur.utilisateur_id"), nullable=False)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    deleted_at = Column(DateTime, nullable=True)

    infrastructure = relationship("Infrastructure", back_populates="maintenances")  # pluriel ici
    utilisateur = relationship("Utilisateur")
