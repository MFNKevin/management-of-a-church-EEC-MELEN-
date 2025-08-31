from pydantic import BaseModel, ConfigDict
from typing import Optional
from datetime import datetime

class RecuBase(BaseModel):
    date_emission: Optional[datetime] = None
    montant: int
    description: Optional[str]
    utilisateur_id: int

class RecuCreate(RecuBase):
    pass

class RecuOut(RecuBase):
    recu_id: int
    montant_total: Optional[float] = None  # ← à ajouter
    deleted_at: Optional[datetime]

    model_config = ConfigDict(from_attributes=True)
