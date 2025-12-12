from fastapi import FastAPI
from contextlib import asynccontextmanager
import asyncio
import structlog
import os

from src.config import Config
from src.infrastructure.database import Database
from src.infrastructure.repository import CorrelationRepository
from src.infrastructure.kafka_client import KafkaConsumer, KafkaProducer
from src.application.event_handler import EventHandler
from src.api.state import app_state, consumer_task

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
            return True
        except Exception as e:
            if attempt == max_retries:
                logger.error("Failed to initialize database after max retries", error=str(e), attempts=max_retries)
                return False
            logger.warning("Database initialization failed, retrying...", error=str(e), attempt=attempt, max_retries=max_retries)
            await asyncio.sleep(retry_delay)
    return False


@asynccontextmanager
async def lifespan(app: FastAPI):
    config = Config()
    
    logger.info("Starting Correlation Service", service_name="correlation-service")
    
    db = Database(config)
    
    db_connected = await init_database_with_retry(db, initial_delay=float(os.getenv("DB_INIT_DELAY", "5")))
    if not db_connected:
        if getattr(config, 'require_database', True):
            logger.error("Cannot proceed without database connection. Please fix database configuration.")
            raise RuntimeError("Database connection failed. Check logs for details.")
        else:
            logger.warning("Database connection failed but require_database is False. Service will start without database functionality.")
    
    repository = CorrelationRepository(db)
    kafka_producer = KafkaProducer(config)
    kafka_producer.start()
    
    event_handler = EventHandler(repository, db, kafka_producer, config)
    kafka_consumer = KafkaConsumer(config, event_handler.handle_message)
    kafka_consumer.start()
    
    app_state["config"] = config
    app_state["db"] = db
    app_state["repository"] = repository
    app_state["kafka_consumer"] = kafka_consumer
    app_state["kafka_producer"] = kafka_producer
    
    import src.api.state as state_module
    state_module.consumer_task = asyncio.create_task(kafka_consumer.consume_loop())
    
    logger.info("Correlation Service started successfully")
    yield
    
    import src.api.state as state_module
    if state_module.consumer_task:
        state_module.consumer_task.cancel()
        try:
            await state_module.consumer_task
        except asyncio.CancelledError:
            pass
    
    kafka_consumer.stop()
    kafka_producer.stop()
    await db.close()
    logger.info("Correlation Service stopped")


app = FastAPI(
    title="Correlation Service",
    version="1.0.0",
    lifespan=lifespan
)


@app.get("/health")
async def health():
    return {"status": "healthy", "service": "correlation-service"}
