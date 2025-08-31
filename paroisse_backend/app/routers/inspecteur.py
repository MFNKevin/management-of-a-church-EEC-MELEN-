from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List

from app.database import get_db
from app.schemas.inspecteur import InspecteurCreate, InspecteurUpdate, InspecteurOut
from app.crud import inspecteur as crud
from app.utils.security import get_current_user
from app.permissions.inspecteur import ALLOWED_ROLES

router = APIRouter()

def check_role(user, allowed_roles):
    if user.role not in allowed_roles:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Accès refusé : rôle non autorisé"
        )

@router.post("/", response_model=InspecteurOut)
async def create_inspecteur(
    inspecteur: InspecteurCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    return crud.create_inspecteur(db, inspecteur)

@router.get("/", response_model=List[InspecteurOut])
async def list_inspecteurs(
    db: Session = Depends(get_db),
    include_deleted: bool = False,
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    return crud.get_inspecteurs(db, include_deleted=include_deleted)

@router.get("/{inspecteur_id}", response_model=InspecteurOut)
async def get_inspecteur(
    inspecteur_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    inspecteur = crud.get_inspecteur(db, inspecteur_id)
    if not inspecteur:
        raise HTTPException(status_code=404, detail="Inspecteur non trouvé")
    return inspecteur

@router.put("/{inspecteur_id}", response_model=InspecteurOut)
async def update_inspecteur(
    inspecteur_id: int,
    data: InspecteurUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    inspecteur = crud.update_inspecteur(db, inspecteur_id, data)
    if not inspecteur:
        raise HTTPException(status_code=404, detail="Inspecteur non trouvé")
    return inspecteur

@router.delete("/{inspecteur_id}")
async def soft_delete_inspecteur(
    inspecteur_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    inspecteur = crud.soft_delete_inspecteur(db, inspecteur_id)
    if not inspecteur:
        raise HTTPException(status_code=404, detail="Inspecteur non trouvé")
    return {"message": "Inspecteur mis dans la corbeille"}

@router.put("/restore/{inspecteur_id}")
async def restore_inspecteur(
    inspecteur_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    inspecteur = crud.restore_inspecteur(db, inspecteur_id)
    if not inspecteur:
        raise HTTPException(status_code=404, detail="Inspecteur non trouvé ou non supprimé")
    return {"message": "Inspecteur restauré"}

@router.get("/search/", response_model=List[InspecteurOut])
async def search_inspecteurs(
    query: str = Query(..., min_length=1),
    skip: int = 0,
    limit: int = 50,
    include_deleted: bool = False,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    return crud.search_inspecteurs(
        db=db,
        query=query,
        skip=skip,
        limit=limit,
        include_deleted=include_deleted
    )
