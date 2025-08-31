from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.database import get_db
from app.schemas.groupe import GroupeCreate, GroupeUpdate, GroupeOut
from app.crud import groupe as crud_groupe
from app.utils.security import get_current_user
from app.permissions.groupe import ALLOWED_ROLES

router = APIRouter()

def check_role(user, allowed_roles):
    if user.role not in allowed_roles:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Accès refusé : rôle non autorisé"
        )

@router.post("/", response_model=GroupeOut)
async def create_groupe(
    groupe: GroupeCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    return crud_groupe.create_groupe(db, groupe)

@router.get("/", response_model=List[GroupeOut])
async def list_groupes(
    include_deleted: bool = False,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    return crud_groupe.get_groupes(db, include_deleted)

@router.get("/{groupe_id}", response_model=GroupeOut)
async def get_groupe(
    groupe_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    db_groupe = crud_groupe.get_groupe(db, groupe_id)
    if not db_groupe:
        raise HTTPException(status_code=404, detail="Groupe non trouvé")
    return db_groupe

@router.put("/{groupe_id}", response_model=GroupeOut)
async def update_groupe(
    groupe_id: int,
    groupe: GroupeUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    db_groupe = crud_groupe.update_groupe(db, groupe_id, groupe)
    if not db_groupe:
        raise HTTPException(status_code=404, detail="Groupe non trouvé ou supprimé")
    return db_groupe

@router.delete("/{groupe_id}")
async def soft_delete_groupe(
    groupe_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    db_groupe = crud_groupe.soft_delete_groupe(db, groupe_id)
    if not db_groupe:
        raise HTTPException(status_code=404, detail="Groupe non trouvé")
    return {"message": "Groupe mis en corbeille"}

@router.put("/restore/{groupe_id}")
async def restore_groupe(
    groupe_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    db_groupe = crud_groupe.restore_groupe(db, groupe_id)
    if not db_groupe:
        raise HTTPException(status_code=404, detail="Groupe non trouvé ou pas supprimé")
    return {"message": "Groupe restauré"}

@router.get("/search/", response_model=List[GroupeOut])
async def search_groupes(
    query: str,
    skip: int = 0,
    limit: int = 50,
    include_deleted: bool = False,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    return crud_groupe.search_groupes(db, query, skip=skip, limit=limit, include_deleted=include_deleted)
