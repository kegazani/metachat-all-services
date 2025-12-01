from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from datetime import datetime
import uuid

from src.infrastructure.models import MoodAnalysis
from src.infrastructure.database import Database


class MoodAnalysisRepository:
    def __init__(self, db: Database):
        self.db = db
    
    async def save_analysis(self, session: AsyncSession, analysis_data: dict) -> MoodAnalysis:
        analysis = MoodAnalysis(
            id=str(uuid.uuid4()),
            entry_id=analysis_data["entry_id"],
            user_id=analysis_data["user_id"],
            emotion_vector=analysis_data["emotion_vector"],
            dominant_emotion=analysis_data["dominant_emotion"],
            valence=analysis_data["valence"],
            arousal=analysis_data["arousal"],
            confidence=analysis_data["confidence"],
            model_version=analysis_data["model_version"],
            tokens_count=analysis_data["tokens_count"],
            detected_topics=analysis_data.get("detected_topics", []),
            keywords=analysis_data.get("keywords", [])
        )
        
        session.add(analysis)
        await session.commit()
        await session.refresh(analysis)
        
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

