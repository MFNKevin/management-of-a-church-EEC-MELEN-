from app.models.utilisateur import RoleEnum

ALLOWED_ROLES = {
    RoleEnum.TresorierParoissial,
    RoleEnum.Administrateur,
}
