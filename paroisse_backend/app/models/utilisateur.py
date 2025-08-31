from sqlalchemy import Column, Integer, String, Date, Enum, DateTime
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database import Base
import enum

class RoleEnum(str, enum.Enum):
    TresorierParoissial = 'TresorierParoissial'
    Evangeliste = 'Evangeliste'
    Administrateur = 'Administrateur'
    Fidele = 'Fidele'
    Pasteur = 'Pasteur'
    Inspecteur = 'Inspecteur'
    ResponsableLaique = 'ResponsableLaique'
    Secretaire = 'Secretaire'
    SousCommissionFinanciere = "SousCommissionFinanciere"
    CommissionFinanciere = "CommissionFinanciere"
 
    
class Utilisateur(Base):
    __tablename__ = "Utilisateur"

    utilisateur_id = Column(Integer, primary_key=True, index=True)
    photo = Column(String(255), nullable=True)
    nom = Column(String(100), nullable=True)
    prenom = Column(String(100), nullable=True)
    dateNaissance = Column(Date, nullable=True)
    lieuNaissance = Column(String(100), nullable=True)
    nationalite = Column(String(50), nullable=True)
    villeResidence = Column(String(100), nullable=True)
    email = Column(String(100), nullable=True, unique=True)
    profession = Column(String(100), nullable=True)
    telephone = Column(String(20), nullable=True)
    etatCivil = Column(String(20), nullable=True)
    sexe = Column(String(10), nullable=True)
    mot_de_passe = Column(String(255), nullable=False)
    role = Column(Enum(RoleEnum), nullable=False)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, onupdate=func.now())


    deleted_at = Column(DateTime, nullable=True, default=None)

    recus = relationship("Recu", back_populates="utilisateur")

    notifications = relationship("Notification", back_populates="utilisateur")
    budgets = relationship("Budget", backref="utilisateur")

