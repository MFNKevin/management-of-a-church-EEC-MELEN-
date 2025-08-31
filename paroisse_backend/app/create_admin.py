# create_admin.py

from app.database import SessionLocal
from app.models.utilisateur import Utilisateur, RoleEnum
from app.utils.security import hash_password

def create_admin():
    db = SessionLocal()
    try:
        email = "admin@example.com"
        password = "admin123"  # Mot de passe initial, à changer après

        # Vérifier si l'admin existe déjà
        admin_exist = db.query(Utilisateur).filter(Utilisateur.email == email).first()
        if admin_exist:
            print(f"Un utilisateur avec l'email {email} existe déjà.")
            return

        hashed_password = hash_password(password)

        admin = Utilisateur(
            nom="Administrateur",
            prenom="Admin",
            email=email,
            mot_de_passe=hashed_password,
            role=RoleEnum.Administrateur
        )
        db.add(admin)
        db.commit()
        print(f"Admin créé avec succès avec l'email {email} et mot de passe '{password}'")
    except Exception as e:
        print(f"Erreur lors de la création de l'admin : {e}")
    finally:
        db.close()

if __name__ == "__main__":
    create_admin()
