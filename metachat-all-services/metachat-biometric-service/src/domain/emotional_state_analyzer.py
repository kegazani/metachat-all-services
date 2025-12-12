from typing import List, Dict, Any, Optional, Tuple
from datetime import datetime, timedelta
from dataclasses import dataclass
from enum import Enum
import numpy as np
import structlog

logger = structlog.get_logger()


class EmotionalState(str, Enum):
    CALM = "calm"
    RELAXED = "relaxed"
    ENERGIZED = "energized"
    STRESSED = "stressed"
    ANXIOUS = "anxious"
    EXCITED = "excited"
    TIRED = "tired"
    FOCUSED = "focused"
    AGITATED = "agitated"


class ActivityType(str, Enum):
    SEDENTARY = "sedentary"
    LIGHT_ACTIVITY = "light_activity"
    MODERATE_ACTIVITY = "moderate_activity"
    VIGOROUS_ACTIVITY = "vigorous_activity"
    SLEEP = "sleep"
    COMMUTING = "commuting"
    WORKING = "working"


@dataclass
class EmotionalSpike:
    timestamp: datetime
    spike_type: str
    intensity: float
    duration_minutes: int
    trigger_metric: str
    before_value: float
    peak_value: float
    context: Optional[Dict[str, Any]] = None


@dataclass
class DayEmotionalSummary:
    date: str
    user_id: str
    overall_state: EmotionalState
    emotional_stability: float
    stress_periods: List[Dict[str, Any]]
    calm_periods: List[Dict[str, Any]]
    energy_curve: List[Dict[str, Any]]
    activity_emotional_correlation: Dict[str, float]
    spikes: List[EmotionalSpike]
    location_contexts: List[Dict[str, Any]]
    insights: List[str]
    recommendations: List[str]


class EmotionalStateAnalyzer:
    
    HR_CALM_RANGE = (50, 75)
    HR_MODERATE_RANGE = (76, 100)
    HR_ELEVATED_RANGE = (101, 120)
    
    HRV_LOW_THRESHOLD = 30
    HRV_NORMAL_THRESHOLD = 50
    HRV_HIGH_THRESHOLD = 80
    
    STRESS_HIGH_THRESHOLD = 70
    STRESS_MODERATE_THRESHOLD = 40
    
    SPIKE_THRESHOLD_PERCENT = 20
    
    def __init__(self):
        pass
    
    def analyze_current_state(
        self,
        heart_rate: Optional[float],
        hrv: Optional[float],
        stress_level: Optional[int],
        blood_oxygen: Optional[float],
        activity_level: Optional[int],
        sleep_quality: Optional[int]
    ) -> Tuple[EmotionalState, float, Dict[str, Any]]:
        
        factors = {}
        state_scores = {state: 0.0 for state in EmotionalState}
        
        if heart_rate is not None:
            if heart_rate < self.HR_CALM_RANGE[1]:
                state_scores[EmotionalState.CALM] += 0.3
                state_scores[EmotionalState.RELAXED] += 0.2
            elif heart_rate < self.HR_MODERATE_RANGE[1]:
                state_scores[EmotionalState.FOCUSED] += 0.2
                state_scores[EmotionalState.ENERGIZED] += 0.2
            elif heart_rate < self.HR_ELEVATED_RANGE[1]:
                state_scores[EmotionalState.EXCITED] += 0.2
                state_scores[EmotionalState.STRESSED] += 0.2
            else:
                state_scores[EmotionalState.AGITATED] += 0.3
                state_scores[EmotionalState.ANXIOUS] += 0.2
            factors['heart_rate_factor'] = heart_rate
        
        if hrv is not None:
            if hrv > self.HRV_HIGH_THRESHOLD:
                state_scores[EmotionalState.RELAXED] += 0.3
                state_scores[EmotionalState.CALM] += 0.2
            elif hrv > self.HRV_NORMAL_THRESHOLD:
                state_scores[EmotionalState.FOCUSED] += 0.2
            elif hrv > self.HRV_LOW_THRESHOLD:
                state_scores[EmotionalState.STRESSED] += 0.2
            else:
                state_scores[EmotionalState.STRESSED] += 0.3
                state_scores[EmotionalState.ANXIOUS] += 0.2
            factors['hrv_factor'] = hrv
        
        if stress_level is not None:
            if stress_level >= self.STRESS_HIGH_THRESHOLD:
                state_scores[EmotionalState.STRESSED] += 0.4
                state_scores[EmotionalState.ANXIOUS] += 0.2
            elif stress_level >= self.STRESS_MODERATE_THRESHOLD:
                state_scores[EmotionalState.FOCUSED] += 0.2
            else:
                state_scores[EmotionalState.CALM] += 0.3
                state_scores[EmotionalState.RELAXED] += 0.2
            factors['stress_factor'] = stress_level
        
        if activity_level is not None:
            if activity_level > 70:
                state_scores[EmotionalState.ENERGIZED] += 0.3
                state_scores[EmotionalState.EXCITED] += 0.2
            elif activity_level > 30:
                state_scores[EmotionalState.FOCUSED] += 0.2
            else:
                state_scores[EmotionalState.TIRED] += 0.2
                state_scores[EmotionalState.RELAXED] += 0.2
            factors['activity_factor'] = activity_level
        
        if sleep_quality is not None:
            if sleep_quality < 50:
                state_scores[EmotionalState.TIRED] += 0.3
                state_scores[EmotionalState.STRESSED] += 0.1
            elif sleep_quality > 80:
                state_scores[EmotionalState.ENERGIZED] += 0.2
                state_scores[EmotionalState.FOCUSED] += 0.2
            factors['sleep_factor'] = sleep_quality
        
        total = sum(state_scores.values())
        if total > 0:
            state_scores = {k: v / total for k, v in state_scores.items()}
        
        dominant_state = max(state_scores, key=state_scores.get)
        confidence = state_scores[dominant_state]
        
        return dominant_state, confidence, factors
    
    def detect_emotional_spikes(
        self,
        data_points: List[Dict[str, Any]],
        window_minutes: int = 15
    ) -> List[EmotionalSpike]:
        
        if len(data_points) < 3:
            return []
        
        spikes = []
        
        sorted_data = sorted(data_points, key=lambda x: x.get('timestamp') or x.get('recorded_at'))
        
        metrics_to_check = ['heart_rate', 'stress_level', 'heart_rate_variability']
        
        for metric in metrics_to_check:
            values = []
            timestamps = []
            
            for dp in sorted_data:
                val = dp.get(metric)
                ts = dp.get('timestamp') or dp.get('recorded_at')
                if val is not None and ts is not None:
                    values.append(val)
                    timestamps.append(ts if isinstance(ts, datetime) else datetime.fromisoformat(str(ts).replace('Z', '+00:00')))
            
            if len(values) < 3:
                continue
            
            values_array = np.array(values)
            mean_val = np.mean(values_array)
            std_val = np.std(values_array)
            
            if std_val == 0:
                continue
            
            for i in range(1, len(values) - 1):
                change_percent = abs(values[i] - values[i-1]) / max(values[i-1], 1) * 100
                
                if change_percent >= self.SPIKE_THRESHOLD_PERCENT:
                    z_score = (values[i] - mean_val) / std_val
                    
                    if abs(z_score) > 1.5:
                        spike_type = "increase" if values[i] > values[i-1] else "decrease"
                        
                        duration = 0
                        if i < len(timestamps) - 1:
                            duration = int((timestamps[i+1] - timestamps[i-1]).total_seconds() / 60)
                        
                        spike = EmotionalSpike(
                            timestamp=timestamps[i],
                            spike_type=spike_type,
                            intensity=float(abs(z_score)),
                            duration_minutes=duration,
                            trigger_metric=metric,
                            before_value=float(values[i-1]),
                            peak_value=float(values[i]),
                            context=self._get_spike_context(sorted_data[i])
                        )
                        spikes.append(spike)
        
        return spikes
    
    def _get_spike_context(self, data_point: Dict[str, Any]) -> Dict[str, Any]:
        context = {}
        
        if data_point.get('latitude') and data_point.get('longitude'):
            context['location'] = {
                'latitude': data_point['latitude'],
                'longitude': data_point['longitude']
            }
        
        if data_point.get('activity'):
            activity = data_point['activity']
            if isinstance(activity, dict):
                context['activity_type'] = activity.get('activity_type')
                context['steps'] = activity.get('steps')
        
        return context
    
    def analyze_day_emotional_pattern(
        self,
        user_id: str,
        date: str,
        biometric_data: List[Dict[str, Any]]
    ) -> DayEmotionalSummary:
        
        if not biometric_data:
            return self._empty_summary(user_id, date)
        
        hourly_states = {}
        stress_periods = []
        calm_periods = []
        current_period = None
        current_period_type = None
        
        sorted_data = sorted(biometric_data, key=lambda x: x.get('timestamp') or x.get('recorded_at', ''))
        
        for dp in sorted_data:
            ts = dp.get('timestamp') or dp.get('recorded_at')
            if not ts:
                continue
            
            if isinstance(ts, str):
                ts = datetime.fromisoformat(ts.replace('Z', '+00:00'))
            
            hour = ts.hour
            
            state, confidence, factors = self.analyze_current_state(
                heart_rate=dp.get('heart_rate'),
                hrv=dp.get('heart_rate_variability'),
                stress_level=dp.get('stress_level'),
                blood_oxygen=dp.get('blood_oxygen'),
                activity_level=dp.get('energy_level'),
                sleep_quality=dp.get('sleep_score')
            )
            
            if hour not in hourly_states:
                hourly_states[hour] = []
            hourly_states[hour].append({
                'state': state,
                'confidence': confidence,
                'factors': factors,
                'timestamp': ts
            })
            
            is_stress = state in [EmotionalState.STRESSED, EmotionalState.ANXIOUS, EmotionalState.AGITATED]
            is_calm = state in [EmotionalState.CALM, EmotionalState.RELAXED]
            
            if is_stress:
                if current_period_type != 'stress':
                    if current_period and current_period_type == 'calm':
                        calm_periods.append(current_period)
                    current_period = {'start': ts, 'end': ts, 'peak_stress': dp.get('stress_level', 0)}
                    current_period_type = 'stress'
                else:
                    current_period['end'] = ts
                    current_period['peak_stress'] = max(current_period['peak_stress'], dp.get('stress_level', 0))
            elif is_calm:
                if current_period_type != 'calm':
                    if current_period and current_period_type == 'stress':
                        stress_periods.append(current_period)
                    current_period = {'start': ts, 'end': ts}
                    current_period_type = 'calm'
                else:
                    current_period['end'] = ts
            else:
                if current_period:
                    if current_period_type == 'stress':
                        stress_periods.append(current_period)
                    elif current_period_type == 'calm':
                        calm_periods.append(current_period)
                current_period = None
                current_period_type = None
        
        if current_period:
            if current_period_type == 'stress':
                stress_periods.append(current_period)
            elif current_period_type == 'calm':
                calm_periods.append(current_period)
        
        energy_curve = self._build_energy_curve(hourly_states)
        
        spikes = self.detect_emotional_spikes(biometric_data)
        
        overall_state, stability = self._calculate_overall_state(hourly_states)
        
        activity_correlation = self._calculate_activity_emotional_correlation(biometric_data)
        
        location_contexts = self._extract_location_contexts(biometric_data)
        
        insights, recommendations = self._generate_insights_and_recommendations(
            overall_state, stability, stress_periods, calm_periods, spikes, energy_curve
        )
        
        return DayEmotionalSummary(
            date=date,
            user_id=user_id,
            overall_state=overall_state,
            emotional_stability=stability,
            stress_periods=[{
                'start': p['start'].isoformat(),
                'end': p['end'].isoformat(),
                'duration_minutes': int((p['end'] - p['start']).total_seconds() / 60),
                'peak_stress': p.get('peak_stress')
            } for p in stress_periods],
            calm_periods=[{
                'start': p['start'].isoformat(),
                'end': p['end'].isoformat(),
                'duration_minutes': int((p['end'] - p['start']).total_seconds() / 60)
            } for p in calm_periods],
            energy_curve=energy_curve,
            activity_emotional_correlation=activity_correlation,
            spikes=[{
                'timestamp': s.timestamp.isoformat(),
                'spike_type': s.spike_type,
                'intensity': s.intensity,
                'duration_minutes': s.duration_minutes,
                'trigger_metric': s.trigger_metric,
                'before_value': s.before_value,
                'peak_value': s.peak_value,
                'context': s.context
            } for s in spikes],
            location_contexts=location_contexts,
            insights=insights,
            recommendations=recommendations
        )
    
    def _build_energy_curve(self, hourly_states: Dict[int, List]) -> List[Dict[str, Any]]:
        curve = []
        for hour in range(24):
            if hour in hourly_states:
                states = hourly_states[hour]
                energy_scores = []
                for s in states:
                    state = s['state']
                    if state in [EmotionalState.ENERGIZED, EmotionalState.EXCITED]:
                        energy_scores.append(0.9)
                    elif state in [EmotionalState.FOCUSED]:
                        energy_scores.append(0.7)
                    elif state in [EmotionalState.CALM, EmotionalState.RELAXED]:
                        energy_scores.append(0.5)
                    elif state in [EmotionalState.STRESSED, EmotionalState.ANXIOUS]:
                        energy_scores.append(0.6)
                    else:
                        energy_scores.append(0.3)
                avg_energy = np.mean(energy_scores) if energy_scores else 0.5
            else:
                avg_energy = None
            
            curve.append({
                'hour': hour,
                'energy_level': float(avg_energy) if avg_energy is not None else None,
                'data_available': hour in hourly_states
            })
        return curve
    
    def _calculate_overall_state(self, hourly_states: Dict[int, List]) -> Tuple[EmotionalState, float]:
        all_states = []
        for states in hourly_states.values():
            for s in states:
                all_states.append(s['state'])
        
        if not all_states:
            return EmotionalState.CALM, 0.5
        
        state_counts = {}
        for state in all_states:
            state_counts[state] = state_counts.get(state, 0) + 1
        
        dominant = max(state_counts, key=state_counts.get)
        
        unique_states = len(set(all_states))
        total_states = len(all_states)
        stability = 1.0 - (unique_states / max(total_states, 1)) * 0.5
        
        return dominant, float(stability)
    
    def _calculate_activity_emotional_correlation(self, data: List[Dict[str, Any]]) -> Dict[str, float]:
        correlations = {}
        
        steps = []
        stress = []
        heart_rates = []
        
        for dp in data:
            activity = dp.get('activity', {})
            if isinstance(activity, dict):
                s = activity.get('steps')
                if s is not None:
                    steps.append(s)
                    if dp.get('stress_level') is not None:
                        stress.append(dp['stress_level'])
                    if dp.get('heart_rate') is not None:
                        heart_rates.append(dp['heart_rate'])
        
        if len(steps) > 2 and len(stress) > 2:
            min_len = min(len(steps), len(stress))
            corr = np.corrcoef(steps[:min_len], stress[:min_len])[0, 1]
            if not np.isnan(corr):
                correlations['steps_stress'] = float(corr)
        
        if len(steps) > 2 and len(heart_rates) > 2:
            min_len = min(len(steps), len(heart_rates))
            corr = np.corrcoef(steps[:min_len], heart_rates[:min_len])[0, 1]
            if not np.isnan(corr):
                correlations['steps_heart_rate'] = float(corr)
        
        return correlations
    
    def _extract_location_contexts(self, data: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        contexts = []
        seen_locations = set()
        
        for dp in data:
            lat = dp.get('latitude')
            lon = dp.get('longitude')
            
            if lat is not None and lon is not None:
                location_key = f"{round(lat, 4)}_{round(lon, 4)}"
                
                if location_key not in seen_locations:
                    seen_locations.add(location_key)
                    
                    ts = dp.get('timestamp') or dp.get('recorded_at')
                    state, confidence, _ = self.analyze_current_state(
                        heart_rate=dp.get('heart_rate'),
                        hrv=dp.get('heart_rate_variability'),
                        stress_level=dp.get('stress_level'),
                        blood_oxygen=dp.get('blood_oxygen'),
                        activity_level=dp.get('energy_level'),
                        sleep_quality=None
                    )
                    
                    contexts.append({
                        'latitude': lat,
                        'longitude': lon,
                        'timestamp': ts.isoformat() if isinstance(ts, datetime) else ts,
                        'emotional_state': state.value,
                        'activity': dp.get('activity'),
                        'stress_level': dp.get('stress_level'),
                        'heart_rate': dp.get('heart_rate')
                    })
        
        return contexts
    
    def _generate_insights_and_recommendations(
        self,
        overall_state: EmotionalState,
        stability: float,
        stress_periods: List,
        calm_periods: List,
        spikes: List,
        energy_curve: List
    ) -> Tuple[List[str], List[str]]:
        insights = []
        recommendations = []
        
        if overall_state in [EmotionalState.STRESSED, EmotionalState.ANXIOUS]:
            insights.append("Ваш день был преимущественно напряженным")
            recommendations.append("Попробуйте дыхательные упражнения или медитацию")
        elif overall_state in [EmotionalState.CALM, EmotionalState.RELAXED]:
            insights.append("Вы провели спокойный и расслабленный день")
        elif overall_state == EmotionalState.ENERGIZED:
            insights.append("Вы были полны энергии сегодня")
        elif overall_state == EmotionalState.TIRED:
            insights.append("Вы чувствовали усталость в течение дня")
            recommendations.append("Постарайтесь лечь спать раньше")
        
        if stability < 0.5:
            insights.append("Ваше эмоциональное состояние значительно менялось в течение дня")
            recommendations.append("Обратите внимание на триггеры эмоциональных изменений")
        elif stability > 0.8:
            insights.append("Ваше эмоциональное состояние было стабильным")
        
        total_stress_minutes = sum([
            int((p['end'] - p['start']).total_seconds() / 60) 
            for p in stress_periods
        ])
        if total_stress_minutes > 120:
            insights.append(f"Стресс занял {total_stress_minutes} минут вашего дня")
            recommendations.append("Рассмотрите короткие перерывы для отдыха")
        
        if len(spikes) > 3:
            insights.append(f"Обнаружено {len(spikes)} эмоциональных всплесков")
            recommendations.append("Ведите дневник, чтобы понять причины резких изменений")
        
        peak_hours = [h['hour'] for h in energy_curve if h['energy_level'] and h['energy_level'] > 0.7]
        if peak_hours:
            insights.append(f"Пик вашей энергии приходился на {peak_hours[0]}:00 - {peak_hours[-1]}:00")
        
        return insights, recommendations
    
    def _empty_summary(self, user_id: str, date: str) -> DayEmotionalSummary:
        return DayEmotionalSummary(
            date=date,
            user_id=user_id,
            overall_state=EmotionalState.CALM,
            emotional_stability=0.5,
            stress_periods=[],
            calm_periods=[],
            energy_curve=[],
            activity_emotional_correlation={},
            spikes=[],
            location_contexts=[],
            insights=["Недостаточно данных для анализа"],
            recommendations=["Носите часы чаще для получения точных данных"]
        )

