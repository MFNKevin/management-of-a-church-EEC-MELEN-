from sqlalchemy.orm import Session
from datetime import datetime
from app.models.materiel import Materiel
from app.schemas.materiel import MaterielCreate, MaterielUpdate
from sqlalchemy import or_, String  # String pour le cast

def create_materiel(db: Session, materiel: MaterielCreate):
    db_materiel = Materiel(**materiel.dict())
    db.add(db_materiel)
    db.commit()
    db.refresh(db_materiel)
    return db_materiel

def get_materiels(db: Session, include_deleted: bool = False):
    query = db.query(Materiel)
    if not include_deleted:
        query = query.filter(Materiel.deleted_at.is_(None))
    return query.all()

def get_materiel(db: Session, materiel_id: int, include_deleted: bool = False):
    query = db.query(Materiel).filter(Materiel.materiel_id == materiel_id)
    if not include_deleted:
        query = query.filter(Materiel.deleted_at.is_(None))
    return query.first()

def update_materiel(db: Session, materiel_id: int, materiel: MaterielUpdate):
    db_materiel = db.query(Materiel).filter(Materiel.materiel_id == materiel_id).first()
    if not db_materiel:
        return None
    for field, value in materiel.dict(exclude_unset=True).items():
        setattr(db_materiel, field, value)
    db.commit()
    db.refresh(db_materiel)
    return db_materiel

def soft_delete_materiel(db: Session, materiel_id: int):
    db_materiel = db.query(Materiel).filter(Materiel.materiel_id == materiel_id).first()
    if db_materiel and db_materiel.deleted_at is None:
        db_materiel.deleted_at = datetime.utcnow()
        db.commit()
    return db_materiel

def restore_materiel(db: Session, materiel_id: int):
    db_materiel = db.query(Materiel).filter(Materiel.materiel_id == materiel_id).first()
    if db_materiel and db_materiel.deleted_at is not None:
        db_materiel.deleted_at = None
        db.commit()
    return db_materiel

def search_materiels(db: Session, query: str, skip: int = 0, limit: int = 50, include_deleted: bool = False):
    q = db.query(Materiel)
    if not include_deleted:
        q = q.filter(Materiel.deleted_at.is_(None))

    search_filter = or_(
        Materiel.nom.ilike(f"%{query}%"),
        Materiel.description.ilike(f"%{query}%"),
        Materiel.date_acquisition.cast(String).ilike(f"%{query}%")
    )

    q = q.filter(search_filter).order_by(Materiel.date_acquisition.desc())
    return q.offset(skip).limit(limit).all()
