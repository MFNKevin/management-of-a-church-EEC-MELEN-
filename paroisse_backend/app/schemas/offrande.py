from pydantic import BaseModel, Field, ConfigDict
from typing import Optional
from datetime import date, datetime  # ⚠️ Importer datetime aussi !

class OffrandeBase(BaseModel):
    date_offrande: date = Field(..., alias="date", description="Date de l'offrande")  # alias ici
    montant: float = Field(..., gt=0, description="Montant de l'offrande, strictement positif")
    type: str = Field(..., description="Type de l'offrande (espèce, mobile, chèque, etc.)")
    description: Optional[str] = None
    utilisateur_id: Optional[int] = None

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)

class OffrandeCreate(OffrandeBase):
    pass

class OffrandeUpdate(BaseModel):
    date: Optional[date]  # 🛠️ Doit correspondre au champ original
    montant: Optional[float]
    type: Optional[str]
    description: Optional[str]
    utilisateur_id: Optional[int]

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)
    
class OffrandeOut(OffrandeBase):
    offrande_id: int
    montant_total: Optional[float] = None
    deleted_at: Optional[datetime]

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)  # important

