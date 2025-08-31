from pydantic import BaseModel, ConfigDict
from typing import Optional
from datetime import date, datetime
from enum import Enum

class EtatInfrastructureEnum(str, Enum):
    bon = "bon"
    usage_limite = "usage_limite"
    endommage = "endommage"
    en_reparation = "en_reparation"
    hors_service = "hors_service"

class InfrastructureBase(BaseModel):
    nom: str
    description: Optional[str]
    etat: EtatInfrastructureEnum = EtatInfrastructureEnum.bon
    date_acquisition: Optional[date]
    valeur: Optional[float]

class InfrastructureCreate(InfrastructureBase):
    pass

class InfrastructureUpdate(BaseModel):
    nom: Optional[str]
    description: Optional[str]
    etat: Optional[EtatInfrastructureEnum]
    date_acquisition: Optional[date]
    valeur: Optional[float]

class InfrastructureOut(InfrastructureBase):
    infrastructure_id: int
    created_at: Optional[datetime]
    updated_at: Optional[datetime]
    deleted_at: Optional[datetime]

    model_config = ConfigDict(from_attributes=True)
