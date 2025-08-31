from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.utils.stock_alerts import verifier_alertes_stock
from app.utils.security import get_current_user
from app.models.utilisateur import RoleEnum, Utilisateur
from typing import Set

router = APIRouter(prefix="/stock-alerts", tags=["Stock Alerts"])

ALLOWED_ROLES: Set[RoleEnum] = {RoleEnum.Evangeliste, RoleEnum.Administrateur}

def check_role(current_user: Utilisateur):
    if current_user.role not in ALLOWED_ROLES:
        raise HTTPException(status_code=403, detail=f"Permission refusée pour le rôle {current_user.role}")

@router.post("/verifier")
def verifier_alertes(
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(get_current_user)
):
    check_role(current_user)
    notifications = verifier_alertes_stock(db)
    return {"message": f"{len(notifications)} alertes générées."}
