from pydantic import BaseModel, ConfigDict
from typing import Optional
from enum import Enum
from datetime import datetime

class TypeNotificationEnum(str, Enum):
    info = "info"
    success = "success"
    warning = "warning"
    error = "error"
    confirmation = "confirmation"
    question = "question"

class NotificationBase(BaseModel):
    titre: str
    message: str
    type: TypeNotificationEnum
    utilisateur_id: Optional[int] = None

class NotificationCreate(NotificationBase):
    pass

class NotificationOut(NotificationBase):
    notification_id: int
    est_lue: bool
    email_envoye: bool
    email_envoye_at: Optional[datetime]
    created_at: datetime
    updated_at: Optional[datetime]
    deleted_at: Optional[datetime]

    model_config = ConfigDict(from_attributes=True)
