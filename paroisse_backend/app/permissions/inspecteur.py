from app.models.utilisateur import RoleEnum

ALLOWED_ROLES = {
    RoleEnum.Administrateur,
    RoleEnum.Evangeliste,  # exemple, à ajuster selon ta logique métier
}
