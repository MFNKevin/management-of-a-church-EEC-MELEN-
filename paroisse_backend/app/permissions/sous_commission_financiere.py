from app.models.utilisateur import RoleEnum

# Rôles autorisés à gérer les sous-commissions financières
ALLOWED_ROLES_SOUS_COMMISSION = {
    RoleEnum.Administrateur,
    RoleEnum.TresorierParoissial
}
