from datetime import date
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from typing import List, Optional

from app.database import get_db
from app.schemas.achat import AchatCreate, AchatUpdate, AchatOut
from app.crud import achat as crud
from app.permissions.achat import ALLOWED_ROLES
from app.utils.security import get_current_user

router = APIRouter()


def check_role(user, allowed_roles):
    if user.role not in allowed_roles:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Accès refusé : rôle non autorisé"
        )


@router.post("/", response_model=AchatOut)
async def create(
    achat: AchatCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    return crud.create_achat(db, achat, utilisateur_id=current_user.utilisateur_id)


@router.get("/", response_model=List[AchatOut])
async def list_all(
    db: Session = Depends(get_db),
    include_deleted: bool = False,
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    return crud.get_achats(db, include_deleted)


@router.get("/search", response_model=List[AchatOut])
async def search_achats_route(
    libelle: Optional[str] = Query(None, description="Libellé de l'achat"),
    date_achat: Optional[date] = Query(None, description="Date exacte de l'achat"),
    fournisseur: Optional[str] = Query(None, description="Nom du fournisseur"),
    montant_min: Optional[float] = Query(None, description="Montant minimum"),
    montant_max: Optional[float] = Query(None, description="Montant maximum"),
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)

    return crud.search_achats(
        db=db,
        libelle=libelle,
        date_achat=date_achat,
        fournisseur=fournisseur,
        montant_min=montant_min,
        montant_max=montant_max
    )


@router.get("/supprimes", response_model=List[AchatOut])
def lire_achats_supprimes(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    return crud.get_achats(db, include_deleted=True)


@router.get("/{achat_id}", response_model=AchatOut)
async def get(
    achat_id: int,
    db: Session = Depends(get_db),
    include_deleted: bool = False,
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    achat = crud.get_achat(db, achat_id, include_deleted)
    if not achat:
        raise HTTPException(status_code=404, detail="Achat non trouvé")
    return achat


@router.put("/{achat_id}", response_model=AchatOut)
async def update(
    achat_id: int,
    achat: AchatUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    updated = crud.update_achat(db, achat_id, achat)
    if not updated:
        raise HTTPException(status_code=404, detail="Achat non trouvé")
    return updated


@router.delete("/{achat_id}")
async def soft_delete(
    achat_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    deleted = crud.soft_delete_achat(db, achat_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Achat non trouvé ou déjà supprimé")
    return {"message": "Achat supprimé logiquement"}


@router.put("/restore/{achat_id}")
async def restore(
    achat_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    restored = crud.restore_achat(db, achat_id)
    if not restored:
        raise HTTPException(status_code=404, detail="Achat non trouvé ou non supprimé")
    return {"message": "Achat restauré avec succès"}
