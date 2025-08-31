from sqlalchemy import Column, Integer, String, DateTime
from sqlalchemy.sql import func
from app.database import Base

class Inspecteur(Base):
    __tablename__ = "Inspecteur"

    inspecteur_id = Column(Integer, primary_key=True, index=True)
    nom = Column(String(100), nullable=False)
    prenom = Column(String(100), nullable=True)
    email = Column(String(100), nullable=True)
    telephone = Column(String(50), nullable=True)
    fonction = Column(String(100), nullable=True)

    created_at = Column(DateTime, default=func.now())
    deleted_at = Column(DateTime, nullable=True)
