from fastapi import FastAPI
from contextlib import asynccontextmanager
import asyncio
import structlog
import os

from src.config import Config
from src.domain.big_five_classifier import BigFiveClassifier
from src.infrastructure.database import Database, Base
from src.infrastructure.repository import PersonalityRepository
from src.infrastructure.kafka_client import KafkaProducer, KafkaConsumer
from src.application.event_handler import EventHandler
from src.infrastructure.models import UserPersonalityData, BigFiveCalculation

logger = structlog.get_logger()

app_state = {}
consumer_task = None


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
    
    logger.info("Starting Personality Service (Big Five)", service_name="archetype-service")
    
    db = Database(config)
    
    await init_database_with_retry(db, initial_delay=float(os.getenv("DB_INIT_DELAY", "5")))
    
    classifier = BigFiveClassifier()
    repository = PersonalityRepository(db)
    kafka_producer = KafkaProducer(config)
    kafka_producer.start()
    
    event_handler = EventHandler(classifier, repository, kafka_producer, db, config)
    kafka_consumer = KafkaConsumer(config, event_handler.handle_message)
    kafka_consumer.start()
    
    app_state["config"] = config
    app_state["db"] = db
    app_state["classifier"] = classifier
    app_state["repository"] = repository
    app_state["kafka_producer"] = kafka_producer
    app_state["kafka_consumer"] = kafka_consumer
    
    global consumer_task
    consumer_task = asyncio.create_task(kafka_consumer.consume_loop())
    
    logger.info("Personality Service (Big Five) started successfully")
    
    yield
    
    if consumer_task:
        consumer_task.cancel()
        try:
            await consumer_task
        except asyncio.CancelledError:
            pass
    
    kafka_consumer.stop()
    kafka_producer.stop()
    await db.close()
    logger.info("Personality Service stopped")


app = FastAPI(
    title="Personality Service",
    description="Service for determining Big Five personality traits",
    version="2.0.0",
    lifespan=lifespan
)


@app.get("/")
async def root():
    return {"service": "personality-service", "version": "2.0.0", "model": "Big Five (OCEAN)"}


@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "personality-service"}
