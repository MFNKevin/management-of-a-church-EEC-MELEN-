from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from app.database import get_db
from app.schemas.budget import BudgetCreate, BudgetOut, BudgetUpdate
from app.crud import budget as crud_budget
from app.crud.budget import verifier_solde_et_notifier
from app.database import SessionLocal
from app.permissions.budget import ALLOWED_ROLES
from app.utils.security import get_current_user

router = APIRouter()



def check_role(user, allowed_roles):
    if user.role not in allowed_roles:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Accès refusé : rôle non autorisé"
        )

@router.post("/", response_model=BudgetOut)
async def create(
    b: BudgetCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    return crud_budget.create_budget(db, b)

@router.get("/", response_model=List[BudgetOut])
async def list(
    skip: int = 0,
    limit: int = 100,
    include_deleted: bool = False,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    return crud_budget.get_budgets(db, skip=skip, limit=limit, include_deleted=include_deleted)


@router.get("/search", response_model=List[BudgetOut])
async def search(
    intitule: Optional[str] = None,
    annee: Optional[int] = None,
    statut: Optional[str] = None,
    categorie: Optional[str] = None,
    utilisateur_id: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    return crud_budget.search_budgets(
        db=db,
        intitule=intitule,
        annee=annee,
        statut=statut,
        categorie=categorie,
        utilisateur_id=utilisateur_id
    )


@router.get("/{budget_id}", response_model=BudgetOut)
async def get_one(
    budget_id: int,
    include_deleted: bool = False,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    b = crud_budget.get_budget(db, budget_id, include_deleted)
    if not b:
        raise HTTPException(status_code=404, detail="Budget non trouvé")
    return b

@router.get("/solde/{annee}")
async def get_solde_annuel(
    annee: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    solde = verifier_solde_et_notifier(annee=annee, db=db)
    return {"annee": annee, "solde": solde}

@router.put("/{budget_id}", response_model=BudgetOut)
async def update(
    budget_id: int,
    upd: BudgetUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    b = crud_budget.update_budget(db, budget_id, upd)
    if not b:
        raise HTTPException(status_code=404, detail="Budget non trouvé")
    return b

@router.delete("/{budget_id}")
async def soft_delete(
    budget_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    b = crud_budget.soft_delete_budget(db, budget_id)
    if not b:
        raise HTTPException(status_code=404, detail="Budget non trouvé")
    return {"message": "Budget supprimé"}

@router.put("/restore/{budget_id}")
async def restore(
    budget_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    b = crud_budget.restore_budget(db, budget_id)
    if not b:
        raise HTTPException(status_code=404, detail="Budget non trouvé ou non supprimé")
    return {"message": "Budget restauré"}


