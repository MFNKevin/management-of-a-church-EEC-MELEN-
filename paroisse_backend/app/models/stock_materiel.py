from sqlalchemy import Column, Integer, ForeignKey, DateTime, Enum, String
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base
import enum

class TypeMouvementStockEnum(str, enum.Enum):
    entree = "entrée"
    sortie = "sortie"

class StockMateriel(Base):
    __tablename__ = "StockMateriel"

    stock_id = Column(Integer, primary_key=True, index=True)
    materiel_id = Column(Integer, ForeignKey("Materiel.materiel_id"), nullable=False)
    quantite = Column(Integer, nullable=False, default=1)
    type_mouvement = Column(Enum(TypeMouvementStockEnum), nullable=False)
    description = Column(String(255), nullable=True)  # Ex : "Réception commande", "Prêt matériel"
    date_mouvement = Column(DateTime(timezone=True), server_default=func.now())
    
    materiel = relationship("Materiel")
