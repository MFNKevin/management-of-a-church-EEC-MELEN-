from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List

from app.schemas.maintenance import MaintenanceCreate, MaintenanceUpdate, MaintenanceOut
from app.crud import maintenance as crud
from app.database import get_db
from app.utils.security import get_current_user
from app.permissions.maintenance import ALLOWED_INFRA_ROLES  # <-- Import clair

router = APIRouter(prefix="/maintenances", tags=["Maintenance"])

def check_role(user, allowed_roles):
    if user.role not in allowed_roles:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Accès refusé : rôle non autorisé"
        )

@router.post("/", response_model=MaintenanceOut)
def create(
    maintenance: MaintenanceCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_INFRA_ROLES)
    return crud.create_maintenance(db, maintenance)

@router.get("/", response_model=List[MaintenanceOut])
def list_all(
    db: Session = Depends(get_db),
    include_deleted: bool = False,
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_INFRA_ROLES)
    return crud.get_maintenances(db, include_deleted)

@router.get("/{maintenance_id}", response_model=MaintenanceOut)
def get(
    maintenance_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_INFRA_ROLES)
    obj = crud.get_maintenance(db, maintenance_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Maintenance non trouvée")
    return obj

@router.put("/{maintenance_id}", response_model=MaintenanceOut)
def update(
    maintenance_id: int,
    data: MaintenanceUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_INFRA_ROLES)
    obj = crud.update_maintenance(db, maintenance_id, data)
    if not obj:
        raise HTTPException(status_code=404, detail="Maintenance non trouvée")
    return obj

@router.delete("/{maintenance_id}")
def soft_delete(
    maintenance_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_INFRA_ROLES)
    obj = crud.soft_delete_maintenance(db, maintenance_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Maintenance non trouvée")
    return {"message": "Maintenance mise en corbeille"}

@router.put("/restore/{maintenance_id}")
def restore(
    maintenance_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_INFRA_ROLES)
    obj = crud.restore_maintenance(db, maintenance_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Maintenance non trouvée ou non supprimée")
    return {"message": "Maintenance restaurée"}


@router.get("/search/", response_model=List[MaintenanceOut])
def search_maintenances(
    query: str = Query(..., min_length=1),
    skip: int = 0,
    limit: int = 50,
    include_deleted: bool = False,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_INFRA_ROLES)
    return crud.search_maintenances(
        db=db,
        query=query,
        skip=skip,
        limit=limit,
        include_deleted=include_deleted
    )
