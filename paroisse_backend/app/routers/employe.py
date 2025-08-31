from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List

from app.schemas.employe import EmployeCreate, EmployeUpdate, EmployeOut
from app.crud import employe as crud_employe
from app.database import get_db

from app.permissions.employe import ALLOWED_ROLES
from app.utils.security import get_current_user

router = APIRouter()

def check_role(user, allowed_roles):
    if user.role not in allowed_roles:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Accès refusé : rôle non autorisé"
        )

@router.post("/", response_model=EmployeOut)
async def create_employe(
    employe: EmployeCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    return crud_employe.create_employe(db, employe)

@router.get("/", response_model=List[EmployeOut])
async def list_employes(
    db: Session = Depends(get_db),
    include_deleted: bool = False,
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    return crud_employe.get_employes(db, include_deleted=include_deleted)

@router.get("/{employe_id}", response_model=EmployeOut)
async def get_employe(
    employe_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    employe = crud_employe.get_employe(db, employe_id)
    if not employe:
        raise HTTPException(status_code=404, detail="Employé non trouvé")
    return employe

@router.put("/{employe_id}", response_model=EmployeOut)
async def update_employe(
    employe_id: int,
    data: EmployeUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    employe = crud_employe.update_employe(db, employe_id, data)
    if not employe:
        raise HTTPException(status_code=404, detail="Employé non trouvé")
    return employe

@router.delete("/{employe_id}")
async def soft_delete_employe(
    employe_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    employe = crud_employe.soft_delete_employe(db, employe_id)
    if not employe:
        raise HTTPException(status_code=404, detail="Employé non trouvé")
    return {"message": "Employé mis dans la corbeille"}

@router.put("/restore/{employe_id}")
async def restore_employe(
    employe_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    employe = crud_employe.restore_employe(db, employe_id)
    if not employe:
        raise HTTPException(status_code=404, detail="Employé non trouvé ou non supprimé")
    return {"message": "Employé restauré"}



@router.get("/search/", response_model=List[EmployeOut])
async def search_employes(
    query: str,
    skip: int = Query(0, ge=0),
    limit: int = Query(10, ge=1),
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    return crud_employe.search_employes(db, query, skip, limit)

