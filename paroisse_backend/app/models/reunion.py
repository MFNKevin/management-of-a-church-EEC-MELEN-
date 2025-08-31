from sqlalchemy import Column, Integer, String, DateTime, Text, Enum
from sqlalchemy.ext.hybrid import hybrid_property
from sqlalchemy.sql import func
from app.database import Base
import enum
import json
from sqlalchemy.orm import relationship

class ConvocateurEnum(enum.Enum):
    Pasteur = "Pasteur"
    Evangeliste = "Evangeliste"
    ResponsableLaique = "ResponsableLaique"
    Secretaire = "Secretaire"
    Fidele = "Fidele"



class Reunion(Base):
    __tablename__ = "Reunion"  # correspond exactement à ForeignKey

    reunion_id = Column(Integer, primary_key=True, index=True)
    titre = Column(String(200), nullable=False)
    date = Column(DateTime, nullable=False)
    lieu = Column(String(200), nullable=True)
    description = Column(Text, nullable=True)
    convocateur_role = Column(Enum(ConvocateurEnum), nullable=False)
    _convoques = Column("convoques", Text, nullable=False)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    deleted_at = Column(DateTime(timezone=True), nullable=True)

    decisions = relationship("Decision", back_populates="reunion", cascade="all, delete-orphan")

    @hybrid_property
    def convoques(self) -> list[int]:
        try:
            return json.loads(self._convoques)
        except Exception:
            return []

    @convoques.setter
    def convoques(self, value: list[int]):
        self._convoques = json.dumps(value)
