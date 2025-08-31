from sqlalchemy.orm import Session
from app.models.stock_materiel import StockMateriel, TypeMouvementStockEnum
from app.schemas.stock_materiel import StockMaterielCreate
from datetime import datetime
from typing import Optional
from app.utils.stock_alerts import verifier_alertes_stock

def create_mouvement_stock(db: Session, mouvement: StockMaterielCreate) -> StockMateriel:
    db_mouvement = StockMateriel(
        materiel_id=mouvement.materiel_id,
        quantite=mouvement.quantite,
        type_mouvement=mouvement.type_mouvement,
        description=mouvement.description,
        date_mouvement=datetime.utcnow()
    )
    db.add(db_mouvement)
    db.commit()
    db.refresh(db_mouvement)

    # Déclenchement automatique des alertes après chaque mouvement
    verifier_alertes_stock(db)

    return db_mouvement

def get_mouvements_stock(
    db: Session, 
    skip: int = 0, 
    limit: int = 100, 
    search: Optional[str] = None
):
    query = db.query(StockMateriel).order_by(StockMateriel.date_mouvement.desc())
    if search:
        search_term = f"%{search}%"
        query = query.filter(StockMateriel.description.ilike(search_term))
    return query.offset(skip).limit(limit).all()

def get_stock_actuel_par_materiel(db: Session, materiel_id: int) -> int:
    mouvements = db.query(StockMateriel).filter(StockMateriel.materiel_id == materiel_id).all()
    total_entree = sum(m.quantite for m in mouvements if m.type_mouvement == TypeMouvementStockEnum.entree)
    total_sortie = sum(m.quantite for m in mouvements if m.type_mouvement == TypeMouvementStockEnum.sortie)
    return total_entree - total_sortie
