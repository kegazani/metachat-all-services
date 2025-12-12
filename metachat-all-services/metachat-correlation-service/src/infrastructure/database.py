from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import declarative_base
from sqlalchemy import text
from typing import AsyncGenerator
import structlog

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
            pool_pre_ping=True
        )
        self.async_session_maker = async_sessionmaker(
            self.engine,
            class_=AsyncSession,
            expire_on_commit=False
        )
    
    async def create_database_if_not_exists(self):
        try:
            db_url = self.config.database_url
            if "postgresql" in db_url:
                from urllib.parse import urlparse
                parsed = urlparse(db_url.replace("postgresql+asyncpg://", "postgresql://"))
                db_name = parsed.path.lstrip("/")
                
                admin_url = db_url.replace(f"/{db_name}", "/postgres")
                admin_engine = create_async_engine(
                    admin_url,
                    isolation_level="AUTOCOMMIT",
                    pool_pre_ping=True
                )
                
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
                finally:
                    await admin_engine.dispose()
        except Exception as e:
            logger.warning("Could not create database automatically", error=str(e))
    
    async def test_connection(self):
        try:
            async with self.engine.connect() as conn:
                await conn.execute(text("SELECT 1"))
            logger.info("Database connection successful")
            return True
        except Exception as e:
            db_info = self.config.database_url.split("@")[-1] if "@" in self.config.database_url else "unknown"
            logger.error(
                "Database connection failed",
                error=str(e),
                database=db_info,
                hint="Please verify PostgreSQL is running and credentials are correct in config.yaml or environment variables"
            )
            return False
    
    async def create_tables(self):
        try:
            from src.infrastructure.models import Correlation, UserCorrelationCache
            async with self.engine.begin() as conn:
                await conn.run_sync(Base.metadata.create_all)
            logger.info("Tables created successfully")
        except Exception as e:
            db_info = self.config.database_url.split("@")[-1] if "@" in self.config.database_url else "unknown"
            logger.error("Error creating tables", error=str(e), database=db_info)
            raise
    
    async def get_session(self) -> AsyncGenerator[AsyncSession, None]:
        async with self.async_session_maker() as session:
            try:
                yield session
            finally:
                await session.close()
    
    async def close(self):
        await self.engine.dispose()

