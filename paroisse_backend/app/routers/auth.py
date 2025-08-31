from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from fastapi.security import OAuth2PasswordRequestForm

from app.database import get_db
from app.models.utilisateur import Utilisateur
from app.utils.security import verify_password, create_access_token

router = APIRouter(prefix="/auth", tags=["Authentification"])

@router.post("/login")
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = db.query(Utilisateur).filter(
        Utilisateur.email == form_data.username,
        Utilisateur.deleted_at.is_(None)
    ).first()

    if not user or not verify_password(form_data.password, user.mot_de_passe):
        raise HTTPException(status_code=401, detail="Identifiants invalides")

    access_token = create_access_token(data={"sub": str(user.utilisateur_id)})
    return {"access_token": access_token, "token_type": "bearer"}
