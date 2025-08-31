from sqlalchemy.orm import Session
from sqlalchemy import or_, cast, String
from datetime import datetime
from app.models.reunion import Reunion
from app.schemas.reunion import ReunionCreate, ReunionUpdate


def create_reunion(db: Session, data: ReunionCreate) -> Reunion:
    db_reu = Reunion(
        titre=data.titre,
        date=data.date,
        lieu=data.lieu,
        description=data.description,
        convocateur_role=data.convocateur_role,
        convoques=data.convoques
    )
    db.add(db_reu)
    db.commit()
    db.refresh(db_reu)
    return db_reu


def get_reunions(db: Session, include_deleted=False) -> list[Reunion]:
    q = db.query(Reunion)
    if not include_deleted:
        q = q.filter(Reunion.deleted_at.is_(None))
    return q.all()


def get_reunion(db: Session, reunion_id: int) -> Reunion | None:
    return db.query(Reunion).filter(Reunion.reunion_id == reunion_id).first()


def update_reunion(db: Session, rid: int, upd: ReunionUpdate) -> Reunion | None:
    reu = get_reunion(db, rid)
    if not reu:
        return None

    for k, v in upd.dict(exclude_unset=True).items():
        setattr(reu, k, v)
    # updated_at sera mis à jour automatiquement par SQLAlchemy onupdate=func.now()

    db.commit()
    db.refresh(reu)
    return reu


def soft_delete_reunion(db: Session, rid: int) -> Reunion | None:
    reu = get_reunion(db, rid)
    if reu and reu.deleted_at is None:
        reu.deleted_at = datetime.utcnow()
        db.commit()
    return reu


def restore_reunion(db: Session, reunion_id: int) -> Reunion | None:
    reunion = get_reunion(db, reunion_id)
    if reunion and reunion.deleted_at is not None:
        reunion.deleted_at = None
        db.commit()
    return reunion


def search_reunions(db: Session, keyword: str, include_deleted: bool = False) -> list[Reunion]:
    keyword_like = f"%{keyword}%"
    query = db.query(Reunion)
    if not include_deleted:
        query = query.filter(Reunion.deleted_at.is_(None))

    query = query.filter(
        or_(
            Reunion.titre.ilike(keyword_like),
            Reunion.lieu.ilike(keyword_like),
            Reunion.description.ilike(keyword_like),
            cast(Reunion.convocateur_role, String).ilike(keyword_like),
            cast(Reunion.date, String).ilike(keyword_like),
        )
    )
    return query.order_by(Reunion.date.desc()).all()
