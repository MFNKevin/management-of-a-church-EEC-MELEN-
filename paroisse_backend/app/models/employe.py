from sqlalchemy import Column, Integer, String, Date, Float, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.database import Base
from sqlalchemy.sql import func

class Employe(Base):
    __tablename__ = "Employe"

    employe_id = Column(Integer, primary_key=True, index=True)
    nom = Column(String(100), nullable=False)
    prenom = Column(String(100), nullable=True)
    poste = Column(String(100), nullable=True)
    date_naissance = Column(Date, nullable=True)
    date_embauche = Column(Date, nullable=True)    
    salaire = Column(Float, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    deleted_at = Column(DateTime(timezone=True), nullable=True, default=None)


    groupe_id = Column(Integer, ForeignKey("Groupe.groupe_id"), nullable=True)  
    groupe = relationship("Groupe", back_populates="employes")
    salaires = relationship("Salaire", back_populates="employe", cascade="all, delete-orphan")