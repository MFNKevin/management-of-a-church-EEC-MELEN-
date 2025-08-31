from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List

from app.schemas.materiel import MaterielCreate, MaterielUpdate, MaterielOut
from app.crud import materiel as crud_materiel
from app.database import get_db
from app.utils.security import get_current_user
from app.permissions.materiel import ALLOWED_ROLES_EVANGELISTE

router = APIRouter(prefix="/materiels", tags=["Materiel"])

def check_role(user, allowed_roles):
    if user.role not in allowed_roles:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Accès refusé : rôle non autorisé"
        )

@router.post("/", response_model=MaterielOut)
def create_materiel(
    materiel: MaterielCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES_EVANGELISTE)
    return crud_materiel.create_materiel(db, materiel)

@router.get("/search", response_model=List[MaterielOut])
def search_materiels(
    query: str = Query(..., min_length=1),
    skip: int = 0,
    limit: int = 50,
    include_deleted: bool = False,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES_EVANGELISTE)
    return crud_materiel.search_materiels(
        db=db,
        query=query,
        skip=skip,
        limit=limit,
        include_deleted=include_deleted
    )

@router.get("/", response_model=List[MaterielOut])
def list_materiels(
    db: Session = Depends(get_db),
    include_deleted: bool = False,
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES_EVANGELISTE)
    return crud_materiel.get_materiels(db, include_deleted)

@router.get("/{materiel_id}", response_model=MaterielOut)
def get_materiel(
    materiel_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES_EVANGELISTE)
    materiel = crud_materiel.get_materiel(db, materiel_id)
    if not materiel:
        raise HTTPException(status_code=404, detail="Matériel non trouvé")
    return materiel

@router.put("/{materiel_id}", response_model=MaterielOut)
def update_materiel(
    materiel_id: int,
    materiel: MaterielUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES_EVANGELISTE)
    updated = crud_materiel.update_materiel(db, materiel_id, materiel)
    if not updated:
        raise HTTPException(status_code=404, detail="Matériel non trouvé")
    return updated

@router.delete("/{materiel_id}")
def soft_delete_materiel(
    materiel_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES_EVANGELISTE)
    deleted = crud_materiel.soft_delete_materiel(db, materiel_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Matériel non trouvé")
    return {"message": "Matériel mis dans la corbeille"}

@router.put("/restore/{materiel_id}")
def restore_materiel(
    materiel_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES_EVANGELISTE)
    restored = crud_materiel.restore_materiel(db, materiel_id)
    if not restored:
        raise HTTPException(status_code=404, detail="Matériel non trouvé ou non supprimé")
    return {"message": "Matériel restauré"}
