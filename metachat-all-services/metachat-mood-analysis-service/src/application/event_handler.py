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
        entry_id = None
        user_id = None
        
        try:
            logger.debug("Raw event_data", event_data_keys=list(event_data.keys()) if isinstance(event_data, dict) else [])
            
            payload = event_data.get("payload", {})
            if isinstance(payload, str):
                import json
                payload = json.loads(payload)
            
            metadata = event_data.get("metadata", {})
            if isinstance(metadata, str):
                import json
                metadata = json.loads(metadata)
            
            logger.debug(
                "Parsed structure",
                payload_keys=list(payload.keys()) if isinstance(payload, dict) else [],
                metadata_keys=list(metadata.keys()) if isinstance(metadata, dict) else []
            )
            
            correlation_id = correlation_id or metadata.get("correlation_id") or event_data.get("correlation_id")
            causation_id = causation_id or metadata.get("causation_id") or event_data.get("causation_id")
            
            entry_id = event_data.get("aggregate_id") or payload.get("entry_id") or payload.get("diary_id")
            user_id = payload.get("user_id")
            
            if not user_id:
                logger.error(
                    "user_id is missing in event payload",
                    entry_id=entry_id,
                    payload_keys=list(payload.keys()) if isinstance(payload, dict) else [],
                    event_data_keys=list(event_data.keys()) if isinstance(event_data, dict) else []
                )
                return
            
            text = payload.get("content") or payload.get("text", "")
            tokens_count = payload.get("token_count", 0) or payload.get("tokens_count", 0)
            
            logger.info(
                "Extracted event data (created)",
                entry_id=entry_id,
                user_id=user_id,
                text_length=len(text) if text else 0,
                text_preview=text[:100] if text else "",
                text=text,
                tokens_count=tokens_count,
                payload_content=payload.get("content") if isinstance(payload, dict) else None,
                payload_text=payload.get("text") if isinstance(payload, dict) else None
            )
            
            if not all([entry_id, user_id, text]):
                logger.warning(
                    "Missing required fields in DiaryEntryCreated",
                    entry_id=entry_id,
                    user_id=user_id,
                    has_text=bool(text)
                )
                return
            
            result = self.mood_analyzer.analyze(
                text=text,
                entry_id=entry_id,
                user_id=user_id,
                tokens_count=tokens_count
            )
            
            logger.info(
                "Analysis result before saving",
                entry_id=entry_id,
                has_keywords="keywords" in result,
                keywords=result.get("keywords", []),
                keywords_count=len(result.get("keywords", [])),
                has_detected_topics="detected_topics" in result,
                detected_topics=result.get("detected_topics", []),
                text_length=len(text) if text else 0,
                result_keys=list(result.keys())
            )
            
            if self.db and self.repository and entry_id != "temp" and user_id != "temp":
                try:
                    async with self.db.async_session_maker() as session:
                        existing = await self.repository.get_by_entry_id(session, entry_id)
                        if existing:
                            await session.delete(existing)
                            await session.commit()
                        
                        saved_analysis = await self.repository.save_analysis(session, result)
                        logger.debug(
                            "Analysis saved to DB",
                            entry_id=entry_id,
                            saved_keywords=saved_analysis.keywords,
                            saved_keywords_count=len(saved_analysis.keywords) if saved_analysis.keywords else 0,
                            saved_detected_topics=saved_analysis.detected_topics
                        )
                except Exception as e:
                    logger.error(
                        "Error saving analysis to DB",
                        entry_id=entry_id,
                        error=str(e),
                        result_keywords=result.get("keywords", []),
                        exc_info=True
                    )
            
            self.kafka_producer.publish_mood_analyzed(
                result,
                correlation_id=correlation_id,
                causation_id=causation_id or event_data.get("id")
            )
            
            logger.info("DiaryEntryCreated processed", entry_id=entry_id, user_id=user_id)
            
        except Exception as e:
            logger.error(
                "Error processing DiaryEntryCreated",
                error=str(e),
                entry_id=entry_id,
                user_id=user_id,
                exc_info=True
            )
            
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
        entry_id = None
        user_id = None
        
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
            
            entry_id = event_data.get("aggregate_id") or payload.get("entry_id") or payload.get("diary_id")
            user_id = payload.get("user_id")
            
            if not user_id:
                logger.error(
                    "user_id is missing in event payload",
                    entry_id=entry_id,
                    payload_keys=list(payload.keys()) if isinstance(payload, dict) else [],
                    event_data_keys=list(event_data.keys()) if isinstance(event_data, dict) else []
                )
                return
            
            text = payload.get("content") or payload.get("text", "")
            tokens_count = payload.get("token_count", 0) or payload.get("tokens_count", 0)
            
            logger.info(
                "Extracted event data (updated)",
                entry_id=entry_id,
                user_id=user_id,
                text_length=len(text) if text else 0,
                text_preview=text[:100] if text else "",
                text=text,
                tokens_count=tokens_count,
                payload_content=payload.get("content"),
                payload_text=payload.get("text")
            )
            
            if not all([entry_id, user_id, text]):
                logger.warning(
                    "Missing required fields in DiaryEntryUpdated",
                    entry_id=entry_id,
                    user_id=user_id,
                    has_text=bool(text)
                )
                return
            
            result = self.mood_analyzer.analyze(
                text=text,
                entry_id=entry_id,
                user_id=user_id,
                tokens_count=tokens_count
            )
            
            logger.info(
                "Analysis result before saving (updated)",
                entry_id=entry_id,
                has_keywords="keywords" in result,
                keywords=result.get("keywords", []),
                keywords_count=len(result.get("keywords", [])),
                has_detected_topics="detected_topics" in result,
                detected_topics=result.get("detected_topics", []),
                text_length=len(text) if text else 0,
                result_keys=list(result.keys())
            )
            
            if self.db and self.repository and entry_id != "temp" and user_id != "temp":
                try:
                    async with self.db.async_session_maker() as session:
                        existing = await self.repository.get_by_entry_id(session, entry_id)
                        if existing:
                            await session.delete(existing)
                            await session.commit()
                        
                        saved_analysis = await self.repository.save_analysis(session, result)
                        logger.debug(
                            "Analysis saved to DB (updated)",
                            entry_id=entry_id,
                            saved_keywords=saved_analysis.keywords,
                            saved_keywords_count=len(saved_analysis.keywords) if saved_analysis.keywords else 0,
                            saved_detected_topics=saved_analysis.detected_topics
                        )
                except Exception as e:
                    logger.error(
                        "Error saving analysis to DB",
                        entry_id=entry_id,
                        error=str(e),
                        result_keywords=result.get("keywords", []),
                        exc_info=True
                    )
            
            self.kafka_producer.publish_mood_analyzed(
                result,
                correlation_id=correlation_id,
                causation_id=causation_id or event_data.get("id")
            )
            
            logger.info("DiaryEntryUpdated processed", entry_id=entry_id, user_id=user_id)
            
        except Exception as e:
            logger.error(
                "Error processing DiaryEntryUpdated",
                error=str(e),
                entry_id=entry_id,
                user_id=user_id,
                exc_info=True
            )
            
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

