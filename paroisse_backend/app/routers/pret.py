from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.permissions.pret import ALLOWED_ROLES
from app.schemas.pret import PretCreate, PretUpdate, PretOut
from app.crud import pret as crud_pret
from app.database import get_db
from app.utils.security import get_current_user

router = APIRouter(prefix="/prets", tags=["Prêts"])


def check_role(user, allowed_roles):
    if user.role not in allowed_roles:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Accès refusé : rôle non autorisé"
        )


@router.post("/", response_model=PretOut)
def create_pret(
    pret: PretCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)

    if not pret.materiel_id and not pret.infrastructure_id:
        raise HTTPException(status_code=400, detail="Un prêt doit concerner soit un matériel, soit une infrastructure.")

    return crud_pret.create_pret(db, pret)


@router.get("/", response_model=List[PretOut])
def list_prets(
    db: Session = Depends(get_db),
    include_deleted: bool = False,
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    return crud_pret.get_prets(db, include_deleted)


@router.get("/{pret_id}", response_model=PretOut)
def get_pret(
    pret_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    pret = crud_pret.get_pret(db, pret_id)
    if not pret:
        raise HTTPException(status_code=404, detail="Prêt non trouvé")
    return pret


@router.put("/{pret_id}", response_model=PretOut)
def update_pret(
    pret_id: int,
    pret: PretUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    pret = crud_pret.update_pret(db, pret_id, pret)
    if not pret:
        raise HTTPException(status_code=404, detail="Prêt non trouvé")
    return pret


@router.delete("/{pret_id}")
def soft_delete_pret(
    pret_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    pret = crud_pret.soft_delete_pret(db, pret_id)
    if not pret:
        raise HTTPException(status_code=404, detail="Prêt non trouvé")
    return {"message": "Prêt mis dans la corbeille"}


@router.put("/restore/{pret_id}")
def restore_pret(
    pret_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    pret = crud_pret.restore_pret(db, pret_id)
    if not pret:
        raise HTTPException(status_code=404, detail="Prêt non trouvé ou non supprimé")
    return {"message": "Prêt restauré"}


@router.get("/search", response_model=List[PretOut])
def search_prets(
    keyword: str,
    include_deleted: bool = False,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    return crud_pret.search_prets(db, keyword, include_deleted)
