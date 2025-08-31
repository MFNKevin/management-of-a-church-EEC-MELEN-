from pydantic import BaseModel, ConfigDict
from datetime import date, datetime
from typing import Optional

class SalaireBase(BaseModel):
    employe_id: int
    montant: float
    date_paiement: date

class SalaireCreate(SalaireBase):
    pass

class SalaireUpdate(SalaireBase):
    pass

class SalaireOut(SalaireBase):
    salaire_id: int
    utilisateur_id: int 
    created_at: datetime
    montant_total: Optional[float] = None
    deleted_at: Optional[datetime]

    employe_nom: Optional[str] = None
    employe_prenom: Optional[str] = None
    employe_poste: Optional[str] = None
    
    model_config = ConfigDict(from_attributes=True)
