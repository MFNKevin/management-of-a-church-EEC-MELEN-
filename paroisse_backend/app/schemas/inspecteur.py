from pydantic import BaseModel, EmailStr, ConfigDict
from typing import Optional
from datetime import datetime

class InspecteurBase(BaseModel):
    nom: str
    prenom: Optional[str]
    email: Optional[EmailStr]
    telephone: Optional[str]
    fonction: Optional[str]

class InspecteurCreate(InspecteurBase):
    pass

class InspecteurUpdate(InspecteurBase):
    pass

class InspecteurOut(InspecteurBase):
    inspecteur_id: int
    created_at: datetime
    deleted_at: Optional[datetime]

    model_config = ConfigDict(from_attributes=True)
