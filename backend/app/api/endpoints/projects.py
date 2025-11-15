"""Project endpoints"""
from fastapi import APIRouter, Depends, HTTPException, status
from prisma import Prisma
from typing import List, Optional

from app.core.database import get_db
from app.api.deps import get_current_user
from app.schemas.project import ProjectCreate, ProjectUpdate, ProjectResponse
from prisma.models import User

router = APIRouter()


@router.get("", response_model=List[ProjectResponse])
async def list_projects(
    status: Optional[str] = None,
    limit: int = 50,
    offset: int = 0,
    current_user: User = Depends(get_current_user),
    db: Prisma = Depends(get_db)
):
    """List all projects for authenticated user"""
    where = {"userId": current_user.id, "deletedAt": None}
    if status:
        where["status"] = status

    projects = await db.project.find_many(
        where=where,
        skip=offset,
        take=limit,
        order={"createdAt": "desc"}
    )

    return [ProjectResponse.model_validate(p) for p in projects]


@router.post("", response_model=ProjectResponse, status_code=status.HTTP_201_CREATED)
async def create_project(
    project_data: ProjectCreate,
    current_user: User = Depends(get_current_user),
    db: Prisma = Depends(get_db)
):
    """Create new project"""
    project = await db.project.create(
        data={
            "userId": current_user.id,
            "name": project_data.name,
            "bpm": project_data.bpm,
            "key": project_data.key,
            "genre": project_data.genre,
            "abletonProjectPath": project_data.abletonProjectPath
        }
    )

    return ProjectResponse.model_validate(project)


@router.get("/{project_id}", response_model=ProjectResponse)
async def get_project(
    project_id: str,
    current_user: User = Depends(get_current_user),
    db: Prisma = Depends(get_db)
):
    """Get project details"""
    project = await db.project.find_unique(
        where={"id": project_id},
        include={"versions": True, "notes": True}
    )

    if not project or project.userId != current_user.id or project.deletedAt:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Project not found"
        )

    return ProjectResponse.model_validate(project)


@router.patch("/{project_id}", response_model=ProjectResponse)
async def update_project(
    project_id: str,
    project_data: ProjectUpdate,
    current_user: User = Depends(get_current_user),
    db: Prisma = Depends(get_db)
):
    """Update project"""
    project = await db.project.find_unique(where={"id": project_id})

    if not project or project.userId != current_user.id or project.deletedAt:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Project not found"
        )

    # Build update data
    update_data = project_data.model_dump(exclude_unset=True)

    updated_project = await db.project.update(
        where={"id": project_id},
        data=update_data
    )

    return ProjectResponse.model_validate(updated_project)


@router.delete("/{project_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_project(
    project_id: str,
    current_user: User = Depends(get_current_user),
    db: Prisma = Depends(get_db)
):
    """Soft delete project"""
    project = await db.project.find_unique(where={"id": project_id})

    if not project or project.userId != current_user.id or project.deletedAt:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Project not found"
        )

    await db.project.update(
        where={"id": project_id},
        data={"deletedAt": datetime.utcnow()}
    )

    return None


from datetime import datetime
