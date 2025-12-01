import asyncio
from typing import Dict, Any, Optional
import structlog

from src.domain.mood_analyzer import MoodAnalyzer
from src.infrastructure.repository import MoodAnalysisRepository
from src.infrastructure.kafka_client import KafkaProducer
from src.infrastructure.database import Database

logger = structlog.get_logger()


class EventHandler:
    def __init__(
        self,
        mood_analyzer: MoodAnalyzer,
        repository: MoodAnalysisRepository,
        kafka_producer: KafkaProducer,
        db: Database
    ):
        self.mood_analyzer = mood_analyzer
        self.repository = repository
        self.kafka_producer = kafka_producer
        self.db = db
    
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
            
            metadata = event_data.get("metadata", {})
            if isinstance(metadata, str):
                import json
                metadata = json.loads(metadata)
            
            correlation_id = correlation_id or metadata.get("correlation_id") or event_data.get("correlation_id")
            causation_id = causation_id or metadata.get("causation_id") or event_data.get("causation_id")
            
            entry_id = event_data.get("aggregate_id") or payload.get("entry_id")
            user_id = payload.get("user_id") or metadata.get("user_id")
            content = payload.get("content") or payload.get("text", "")
            tokens_count = payload.get("token_count", 0)
            
            if not all([entry_id, user_id, content]):
                logger.warning(
                    "Missing required fields in DiaryEntryCreated",
                    event_data=event_data
                )
                return
            
            logger.info("Processing DiaryEntryCreated", entry_id=entry_id, user_id=user_id)
            
            analysis_result = self.mood_analyzer.analyze(
                text=content,
                entry_id=entry_id,
                user_id=user_id,
                tokens_count=tokens_count
            )
            
            async for session in self.db.get_session():
                try:
                    await self.repository.save_analysis(session, analysis_result)
                    break
                finally:
                    await session.close()
            
            self.kafka_producer.publish_mood_analyzed(
                analysis_result,
                correlation_id=correlation_id,
                causation_id=causation_id or event_data.get("id")
            )
            
            logger.info("DiaryEntryCreated processed", entry_id=entry_id, user_id=user_id)
            
        except Exception as e:
            logger.error(
                "Error processing DiaryEntryCreated",
                error=str(e),
                entry_id=entry_id if 'entry_id' in locals() else None,
                user_id=user_id if 'user_id' in locals() else None,
                exc_info=True
            )
            
            entry_id = event_data.get("aggregate_id") or (payload.get("entry_id") if 'payload' in locals() else None)
            user_id = payload.get("user_id") if 'payload' in locals() else None
            
            if entry_id and user_id:
                self.kafka_producer.publish_mood_analysis_failed(
                    entry_id=entry_id,
                    user_id=user_id,
                    error_message=str(e),
                    error_type=type(e).__name__,
                    correlation_id=correlation_id
                )
    
    async def handle_diary_entry_updated(
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
            
            metadata = event_data.get("metadata", {})
            if isinstance(metadata, str):
                import json
                metadata = json.loads(metadata)
            
            correlation_id = correlation_id or metadata.get("correlation_id") or event_data.get("correlation_id")
            causation_id = causation_id or metadata.get("causation_id") or event_data.get("causation_id")
            
            entry_id = event_data.get("aggregate_id")
            user_id = payload.get("user_id") or metadata.get("user_id")
            content = payload.get("content") or payload.get("text", "")
            tokens_count = payload.get("token_count", 0)
            
            if not all([entry_id, user_id, content]):
                logger.warning(
                    "Missing required fields in DiaryEntryUpdated",
                    event_data=event_data
                )
                return
            
            logger.info("Processing DiaryEntryUpdated", entry_id=entry_id, user_id=user_id)
            
            analysis_result = self.mood_analyzer.analyze(
                text=content,
                entry_id=entry_id,
                user_id=user_id,
                tokens_count=tokens_count
            )
            
            async for session in self.db.get_session():
                try:
                    existing = await self.repository.get_by_entry_id(session, entry_id)
                    if existing:
                        await session.delete(existing)
                        await session.commit()
                    
                    await self.repository.save_analysis(session, analysis_result)
                    break
                finally:
                    await session.close()
            
            self.kafka_producer.publish_mood_analyzed(
                analysis_result,
                correlation_id=correlation_id,
                causation_id=causation_id or event_data.get("id")
            )
            
            logger.info("DiaryEntryUpdated processed", entry_id=entry_id, user_id=user_id)
            
        except Exception as e:
            logger.error(
                "Error processing DiaryEntryUpdated",
                error=str(e),
                entry_id=entry_id if 'entry_id' in locals() else None,
                user_id=user_id if 'user_id' in locals() else None,
                exc_info=True
            )
            
            entry_id = event_data.get("aggregate_id")
            user_id = payload.get("user_id") if 'payload' in locals() else None
            
            if entry_id and user_id:
                self.kafka_producer.publish_mood_analysis_failed(
                    entry_id=entry_id,
                    user_id=user_id,
                    error_message=str(e),
                    error_type=type(e).__name__,
                    correlation_id=correlation_id
                )
    
    async def handle_message(
        self,
        topic: str,
        event_data: Dict[str, Any],
        correlation_id: Optional[str] = None,
        causation_id: Optional[str] = None
    ):
        if "diary.entry.created" in topic or "DiaryEntryCreated" in topic:
            await self.handle_diary_entry_created(event_data, correlation_id, causation_id)
        elif "diary.entry.updated" in topic or "DiaryEntryUpdated" in topic:
            await self.handle_diary_entry_updated(event_data, correlation_id, causation_id)
        else:
            logger.warning("Unknown topic", topic=topic)

