from pydantic import BaseModel, ConfigDict
from typing import Optional
from datetime import date, datetime
import enum

class EtatMaterielEnum(str, enum.Enum):
    neuf = "neuf"
    bon = "bon"
    use = "usé"
    hors_service = "hors_service"

class MaterielBase(BaseModel):
    nom: str
    description: Optional[str] = None
    date_acquisition: date
    etat: EtatMaterielEnum
    localisation: Optional[str] = None
    utilisateur_id: int

class MaterielCreate(MaterielBase):
    pass

class MaterielUpdate(BaseModel):
    nom: Optional[str] = None
    description: Optional[str] = None
    date_acquisition: Optional[date] = None
    etat: Optional[EtatMaterielEnum] = None
    localisation: Optional[str] = None

class MaterielOut(MaterielBase):
    materiel_id: int
    created_at: Optional[datetime]
    updated_at: Optional[datetime]
    deleted_at: Optional[datetime]

    model_config = ConfigDict(from_attributes=True)
