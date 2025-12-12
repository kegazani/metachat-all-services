import json
import uuid
from datetime import datetime
from typing import Dict, Any, Optional, List
from confluent_kafka import Producer, KafkaException
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
    
    def publish_biometric_data_received(
        self,
        user_id: str,
        heart_rate: Optional[float] = None,
        sleep_data: Optional[Dict[str, Any]] = None,
        activity: Optional[Dict[str, Any]] = None,
        device_id: Optional[str] = None,
        timestamp: Optional[datetime] = None,
        correlation_id: Optional[str] = None
    ):
        if not self.producer:
            logger.error("Kafka producer is not started")
            return
        
        try:
            event_timestamp = timestamp or datetime.utcnow()
            event = {
                "event_id": str(uuid.uuid4()),
                "event_type": "BiometricDataReceived",
                "timestamp": event_timestamp.isoformat() + "Z",
                "correlation_id": correlation_id or str(uuid.uuid4()),
                "payload": {
                    "user_id": user_id,
                    "heart_rate": heart_rate,
                    "sleep_data": sleep_data,
                    "activity": activity,
                    "device_id": device_id,
                    "timestamp": event_timestamp.isoformat() + "Z"
                }
            }
            
            value = json.dumps(event).encode('utf-8')
            key = user_id.encode('utf-8')
            
            self.producer.produce(
                topic=self.config.biometric_data_received_topic,
                key=key,
                value=value,
                callback=self._delivery_callback
            )
            
            self.producer.poll(0)
            
            logger.debug("Published BiometricDataReceived event", user_id=user_id, device_id=device_id)
            
        except Exception as e:
            logger.error("Error publishing BiometricDataReceived event", error=str(e), exc_info=True)
    
    def publish_watch_data_received(
        self,
        user_id: str,
        heart_rate: Optional[float] = None,
        heart_rate_variability: Optional[float] = None,
        blood_oxygen: Optional[float] = None,
        stress_level: Optional[int] = None,
        steps: Optional[int] = None,
        calories: Optional[float] = None,
        sleep_minutes: Optional[int] = None,
        sleep_score: Optional[int] = None,
        health_score: Optional[int] = None,
        device_id: Optional[str] = None,
        device_type: Optional[str] = None,
        timestamp: Optional[datetime] = None,
        correlation_id: Optional[str] = None
    ):
        if not self.producer:
            logger.error("Kafka producer is not started")
            return
        
        try:
            event_timestamp = timestamp or datetime.utcnow()
            event = {
                "event_id": str(uuid.uuid4()),
                "event_type": "WatchDataReceived",
                "timestamp": event_timestamp.isoformat() + "Z",
                "correlation_id": correlation_id or str(uuid.uuid4()),
                "payload": {
                    "user_id": user_id,
                    "heart_rate": heart_rate,
                    "heart_rate_variability": heart_rate_variability,
                    "blood_oxygen": blood_oxygen,
                    "stress_level": stress_level,
                    "steps": steps,
                    "calories": calories,
                    "sleep_minutes": sleep_minutes,
                    "sleep_score": sleep_score,
                    "health_score": health_score,
                    "device_id": device_id,
                    "device_type": device_type,
                    "timestamp": event_timestamp.isoformat() + "Z"
                }
            }
            
            value = json.dumps(event).encode('utf-8')
            key = user_id.encode('utf-8')
            
            self.producer.produce(
                topic=self.config.watch_data_received_topic,
                key=key,
                value=value,
                callback=self._delivery_callback
            )
            
            self.producer.poll(0)
            
            logger.debug("Published WatchDataReceived event", user_id=user_id, device_type=device_type)
            
        except Exception as e:
            logger.error("Error publishing WatchDataReceived event", error=str(e), exc_info=True)
    
    def publish_user_health_updated(
        self,
        user_id: str,
        health_score: int,
        today_steps: Optional[int] = None,
        today_calories: Optional[float] = None,
        current_heart_rate: Optional[float] = None,
        resting_heart_rate: Optional[float] = None,
        avg_hrv: Optional[float] = None,
        avg_blood_oxygen: Optional[float] = None,
        avg_stress_level: Optional[float] = None,
        last_sleep_score: Optional[int] = None,
        last_sleep_duration_hours: Optional[float] = None,
        timestamp: Optional[datetime] = None,
        correlation_id: Optional[str] = None
    ):
        if not self.producer:
            logger.error("Kafka producer is not started")
            return
        
        try:
            event_timestamp = timestamp or datetime.utcnow()
            event = {
                "event_id": str(uuid.uuid4()),
                "event_type": "UserHealthUpdated",
                "timestamp": event_timestamp.isoformat() + "Z",
                "correlation_id": correlation_id or str(uuid.uuid4()),
                "payload": {
                    "user_id": user_id,
                    "health_score": health_score,
                    "today_steps": today_steps,
                    "today_calories": today_calories,
                    "current_heart_rate": current_heart_rate,
                    "resting_heart_rate": resting_heart_rate,
                    "avg_hrv": avg_hrv,
                    "avg_blood_oxygen": avg_blood_oxygen,
                    "avg_stress_level": avg_stress_level,
                    "last_sleep_score": last_sleep_score,
                    "last_sleep_duration_hours": last_sleep_duration_hours,
                    "timestamp": event_timestamp.isoformat() + "Z"
                }
            }
            
            value = json.dumps(event).encode('utf-8')
            key = user_id.encode('utf-8')
            
            self.producer.produce(
                topic=self.config.user_health_updated_topic,
                key=key,
                value=value,
                callback=self._delivery_callback
            )
            
            self.producer.poll(0)
            
            logger.debug("Published UserHealthUpdated event", user_id=user_id, health_score=health_score)
            
        except Exception as e:
            logger.error("Error publishing UserHealthUpdated event", error=str(e), exc_info=True)
    
    def publish_emotional_state_analyzed(
        self,
        user_id: str,
        date: str,
        overall_state: str,
        emotional_stability: float,
        stress_periods_count: int,
        spikes_count: int,
        health_score: Optional[int] = None,
        insights: Optional[List[str]] = None,
        timestamp: Optional[datetime] = None,
        correlation_id: Optional[str] = None
    ):
        if not self.producer:
            logger.error("Kafka producer is not started")
            return
        
        try:
            event_timestamp = timestamp or datetime.utcnow()
            event = {
                "event_id": str(uuid.uuid4()),
                "event_type": "EmotionalStateAnalyzed",
                "timestamp": event_timestamp.isoformat() + "Z",
                "correlation_id": correlation_id or str(uuid.uuid4()),
                "payload": {
                    "user_id": user_id,
                    "date": date,
                    "overall_state": overall_state,
                    "emotional_stability": emotional_stability,
                    "stress_periods_count": stress_periods_count,
                    "spikes_count": spikes_count,
                    "health_score": health_score,
                    "insights": insights or [],
                    "timestamp": event_timestamp.isoformat() + "Z"
                }
            }
            
            value = json.dumps(event).encode('utf-8')
            key = user_id.encode('utf-8')
            
            self.producer.produce(
                topic="metachat.emotional.state.analyzed",
                key=key,
                value=value,
                callback=self._delivery_callback
            )
            
            self.producer.poll(0)
            
            logger.debug("Published EmotionalStateAnalyzed event", user_id=user_id, date=date)
            
        except Exception as e:
            logger.error("Error publishing EmotionalStateAnalyzed event", error=str(e), exc_info=True)
    
    def publish_day_insights_generated(
        self,
        user_id: str,
        date: str,
        total_active_hours: float,
        total_steps: int,
        key_moments_count: int,
        daily_story: str,
        timestamp: Optional[datetime] = None,
        correlation_id: Optional[str] = None
    ):
        if not self.producer:
            logger.error("Kafka producer is not started")
            return
        
        try:
            event_timestamp = timestamp or datetime.utcnow()
            event = {
                "event_id": str(uuid.uuid4()),
                "event_type": "DayInsightsGenerated",
                "timestamp": event_timestamp.isoformat() + "Z",
                "correlation_id": correlation_id or str(uuid.uuid4()),
                "payload": {
                    "user_id": user_id,
                    "date": date,
                    "total_active_hours": total_active_hours,
                    "total_steps": total_steps,
                    "key_moments_count": key_moments_count,
                    "daily_story": daily_story,
                    "timestamp": event_timestamp.isoformat() + "Z"
                }
            }
            
            value = json.dumps(event).encode('utf-8')
            key = user_id.encode('utf-8')
            
            self.producer.produce(
                topic="metachat.day.insights.generated",
                key=key,
                value=value,
                callback=self._delivery_callback
            )
            
            self.producer.poll(0)
            
            logger.debug("Published DayInsightsGenerated event", user_id=user_id, date=date)
            
        except Exception as e:
            logger.error("Error publishing DayInsightsGenerated event", error=str(e), exc_info=True)
    
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

