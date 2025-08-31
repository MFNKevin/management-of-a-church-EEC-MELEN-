import os
from datetime import date
from typing import List, Optional

from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    Query,
    Path,
    UploadFile,
    File,
    Form,
)
from sqlalchemy.orm import Session

from app.schemas.utilisateur import UtilisateurCreate, UtilisateurOut
from app.crud import utilisateur as crud_utilisateur
from app.database import get_db
from app.utils.security import get_current_user, hash_password
from app.models.utilisateur import Utilisateur, RoleEnum
from app.permissions.utilisateur import ALLOWED_ROLES_UTILISATEUR

router = APIRouter()


# Vérifie les permissions du rôle
def check_role(current_user: Utilisateur):
    if current_user.role not in ALLOWED_ROLES_UTILISATEUR:
        raise HTTPException(status_code=403, detail=f"Permission refusée pour le rôle {current_user.role}")


# Création d’un utilisateur
@router.post("/", response_model=UtilisateurOut)
def create_utilisateur(
    utilisateur: UtilisateurCreate,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(get_current_user)
):
    check_role(current_user)
    return crud_utilisateur.create_utilisateur(db, utilisateur)


# Récupération du profil connecté
@router.get("/me", response_model=UtilisateurOut)
def get_my_profile(
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(get_current_user)
):
    return current_user


# Liste des utilisateurs
@router.get("/", response_model=List[UtilisateurOut])
def list_utilisateurs(
    skip: int = 0,
    limit: int = 100,
    include_deleted: bool = False,
    search: Optional[str] = Query(None, description="Recherche par nom ou prénom"),
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(get_current_user)
):
    check_role(current_user)
    return crud_utilisateur.get_utilisateurs(db, skip, limit, include_deleted, search)


# Mise à jour d’un utilisateur (avec ou sans image)
@router.put("/update/{utilisateur_id}", response_model=UtilisateurOut)
async def update_utilisateur(
    utilisateur_id: int = Path(..., description="ID de l'utilisateur à modifier"),
    nom: Optional[str] = Form(None),
    prenom: Optional[str] = Form(None),
    email: Optional[str] = Form(None),
    telephone: Optional[str] = Form(None),
    profession: Optional[str] = Form(None),
    villeResidence: Optional[str] = Form(None),
    nationalite: Optional[str] = Form(None),
    lieuNaissance: Optional[str] = Form(None),
    etatCivil: Optional[str] = Form(None),
    sexe: Optional[str] = Form(None),
    dateNaissance: Optional[str] = Form(None),
    role: Optional[str] = Form(None),
    mot_de_passe: Optional[str] = Form(None),
    photo: Optional[UploadFile] = File(None),
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(get_current_user)
):
    check_role(current_user)

    utilisateur = db.query(Utilisateur).filter(
        Utilisateur.utilisateur_id == utilisateur_id,
        Utilisateur.deleted_at == None
    ).first()

    if not utilisateur:
        raise HTTPException(status_code=404, detail="Utilisateur non trouvé")

    update_data = {}

    if nom is not None:
        update_data["nom"] = nom
    if prenom is not None:
        update_data["prenom"] = prenom
    if email is not None:
        update_data["email"] = email
    if telephone is not None:
        update_data["telephone"] = telephone
    if profession is not None:
        update_data["profession"] = profession
    if villeResidence is not None:
        update_data["villeResidence"] = villeResidence
    if nationalite is not None:
        update_data["nationalite"] = nationalite
    if lieuNaissance is not None:
        update_data["lieuNaissance"] = lieuNaissance
    if etatCivil is not None:
        update_data["etatCivil"] = etatCivil
    if sexe is not None:
        update_data["sexe"] = sexe
    if dateNaissance:
        try:
            update_data["dateNaissance"] = date.fromisoformat(dateNaissance)
        except Exception:
            raise HTTPException(status_code=400, detail="dateNaissance invalide")
    if role is not None:
        try:
            update_data["role"] = RoleEnum(role)
        except Exception:
            raise HTTPException(status_code=400, detail="role invalide")
    if mot_de_passe is not None:
        update_data["mot_de_passe"] = hash_password(mot_de_passe)

    # Gestion de la photo
    if photo is not None:
        try:
            os.makedirs("photos", exist_ok=True)
            contenu = await photo.read()
            nom_fichier = f"{utilisateur_id}_{photo.filename}"
            chemin = os.path.join("photos", nom_fichier)
            with open(chemin, "wb") as f:
                f.write(contenu)
            update_data["photo"] = chemin
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Erreur enregistrement image : {str(e)}")

    for key, value in update_data.items():
        setattr(utilisateur, key, value)

    db.commit()
    db.refresh(utilisateur)
    return utilisateur


# Suppression (corbeille) d’un utilisateur
@router.delete("/{utilisateur_id}")
def soft_delete_utilisateur(
    utilisateur_id: int,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(get_current_user)
):
    check_role(current_user)
    utilisateur = crud_utilisateur.soft_delete_utilisateur(db, utilisateur_id)
    if not utilisateur:
        raise HTTPException(status_code=404, detail="Utilisateur non trouvé")
    return {"message": "Utilisateur mis dans la corbeille"}


# Restauration d’un utilisateur supprimé
@router.put("/restore/{utilisateur_id}")
def restore_utilisateur(
    utilisateur_id: int,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(get_current_user)
):
    check_role(current_user)
    utilisateur = crud_utilisateur.restore_utilisateur(db, utilisateur_id)
    if not utilisateur:
        raise HTTPException(status_code=404, detail="Utilisateur non trouvé ou pas supprimé")
    return {"message": "Utilisateur restauré"}

@router.get("/email-exists")
def email_exists(email: str, db: Session = Depends(get_db)):
    utilisateur = crud_utilisateur.get_utilisateur_by_email(db, email)
    return {"exists": utilisateur is not None}
