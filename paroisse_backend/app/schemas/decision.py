from pydantic import BaseModel, ConfigDict
from typing import Optional
from datetime import datetime

class DecisionBase(BaseModel):
    titre: str
    description: Optional[str]
    reunion_id: int
    auteur_id: int

class DecisionCreate(DecisionBase):
    pass

class DecisionUpdate(BaseModel):
    titre: Optional[str]
    description: Optional[str]
    reunion_id: Optional[int]
    auteur_id: Optional[int]
    date_valide: Optional[datetime]

class DecisionOut(DecisionBase):
    decision_id: int
    date_valide: Optional[datetime]
    deleted_at: Optional[datetime]

    # Champs issus de la relation auteur (Utilisateur)
    titre_reunion: Optional[str] = None
    nom_auteur: Optional[str] = None
    prenom_auteur: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)
