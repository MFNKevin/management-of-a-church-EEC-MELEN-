# app/permissions/maintenance.py
from app.models.utilisateur import RoleEnum

# Seul l'évangéliste peut gérer les infrastructures et maintenances
ALLOWED_INFRA_ROLES = {
    RoleEnum.Administrateur,
    RoleEnum.Evangeliste,
}
