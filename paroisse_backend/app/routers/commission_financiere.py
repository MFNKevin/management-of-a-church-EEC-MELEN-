from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload
from typing import List, Optional

from app.database import get_db
from app.models.commission_financiere import CommissionFinanciere, MembreCommission
from app.schemas.commission_financiere import *
from app.crud import commission_financiere as crud
from app.permissions.commission_financiere import ALLOWED_ROLES
from app.utils.security import get_current_user
from app.enums import RoleCommission

router = APIRouter()

def check_role(user, allowed_roles):
    if user.role not in allowed_roles:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Accès refusé : rôle non autorisé"
        )

# ---- Commission ----

@router.post("/commissions", response_model=CommissionOut)
async def create_commission(
    data: CommissionCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    return crud.create_commission(db, data)

@router.get("/commissions", response_model=List[CommissionOut])
async def list_commissions(
    include_deleted: bool = False,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    return crud.get_commissions(db, include_deleted)

@router.put("/commissions/{commission_id}", response_model=CommissionOut)
async def update_commission(
    commission_id: int,
    data: CommissionCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    commission = db.query(CommissionFinanciere).filter(
        CommissionFinanciere.commission_id == commission_id,
        CommissionFinanciere.deleted_at == None
    ).first()

    if not commission:
        raise HTTPException(status_code=404, detail="Commission non trouvée")

    commission.nom = data.nom
    commission.description = data.description
    db.commit()
    db.refresh(commission)
    return commission


@router.delete("/commissions/{commission_id}")
async def soft_delete_commission(
    commission_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    if not crud.soft_delete_commission(db, commission_id):
        raise HTTPException(status_code=404, detail="Commission non trouvée")
    return {"message": "Commission supprimée (soft delete)"}

@router.put("/commissions/restore/{commission_id}")
async def restore_commission(
    commission_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    if not crud.restore_commission(db, commission_id):
        raise HTTPException(status_code=404, detail="Commission non trouvée ou non supprimée")
    return {"message": "Commission restaurée"}

# ---- Membres ----

@router.post("/membres_commission", response_model=MembreCommissionOut)
async def create_membre_commission(
    data: MembreCommissionCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    membre = crud.create_membre_commission(db, data)

    # Recharger avec relations pour fournir nom_commission, nom_utilisateur, prenom_utilisateur
    membre = (
        db.query(MembreCommission)
        .options(
            joinedload(MembreCommission.commission),
            joinedload(MembreCommission.utilisateur)
        )
        .filter(MembreCommission.membre_commission_id == membre.membre_commission_id)
        .first()
    )

    membre.nom_commission = membre.commission.nom if membre.commission else None
    membre.nom_utilisateur = membre.utilisateur.nom if membre.utilisateur else None
    membre.prenom_utilisateur = membre.utilisateur.prenom if membre.utilisateur else None

    return membre

@router.get("/commissions/{commission_id}/membres", response_model=List[MembreCommissionOut])
async def get_membres_commission(
    commission_id: int,
    include_deleted: bool = False,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    return crud.get_membres_commission(db, commission_id, include_deleted)

@router.get("/membres_commission", response_model=List[MembreCommissionOut])
async def get_all_membres_commission(
    include_deleted: bool = False,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    return crud.get_all_membres_commission(db, include_deleted)

@router.put("/membres_commission/{membre_commission_id}", response_model=MembreCommissionOut)
async def update_membre_commission_route(
    membre_commission_id: int,
    data: MembreCommissionCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    # Vérification des permissions
    check_role(current_user, ALLOWED_ROLES)

    membre = crud.update_membre_commission(db, membre_commission_id, data)
    if not membre:
        raise HTTPException(status_code=404, detail="Membre non trouvé")

    # Recharger les relations pour retour complet
    membre = (
        db.query(MembreCommission)
        .options(
            joinedload(MembreCommission.commission),
            joinedload(MembreCommission.utilisateur)
        )
        .filter(MembreCommission.membre_commission_id == membre_commission_id)
        .first()
    )

    membre.nom_commission = membre.commission.nom if membre.commission else None
    membre.nom_utilisateur = membre.utilisateur.nom if membre.utilisateur else None
    membre.prenom_utilisateur = membre.utilisateur.prenom if membre.utilisateur else None

    return membre


@router.delete("/membres_commission/{membre_commission_id}")
async def soft_delete_membre(
    membre_commission_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    if not crud.soft_delete_membre_commission(db, membre_commission_id):
        raise HTTPException(status_code=404, detail="Membre non trouvé")
    return {"message": "Membre supprimé"}

@router.put("/membres_commission/restore/{membre_commission_id}")
async def restore_membre(
    membre_commission_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    if not crud.restore_membre_commission(db, membre_commission_id):
        raise HTTPException(status_code=404, detail="Membre non trouvé ou non supprimé")
    return {"message": "Membre restauré"}

@router.get("/roles_commission")
async def list_roles_commission(current_user=Depends(get_current_user)):
    check_role(current_user, ALLOWED_ROLES)
    return [r.value for r in RoleCommission]


@router.get("/commissions/search", response_model=List[CommissionOut])
async def search_commissions(
    nom: Optional[str] = None,
    description: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    return crud.search_commissions(db, nom=nom, description=description)
