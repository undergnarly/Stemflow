"""Authentication endpoints"""
from fastapi import APIRouter, Depends, HTTPException, status
from prisma import Prisma
from datetime import datetime, timedelta

from app.core.database import get_db
from app.core.security import (
    verify_password,
    get_password_hash,
    create_access_token,
    create_refresh_token,
    decode_token
)
from app.core.config import settings
from app.schemas.user import (
    UserCreate,
    UserLogin,
    UserResponse,
    TokenResponse,
    RefreshTokenRequest
)
from app.api.deps import get_current_user
from prisma.models import User

router = APIRouter()


@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register(user_data: UserCreate, db: Prisma = Depends(get_db)):
    """Register a new user"""
    # Check if user already exists
    existing_user = await db.user.find_unique(where={"email": user_data.email})
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )

    # Hash password
    hashed_password = get_password_hash(user_data.password)

    # Create user
    user = await db.user.create(
        data={
            "email": user_data.email,
            "name": user_data.name,
            "password": hashed_password
        }
    )

    # Create tokens
    access_token = create_access_token(data={"sub": user.id})
    refresh_token = create_refresh_token(data={"sub": user.id})

    # Store refresh token
    expires_at = datetime.utcnow() + timedelta(days=settings.refresh_token_expire_days)
    await db.refreshtoken.create(
        data={
            "token": refresh_token,
            "userId": user.id,
            "expiresAt": expires_at
        }
    )

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        user=UserResponse.model_validate(user)
    )


@router.post("/login", response_model=TokenResponse)
async def login(credentials: UserLogin, db: Prisma = Depends(get_db)):
    """Login user"""
    # Find user
    user = await db.user.find_unique(where={"email": credentials.email})
    if not user or not verify_password(credentials.password, user.password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password"
        )

    # Create tokens
    access_token = create_access_token(data={"sub": user.id})
    refresh_token = create_refresh_token(data={"sub": user.id})

    # Store refresh token
    expires_at = datetime.utcnow() + timedelta(days=settings.refresh_token_expire_days)
    await db.refreshtoken.create(
        data={
            "token": refresh_token,
            "userId": user.id,
            "expiresAt": expires_at
        }
    )

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        user=UserResponse.model_validate(user)
    )


@router.post("/refresh")
async def refresh_token(token_data: RefreshTokenRequest, db: Prisma = Depends(get_db)):
    """Refresh access token"""
    # Decode refresh token
    payload = decode_token(token_data.refresh_token)
    if payload is None or payload.get("type") != "refresh":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token"
        )

    # Verify token exists in database
    stored_token = await db.refreshtoken.find_unique(
        where={"token": token_data.refresh_token}
    )
    if not stored_token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token"
        )

    # Check expiration
    if stored_token.expiresAt < datetime.utcnow():
        await db.refreshtoken.delete(where={"id": stored_token.id})
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Refresh token expired"
        )

    # Create new access token
    user_id = payload.get("sub")
    access_token = create_access_token(data={"sub": user_id})

    return {"access_token": access_token, "token_type": "bearer"}


@router.get("/me", response_model=UserResponse)
async def get_me(current_user: User = Depends(get_current_user)):
    """Get current user profile"""
    return UserResponse.model_validate(current_user)
