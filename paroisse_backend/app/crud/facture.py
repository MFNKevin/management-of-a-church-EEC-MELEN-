from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import datetime
from app.models.facture import Facture
from app.models.achat import Achat
from app.schemas.facture import FactureCreate, FactureUpdate
from typing import List, Optional
from sqlalchemy import or_

def create_facture(db: Session, facture: FactureCreate):
    db_facture = Facture(
        numero=facture.numero,
        montant=facture.montant,
        date_facture=facture.date_facture or datetime.utcnow(),
        description=facture.description,
        utilisateur_id=facture.utilisateur_id
    )
    db.add(db_facture)
    db.commit()
    db.refresh(db_facture)
    return db_facture


def get_factures(db: Session, include_deleted=False, skip: int = 0, limit: int = 100):
    query = db.query(Facture)
    if not include_deleted:
        query = query.filter(Facture.deleted_at == None)
    factures = query.offset(skip).limit(limit).all()

    montant_total = db.query(func.coalesce(func.sum(Facture.montant), 0))\
        .filter(Facture.deleted_at == None if not include_deleted else True).scalar()

    for f in factures:
        f.montant_total = montant_total

    return factures


def get_facture(db: Session, facture_id: int, include_deleted=False):
    query = db.query(Facture).filter(Facture.facture_id == facture_id)
    if not include_deleted:
        query = query.filter(Facture.deleted_at == None)
    facture = query.first()
    if not facture:
        return None

    montant_total = db.query(func.coalesce(func.sum(Facture.montant), 0))\
        .filter(Facture.deleted_at == None).scalar()
    facture.montant_total = montant_total

    return facture


def update_facture(db: Session, facture_id: int, facture_update: FactureUpdate):
    db_facture = db.query(Facture).filter(Facture.facture_id == facture_id, Facture.deleted_at == None).first()
    if not db_facture:
        return None

    for attr, value in facture_update.dict(exclude_unset=True).items():
        setattr(db_facture, attr, value)

    db.commit()
    db.refresh(db_facture)
    return db_facture


def soft_delete_facture(db: Session, facture_id: int):
    facture = db.query(Facture).filter(Facture.facture_id == facture_id, Facture.deleted_at == None).first()
    if not facture:
        return None

    # Vérifie si un achat actif utilise cette facture
    achat = db.query(Achat).filter(Achat.facture_id == facture_id, Achat.deleted_at == None).first()
    if achat:
        raise Exception("Impossible de supprimer la facture : elle est liée à un achat non supprimé.")

    try:
        facture.deleted_at = datetime.utcnow()
        db.commit()
    except Exception as e:
        db.rollback()
        raise Exception(f"Erreur suppression logique facture : {str(e)}")

    return facture


def restore_facture(db: Session, facture_id: int):
    facture = db.query(Facture).filter(Facture.facture_id == facture_id, Facture.deleted_at != None).first()
    if not facture:
        return None

    # Vérifie si l’achat lié est supprimé
    achat = db.query(Achat).filter(Achat.facture_id == facture_id, Achat.deleted_at != None).first()
    if achat:
        raise Exception("Impossible de restaurer la facture : l’achat lié est encore dans la corbeille.")

    try:
        facture.deleted_at = None
        db.commit()
    except Exception as e:
        db.rollback()
        raise Exception(f"Erreur restauration facture : {str(e)}")

    return facture



def search_factures(
    db: Session,
    query: str,
    include_deleted: bool = False,
    skip: int = 0,
    limit: int = 50
) -> List[Facture]:
    q = db.query(Facture)
    if not include_deleted:
        q = q.filter(Facture.deleted_at == None)
    # Recherche sur numero OU description (ilike = insensible à la casse)
    q = q.filter(
        or_(
            Facture.numero.ilike(f"%{query}%"),
            Facture.description.ilike(f"%{query}%")
        )
    )
    q = q.order_by(Facture.date_facture.desc())
    return q.offset(skip).limit(limit).all()
