from pydantic import BaseModel, ConfigDict
from typing import Optional
from datetime import datetime

class FactureBase(BaseModel):
    numero: str
    montant: float
    date_facture: Optional[datetime] = None
    description: Optional[str]
    utilisateur_id: int

class FactureCreate(FactureBase):
    pass

class FactureUpdate(BaseModel):
    numero: Optional[str]
    montant: Optional[float]
    date_facture: Optional[datetime]
    description: Optional[str]
    utilisateur_id: Optional[int]

class FactureOut(FactureBase):
    facture_id: int
    montant_total: Optional[float] = None  # ← à ajouter
    deleted_at: Optional[datetime]

    model_config = ConfigDict(from_attributes=True)
