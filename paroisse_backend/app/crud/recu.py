from sqlalchemy import func
from sqlalchemy.orm import Session
from datetime import datetime
from app.models.recu import Recu
from app.schemas.recu import RecuCreate
from sqlalchemy import or_, cast, String

def create_recu(db: Session, recu: RecuCreate):
    db_recu = Recu(**recu.dict())
    db.add(db_recu)
    db.commit()
    db.refresh(db_recu)
    return db_recu

def get_recus(db: Session, include_deleted=False):
    query = db.query(Recu)
    if not include_deleted:
        query = query.filter(Recu.deleted_at == None)
    return query.all()

def get_recu(db: Session, recu_id: int, include_deleted=False):
    query = db.query(Recu).filter(Recu.recu_id == recu_id)
    if not include_deleted:
        query = query.filter(Recu.deleted_at == None)
    recu_instance = query.first()
    if not recu_instance:
        return None
    montant_total = db.query(func.coalesce(func.sum(Recu.montant), 0))\
        .filter(Recu.utilisateur_id == recu_instance.utilisateur_id, Recu.deleted_at == None).scalar()
    recu_instance.montant_total = montant_total
    return recu_instance

def soft_delete_recu(db: Session, recu_id: int):
    recu = db.query(Recu).filter(Recu.recu_id == recu_id).first()
    if recu and recu.deleted_at is None:
        recu.deleted_at = datetime.utcnow()
        db.commit()
    return recu

def restore_recu(db: Session, recu_id: int):
    recu = db.query(Recu).filter(Recu.recu_id == recu_id).first()
    if recu and recu.deleted_at is not None:
        recu.deleted_at = None
        db.commit()
    return recu


from sqlalchemy import or_, cast, String, func

def search_recus(db: Session, keyword: str, include_deleted: bool = False):
    keyword_like = f"%{keyword}%"
    query = db.query(Recu)

    if not include_deleted:
        query = query.filter(Recu.deleted_at == None)

    query = query.filter(
        or_(
            Recu.description.ilike(keyword_like),
            cast(Recu.montant, String).ilike(keyword_like),
            cast(Recu.date_emission, String).ilike(keyword_like),
            cast(Recu.utilisateur_id, String).ilike(keyword_like)
        )
    )

    results = query.order_by(Recu.date_emission.desc()).all()

    montant_total = db.query(func.coalesce(func.sum(Recu.montant), 0))
    if not include_deleted:
        montant_total = montant_total.filter(Recu.deleted_at == None)
    total = montant_total.scalar()

    for r in results:
        r.montant_total = total

    return results
