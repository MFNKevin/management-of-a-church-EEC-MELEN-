from sqlalchemy.orm import Session
from sqlalchemy import func, or_, cast, String
from datetime import datetime
from app.models.salaire import Salaire
from app.models.notification import Notification, TypeNotificationEnum
from app.models.employe import Employe
from app.schemas.salaire import SalaireCreate, SalaireUpdate
from app.schemas.recu import RecuCreate
from app.crud.recu import create_recu
from app.utils.budget import update_budget_reel, verifier_solde_disponible

def create_salaire(db: Session, salaire: SalaireCreate, utilisateur_id: int):
    if salaire.montant <= 0:
        raise Exception("Le montant du salaire doit être supérieur à 0")

    # Vérification du solde disponible avant création
    if not verifier_solde_disponible(db, salaire.date_paiement.year, salaire.montant):
        notif = Notification(
            titre="Salaire refusé",
            message=f"Impossible de créer le salaire de {salaire.montant} FCFA : solde insuffisant.",
            type=TypeNotificationEnum.warning,
            utilisateur_id=utilisateur_id,
            created_at=datetime.utcnow()
        )
        db.add(notif)
        db.commit()
        raise Exception(f"Solde insuffisant pour le salaire ({salaire.montant})")

    db_salaire = Salaire(
        montant=salaire.montant,
        date_paiement=salaire.date_paiement,
        employe_id=salaire.employe_id,
        utilisateur_id=utilisateur_id
    )
    db.add(db_salaire)

    try:
        db.flush()

        # Création automatique du reçu
        recu_data = RecuCreate(
            montant=salaire.montant,
            description=f"Paiement du salaire (Employé ID: {salaire.employe_id})",
            date_emission=datetime.utcnow(),
            utilisateur_id=utilisateur_id
        )
        create_recu(db, recu_data)

        # Mise à jour du budget réel
        update_budget_reel(db, db_salaire.date_paiement.year, "Salaire", utilisateur_id)

        # Notification succès
        notif = Notification(
            titre="Salaire payé",
            message=f"Salaire de {salaire.montant} FCFA payé avec succès.",
            type=TypeNotificationEnum.success,
            utilisateur_id=utilisateur_id
        )
        db.add(notif)

        db.commit()
    except Exception as e:
        db.rollback()
        raise Exception(f"Erreur lors de la création du salaire : {str(e)}")

    db.refresh(db_salaire)
    return db_salaire


def get_salaires(db: Session, include_deleted: bool = False):
    query = db.query(Salaire).join(Employe)
    if not include_deleted:
        query = query.filter(Salaire.deleted_at == None)
    salaires = query.all()

    montant_total_query = db.query(func.coalesce(func.sum(Salaire.montant), 0))
    if not include_deleted:
        montant_total_query = montant_total_query.filter(Salaire.deleted_at == None)
    montant_total = montant_total_query.scalar()

    for s in salaires:
        s.montant_total = montant_total
        s.employe_nom = s.employe.nom
        s.employe_prenom = s.employe.prenom
        s.employe_poste = s.employe.poste

    return salaires


def get_salaire(db: Session, salaire_id: int, include_deleted: bool = False):
    query = db.query(Salaire).filter(Salaire.salaire_id == salaire_id)
    if not include_deleted:
        query = query.filter(Salaire.deleted_at == None)
    salaire_instance = query.first()
    if not salaire_instance:
        return None

    montant_total = db.query(func.coalesce(func.sum(Salaire.montant), 0))\
        .filter(Salaire.utilisateur_id == salaire_instance.utilisateur_id, Salaire.deleted_at == None).scalar()
    salaire_instance.montant_total = montant_total
    return salaire_instance


def soft_delete_salaire(db: Session, salaire_id: int):
    db_salaire = db.query(Salaire).filter(Salaire.salaire_id == salaire_id, Salaire.deleted_at == None).first()
    if not db_salaire:
        return None

    # Vérification solde avant suppression
    if not verifier_solde_disponible(db, db_salaire.date_paiement.year, -db_salaire.montant):
        raise Exception(f"Impossible de supprimer le salaire {db_salaire.salaire_id} : solde insuffisant")

    try:
        db_salaire.deleted_at = datetime.utcnow()
        db.commit()
        update_budget_reel(db, db_salaire.date_paiement.year, "Salaire", db_salaire.utilisateur_id)

        notif = Notification(
            titre="Salaire supprimé",
            message=f"Salaire de {db_salaire.montant} FCFA supprimé logiquement.",
            type=TypeNotificationEnum.info,
            utilisateur_id=db_salaire.utilisateur_id
        )
        db.add(notif)
        db.commit()
    except Exception as e:
        db.rollback()
        raise Exception(f"Erreur suppression logique salaire : {str(e)}")

    return db_salaire


def restore_salaire(db: Session, salaire_id: int):
    db_salaire = db.query(Salaire).filter(Salaire.salaire_id == salaire_id, Salaire.deleted_at != None).first()
    if not db_salaire:
        return None

    # Vérification solde avant restauration
    if not verifier_solde_disponible(db, db_salaire.date_paiement.year, db_salaire.montant):
        raise Exception(f"Solde insuffisant pour restaurer le salaire ({db_salaire.montant})")

    try:
        db_salaire.deleted_at = None
        db.commit()
        update_budget_reel(db, db_salaire.date_paiement.year, "Salaire", db_salaire.utilisateur_id)

        notif = Notification(
            titre="Salaire restauré",
            message=f"Salaire de {db_salaire.montant} FCFA restauré avec succès.",
            type=TypeNotificationEnum.success,
            utilisateur_id=db_salaire.utilisateur_id
        )
        db.add(notif)
        db.commit()
    except Exception as e:
        db.rollback()
        raise Exception(f"Erreur restauration salaire : {str(e)}")

    return db_salaire


def search_salaires(db: Session, keyword: str, include_deleted: bool = False):
    keyword_like = f"%{keyword}%"
    query = db.query(Salaire).join(Employe)

    if not include_deleted:
        query = query.filter(Salaire.deleted_at == None)

    query = query.filter(
        or_(
            cast(Salaire.date_paiement, String).ilike(keyword_like),
            cast(Salaire.montant, String).ilike(keyword_like),
            Employe.nom.ilike(keyword_like),
            Employe.prenom.ilike(keyword_like)
        )
    ).order_by(Salaire.date_paiement.desc())

    return query.all()
