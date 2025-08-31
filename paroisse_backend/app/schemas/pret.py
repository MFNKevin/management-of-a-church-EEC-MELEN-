from pydantic import BaseModel, ConfigDict, EmailStr, model_validator
from typing import Optional
from datetime import date, datetime

class PretBase(BaseModel):
    materiel_id: Optional[int] = None
    infrastructure_id: Optional[int] = None
    beneficiaire: str
    numero_cni: str
    email: EmailStr
    telephone: str
    date_pret: date
    date_retour_prevue: date
    date_retour_effective: Optional[date] = None
    etat_retour: Optional[str] = None

    @model_validator(mode="after")
    def check_materiel_or_infrastructure(self):
        if not self.materiel_id and not self.infrastructure_id:
            raise ValueError("Un prêt doit concerner au moins un matériel ou une infrastructure.")
        return self

class PretCreate(PretBase):
    pass

class PretUpdate(BaseModel):
    date_retour_effective: Optional[date]
    etat_retour: Optional[str]

class PretOut(PretBase):
    pret_id: int
    created_at: Optional[datetime]
    updated_at: Optional[datetime]
    deleted_at: Optional[datetime]

    model_config = ConfigDict(from_attributes=True)
