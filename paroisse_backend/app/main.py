from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles

from app.database import engine, Base
import app.models  # Assure le chargement des modèles

# Création de l'application FastAPI
app = FastAPI(title="API Gestion Paroisse")

# Monter le dossier des images (ex: /photos/3_toto.jpg)
app.mount("/photos", StaticFiles(directory="photos"), name="photos")

# Importation des routeurs
from app.routers.auth import router as auth_router
from app.routers.achat import router as achat_router
from app.routers.budget import router as budget_router
from app.routers.chatbot import router as chatbot_router
from app.routers.commission_financiere import router as commission_financiere_router
from app.routers.decision import router as decision_router
from app.routers.don import router as don_router
from app.routers.employe import router as employe_router
from app.routers.facture import router as facture_router
from app.routers.groupe import router as groupe_router
from app.routers.inspecteur import router as inspecteur_router
from app.routers.notification import router as notification_router
from app.routers.offrande import router as offrande_router
from app.routers.quete import router as quete_router
from app.routers.recu import router as recu_router
from app.routers.rapport import router as rapport_router
from app.routers.salaire import router as salaire_router
from app.routers.sous_commission_financiere import router as sous_commission_financiere_router
from app.routers.utilisateur import router as utilisateur_router
from app.routers.reunion import router as reunion_router
from app.routers.pret import router as pret_router

# Nouveaux modules
from app.routers.stock_alerts import router as stock_alerts
from app.routers.stock_materiel import router as stock_materiel
from app.routers.maintenance import router as maintenances
from app.routers.materiel import router as materiels
from app.routers.infrastructure import router as infrastructures

# Tâches planifiées (scheduler)
from app.scheduler import start_scheduler
scheduler = start_scheduler()

# Exécuté au démarrage
@app.on_event("startup")
def startup_event():
    Base.metadata.create_all(bind=engine)
    for route in app.routes:
        print(route.path)


# Route racine
@app.get("/")
def read_root():
    return {"message": "Bienvenue dans l'API Gestion Paroisse"}

# Inclusion des routeurs par catégories
app.include_router(auth_router, prefix="/api")
app.include_router(achat_router, prefix="/api/achats", tags=["Achats"])
app.include_router(budget_router, prefix="/api/budgets", tags=["Budgets"])
app.include_router(chatbot_router, prefix="/api/chatbot", tags=["Chatbot"])
app.include_router(commission_financiere_router, prefix="/api/commission-financiere", tags=["Commission Financière"])
app.include_router(decision_router, prefix="/api/decisions", tags=["Décisions"])
app.include_router(don_router, prefix="/api/dons", tags=["Dons"])
app.include_router(employe_router, prefix="/api/employes", tags=["Employés"])
app.include_router(facture_router, prefix="/api/factures", tags=["Factures"])
app.include_router(groupe_router, prefix="/api/groupes", tags=["Groupes"])
app.include_router(infrastructures, prefix="/api/infrastructures", tags=["Infrastructure"])
app.include_router(inspecteur_router, prefix="/api/inspecteurs", tags=["Inspecteurs"])
app.include_router(maintenances, prefix="/api/maintenances", tags=["Maintenance"])
app.include_router(materiels, prefix="/api/materiels", tags=["Materiel"])
app.include_router(notification_router, prefix="/api/notifications", tags=["Notifications"])
app.include_router(offrande_router, prefix="/api/offrandes", tags=["Offrandes"])
app.include_router(pret_router, prefix="/api/pret", tags=["Pret"])
app.include_router(quete_router, prefix="/api/quetes", tags=["Quêtes"])
app.include_router(recu_router, prefix="/api/recus", tags=["Reçus"])
app.include_router(sous_commission_financiere_router, prefix="/api/sous-commission-financiere", tags=["Sous Commission Financière"])
app.include_router(rapport_router, prefix="/api/rapports", tags=["Rapports"])
app.include_router(salaire_router, prefix="/api/salaires", tags=["Salaires"])
app.include_router(stock_materiel, prefix="/api/stock", tags=["StockMateriel"])
app.include_router(stock_alerts, prefix="/api/stock-alerts", tags=["Stock Alerts"])
app.include_router(utilisateur_router, prefix="/api/utilisateurs", tags=["Utilisateurs"])
app.include_router(reunion_router, prefix="/api/reunions", tags=["Réunions"])
