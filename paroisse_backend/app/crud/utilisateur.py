from fastapi import Body
from sqlalchemy.orm import Session
from sqlalchemy import or_
from datetime import datetime
from app.models.utilisateur import Utilisateur
from app.schemas.utilisateur import UtilisateurCreate, UtilisateurUpdate
from app.utils.security import hash_password

def create_utilisateur(db: Session, utilisateur: UtilisateurCreate):
    hashed_pwd = hash_password(utilisateur.mot_de_passe)
    db_utilisateur = Utilisateur(**utilisateur.dict(exclude={"mot_de_passe"}), mot_de_passe=hashed_pwd)
    db.add(db_utilisateur)
    db.commit()
    db.refresh(db_utilisateur)
    return db_utilisateur

def get_utilisateurs(
    db: Session, 
    skip: int = 0, 
    limit: int = 100, 
    include_deleted: bool = False, 
    search: str | None = None
):
    query = db.query(Utilisateur)
    if not include_deleted:
        query = query.filter(Utilisateur.deleted_at == None)
    if search:
        search_term = f"%{search}%"
        query = query.filter(
            or_(
                Utilisateur.nom.ilike(search_term),
                Utilisateur.prenom.ilike(search_term)
            )
        )
    return query.offset(skip).limit(limit).all()

def get_utilisateur(db: Session, utilisateur_id: int, include_deleted: bool = False):
    query = db.query(Utilisateur).filter(Utilisateur.utilisateur_id == utilisateur_id)
    if not include_deleted:
        query = query.filter(Utilisateur.deleted_at == None)
    return query.first()


def get_utilisateur_update(utilisateur_update: UtilisateurUpdate = Body(...)):
    return utilisateur_update

def update_utilisateur(db: Session, utilisateur_id: int, utilisateur_update: UtilisateurUpdate):
    utilisateur = db.query(Utilisateur).filter(
        Utilisateur.utilisateur_id == utilisateur_id,
        Utilisateur.deleted_at == None
    ).first()

    if not utilisateur:
        return None

    # Hasher le mot de passe s'il est fourni
    if utilisateur_update.mot_de_passe:
        utilisateur.mot_de_passe = hash_password(utilisateur_update.mot_de_passe)

    # Mettre à jour les autres champs sauf mot_de_passe
    update_data = utilisateur_update.model_dump(exclude_unset=True, exclude={"mot_de_passe"})
    for key, value in update_data.items():
        setattr(utilisateur, key, value)

    db.commit()
    db.refresh(utilisateur)
    return utilisateur


def soft_delete_utilisateur(db: Session, utilisateur_id: int):
    utilisateur = db.query(Utilisateur).filter(Utilisateur.utilisateur_id == utilisateur_id).first()
    if utilisateur and utilisateur.deleted_at is None:
        utilisateur.deleted_at = datetime.utcnow()
        db.commit()
    return utilisateur

def restore_utilisateur(db: Session, utilisateur_id: int):
    utilisateur = db.query(Utilisateur).filter(Utilisateur.utilisateur_id == utilisateur_id).first()
    if utilisateur and utilisateur.deleted_at is not None:
        utilisateur.deleted_at = None
        db.commit()
    return utilisateur

def get_utilisateur_by_email(db: Session, email: str):
    return db.query(Utilisateur).filter(Utilisateur.email == email, Utilisateur.deleted_at == None).first()
