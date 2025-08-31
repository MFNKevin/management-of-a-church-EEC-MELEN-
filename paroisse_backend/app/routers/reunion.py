from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from typing import List
from app.database import get_db
from app.schemas.reunion import ReunionCreate, ReunionUpdate, ReunionOut
from app.crud.reunion import (
    create_reunion,
    get_reunions,
    get_reunion,
    update_reunion,
    soft_delete_reunion,
    restore_reunion,
    search_reunions,
)
from app.utils.security import get_current_user
from app.permissions.reunion import ALLOWED_ROLES_REUNION


router = APIRouter()


def verify_role(current_user=Depends(get_current_user)):
    if current_user.role not in ALLOWED_ROLES_REUNION:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN,
                            detail=f"Permission refusée pour le rôle {current_user.role}")
    return current_user


@router.post("/", response_model=ReunionOut, status_code=status.HTTP_201_CREATED)
def create_reunion_route(
    reunion_in: ReunionCreate,
    db: Session = Depends(get_db),
    current_user=Depends(verify_role),
):
    reunion = create_reunion(db, reunion_in)
    return reunion


@router.get("/", response_model=List[ReunionOut])
def list_reunions(
    include_deleted: bool = False,
    db: Session = Depends(get_db),
    current_user=Depends(verify_role),
):
    reunions = get_reunions(db, include_deleted=include_deleted)
    return reunions


@router.get("/search", response_model=List[ReunionOut])
def search_reunions_route(
    keyword: str = Query(..., min_length=1),
    include_deleted: bool = False,
    db: Session = Depends(get_db),
    current_user=Depends(verify_role),
):
    results = search_reunions(db, keyword, include_deleted=include_deleted)
    return results


@router.get("/{reunion_id}", response_model=ReunionOut)
def get_reunion_route(
    reunion_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(verify_role),
):
    reunion = get_reunion(db, reunion_id)
    if not reunion:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Réunion non trouvée")
    return reunion


@router.put("/{reunion_id}", response_model=ReunionOut)
def update_reunion_route(
    reunion_id: int,
    reunion_in: ReunionUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(verify_role),
):
    reunion = update_reunion(db, reunion_id, reunion_in)
    if not reunion:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Réunion non trouvée")
    return reunion


@router.delete("/{reunion_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_reunion_route(
    reunion_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(verify_role),
):
    deleted = soft_delete_reunion(db, reunion_id)
    if not deleted:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,
                            detail="Réunion non trouvée ou déjà archivée")
    return {"detail": "Réunion archivée avec succès"}


@router.put("/restore/{reunion_id}")
def restore_reunion_route(
    reunion_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(verify_role),
):
    restored = restore_reunion(db, reunion_id)
    if not restored:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,
                            detail="Réunion non trouvée ou non archivée")
    return {"detail": "Réunion restaurée avec succès"}
