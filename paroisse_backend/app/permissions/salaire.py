from app.models.utilisateur import RoleEnum

# Rôles autorisés à gérer les salaires
ALLOWED_ROLES_SALAIRE = {
    RoleEnum.Administrateur,
    RoleEnum.TresorierParoissial
}
