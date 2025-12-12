from sqlalchemy import Column, String, Float, Integer, DateTime, JSON, Index, Boolean
from sqlalchemy.sql import func
from datetime import datetime

from src.infrastructure.database import Base


class BiometricData(Base):
    __tablename__ = "biometric_data"
    
    id = Column(String, primary_key=True)
    user_id = Column(String, nullable=False, index=True)
    device_id = Column(String, nullable=True)
    device_type = Column(String, nullable=True)
    heart_rate = Column(Float, nullable=True)
    sleep_data = Column(JSON, nullable=True)
    activity = Column(JSON, nullable=True)
    recorded_at = Column(DateTime(timezone=True), nullable=False, index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    
    __table_args__ = (
        Index("idx_biometric_user_recorded", "user_id", "recorded_at"),
    )


class WatchData(Base):
    __tablename__ = "watch_data"
    
    id = Column(String, primary_key=True)
    user_id = Column(String, nullable=False, index=True)
    device_id = Column(String, nullable=True)
    device_type = Column(String, nullable=True)
    
    heart_rate = Column(Float, nullable=True)
    heart_rate_variability = Column(Float, nullable=True)
    resting_heart_rate = Column(Float, nullable=True)
    
    blood_oxygen = Column(Float, nullable=True)
    respiratory_rate = Column(Float, nullable=True)
    body_temperature = Column(Float, nullable=True)
    
    stress_level = Column(Integer, nullable=True)
    energy_level = Column(Integer, nullable=True)
    
    steps = Column(Integer, nullable=True)
    distance_meters = Column(Float, nullable=True)
    calories_burned = Column(Float, nullable=True)
    active_minutes = Column(Integer, nullable=True)
    
    sleep_minutes = Column(Integer, nullable=True)
    sleep_score = Column(Integer, nullable=True)
    sleep_data = Column(JSON, nullable=True)
    
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    
    raw_data = Column(JSON, nullable=True)
    
    recorded_at = Column(DateTime(timezone=True), nullable=False, index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    
    __table_args__ = (
        Index("idx_watch_user_recorded", "user_id", "recorded_at"),
        Index("idx_watch_device_recorded", "device_id", "recorded_at"),
    )


class BiometricSummary(Base):
    __tablename__ = "biometric_summary"
    
    id = Column(String, primary_key=True)
    user_id = Column(String, nullable=False, index=True)
    date = Column(String, nullable=False)
    
    avg_heart_rate = Column(Float, nullable=True)
    min_heart_rate = Column(Float, nullable=True)
    max_heart_rate = Column(Float, nullable=True)
    avg_hrv = Column(Float, nullable=True)
    resting_heart_rate = Column(Float, nullable=True)
    
    avg_blood_oxygen = Column(Float, nullable=True)
    min_blood_oxygen = Column(Float, nullable=True)
    
    avg_stress_level = Column(Float, nullable=True)
    max_stress_level = Column(Integer, nullable=True)
    
    total_steps = Column(Integer, nullable=True)
    total_distance_meters = Column(Float, nullable=True)
    total_calories = Column(Float, nullable=True)
    active_minutes = Column(Integer, nullable=True)
    
    total_sleep_minutes = Column(Integer, nullable=True)
    sleep_score = Column(Integer, nullable=True)
    sleep_efficiency = Column(Float, nullable=True)
    
    health_score = Column(Integer, nullable=True)
    
    data_points = Column(Integer, nullable=False, default=0)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    
    __table_args__ = (
        Index("idx_biometric_summary_user_date", "user_id", "date", unique=True),
    )


class UserBiometricState(Base):
    __tablename__ = "user_biometric_state"
    
    user_id = Column(String, primary_key=True)
    
    current_heart_rate = Column(Float, nullable=True)
    resting_heart_rate = Column(Float, nullable=True)
    avg_hrv_7d = Column(Float, nullable=True)
    avg_blood_oxygen_7d = Column(Float, nullable=True)
    avg_stress_level_7d = Column(Float, nullable=True)
    
    today_steps = Column(Integer, nullable=True)
    today_calories = Column(Float, nullable=True)
    today_active_minutes = Column(Integer, nullable=True)
    
    last_sleep_score = Column(Integer, nullable=True)
    last_sleep_duration_minutes = Column(Integer, nullable=True)
    
    health_score = Column(Integer, nullable=True)
    
    device_type = Column(String, nullable=True)
    device_id = Column(String, nullable=True)
    
    is_connected = Column(Boolean, default=False)
    last_sync = Column(DateTime(timezone=True), nullable=True)
    
    trends = Column(JSON, nullable=True)
    
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

