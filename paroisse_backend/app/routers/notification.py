from fastapi import APIRouter, Depends, HTTPException, status, BackgroundTasks
from sqlalchemy.orm import Session
from typing import List, Optional

from app.database import get_db
from app.schemas.notification import NotificationCreate, NotificationOut
from app.crud import notification as crud_notification
from app.utils.security import get_current_user
from app.permissions.notification import ALLOWED_ROLES

router = APIRouter()

def check_role(user, allowed_roles):
    if user.role not in allowed_roles:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Accès refusé : rôle non autorisé"
        )

# ✅ Créer une notification et envoyer un email si applicable
@router.post("/", response_model=NotificationOut, status_code=status.HTTP_201_CREATED)
async def creer_notification(
    notif: NotificationCreate,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    return crud_notification.create_notification_and_send_email(db, notif, background_tasks)

# ✅ Lister les notifications (avec filtrage facultatif par utilisateur)
@router.get("/", response_model=List[NotificationOut])
async def lister_notifications(
    utilisateur_id: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    return crud_notification.get_notifications(db, utilisateur_id)

# ✅ Marquer une notification comme lue
@router.put("/{notification_id}/lu", response_model=NotificationOut)
async def marquer_comme_lue(
    notification_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    notif = crud_notification.mark_as_read(db, notification_id)
    if not notif:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Notification non trouvée")
    return notif

# ✅ Suppression logique (soft delete)
@router.delete("/{notification_id}", response_model=NotificationOut)
async def supprimer_notification(
    notification_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    notif = crud_notification.soft_delete_notification(db, notification_id)
    if not notif:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Notification non trouvée")
    return notif

# ✅ Rechercher des notifications (avec options)
@router.get("/search", response_model=List[NotificationOut])
async def rechercher_notifications(
    keyword: str,
    utilisateur_id: Optional[int] = None,
    include_deleted: bool = False,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    check_role(current_user, ALLOWED_ROLES)
    return crud_notification.search_notifications(
        db=db,
        keyword=keyword,
        utilisateur_id=utilisateur_id,
        include_deleted=include_deleted
    )
