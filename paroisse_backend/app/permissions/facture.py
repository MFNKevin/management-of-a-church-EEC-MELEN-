# app/permissions/facture.py

from app.models.utilisateur import RoleEnum

ALLOWED_ROLES = {
    RoleEnum.Administrateur,
    RoleEnum.TresorierParoissial,
}
