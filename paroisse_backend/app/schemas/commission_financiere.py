from pydantic import BaseModel, ConfigDict
from typing import Optional
from datetime import datetime
from app.enums import RoleCommission

class CommissionBase(BaseModel):
    nom: str
    description: Optional[str]

class CommissionCreate(CommissionBase):
    pass

class CommissionOut(CommissionBase):
    commission_id: int
    created_at: datetime
    deleted_at: Optional[datetime]

    model_config = ConfigDict(from_attributes=True)

# ---- Membre Commission ----

class MembreCommissionBase(BaseModel):
    commission_id: int
    utilisateur_id: int
    role: Optional[RoleCommission] = RoleCommission.membre

class MembreCommissionCreate(MembreCommissionBase):
    pass

class MembreCommissionOut(MembreCommissionBase):
    membre_commission_id: int
    created_at: datetime
    deleted_at: Optional[datetime]

    nom_commission: Optional[str]           # nom de la commission
    nom_utilisateur: Optional[str]          # nom de l'utilisateur/membre
    prenom_utilisateur: Optional[str]       # prénom de l'utilisateur/membre

    model_config = ConfigDict(from_attributes=True)
