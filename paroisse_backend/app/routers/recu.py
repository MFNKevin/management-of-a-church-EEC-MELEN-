from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app.schemas.recu import RecuCreate, RecuOut
from app.crud import recu as crud_recu
from app.database import get_db
from app.utils.security import get_current_user
from app.permissions.recu import ALLOWED_ROLES_RECU_ADMIN

router = APIRouter()

def check_role(current_user):
    if current_user.role not in ALLOWED_ROLES_RECU_ADMIN:
        raise HTTPException(status_code=403, detail=f"Permission refusée pour le rôle {current_user.role}")

@router.post("/", response_model=RecuOut)
def create_recu(recu: RecuCreate, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    check_role(current_user)
    return crud_recu.create_recu(db, recu)

@router.get("/", response_model=List[RecuOut])
def list_recus(db: Session = Depends(get_db), include_deleted: bool = False, current_user=Depends(get_current_user)):
    check_role(current_user)
    return crud_recu.get_recus(db, include_deleted=include_deleted)

# La route /search doit être avant la route dynamique /{recu_id}
@router.get("/search", response_model=List[RecuOut])
def search_recus(
    keyword: str,
    include_deleted: bool = False,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user)
    return crud_recu.search_recus(db, keyword, include_deleted)

@router.get("/{recu_id}", response_model=RecuOut)
def get_recu(recu_id: int, db: Session = Depends(get_db), include_deleted: bool = False, current_user=Depends(get_current_user)):
    check_role(current_user)
    recu = crud_recu.get_recu(db, recu_id, include_deleted=include_deleted)
    if not recu:
        raise HTTPException(status_code=404, detail="Reçu non trouvé")
    return recu

@router.delete("/{recu_id}")
def soft_delete_recu(recu_id: int, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    check_role(current_user)
    recu = crud_recu.soft_delete_recu(db, recu_id)
    if not recu:
        raise HTTPException(status_code=404, detail="Reçu non trouvé")
    return {"message": "Reçu mis dans la corbeille"}

@router.put("/restore/{recu_id}")
def restore_recu(recu_id: int, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    check_role(current_user)
    recu = crud_recu.restore_recu(db, recu_id)
    if not recu:
        raise HTTPException(status_code=404, detail="Reçu non trouvé ou pas supprimé")
    return {"message": "Reçu restauré"}
