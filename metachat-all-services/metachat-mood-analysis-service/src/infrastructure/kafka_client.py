import json
import uuid
from datetime import datetime
from typing import Dict, Any, Optional
from confluent_kafka import Producer, Consumer, KafkaException
import structlog

from src.config import Config

logger = structlog.get_logger()


class KafkaProducer:
    def __init__(self, config: Config):
        self.config = config
        
        self.producer_config = {
            'bootstrap.servers': ','.join(config.kafka_brokers),
            'client.id': f'{config.service_name}-producer',
            'acks': 'all',
            'retries': 3,
            'max.in.flight.requests.per.connection': 5,
            'compression.type': 'snappy',
            'linger.ms': 10,
            'batch.num.messages': 1000,
            'queue.buffering.max.messages': 10000,
            'queue.buffering.max.kbytes': 10240,
            'enable.idempotence': True
        }
        
        self.producer = None
        logger.info("KafkaProducer initialized")
    
    def start(self):
        if self.producer:
            logger.warning("Kafka producer is already started")
            return
        
        try:
            self.producer = Producer(self.producer_config)
            logger.info("Kafka producer started")
        except KafkaException as e:
            logger.error("Failed to start Kafka producer", error=str(e))
            raise
    
    def stop(self):
        if not self.producer:
            return
        
        try:
            remaining = self.producer.flush(timeout=10)
            if remaining > 0:
                logger.warning("Messages not delivered", count=remaining)
            logger.info("Kafka producer stopped")
        except Exception as e:
            logger.error("Error stopping Kafka producer", error=str(e))
    
    def publish_mood_analyzed(
        self,
        analysis_data: Dict[str, Any],
        correlation_id: Optional[str] = None,
        causation_id: Optional[str] = None
    ):
        if not self.producer:
            logger.error("Kafka producer is not started")
            return
        
        try:
            event = {
                "event_id": str(uuid.uuid4()),
                "event_type": "MoodAnalyzed",
                "timestamp": datetime.utcnow().isoformat() + "Z",
                "correlation_id": correlation_id or str(uuid.uuid4()),
                "causation_id": causation_id,
                "payload": {
                    "entry_id": analysis_data["entry_id"],
                    "user_id": analysis_data["user_id"],
                    "emotion_vector": [float(v) for v in analysis_data["emotion_vector"]],
                    "dominant_emotion": analysis_data["dominant_emotion"],
                    "valence": float(analysis_data["valence"]),
                    "arousal": float(analysis_data["arousal"]),
                    "confidence": float(analysis_data["confidence"]),
                    "model_version": analysis_data["model_version"],
                    "tokens_count": int(analysis_data["tokens_count"]),
                    "detected_topics": analysis_data.get("detected_topics", []),
                    "keywords": analysis_data.get("keywords", [])
                }
            }
            
            value = json.dumps(event).encode('utf-8')
            key = analysis_data["user_id"].encode('utf-8')
            
            self.producer.produce(
                topic=self.config.mood_analyzed_topic,
                key=key,
                value=value,
                callback=self._delivery_callback
            )
            
            self.producer.poll(0)
            
            logger.debug(
                "Published MoodAnalyzed event",
                entry_id=analysis_data["entry_id"],
                user_id=analysis_data["user_id"]
            )
            
        except Exception as e:
            logger.error("Error publishing MoodAnalyzed event", error=str(e), exc_info=True)
    
    def publish_mood_analysis_failed(
        self,
        entry_id: str,
        user_id: str,
        error_message: str,
        error_type: str,
        correlation_id: Optional[str] = None
    ):
        if not self.producer:
            logger.error("Kafka producer is not started")
            return
        
        try:
            event = {
                "event_id": str(uuid.uuid4()),
                "event_type": "MoodAnalysisFailed",
                "timestamp": datetime.utcnow().isoformat() + "Z",
                "correlation_id": correlation_id or str(uuid.uuid4()),
                "payload": {
                    "entry_id": entry_id,
                    "user_id": user_id,
                    "error_message": error_message,
                    "error_type": error_type
                }
            }
            
            value = json.dumps(event).encode('utf-8')
            key = user_id.encode('utf-8')
            
            self.producer.produce(
                topic=self.config.mood_analysis_failed_topic,
                key=key,
                value=value,
                callback=self._delivery_callback
            )
            
            self.producer.poll(0)
            
            logger.debug("Published MoodAnalysisFailed event", entry_id=entry_id, user_id=user_id)
            
        except Exception as e:
            logger.error("Error publishing MoodAnalysisFailed event", error=str(e), exc_info=True)
    
    def _delivery_callback(self, err, msg):
        if err is not None:
            logger.error("Message delivery failed", error=str(err))
        else:
            logger.debug(
                "Message delivered",
                topic=msg.topic(),
                partition=msg.partition(),
                offset=msg.offset()
            )


class KafkaConsumer:
    def __init__(self, config: Config, message_handler):
        self.config = config
        self.message_handler = message_handler
        
        self.consumer_config = {
            'bootstrap.servers': ','.join(config.kafka_brokers),
            'group.id': config.kafka_consumer_group,
            'auto.offset.reset': 'earliest',
            'enable.auto.commit': False
        }
        
        self.consumer = None
        self.running = False
        logger.info("KafkaConsumer initialized")
    
    def start(self):
        if self.running:
            logger.warning("Kafka consumer is already running")
            return
        
        try:
            self.consumer = Consumer(self.consumer_config)
            topics = [
                self.config.diary_entry_created_topic,
                self.config.diary_entry_updated_topic
            ]
            self.consumer.subscribe(topics)
            self.running = True
            logger.info("Kafka consumer started", topics=topics)
        except KafkaException as e:
            logger.error("Failed to start Kafka consumer", error=str(e))
            raise
    
    def stop(self):
        if not self.running:
            return
        
        self.running = False
        
        if self.consumer:
            self.consumer.close()
        
        logger.info("Kafka consumer stopped")
    
    async def consume_loop(self):
        import asyncio
        
        while self.running:
            try:
                msg = self.consumer.poll(timeout=1.0)
                
                if msg is None:
                    await asyncio.sleep(0.1)
                    continue
                
                if msg.error():
                    logger.error("Consumer error", error=str(msg.error()))
                    continue
                
                try:
                    await self._process_message(msg)
                    self.consumer.commit(asynchronous=False)
                except Exception as e:
                    logger.error("Error processing message", error=str(e), exc_info=True)
                    
            except Exception as e:
                logger.error("Error in consume loop", error=str(e), exc_info=True)
                await asyncio.sleep(1)
    
    async def _process_message(self, msg):
        try:
            value = msg.value().decode('utf-8')
            data = json.loads(value)
            topic = msg.topic()
            
            correlation_id = None
            causation_id = None
            
            if isinstance(data, dict):
                if "metadata" in data:
                    metadata = data["metadata"]
                    correlation_id = metadata.get("correlation_id")
                    causation_id = metadata.get("causation_id")
                elif "correlation_id" in data:
                    correlation_id = data.get("correlation_id")
                    causation_id = data.get("causation_id")
            
            await self.message_handler(topic, data, correlation_id, causation_id)
            
        except json.JSONDecodeError as e:
            logger.error("Failed to decode JSON", error=str(e))
        except Exception as e:
            logger.error("Error processing message", error=str(e), exc_info=True)

