from pydantic import BaseModel, ConfigDict
from typing import Optional
from datetime import datetime
import enum

class TypeMouvementStockEnum(str, enum.Enum):
    entree = "entrée"
    sortie = "sortie"

class StockMaterielBase(BaseModel):
    materiel_id: int
    quantite: int
    type_mouvement: TypeMouvementStockEnum
    description: Optional[str]

class StockMaterielCreate(StockMaterielBase):
    pass

class StockMaterielOut(StockMaterielBase):
    stock_id: int
    date_mouvement: datetime

    model_config = ConfigDict(from_attributes=True)

class StockMaterielResponse(BaseModel):
    stock_mouvement: StockMaterielOut
    message: str
