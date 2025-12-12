from typing import Optional, List, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, func as sql_func, update
from datetime import datetime, timedelta
import uuid

from src.infrastructure.models import BiometricData, BiometricSummary, WatchData, UserBiometricState
from src.infrastructure.database import Database


class BiometricRepository:
    def __init__(self, db: Database):
        self.db = db
    
    async def save_biometric_data(
        self, session: AsyncSession, user_id: str, device_id: Optional[str],
        heart_rate: Optional[float], sleep_data: Optional[dict],
        activity: Optional[dict], recorded_at: datetime
    ) -> BiometricData:
        biometric = BiometricData(
            id=str(uuid.uuid4()),
            user_id=user_id,
            device_id=device_id,
            heart_rate=heart_rate,
            sleep_data=sleep_data,
            activity=activity,
            recorded_at=recorded_at
        )
        session.add(biometric)
        await session.commit()
        await session.refresh(biometric)
        return biometric
    
    async def save_watch_data(
        self, session: AsyncSession,
        user_id: str,
        device_id: Optional[str],
        device_type: Optional[str],
        heart_rate: Optional[float],
        heart_rate_variability: Optional[float],
        resting_heart_rate: Optional[float],
        blood_oxygen: Optional[float],
        respiratory_rate: Optional[float],
        body_temperature: Optional[float],
        stress_level: Optional[int],
        energy_level: Optional[int],
        steps: Optional[int],
        distance_meters: Optional[float],
        calories_burned: Optional[float],
        active_minutes: Optional[int],
        sleep_minutes: Optional[int],
        sleep_score: Optional[int],
        sleep_data: Optional[dict],
        latitude: Optional[float],
        longitude: Optional[float],
        raw_data: Optional[dict],
        recorded_at: datetime
    ) -> WatchData:
        watch_data = WatchData(
            id=str(uuid.uuid4()),
            user_id=user_id,
            device_id=device_id,
            device_type=device_type,
            heart_rate=heart_rate,
            heart_rate_variability=heart_rate_variability,
            resting_heart_rate=resting_heart_rate,
            blood_oxygen=blood_oxygen,
            respiratory_rate=respiratory_rate,
            body_temperature=body_temperature,
            stress_level=stress_level,
            energy_level=energy_level,
            steps=steps,
            distance_meters=distance_meters,
            calories_burned=calories_burned,
            active_minutes=active_minutes,
            sleep_minutes=sleep_minutes,
            sleep_score=sleep_score,
            sleep_data=sleep_data,
            latitude=latitude,
            longitude=longitude,
            raw_data=raw_data,
            recorded_at=recorded_at
        )
        session.add(watch_data)
        await session.commit()
        await session.refresh(watch_data)
        return watch_data
    
    async def get_biometric_data_by_user(
        self, session: AsyncSession, user_id: str,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        limit: int = 100
    ) -> List[BiometricData]:
        query = select(BiometricData).where(BiometricData.user_id == user_id)
        
        if start_date:
            query = query.where(BiometricData.recorded_at >= start_date)
        if end_date:
            query = query.where(BiometricData.recorded_at <= end_date)
        
        query = query.order_by(BiometricData.recorded_at.desc()).limit(limit)
        
        result = await session.execute(query)
        return list(result.scalars().all())
    
    async def get_watch_data_by_user(
        self, session: AsyncSession, user_id: str,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        limit: int = 100
    ) -> List[WatchData]:
        query = select(WatchData).where(WatchData.user_id == user_id)
        
        if start_date:
            query = query.where(WatchData.recorded_at >= start_date)
        if end_date:
            query = query.where(WatchData.recorded_at <= end_date)
        
        query = query.order_by(WatchData.recorded_at.desc()).limit(limit)
        
        result = await session.execute(query)
        return list(result.scalars().all())
    
    async def get_latest_watch_data(
        self, session: AsyncSession, user_id: str
    ) -> Optional[WatchData]:
        query = select(WatchData).where(
            WatchData.user_id == user_id
        ).order_by(WatchData.recorded_at.desc()).limit(1)
        
        result = await session.execute(query)
        return result.scalar_one_or_none()
    
    async def get_or_create_daily_summary(
        self, session: AsyncSession, user_id: str, summary_date: str
    ) -> BiometricSummary:
        result = await session.execute(
            select(BiometricSummary).where(
                and_(
                    BiometricSummary.user_id == user_id,
                    BiometricSummary.date == summary_date
                )
            )
        )
        existing = result.scalar_one_or_none()
        
        if existing:
            return existing
        
        new_summary = BiometricSummary(
            id=str(uuid.uuid4()),
            user_id=user_id,
            date=summary_date,
            data_points=0
        )
        session.add(new_summary)
        await session.commit()
        await session.refresh(new_summary)
        return new_summary
    
    async def update_daily_summary_from_watch(
        self, session: AsyncSession, user_id: str, summary_date: str
    ) -> BiometricSummary:
        summary = await self.get_or_create_daily_summary(session, user_id, summary_date)
        
        start_of_day = datetime.strptime(summary_date, "%Y-%m-%d")
        end_of_day = start_of_day + timedelta(days=1)
        
        stats_query = select(
            sql_func.avg(WatchData.heart_rate).label("avg_hr"),
            sql_func.min(WatchData.heart_rate).label("min_hr"),
            sql_func.max(WatchData.heart_rate).label("max_hr"),
            sql_func.avg(WatchData.heart_rate_variability).label("avg_hrv"),
            sql_func.avg(WatchData.blood_oxygen).label("avg_spo2"),
            sql_func.min(WatchData.blood_oxygen).label("min_spo2"),
            sql_func.avg(WatchData.stress_level).label("avg_stress"),
            sql_func.max(WatchData.stress_level).label("max_stress"),
            sql_func.max(WatchData.steps).label("total_steps"),
            sql_func.max(WatchData.calories_burned).label("total_calories"),
            sql_func.max(WatchData.active_minutes).label("active_mins"),
            sql_func.max(WatchData.distance_meters).label("total_distance"),
            sql_func.count(WatchData.id).label("data_points")
        ).where(
            and_(
                WatchData.user_id == user_id,
                WatchData.recorded_at >= start_of_day,
                WatchData.recorded_at < end_of_day
            )
        )
        
        result = await session.execute(stats_query)
        stats = result.one()
        
        sleep_query = select(
            sql_func.max(WatchData.sleep_minutes).label("sleep_mins"),
            sql_func.max(WatchData.sleep_score).label("sleep_score")
        ).where(
            and_(
                WatchData.user_id == user_id,
                WatchData.recorded_at >= start_of_day - timedelta(hours=12),
                WatchData.recorded_at < end_of_day,
                WatchData.sleep_minutes.isnot(None)
            )
        )
        sleep_result = await session.execute(sleep_query)
        sleep_stats = sleep_result.one()
        
        summary.avg_heart_rate = stats.avg_hr
        summary.min_heart_rate = stats.min_hr
        summary.max_heart_rate = stats.max_hr
        summary.avg_hrv = stats.avg_hrv
        summary.avg_blood_oxygen = stats.avg_spo2
        summary.min_blood_oxygen = stats.min_spo2
        summary.avg_stress_level = stats.avg_stress
        summary.max_stress_level = stats.max_stress
        summary.total_steps = stats.total_steps
        summary.total_calories = stats.total_calories
        summary.active_minutes = stats.active_mins
        summary.total_distance_meters = stats.total_distance
        summary.total_sleep_minutes = sleep_stats.sleep_mins
        summary.sleep_score = sleep_stats.sleep_score
        summary.data_points = stats.data_points or 0
        
        summary.health_score = self._calculate_health_score(summary)
        
        await session.commit()
        await session.refresh(summary)
        return summary
    
    def _calculate_health_score(self, summary: BiometricSummary) -> int:
        score = 50
        
        if summary.avg_heart_rate:
            if 60 <= summary.avg_heart_rate <= 80:
                score += 10
            elif 50 <= summary.avg_heart_rate <= 90:
                score += 5
        
        if summary.total_steps:
            if summary.total_steps >= 10000:
                score += 15
            elif summary.total_steps >= 7500:
                score += 10
            elif summary.total_steps >= 5000:
                score += 5
        
        if summary.total_sleep_minutes:
            hours = summary.total_sleep_minutes / 60
            if 7 <= hours <= 9:
                score += 15
            elif 6 <= hours <= 10:
                score += 10
            elif hours >= 5:
                score += 5
        
        if summary.avg_blood_oxygen:
            if summary.avg_blood_oxygen >= 97:
                score += 10
            elif summary.avg_blood_oxygen >= 95:
                score += 5
        
        return min(100, max(0, score))
    
    async def get_or_create_user_state(
        self, session: AsyncSession, user_id: str
    ) -> UserBiometricState:
        result = await session.execute(
            select(UserBiometricState).where(UserBiometricState.user_id == user_id)
        )
        existing = result.scalar_one_or_none()
        
        if existing:
            return existing
        
        new_state = UserBiometricState(user_id=user_id)
        session.add(new_state)
        await session.commit()
        await session.refresh(new_state)
        return new_state
    
    async def update_user_state(
        self, session: AsyncSession, user_id: str,
        watch_data: WatchData, daily_summary: BiometricSummary
    ) -> UserBiometricState:
        state = await self.get_or_create_user_state(session, user_id)
        
        if watch_data.heart_rate:
            state.current_heart_rate = watch_data.heart_rate
        if watch_data.resting_heart_rate:
            state.resting_heart_rate = watch_data.resting_heart_rate
        if watch_data.device_type:
            state.device_type = watch_data.device_type
        if watch_data.device_id:
            state.device_id = watch_data.device_id
        
        state.today_steps = daily_summary.total_steps
        state.today_calories = daily_summary.total_calories
        state.today_active_minutes = daily_summary.active_minutes
        state.health_score = daily_summary.health_score
        
        if daily_summary.total_sleep_minutes:
            state.last_sleep_duration_minutes = daily_summary.total_sleep_minutes
            state.last_sleep_score = daily_summary.sleep_score
        
        state.is_connected = True
        state.last_sync = datetime.utcnow()
        
        seven_days_ago = datetime.utcnow() - timedelta(days=7)
        avg_query = select(
            sql_func.avg(BiometricSummary.avg_hrv).label("avg_hrv"),
            sql_func.avg(BiometricSummary.avg_blood_oxygen).label("avg_spo2"),
            sql_func.avg(BiometricSummary.avg_stress_level).label("avg_stress")
        ).where(
            and_(
                BiometricSummary.user_id == user_id,
                BiometricSummary.date >= seven_days_ago.strftime("%Y-%m-%d")
            )
        )
        avg_result = await session.execute(avg_query)
        avgs = avg_result.one()
        
        state.avg_hrv_7d = avgs.avg_hrv
        state.avg_blood_oxygen_7d = avgs.avg_spo2
        state.avg_stress_level_7d = avgs.avg_stress
        
        await session.commit()
        await session.refresh(state)
        return state
    
    async def get_user_biometric_profile(
        self, session: AsyncSession, user_id: str
    ) -> Optional[UserBiometricState]:
        result = await session.execute(
            select(UserBiometricState).where(UserBiometricState.user_id == user_id)
        )
        return result.scalar_one_or_none()
    
    async def get_summaries_for_period(
        self, session: AsyncSession, user_id: str, days: int = 7
    ) -> List[BiometricSummary]:
        start_date = (datetime.utcnow() - timedelta(days=days)).strftime("%Y-%m-%d")
        
        query = select(BiometricSummary).where(
            and_(
                BiometricSummary.user_id == user_id,
                BiometricSummary.date >= start_date
            )
        ).order_by(BiometricSummary.date.desc())
        
        result = await session.execute(query)
        return list(result.scalars().all())
    
    async def update_daily_summary(
        self, session: AsyncSession, summary: BiometricSummary,
        avg_heart_rate: Optional[float] = None,
        total_sleep_hours: Optional[float] = None,
        total_steps: Optional[int] = None,
        total_calories: Optional[float] = None,
        data_points: Optional[int] = None
    ) -> BiometricSummary:
        if avg_heart_rate is not None:
            summary.avg_heart_rate = avg_heart_rate
        if total_sleep_hours is not None:
            summary.total_sleep_minutes = int(total_sleep_hours * 60)
        if total_steps is not None:
            summary.total_steps = total_steps
        if total_calories is not None:
            summary.total_calories = total_calories
        if data_points is not None:
            summary.data_points = data_points
        
        await session.commit()
        await session.refresh(summary)
        return summary

