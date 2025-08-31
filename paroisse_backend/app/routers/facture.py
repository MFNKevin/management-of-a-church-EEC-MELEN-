from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from typing import List
from app.database import get_db
from app.schemas.facture import FactureCreate, FactureOut, FactureUpdate
from app.crud import facture as crud_facture
from app.database import SessionLocal
from app.utils.security import get_current_user
from app.permissions.facture import ALLOWED_ROLES

router = APIRouter()


def check_role(user, allowed_roles):
    if user.role not in allowed_roles:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Accès refusé : rôle non autorisé"
        )


@router.post("/", response_model=FactureOut)
async def create_facture(
    facture: FactureCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    return crud_facture.create_facture(db, facture)


@router.get("/", response_model=List[FactureOut])
async def list_factures(
    skip: int = 0,
    limit: int = 100,
    include_deleted: bool = False,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    return crud_facture.get_factures(db, include_deleted=include_deleted, skip=skip, limit=limit)


@router.get("/search/", response_model=List[FactureOut])
async def search_factures(
    query: str = Query(..., min_length=1, description="Texte à chercher dans le numéro ou la description"),
    skip: int = 0,
    limit: int = 50,
    include_deleted: bool = False,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)

    q = db.query(crud_facture.Facture)
    if not include_deleted:
        q = q.filter(crud_facture.Facture.deleted_at == None)

    search_filter = (
        crud_facture.Facture.numero.ilike(f"%{query}%") |
        crud_facture.Facture.description.ilike(f"%{query}%")
    )
    q = q.filter(search_filter)
    q = q.order_by(crud_facture.Facture.date_facture.desc())
    factures = q.offset(skip).limit(limit).all()

    return factures


@router.get("/factures/{facture_id}", response_model=FactureOut)
async def get_facture(
    facture_id: int,
    include_deleted: bool = False,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    facture = crud_facture.get_facture(db, facture_id, include_deleted=include_deleted)
    if not facture:
        raise HTTPException(status_code=404, detail="Facture non trouvée")
    return facture


@router.put("/factures/{facture_id}", response_model=FactureOut)
async def update_facture(
    facture_id: int,
    facture_update: FactureUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    facture = crud_facture.update_facture(db, facture_id, facture_update)
    if not facture:
        raise HTTPException(status_code=404, detail="Facture non trouvée")
    return facture


@router.delete("/{facture_id}")
async def soft_delete_facture(
    facture_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)

    try:
        facture = crud_facture.soft_delete_facture(db, facture_id)
        if not facture:
            return {"success": False, "message": "Facture non trouvée."}
        return {"success": True, "message": "Facture mise dans la corbeille."}
    except Exception as e:
        # Retourne un JSON avec succès false et message d'erreur explicite
        return {"success": False, "message": f"Impossible de supprimer la facture : {str(e)}"}



@router.put("/factures/restore/{facture_id}")
async def restore_facture(
    facture_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)

    try:
        facture = crud_facture.restore_facture(db, facture_id)
        if not facture:
            raise HTTPException(status_code=404, detail="Facture non trouvée ou pas supprimée")
        return {"message": "Facture restaurée"}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/factures/search/", response_model=List[FactureOut])
async def search_factures(
    query: str = Query(..., min_length=1, description="Texte à chercher dans numéro ou description"),
    skip: int = 0,
    limit: int = 50,
    include_deleted: bool = False,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    factures = crud_facture.search_factures(db, query, include_deleted, skip, limit)
    return factures
