from sqlalchemy.orm import Session
from datetime import datetime
from app.models.infrastructure import Infrastructure
from app.schemas.infrastructure import InfrastructureCreate, InfrastructureUpdate
from sqlalchemy import or_

def create_infrastructure(db: Session, infra: InfrastructureCreate):
    db_infra = Infrastructure(**infra.dict())
    db.add(db_infra)
    db.commit()
    db.refresh(db_infra)
    return db_infra


def get_infrastructures(db: Session, include_deleted: bool = False):
    query = db.query(Infrastructure)
    if not include_deleted:
        query = query.filter(Infrastructure.deleted_at == None)
    return query.all()


def get_infrastructure(db: Session, infra_id: int, include_deleted: bool = False):
    query = db.query(Infrastructure).filter(Infrastructure.infrastructure_id == infra_id)
    if not include_deleted:
        query = query.filter(Infrastructure.deleted_at == None)
    return query.first()


def update_infrastructure(db: Session, infra_id: int, infra: InfrastructureUpdate):
    db_infra = db.query(Infrastructure).filter(Infrastructure.infrastructure_id == infra_id).first()
    if not db_infra:
        return None
    for field, value in infra.dict(exclude_unset=True).items():
        setattr(db_infra, field, value)
    db.commit()
    db.refresh(db_infra)
    return db_infra


def soft_delete_infrastructure(db: Session, infra_id: int):
    db_infra = db.query(Infrastructure).filter(Infrastructure.infrastructure_id == infra_id).first()
    if db_infra and db_infra.deleted_at is None:
        db_infra.deleted_at = datetime.utcnow()
        db.commit()
    return db_infra


def restore_infrastructure(db: Session, infra_id: int):
    db_infra = db.query(Infrastructure).filter(Infrastructure.infrastructure_id == infra_id).first()
    if db_infra and db_infra.deleted_at is not None:
        db_infra.deleted_at = None
        db.commit()
    return db_infra


def search_infrastructures(
    db: Session,
    query: str,
    skip: int = 0,
    limit: int = 50,
    include_deleted: bool = False
):
    q = db.query(Infrastructure)
    if not include_deleted:
        q = q.filter(Infrastructure.deleted_at == None)
    
    search_filter = or_(
        Infrastructure.nom.ilike(f"%{query}%"),
        Infrastructure.description.ilike(f"%{query}%")
    )
    q = q.filter(search_filter).order_by(Infrastructure.created_at.desc())
    return q.offset(skip).limit(limit).all()
