from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import datetime
from app.models.budget import Budget
from app.models.notification import Notification, TypeNotificationEnum
from app.models.don import Don
from app.models.offrande import Offrande
from app.models.quete import Quete
from app.models.achat import Achat
from app.models.salaire import Salaire

def update_budget_reel(session: Session, annee: int, intitule: str, utilisateur_id: int):
    intitule_lower = intitule.lower()
    montant_total = 0
    type = None

    if intitule_lower == "don":
        montant_total = session.query(func.coalesce(func.sum(Don.montant), 0))\
            .filter(func.extract('year', Don.date_don) == annee).scalar()
        type = "recette"

    elif intitule_lower == "offrande":
        montant_total = session.query(func.coalesce(func.sum(Offrande.montant), 0))\
            .filter(func.extract('year', Offrande.date) == annee).scalar()
        type = "recette"

    elif intitule_lower == "quete":
        montant_total = session.query(func.coalesce(func.sum(Quete.montant), 0))\
            .filter(func.extract('year', Quete.date_quete) == annee).scalar()
        type = "recette"

    elif intitule_lower == "achat":
        montant_total = session.query(func.coalesce(func.sum(Achat.montant), 0))\
            .filter(func.extract('year', Achat.date_achat) == annee).scalar()
        type = "depense"

    elif intitule_lower == "salaire":
        montant_total = session.query(func.coalesce(func.sum(Salaire.montant), 0))\
            .filter(func.extract('year', Salaire.date_paiement) == annee).scalar()
        type = "depense"

    else:
        montant_total = 0

    budget = session.query(Budget).filter(
        Budget.intitule.ilike(intitule),
        Budget.annee == annee,
        Budget.deleted_at == None
    ).first()

    if not budget:
        budget = Budget(
            intitule=intitule,
            annee=annee,
            montantTotal=0,
            montantApprouve=0,
            statut='Proposé',
            utilisateur_id=utilisateur_id,
            categorie=type.capitalize() if type else None,
            sous_categorie=intitule.capitalize()
        )
        session.add(budget)
        session.commit()

    # Mise à jour du montant réel selon type
    if type == "recette":
        budget.montantTotal = montant_total

    elif type == "depense":
        if budget.montantApprouve is not None and montant_total > budget.montantApprouve:
            notif = Notification(
                titre="Dépense dépassée",
                message=f"La dépense totale pour {intitule} ({montant_total} FCFA) dépasse le budget approuvé.",
                type=TypeNotificationEnum.warning,
                utilisateur_id=utilisateur_id,
                created_at=datetime.utcnow()
            )
            session.add(notif)
        budget.montantTotal = montant_total

    budget.updated_at = datetime.utcnow()
    session.commit()


def verifier_solde_disponible(session: Session, annee: int, montant: float) -> bool:
    """
    Vérifie si une nouvelle dépense peut être ajoutée sans dépasser les recettes disponibles.
    """
    recettes = (
        session.query(func.coalesce(func.sum(Don.montant), 0)).filter(func.extract('year', Don.date_don) == annee).scalar()
        + session.query(func.coalesce(func.sum(Offrande.montant), 0)).filter(func.extract('year', Offrande.date) == annee).scalar()
        + session.query(func.coalesce(func.sum(Quete.montant), 0)).filter(func.extract('year', Quete.date_quete) == annee).scalar()
    )

    depenses = (
        session.query(func.coalesce(func.sum(Achat.montant), 0)).filter(func.extract('year', Achat.date_achat) == annee).scalar()
        + session.query(func.coalesce(func.sum(Salaire.montant), 0)).filter(func.extract('year', Salaire.date_paiement) == annee).scalar()
    )

    solde = recettes - depenses

    return montant <= solde
