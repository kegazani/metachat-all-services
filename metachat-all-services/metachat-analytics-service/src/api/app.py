from fastapi import FastAPI
from contextlib import asynccontextmanager
import asyncio
import structlog
import os

from src.config import Config
from src.infrastructure.database import Database, Base
from src.infrastructure.models import DailyMoodSummary, WeeklyMoodSummary, MonthlyMoodSummary, UserTopicsSummary, ArchetypeHistory
from src.infrastructure.repository import AnalyticsRepository
from src.infrastructure.kafka_client import KafkaConsumer
from src.application.event_handler import EventHandler
from src.api.state import app_state, consumer_task
from src.api.routes import router

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
    
    logger.info("Starting Analytics Service", service_name=config.service_name)
    
    db = Database(config)
    
    await init_database_with_retry(db, initial_delay=float(os.getenv("DB_INIT_DELAY", "5")))
    
    repository = AnalyticsRepository(db)
    
    event_handler = EventHandler(repository, db)
    kafka_consumer = KafkaConsumer(config, event_handler.handle_message)
    kafka_consumer.start()
    
    app_state["config"] = config
    app_state["db"] = db
    app_state["repository"] = repository
    app_state["kafka_consumer"] = kafka_consumer
    
    import src.api.state as state_module
    state_module.consumer_task = asyncio.create_task(kafka_consumer.consume_loop())
    
    logger.info("Analytics Service started successfully")
    
    yield
    
    import src.api.state as state_module
    if state_module.consumer_task:
        state_module.consumer_task.cancel()
        try:
            await state_module.consumer_task
        except asyncio.CancelledError:
            pass
    
    kafka_consumer.stop()
    await db.close()
    logger.info("Analytics Service stopped")


app = FastAPI(
    title="Analytics Service",
    description="Service for mood analytics and aggregation",
    version="1.0.0",
    lifespan=lifespan
)

app.include_router(router)


@app.get("/")
async def root():
    return {"service": "analytics-service", "version": "1.0.0"}
