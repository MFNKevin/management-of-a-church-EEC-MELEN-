from sqlalchemy.orm import Session, joinedload
from datetime import datetime
from app.models.commission_financiere import CommissionFinanciere, MembreCommission
from app.schemas.commission_financiere import CommissionCreate, MembreCommissionCreate

# ---- Commission ----

def create_commission(db: Session, data: CommissionCreate):
    obj = CommissionFinanciere(**data.dict())
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj

def get_commissions(db: Session, include_deleted=False):
    query = db.query(CommissionFinanciere)
    if not include_deleted:
        query = query.filter(CommissionFinanciere.deleted_at == None)
    return query.all()

def soft_delete_commission(db: Session, commission_id: int):
    obj = db.query(CommissionFinanciere).filter(CommissionFinanciere.commission_id == commission_id).first()
    if obj and obj.deleted_at is None:
        obj.deleted_at = datetime.utcnow()
        db.commit()
    return obj

def restore_commission(db: Session, commission_id: int):
    obj = db.query(CommissionFinanciere).filter(CommissionFinanciere.commission_id == commission_id).first()
    if obj and obj.deleted_at:
        obj.deleted_at = None
        db.commit()
    return obj

# ---- MembreCommission ----

def create_membre_commission(db: Session, data: MembreCommissionCreate):
    if data.role in ["Président", "Trésorier", "Secrétaire"]:
        check_unique_role(db, data.commission_id, data.role)
    obj = MembreCommission(**data.dict())
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj

def get_membres_commission(db: Session, commission_id: int, include_deleted=False):
    commission = db.query(CommissionFinanciere).filter_by(commission_id=commission_id).first()
    if not commission:
        raise ValueError("Commission non trouvée")
    
    query = (
        db.query(MembreCommission)
        .options(
            joinedload(MembreCommission.commission),
            joinedload(MembreCommission.utilisateur)
        )
        .filter(MembreCommission.commission_id == commission_id)
    )
    if not include_deleted:
        query = query.filter(MembreCommission.deleted_at == None)
    
    membres = query.all()

    for membre in membres:
        membre.nom_commission = membre.commission.nom if membre.commission else None
        membre.nom_utilisateur = membre.utilisateur.nom if membre.utilisateur else None
        membre.prenom_utilisateur = membre.utilisateur.prenom if membre.utilisateur else None
    
    return membres

def get_all_membres_commission(db: Session, include_deleted: bool = False):
    query = db.query(MembreCommission)
    if not include_deleted:
        query = query.filter(MembreCommission.deleted_at == None)
    membres = query.options(
        joinedload(MembreCommission.commission),
        joinedload(MembreCommission.utilisateur)
    ).all()

    for membre in membres:
        membre.nom_commission = membre.commission.nom if membre.commission else None
        membre.nom_utilisateur = membre.utilisateur.nom if membre.utilisateur else None
        membre.prenom_utilisateur = membre.utilisateur.prenom if membre.utilisateur else None

    return membres

def update_membre_commission(db: Session, membre_commission_id: int, data: MembreCommissionCreate):
    # Récupération de l'objet
    membre = db.query(MembreCommission).filter(
        MembreCommission.membre_commission_id == membre_commission_id,
        MembreCommission.deleted_at.is_(None)
    ).first()

    if not membre:
        return None

    # Vérification unicité du rôle si nécessaire
    if data.role in ["Président", "Trésorier", "Secrétaire"]:
        check_unique_role(db, data.commission_id, data.role)

    # Mise à jour des champs
    membre.commission_id = data.commission_id
    membre.utilisateur_id = data.utilisateur_id
    membre.role = data.role

    db.commit()
    db.refresh(membre)
    return membre


def soft_delete_membre_commission(db: Session, membre_commission_id: int):
    obj = db.query(MembreCommission).filter(MembreCommission.membre_commission_id == membre_commission_id).first()
    if obj and obj.deleted_at is None:
        obj.deleted_at = datetime.utcnow()
        db.commit()
    return obj

def restore_membre_commission(db: Session, membre_commission_id: int):
    obj = db.query(MembreCommission).filter(MembreCommission.membre_commission_id == membre_commission_id).first()
    if obj and obj.deleted_at:
        obj.deleted_at = None
        db.commit()
    return obj

def check_unique_role(db: Session, commission_id: int, role: str):
    if role in ["Président", "Trésorier", "Secrétaire"]:
        existing = db.query(MembreCommission).filter(
            MembreCommission.commission_id == commission_id,
            MembreCommission.role == role,
            MembreCommission.deleted_at == None
        ).first()
        if existing:
            raise ValueError(f"Un {role} est déjà assigné à cette commission.")

def search_commissions(db: Session, nom: str = None, description: str = None):
    query = db.query(CommissionFinanciere).filter(CommissionFinanciere.deleted_at == None)

    if nom:
        query = query.filter(CommissionFinanciere.nom.ilike(f"%{nom}%"))
    if description:
        query = query.filter(CommissionFinanciere.description.ilike(f"%{description}%"))

    return query.all()
