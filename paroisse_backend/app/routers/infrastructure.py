from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List
from app.schemas.infrastructure import InfrastructureCreate, InfrastructureUpdate, InfrastructureOut
from app.crud import infrastructure as crud_infra
from app.database import get_db
from app.utils.security import get_current_user
from app.permissions.infrastructure import ALLOWED_ROLES_EVANGELISTE  # ✅

router = APIRouter(prefix="/infrastructures", tags=["Infrastructure"])

def check_role(user, allowed_roles):
    if user.role not in allowed_roles:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Accès refusé : rôle non autorisé"
        )

@router.post("/", response_model=InfrastructureOut)
def create_infra(
    infra: InfrastructureCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES_EVANGELISTE)
    return crud_infra.create_infrastructure(db, infra)

@router.get("/", response_model=List[InfrastructureOut])
def list_infras(
    db: Session = Depends(get_db),
    include_deleted: bool = False,
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES_EVANGELISTE)
    return crud_infra.get_infrastructures(db, include_deleted=include_deleted)

@router.get("/{infra_id}", response_model=InfrastructureOut)
def get_infra(
    infra_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES_EVANGELISTE)
    infra = crud_infra.get_infrastructure(db, infra_id)
    if not infra:
        raise HTTPException(status_code=404, detail="Infrastructure non trouvée")
    return infra

@router.put("/{infra_id}", response_model=InfrastructureOut)
def update_infra(
    infra_id: int,
    infra: InfrastructureUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES_EVANGELISTE)
    updated = crud_infra.update_infrastructure(db, infra_id, infra)
    if not updated:
        raise HTTPException(status_code=404, detail="Infrastructure non trouvée")
    return updated

@router.delete("/{infra_id}")
def soft_delete_infra(
    infra_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES_EVANGELISTE)
    deleted = crud_infra.soft_delete_infrastructure(db, infra_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Infrastructure non trouvée")
    return {"message": "Infrastructure mise dans la corbeille"}

@router.put("/restore/{infra_id}")
def restore_infra(
    infra_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES_EVANGELISTE)
    restored = crud_infra.restore_infrastructure(db, infra_id)
    if not restored:
        raise HTTPException(status_code=404, detail="Infrastructure non trouvée ou non supprimée")
    return {"message": "Infrastructure restaurée"}


@router.get("/search/", response_model=List[InfrastructureOut])
def search_infra(
    query: str = Query(..., min_length=1),
    skip: int = 0,
    limit: int = 50,
    include_deleted: bool = False,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES_EVANGELISTE)
    return crud_infra.search_infrastructures(
        db,
        query=query,
        skip=skip,
        limit=limit,
        include_deleted=include_deleted
    )
