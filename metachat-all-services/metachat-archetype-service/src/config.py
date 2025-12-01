from typing import List
from pydantic_settings import BaseSettings, SettingsConfigDict


class Config(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", case_sensitive=False)
    
    service_name: str = "archetype-service"
    log_level: str = "INFO"
    
    http_port: int = 8001
    http_host: str = "0.0.0.0"
    
    database_url: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/metachat_archetype"
    database_pool_size: int = 10
    database_max_overflow: int = 20
    
    kafka_brokers: List[str] = ["localhost:9092"]
    kafka_consumer_group: str = "archetype-service"
    mood_analyzed_topic: str = "metachat.mood.analyzed"
    diary_entry_created_topic: str = "metachat.diary.entry.created"
    archetype_assigned_topic: str = "metachat.archetype.assigned"
    archetype_updated_topic: str = "metachat.archetype.updated"
    archetype_calculation_triggered_topic: str = "metachat.archetype.calculation.triggered"
    
    initial_tokens_threshold: int = 10000
    recalculation_tokens_threshold: int = 5000
    min_confidence_threshold: float = 0.6
    recalculation_interval_days: int = 30
    
    model_version: str = "archetype-rules-v1"

