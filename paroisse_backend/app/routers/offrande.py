from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from sqlalchemy import func
from datetime import datetime

from app.database import get_db
from app.models.offrande import Offrande
from app.schemas.offrande import OffrandeCreate, OffrandeUpdate, OffrandeOut
from app.crud import offrande as crud_offrande
from app.permissions.offrande import ALLOWED_ROLES
from app.utils.security import get_current_user
from app.models.notification import Notification, TypeNotificationEnum
from app.schemas.recu import RecuCreate
from app.crud.recu import create_recu
from app.utils.budget import update_budget_reel

router = APIRouter()

# Vérification du rôle utilisateur
def check_role(user, allowed_roles):
    if user.role not in allowed_roles:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Accès refusé : rôle non autorisé"
        )

# ========================
# ✅ Création d’une offrande
# ========================
@router.post("/", response_model=OffrandeOut)
async def create_offrande(
    offrande: OffrandeCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)

    # --- Contraintes identiques au PUT ---
    if offrande.montant is not None and offrande.montant <= 0:
        raise HTTPException(
            status_code=400,
            detail="Le montant de l'offrande doit être supérieur à zéro."
        )
    if offrande.date_offrande and offrande.date_offrande > datetime.utcnow().date():
        raise HTTPException(
            status_code=400,
            detail="La date de l'offrande ne peut pas être dans le futur."
        )

    try:
        db_offrande = crud_offrande.create_offrande(
            db, offrande, utilisateur_id=current_user.utilisateur_id
        )

        # Création automatique du reçu
        recu_data = RecuCreate(
            montant=offrande.montant,
            description=f"Offrande reçue : {offrande.montant} FCFA",
            date_emission=datetime.utcnow(),
            utilisateur_id=current_user.utilisateur_id
        )
        create_recu(db, recu_data)

        # Mise à jour du budget réel
        update_budget_reel(
            db,
            annee=db_offrande.date_offrande.year,
            intitule="Offrande",
            utilisateur_id=current_user.utilisateur_id
        )

        # Notification succès
        notif = Notification(
            titre="Offrande enregistrée",
            message=f"Offrande de {offrande.montant} FCFA ajoutée avec succès.",
            type=TypeNotificationEnum.success,
            utilisateur_id=current_user.utilisateur_id,
            created_at=datetime.utcnow()
        )
        db.add(notif)
        db.commit()
        db.refresh(db_offrande)

        # Recalcul du montant total
        montant_total = db.query(func.coalesce(func.sum(Offrande.montant), 0))\
            .filter(Offrande.deleted_at == None).scalar()
        db_offrande.montant_total = montant_total or 0.0

        return OffrandeOut.from_orm(db_offrande)
    
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=400,
            detail=f"Erreur création offrande : {str(e)}"
        )

# ========================
# ✅ Liste paginée des offrandes
# ========================
@router.get("/", response_model=List[OffrandeOut])
async def list_offrandes(
    skip: int = 0,
    limit: int = 10,
    include_deleted: bool = False,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    return crud_offrande.get_offrandes(db, skip=skip, limit=limit, include_deleted=include_deleted)

# ========================
# ✅ Récupérer une offrande par ID
# ========================
@router.get("/{offrande_id}", response_model=OffrandeOut)
async def get_offrande(
    offrande_id: int,
    include_deleted: bool = False,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    offrande = crud_offrande.get_offrande(db, offrande_id, include_deleted)
    if not offrande:
        raise HTTPException(status_code=404, detail="Offrande non trouvée")

    # Recalcul dynamique du montant total
    montant_total = db.query(func.coalesce(func.sum(Offrande.montant), 0))\
        .filter(Offrande.deleted_at == None).scalar()
    offrande.montant_total = montant_total or 0.0

    return OffrandeOut.from_orm(offrande)

# ========================
# ✅ Mise à jour d’une offrande
# ========================
@router.put("/{offrande_id}", response_model=OffrandeOut)
async def update_offrande(
    offrande_id: int,
    offrande_update: OffrandeUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)

    # --- Contraintes ---
    if offrande_update.montant is not None and offrande_update.montant <= 0:
        raise HTTPException(status_code=400, detail="Le montant de l'offrande doit être supérieur à zéro.")
    if offrande_update.date_offrande and offrande_update.date_offrande > datetime.utcnow().date():
        raise HTTPException(status_code=400, detail="La date de l'offrande ne peut pas être dans le futur.")

    try:
        db_offrande = crud_offrande.update_offrande(
            db, offrande_id, offrande_update, utilisateur_id=current_user.utilisateur_id
        )
        if not db_offrande:
            raise HTTPException(status_code=404, detail="Offrande non trouvée ou supprimée")

        update_budget_reel(
            db,
            annee=db_offrande.date_offrande.year,
            intitule="Offrande",
            utilisateur_id=current_user.utilisateur_id
        )

        db.commit()
        db.refresh(db_offrande)

        # Recalcul du montant total
        montant_total = db.query(func.coalesce(func.sum(Offrande.montant), 0))\
            .filter(Offrande.deleted_at == None).scalar()
        db_offrande.montant_total = montant_total or 0.0

        return OffrandeOut.from_orm(db_offrande)
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"Erreur mise à jour offrande : {str(e)}")

# ✅ Suppression logique (soft delete) avec mise à jour budget (via CRUD)
@router.delete("/{offrande_id}")
async def soft_delete_offrande(
    offrande_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)

    offrande = crud_offrande.soft_delete_offrande(db, offrande_id)
    if not offrande:
        raise HTTPException(status_code=404, detail="Offrande non trouvée ou déjà supprimée")

    return {"message": "Offrande mise dans la corbeille"}


# ✅ Restauration d’une offrande supprimée (via CRUD)
@router.put("/restore/{offrande_id}")
async def restore_offrande(
    offrande_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)

    offrande = crud_offrande.restore_offrande(db, offrande_id)
    if not offrande:
        raise HTTPException(status_code=404, detail="Offrande non trouvée ou pas supprimée")

    return {"message": "Offrande restaurée"}

# ========================
# ✅ Recherche dans les offrandes
# ========================
@router.get("/search/", response_model=List[OffrandeOut])
async def search_offrandes(
    q: str,
    include_deleted: bool = False,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    return crud_offrande.search_offrandes(db, q, include_deleted)
