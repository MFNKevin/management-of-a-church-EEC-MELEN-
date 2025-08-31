# app/permissions/decision.py
from app.models.utilisateur import RoleEnum

ALLOWED_ROLES = {
    RoleEnum.Administrateur,
    RoleEnum.ResponsableLaique,
    RoleEnum.Secretaire,
}
