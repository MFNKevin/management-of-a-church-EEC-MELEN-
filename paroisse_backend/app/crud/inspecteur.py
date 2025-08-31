from sqlalchemy.orm import Session
from datetime import datetime
from app.models.inspecteur import Inspecteur
from app.schemas.inspecteur import InspecteurCreate, InspecteurUpdate
from sqlalchemy import or_

def create_inspecteur(db: Session, data: InspecteurCreate):
    obj = Inspecteur(**data.dict())
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj

def get_inspecteurs(db: Session, include_deleted=False):
    query = db.query(Inspecteur)
    if not include_deleted:
        query = query.filter(Inspecteur.deleted_at == None)
    return query.all()

def get_inspecteur(db: Session, inspecteur_id: int):
    return db.query(Inspecteur).filter(Inspecteur.inspecteur_id == inspecteur_id).first()

def update_inspecteur(db: Session, inspecteur_id: int, data: InspecteurUpdate):
    obj = db.query(Inspecteur).filter(Inspecteur.inspecteur_id == inspecteur_id).first()
    if not obj:
        return None
    for field, value in data.dict(exclude_unset=True).items():
        setattr(obj, field, value)
    db.commit()
    db.refresh(obj)
    return obj

def soft_delete_inspecteur(db: Session, inspecteur_id: int):
    obj = db.query(Inspecteur).filter(Inspecteur.inspecteur_id == inspecteur_id).first()
    if obj and obj.deleted_at is None:
        obj.deleted_at = datetime.utcnow()
        db.commit()
    return obj

def restore_inspecteur(db: Session, inspecteur_id: int):
    obj = db.query(Inspecteur).filter(Inspecteur.inspecteur_id == inspecteur_id).first()
    if obj and obj.deleted_at is not None:
        obj.deleted_at = None
        db.commit()
    return obj

def search_inspecteurs(
    db: Session,
    query: str,
    skip: int = 0,
    limit: int = 50,
    include_deleted: bool = False
):
    q = db.query(Inspecteur)
    if not include_deleted:
        q = q.filter(Inspecteur.deleted_at == None)

    search_filter = or_(
        Inspecteur.nom.ilike(f"%{query}%"),
        Inspecteur.prenom.ilike(f"%{query}%"),
        Inspecteur.email.ilike(f"%{query}%")  # si tu as un champ email ou autre pertinent
    )
    q = q.filter(search_filter).order_by(Inspecteur.nom.asc())
    return q.offset(skip).limit(limit).all()
