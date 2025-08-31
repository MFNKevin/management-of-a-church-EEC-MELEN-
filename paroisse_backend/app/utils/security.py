from datetime import datetime, timedelta
from jose import JWTError, jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from enum import Enum
from passlib.context import CryptContext
from app.database import get_db
from app.models.utilisateur import Utilisateur, RoleEnum

from typing import List, Callable


# --- CONFIGURATION ---
SECRET_KEY = "ton_secret_ultra_confidentiel"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24  # 24h

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")

# --- GESTION MOT DE PASSE ---
def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

# --- GESTION JWT ---
def create_access_token(data: dict, expires_delta: timedelta = None):
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

def decode_access_token(token: str):
    try:
        return jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
    except JWTError:
        return None

# --- UTILISATEUR COURANT (via JWT) ---
def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
) -> Utilisateur:
    payload = decode_access_token(token)
    print("Payload du token :", payload)  # ← TEMPORAIRE

    if not payload or "sub" not in payload:
        raise HTTPException(status_code=401, detail="Token invalide")

    user = db.query(Utilisateur).filter(
        Utilisateur.utilisateur_id == int(payload["sub"]),
        Utilisateur.deleted_at.is_(None)
    ).first()

    if not user:
        raise HTTPException(status_code=401, detail="Utilisateur non trouvé ou supprimé")

    return user

# --- RESTRICTION PAR RÔLE ---
def role_required(allowed_roles: List[str]) -> Callable:
    def wrapper(current_user: Utilisateur = Depends(get_current_user)):
        if current_user.role not in allowed_roles:
            raise HTTPException(
                status_code=403,
                detail=f"Permission refusée pour le rôle {current_user.role}",
            )
        return current_user
    return wrapper



