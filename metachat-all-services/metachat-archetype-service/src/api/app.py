from fastapi import FastAPI
from contextlib import asynccontextmanager
import asyncio

from src.config import Config
from src.domain.archetype_classifier import ArchetypeClassifier
from src.infrastructure.database import Database
from src.infrastructure.repository import ArchetypeRepository
from src.infrastructure.kafka_client import KafkaProducer, KafkaConsumer
from src.application.event_handler import EventHandler

app_state = {}
consumer_task = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    config = Config()
    
    db = Database(config)
    classifier = ArchetypeClassifier()
    repository = ArchetypeRepository(db)
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


app = FastAPI(
    title="Archetype Service",
    description="Service for determining psychological archetypes",
    version="1.0.0",
    lifespan=lifespan
)


@app.get("/")
async def root():
    return {"service": "archetype-service", "version": "1.0.0"}


@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "archetype-service"}

