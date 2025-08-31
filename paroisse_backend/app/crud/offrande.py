from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import date, datetime
from app.models.offrande import Offrande
from app.schemas.offrande import OffrandeCreate, OffrandeUpdate
from app.utils.budget import update_budget_reel
from app.models.notification import Notification, TypeNotificationEnum
from app.utils.recu import generate_recu

from datetime import date, datetime

def create_offrande(db: Session, offrande: OffrandeCreate, utilisateur_id: int):
    # Utiliser date_offrande (obligatoire dans OffrandeCreate)
    date_offrande = offrande.date_offrande
    assert isinstance(date_offrande, (date, datetime))

    db_offrande = Offrande(
        date=date_offrande,  # nom du champ dans la table SQLAlchemy
        montant=offrande.montant,
        type=offrande.type,
        description=offrande.description,
        utilisateur_id=utilisateur_id
    )
    db.add(db_offrande)

    try:
        db.flush()  # pour récupérer db_offrande.offrande_id

        # Génération du reçu lié à l’offrande
        generate_recu(
            db=db,
            montant=offrande.montant,
            source="Offrande",
            reference_id=db_offrande.offrande_id,
            utilisateur_id=utilisateur_id
        )

        # Mise à jour du budget réel
        update_budget_reel(
            session=db,
            annee=date_offrande.year,
            intitule="Offrande",
            utilisateur_id=utilisateur_id
        )

        # Création notification
        notification = Notification(
            titre="Offrande enregistrée",
            message=f"Offrande de {offrande.montant} FCFA enregistrée avec succès.",
            type=TypeNotificationEnum.success,
            utilisateur_id=utilisateur_id
        )
        db.add(notification)

        db.commit()

    except Exception as e:
        db.rollback()
        raise Exception(f"Erreur lors de la création de l'offrande : {str(e)}")

    db.refresh(db_offrande)
    return db_offrande


def get_offrandes(db: Session, skip: int = 0, limit: int = 100, include_deleted: bool = False):
    query = db.query(Offrande)
    if not include_deleted:
        query = query.filter(Offrande.deleted_at == None)

    offrandes = query.offset(skip).limit(limit).all()

    # Calcul du montant total pour toutes les offrandes non supprimées
    montant_total = db.query(func.coalesce(func.sum(Offrande.montant), 0))\
        .filter(Offrande.deleted_at == None if not include_deleted else True).scalar()

    # Injection du montant total dans chaque instance
    for o in offrandes:
        o.montant_total = montant_total

    return offrandes


def get_offrande(db: Session, offrande_id: int, include_deleted: bool = False):
    query = db.query(Offrande).filter(Offrande.offrande_id == offrande_id)
    if not include_deleted:
        query = query.filter(Offrande.deleted_at == None)

    offrande_instance = query.first()
    if not offrande_instance:
        return None

    montant_total = db.query(func.coalesce(func.sum(Offrande.montant), 0))\
        .filter(Offrande.deleted_at == None if not include_deleted else True).scalar()

    offrande_instance.montant_total = montant_total
    return offrande_instance

def update_offrande(
    db: Session,
    offrande_id: int,
    offrande_update: OffrandeUpdate,
    utilisateur_id: int  # <- utilisateur connecté
):
    offrande = get_offrande(db, offrande_id, include_deleted=True)
    if not offrande:
        return None

    for field, value in offrande_update.dict(exclude_unset=True).items():
        setattr(offrande, field, value)

    # Remplace l'ancien auteur par le nouvel utilisateur connecté
    offrande.utilisateur_id = utilisateur_id

    try:
        db.commit()

        # Vérification et conversion de la date
        date_obj = offrande.date if hasattr(offrande, 'date') else None
        if isinstance(date_obj, datetime):
            annee = date_obj.year
        elif isinstance(date_obj, date):
            annee = date_obj.year
        else:
            raise Exception("La date de l'offrande est invalide ou manquante.")

        # Mise à jour du budget avec l'utilisateur connecté
        update_budget_reel(
            session=db,
            annee=annee,
            intitule="Offrande",
            utilisateur_id=utilisateur_id
        )

        # Optionnel : notifier la modification
        notification = Notification(
            titre="Offrande modifiée",
            message=f"Offrande modifiée avec succès.",
            type=TypeNotificationEnum.info,
            utilisateur_id=utilisateur_id
        )
        db.add(notification)
        db.commit()

    except Exception as e:
        db.rollback()
        raise Exception(f"Erreur mise à jour budget après modification Offrande : {str(e)}")

    db.refresh(offrande)
    return offrande



def soft_delete_offrande(db: Session, offrande_id: int):
    offrande = get_offrande(db, offrande_id)
    if not offrande or offrande.deleted_at is not None:
        return None

    try:
        offrande.deleted_at = datetime.utcnow()

        # Sécurisation de la date
        if not offrande.date:
            raise Exception("La date de l'offrande est absente")

        if not isinstance(offrande.date, datetime):
            try:
                offrande.date = datetime.fromisoformat(str(offrande.date))
            except Exception as e:
                raise Exception(f"Format de date invalide : {offrande.date}")

        db.commit()

        update_budget_reel(
            session=db,
            annee=offrande.date.year,
            intitule="Offrande",
            utilisateur_id=offrande.utilisateur_id
        )
    except Exception as e:
        db.rollback()
        raise Exception(f"Erreur suppression logique Offrande : {str(e)}")

    return offrande


def restore_offrande(db: Session, offrande_id: int):
    offrande = get_offrande(db, offrande_id, include_deleted=True)
    if not offrande or offrande.deleted_at is None:
        return None

    try:
        offrande.deleted_at = None

        # Sécurisation de la date
        if not offrande.date:
            raise Exception("La date de l'offrande est absente")

        if not isinstance(offrande.date, datetime):
            try:
                offrande.date = datetime.fromisoformat(str(offrande.date))
            except Exception as e:
                raise Exception(f"Format de date invalide : {offrande.date}")

        db.commit()

        update_budget_reel(
            session=db,
            annee=offrande.date.year,
            intitule="Offrande",
            utilisateur_id=offrande.utilisateur_id
        )
    except Exception as e:
        db.rollback()
        raise Exception(f"Erreur restauration Offrande : {str(e)}")

    return offrande


def search_offrandes(
    db: Session,
    keyword: str,
    include_deleted: bool = False
):
    query = db.query(Offrande)

    if not include_deleted:
        query = query.filter(Offrande.deleted_at == None)

    # Recherche sur description ou type
    keyword_pattern = f"%{keyword}%"
    query = query.filter(
        (Offrande.description.ilike(keyword_pattern)) |
        (Offrande.type.ilike(keyword_pattern))
    )

    results = query.order_by(Offrande.date.desc()).all()

    # Ajout du montant total (facultatif)
    montant_total = db.query(func.coalesce(func.sum(Offrande.montant), 0))\
        .filter(Offrande.deleted_at == None if not include_deleted else True).scalar()

    for offrande in results:
        offrande.montant_total = montant_total

    return results
