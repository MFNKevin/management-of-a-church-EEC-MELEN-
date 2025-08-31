from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.schemas.quete import QueteCreate, QueteUpdate, QueteOut
from app.crud import quete as crud_quete
from app.database import get_db
from app.utils.security import get_current_user
from app.permissions.quete import ALLOWED_ROLES

router = APIRouter()


def check_role(user, allowed_roles):
    if user.role not in allowed_roles:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Accès refusé : rôle non autorisé"
        )


# ========================
# ✅ Création d’une quête
# ========================
@router.post("/", response_model=QueteOut)
async def create_quete(
    quete: QueteCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)

    try:
        db_quete = crud_quete.create_quete(db, quete, utilisateur_id=current_user.utilisateur_id)
        return QueteOut.from_orm(db_quete)
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Erreur création quête : {str(e)}")


# ========================
# ✅ Liste paginée
# ========================
@router.get("/", response_model=List[QueteOut])
async def list_quetes(
    skip: int = 0,
    limit: int = 10,
    include_deleted: bool = False,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    return crud_quete.get_quetes(db, skip=skip, limit=limit, include_deleted=include_deleted)


# ========================
# ✅ Détails d’une quête
# ========================
@router.get("/{quete_id}", response_model=QueteOut)
async def get_quete(
    quete_id: int,
    include_deleted: bool = False,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)

    quete = crud_quete.get_quete(db, quete_id, include_deleted=include_deleted)
    if not quete:
        raise HTTPException(status_code=404, detail="Quête non trouvée")
    return QueteOut.from_orm(quete)


# ========================
# ✅ Mise à jour
# ========================
@router.put("/{quete_id}", response_model=QueteOut)
async def update_quete(
    quete_id: int,
    quete_update: QueteUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)

    db_quete = crud_quete.update_quete(db, quete_id, quete_update)
    if not db_quete:
        raise HTTPException(status_code=404, detail="Quête non trouvée ou supprimée")

    return QueteOut.from_orm(db_quete)


# ========================
# ✅ Suppression logique
# ========================
@router.delete("/{quete_id}")
async def soft_delete_quete(
    quete_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)

    quete = crud_quete.soft_delete_quete(db, quete_id)
    if not quete:
        raise HTTPException(status_code=404, detail="Quête non trouvée ou déjà supprimée")

    return {"message": "Quête mise dans la corbeille"}


# ========================
# ✅ Restauration
# ========================
@router.put("/restore/{quete_id}")
async def restore_quete(
    quete_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)

    quete = crud_quete.restore_quete(db, quete_id)
    if not quete:
        raise HTTPException(status_code=404, detail="Quête non trouvée ou pas supprimée")

    return {"message": "Quête restaurée avec succès"}


# ========================
# ✅ Recherche
# ========================
@router.get("/search/", response_model=List[QueteOut])
async def search_quetes(
    q: str,
    include_deleted: bool = False,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    return crud_quete.search_quetes(db, q, include_deleted)
