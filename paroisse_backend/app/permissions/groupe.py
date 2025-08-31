from app.models.utilisateur import RoleEnum

ALLOWED_ROLES = {
    RoleEnum.Administrateur,
    RoleEnum.ResponsableLaique,  # Par exemple, car ils gèrent les groupes
    RoleEnum.Secretaire,          # Optionnel selon tes besoins
}
