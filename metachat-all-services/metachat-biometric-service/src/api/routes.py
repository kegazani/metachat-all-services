from fastapi import APIRouter, HTTPException, Query, WebSocket, WebSocketDisconnect
from typing import List, Optional, Dict
from datetime import datetime
import structlog
import json
import asyncio

from src.domain.biometric_data import (
    BiometricDataRequest, BiometricDataResponse,
    WatchDataRequest, WatchDataResponse,
    BiometricSummaryResponse, UserBiometricProfile,
    RealtimeWatchEvent
)
from src.api.state import app_state

logger = structlog.get_logger()

router = APIRouter(prefix="/biometric", tags=["biometric"])


class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, List[WebSocket]] = {}
    
    async def connect(self, websocket: WebSocket, user_id: str):
        await websocket.accept()
        if user_id not in self.active_connections:
            self.active_connections[user_id] = []
        self.active_connections[user_id].append(websocket)
        logger.info("WebSocket connected", user_id=user_id)
    
    def disconnect(self, websocket: WebSocket, user_id: str):
        if user_id in self.active_connections:
            if websocket in self.active_connections[user_id]:
                self.active_connections[user_id].remove(websocket)
            if not self.active_connections[user_id]:
                del self.active_connections[user_id]
        logger.info("WebSocket disconnected", user_id=user_id)
    
    async def send_to_user(self, user_id: str, data: dict):
        if user_id in self.active_connections:
            for connection in self.active_connections[user_id]:
                try:
                    await connection.send_json(data)
                except Exception as e:
                    logger.error("Error sending WebSocket message", error=str(e))
    
    async def broadcast_to_user(self, user_id: str, message: str):
        if user_id in self.active_connections:
            for connection in self.active_connections[user_id]:
                await connection.send_text(message)


manager = ConnectionManager()


@router.websocket("/ws/{user_id}")
async def websocket_endpoint(websocket: WebSocket, user_id: str):
    await manager.connect(websocket, user_id)
    
    db = app_state.get("db")
    repository = app_state.get("repository")
    kafka_producer = app_state.get("kafka_producer")
    
    try:
        while True:
            data = await websocket.receive_json()
            
            try:
                watch_data = WatchDataRequest(**data)
                watch_data.user_id = user_id
                
                recorded_at = watch_data.recorded_at or datetime.utcnow()
                
                async for session in db.get_session():
                    sleep_data_dict = watch_data.sleep_data.model_dump() if watch_data.sleep_data else None
                    activity_dict = watch_data.activity.model_dump() if watch_data.activity else None
                    
                    steps = watch_data.activity.steps if watch_data.activity else None
                    distance = watch_data.activity.distance_meters if watch_data.activity else None
                    calories = watch_data.activity.calories_burned if watch_data.activity else None
                    active_mins = watch_data.activity.active_minutes if watch_data.activity else None
                    sleep_mins = watch_data.sleep_data.total_sleep_minutes if watch_data.sleep_data else None
                    sleep_score = watch_data.sleep_data.sleep_score if watch_data.sleep_data else None
                    
                    saved_data = await repository.save_watch_data(
                        session=session,
                        user_id=user_id,
                        device_id=watch_data.device_id,
                        device_type=watch_data.device_type.value if watch_data.device_type else None,
                        heart_rate=watch_data.heart_rate,
                        heart_rate_variability=watch_data.heart_rate_variability,
                        resting_heart_rate=watch_data.resting_heart_rate,
                        blood_oxygen=watch_data.blood_oxygen,
                        respiratory_rate=watch_data.respiratory_rate,
                        body_temperature=watch_data.body_temperature,
                        stress_level=watch_data.stress_level,
                        energy_level=watch_data.energy_level,
                        steps=steps,
                        distance_meters=distance,
                        calories_burned=calories,
                        active_minutes=active_mins,
                        sleep_minutes=sleep_mins,
                        sleep_score=sleep_score,
                        sleep_data=sleep_data_dict,
                        latitude=watch_data.latitude,
                        longitude=watch_data.longitude,
                        raw_data=watch_data.raw_data,
                        recorded_at=recorded_at
                    )
                    
                    today = recorded_at.strftime("%Y-%m-%d")
                    daily_summary = await repository.update_daily_summary_from_watch(
                        session=session, user_id=user_id, summary_date=today
                    )
                    
                    user_state = await repository.update_user_state(
                        session=session, user_id=user_id,
                        watch_data=saved_data, daily_summary=daily_summary
                    )
                    
                    kafka_producer.publish_watch_data_received(
                        user_id=user_id,
                        heart_rate=watch_data.heart_rate,
                        heart_rate_variability=watch_data.heart_rate_variability,
                        blood_oxygen=watch_data.blood_oxygen,
                        stress_level=watch_data.stress_level,
                        steps=steps,
                        calories=calories,
                        sleep_minutes=sleep_mins,
                        sleep_score=sleep_score,
                        health_score=daily_summary.health_score,
                        device_id=watch_data.device_id,
                        device_type=watch_data.device_type.value if watch_data.device_type else None,
                        timestamp=recorded_at
                    )
                    
                    await websocket.send_json({
                        "status": "ok",
                        "data_id": saved_data.id,
                        "health_score": daily_summary.health_score,
                        "today_steps": daily_summary.total_steps,
                        "today_calories": daily_summary.total_calories
                    })
                    
            except Exception as e:
                logger.error("Error processing watch data", error=str(e), exc_info=True)
                await websocket.send_json({"status": "error", "message": str(e)})
                
    except WebSocketDisconnect:
        manager.disconnect(websocket, user_id)
        
        db = app_state.get("db")
        repository = app_state.get("repository")
        if db and repository:
            async for session in db.get_session():
                state = await repository.get_or_create_user_state(session, user_id)
                state.is_connected = False
                await session.commit()


@router.post("/watch/data", response_model=WatchDataResponse)
async def receive_watch_data(data: WatchDataRequest):
    try:
        db = app_state.get("db")
        repository = app_state.get("repository")
        kafka_producer = app_state.get("kafka_producer")
        
        if not db or not repository or not kafka_producer:
            raise HTTPException(status_code=503, detail="Service not ready")
        
        recorded_at = data.recorded_at or datetime.utcnow()
        
        async for session in db.get_session():
            sleep_data_dict = data.sleep_data.model_dump() if data.sleep_data else None
            
            steps = data.activity.steps if data.activity else None
            distance = data.activity.distance_meters if data.activity else None
            calories = data.activity.calories_burned if data.activity else None
            active_mins = data.activity.active_minutes if data.activity else None
            sleep_mins = data.sleep_data.total_sleep_minutes if data.sleep_data else None
            sleep_score = data.sleep_data.sleep_score if data.sleep_data else None
            
            saved_data = await repository.save_watch_data(
                session=session,
                user_id=data.user_id,
                device_id=data.device_id,
                device_type=data.device_type.value if data.device_type else None,
                heart_rate=data.heart_rate,
                heart_rate_variability=data.heart_rate_variability,
                resting_heart_rate=data.resting_heart_rate,
                blood_oxygen=data.blood_oxygen,
                respiratory_rate=data.respiratory_rate,
                body_temperature=data.body_temperature,
                stress_level=data.stress_level,
                energy_level=data.energy_level,
                steps=steps,
                distance_meters=distance,
                calories_burned=calories,
                active_minutes=active_mins,
                sleep_minutes=sleep_mins,
                sleep_score=sleep_score,
                sleep_data=sleep_data_dict,
                latitude=data.latitude,
                longitude=data.longitude,
                raw_data=data.raw_data,
                recorded_at=recorded_at
            )
            
            today = recorded_at.strftime("%Y-%m-%d")
            daily_summary = await repository.update_daily_summary_from_watch(
                session=session, user_id=data.user_id, summary_date=today
            )
            
            user_state = await repository.update_user_state(
                session=session, user_id=data.user_id,
                watch_data=saved_data, daily_summary=daily_summary
            )
            
            kafka_producer.publish_watch_data_received(
                user_id=data.user_id,
                heart_rate=data.heart_rate,
                heart_rate_variability=data.heart_rate_variability,
                blood_oxygen=data.blood_oxygen,
                stress_level=data.stress_level,
                steps=steps,
                calories=calories,
                sleep_minutes=sleep_mins,
                sleep_score=sleep_score,
                health_score=daily_summary.health_score,
                device_id=data.device_id,
                device_type=data.device_type.value if data.device_type else None,
                timestamp=recorded_at
            )
            
            logger.info("Watch data received", user_id=data.user_id, device_id=data.device_id)
            
            return WatchDataResponse(
                id=saved_data.id,
                user_id=saved_data.user_id,
                device_id=saved_data.device_id,
                device_type=saved_data.device_type,
                heart_rate=saved_data.heart_rate,
                heart_rate_variability=saved_data.heart_rate_variability,
                blood_oxygen=saved_data.blood_oxygen,
                stress_level=saved_data.stress_level,
                steps=saved_data.steps,
                calories=saved_data.calories_burned,
                recorded_at=saved_data.recorded_at,
                created_at=saved_data.created_at
            )
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Error receiving watch data", error=str(e), exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/profile/{user_id}", response_model=UserBiometricProfile)
async def get_user_biometric_profile(user_id: str):
    try:
        db = app_state.get("db")
        repository = app_state.get("repository")
        
        if not db or not repository:
            raise HTTPException(status_code=503, detail="Service not ready")
        
        async for session in db.get_session():
            state = await repository.get_user_biometric_profile(session, user_id)
            
            if not state:
                return UserBiometricProfile(user_id=user_id)
            
            return UserBiometricProfile(
                user_id=state.user_id,
                current_heart_rate=state.current_heart_rate,
                resting_heart_rate=state.resting_heart_rate,
                avg_hrv=state.avg_hrv_7d,
                avg_blood_oxygen=state.avg_blood_oxygen_7d,
                avg_stress_level=state.avg_stress_level_7d,
                today_steps=state.today_steps,
                today_calories=state.today_calories,
                last_sleep_score=state.last_sleep_score,
                last_sleep_duration_hours=state.last_sleep_duration_minutes / 60 if state.last_sleep_duration_minutes else None,
                health_score=state.health_score,
                last_sync=state.last_sync,
                device_type=state.device_type,
                trends=state.trends
            )
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Error getting user biometric profile", error=str(e), exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/summary/{user_id}", response_model=List[BiometricSummaryResponse])
async def get_user_summaries(
    user_id: str,
    days: int = Query(7, ge=1, le=90)
):
    try:
        db = app_state.get("db")
        repository = app_state.get("repository")
        
        if not db or not repository:
            raise HTTPException(status_code=503, detail="Service not ready")
        
        async for session in db.get_session():
            summaries = await repository.get_summaries_for_period(
                session=session, user_id=user_id, days=days
            )
            
            return [
                BiometricSummaryResponse(
                    user_id=s.user_id,
                    date=s.date,
                    avg_heart_rate=s.avg_heart_rate,
                    avg_hrv=s.avg_hrv,
                    avg_blood_oxygen=s.avg_blood_oxygen,
                    avg_stress_level=s.avg_stress_level,
                    total_steps=s.total_steps,
                    total_calories=s.total_calories,
                    total_sleep_minutes=s.total_sleep_minutes,
                    sleep_score=s.sleep_score,
                    data_points=s.data_points,
                    last_updated=s.updated_at
                )
                for s in summaries
            ]
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Error getting user summaries", error=str(e), exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/summary/{user_id}/today", response_model=BiometricSummaryResponse)
async def get_today_summary(user_id: str):
    try:
        db = app_state.get("db")
        repository = app_state.get("repository")
        
        if not db or not repository:
            raise HTTPException(status_code=503, detail="Service not ready")
        
        today = datetime.utcnow().strftime("%Y-%m-%d")
        
        async for session in db.get_session():
            summary = await repository.get_or_create_daily_summary(session, user_id, today)
            
            return BiometricSummaryResponse(
                user_id=summary.user_id,
                date=summary.date,
                avg_heart_rate=summary.avg_heart_rate,
                avg_hrv=summary.avg_hrv,
                avg_blood_oxygen=summary.avg_blood_oxygen,
                avg_stress_level=summary.avg_stress_level,
                total_steps=summary.total_steps,
                total_calories=summary.total_calories,
                total_sleep_minutes=summary.total_sleep_minutes,
                sleep_score=summary.sleep_score,
                data_points=summary.data_points,
                last_updated=summary.updated_at
            )
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Error getting today summary", error=str(e), exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/data", response_model=BiometricDataResponse)
async def receive_biometric_data(data: BiometricDataRequest):
    try:
        db = app_state.get("db")
        repository = app_state.get("repository")
        kafka_producer = app_state.get("kafka_producer")
        
        if not db or not repository or not kafka_producer:
            raise HTTPException(status_code=503, detail="Service not ready")
        
        recorded_at = data.recorded_at or datetime.utcnow()
        
        async for session in db.get_session():
            biometric = await repository.save_biometric_data(
                session=session,
                user_id=data.user_id,
                device_id=data.device_id,
                heart_rate=data.heart_rate,
                sleep_data=data.sleep_data,
                activity=data.activity,
                recorded_at=recorded_at
            )
            
            kafka_producer.publish_biometric_data_received(
                user_id=data.user_id,
                heart_rate=data.heart_rate,
                sleep_data=data.sleep_data,
                activity=data.activity,
                device_id=data.device_id,
                timestamp=recorded_at
            )
            
            logger.info("Biometric data received", user_id=data.user_id, device_id=data.device_id)
            
            return BiometricDataResponse(
                id=biometric.id,
                user_id=biometric.user_id,
                device_id=biometric.device_id,
                heart_rate=biometric.heart_rate,
                sleep_data=biometric.sleep_data,
                activity=biometric.activity,
                recorded_at=biometric.recorded_at,
                created_at=biometric.created_at
            )
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Error receiving biometric data", error=str(e), exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/data/{user_id}", response_model=List[BiometricDataResponse])
async def get_biometric_data(
    user_id: str,
    start_date: Optional[datetime] = Query(None),
    end_date: Optional[datetime] = Query(None),
    limit: int = Query(100, ge=1, le=1000)
):
    try:
        db = app_state.get("db")
        repository = app_state.get("repository")
        
        if not db or not repository:
            raise HTTPException(status_code=503, detail="Service not ready")
        
        async for session in db.get_session():
            biometrics = await repository.get_biometric_data_by_user(
                session=session,
                user_id=user_id,
                start_date=start_date,
                end_date=end_date,
                limit=limit
            )
            
            return [
                BiometricDataResponse(
                    id=b.id,
                    user_id=b.user_id,
                    device_id=b.device_id,
                    heart_rate=b.heart_rate,
                    sleep_data=b.sleep_data,
                    activity=b.activity,
                    recorded_at=b.recorded_at,
                    created_at=b.created_at
                )
                for b in biometrics
            ]
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Error getting biometric data", error=str(e), exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/emotional-state/{user_id}/current")
async def get_current_emotional_state(user_id: str):
    try:
        db = app_state.get("db")
        repository = app_state.get("repository")
        emotional_analyzer = app_state.get("emotional_analyzer")
        
        if not db or not repository:
            raise HTTPException(status_code=503, detail="Service not ready")
        
        async for session in db.get_session():
            latest = await repository.get_latest_watch_data(session, user_id)
            
            if not latest:
                return {
                    "user_id": user_id,
                    "state": "unknown",
                    "confidence": 0,
                    "message": "No biometric data available"
                }
            
            state, confidence, factors = emotional_analyzer.analyze_current_state(
                heart_rate=latest.heart_rate,
                hrv=latest.heart_rate_variability,
                stress_level=latest.stress_level,
                blood_oxygen=latest.blood_oxygen,
                activity_level=latest.energy_level,
                sleep_quality=latest.sleep_score
            )
            
            return {
                "user_id": user_id,
                "state": state.value,
                "confidence": confidence,
                "factors": factors,
                "timestamp": latest.recorded_at.isoformat(),
                "metrics": {
                    "heart_rate": latest.heart_rate,
                    "hrv": latest.heart_rate_variability,
                    "stress_level": latest.stress_level,
                    "blood_oxygen": latest.blood_oxygen
                }
            }
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Error getting emotional state", error=str(e), exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/emotional-state/{user_id}/day/{date}")
async def get_day_emotional_summary(user_id: str, date: str):
    try:
        db = app_state.get("db")
        repository = app_state.get("repository")
        emotional_analyzer = app_state.get("emotional_analyzer")
        
        if not db or not repository:
            raise HTTPException(status_code=503, detail="Service not ready")
        
        try:
            target_date = datetime.strptime(date, "%Y-%m-%d")
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid date format. Use YYYY-MM-DD")
        
        start_date = target_date
        end_date = target_date.replace(hour=23, minute=59, second=59)
        
        async for session in db.get_session():
            watch_data = await repository.get_watch_data_by_user(
                session=session,
                user_id=user_id,
                start_date=start_date,
                end_date=end_date,
                limit=1000
            )
            
            biometric_data = [
                {
                    "timestamp": w.recorded_at,
                    "heart_rate": w.heart_rate,
                    "heart_rate_variability": w.heart_rate_variability,
                    "stress_level": w.stress_level,
                    "blood_oxygen": w.blood_oxygen,
                    "energy_level": w.energy_level,
                    "sleep_score": w.sleep_score,
                    "latitude": w.latitude,
                    "longitude": w.longitude,
                    "activity": {
                        "steps": w.steps,
                        "calories_burned": w.calories_burned,
                        "distance_meters": w.distance_meters,
                        "active_minutes": w.active_minutes
                    } if w.steps else None
                }
                for w in watch_data
            ]
            
            summary = emotional_analyzer.analyze_day_emotional_pattern(
                user_id=user_id,
                date=date,
                biometric_data=biometric_data
            )
            
            return {
                "user_id": summary.user_id,
                "date": summary.date,
                "overall_state": summary.overall_state.value,
                "emotional_stability": summary.emotional_stability,
                "stress_periods": summary.stress_periods,
                "calm_periods": summary.calm_periods,
                "energy_curve": summary.energy_curve,
                "activity_emotional_correlation": summary.activity_emotional_correlation,
                "spikes": summary.spikes,
                "location_contexts": summary.location_contexts,
                "insights": summary.insights,
                "recommendations": summary.recommendations
            }
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Error getting day emotional summary", error=str(e), exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/insights/{user_id}/day/{date}")
async def get_day_insights(user_id: str, date: str):
    try:
        db = app_state.get("db")
        repository = app_state.get("repository")
        day_insights_analyzer = app_state.get("day_insights_analyzer")
        
        if not db or not repository:
            raise HTTPException(status_code=503, detail="Service not ready")
        
        try:
            target_date = datetime.strptime(date, "%Y-%m-%d")
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid date format. Use YYYY-MM-DD")
        
        start_date = target_date
        end_date = target_date.replace(hour=23, minute=59, second=59)
        
        async for session in db.get_session():
            watch_data = await repository.get_watch_data_by_user(
                session=session,
                user_id=user_id,
                start_date=start_date,
                end_date=end_date,
                limit=1000
            )
            
            biometric_data = [
                {
                    "timestamp": w.recorded_at,
                    "heart_rate": w.heart_rate,
                    "heart_rate_variability": w.heart_rate_variability,
                    "stress_level": w.stress_level,
                    "blood_oxygen": w.blood_oxygen,
                    "energy_level": w.energy_level,
                    "sleep_score": w.sleep_score,
                    "latitude": w.latitude,
                    "longitude": w.longitude,
                    "activity": {
                        "steps": w.steps,
                        "calories_burned": w.calories_burned,
                        "distance_meters": w.distance_meters,
                        "active_minutes": w.active_minutes
                    } if w.steps else None
                }
                for w in watch_data
            ]
            
            insights = day_insights_analyzer.analyze_day(
                user_id=user_id,
                date=date,
                biometric_data=biometric_data
            )
            
            return {
                "date": insights.date,
                "user_id": insights.user_id,
                "wake_up_time": insights.wake_up_time,
                "sleep_time": insights.sleep_time,
                "total_active_hours": insights.total_active_hours,
                "most_productive_hours": insights.most_productive_hours,
                "most_stressful_hours": insights.most_stressful_hours,
                "location_insights": [
                    {
                        "location_type": l.location_type.value,
                        "time_spent_minutes": l.time_spent_minutes,
                        "emotional_state": l.emotional_state,
                        "avg_stress": l.avg_stress,
                        "avg_heart_rate": l.avg_heart_rate,
                        "activity_level": l.activity_level,
                        "start_time": l.timestamp_start.isoformat(),
                        "end_time": l.timestamp_end.isoformat()
                    }
                    for l in insights.location_insights
                ],
                "activity_insights": [
                    {
                        "activity_type": a.activity_type.value,
                        "duration_minutes": a.duration_minutes,
                        "steps": a.steps,
                        "calories": a.calories,
                        "avg_heart_rate": a.avg_heart_rate,
                        "emotional_impact": a.emotional_impact,
                        "time_of_day": a.time_of_day
                    }
                    for a in insights.activity_insights
                ],
                "movement_patterns": insights.movement_patterns,
                "emotional_journey": insights.emotional_journey,
                "key_moments": insights.key_moments,
                "daily_story": insights.daily_story,
                "health_metrics_summary": insights.health_metrics_summary,
                "comparison_with_average": insights.comparison_with_average
            }
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Error getting day insights", error=str(e), exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/spikes/{user_id}")
async def get_emotional_spikes(
    user_id: str,
    start_date: Optional[datetime] = Query(None),
    end_date: Optional[datetime] = Query(None),
    limit: int = Query(50, ge=1, le=200)
):
    try:
        db = app_state.get("db")
        repository = app_state.get("repository")
        emotional_analyzer = app_state.get("emotional_analyzer")
        
        if not db or not repository:
            raise HTTPException(status_code=503, detail="Service not ready")
        
        if not start_date:
            start_date = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
        if not end_date:
            end_date = datetime.now()
        
        async for session in db.get_session():
            watch_data = await repository.get_watch_data_by_user(
                session=session,
                user_id=user_id,
                start_date=start_date,
                end_date=end_date,
                limit=1000
            )
            
            data_points = [
                {
                    "timestamp": w.recorded_at,
                    "heart_rate": w.heart_rate,
                    "heart_rate_variability": w.heart_rate_variability,
                    "stress_level": w.stress_level,
                    "latitude": w.latitude,
                    "longitude": w.longitude,
                    "activity": {
                        "steps": w.steps
                    } if w.steps else None
                }
                for w in watch_data
            ]
            
            spikes = emotional_analyzer.detect_emotional_spikes(data_points)
            
            return {
                "user_id": user_id,
                "period": {
                    "start": start_date.isoformat(),
                    "end": end_date.isoformat()
                },
                "total_spikes": len(spikes),
                "spikes": [
                    {
                        "timestamp": s.timestamp.isoformat(),
                        "spike_type": s.spike_type,
                        "intensity": s.intensity,
                        "duration_minutes": s.duration_minutes,
                        "trigger_metric": s.trigger_metric,
                        "before_value": s.before_value,
                        "peak_value": s.peak_value,
                        "context": s.context
                    }
                    for s in spikes[:limit]
                ]
            }
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Error getting emotional spikes", error=str(e), exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))

