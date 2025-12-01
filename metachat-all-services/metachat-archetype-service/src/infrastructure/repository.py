from typing import Optional, List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
import uuid

from src.infrastructure.models import UserArchetypeData, ArchetypeCalculation
from src.infrastructure.database import Database


class ArchetypeRepository:
    def __init__(self, db: Database):
        self.db = db
    
    async def get_user_data(self, session: AsyncSession, user_id: str) -> Optional[UserArchetypeData]:
        result = await session.execute(
            select(UserArchetypeData).where(UserArchetypeData.user_id == user_id)
        )
        return result.scalar_one_or_none()
    
    async def create_or_update_user_data(
        self,
        session: AsyncSession,
        user_id: str,
        accumulated_tokens: int,
        aggregated_emotion_vector: Optional[List[float]] = None,
        topic_distribution: Optional[dict] = None,
        stylistic_metrics: Optional[dict] = None
    ) -> UserArchetypeData:
        existing = await self.get_user_data(session, user_id)
        
        if existing:
            existing.accumulated_tokens = accumulated_tokens
            if aggregated_emotion_vector is not None:
                existing.aggregated_emotion_vector = aggregated_emotion_vector
            if topic_distribution is not None:
                existing.topic_distribution = topic_distribution
            if stylistic_metrics is not None:
                existing.stylistic_metrics = stylistic_metrics
            await session.commit()
            await session.refresh(existing)
            return existing
        else:
            new_data = UserArchetypeData(
                user_id=user_id,
                accumulated_tokens=accumulated_tokens,
                aggregated_emotion_vector=aggregated_emotion_vector,
                topic_distribution=topic_distribution,
                stylistic_metrics=stylistic_metrics
            )
            session.add(new_data)
            await session.commit()
            await session.refresh(new_data)
            return new_data
    
    async def save_calculation(
        self,
        session: AsyncSession,
        user_id: str,
        archetype: str,
        archetype_probabilities: dict,
        confidence: float,
        model_version: str,
        tokens_analyzed: int,
        used_data: Optional[dict] = None
    ) -> ArchetypeCalculation:
        calculation = ArchetypeCalculation(
            id=str(uuid.uuid4()),
            user_id=user_id,
            archetype=archetype,
            archetype_probabilities=archetype_probabilities,
            confidence=confidence,
            model_version=model_version,
            tokens_analyzed=tokens_analyzed,
            used_data=used_data
        )
        
        session.add(calculation)
        await session.commit()
        await session.refresh(calculation)
        
        return calculation
    
    async def get_latest_calculation(
        self,
        session: AsyncSession,
        user_id: str
    ) -> Optional[ArchetypeCalculation]:
        result = await session.execute(
            select(ArchetypeCalculation)
            .where(ArchetypeCalculation.user_id == user_id)
            .order_by(ArchetypeCalculation.calculated_at.desc())
            .limit(1)
        )
        return result.scalar_one_or_none()

