# app/enums.py

from enum import Enum

class RoleCommission(str, Enum):
    president = "Président"
    secretaire = "Secrétaire"
    tresorier = "Trésorier"
    membre = "Membre"
