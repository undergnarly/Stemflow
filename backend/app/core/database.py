"""Database connection and utilities"""
from prisma import Prisma
from typing import AsyncGenerator

# Global database instance
db = Prisma(auto_register=True)


async def get_db() -> AsyncGenerator[Prisma, None]:
    """Dependency for database access"""
    if not db.is_connected():
        await db.connect()
    try:
        yield db
    finally:
        pass  # Connection managed at application lifecycle


async def connect_db() -> None:
    """Connect to database (called at startup)"""
    if not db.is_connected():
        await db.connect()


async def disconnect_db() -> None:
    """Disconnect from database (called at shutdown)"""
    if db.is_connected():
        await db.disconnect()
