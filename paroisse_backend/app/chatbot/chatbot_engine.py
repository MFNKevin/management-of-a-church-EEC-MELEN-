from sqlalchemy.orm import Session
from .intentions import FAQ
from app.models.don import Don
from app.models.rapport import Rapport
from app.models.quete import Quete
from app.models.facture import Facture
from app.models.budget import Budget
from datetime import datetime
from sqlalchemy import func


def repondre_question(message: str, db: Session) -> str:
    message = message.lower()

    # Réponses statiques d'abord
    for mot_cle, reponse in FAQ.items():
        if mot_cle in message:
            return reponse

    # Réponses dynamiques ensuite
    if "dernier don" in message:
        don = db.query(Don).filter(Don.deleted_at == None).order_by(Don.date_don.desc()).first()
        return f"Dernier don reçu : {don.montant} FCFA le {don.date_don}" if don else "Aucun don trouvé."

    if "rapports disponibles" in message:
        rapports = db.query(Rapport).filter(Rapport.deleted_at == None).all()
        return f"{len(rapports)} rapport(s) disponible(s)." if rapports else "Aucun rapport disponible."

    if "nombre de quêtes" in message or "combien de quêtes" in message:
        mois_actuel = datetime.utcnow().month
        annee_actuelle = datetime.utcnow().year
        quetes = db.query(Quete).filter(
            Quete.deleted_at == None,
            func.month(Quete.date_quete) == mois_actuel,
            func.year(Quete.date_quete) == annee_actuelle
        ).count()
        return f"{quetes} quête(s) ont été enregistrées ce mois-ci."

    if "budget" in message:
        budget = db.query(Budget).filter(Budget.deleted_at == None).order_by(Budget.date_creation.desc()).first()
        return f"Le budget actuel est de {budget.montant_total} FCFA" if budget else "Aucun budget disponible."

    if "factures impayées" in message:
        factures = db.query(Facture).filter(Facture.statut == "non payé", Facture.deleted_at == None).count()
        return f"Il y a {factures} facture(s) impayée(s)."

    return "Je suis désolé, je n'ai pas compris votre question. Essayez avec d'autres mots."


