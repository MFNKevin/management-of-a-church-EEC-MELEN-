from sqlalchemy.orm import Session
from datetime import datetime
from app.models.recu import Recu

def generate_recu(db: Session, montant: float, source: str, reference_id: int, utilisateur_id: int):
    nouveau_recu = Recu(
        montant=montant,
        date_emission=datetime.utcnow(),  # ✅ nom correct du champ dans le modèle
        description=f"Reçu automatique pour {source} n°{reference_id}",  # ✅ pas de champ 'source' ou 'reference_id', donc on les met dans description
        utilisateur_id=utilisateur_id
    )
    db.add(nouveau_recu)
    db.commit()
    db.refresh(nouveau_recu)
    return nouveau_recu
