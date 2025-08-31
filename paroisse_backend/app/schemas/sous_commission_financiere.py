from pydantic import BaseModel, ConfigDict
from typing import Optional
from datetime import datetime

# Sous-commission
class SousCommissionBase(BaseModel):
    nom: str
    description: Optional[str]

class SousCommissionCreate(SousCommissionBase):
    pass

class SousCommissionOut(SousCommissionBase):
    sous_commission_id: int
    created_at: datetime
    deleted_at: Optional[datetime]

    model_config = ConfigDict(from_attributes=True)

# Membre de la sous-commission
class MembreSousCommissionBase(BaseModel):
    sous_commission_id: int
    utilisateur_id: int
    role: Optional[str] = None

class MembreSousCommissionCreate(MembreSousCommissionBase):
    pass

class MembreSousCommissionOut(MembreSousCommissionBase):
    membre_sous_commission_id: int
    created_at: datetime
    deleted_at: Optional[datetime]

    nom_utilisateur: Optional[str] = None
    prenom_utilisateur: Optional[str] = None
    nom_sous_commission: Optional[str] = None  # ✅ Ajout

    model_config = ConfigDict(from_attributes=True)
