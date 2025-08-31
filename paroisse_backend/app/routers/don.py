from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from sqlalchemy import func
from datetime import datetime

from app.database import get_db
from app.models.don import Don
from app.schemas.don import DonCreate, DonUpdate, DonOut
from app.crud import don as crud_don
from app.permissions.don import ALLOWED_ROLES
from app.utils.security import get_current_user
from app.models.notification import Notification, TypeNotificationEnum
from app.schemas.recu import RecuCreate
from app.crud.recu import create_recu
from app.utils.budget import update_budget_reel, verifier_solde_disponible

router = APIRouter()

# Vérification du rôle utilisateur
def check_role(user, allowed_roles):
    if user.role not in allowed_roles:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Accès refusé : rôle non autorisé"
        )

# ✅ Création d’un don avec budget et reçu
@router.post("/", response_model=DonOut)
async def create_don(
    don: DonCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)

    try:
        # Création du don
        db_don = crud_don.create_don(db, don, utilisateur_id=current_user.utilisateur_id)

        # Création automatique du reçu
        recu_data = RecuCreate(
            montant=don.montant,
            description=f"Don reçu : {don.montant} FCFA",
            date_emission=datetime.utcnow(),
            utilisateur_id=current_user.utilisateur_id
        )
        create_recu(db, recu_data)

        # Mise à jour du budget réel
        update_budget_reel(
            db,
            annee=db_don.date_don.year,
            intitule="Don",
            utilisateur_id=current_user.utilisateur_id
        )

        # Notification succès
        notif = Notification(
            titre="Don enregistré",
            message=f"Don de {don.montant} FCFA ajouté avec succès.",
            type=TypeNotificationEnum.success,
            utilisateur_id=current_user.utilisateur_id,
            created_at=datetime.utcnow()
        )
        db.add(notif)
        db.commit()
        db.refresh(db_don)

        # Calcul du montant total des dons actifs
        montant_total = db.query(func.coalesce(func.sum(Don.montant), 0))\
            .filter(Don.deleted_at == None).scalar()
        db_don.montant_total = montant_total or 0.0

        return DonOut.from_orm(db_don)

    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"Erreur création don : {str(e)}")


# ✅ Liste paginée des dons
@router.get("/", response_model=List[DonOut])
async def list_dons(
    skip: int = 0,
    limit: int = 10,
    include_deleted: bool = False,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    return crud_don.get_dons(db, skip=skip, limit=limit, include_deleted=include_deleted)


# ✅ Récupérer un don par ID
@router.get("/{don_id}", response_model=DonOut)
async def get_don(
    don_id: int,
    include_deleted: bool = False,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    don = crud_don.get_don(db, don_id, include_deleted)
    if not don:
        raise HTTPException(status_code=404, detail="Don non trouvé")
    return don


# ✅ Mise à jour d’un don avec budget
@router.put("/{don_id}", response_model=DonOut)
async def update_don(
    don_id: int,
    don_update: DonUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    don = crud_don.update_don(db, don_id, don_update)
    if not don:
        raise HTTPException(status_code=404, detail="Don non trouvé ou supprimé")

    # Mise à jour du budget réel après modification
    update_budget_reel(
        db,
        annee=don.date_don.year,
        intitule="Don",
        utilisateur_id=current_user.utilisateur_id
    )

    # Recalcul du montant total des dons actifs
    montant_total = db.query(func.coalesce(func.sum(Don.montant), 0))\
        .filter(Don.deleted_at == None).scalar()
    don.montant_total = montant_total or 0.0

    return DonOut.from_orm(don)


# ✅ Suppression logique (soft delete) avec mise à jour budget
@router.delete("/{don_id}")
async def soft_delete_don(
    don_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    don = crud_don.soft_delete_don(db, don_id)
    if not don:
        raise HTTPException(status_code=404, detail="Don non trouvé")

    # Mise à jour du budget réel
    update_budget_reel(
        db,
        annee=don.date_don.year,
        intitule="Don",
        utilisateur_id=current_user.utilisateur_id
    )

    return {"message": "Don mis dans la corbeille"}


# ✅ Restauration d’un don supprimé
@router.put("/restore/{don_id}")
async def restore_don(
    don_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    don = crud_don.restore_don(db, don_id)
    if not don:
        raise HTTPException(status_code=404, detail="Don non trouvé ou pas supprimé")

    # Mise à jour du budget réel
    update_budget_reel(
        db,
        annee=don.date_don.year,
        intitule="Don",
        utilisateur_id=current_user.utilisateur_id
    )

    return {"message": "Don restauré"}


# ✅ Recherche dans les dons
@router.get("/search/", response_model=List[DonOut])
async def search_dons(
    q: str,
    include_deleted: bool = False,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    return crud_don.search_dons(db, q, include_deleted)
