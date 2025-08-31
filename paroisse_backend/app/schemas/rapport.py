from pydantic import BaseModel, ConfigDict
from typing import Optional
from datetime import date, datetime
import enum

class TypeRapportEnum(str, enum.Enum):    
    administratif = "administratif"
    financier = "financier"
    materiel = "materiel"
    audit = "audit"

class RapportBase(BaseModel):
    titre: str
    contenu: str
    date_rapport: date
    utilisateur_id: int
    type: TypeRapportEnum

class RapportCreate(RapportBase):
    pass

class RapportUpdate(BaseModel):
    titre: Optional[str]
    contenu: Optional[str]
    date_rapport: Optional[date]
   
class RapportOut(RapportBase):
    rapport_id: int
    created_at: Optional[datetime]
    updated_at: Optional[datetime]
    deleted_at: Optional[datetime]

    model_config = ConfigDict(from_attributes=True)
