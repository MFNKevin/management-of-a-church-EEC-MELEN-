import enum
from pydantic import BaseModel, ConfigDict
from typing import Optional
from datetime import datetime


class TypeDonEnum(str, enum.Enum):
    espece = "espèce"
    mobile = "mobile"
    cheque = "chèque"


class DonBase(BaseModel):
    donateur: str                     # ✅ Ajouté
    montant: float
    type: TypeDonEnum
    date_don: Optional[datetime] = None
    commentaire: Optional[str] = None  # ✅ Ajouté
    utilisateur_id: int


class DonCreate(DonBase):
    pass


class DonUpdate(BaseModel):
    donateur: Optional[str] = None         # ✅ pour mise à jour
    montant: Optional[float] = None
    type: Optional[TypeDonEnum] = None
    date_don: Optional[datetime] = None
    commentaire: Optional[str] = None


class DonOut(DonBase):
    don_id: int
    montant_total: Optional[float] = None   # ✅ Aligné avec Dart (nullable)
    deleted_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)
    # Pour Pydantic v1.x, utilisez plutôt:
    # class Config:
    #     orm_mode = True
