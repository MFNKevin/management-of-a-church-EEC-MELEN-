from pydantic import BaseModel, ConfigDict
from typing import Optional
from datetime import datetime

class BudgetBase(BaseModel):
    intitule: str
    annee: int
    montantTotal: float
    montantApprouve: Optional[float]
    statut: Optional[str]
    utilisateur_id: int
    sous_categorie: str
    categorie: str

class BudgetCreate(BudgetBase):
    pass

class BudgetUpdate(BaseModel):
    intitule: Optional[str]
    montantTotal: Optional[float]
    montantApprouve: Optional[float]
    statut: Optional[str]
    utilisateur_id: Optional[int]
    categorie: Optional[str]
    sous_categorie: Optional[str]

class BudgetOut(BudgetBase):
    budget_id: int
    dateSoumission: datetime
    deleted_at: Optional[datetime]

    model_config = ConfigDict(from_attributes=True)
