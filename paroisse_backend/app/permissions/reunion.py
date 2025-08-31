from app.models.utilisateur import RoleEnum

# Les rôles autorisés à gérer les réunions
ALLOWED_ROLES_REUNION = {
    RoleEnum.Administrateur,
    RoleEnum.Secretaire,
    RoleEnum.Pasteur
}
