from pydantic import BaseModel, ConfigDict
from typing import Optional
from datetime import date, datetime

class AchatBase(BaseModel):
    libelle: str
    montant: float
    date_achat: date
    fournisseur: Optional[str] = None
    

class AchatCreate(AchatBase):
    pass

class AchatUpdate(AchatBase):
    pass

class AchatOut(AchatBase):
    achat_id: int
    montant_total: Optional[float] = None
    deleted_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)
