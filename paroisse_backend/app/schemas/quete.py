from pydantic import BaseModel, ConfigDict
from typing import Optional
from datetime import datetime

class QueteBase(BaseModel):
    libelle: str
    montant: float
    date_quete: Optional[datetime] = None
    utilisateur_id: int

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)

class QueteCreate(QueteBase):
    pass

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)

class QueteUpdate(BaseModel):
    libelle: Optional[str]
    montant: Optional[float]
    date_quete: Optional[datetime]
    utilisateur_id: Optional[int]

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)
    
class QueteOut(QueteBase):
    quete_id: int
    montant_total: Optional[float] = None
    deleted_at: Optional[datetime]

    model_config = ConfigDict(from_attributes=True)
