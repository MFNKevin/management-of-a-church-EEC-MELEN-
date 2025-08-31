from sqlalchemy.orm import Session
from sqlalchemy import or_
from datetime import datetime
from app.models.rapport import Rapport
from app.models.utilisateur import Utilisateur

# --- FONCTIONS CRUD DE BASE ---

def get_rapports(db: Session, include_deleted: bool = False):
    query = db.query(Rapport)
    if not include_deleted:
        query = query.filter(Rapport.deleted_at == None)
    return query.order_by(Rapport.date_rapport.desc()).all()

def get_rapport(db: Session, rapport_id: int):
    return db.query(Rapport).filter(Rapport.rapport_id == rapport_id).first()

def create_rapport(db: Session, rapport, utilisateur_id: int = None):
    nouveau = Rapport(
        titre=rapport.titre,
        contenu=rapport.contenu,
        type=rapport.type,
        date_rapport=rapport.date_rapport or datetime.utcnow(),
        utilisateur_id=utilisateur_id
    )
    db.add(nouveau)
    db.commit()
    db.refresh(nouveau)
    return nouveau

from datetime import datetime

def update_rapport(db: Session, rapport_id: int, rapport_update):
    rapport = get_rapport(db, rapport_id)
    if not rapport:
        return None

    update_data = rapport_update.dict(exclude_unset=True)

    # Retirer 'type' s'il est dans les données de mise à jour pour ne pas modifier ce champ
    if 'type' in update_data:
        update_data.pop('type')

    for attr, value in update_data.items():
        setattr(rapport, attr, value)

    rapport.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(rapport)
    return rapport


def soft_delete_rapport(db: Session, rapport_id: int):
    rapport = get_rapport(db, rapport_id)
    if not rapport or rapport.deleted_at:
        return None
    rapport.deleted_at = datetime.utcnow()
    db.commit()
    return rapport

def restore_rapport(db: Session, rapport_id: int):
    rapport = get_rapport(db, rapport_id)
    if not rapport or not rapport.deleted_at:
        return None
    rapport.deleted_at = None
    db.commit()
    return rapport

def search_rapports(db: Session, query: str = None, type: str = None):
    q = db.query(Rapport).filter(Rapport.deleted_at == None)

    if query:
        q = q.filter(or_(
            Rapport.titre.ilike(f"%{query}%"),
            Rapport.contenu.ilike(f"%{query}%")
        ))

    if type:
        q = q.filter(Rapport.type == type)

    return q.order_by(Rapport.date_rapport.desc()).all()

# --- CRÉATION PAR TYPE (version sans restriction de rôle) ---

def create_rapport_financier(db: Session, rapport, utilisateur_id: int):
    rapport.type = "financier"
    return create_rapport(db, rapport, utilisateur_id)

def create_rapport_administratif(db: Session, rapport, utilisateur_id: int):
    rapport.type = "administratif"
    return create_rapport(db, rapport, utilisateur_id)

def create_rapport_materiel(db: Session, rapport, utilisateur_id: int):
    rapport.type = "materiel"
    return create_rapport(db, rapport, utilisateur_id)

def create_rapport_audit(db: Session, rapport, utilisateur_id: int):
    rapport.type = "audit"
    return create_rapport(db, rapport, utilisateur_id)

# --- RAPPORTS FINANCIERS / ADMINISTRATIFS / MATERIELS / AUDIT ---

def generer_rapport_financier_annuel(db: Session, annee: int, utilisateur_id: int):
    # Données simulées (remplacer par vos calculs réels)
    recettes = {
        "details": {
            "dons": 1000000,
            "offrandes": 500000,
            "quetes": 300000
        },
        "total": 1800000
    }

    depenses = {
        "details": {
            "achats": 400000,
            "salaires": 300000,
            "factures": 250000
        },
        "total": 950000
    }

    budget_previsionnel = 2000000
    budget_reel = recettes["total"] - depenses["total"]
    ecart = budget_previsionnel - (recettes["total"] + depenses["total"])
    solde = recettes["total"] - depenses["total"]

    return {
        "annee": annee,
        "recettes": recettes,
        "depenses": depenses,
        "budget": {
            "previsionnel": budget_previsionnel,
            "reel": budget_reel,
            "ecart": ecart
        },
        "solde": solde
    }

def generer_rapport_administratif(db: Session, date_debut: datetime = None, date_fin: datetime = None):
    query = db.query(Rapport).filter(Rapport.type == "administratif", Rapport.deleted_at == None)
    if date_debut:
        query = query.filter(Rapport.date_rapport >= date_debut)
    if date_fin:
        query = query.filter(Rapport.date_rapport <= date_fin)
    rapports = query.order_by(Rapport.date_rapport.desc()).all()

    return {
        "total_rapports": len(rapports),
        "rapports": [
            {
                "titre": r.titre,
                "date_rapport": r.date_rapport.strftime("%Y-%m-%d"),
                "auteur": r.utilisateur.nom if r.utilisateur else "Inconnu",
                "contenu": r.contenu
            } for r in rapports
        ]
    }

def generer_rapport_materiel(db: Session, date_debut: datetime = None, date_fin: datetime = None):
    # Données fictives à remplacer par vos propres requêtes ou jointures
    return {
        "materiels": {
            "total": 50,
            "etat": {
                "bon": 30,
                "moyen": 15,
                "endommagé": 5
            },
            "pret": [
                {
                    "materiel": "Chaise",
                    "beneficiaire": "Jean",
                    "date_pret": "2025-04-01",
                    "date_retour_prevue": "2025-04-10",
                    "date_retour_effective": None,
                    "etat_retour": "bon"
                }
            ]
        },
        "infrastructures": {
            "total": 10,
            "etat": {
                "bon": 6,
                "moyen": 3,
                "endommagé": 1
            },
            "pret": [
                {
                    "infrastructure": "Salle paroissiale",
                    "beneficiaire": "Marie",
                    "date_pret": "2025-03-10",
                    "date_retour_prevue": "2025-03-15",
                    "date_retour_effective": "2025-03-14",
                    "etat_retour": "moyen"
                }
            ]
        }
    }

def generer_rapport_audit_compile(db: Session, date_debut: datetime, date_fin: datetime):
    return {
        "periode": {
            "date_debut": date_debut.strftime("%Y-%m-%d"),
            "date_fin": date_fin.strftime("%Y-%m-%d"),
            "annee_financiere": date_debut.year
        },
        "administratif": generer_rapport_administratif(db, date_debut, date_fin),
        "financier": generer_rapport_financier_annuel(db, date_debut.year, utilisateur_id=None),
        "materiel": generer_rapport_materiel(db, date_debut, date_fin)
    }
