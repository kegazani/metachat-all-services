import asyncio
from typing import Dict, Any, Optional, List
from datetime import datetime, timedelta
import numpy as np
import structlog

from src.domain.archetype_classifier import ArchetypeClassifier
from src.infrastructure.repository import ArchetypeRepository
from src.infrastructure.kafka_client import KafkaProducer
from src.infrastructure.database import Database
from src.config import Config

logger = structlog.get_logger()


class EventHandler:
    def __init__(
        self,
        classifier: ArchetypeClassifier,
        repository: ArchetypeRepository,
        kafka_producer: KafkaProducer,
        db: Database,
        config: Config
    ):
        self.classifier = classifier
        self.repository = repository
        self.kafka_producer = kafka_producer
        self.db = db
        self.config = config
    
    async def handle_mood_analyzed(
        self,
        event_data: Dict[str, Any],
        correlation_id: Optional[str] = None,
        causation_id: Optional[str] = None
    ):
        try:
            payload = event_data.get("payload", {})
            if isinstance(payload, str):
                import json
                payload = json.loads(payload)
            
            user_id = payload.get("user_id")
            emotion_vector = payload.get("emotion_vector", [])
            detected_topics = payload.get("detected_topics", [])
            
            if not user_id or not emotion_vector:
                logger.warning("Missing required fields in MoodAnalyzed", event_data=event_data)
                return
            
            logger.info("Processing MoodAnalyzed", user_id=user_id)
            
            async for session in self.db.get_session():
                try:
                    user_data = await self.repository.get_user_data(session, user_id)
                    
                    if user_data:
                        current_emotions = user_data.aggregated_emotion_vector or [0.0] * 8
                        current_topics = user_data.topic_distribution or {}
                        
                        new_emotions = np.array(current_emotions) * 0.7 + np.array(emotion_vector) * 0.3
                        new_emotions = new_emotions.tolist()
                        
                        for topic in detected_topics:
                            current_topics[topic] = current_topics.get(topic, 0) + 1
                        
                        total_topic_count = sum(current_topics.values())
                        if total_topic_count > 0:
                            topic_distribution = {k: v / total_topic_count for k, v in current_topics.items()}
                        else:
                            topic_distribution = {}
                        
                        await self.repository.create_or_update_user_data(
                            session,
                            user_id,
                            user_data.accumulated_tokens,
                            aggregated_emotion_vector=new_emotions,
                            topic_distribution=topic_distribution
                        )
                    break
                finally:
                    await session.close()
            
            await self._check_triggers(user_id, correlation_id)
            
        except Exception as e:
            logger.error("Error processing MoodAnalyzed", error=str(e), exc_info=True)
    
    async def handle_diary_entry_created(
        self,
        event_data: Dict[str, Any],
        correlation_id: Optional[str] = None,
        causation_id: Optional[str] = None
    ):
        try:
            payload = event_data.get("payload", {})
            if isinstance(payload, str):
                import json
                payload = json.loads(payload)
            
            user_id = payload.get("user_id")
            tokens_count = payload.get("token_count", 0)
            
            if not user_id:
                logger.warning("Missing user_id in DiaryEntryCreated", event_data=event_data)
                return
            
            logger.info("Processing DiaryEntryCreated", user_id=user_id, tokens_count=tokens_count)
            
            async for session in self.db.get_session():
                try:
                    user_data = await self.repository.get_user_data(session, user_id)
                    
                    if user_data:
                        new_tokens = user_data.accumulated_tokens + tokens_count
                        await self.repository.create_or_update_user_data(
                            session,
                            user_id,
                            accumulated_tokens=new_tokens
                        )
                    else:
                        await self.repository.create_or_update_user_data(
                            session,
                            user_id,
                            accumulated_tokens=tokens_count
                        )
                    break
                finally:
                    await session.close()
            
            await self._check_triggers(user_id, correlation_id)
            
        except Exception as e:
            logger.error("Error processing DiaryEntryCreated", error=str(e), exc_info=True)
    
    async def _check_triggers(self, user_id: str, correlation_id: Optional[str] = None):
        async for session in self.db.get_session():
            try:
                user_data = await self.repository.get_user_data(session, user_id)
                if not user_data:
                    return
                
                latest_calculation = await self.repository.get_latest_calculation(session, user_id)
                
                should_calculate = False
                reason = ""
                
                if not latest_calculation:
                    if user_data.accumulated_tokens >= self.config.initial_tokens_threshold:
                        should_calculate = True
                        reason = "initial_threshold"
                else:
                    tokens_since_calc = user_data.accumulated_tokens - latest_calculation.tokens_analyzed
                    days_since_calc = (datetime.utcnow() - latest_calculation.calculated_at.replace(tzinfo=None)).days
                    
                    if tokens_since_calc >= self.config.recalculation_tokens_threshold:
                        should_calculate = True
                        reason = "tokens_threshold"
                    elif days_since_calc >= self.config.recalculation_interval_days:
                        should_calculate = True
                        reason = "time_threshold"
                
                if should_calculate:
                    await self._calculate_archetype(session, user_data, latest_calculation, reason, correlation_id)
                
            finally:
                await session.close()
    
    async def _calculate_archetype(
        self,
        session,
        user_data,
        previous_calculation: Optional[Any],
        reason: str,
        correlation_id: Optional[str] = None
    ):
        try:
            emotion_vector = user_data.aggregated_emotion_vector or [0.0] * 8
            topic_distribution = user_data.topic_distribution or {}
            stylistic_metrics = user_data.stylistic_metrics or {}
            
            avg_valence = sum(emotion_vector[:4]) - sum(emotion_vector[4:]) if len(emotion_vector) >= 8 else 0.0
            avg_arousal = sum(emotion_vector[::2]) - sum(emotion_vector[1::2]) if len(emotion_vector) >= 8 else 0.0
            
            archetype, probabilities, confidence = self.classifier.classify(
                emotion_vector,
                topic_distribution,
                stylistic_metrics,
                avg_valence,
                avg_arousal
            )
            
            if confidence < self.config.min_confidence_threshold:
                logger.info(
                    "Archetype confidence too low",
                    user_id=user_data.user_id,
                    confidence=confidence,
                    threshold=self.config.min_confidence_threshold
                )
                return
            
            calculation = await self.repository.save_calculation(
                session,
                user_data.user_id,
                archetype,
                probabilities,
                confidence,
                self.config.model_version,
                user_data.accumulated_tokens,
                used_data={
                    "emotion_vector": emotion_vector,
                    "topic_distribution": topic_distribution,
                    "stylistic_metrics": stylistic_metrics
                }
            )
            
            if previous_calculation and previous_calculation.archetype == archetype:
                self.kafka_producer.publish_archetype_updated(
                    user_data.user_id,
                    archetype,
                    probabilities,
                    confidence,
                    self.config.model_version,
                    user_data.accumulated_tokens,
                    correlation_id=correlation_id
                )
            else:
                self.kafka_producer.publish_archetype_assigned(
                    user_data.user_id,
                    archetype,
                    probabilities,
                    confidence,
                    self.config.model_version,
                    user_data.accumulated_tokens,
                    correlation_id=correlation_id
                )
            
            logger.info(
                "Archetype calculated",
                user_id=user_data.user_id,
                archetype=archetype,
                confidence=confidence,
                reason=reason
            )
            
        except Exception as e:
            logger.error("Error calculating archetype", error=str(e), exc_info=True)
    
    async def handle_message(
        self,
        topic: str,
        event_data: Dict[str, Any],
        correlation_id: Optional[str] = None,
        causation_id: Optional[str] = None
    ):
        if "mood.analyzed" in topic or "MoodAnalyzed" in topic:
            await self.handle_mood_analyzed(event_data, correlation_id, causation_id)
        elif "diary.entry.created" in topic or "DiaryEntryCreated" in topic:
            await self.handle_diary_entry_created(event_data, correlation_id, causation_id)
        else:
            logger.warning("Unknown topic", topic=topic)

