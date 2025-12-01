import os
from typing import List, Optional
from pydantic_settings import BaseSettings, SettingsConfigDict


class Config(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", case_sensitive=False)
    
    service_name: str = "mood-analysis-service"
    log_level: str = "INFO"
    
    grpc_port: int = 50051
    http_port: int = 8000
    http_host: str = "0.0.0.0"
    
    database_url: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/metachat_mood"
    database_pool_size: int = 10
    database_max_overflow: int = 20
    
    kafka_brokers: List[str] = ["localhost:9092"]
    kafka_consumer_group: str = "mood-analysis-service"
    diary_entry_created_topic: str = "metachat.diary.entry.created"
    diary_entry_updated_topic: str = "metachat.diary.entry.updated"
    mood_analyzed_topic: str = "metachat.mood.analyzed"
    mood_analysis_failed_topic: str = "metachat.mood.analysis.failed"
    
    model_name: str = "blanchefort/rubert-base-cased-sentiment"
    model_cache_dir: str = "/app/models"
    model_version: str = "rubert-emotion-v1"
    
    plutchik_emotions: List[str] = ["joy", "trust", "fear", "surprise", "sadness", "disgust", "anger", "anticipation"]
    
    topics_dictionary: List[str] = [
        "работа", "отношения", "здоровье", "семья", "друзья", 
        "финансы", "хобби", "стресс", "учеба", "путешествия"
    ]
    
    retry_max_attempts: int = 3
    retry_initial_delay: float = 1.0
    retry_max_delay: float = 60.0
    retry_exponential_base: float = 2.0
