from sqlalchemy.orm import Session
from datetime import datetime
from fastapi import HTTPException
from app.models.employe import Employe
from app.models.groupe import Groupe
from app.schemas.employe import EmployeCreate, EmployeUpdate
from sqlalchemy import and_, or_


def create_employe(db: Session, employe: EmployeCreate):
    # Vérifier que le groupe existe s'il est fourni
    if employe.groupe_id is not None:
        groupe = db.query(Groupe).filter(Groupe.groupe_id == employe.groupe_id).first()
        if not groupe:
            raise HTTPException(
                status_code=400,
                detail=f"Le groupe avec l'ID {employe.groupe_id} n'existe pas."
            )

    db_employe = Employe(**employe.dict())
    db.add(db_employe)
    db.commit()
    db.refresh(db_employe)
    return db_employe


def get_employes(db: Session, include_deleted=False):
    query = db.query(Employe)
    if not include_deleted:
        query = query.filter(Employe.deleted_at == None)
    return query.all()


def get_employe(db: Session, employe_id: int, include_deleted=False):
    query = db.query(Employe).filter(Employe.employe_id == employe_id)
    if not include_deleted:
        query = query.filter(Employe.deleted_at == None)
    return query.first()


def update_employe(db: Session, employe_id: int, update_data: EmployeUpdate):
    employe = db.query(Employe).filter(Employe.employe_id == employe_id).first()
    if not employe:
        return None

    update_dict = update_data.dict(exclude_unset=True)

    # Si groupe_id est mis à jour, on vérifie qu'il existe
    if "groupe_id" in update_dict and update_dict["groupe_id"] is not None:
        groupe = db.query(Groupe).filter(Groupe.groupe_id == update_dict["groupe_id"]).first()
        if not groupe:
            raise HTTPException(
                status_code=400,
                detail=f"Le groupe avec l'ID {update_dict['groupe_id']} n'existe pas."
            )

    for field, value in update_dict.items():
        setattr(employe, field, value)

    employe.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(employe)
    return employe


def soft_delete_employe(db: Session, employe_id: int):
    employe = db.query(Employe).filter(Employe.employe_id == employe_id).first()
    if employe and employe.deleted_at is None:
        employe.deleted_at = datetime.utcnow()
        db.commit()
    return employe


def restore_employe(db: Session, employe_id: int):
    employe = db.query(Employe).filter(Employe.employe_id == employe_id).first()
    if employe and employe.deleted_at is not None:
        employe.deleted_at = None
        db.commit()
    return employe


def search_employes(db: Session, query: str, skip: int = 0, limit: int = 10):
    return db.query(Employe).filter(
        and_(
            Employe.deleted_at == None,
            or_(
                Employe.nom.ilike(f"%{query}%"),
                Employe.poste.ilike(f"%{query}%")
            )
        )
    ).order_by(Employe.nom.asc()).offset(skip).limit(limit).all()
