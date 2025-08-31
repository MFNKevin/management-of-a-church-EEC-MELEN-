from pydantic import BaseModel, ConfigDict
from typing import Optional
from datetime import datetime

class GroupeBase(BaseModel):
    nom: str
    description: Optional[str]

class GroupeCreate(GroupeBase):
    pass

class GroupeUpdate(GroupeBase):
    pass

class GroupeOut(GroupeBase):
    groupe_id: int
    created_at: datetime
    updated_at: Optional[datetime]
    deleted_at: Optional[datetime]

    model_config = ConfigDict(from_attributes=True)
