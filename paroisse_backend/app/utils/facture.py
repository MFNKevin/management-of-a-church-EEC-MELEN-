from sqlalchemy.orm import Session
from datetime import datetime
from app.models.facture import Facture

def generate_facture(db: Session, montant: float, type_facture: str, reference_id: int, utilisateur_id: int):
    nouvelle_facture = Facture(
        montant=montant,
        date_facture=datetime.utcnow(),
        type=type_facture,
        reference_id=reference_id,
        utilisateur_id=utilisateur_id
    )
    db.add(nouvelle_facture)
    db.commit()
    db.refresh(nouvelle_facture)
    return nouvelle_facture
