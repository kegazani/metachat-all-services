from typing import Optional, List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
import uuid

from src.infrastructure.models import UserPersonalityData, BigFiveCalculation
from src.infrastructure.database import Database


class PersonalityRepository:
    def __init__(self, db: Database):
        self.db = db
    
    async def get_user_data(self, session: AsyncSession, user_id: str) -> Optional[UserPersonalityData]:
        result = await session.execute(
            select(UserPersonalityData).where(UserPersonalityData.user_id == user_id)
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
    ) -> UserPersonalityData:
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
            new_data = UserPersonalityData(
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
        openness: float,
        conscientiousness: float,
        extraversion: float,
        agreeableness: float,
        neuroticism: float,
        dominant_trait: str,
        confidence: float,
        model_version: str,
        tokens_analyzed: int,
        used_data: Optional[dict] = None
    ) -> BigFiveCalculation:
        calculation = BigFiveCalculation(
            id=str(uuid.uuid4()),
            user_id=user_id,
            openness=openness,
            conscientiousness=conscientiousness,
            extraversion=extraversion,
            agreeableness=agreeableness,
            neuroticism=neuroticism,
            dominant_trait=dominant_trait,
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
    ) -> Optional[BigFiveCalculation]:
        result = await session.execute(
            select(BigFiveCalculation)
            .where(BigFiveCalculation.user_id == user_id)
            .order_by(BigFiveCalculation.calculated_at.desc())
            .limit(1)
        )
        return result.scalar_one_or_none()
    
    async def get_profile_progress(
        self,
        session: AsyncSession,
        user_id: str
    ) -> Optional[dict]:
        from datetime import datetime, timedelta
        
        user_data = await self.get_user_data(session, user_id)
        if not user_data:
            return {
                "tokens_analyzed": 0,
                "tokens_required_for_first": 50,
                "tokens_required_for_recalc": 100,
                "days_since_last_calc": 0,
                "days_until_recalc": 0,
                "is_first_calculation": True,
                "progress_percentage": 0.0
            }
        
        latest_calc = await self.get_latest_calculation(session, user_id)
        
        tokens_analyzed = user_data.accumulated_tokens
        tokens_required_for_first = 50
        tokens_required_for_recalc = 100
        
        is_first_calculation = latest_calc is None
        
        days_since_last_calc = 0
        days_until_recalc = 0
        
        if latest_calc:
            days_since_last_calc = (datetime.now(latest_calc.calculated_at.tzinfo) - latest_calc.calculated_at).days
            days_until_recalc = max(0, 7 - days_since_last_calc)
        
        if is_first_calculation:
            progress_percentage = min(1.0, float(tokens_analyzed) / float(tokens_required_for_first))
        else:
            tokens_since_calc = tokens_analyzed - latest_calc.tokens_analyzed
            progress_percentage = min(1.0, float(tokens_since_calc) / float(tokens_required_for_recalc))
        
        return {
            "tokens_analyzed": tokens_analyzed,
            "tokens_required_for_first": tokens_required_for_first,
            "tokens_required_for_recalc": tokens_required_for_recalc,
            "days_since_last_calc": days_since_last_calc,
            "days_until_recalc": days_until_recalc,
            "is_first_calculation": is_first_calculation,
            "progress_percentage": progress_percentage
        }

