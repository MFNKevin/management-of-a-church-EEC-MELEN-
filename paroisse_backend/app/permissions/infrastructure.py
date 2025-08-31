# app/permissions/infrastructure.py

from app.models.utilisateur import RoleEnum

# Rôles autorisés pour accéder aux routes liées aux infrastructures
ALLOWED_ROLES_EVANGELISTE = {
    RoleEnum.Administrateur,
    RoleEnum.Evangeliste,
}
