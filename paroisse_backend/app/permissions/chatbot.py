# app/permissions/chatbot.py
from app.models.utilisateur import RoleEnum

ALLOWED_ROLES = {
    RoleEnum.Administrateur,
    RoleEnum.TresorierParoissial,
    RoleEnum.ResponsableLaique,
    RoleEnum.Evangeliste,
    RoleEnum.Secretaire,
}
