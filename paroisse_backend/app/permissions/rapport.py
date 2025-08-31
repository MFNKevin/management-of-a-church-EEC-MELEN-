from app.models.utilisateur import RoleEnum

# Rôles autorisés par type de rapport
ALLOWED_ROLES_FINANCIER = {
    RoleEnum.Administrateur,
    RoleEnum.TresorierParoissial
}

ALLOWED_ROLES_ADMINISTRATIF = {
    RoleEnum.Administrateur, 
    RoleEnum.Secretaire
}

ALLOWED_ROLES_AUDIT = {
    RoleEnum.Administrateur,    
    RoleEnum.Inspecteur
}

ALLOWED_ROLES_MATERIEL = {
    RoleEnum.Administrateur,
    RoleEnum.Evangeliste
}

