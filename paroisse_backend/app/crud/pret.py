from sqlalchemy import and_, or_
from sqlalchemy.orm import Session
from datetime import datetime
from app.models.pret import Pret
from app.schemas.pret import PretCreate, PretUpdate
from app.crud import stock_materiel as crud_stock
from app.schemas.stock_materiel import StockMaterielCreate
from app.models.stock_materiel import TypeMouvementStockEnum
from fastapi import HTTPException


def verifier_chevauchement(db: Session, pret: PretCreate):
    query = db.query(Pret).filter(
        Pret.deleted_at == None,
        Pret.date_retour_effective == None,  # Le prêt est encore actif
    )

    if pret.materiel_id:
        query = query.filter(Pret.materiel_id == pret.materiel_id)
    if pret.infrastructure_id:
        query = query.filter(Pret.infrastructure_id == pret.infrastructure_id)

    conflit = query.filter(
        and_(
            Pret.date_pret <= pret.date_retour_prevue,
            Pret.date_retour_prevue >= pret.date_pret
        )
    ).first()

    if conflit:
        raise HTTPException(
            status_code=400,
            detail="Le matériel ou l’infrastructure est déjà prêté pendant cette période."
        )

def create_pret(db: Session, pret: PretCreate):
    verifier_chevauchement(db, pret)

    db_pret = Pret(**pret.dict())
    db.add(db_pret)
    db.commit()
    db.refresh(db_pret)

    # Enregistrement mouvement de stock si matériel
    if pret.materiel_id:
        mouvement_sortie = StockMaterielCreate(
            materiel_id=pret.materiel_id,
            quantite=1,
            type_mouvement=TypeMouvementStockEnum.sortie,
            description=f"Prêt matériel ID {db_pret.pret_id} à {pret.beneficiaire}"
        )
        crud_stock.create_mouvement_stock(db, mouvement_sortie)

    return db_pret


def get_pret(db: Session, pret_id: int, include_deleted: bool = False):
    query = db.query(Pret).filter(Pret.pret_id == pret_id)
    if not include_deleted:
        query = query.filter(Pret.deleted_at == None)
    return query.first()


def get_prets(db: Session, include_deleted: bool = False):
    query = db.query(Pret)
    if not include_deleted:
        query = query.filter(Pret.deleted_at == None)
    return query.order_by(Pret.date_pret.desc()).all()


def update_pret(db: Session, pret_id: int, pret_update: PretUpdate):
    pret = db.query(Pret).filter(Pret.pret_id == pret_id).first()
    if not pret:
        return None

    prev_date_retour_effective = pret.date_retour_effective

    for key, value in pret_update.dict(exclude_unset=True).items():
        setattr(pret, key, value)

    db.commit()
    db.refresh(pret)

    # Si retour matériel pour la première fois
    if pret.materiel_id and pret.date_retour_effective and prev_date_retour_effective is None:
        mouvement_entree = StockMaterielCreate(
            materiel_id=pret.materiel_id,
            quantite=1,
            type_mouvement=TypeMouvementStockEnum.entree,
            description=f"Retour prêt matériel ID {pret.pret_id} par {pret.beneficiaire}"
        )
        crud_stock.create_mouvement_stock(db, mouvement_entree)

    return pret


def soft_delete_pret(db: Session, pret_id: int):
    pret = db.query(Pret).filter(Pret.pret_id == pret_id).first()
    if pret and pret.deleted_at is None:
        pret.deleted_at = datetime.utcnow()
        db.commit()
    return pret


def restore_pret(db: Session, pret_id: int):
    pret = db.query(Pret).filter(Pret.pret_id == pret_id).first()
    if pret and pret.deleted_at is not None:
        pret.deleted_at = None
        db.commit()
    return pret


def search_prets(db: Session, keyword: str, include_deleted: bool = False):
    from sqlalchemy import or_

    query = db.query(Pret)
    if not include_deleted:
        query = query.filter(Pret.deleted_at == None)

    keyword_pattern = f"%{keyword}%"
    query = query.filter(
        or_(
            Pret.beneficiaire.ilike(keyword_pattern),
            Pret.numero_cni.ilike(keyword_pattern),
            Pret.email.ilike(keyword_pattern),
            Pret.telephone.ilike(keyword_pattern),
            Pret.etat_retour.ilike(keyword_pattern)
        )
    )

    return query.order_by(Pret.date_pret.desc()).all()
