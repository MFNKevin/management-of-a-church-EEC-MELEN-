from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from app.database import get_db
from app.schemas.sous_commission_financiere import (
    SousCommissionCreate, SousCommissionOut,
    MembreSousCommissionCreate, MembreSousCommissionOut
)
from app.crud import sous_commission_financiere as crud
from app.utils.security import get_current_user
from app.permissions.sous_commission_financiere import ALLOWED_ROLES_SOUS_COMMISSION

router = APIRouter()

def check_role(current_user):
    if current_user.role not in ALLOWED_ROLES_SOUS_COMMISSION:
        raise HTTPException(status_code=403, detail=f"Permission refusée pour le rôle {current_user.role}")

# --- Sous-commission ---

@router.post("/", response_model=SousCommissionOut)
def create_sous_commission(
    data: SousCommissionCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user)
    return crud.create_sous_commission(db, data)


@router.get("/", response_model=List[SousCommissionOut])
def get_sous_commissions(
    include_deleted: bool = False,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user)
    return crud.get_sous_commissions(db, include_deleted, skip, limit)


@router.get("/search", response_model=List[SousCommissionOut])
def search_sous_commissions(
    search: str = Query(..., description="Recherche par nom ou description"),
    include_deleted: bool = False,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user)
    return crud.search_sous_commissions(db, search, skip, limit, include_deleted)


@router.get("/{sous_commission_id}", response_model=SousCommissionOut)
def get_sous_commission(
    sous_commission_id: int,
    include_deleted: bool = False,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user)
    obj = crud.get_sous_commission(db, sous_commission_id, include_deleted)
    if not obj:
        raise HTTPException(status_code=404, detail="Sous-commission non trouvée")
    return obj


@router.delete("/{sous_commission_id}")
def soft_delete_sous_commission(
    sous_commission_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user)
    if not crud.soft_delete_sous_commission(db, sous_commission_id):
        raise HTTPException(status_code=404, detail="Sous-commission non trouvée")
    return {"message": "Sous-commission supprimée"}


@router.put("/restore/{sous_commission_id}")
def restore_sous_commission(
    sous_commission_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user)
    if not crud.restore_sous_commission(db, sous_commission_id):
        raise HTTPException(status_code=404, detail="Sous-commission non trouvée ou non supprimée")
    return {"message": "Sous-commission restaurée"}


# --- Membres sous-commission ---

@router.post("/membres", response_model=MembreSousCommissionOut)
def create_membre_sous_commission(
    data: MembreSousCommissionCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user)
    # CRUD retourne un membre enrichi avec nom/prenom utilisateur et nom sous-commission
    return crud.create_membre_sous_commission(db, data)


@router.get("/{sous_commission_id}/membres", response_model=List[MembreSousCommissionOut])
def get_membres_sous_commission(
    sous_commission_id: int,
    include_deleted: bool = False,
    skip: int = 0,
    limit: int = 100,
    search: Optional[str] = Query(None, description="Recherche par nom ou prénom utilisateur"),
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user)
    return crud.get_membres_sous_commission(db, sous_commission_id, include_deleted, skip, limit, search)


@router.get("/membres/{membre_id}", response_model=MembreSousCommissionOut)
def get_membre_sous_commission(
    membre_id: int,
    include_deleted: bool = False,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user)
    obj = crud.get_membre_sous_commission(db, membre_id, include_deleted)
    if not obj:
        raise HTTPException(status_code=404, detail="Membre non trouvé")
    return obj


@router.delete("/membres/{membre_id}")
def soft_delete_membre(
    membre_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user)
    if not crud.soft_delete_membre_sous_commission(db, membre_id):
        raise HTTPException(status_code=404, detail="Membre non trouvé")
    return {"message": "Membre supprimé"}


@router.put("/membres/restore/{membre_id}")
def restore_membre(
    membre_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user)
    if not crud.restore_membre_sous_commission(db, membre_id):
        raise HTTPException(status_code=404, detail="Membre non trouvé ou non supprimé")
    return {"message": "Membre restauré"}
