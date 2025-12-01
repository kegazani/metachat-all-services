import json
from typing import Dict, Any

from confluent_kafka import Producer, KafkaException
from loguru import logger

from src.config import Config


class KafkaProducer:
    def __init__(self, config: Config):
        self.config = config
        
        # Kafka producer configuration
        self.producer_config = {
            'bootstrap.servers': ','.join(config.kafka_brokers),
            'client.id': 'mood-analysis-service-producer',
            'acks': 'all',
            'retries': 3,
            'max.in.flight.requests.per.connection': 5,
            'compression.codec': 'snappy',
            'linger.ms': 10,
            'batch.num.messages': 1000,
            'queue.buffering.max.messages': 10000,
            'queue.buffering.max.kbytes': 10240,
            'enable.idempotence': True
        }
        
        # Producer instance
        self.producer = None
        
        # Topic for mood analyzed events
        self.mood_analyzed_topic = config.mood_analyzed_topic
        
        logger.info("KafkaProducer initialized")

    def start(self):
        """Start Kafka producer."""
        if self.producer:
            logger.warning("Kafka producer is already started")
            return
        
        try:
            # Create producer
            self.producer = Producer(self.producer_config)
            logger.info("Kafka producer started")
        except KafkaException as e:
            logger.error(f"Failed to start Kafka producer: {e}")
            raise

    def stop(self):
        """Stop Kafka producer."""
        if not self.producer:
            logger.warning("Kafka producer is not started")
            return
        
        try:
            # Flush producer to ensure all messages are sent
            remaining = self.producer.flush(timeout=10)
            if remaining > 0:
                logger.warning(f"{remaining} messages were not delivered")
            
            logger.info("Kafka producer stopped")
        except Exception as e:
            logger.error(f"Error stopping Kafka producer: {e}")

    def publish_mood_analyzed(self, mood_result: Dict[str, Any]):
        """
        Publish a MoodAnalyzed event to Kafka.
        
        Args:
            mood_result: The mood analysis result
        """
        if not self.producer:
            logger.error("Kafka producer is not started")
            return
        
        try:
            # Convert to JSON
            value = json.dumps(mood_result).encode('utf-8')
            
            # Create key (user_id for partitioning)
            key = mood_result.get('user_id', '').encode('utf-8')
            
            # Produce message
            self.producer.produce(
                topic=self.mood_analyzed_topic,
                key=key,
                value=value,
                callback=self._delivery_callback
            )
            
            # Poll to handle delivery callbacks
            self.producer.poll(0)
            
            logger.debug(f"Published MoodAnalyzed event for user {mood_result.get('user_id')}")
            
        except Exception as e:
            logger.error(f"Error publishing MoodAnalyzed event: {e}")

    def _delivery_callback(self, err, msg):
        """
        Callback for message delivery reports.
        
        Args:
            err: The error, if any
            msg: The message
        """
        if err is not None:
            logger.error(f"Message delivery failed: {err}")
        else:
            logger.debug(f"Message delivered to {msg.topic()} [{msg.partition()}] at offset {msg.offset()}")