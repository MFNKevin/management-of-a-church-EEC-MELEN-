from pydantic import BaseModel, EmailStr, ConfigDict
from typing import Optional
from datetime import date, datetime
from app.models.utilisateur import RoleEnum

class UtilisateurBase(BaseModel):
    photo: Optional[str]
    nom: Optional[str]
    prenom: Optional[str]
    dateNaissance: Optional[date]
    lieuNaissance: Optional[str]
    nationalite: Optional[str]
    villeResidence: Optional[str]
    email: Optional[EmailStr]
    profession: Optional[str]
    telephone: Optional[str]
    etatCivil: Optional[str]
    sexe: Optional[str]

class UtilisateurCreate(UtilisateurBase):
    role: RoleEnum
    mot_de_passe: str

class UtilisateurUpdate(BaseModel):
    nom: Optional[str]
    prenom: Optional[str]
    email: Optional[EmailStr]
    telephone: Optional[str]
    profession: Optional[str]
    villeResidence: Optional[str]
    nationalite: Optional[str]
    lieuNaissance: Optional[str]
    etatCivil: Optional[str]
    sexe: Optional[str]
    dateNaissance: Optional[date]
    role: Optional[RoleEnum]
    mot_de_passe: Optional[str]

class UtilisateurOut(UtilisateurBase):
    utilisateur_id: int
    role: RoleEnum
    deleted_at: Optional[datetime]

    model_config = ConfigDict(from_attributes=True)
