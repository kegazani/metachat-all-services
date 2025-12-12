from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from datetime import datetime
import uuid
import structlog

from src.infrastructure.models import MoodAnalysis
from src.infrastructure.database import Database

logger = structlog.get_logger()


class MoodAnalysisRepository:
    def __init__(self, db: Database):
        self.db = db
    
    async def save_analysis(self, session: AsyncSession, analysis_data: dict) -> MoodAnalysis:
        detected_topics_raw = analysis_data.get("detected_topics")
        keywords_raw = analysis_data.get("keywords")
        
        logger.debug(
            "Saving analysis to DB",
            entry_id=analysis_data.get("entry_id"),
            detected_topics_raw=detected_topics_raw,
            keywords_raw=keywords_raw,
            detected_topics_type=type(detected_topics_raw).__name__,
            keywords_type=type(keywords_raw).__name__,
            has_detected_topics="detected_topics" in analysis_data,
            has_keywords="keywords" in analysis_data
        )
        
        if detected_topics_raw is None:
            detected_topics = []
        elif isinstance(detected_topics_raw, list):
            detected_topics = [str(t) for t in detected_topics_raw if t]
        else:
            detected_topics = []
        
        if keywords_raw is None:
            keywords = []
        elif isinstance(keywords_raw, list):
            keywords = [str(k) for k in keywords_raw if k]
        else:
            keywords = []
        
        emotion_vector = [float(v) for v in analysis_data["emotion_vector"]]
        
        logger.debug(
            "Processed data for saving",
            entry_id=analysis_data.get("entry_id"),
            detected_topics=detected_topics,
            keywords=keywords,
            detected_topics_count=len(detected_topics),
            keywords_count=len(keywords)
        )
        
        analysis = MoodAnalysis(
            id=str(uuid.uuid4()),
            entry_id=str(analysis_data["entry_id"]),
            user_id=str(analysis_data["user_id"]),
            emotion_vector=emotion_vector,
            dominant_emotion=str(analysis_data["dominant_emotion"]),
            valence=float(analysis_data["valence"]),
            arousal=float(analysis_data["arousal"]),
            confidence=float(analysis_data["confidence"]),
            model_version=str(analysis_data["model_version"]),
            tokens_count=int(analysis_data["tokens_count"]),
            detected_topics=detected_topics,
            keywords=keywords
        )
        
        session.add(analysis)
        await session.commit()
        await session.refresh(analysis)
        
        logger.debug(
            "Analysis saved successfully",
            entry_id=analysis.entry_id,
            saved_detected_topics=analysis.detected_topics,
            saved_keywords=analysis.keywords
        )
        
        return analysis
    
    async def get_by_entry_id(self, session: AsyncSession, entry_id: str) -> Optional[MoodAnalysis]:
        result = await session.execute(
            select(MoodAnalysis).where(MoodAnalysis.entry_id == entry_id)
        )
        return result.scalar_one_or_none()
    
    async def get_by_user_id(
        self,
        session: AsyncSession,
        user_id: str,
        limit: int = 100,
        offset: int = 0
    ) -> list[MoodAnalysis]:
        result = await session.execute(
            select(MoodAnalysis)
            .where(MoodAnalysis.user_id == user_id)
            .order_by(MoodAnalysis.analyzed_at.desc())
            .limit(limit)
            .offset(offset)
        )
        return list(result.scalars().all())

