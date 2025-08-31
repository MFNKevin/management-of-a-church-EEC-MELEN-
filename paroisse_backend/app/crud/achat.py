from typing import Optional
from sqlalchemy import func
from sqlalchemy.orm import Session
from datetime import datetime, date
from uuid import uuid4

from app.models.achat import Achat
from app.models.facture import Facture
from app.models.budget import Budget
from app.models.notification import Notification, TypeNotificationEnum
from app.schemas.achat import AchatCreate, AchatUpdate
from app.schemas.facture import FactureCreate
from app.crud.facture import create_facture
from app.utils.budget import update_budget_reel, verifier_solde_disponible


# ✅ Crée le budget "Achat" si manquant pour l'année
def verifier_ou_creer_budget_achat(db: Session, annee: int, utilisateur_id: int):
    budget_existant = (
        db.query(Budget)
        .filter(
            Budget.intitule.ilike("Achat"),
            Budget.annee == annee,
            Budget.deleted_at == None
        )
        .first()
    )
    if not budget_existant:
        budget = Budget(
            intitule="Achat",
            annee=annee,
            montantTotal=0,
            montantApprouve=0,
            statut="Proposé",
            utilisateur_id=utilisateur_id,
            categorie="Dépense",
            sous_categorie="Achat",
        )
        db.add(budget)
        db.commit()


# ✅ Création d’un achat (validations fortes + facture + budget + notif)
def create_achat(db: Session, achat: AchatCreate, utilisateur_id: int):
    try:
        # -- Contraintes côté CRUD (défense en profondeur) --
        if achat.montant is None or achat.montant <= 0:
            raise Exception("Le montant de l'achat doit être strictement positif.")
        if achat.date_achat is None:
            raise Exception("La date de l'achat est obligatoire.")
        if achat.date_achat > datetime.utcnow().date():
            raise Exception("La date de l'achat ne peut pas être dans le futur.")

        # Vérifier/créer budget
        verifier_ou_creer_budget_achat(db, achat.date_achat.year, utilisateur_id)

        # Vérification du solde disponible (dépense sortante)
        if not verifier_solde_disponible(db, achat.date_achat.year, achat.montant):
            notif = Notification(
                titre="Achat refusé",
                message=f"Impossible de créer l'achat de {achat.montant} FCFA : solde insuffisant.",
                type=TypeNotificationEnum.warning,
                utilisateur_id=utilisateur_id,
                created_at=datetime.utcnow(),
            )
            db.add(notif)
            db.commit()
            raise Exception(f"Solde insuffisant pour l'achat ({achat.montant})")

        # Création automatique de la facture
        facture = FactureCreate(
            numero=f"F-{uuid4().hex[:8]}",
            montant=achat.montant,
            date_facture=achat.date_achat,
            description=f"Facture générée pour achat : {achat.libelle}",
            utilisateur_id=utilisateur_id,
        )
        facture_obj = create_facture(db, facture)

        # Création de l'achat
        db_achat = Achat(
            montant=achat.montant,
            date_achat=achat.date_achat,
            libelle=achat.libelle,
            utilisateur_id=utilisateur_id,
            facture_id=facture_obj.facture_id,
        )
        db.add(db_achat)
        db.flush()  # pour avoir achat_id

        # Mise à jour du budget réel
        update_budget_reel(db, db_achat.date_achat.year, "Achat", utilisateur_id)

        # Notification succès
        notification = Notification(
            titre="Achat enregistré",
            message=f"Achat de {achat.montant} FCFA avec facture automatique créé.",
            type=TypeNotificationEnum.success,
            utilisateur_id=utilisateur_id,
            created_at=datetime.utcnow(),
        )
        db.add(notification)
        db.commit()
        db.refresh(db_achat)
        return db_achat

    except Exception as e:
        db.rollback()
        raise Exception(f"Erreur lors de la création de l'achat : {str(e)}")


# ✅ Mise à jour d’un achat (vérif solde si augmentation + budget + notif)
def update_achat(db: Session, achat_id: int, achat: AchatUpdate):
    db_achat = (
        db.query(Achat)
        .filter(Achat.achat_id == achat_id, Achat.deleted_at == None)
        .first()
    )
    if not db_achat:
        return None

    # Préparer validations et calcul de différence
    payload = achat.dict(exclude_unset=True)
    montant_nouveau = payload.get("montant", db_achat.montant)
    date_nouvelle = payload.get("date_achat", db_achat.date_achat)

    # -- Contraintes --
    if montant_nouveau <= 0:
        raise Exception("Le montant de l'achat doit être strictement positif.")
    if date_nouvelle > datetime.utcnow().date():
        raise Exception("La date de l'achat ne peut pas être dans le futur.")

    difference = montant_nouveau - db_achat.montant
    if difference > 0:
        # besoin de plus de trésorerie => vérifier solde
        if not verifier_solde_disponible(db, date_nouvelle.year, difference):
            raise Exception(
                f"Solde insuffisant pour augmenter le montant de l'achat à {montant_nouveau}."
            )

    # Appliquer modifications
    for attr, value in payload.items():
        setattr(db_achat, attr, value)

    try:
        db.commit()

        # Vérifier/créer budget si année changée
        verifier_ou_creer_budget_achat(db, db_achat.date_achat.year, db_achat.utilisateur_id)

        # Mettre à jour le budget réel
        update_budget_reel(db, db_achat.date_achat.year, "Achat", db_achat.utilisateur_id)

        notif = Notification(
            titre="Achat modifié",
            message=f"Achat {db_achat.libelle} mis à jour avec succès.",
            type=TypeNotificationEnum.info,
            utilisateur_id=db_achat.utilisateur_id,
            created_at=datetime.utcnow(),
        )
        db.add(notif)
        db.commit()
    except Exception as e:
        db.rollback()
        raise Exception(f"Erreur mise à jour budget après modification achat : {str(e)}")

    db.refresh(db_achat)
    return db_achat


# ✅ Suppression logique (pas de vérif solde — une suppression d’une dépense libère de la trésorerie)
def soft_delete_achat(db: Session, achat_id: int):
    db_achat = (
        db.query(Achat)
        .filter(Achat.achat_id == achat_id, Achat.deleted_at == None)
        .first()
    )
    if not db_achat:
        return None

    try:
        db_achat.deleted_at = datetime.utcnow()
        db.commit()

        # Vérifier/créer budget
        verifier_ou_creer_budget_achat(db, db_achat.date_achat.year, db_achat.utilisateur_id)

        # Recalcul budget réel
        update_budget_reel(db, db_achat.date_achat.year, "Achat", db_achat.utilisateur_id)

        notif = Notification(
            titre="Achat supprimé",
            message=f"Achat {db_achat.libelle} supprimé logiquement.",
            type=TypeNotificationEnum.info,
            utilisateur_id=db_achat.utilisateur_id,
            created_at=datetime.utcnow(),
        )
        db.add(notif)
        db.commit()
    except Exception as e:
        db.rollback()
        raise Exception(f"Erreur suppression logique achat : {str(e)}")

    return db_achat


# ✅ Restauration (vérif solde — on ré-impute la dépense)
def restore_achat(db: Session, achat_id: int):
    db_achat = (
        db.query(Achat)
        .filter(Achat.achat_id == achat_id, Achat.deleted_at != None)
        .first()
    )
    if not db_achat:
        return None

    # Vérification solde avant restauration (on “ressort” la dépense)
    if not verifier_solde_disponible(db, db_achat.date_achat.year, db_achat.montant):
        raise Exception(f"Solde insuffisant pour restaurer l'achat ({db_achat.montant})")

    try:
        db_achat.deleted_at = None
        db.commit()

        # Vérifier/créer budget
        verifier_ou_creer_budget_achat(db, db_achat.date_achat.year, db_achat.utilisateur_id)

        # Recalcul budget réel
        update_budget_reel(db, db_achat.date_achat.year, "Achat", db_achat.utilisateur_id)

        notif = Notification(
            titre="Achat restauré",
            message=f"Achat {db_achat.libelle} restauré avec succès.",
            type=TypeNotificationEnum.success,
            utilisateur_id=db_achat.utilisateur_id,
            created_at=datetime.utcnow(),
        )
        db.add(notif)
        db.commit()
    except Exception as e:
        db.rollback()
        raise Exception(f"Erreur restauration achat : {str(e)}")

    return db_achat


# ✅ Liste + total
def get_achats(db: Session, include_deleted: bool = False):
    query = db.query(Achat)
    if not include_deleted:
        query = query.filter(Achat.deleted_at == None)
    achats = query.all()

    total_query = db.query(func.coalesce(func.sum(Achat.montant), 0))
    if not include_deleted:
        total_query = total_query.filter(Achat.deleted_at == None)
    montant_total = total_query.scalar()

    for a in achats:
        a.montant_total = montant_total
    return achats


# ✅ Détail + total par utilisateur
def get_achat(db: Session, achat_id: int, include_deleted: bool = False):
    query = db.query(Achat).filter(Achat.achat_id == achat_id)
    if not include_deleted:
        query = query.filter(Achat.deleted_at == None)
    achat_instance = query.first()
    if not achat_instance:
        return None

    montant_total = (
        db.query(func.coalesce(func.sum(Achat.montant), 0))
        .filter(
            Achat.utilisateur_id == achat_instance.utilisateur_id,
            Achat.deleted_at == None
        )
        .scalar()
    )
    achat_instance.montant_total = montant_total
    return achat_instance


def get_achats_supprimes(db: Session):
    return db.query(Achat).filter(Achat.deleted_at.isnot(None)).all()


# ✅ Recherche (sur non supprimés)
def search_achats(
    db: Session,
    libelle: Optional[str] = None,
    date_achat: Optional[date] = None,
    fournisseur: Optional[str] = None,
    montant_min: Optional[float] = None,
    montant_max: Optional[float] = None,
):
    query = db.query(Achat).filter(Achat.deleted_at == None)
    if libelle:
        query = query.filter(Achat.libelle.ilike(f"%{libelle}%"))
    if date_achat:
        query = query.filter(Achat.date_achat == date_achat)
    if fournisseur:
        # champ “fournisseur” doit exister dans le modèle Achat
        query = query.filter(Achat.fournisseur.ilike(f"%{fournisseur}%"))
    if montant_min is not None:
        query = query.filter(Achat.montant >= montant_min)
    if montant_max is not None:
        query = query.filter(Achat.montant <= montant_max)

    results = query.all()
    montant_total = sum(achat.montant for achat in results)
    for achat in results:
        achat.montant_total = montant_total
    return results
