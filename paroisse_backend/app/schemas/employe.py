from pydantic import BaseModel, Field, ConfigDict
from typing import Optional
from datetime import date, datetime

class EmployeBase(BaseModel):
    nom: str
    prenom: Optional[str]
    poste: Optional[str]
    date_naissance: Optional[date]
    date_embauche: Optional[date]
    salaire: float = Field(..., ge=0, description="Salaire doit être positif")
    groupe_id: Optional[int]

class EmployeCreate(EmployeBase):
    pass

class EmployeUpdate(EmployeBase):
    pass

class EmployeOut(EmployeBase):
    employe_id: int
    deleted_at: Optional[datetime]

    model_config = ConfigDict(from_attributes=True)
