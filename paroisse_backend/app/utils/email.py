from fastapi_mail import FastMail, MessageSchema, ConnectionConfig
from pydantic import  EmailStr
import os
from dotenv import load_dotenv
from pydantic_settings import BaseSettings

# Charger les variables d’environnement depuis un fichier .env
load_dotenv()

# Configuration via les variables d’environnement
class MailSettings(BaseSettings):
    MAIL_USERNAME: str
    MAIL_PASSWORD: str
    MAIL_FROM: EmailStr
    MAIL_PORT: int = 587
    MAIL_SERVER: str = "smtp.gmail.com"
    MAIL_STARTTLS: bool = True
    MAIL_SSL_TLS: bool = False
    USE_CREDENTIALS: bool = True
    VALIDATE_CERTS: bool = True

    class Config:
        env_file = ".env"

mail_settings = MailSettings()

conf = ConnectionConfig(
    MAIL_USERNAME=mail_settings.MAIL_USERNAME,
    MAIL_PASSWORD=mail_settings.MAIL_PASSWORD,
    MAIL_FROM=mail_settings.MAIL_FROM,
    MAIL_PORT=mail_settings.MAIL_PORT,
    MAIL_SERVER=mail_settings.MAIL_SERVER,
    MAIL_STARTTLS=mail_settings.MAIL_STARTTLS,
    MAIL_SSL_TLS=mail_settings.MAIL_SSL_TLS,
    USE_CREDENTIALS=mail_settings.USE_CREDENTIALS,
    VALIDATE_CERTS=mail_settings.VALIDATE_CERTS,
)


async def send_email(subject: str, recipient: EmailStr, body: str) -> bool:
    message = MessageSchema(
        subject=subject,
        recipients=[recipient],
        body=body,
        subtype="html"
    )
    try:
        fm = FastMail(conf)
        await fm.send_message(message)
        return True
    except Exception as e:
        print(f"[Erreur envoi email] {e}")
        return False
