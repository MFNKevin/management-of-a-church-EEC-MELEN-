from app.models.utilisateur import RoleEnum

# Seuls les admins peuvent gérer les utilisateurs
ALLOWED_ROLES_UTILISATEUR = {
    RoleEnum.Administrateur
    
}
