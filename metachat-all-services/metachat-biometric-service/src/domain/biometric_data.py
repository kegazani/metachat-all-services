from typing import Optional, Dict, Any, List
from datetime import datetime
from pydantic import BaseModel, Field
from enum import Enum


class DeviceType(str, Enum):
    APPLE_WATCH = "apple_watch"
    WEAR_OS = "wear_os"
    GARMIN = "garmin"
    FITBIT = "fitbit"
    SAMSUNG = "samsung"
    XIAOMI = "xiaomi"
    HUAWEI = "huawei"
    OTHER = "other"


class SleepStage(str, Enum):
    AWAKE = "awake"
    LIGHT = "light"
    DEEP = "deep"
    REM = "rem"


class SleepSegment(BaseModel):
    stage: SleepStage
    start_time: datetime
    end_time: datetime
    duration_minutes: int


class SleepData(BaseModel):
    total_sleep_minutes: Optional[int] = None
    time_in_bed_minutes: Optional[int] = None
    sleep_efficiency: Optional[float] = None
    segments: Optional[List[SleepSegment]] = None
    sleep_score: Optional[int] = None


class ActivityData(BaseModel):
    steps: Optional[int] = None
    distance_meters: Optional[float] = None
    calories_burned: Optional[float] = None
    active_minutes: Optional[int] = None
    floors_climbed: Optional[int] = None
    activity_type: Optional[str] = None


class WatchDataRequest(BaseModel):
    user_id: str
    device_id: Optional[str] = None
    device_type: Optional[DeviceType] = DeviceType.OTHER
    
    heart_rate: Optional[float] = Field(None, ge=30, le=250)
    heart_rate_variability: Optional[float] = Field(None, ge=0, le=500)
    resting_heart_rate: Optional[float] = Field(None, ge=30, le=150)
    
    blood_oxygen: Optional[float] = Field(None, ge=70, le=100)
    respiratory_rate: Optional[float] = Field(None, ge=5, le=60)
    body_temperature: Optional[float] = Field(None, ge=35.0, le=42.0)
    
    stress_level: Optional[int] = Field(None, ge=0, le=100)
    energy_level: Optional[int] = Field(None, ge=0, le=100)
    
    sleep_data: Optional[SleepData] = None
    activity: Optional[ActivityData] = None
    
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    
    recorded_at: Optional[datetime] = None
    
    raw_data: Optional[Dict[str, Any]] = None


class BiometricDataRequest(BaseModel):
    user_id: str
    device_id: Optional[str] = None
    heart_rate: Optional[float] = None
    sleep_data: Optional[Dict[str, Any]] = None
    activity: Optional[Dict[str, Any]] = None
    recorded_at: Optional[datetime] = None


class BiometricDataResponse(BaseModel):
    id: str
    user_id: str
    device_id: Optional[str]
    heart_rate: Optional[float]
    sleep_data: Optional[Dict[str, Any]]
    activity: Optional[Dict[str, Any]]
    recorded_at: datetime
    created_at: datetime


class WatchDataResponse(BaseModel):
    id: str
    user_id: str
    device_id: Optional[str]
    device_type: Optional[str]
    heart_rate: Optional[float]
    heart_rate_variability: Optional[float]
    blood_oxygen: Optional[float]
    stress_level: Optional[int]
    steps: Optional[int]
    calories: Optional[float]
    recorded_at: datetime
    created_at: datetime


class BiometricSummaryResponse(BaseModel):
    user_id: str
    date: str
    avg_heart_rate: Optional[float]
    avg_hrv: Optional[float]
    avg_blood_oxygen: Optional[float]
    avg_stress_level: Optional[float]
    total_steps: Optional[int]
    total_calories: Optional[float]
    total_sleep_minutes: Optional[int]
    sleep_score: Optional[int]
    data_points: int
    last_updated: datetime


class UserBiometricProfile(BaseModel):
    user_id: str
    current_heart_rate: Optional[float] = None
    resting_heart_rate: Optional[float] = None
    avg_hrv: Optional[float] = None
    avg_blood_oxygen: Optional[float] = None
    avg_stress_level: Optional[float] = None
    today_steps: Optional[int] = None
    today_calories: Optional[float] = None
    last_sleep_score: Optional[int] = None
    last_sleep_duration_hours: Optional[float] = None
    health_score: Optional[int] = None
    last_sync: Optional[datetime] = None
    device_type: Optional[str] = None
    trends: Optional[Dict[str, Any]] = None


class RealtimeWatchEvent(BaseModel):
    event_type: str
    user_id: str
    device_id: Optional[str]
    timestamp: datetime
    data: Dict[str, Any]

