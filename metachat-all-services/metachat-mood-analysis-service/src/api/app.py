from fastapi import FastAPI
from contextlib import asynccontextmanager
import asyncio
import structlog

from src.config import Config
from src.domain.mood_analyzer import MoodAnalyzer
from src.infrastructure.database import Database
from src.infrastructure.repository import MoodAnalysisRepository
from src.infrastructure.kafka_client import KafkaProducer, KafkaConsumer
from src.application.event_handler import EventHandler
from src.api.state import app_state, consumer_task
from src.api.routes import router

logger = structlog.get_logger()


@asynccontextmanager
async def lifespan(app: FastAPI):
    config = Config()
    
    db = Database(config)
    
    await db.create_database_if_not_exists()
    await db.create_tables()
    
    mood_analyzer = MoodAnalyzer(config)
    repository = MoodAnalysisRepository(db)
    kafka_producer = KafkaProducer(config)
    kafka_producer.start()
    
    event_handler = EventHandler(mood_analyzer, repository, kafka_producer, db)
    kafka_consumer = KafkaConsumer(config, event_handler.handle_message)
    kafka_consumer.start()
    
    app_state["config"] = config
    app_state["db"] = db
    app_state["mood_analyzer"] = mood_analyzer
    app_state["repository"] = repository
    app_state["kafka_producer"] = kafka_producer
    app_state["kafka_consumer"] = kafka_consumer
    
    import src.api.state as state_module
    state_module.consumer_task = asyncio.create_task(kafka_consumer.consume_loop())
    
    logger.info("Mood Analysis Service started")
    
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


app = FastAPI(
    title="Mood Analysis Service",
    description="ML service for emotional diary analysis",
    version="1.0.0",
    lifespan=lifespan
)

app.include_router(router)

@app.get("/")
async def root():
    return {"service": "mood-analysis-service", "version": "1.0.0"}

