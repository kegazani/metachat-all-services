from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import declarative_base
from sqlalchemy import text
from typing import AsyncGenerator
import structlog
import asyncio

from src.config import Config

logger = structlog.get_logger()

Base = declarative_base()

class Database:
    def __init__(self, config: Config):
        self.config = config
        self.engine = create_async_engine(
            config.database_url,
            pool_size=config.database_pool_size,
            max_overflow=config.database_max_overflow,
            echo=False,
            pool_pre_ping=True,
            connect_args={"ssl": False}
        )
        self.async_session_maker = async_sessionmaker(
            self.engine,
            class_=AsyncSession,
            expire_on_commit=False
        )
    
    async def wait_for_postgres(self, max_attempts: int = 30, delay: float = 2.0):
        from urllib.parse import urlparse
        db_url = self.config.database_url
        parsed = urlparse(db_url.replace("postgresql+asyncpg://", "postgresql://"))
        admin_url = db_url.replace(f"/{parsed.path.lstrip('/')}", "/postgres")
        
        admin_engine = create_async_engine(
            admin_url,
            isolation_level="AUTOCOMMIT",
            pool_pre_ping=True,
            connect_args={"ssl": False}
        )
        
        for attempt in range(max_attempts):
            try:
                async with admin_engine.connect() as conn:
                    await conn.execute(text("SELECT 1"))
                logger.info("PostgreSQL connection established", attempt=attempt + 1)
                await admin_engine.dispose()
                return True
            except Exception as e:
                if attempt < max_attempts - 1:
                    logger.warning("Waiting for PostgreSQL...", attempt=attempt + 1, max_attempts=max_attempts, delay=delay, error=str(e))
                    await asyncio.sleep(delay)
                else:
                    logger.error("PostgreSQL not available after max attempts", error=str(e))
                    await admin_engine.dispose()
                    raise ConnectionError(f"Cannot connect to PostgreSQL after {max_attempts} attempts: {e}")
        
        await admin_engine.dispose()
        return False
    
    async def create_database_if_not_exists(self):
        max_attempts = 15
        delay = 3.0
        max_delay = 30.0
        base = 1.5
        
        db_url = self.config.database_url
        if "postgresql" not in db_url:
            return
            
        from urllib.parse import urlparse
        parsed = urlparse(db_url.replace("postgresql+asyncpg://", "postgresql://"))
        db_name = parsed.path.lstrip("/")
        
        admin_url = db_url.replace(f"/{db_name}", "/postgres")
        admin_engine = create_async_engine(
            admin_url,
            isolation_level="AUTOCOMMIT",
            pool_pre_ping=True,
            connect_args={"ssl": False}
        )
        
        for attempt in range(max_attempts):
            try:
                async with admin_engine.connect() as conn:
                    result = await conn.execute(
                        text(f"SELECT 1 FROM pg_database WHERE datname = '{db_name}'")
                    )
                    exists = result.scalar()
                    
                    if not exists:
                        logger.info("Creating database", database=db_name)
                        await conn.execute(text(f'CREATE DATABASE "{db_name}"'))
                        logger.info("Database created", database=db_name)
                    else:
                        logger.info("Database already exists", database=db_name)
                await admin_engine.dispose()
                return
            except Exception as e:
                if attempt < max_attempts - 1:
                    logger.warning("Database creation attempt failed, retrying", attempt=attempt + 1, max_attempts=max_attempts, delay=delay, error=str(e))
                    await asyncio.sleep(delay)
                    delay = min(delay * base, max_delay)
                else:
                    logger.error("Could not create database after all retries", error=str(e))
                    await admin_engine.dispose()
                    raise ConnectionError(f"Failed to create database {db_name}: {e}")
    
    async def create_tables(self):
        max_attempts = 15
        delay = 3.0
        max_delay = 30.0
        base = 1.5
        
        for attempt in range(max_attempts):
            try:
                async with self.engine.begin() as conn:
                    await conn.run_sync(Base.metadata.create_all)
                logger.info("Tables created successfully")
                return
            except Exception as e:
                if attempt < max_attempts - 1:
                    logger.warning("Failed to create tables, retrying", attempt=attempt + 1, max_attempts=max_attempts, delay=delay, error=str(e))
                    await asyncio.sleep(delay)
                    delay = min(delay * base, max_delay)
                else:
                    logger.error("Error creating tables after all retries", error=str(e))
                    raise
    
    async def get_session(self) -> AsyncGenerator[AsyncSession, None]:
        async with self.async_session_maker() as session:
            try:
                yield session
            finally:
                await session.close()
    
    async def close(self):
        await self.engine.dispose()
