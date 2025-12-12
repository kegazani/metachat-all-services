from fastapi import FastAPI
from contextlib import asynccontextmanager
import asyncio
import structlog
import os

from src.config import Config
from src.infrastructure.database import Database
from src.infrastructure.repository import BiometricRepository
from src.infrastructure.kafka_client import KafkaProducer
from src.domain.emotional_state_analyzer import EmotionalStateAnalyzer
from src.domain.day_insights import DayInsightsAnalyzer
from src.api.routes import router
from src.api.state import app_state

logger = structlog.get_logger()


async def init_database_with_retry(db: Database, max_retries: int = 20, initial_delay: float = 5.0, retry_delay: float = 3.0):
    logger.info("Waiting for database to be ready", initial_delay=initial_delay)
    await asyncio.sleep(initial_delay)
    
    for attempt in range(1, max_retries + 1):
        try:
            logger.info("Attempting to connect to database", attempt=attempt, max_retries=max_retries)
            await db.wait_for_postgres(max_attempts=10, delay=2.0)
            await db.create_database_if_not_exists()
            await db.create_tables()
            logger.info("Database initialized successfully", attempt=attempt)
            return
        except Exception as e:
            if attempt == max_retries:
                logger.error("Failed to initialize database after max retries", error=str(e), attempts=max_retries)
                raise
            logger.warning("Database initialization failed, retrying...", error=str(e), attempt=attempt, max_retries=max_retries)
            await asyncio.sleep(retry_delay)


@asynccontextmanager
async def lifespan(app: FastAPI):
    config = Config()
    
    logger.info("Starting Biometric Service", service_name="biometric-service")
    
    db = Database(config)
    await init_database_with_retry(db, initial_delay=float(os.getenv("DB_INIT_DELAY", "5")))
    
    repository = BiometricRepository(db)
    kafka_producer = KafkaProducer(config)
    kafka_producer.start()
    
    emotional_analyzer = EmotionalStateAnalyzer()
    day_insights_analyzer = DayInsightsAnalyzer()
    
    app_state["config"] = config
    app_state["db"] = db
    app_state["repository"] = repository
    app_state["kafka_producer"] = kafka_producer
    app_state["emotional_analyzer"] = emotional_analyzer
    app_state["day_insights_analyzer"] = day_insights_analyzer
    
    logger.info("Biometric Service started successfully")
    yield
    
    kafka_producer.stop()
    await db.close()
    logger.info("Biometric Service stopped")


app = FastAPI(
    title="Biometric Service",
    version="1.0.0",
    lifespan=lifespan
)

app.include_router(router)


@app.get("/health")
async def health():
    return {"status": "healthy", "service": "biometric-service"}
