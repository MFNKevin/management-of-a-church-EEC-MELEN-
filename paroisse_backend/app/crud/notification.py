from typing import Optional
from sqlalchemy.orm import Session
from app.models.notification import Notification, TypeNotificationEnum
from app.models.utilisateur import Utilisateur
from app.schemas.notification import NotificationCreate
from datetime import datetime
from app.utils.email import send_email
from fastapi import BackgroundTasks


def create_notification(
    db: Session,
    utilisateur_id: int,
    titre: str,
    message: str,
    type_notif: str = "info"
):
    notif = Notification(
        titre=titre,
        message=message,
        type=TypeNotificationEnum(type_notif),
        utilisateur_id=utilisateur_id,
        email_envoye=False,
        email_envoye_at=None,
        est_lue=False,
        created_at=datetime.utcnow()
    )
    db.add(notif)
    db.commit()
    db.refresh(notif)
    return notif


def create_notification_from_schema(db: Session, notif: NotificationCreate):
    db_notif = Notification(
        titre=notif.titre,
        message=notif.message,
        type=notif.type,
        utilisateur_id=notif.utilisateur_id,
        email_envoye=False,
        email_envoye_at=None,
        est_lue=False,
        created_at=datetime.utcnow()
    )
    db.add(db_notif)
    db.commit()
    db.refresh(db_notif)
    return db_notif


def create_notification_and_send_email(
    db: Session,
    notif: NotificationCreate,
    background_tasks: BackgroundTasks
):
    db_notif = Notification(
        titre=notif.titre,
        message=notif.message,
        type=notif.type,
        utilisateur_id=notif.utilisateur_id,
        email_envoye=False,
        email_envoye_at=None,
        est_lue=False,
        created_at=datetime.utcnow()
    )
    db.add(db_notif)
    db.commit()
    db.refresh(db_notif)

    if db_notif.utilisateur_id:
        utilisateur = db.query(Utilisateur).filter(Utilisateur.utilisateur_id == db_notif.utilisateur_id).first()
        if utilisateur and utilisateur.email:
            subject = f"Nouvelle notification : {db_notif.titre}"
            body = f"<p>{db_notif.message}</p>"

            # Envoi d’email en arrière-plan
            background_tasks.add_task(send_email, subject, utilisateur.email, body)

            # Mise à jour des champs après l’envoi
            db_notif.email_envoye = True
            db_notif.email_envoye_at = datetime.utcnow()
            db.commit()
            db.refresh(db_notif)

    return db_notif


def get_notifications(db: Session, utilisateur_id: Optional[int] = None):
    query = db.query(Notification).filter(Notification.deleted_at == None)
    if utilisateur_id:
        query = query.filter(
            (Notification.utilisateur_id == utilisateur_id) | (Notification.utilisateur_id == None)
        )
    return query.order_by(Notification.created_at.desc()).all()


def mark_as_read(db: Session, notification_id: int):
    notif = db.query(Notification).filter(Notification.notification_id == notification_id).first()
    if not notif:
        return None
    notif.est_lue = True
    notif.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(notif)
    return notif


def soft_delete_notification(db: Session, notification_id: int):
    notif = db.query(Notification).filter(Notification.notification_id == notification_id).first()
    if notif and notif.deleted_at is None:
        notif.deleted_at = datetime.utcnow()
        notif.updated_at = datetime.utcnow()
        db.commit()
        db.refresh(notif)
    return notif


def search_notifications(
    db: Session,
    keyword: str,
    utilisateur_id: Optional[int] = None,
    include_deleted: bool = False
):
    query = db.query(Notification)

    if not include_deleted:
        query = query.filter(Notification.deleted_at == None)

    if utilisateur_id:
        query = query.filter(
            (Notification.utilisateur_id == utilisateur_id) | (Notification.utilisateur_id == None)
        )

    keyword = f"%{keyword}%"
    query = query.filter(
        (Notification.titre.ilike(keyword)) |
        (Notification.message.ilike(keyword))
    )

    return query.order_by(Notification.created_at.desc()).all()
