from sqlalchemy.orm import Session, joinedload
from sqlalchemy import or_
from datetime import datetime
from app.models.sous_commission_financiere import SousCommissionFinanciere, MembreSousCommission
from app.models.utilisateur import Utilisateur
from app.schemas.sous_commission_financiere import SousCommissionCreate, MembreSousCommissionCreate


# Fonction utilitaire pour enrichir un membre avec les infos utilisateur et sous-commission
def enrich_membre_with_user_info(membre: MembreSousCommission):
    # Infos utilisateur
    if membre.utilisateur:
        membre.nom_utilisateur = membre.utilisateur.nom
        membre.prenom_utilisateur = membre.utilisateur.prenom
    else:
        membre.nom_utilisateur = None
        membre.prenom_utilisateur = None

    # Nom de la sous-commission
    if membre.sous_commission:
        membre.nom_sous_commission = membre.sous_commission.nom
    else:
        membre.nom_sous_commission = None

    return membre


# --- Sous-commission ---

def create_sous_commission(db: Session, data: SousCommissionCreate):
    obj = SousCommissionFinanciere(**data.dict())
    db.add(obj)
    try:
        db.commit()
        db.refresh(obj)
        return obj
    except Exception:
        db.rollback()
        raise


def get_sous_commission(db: Session, sous_commission_id: int, include_deleted=False):
    query = db.query(SousCommissionFinanciere).filter(SousCommissionFinanciere.sous_commission_id == sous_commission_id)
    if not include_deleted:
        query = query.filter(SousCommissionFinanciere.deleted_at == None)
    return query.first()


def get_sous_commissions(db: Session, include_deleted=False, skip: int = 0, limit: int = 100, search: str = None):
    query = db.query(SousCommissionFinanciere)
    if not include_deleted:
        query = query.filter(SousCommissionFinanciere.deleted_at == None)
    if search:
        search_term = f"%{search}%"
        query = query.filter(SousCommissionFinanciere.nom.ilike(search_term))
    return query.offset(skip).limit(limit).all()


def soft_delete_sous_commission(db: Session, sous_commission_id: int):
    obj = db.query(SousCommissionFinanciere).filter(SousCommissionFinanciere.sous_commission_id == sous_commission_id).first()
    if not obj or obj.deleted_at is not None:
        return None
    obj.deleted_at = datetime.utcnow()
    try:
        db.commit()
        return obj
    except Exception:
        db.rollback()
        raise


def restore_sous_commission(db: Session, sous_commission_id: int):
    obj = db.query(SousCommissionFinanciere).filter(SousCommissionFinanciere.sous_commission_id == sous_commission_id).first()
    if not obj or obj.deleted_at is None:
        return None
    obj.deleted_at = None
    try:
        db.commit()
        return obj
    except Exception:
        db.rollback()
        raise


def search_sous_commissions(
    db: Session,
    search: str,
    skip: int = 0,
    limit: int = 100,
    include_deleted: bool = False
):
    search_term = f"%{search}%"

    query = db.query(SousCommissionFinanciere)

    if not include_deleted:
        query = query.filter(SousCommissionFinanciere.deleted_at == None)

    query = query.filter(
        or_(
            SousCommissionFinanciere.nom.ilike(search_term),
            SousCommissionFinanciere.description.ilike(search_term)
        )
    )

    return query.offset(skip).limit(limit).all()


# --- Membre sous-commission ---

def create_membre_sous_commission(db: Session, data: MembreSousCommissionCreate):
    if not data.utilisateur_id:
        raise ValueError("utilisateur_id est obligatoire")

    membre = MembreSousCommission(**data.dict())
    db.add(membre)
    try:
        db.commit()
        db.refresh(membre)
        return enrich_membre_with_user_info(membre)
    except Exception:
        db.rollback()
        raise


def get_membre_sous_commission(db: Session, membre_id: int, include_deleted=False):
    query = db.query(MembreSousCommission).options(
        joinedload(MembreSousCommission.utilisateur),
        joinedload(MembreSousCommission.sous_commission)
    ).filter(
        MembreSousCommission.membre_sous_commission_id == membre_id
    )
    if not include_deleted:
        query = query.filter(MembreSousCommission.deleted_at == None)
    membre = query.first()
    if membre:
        membre = enrich_membre_with_user_info(membre)
    return membre


def get_membres_sous_commission(db: Session, sous_commission_id: int, include_deleted=False, skip: int = 0, limit: int = 100, search: str = None):
    query = db.query(MembreSousCommission).options(
        joinedload(MembreSousCommission.utilisateur),
        joinedload(MembreSousCommission.sous_commission)
    ).filter(
        MembreSousCommission.sous_commission_id == sous_commission_id
    )
    if not include_deleted:
        query = query.filter(MembreSousCommission.deleted_at == None)

    if search:
        search_term = f"%{search}%"
        query = query.join(Utilisateur, MembreSousCommission.utilisateur_id == Utilisateur.utilisateur_id, isouter=True).filter(
            or_(
                Utilisateur.nom.ilike(search_term),
                Utilisateur.prenom.ilike(search_term)
            )
        )

    membres = query.offset(skip).limit(limit).all()
    membres = [enrich_membre_with_user_info(m) for m in membres]
    return membres


def soft_delete_membre_sous_commission(db: Session, membre_id: int):
    obj = db.query(MembreSousCommission).filter(MembreSousCommission.membre_sous_commission_id == membre_id).first()
    if not obj or obj.deleted_at is not None:
        return None
    obj.deleted_at = datetime.utcnow()
    try:
        db.commit()
        return obj
    except Exception:
        db.rollback()
        raise


def restore_membre_sous_commission(db: Session, membre_id: int):
    obj = db.query(MembreSousCommission).filter(MembreSousCommission.membre_sous_commission_id == membre_id).first()
    if not obj or obj.deleted_at is None:
        return None
    obj.deleted_at = None
    try:
        db.commit()
        return obj
    except Exception:
        db.rollback()
        raise


def search_membres_sous_commission(
    db: Session,
    sous_commission_id: int,
    search: str,
    skip: int = 0,
    limit: int = 100,
    include_deleted: bool = False
):
    search_term = f"%{search}%"

    query = db.query(MembreSousCommission)\
        .options(
            joinedload(MembreSousCommission.utilisateur),
            joinedload(MembreSousCommission.sous_commission)
        )\
        .filter(MembreSousCommission.sous_commission_id == sous_commission_id)

    if not include_deleted:
        query = query.filter(MembreSousCommission.deleted_at == None)

    query = query.join(Utilisateur, isouter=True).filter(
        or_(
            MembreSousCommission.role.ilike(search_term),
            Utilisateur.nom.ilike(search_term),
            Utilisateur.prenom.ilike(search_term),
            Utilisateur.role.ilike(search_term)
        )
    )

    membres = query.offset(skip).limit(limit).all()
    membres = [enrich_membre_with_user_info(m) for m in membres]
    return membres
