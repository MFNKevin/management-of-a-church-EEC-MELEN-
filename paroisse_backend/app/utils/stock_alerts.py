from sqlalchemy.orm import Session
from app.crud import stock_materiel as crud_stock
from app.crud import materiel as crud_materiel
from app.models.notification import Notification, TypeNotificationEnum
from app.models.utilisateur import Utilisateur
from app.permissions.stock_materiel import ALLOWED_ROLES_STOCK

def verifier_alertes_stock(db: Session):
    materiels = crud_materiel.get_materiels(db)
    utilisateurs_autorises = db.query(Utilisateur).filter(Utilisateur.role.in_(ALLOWED_ROLES_STOCK)).all()

    notifications_creees = []
    for materiel in materiels:
        quantite_dispo = crud_stock.get_stock_actuel_par_materiel(db, materiel.materiel_id)

        if quantite_dispo <= materiel.seuil_min:
            for user in utilisateurs_autorises:
                notif_existante = db.query(Notification).filter(
                    Notification.titre == f"Stock faible: {materiel.nom}",
                    Notification.utilisateur_id == user.utilisateur_id,
                    Notification.type == TypeNotificationEnum.warning,
                    Notification.est_lue == False
                ).first()

                if not notif_existante:
                    notif = Notification(
                        titre=f"Stock faible: {materiel.nom}",
                        message=f"Le stock du matériel '{materiel.nom}' est faible ({quantite_dispo} unité(s) disponible(s)).",
                        type=TypeNotificationEnum.warning,
                        utilisateur_id=user.utilisateur_id,
                        est_lue=False
                    )
                    db.add(notif)
                    notifications_creees.append(notif)

    if notifications_creees:
        db.commit()

    return notifications_creees
