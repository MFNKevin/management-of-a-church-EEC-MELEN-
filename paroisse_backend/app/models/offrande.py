from sqlalchemy import Column, Integer, String, Date, Float, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base

class Offrande(Base):
    __tablename__ = "Offrande"

    offrande_id = Column(Integer, primary_key=True, index=True)
    date = Column(Date, nullable=False)
    montant = Column(Float, nullable=False)
    type = Column(String(50), nullable=False)
    description = Column(String(255), nullable=True)

    utilisateur_id = Column(Integer, ForeignKey("Utilisateur.utilisateur_id"), nullable=True)
    utilisateur = relationship("Utilisateur", backref="offrandes")

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    deleted_at = Column(DateTime, nullable=True)
