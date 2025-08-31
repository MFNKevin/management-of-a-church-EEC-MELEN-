from pydantic import BaseModel, validator
from typing import List, Optional
from datetime import datetime
from enum import Enum


class ConvocateurEnum(str, Enum):
    Pasteur = "Pasteur"
    Evangeliste = "Evangeliste"
    ResponsableLaique = "ResponsableLaique"
    Secretaire = "Secretaire"
    Fidele = "Fidele"


class ReunionBase(BaseModel):
    titre: str
    date: datetime
    lieu: Optional[str] = None
    description: Optional[str] = None
    convocateur_role: ConvocateurEnum
    convoques: List[int]

    @validator("convoques")
    def validate_convoques(cls, v):
        if not isinstance(v, list) or not all(isinstance(i, int) for i in v):
            raise ValueError("Le champ 'convoques' doit être une liste d'entiers")
        return v


class ReunionCreate(ReunionBase):
    pass


class ReunionUpdate(BaseModel):
    titre: Optional[str] = None
    date: Optional[datetime] = None
    lieu: Optional[str] = None
    description: Optional[str] = None
    convocateur_role: Optional[ConvocateurEnum] = None
    convoques: Optional[List[int]] = None

    @validator("convoques")
    def validate_convoques(cls, v):
        if v is not None:
            if not isinstance(v, list) or not all(isinstance(i, int) for i in v):
                raise ValueError("Le champ 'convoques' doit être une liste d'entiers")
        return v


class ReunionOut(ReunionBase):
    reunion_id: int
    deleted_at: Optional[datetime] = None

    class Config:
        orm_mode = True
