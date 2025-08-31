from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app.database import get_db
from app.schemas.decision import DecisionCreate, DecisionUpdate, DecisionOut
from app.crud.decision import (
    create_decision,
    get_decisions,
    get_decision,
    update_decision,
    soft_delete_decision,
    restore_decision,
    search_decisions,
)
from app.permissions.decision import ALLOWED_ROLES
from app.utils.security import get_current_user

router = APIRouter()

def check_role(user, allowed_roles):
    if user.role not in allowed_roles:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Accès refusé : rôle non autorisé"
        )

def enrich_decision_out(decision) -> DecisionOut:
    out = DecisionOut.from_orm(decision)
    out.titre_reunion = decision.reunion.titre if decision.reunion else None
    out.nom_auteur = decision.auteur.nom if decision.auteur else None
    out.prenom_auteur = decision.auteur.prenom if decision.auteur else None
    return out

@router.post("/", response_model=DecisionOut)
async def create(
    d: DecisionCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    # Optionnel: forcer auteur_id = current_user.utilisateur_id
    # d.auteur_id = current_user.utilisateur_id
    dec = create_decision(db, d)
    return enrich_decision_out(dec)

@router.get("/", response_model=List[DecisionOut])
async def list(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    decisions = get_decisions(db)
    return [enrich_decision_out(d) for d in decisions]

@router.get("/{did}", response_model=DecisionOut)
async def get_one(
    did: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    dec = get_decision(db, did)
    if not dec:
        raise HTTPException(404, "Décision non trouvée")
    return enrich_decision_out(dec)

@router.put("/{did}", response_model=DecisionOut)
async def update(
    did: int,
    u: DecisionUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    dec = update_decision(db, did, u)
    if not dec:
        raise HTTPException(404, "Décision non trouvée ou supprimée")
    return enrich_decision_out(dec)

@router.delete("/{did}")
async def delete(
    did: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    if not soft_delete_decision(db, did):
        raise HTTPException(404, "Décision non trouvée")
    return {"message": "Décision archivée"}

@router.put("/restore/{did}", response_model=DecisionOut)
async def restore(
    did: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    dec = restore_decision(db, did)
    if not dec:
        raise HTTPException(404, "Décision non trouvée ou non archivée")
    return enrich_decision_out(dec)

@router.get("/search/", response_model=List[DecisionOut])
async def search(
    q: str,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    decisions = search_decisions(db, q)
    return [enrich_decision_out(d) for d in decisions]
