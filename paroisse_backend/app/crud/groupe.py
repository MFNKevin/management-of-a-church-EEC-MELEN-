from sqlalchemy.orm import Session
from datetime import datetime
from app.models.groupe import Groupe
from app.schemas.groupe import GroupeCreate, GroupeUpdate
from sqlalchemy import or_

def create_groupe(db: Session, groupe: GroupeCreate):
    db_groupe = Groupe(**groupe.dict())
    db.add(db_groupe)
    db.commit()
    db.refresh(db_groupe)
    return db_groupe

def get_groupes(db: Session, include_deleted=False):
    query = db.query(Groupe)
    if not include_deleted:
        query = query.filter(Groupe.deleted_at == None)
    return query.all()

def get_groupe(db: Session, groupe_id: int, include_deleted=False):
    query = db.query(Groupe).filter(Groupe.groupe_id == groupe_id)
    if not include_deleted:
        query = query.filter(Groupe.deleted_at == None)
    return query.first()

def update_groupe(db: Session, groupe_id: int, groupe: GroupeUpdate):
    db_groupe = db.query(Groupe).filter(Groupe.groupe_id == groupe_id, Groupe.deleted_at == None).first()
    if db_groupe:
        for key, value in groupe.dict().items():
            setattr(db_groupe, key, value)
        db.commit()
        db.refresh(db_groupe)
    return db_groupe

def soft_delete_groupe(db: Session, groupe_id: int):
    db_groupe = db.query(Groupe).filter(Groupe.groupe_id == groupe_id).first()
    if db_groupe and db_groupe.deleted_at is None:
        db_groupe.deleted_at = datetime.utcnow()
        db.commit()
    return db_groupe

def restore_groupe(db: Session, groupe_id: int):
    db_groupe = db.query(Groupe).filter(Groupe.groupe_id == groupe_id).first()
    if db_groupe and db_groupe.deleted_at is not None:
        db_groupe.deleted_at = None
        db.commit()
    return db_groupe


def search_groupes(db: Session, query: str, skip: int = 0, limit: int = 50, include_deleted: bool = False):
    q = db.query(Groupe)
    if not include_deleted:
        q = q.filter(Groupe.deleted_at == None)

    search_filter = or_(
        Groupe.nom.ilike(f"%{query}%"),
        Groupe.description.ilike(f"%{query}%")
    )
    q = q.filter(search_filter).order_by(Groupe.created_at.desc())
    return q.offset(skip).limit(limit).all()
