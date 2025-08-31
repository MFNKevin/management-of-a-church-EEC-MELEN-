# app/permissions/commission_financiere.py
from app.models.utilisateur import RoleEnum

# Seuls les Administrateurs, Trésoriers et membres de commission peuvent gérer cela
ALLOWED_ROLES = {
    RoleEnum.Administrateur,
    RoleEnum.TresorierParoissial,
}
