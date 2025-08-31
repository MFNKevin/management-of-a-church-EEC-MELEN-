from app.models.utilisateur import RoleEnum

# Rôles autorisés à gérer les reçus (création, consultation, suppression...)
ALLOWED_ROLES_RECU_ADMIN = {
    RoleEnum.Administrateur,
    RoleEnum.TresorierParoissial
}
