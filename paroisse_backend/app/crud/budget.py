from typing import Optional
from sqlalchemy.orm import Session
from datetime import datetime
from sqlalchemy import func

from app.models.budget import Budget
from app.models.don import Don
from app.models.offrande import Offrande
from app.models.quete import Quete
from app.models.achat import Achat
from app.models.salaire import Salaire
from app.models.notification import Notification, TypeNotificationEnum
from app.schemas.budget import BudgetCreate, BudgetUpdate


def create_budget(db: Session, budget: BudgetCreate):
    # Validation explicite (optionnelle mais conseillée)
    if not budget.categorie or not budget.sous_categorie:
        raise ValueError("Les champs 'categorie' et 'sous_categorie' sont obligatoires.")
    
    db_budget = Budget(**budget.dict())
    db.add(db_budget)
    db.commit()
    db.refresh(db_budget)
    return db_budget


def get_budgets(db: Session, skip=0, limit=100, include_deleted=False):
    query = db.query(Budget)
    if not include_deleted:
        query = query.filter(Budget.deleted_at.is_(None))
    return query.offset(skip).limit(limit).all()


def get_budget(db: Session, budget_id: int, include_deleted=False):
    query = db.query(Budget).filter(Budget.budget_id == budget_id)
    if not include_deleted:
        query = query.filter(Budget.deleted_at.is_(None))
    return query.first()


def update_budget(db: Session, budget_id: int, upd: BudgetUpdate):
    budget = db.query(Budget).filter(Budget.budget_id == budget_id).first()
    if not budget:
        return None
    for key, value in upd.dict(exclude_unset=True).items():
        setattr(budget, key, value)
    db.commit()
    db.refresh(budget)
    return budget


def soft_delete_budget(db: Session, budget_id: int):
    budget = db.query(Budget).filter(Budget.budget_id == budget_id).first()
    if budget and not budget.deleted_at:
        budget.deleted_at = datetime.utcnow()
        db.commit()
    return budget


def restore_budget(db: Session, budget_id: int):
    budget = db.query(Budget).filter(Budget.budget_id == budget_id).first()
    if budget and budget.deleted_at:
        budget.deleted_at = None
        db.commit()
    return budget


def verifier_solde_et_notifier(annee: int, db: Session, utilisateur_id: Optional[int] = None):
    # Recettes
    total_dons = db.query(func.coalesce(func.sum(Don.montant), 0)).filter(
        func.extract('year', Don.date_don) == annee,
        Don.deleted_at.is_(None)
    ).scalar()

    total_offrandes = db.query(func.coalesce(func.sum(Offrande.montant), 0)).filter(
        func.extract('year', Offrande.date) == annee,
        Offrande.deleted_at.is_(None)
    ).scalar()

    total_quetes = db.query(func.coalesce(func.sum(Quete.montant), 0)).filter(
        func.extract('year', Quete.date_quete) == annee,
        Quete.deleted_at.is_(None)
    ).scalar()

    total_recettes = total_dons + total_offrandes + total_quetes

    # Dépenses
    total_achats = db.query(func.coalesce(func.sum(Achat.montant), 0)).filter(
        func.extract('year', Achat.date_achat) == annee,
        Achat.deleted_at.is_(None)
    ).scalar()

    total_salaires = db.query(func.coalesce(func.sum(Salaire.montant), 0)).filter(
        func.extract('year', Salaire.date_paiement) == annee,
        Salaire.deleted_at.is_(None)
    ).scalar()

    total_depenses = total_achats + total_salaires

    solde = total_recettes - total_depenses

    if solde < 0:
        notif = Notification(
            titre="Solde négatif",
            message=f"Le solde budgétaire de l'année {annee} est négatif : {solde:.2f} FCFA.",
            type=TypeNotificationEnum.warning,
            utilisateur_id=utilisateur_id
        )
        db.add(notif)
        db.commit()

    return solde


def search_budgets(
    db: Session,
    intitule: Optional[str] = None,
    annee: Optional[int] = None,
    statut: Optional[str] = None,
    categorie: Optional[str] = None,
    sous_categorie: Optional[str] = None,
    utilisateur_id: Optional[int] = None
):
    query = db.query(Budget).filter(Budget.deleted_at.is_(None))

    if intitule:
        query = query.filter(Budget.intitule.ilike(f"%{intitule}%"))
    if annee:
        query = query.filter(Budget.annee == annee)
    if statut:
        query = query.filter(Budget.statut == statut)
    if categorie:
        query = query.filter(Budget.categorie == categorie)
    if sous_categorie:
        query = query.filter(Budget.sous_categorie == sous_categorie)
    if utilisateur_id:
        query = query.filter(Budget.utilisateur_id == utilisateur_id)

    return query.all()
