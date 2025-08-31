from sqlalchemy.orm import Session, joinedload
from datetime import datetime
from app.models.decision import Decision
from app.schemas.decision import DecisionCreate, DecisionUpdate

def create_decision(db: Session, data: DecisionCreate):
    db_dec = Decision(**data.dict())
    db.add(db_dec)
    db.commit()
    db.refresh(db_dec)
    return db_dec

def get_decisions(db: Session, include_deleted=False):
    q = db.query(Decision).options(
        joinedload(Decision.auteur),
        joinedload(Decision.reunion)
    )
    if not include_deleted:
        q = q.filter(Decision.deleted_at == None)
    return q.all()

def get_decision(db: Session, did: int, include_deleted=False):
    q = db.query(Decision).options(
        joinedload(Decision.auteur),
        joinedload(Decision.reunion)
    ).filter(Decision.decision_id == did)
    if not include_deleted:
        q = q.filter(Decision.deleted_at == None)
    return q.first()

def update_decision(db: Session, did: int, upd: DecisionUpdate):
    dec = get_decision(db, did, include_deleted=False)
    if not dec:
        return None
    for k, v in upd.dict(exclude_unset=True).items():
        setattr(dec, k, v)
    dec.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(dec)
    return dec

def soft_delete_decision(db: Session, did: int):
    dec = get_decision(db, did, include_deleted=False)
    if dec and not dec.deleted_at:
        dec.deleted_at = datetime.utcnow()
        db.commit()
    return dec

def restore_decision(db: Session, did: int):
    dec = get_decision(db, did, include_deleted=True)
    if dec and dec.deleted_at:
        dec.deleted_at = None
        db.commit()
        db.refresh(dec)
        return dec
    return None

def search_decisions(db: Session, query: str):
    return db.query(Decision)\
        .options(
            joinedload(Decision.auteur),
            joinedload(Decision.reunion)
        )\
        .filter(
            Decision.deleted_at == None,
            (Decision.titre.ilike(f"%{query}%") | Decision.description.ilike(f"%{query}%"))
        )\
        .order_by(Decision.created_at.desc())\
        .all()
