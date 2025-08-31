from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app.schemas.salaire import SalaireCreate, SalaireOut
from app.crud import salaire as crud_salaire
from app.database import get_db
from app.utils.security import get_current_user
from app.permissions.salaire import ALLOWED_ROLES_SALAIRE

router = APIRouter()


def check_role(user, allowed_roles):
    if user.role not in allowed_roles:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Accès refusé : rôle non autorisé"
        )


@router.post("/", response_model=SalaireOut)
def create_salaire(
    data: SalaireCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES_SALAIRE)
    return crud_salaire.create_salaire(db, data, current_user.utilisateur_id)


@router.get("/", response_model=List[SalaireOut])
def list_salaires(
    include_deleted: bool = False,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES_SALAIRE)
    return crud_salaire.get_salaires(db, include_deleted)


# ✅ Cette route doit venir AVANT /{salaire_id}
@router.get("/search", response_model=List[SalaireOut])
def search_salaires(
    keyword: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES_SALAIRE)
    return crud_salaire.search_salaires(db, keyword)


@router.get("/{salaire_id}", response_model=SalaireOut)
def get_salaire(
    salaire_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES_SALAIRE)
    salaire = crud_salaire.get_salaire(db, salaire_id)
    if not salaire:
        raise HTTPException(status_code=404, detail="Salaire non trouvé")
    return salaire


@router.delete("/{salaire_id}")
def soft_delete_salaire(
    salaire_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES_SALAIRE)
    salaire = crud_salaire.soft_delete_salaire(db, salaire_id)
    if not salaire:
        raise HTTPException(status_code=404, detail="Salaire non trouvé")
    return {"message": "Salaire supprimé (soft delete)"}


@router.put("/restore/{salaire_id}")
def restore_salaire(
    salaire_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES_SALAIRE)
    salaire = crud_salaire.restore_salaire(db, salaire_id)
    if not salaire:
        raise HTTPException(status_code=404, detail="Salaire non trouvé ou non supprimé")
    return {"message": "Salaire restauré"}
