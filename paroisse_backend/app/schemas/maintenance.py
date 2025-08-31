from pydantic import BaseModel, ConfigDict
from datetime import date, datetime
from typing import Optional

class MaintenanceBase(BaseModel):
    description: str
    date_maintenance: date
    cout: Optional[float]
    infrastructure_id: int
    utilisateur_id: int

class MaintenanceCreate(MaintenanceBase):
    pass

class MaintenanceUpdate(BaseModel):
    description: Optional[str]
    date_maintenance: Optional[date]
    cout: Optional[float]

class MaintenanceOut(MaintenanceBase):
    maintenance_id: int
    created_at: Optional[datetime]
    updated_at: Optional[datetime]
    deleted_at: Optional[datetime]

    model_config = ConfigDict(from_attributes=True)
