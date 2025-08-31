from sqlalchemy.orm import Session
from sqlalchemy import func, or_, cast, String
from datetime import datetime, date

from app.models.quete import Quete
from app.models.budget import Budget
from app.models.notification import Notification, TypeNotificationEnum
from app.models.utilisateur import Utilisateur
from app.schemas.quete import QueteCreate, QueteUpdate
from app.utils.recu import generate_recu
from app.utils.budget import update_budget_reel
from sqlalchemy.exc import SQLAlchemyError

def verifier_ou_creer_budget_quete(db: Session, annee: int, utilisateur_id: int):
    budget_existant = db.query(Budget).filter(
        Budget.intitule.ilike("Quête"),
        Budget.annee == annee,
        Budget.deleted_at == None
    ).first()
    if not budget_existant:
        budget = Budget(
            intitule="Quête",
            annee=annee,
            montantTotal=0,
            montantApprouve=0,
            statut="Proposé",
            utilisateur_id=utilisateur_id,
            categorie="Recette",
            sous_categorie="Quête"
        )
        db.add(budget)
        db.commit()

def create_quete(db: Session, quete_data: QueteCreate, utilisateur_id: int):
    db_quete = Quete(
        libelle=quete_data.libelle,
        montant=quete_data.montant,
        date_quete=quete_data.date_quete or datetime.utcnow(),
        utilisateur_id=utilisateur_id
    )
    db.add(db_quete)
    try:
        db.flush()

        generate_recu(
            db=db,
            montant=quete_data.montant,
            source="Quête",
            reference_id=db_quete.quete_id,
            utilisateur_id=utilisateur_id
        )

        date_quete = db_quete.date_quete
        verifier_ou_creer_budget_quete(db, date_quete.year, utilisateur_id)

        update_budget_reel(db, date_quete.year, "Quête", utilisateur_id)

        notification = Notification(
            titre="Quête enregistrée",
            message=f"Quête de {quete_data.montant} FCFA enregistrée avec succès.",
            type=TypeNotificationEnum.success,
            utilisateur_id=utilisateur_id
        )
        db.add(notification)

        db.commit()
    except Exception as e:
        db.rollback()
        raise Exception(f"Erreur lors de la création de la quête : {e}")

    db.refresh(db_quete)
    return db_quete

def get_quetes(db: Session, include_deleted=False, skip=0, limit=100):
    query = db.query(Quete)
    if not include_deleted:
        query = query.filter(Quete.deleted_at == None)
    quetes = query.offset(skip).limit(limit).all()

    total = db.query(func.coalesce(func.sum(Quete.montant), 0))
    if not include_deleted:
        total = total.filter(Quete.deleted_at == None)
    montant_total = total.scalar()

    for q in quetes:
        q.montant_total = montant_total
    return quetes

def get_quete(db: Session, quete_id: int, include_deleted=False):
    query = db.query(Quete).filter(Quete.quete_id == quete_id)
    if not include_deleted:
        query = query.filter(Quete.deleted_at == None)
    quete_instance = query.first()
    if not quete_instance:
        return None

    montant_total = db.query(func.coalesce(func.sum(Quete.montant), 0))\
        .filter(Quete.utilisateur_id == quete_instance.utilisateur_id, Quete.deleted_at == None).scalar()
    quete_instance.montant_total = montant_total
    return quete_instance

def update_quete(db: Session, quete_id: int, quete_update: QueteUpdate):
    db_quete = db.query(Quete).filter(Quete.quete_id == quete_id, Quete.deleted_at == None).first()
    if not db_quete:
        return None

    for key, value in quete_update.dict(exclude_unset=True).items():
        setattr(db_quete, key, value)

    try:
        # Vérifie que l'utilisateur existe avant de continuer
        utilisateur_existant = db.query(Utilisateur).filter_by(utilisateur_id=db_quete.utilisateur_id).first()
        if not utilisateur_existant:
            raise Exception("Utilisateur introuvable")

        db.commit()

        date_quete = db_quete.date_quete
        verifier_ou_creer_budget_quete(db, date_quete.year, db_quete.utilisateur_id)
        update_budget_reel(db, date_quete.year, "Quête", db_quete.utilisateur_id)

    except SQLAlchemyError as e:
        db.rollback()
        raise Exception(f"Erreur SQL lors de la mise à jour de la quête : {str(e)}")
    except Exception as e:
        db.rollback()
        raise Exception(f"Erreur lors de la mise à jour de la quête : {str(e)}")

    db.refresh(db_quete)
    return db_quete

def soft_delete_quete(db: Session, quete_id: int):
    db_quete = db.query(Quete).filter(Quete.quete_id == quete_id, Quete.deleted_at == None).first()
    if not db_quete:
        return None

    try:
        db_quete.deleted_at = datetime.utcnow()
        db.commit()

        date_quete = db_quete.date_quete
        verifier_ou_creer_budget_quete(db, date_quete.year, db_quete.utilisateur_id)
        update_budget_reel(db, date_quete.year, "Quête", db_quete.utilisateur_id)

    except Exception as e:
        db.rollback()
        raise Exception(f"Erreur lors de la suppression logique de la quête : {e}")

    return db_quete

def restore_quete(db: Session, quete_id: int):
    db_quete = db.query(Quete).filter(Quete.quete_id == quete_id, Quete.deleted_at != None).first()
    if not db_quete:
        return None

    try:
        db_quete.deleted_at = None
        db.commit()

        date_quete = db_quete.date_quete
        verifier_ou_creer_budget_quete(db, date_quete.year, db_quete.utilisateur_id)
        update_budget_reel(db, date_quete.year, "Quête", db_quete.utilisateur_id)

    except Exception as e:
        db.rollback()
        raise Exception(f"Erreur lors de la restauration de la quête : {e}")

    return db_quete

def search_quetes(db: Session, keyword: str, include_deleted=False):
    query = db.query(Quete)
    if not include_deleted:
        query = query.filter(Quete.deleted_at == None)

    keyword_like = f"%{keyword}%"
    query = query.filter(
        or_(
            Quete.libelle.ilike(keyword_like),
            cast(Quete.date_quete, String).ilike(keyword_like),
            cast(Quete.montant, String).ilike(keyword_like)
        )
    )
    results = query.order_by(Quete.date_quete.desc()).all()

    montant_total = db.query(func.coalesce(func.sum(Quete.montant), 0))
    if not include_deleted:
        montant_total = montant_total.filter(Quete.deleted_at == None)
    total = montant_total.scalar()

    for q in results:
        q.montant_total = total
    return results
