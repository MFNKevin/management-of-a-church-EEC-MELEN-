# app/permissions/stock_materiel.py

from app.models.utilisateur import RoleEnum

ALLOWED_ROLES_STOCK = {
    RoleEnum.Administrateur,
    RoleEnum.Evangeliste,
}
