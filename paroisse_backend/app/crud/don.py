from sqlalchemy.orm import Session
from sqlalchemy import String, func
from datetime import datetime
from app import models, schemas
from app.models.notification import Notification, TypeNotificationEnum
from app.models.don import Don
from app.schemas.don import DonCreate, DonUpdate, TypeDonEnum, DonOut
from app.utils.budget import update_budget_reel
from app.utils.recu import generate_recu


def create_don(db: Session, don: DonCreate, utilisateur_id: int):
    date_don = don.date_don or datetime.utcnow()
    assert isinstance(date_don, datetime)

    db_don = models.Don(
        donateur=don.donateur,
        montant=don.montant,
        type=don.type.value if isinstance(don.type, TypeDonEnum) else don.type,
        date_don=date_don,
        commentaire=don.commentaire,
        utilisateur_id=utilisateur_id
    )

    db.add(db_don)

    try:
        db.flush()

        generate_recu(
            db=db,
            montant=don.montant,
            source="Don",
            reference_id=db_don.don_id,
            utilisateur_id=utilisateur_id
        )

        update_budget_reel(
            session=db,
            annee=date_don.year,
            intitule="Don",
            utilisateur_id=utilisateur_id
        )

        notification = Notification(
            titre="Don enregistré",
            message=f"Don de {don.montant} FCFA de {don.donateur} enregistré avec succès.",
            type=TypeNotificationEnum.success,
            utilisateur_id=utilisateur_id
        )
        db.add(notification)
        db.commit()

    except Exception as e:
        db.rollback()
        raise Exception(f"Erreur Don : {str(e)}")

    db.refresh(db_don)
    return db_don


def update_don(db: Session, don_id: int, don_update: DonUpdate):
    db_don = db.query(Don).filter(Don.don_id == don_id, Don.deleted_at == None).first()
    if not db_don:
        return None

    for var, value in don_update.dict(exclude_unset=True).items():
        if var == "type" and isinstance(value, TypeDonEnum):
            value = value.value
        setattr(db_don, var, value)

    try:
        db.commit()

        assert isinstance(db_don.date_don, datetime)
        update_budget_reel(
            session=db,
            annee=db_don.date_don.year,
            intitule="Don",
            utilisateur_id=db_don.utilisateur_id
        )
    except Exception as e:
        db.rollback()
        raise Exception(f"Erreur mise à jour budget après modification Don : {str(e)}")

    db.refresh(db_don)
    return db_don


def soft_delete_don(db: Session, don_id: int):
    don = db.query(Don).filter(Don.don_id == don_id, Don.deleted_at == None).first()
    if not don:
        return None

    try:
        don.deleted_at = datetime.utcnow()
        db.commit()

        assert isinstance(don.date_don, datetime)
        update_budget_reel(
            session=db,
            annee=don.date_don.year,
            intitule="Don",
            utilisateur_id=don.utilisateur_id
        )
    except Exception as e:
        db.rollback()
        raise Exception(f"Erreur suppression logique Don : {str(e)}")

    return don


def restore_don(db: Session, don_id: int):
    don = db.query(Don).filter(Don.don_id == don_id, Don.deleted_at != None).first()
    if not don:
        return None

    try:
        don.deleted_at = None
        db.commit()

        assert isinstance(don.date_don, datetime)
        update_budget_reel(
            session=db,
            annee=don.date_don.year,
            intitule="Don",
            utilisateur_id=don.utilisateur_id
        )
    except Exception as e:
        db.rollback()
        raise Exception(f"Erreur restauration Don : {str(e)}")

    return don


def get_dons(db: Session, skip: int = 0, limit: int = 10, include_deleted: bool = False):
    query = db.query(Don)
    if not include_deleted:
        query = query.filter(Don.deleted_at == None)
    dons = query.offset(skip).limit(limit).all()

    montant_total = db.query(func.coalesce(func.sum(Don.montant), 0))\
        .filter(Don.deleted_at == None if not include_deleted else True).scalar()

    dons_out = []
    for d in dons:
        d.montant_total = montant_total  # champ temporaire injecté dans l’objet
        dons_out.append(DonOut.from_orm(d))

    return dons_out


def get_don(db: Session, don_id: int, include_deleted: bool = False):
    query = db.query(Don).filter(Don.don_id == don_id)
    if not include_deleted:
        query = query.filter(Don.deleted_at == None)
    don_instance = query.first()
    if not don_instance:
        return None

    montant_total = db.query(func.coalesce(func.sum(Don.montant), 0))\
        .filter(Don.utilisateur_id == don_instance.utilisateur_id, Don.deleted_at == None).scalar()

    don_instance.montant_total = montant_total
    return DonOut.from_orm(don_instance)


def search_dons(db: Session, query: str, include_deleted: bool = False):
    q = db.query(Don)
    if not include_deleted:
        q = q.filter(Don.deleted_at == None)

    q = q.filter(
        (Don.donateur.ilike(f"%{query}%")) |   # ✅ ajout de donateur dans la recherche
        (Don.type.ilike(f"%{query}%")) |
        (func.cast(Don.montant, String).ilike(f"%{query}%")) |
        (func.cast(Don.date_don, String).ilike(f"%{query}%"))
    )

    return q.order_by(Don.date_don.desc()).all()
