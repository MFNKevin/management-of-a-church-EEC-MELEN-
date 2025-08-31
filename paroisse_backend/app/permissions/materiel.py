# app/permissions/materiel.py

from app.models.utilisateur import RoleEnum

# Rôles autorisés pour accéder aux routes liées au matériel
ALLOWED_ROLES_EVANGELISTE = {
    RoleEnum.Administrateur,
    RoleEnum.Evangeliste,
}
