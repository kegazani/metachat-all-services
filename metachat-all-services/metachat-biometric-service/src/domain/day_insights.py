from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta
from dataclasses import dataclass
from enum import Enum
import structlog

logger = structlog.get_logger()


class LocationType(str, Enum):
    HOME = "home"
    WORK = "work"
    GYM = "gym"
    OUTDOORS = "outdoors"
    TRANSPORT = "transport"
    RESTAURANT = "restaurant"
    SHOPPING = "shopping"
    UNKNOWN = "unknown"


class ActivityContext(str, Enum):
    WORKING = "working"
    EXERCISING = "exercising"
    COMMUTING = "commuting"
    RESTING = "resting"
    SOCIALIZING = "socializing"
    EATING = "eating"
    SLEEPING = "sleeping"
    UNKNOWN = "unknown"


@dataclass
class LocationInsight:
    location_type: LocationType
    time_spent_minutes: int
    emotional_state: str
    avg_stress: Optional[float]
    avg_heart_rate: Optional[float]
    activity_level: str
    timestamp_start: datetime
    timestamp_end: datetime


@dataclass
class ActivityInsight:
    activity_type: ActivityContext
    duration_minutes: int
    steps: Optional[int]
    calories: Optional[float]
    avg_heart_rate: Optional[float]
    emotional_impact: str
    time_of_day: str


@dataclass
class DayInsights:
    date: str
    user_id: str
    
    wake_up_time: Optional[str]
    sleep_time: Optional[str]
    total_active_hours: float
    
    most_productive_hours: List[int]
    most_stressful_hours: List[int]
    
    location_insights: List[LocationInsight]
    activity_insights: List[ActivityInsight]
    
    movement_patterns: Dict[str, Any]
    emotional_journey: List[Dict[str, Any]]
    
    key_moments: List[Dict[str, Any]]
    daily_story: str
    
    health_metrics_summary: Dict[str, Any]
    comparison_with_average: Dict[str, Any]


class DayInsightsAnalyzer:
    
    def __init__(self):
        self.home_hours = list(range(0, 7)) + list(range(20, 24))
        self.work_hours = list(range(9, 18))
    
    def analyze_day(
        self,
        user_id: str,
        date: str,
        biometric_data: List[Dict[str, Any]],
        historical_averages: Optional[Dict[str, Any]] = None
    ) -> DayInsights:
        
        if not biometric_data:
            return self._empty_insights(user_id, date)
        
        sorted_data = sorted(biometric_data, key=lambda x: x.get('timestamp') or x.get('recorded_at', ''))
        
        wake_up_time, sleep_time = self._detect_wake_sleep_times(sorted_data)
        total_active_hours = self._calculate_active_hours(sorted_data)
        
        productive_hours, stressful_hours = self._find_peak_hours(sorted_data)
        
        location_insights = self._analyze_locations(sorted_data)
        activity_insights = self._analyze_activities(sorted_data)
        
        movement_patterns = self._analyze_movement_patterns(sorted_data)
        emotional_journey = self._build_emotional_journey(sorted_data)
        
        key_moments = self._identify_key_moments(sorted_data)
        
        daily_story = self._generate_daily_story(
            wake_up_time, sleep_time, location_insights, 
            activity_insights, key_moments, emotional_journey
        )
        
        health_metrics = self._summarize_health_metrics(sorted_data)
        comparison = self._compare_with_average(health_metrics, historical_averages)
        
        return DayInsights(
            date=date,
            user_id=user_id,
            wake_up_time=wake_up_time,
            sleep_time=sleep_time,
            total_active_hours=total_active_hours,
            most_productive_hours=productive_hours,
            most_stressful_hours=stressful_hours,
            location_insights=location_insights,
            activity_insights=activity_insights,
            movement_patterns=movement_patterns,
            emotional_journey=emotional_journey,
            key_moments=key_moments,
            daily_story=daily_story,
            health_metrics_summary=health_metrics,
            comparison_with_average=comparison
        )
    
    def _detect_wake_sleep_times(self, data: List[Dict[str, Any]]) -> tuple:
        if not data:
            return None, None
        
        first_activity = None
        last_activity = None
        
        for dp in data:
            activity = dp.get('activity', {})
            if isinstance(activity, dict):
                steps = activity.get('steps', 0)
                if steps and steps > 0:
                    ts = dp.get('timestamp') or dp.get('recorded_at')
                    if isinstance(ts, str):
                        ts = datetime.fromisoformat(ts.replace('Z', '+00:00'))
                    if first_activity is None:
                        first_activity = ts
                    last_activity = ts
        
        wake_time = first_activity.strftime("%H:%M") if first_activity else None
        sleep_time = last_activity.strftime("%H:%M") if last_activity else None
        
        return wake_time, sleep_time
    
    def _calculate_active_hours(self, data: List[Dict[str, Any]]) -> float:
        active_hours = set()
        
        for dp in data:
            ts = dp.get('timestamp') or dp.get('recorded_at')
            if isinstance(ts, str):
                ts = datetime.fromisoformat(ts.replace('Z', '+00:00'))
            
            activity = dp.get('activity', {})
            hr = dp.get('heart_rate')
            
            is_active = False
            if isinstance(activity, dict) and activity.get('steps', 0) > 50:
                is_active = True
            if hr and hr > 80:
                is_active = True
            
            if is_active and ts:
                active_hours.add(ts.hour)
        
        return len(active_hours)
    
    def _find_peak_hours(self, data: List[Dict[str, Any]]) -> tuple:
        hourly_productivity = {}
        hourly_stress = {}
        
        for dp in data:
            ts = dp.get('timestamp') or dp.get('recorded_at')
            if isinstance(ts, str):
                ts = datetime.fromisoformat(ts.replace('Z', '+00:00'))
            
            hour = ts.hour if ts else None
            if hour is None:
                continue
            
            activity = dp.get('activity', {})
            stress = dp.get('stress_level')
            energy = dp.get('energy_level')
            
            productivity_score = 0
            if isinstance(activity, dict):
                steps = activity.get('steps', 0)
                if steps:
                    productivity_score = min(steps / 500, 1.0)
            if energy:
                productivity_score = (productivity_score + energy / 100) / 2
            
            if hour not in hourly_productivity:
                hourly_productivity[hour] = []
            hourly_productivity[hour].append(productivity_score)
            
            if stress is not None:
                if hour not in hourly_stress:
                    hourly_stress[hour] = []
                hourly_stress[hour].append(stress)
        
        avg_productivity = {h: sum(v)/len(v) for h, v in hourly_productivity.items() if v}
        avg_stress = {h: sum(v)/len(v) for h, v in hourly_stress.items() if v}
        
        productive_hours = sorted(avg_productivity, key=avg_productivity.get, reverse=True)[:3]
        stressful_hours = sorted(avg_stress, key=avg_stress.get, reverse=True)[:3]
        
        return productive_hours, stressful_hours
    
    def _analyze_locations(self, data: List[Dict[str, Any]]) -> List[LocationInsight]:
        insights = []
        current_location = None
        location_start = None
        location_data = []
        
        for dp in data:
            lat = dp.get('latitude')
            lon = dp.get('longitude')
            ts = dp.get('timestamp') or dp.get('recorded_at')
            
            if isinstance(ts, str):
                ts = datetime.fromisoformat(ts.replace('Z', '+00:00'))
            
            hour = ts.hour if ts else 12
            
            if lat is not None and lon is not None:
                location_type = self._classify_location(lat, lon, hour)
            else:
                location_type = self._infer_location_from_time(hour)
            
            if current_location is None:
                current_location = location_type
                location_start = ts
                location_data = [dp]
            elif location_type != current_location:
                if location_start and ts and location_data:
                    insight = self._create_location_insight(
                        current_location, location_start, ts, location_data
                    )
                    insights.append(insight)
                
                current_location = location_type
                location_start = ts
                location_data = [dp]
            else:
                location_data.append(dp)
        
        if current_location and location_start and location_data:
            last_ts = location_data[-1].get('timestamp') or location_data[-1].get('recorded_at')
            if isinstance(last_ts, str):
                last_ts = datetime.fromisoformat(last_ts.replace('Z', '+00:00'))
            insight = self._create_location_insight(
                current_location, location_start, last_ts, location_data
            )
            insights.append(insight)
        
        return insights
    
    def _classify_location(self, lat: float, lon: float, hour: int) -> LocationType:
        if hour in self.home_hours:
            return LocationType.HOME
        elif hour in self.work_hours:
            return LocationType.WORK
        else:
            return LocationType.UNKNOWN
    
    def _infer_location_from_time(self, hour: int) -> LocationType:
        if hour in self.home_hours:
            return LocationType.HOME
        elif hour in self.work_hours:
            return LocationType.WORK
        elif hour in [7, 8, 18, 19]:
            return LocationType.TRANSPORT
        else:
            return LocationType.UNKNOWN
    
    def _create_location_insight(
        self, loc_type: LocationType, start: datetime, end: datetime, data: List[Dict]
    ) -> LocationInsight:
        stress_vals = [d.get('stress_level') for d in data if d.get('stress_level') is not None]
        hr_vals = [d.get('heart_rate') for d in data if d.get('heart_rate') is not None]
        
        emotional_state = "neutral"
        if stress_vals:
            avg_stress = sum(stress_vals) / len(stress_vals)
            if avg_stress > 60:
                emotional_state = "stressed"
            elif avg_stress < 30:
                emotional_state = "relaxed"
        
        activity_level = "low"
        total_steps = sum([
            d.get('activity', {}).get('steps', 0) 
            for d in data if isinstance(d.get('activity'), dict)
        ])
        if total_steps > 1000:
            activity_level = "high"
        elif total_steps > 300:
            activity_level = "moderate"
        
        return LocationInsight(
            location_type=loc_type,
            time_spent_minutes=int((end - start).total_seconds() / 60),
            emotional_state=emotional_state,
            avg_stress=sum(stress_vals)/len(stress_vals) if stress_vals else None,
            avg_heart_rate=sum(hr_vals)/len(hr_vals) if hr_vals else None,
            activity_level=activity_level,
            timestamp_start=start,
            timestamp_end=end
        )
    
    def _analyze_activities(self, data: List[Dict[str, Any]]) -> List[ActivityInsight]:
        insights = []
        
        hourly_data = {}
        for dp in data:
            ts = dp.get('timestamp') or dp.get('recorded_at')
            if isinstance(ts, str):
                ts = datetime.fromisoformat(ts.replace('Z', '+00:00'))
            
            if ts:
                hour = ts.hour
                if hour not in hourly_data:
                    hourly_data[hour] = []
                hourly_data[hour].append(dp)
        
        for hour, hour_data in sorted(hourly_data.items()):
            activity_type = self._classify_activity(hour_data, hour)
            
            total_steps = sum([
                d.get('activity', {}).get('steps', 0)
                for d in hour_data if isinstance(d.get('activity'), dict)
            ])
            total_calories = sum([
                d.get('activity', {}).get('calories_burned', 0)
                for d in hour_data if isinstance(d.get('activity'), dict)
            ])
            hr_vals = [d.get('heart_rate') for d in hour_data if d.get('heart_rate')]
            stress_vals = [d.get('stress_level') for d in hour_data if d.get('stress_level')]
            
            emotional_impact = "neutral"
            if stress_vals:
                avg_stress = sum(stress_vals) / len(stress_vals)
                if avg_stress > 60:
                    emotional_impact = "stressful"
                elif avg_stress < 30:
                    emotional_impact = "calming"
            
            time_of_day = "morning" if hour < 12 else ("afternoon" if hour < 18 else "evening")
            
            insights.append(ActivityInsight(
                activity_type=activity_type,
                duration_minutes=len(hour_data) * 5,
                steps=total_steps if total_steps > 0 else None,
                calories=total_calories if total_calories > 0 else None,
                avg_heart_rate=sum(hr_vals)/len(hr_vals) if hr_vals else None,
                emotional_impact=emotional_impact,
                time_of_day=time_of_day
            ))
        
        return insights
    
    def _classify_activity(self, data: List[Dict], hour: int) -> ActivityContext:
        total_steps = sum([
            d.get('activity', {}).get('steps', 0)
            for d in data if isinstance(d.get('activity'), dict)
        ])
        avg_hr = sum([d.get('heart_rate', 0) for d in data if d.get('heart_rate')]) / max(len(data), 1)
        
        if hour in [7, 8, 18, 19] and total_steps > 200:
            return ActivityContext.COMMUTING
        elif total_steps > 500 and avg_hr > 100:
            return ActivityContext.EXERCISING
        elif hour in self.work_hours and avg_hr < 90:
            return ActivityContext.WORKING
        elif total_steps < 50 and avg_hr < 70:
            return ActivityContext.RESTING
        elif hour in [12, 13, 19, 20]:
            return ActivityContext.EATING
        else:
            return ActivityContext.UNKNOWN
    
    def _analyze_movement_patterns(self, data: List[Dict[str, Any]]) -> Dict[str, Any]:
        hourly_steps = {}
        for dp in data:
            ts = dp.get('timestamp') or dp.get('recorded_at')
            if isinstance(ts, str):
                ts = datetime.fromisoformat(ts.replace('Z', '+00:00'))
            
            activity = dp.get('activity', {})
            if isinstance(activity, dict) and ts:
                steps = activity.get('steps', 0)
                hour = ts.hour
                if hour not in hourly_steps:
                    hourly_steps[hour] = 0
                hourly_steps[hour] = max(hourly_steps[hour], steps)
        
        total_steps = sum(hourly_steps.values())
        peak_hour = max(hourly_steps, key=hourly_steps.get) if hourly_steps else None
        
        return {
            "total_steps": total_steps,
            "peak_movement_hour": peak_hour,
            "hourly_distribution": hourly_steps,
            "movement_consistency": len([v for v in hourly_steps.values() if v > 100]) / max(len(hourly_steps), 1)
        }
    
    def _build_emotional_journey(self, data: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        journey = []
        
        for dp in data:
            ts = dp.get('timestamp') or dp.get('recorded_at')
            if isinstance(ts, str):
                ts = datetime.fromisoformat(ts.replace('Z', '+00:00'))
            
            stress = dp.get('stress_level')
            hr = dp.get('heart_rate')
            hrv = dp.get('heart_rate_variability')
            
            if ts and (stress is not None or hr is not None):
                emotional_state = "neutral"
                if stress is not None:
                    if stress > 70:
                        emotional_state = "stressed"
                    elif stress > 40:
                        emotional_state = "focused"
                    else:
                        emotional_state = "relaxed"
                
                journey.append({
                    "timestamp": ts.isoformat(),
                    "hour": ts.hour,
                    "emotional_state": emotional_state,
                    "stress_level": stress,
                    "heart_rate": hr,
                    "hrv": hrv
                })
        
        return journey
    
    def _identify_key_moments(self, data: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        moments = []
        
        hr_vals = [(d.get('heart_rate'), d) for d in data if d.get('heart_rate')]
        if hr_vals:
            max_hr_data = max(hr_vals, key=lambda x: x[0])
            ts = max_hr_data[1].get('timestamp') or max_hr_data[1].get('recorded_at')
            moments.append({
                "type": "peak_heart_rate",
                "timestamp": ts,
                "value": max_hr_data[0],
                "description": f"Пик пульса: {max_hr_data[0]} уд/мин"
            })
        
        stress_vals = [(d.get('stress_level'), d) for d in data if d.get('stress_level')]
        if stress_vals:
            max_stress_data = max(stress_vals, key=lambda x: x[0])
            if max_stress_data[0] > 70:
                ts = max_stress_data[1].get('timestamp') or max_stress_data[1].get('recorded_at')
                moments.append({
                    "type": "high_stress",
                    "timestamp": ts,
                    "value": max_stress_data[0],
                    "description": f"Высокий уровень стресса: {max_stress_data[0]}%"
                })
        
        activity_vals = [
            (d.get('activity', {}).get('steps', 0), d) 
            for d in data if isinstance(d.get('activity'), dict)
        ]
        if activity_vals:
            max_activity = max(activity_vals, key=lambda x: x[0])
            if max_activity[0] > 1000:
                ts = max_activity[1].get('timestamp') or max_activity[1].get('recorded_at')
                moments.append({
                    "type": "peak_activity",
                    "timestamp": ts,
                    "value": max_activity[0],
                    "description": f"Максимальная активность: {max_activity[0]} шагов"
                })
        
        return moments
    
    def _generate_daily_story(
        self, wake_up: Optional[str], sleep_time: Optional[str],
        locations: List[LocationInsight], activities: List[ActivityInsight],
        key_moments: List[Dict], emotional_journey: List[Dict]
    ) -> str:
        parts = []
        
        if wake_up:
            parts.append(f"Ваш день начался в {wake_up}.")
        
        work_time = sum([l.time_spent_minutes for l in locations if l.location_type == LocationType.WORK])
        if work_time > 60:
            parts.append(f"На работе вы провели {work_time // 60} часов.")
        
        exercise = [a for a in activities if a.activity_type == ActivityContext.EXERCISING]
        if exercise:
            total_exercise = sum([a.duration_minutes for a in exercise])
            parts.append(f"Физической активности было {total_exercise} минут.")
        
        stressed_hours = [e for e in emotional_journey if e.get('emotional_state') == 'stressed']
        if len(stressed_hours) > 3:
            parts.append("В течение дня были периоды повышенного стресса.")
        else:
            relaxed = [e for e in emotional_journey if e.get('emotional_state') == 'relaxed']
            if len(relaxed) > len(emotional_journey) / 2:
                parts.append("День прошел достаточно спокойно.")
        
        if sleep_time:
            parts.append(f"Активность завершилась около {sleep_time}.")
        
        return " ".join(parts) if parts else "Недостаточно данных для формирования истории дня."
    
    def _summarize_health_metrics(self, data: List[Dict[str, Any]]) -> Dict[str, Any]:
        hr_vals = [d.get('heart_rate') for d in data if d.get('heart_rate')]
        stress_vals = [d.get('stress_level') for d in data if d.get('stress_level')]
        spo2_vals = [d.get('blood_oxygen') for d in data if d.get('blood_oxygen')]
        
        total_steps = 0
        total_calories = 0
        for d in data:
            activity = d.get('activity', {})
            if isinstance(activity, dict):
                total_steps = max(total_steps, activity.get('steps', 0))
                total_calories = max(total_calories, activity.get('calories_burned', 0))
        
        return {
            "avg_heart_rate": sum(hr_vals) / len(hr_vals) if hr_vals else None,
            "min_heart_rate": min(hr_vals) if hr_vals else None,
            "max_heart_rate": max(hr_vals) if hr_vals else None,
            "avg_stress": sum(stress_vals) / len(stress_vals) if stress_vals else None,
            "max_stress": max(stress_vals) if stress_vals else None,
            "avg_spo2": sum(spo2_vals) / len(spo2_vals) if spo2_vals else None,
            "total_steps": total_steps,
            "total_calories": total_calories,
            "data_points": len(data)
        }
    
    def _compare_with_average(
        self, today: Dict[str, Any], historical: Optional[Dict[str, Any]]
    ) -> Dict[str, Any]:
        if not historical:
            return {"status": "no_historical_data"}
        
        comparison = {}
        for key in ['avg_heart_rate', 'avg_stress', 'total_steps', 'total_calories']:
            if today.get(key) and historical.get(key):
                diff = ((today[key] - historical[key]) / historical[key]) * 100
                comparison[key] = {
                    "today": today[key],
                    "average": historical[key],
                    "diff_percent": round(diff, 1),
                    "trend": "up" if diff > 5 else ("down" if diff < -5 else "stable")
                }
        
        return comparison
    
    def _empty_insights(self, user_id: str, date: str) -> DayInsights:
        return DayInsights(
            date=date,
            user_id=user_id,
            wake_up_time=None,
            sleep_time=None,
            total_active_hours=0,
            most_productive_hours=[],
            most_stressful_hours=[],
            location_insights=[],
            activity_insights=[],
            movement_patterns={},
            emotional_journey=[],
            key_moments=[],
            daily_story="Данные за этот день отсутствуют.",
            health_metrics_summary={},
            comparison_with_average={}
        )

