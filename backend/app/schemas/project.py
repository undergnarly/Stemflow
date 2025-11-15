"""Project schemas"""
from pydantic import BaseModel
from datetime import datetime
from typing import Optional


class ProjectBase(BaseModel):
    """Base project schema"""
    name: str
    bpm: Optional[float] = None
    key: Optional[str] = None
    genre: Optional[str] = None
    abletonProjectPath: Optional[str] = None


class ProjectCreate(ProjectBase):
    """Project creation schema"""
    pass


class ProjectUpdate(BaseModel):
    """Project update schema"""
    name: Optional[str] = None
    bpm: Optional[float] = None
    key: Optional[str] = None
    genre: Optional[str] = None
    status: Optional[str] = None
    abletonProjectPath: Optional[str] = None


class ProjectResponse(ProjectBase):
    """Project response schema"""
    id: str
    userId: str
    status: str
    totalTimeSeconds: int
    createdAt: datetime
    updatedAt: datetime

    class Config:
        from_attributes = True
