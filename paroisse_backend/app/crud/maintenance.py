from sqlalchemy.orm import Session
from datetime import datetime
from app.models.maintenance import Maintenance
from app.schemas.maintenance import MaintenanceCreate, MaintenanceUpdate
from sqlalchemy import or_

def create_maintenance(db: Session, maintenance: MaintenanceCreate):
    db_obj = Maintenance(**maintenance.dict())
    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)
    return db_obj

def get_maintenances(db: Session, include_deleted=False):
    query = db.query(Maintenance)
    if not include_deleted:
        query = query.filter(Maintenance.deleted_at == None)
    return query.all()

def get_maintenance(db: Session, maintenance_id: int):
    return db.query(Maintenance).filter(Maintenance.maintenance_id == maintenance_id).first()

def update_maintenance(db: Session, maintenance_id: int, data: MaintenanceUpdate):
    obj = db.query(Maintenance).filter(Maintenance.maintenance_id == maintenance_id).first()
    if not obj:
        return None
    for field, value in data.dict(exclude_unset=True).items():
        setattr(obj, field, value)
    db.commit()
    db.refresh(obj)
    return obj

def soft_delete_maintenance(db: Session, maintenance_id: int):
    obj = db.query(Maintenance).filter(Maintenance.maintenance_id == maintenance_id).first()
    if obj and not obj.deleted_at:
        obj.deleted_at = datetime.utcnow()
        db.commit()
    return obj

def restore_maintenance(db: Session, maintenance_id: int):
    obj = db.query(Maintenance).filter(Maintenance.maintenance_id == maintenance_id).first()
    if obj and obj.deleted_at:
        obj.deleted_at = None
        db.commit()
    return obj


from sqlalchemy import or_, cast, String

def search_maintenances(
    db: Session,
    query: str,
    skip: int = 0,
    limit: int = 50,
    include_deleted: bool = False
):
    q = db.query(Maintenance)

    if not include_deleted:
        q = q.filter(Maintenance.deleted_at == None)

    search_filter = or_(
        Maintenance.description.ilike(f"%{query}%"),
        cast(Maintenance.cout, String).ilike(f"%{query}%"),
        cast(Maintenance.date_maintenance, String).ilike(f"%{query}%")
    )

    q = q.filter(search_filter).order_by(Maintenance.date_maintenance.desc())

    return q.offset(skip).limit(limit).all()
