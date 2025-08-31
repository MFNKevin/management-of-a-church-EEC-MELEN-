from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional

from app.schemas.stock_materiel import StockMaterielCreate, StockMaterielOut
from app.crud import stock_materiel as crud_stock
from app.database import get_db
from app.utils.security import get_current_user
from app.models.utilisateur import Utilisateur
from app.permissions.stock_materiel import ALLOWED_ROLES_STOCK
from app.models.stock_materiel import TypeMouvementStockEnum

router = APIRouter(prefix="/stock", tags=["StockMateriel"])

def check_role(current_user: Utilisateur):
    if current_user.role not in ALLOWED_ROLES_STOCK:
        raise HTTPException(status_code=403, detail=f"Permission refusée pour le rôle {current_user.role}")

@router.post("/", response_model=StockMaterielOut)
def create_mouvement(
    mouvement: StockMaterielCreate, 
    db: Session = Depends(get_db), 
    current_user: Utilisateur = Depends(get_current_user)
):
    check_role(current_user)
    if mouvement.quantite <= 0:
        raise HTTPException(status_code=400, detail="La quantité doit être positive.")

    if mouvement.type_mouvement == TypeMouvementStockEnum.sortie:
        stock_actuel = crud_stock.get_stock_actuel_par_materiel(db, mouvement.materiel_id)
        if mouvement.quantite > stock_actuel:
            raise HTTPException(
                status_code=400,
                detail=f"La quantité sortie ({mouvement.quantite}) ne peut pas dépasser la quantité en stock ({stock_actuel})."
            )

    return crud_stock.create_mouvement_stock(db, mouvement)

@router.get("/", response_model=List[StockMaterielOut])
def list_mouvements(
    db: Session = Depends(get_db), 
    skip: int = 0, 
    limit: int = 100,
    search: Optional[str] = Query(None, description="Recherche par description"),
    current_user: Utilisateur = Depends(get_current_user)
):
    check_role(current_user)
    return crud_stock.get_mouvements_stock(db, skip=skip, limit=limit, search=search)
