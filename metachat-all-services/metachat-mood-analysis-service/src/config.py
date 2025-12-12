import os
import yaml
import json
from pathlib import Path
from typing import List, Optional
from pydantic import model_validator, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


def load_yaml_config(config_path: str = "config.yaml") -> dict:
    config_file = Path(config_path)
    if not config_file.exists():
        config_file = Path(__file__).parent.parent / config_path
    
    if config_file.exists():
        with open(config_file, 'r', encoding='utf-8') as f:
            return yaml.safe_load(f) or {}
    return {}


class Config(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        protected_namespaces=(),
        extra="allow"
    )
    
    def __init__(self, **kwargs):
        env_kafka_brokers = os.getenv("KAFKA_BROKERS") or os.getenv("kafka_brokers")
        if env_kafka_brokers is not None and "kafka_brokers" not in kwargs:
            try:
                if env_kafka_brokers.strip():
                    parsed = json.loads(env_kafka_brokers)
                    kwargs["kafka_brokers"] = parsed if isinstance(parsed, list) else [parsed] if parsed else ["localhost:9092"]
                else:
                    kwargs["kafka_brokers"] = ["localhost:9092"]
            except (json.JSONDecodeError, ValueError):
                kwargs["kafka_brokers"] = [env_kafka_brokers] if env_kafka_brokers else ["localhost:9092"]
            os.environ.pop("KAFKA_BROKERS", None)
            os.environ.pop("kafka_brokers", None)
        
        yaml_config = load_yaml_config()
        
        if yaml_config:
            service_config = yaml_config.get("service", {})
            server_config = yaml_config.get("server", {})
            database_config = yaml_config.get("database", {})
            kafka_config = yaml_config.get("kafka", {})
            model_config = yaml_config.get("model", {})
            plutchik_config = yaml_config.get("plutchik", {})
            topics_config = yaml_config.get("topics", {})
            retry_config = yaml_config.get("retry", {})
            
            kwargs.setdefault("service_name", service_config.get("name", "mood-analysis-service"))
            kwargs.setdefault("log_level", service_config.get("log_level", "INFO"))
            kwargs.setdefault("grpc_port", server_config.get("grpc_port", 50051))
            kwargs.setdefault("http_port", server_config.get("http_port", 8000))
            kwargs.setdefault("http_host", server_config.get("http_host", "0.0.0.0"))
            kwargs.setdefault("database_url", database_config.get("url", "postgresql+asyncpg://metachat:metachat_password@localhost:5432/metachat_mood"))
            kwargs.setdefault("database_pool_size", database_config.get("pool_size", 10))
            kwargs.setdefault("database_max_overflow", database_config.get("max_overflow", 20))
            kwargs.setdefault("kafka_brokers", kafka_config.get("brokers", ["localhost:9092"]))
            kwargs.setdefault("kafka_consumer_group", kafka_config.get("consumer_group", "mood-analysis-service"))
            
            topics = kafka_config.get("topics", {})
            kwargs.setdefault("diary_entry_created_topic", topics.get("diary_entry_created", "metachat.diary.entry.created"))
            kwargs.setdefault("diary_entry_updated_topic", topics.get("diary_entry_updated", "metachat.diary.entry.updated"))
            kwargs.setdefault("mood_analyzed_topic", topics.get("mood_analyzed", "metachat.mood.analyzed"))
            kwargs.setdefault("mood_analysis_failed_topic", topics.get("mood_analysis_failed", "metachat.mood.analysis.failed"))
            
            kwargs.setdefault("model_name", model_config.get("name", "blanchefort/rubert-base-cased-sentiment"))
            kwargs.setdefault("model_cache_dir", model_config.get("cache_dir", "/app/models"))
            kwargs.setdefault("model_version", model_config.get("version", "rubert-emotion-v1"))
            
            kwargs.setdefault("plutchik_emotions", plutchik_config.get("emotions", ["joy", "trust", "fear", "surprise", "sadness", "disgust", "anger", "anticipation"]))
            kwargs.setdefault("topics_dictionary", topics_config.get("dictionary", ["работа", "отношения", "здоровье", "семья", "друзья", "финансы", "хобби", "стресс", "учеба", "путешествия"]))
            
            kwargs.setdefault("retry_max_attempts", retry_config.get("max_attempts", 3))
            kwargs.setdefault("retry_initial_delay", retry_config.get("initial_delay", 1.0))
            kwargs.setdefault("retry_max_delay", retry_config.get("max_delay", 60.0))
            kwargs.setdefault("retry_exponential_base", retry_config.get("exponential_base", 2.0))
        
        super().__init__(**kwargs)
    
    service_name: str = "mood-analysis-service"
    log_level: str = "INFO"
    
    grpc_port: int = 50051
    http_port: int = 8000
    http_host: str = "0.0.0.0"
    
    database_url: str = "postgresql+asyncpg://metachat:metachat_password@localhost:5432/metachat_mood"
    database_pool_size: int = 10
    database_max_overflow: int = 20
    
    kafka_brokers: List[str] = ["localhost:9092"]
    kafka_consumer_group: str = "mood-analysis-service"
    
    @field_validator('kafka_brokers', mode='before')
    @classmethod
    def parse_kafka_brokers(cls, v):
        if v is None:
            return ["localhost:9092"]
        if isinstance(v, str):
            if not v.strip():
                return ["localhost:9092"]
            try:
                parsed = json.loads(v)
                if isinstance(parsed, list):
                    return parsed
                return [parsed] if parsed else ["localhost:9092"]
            except (json.JSONDecodeError, ValueError):
                return [v] if v else ["localhost:9092"]
        if isinstance(v, list):
            return v if v else ["localhost:9092"]
        return ["localhost:9092"]
    
    @model_validator(mode='after')
    def fix_localhost_addresses(self):
        if "localhost" in self.database_url:
            object.__setattr__(self, 'database_url', self.database_url.replace("localhost", "127.0.0.1"))
        
        if self.kafka_brokers:
            new_brokers = [broker.replace("localhost", "127.0.0.1") if "localhost" in broker else broker for broker in self.kafka_brokers]
            object.__setattr__(self, 'kafka_brokers', new_brokers)
        
        return self
    
    diary_entry_created_topic: str = "metachat.diary.entry.created"
    diary_entry_updated_topic: str = "metachat.diary.entry.updated"
    mood_analyzed_topic: str = "metachat.mood.analyzed"
    mood_analysis_failed_topic: str = "metachat.mood.analysis.failed"
    
    all_kafka_topics: dict = {
        "user_service": ["metachat-user-events"],
        "diary_service": [
            "diary-events",
            "session-events",
            "metachat.diary.entry.created",
            "metachat.diary.entry.updated",
            "metachat.diary.entry.deleted"
        ],
        "mood_analysis_service": [
            "metachat.diary.entry.created",
            "metachat.diary.entry.updated",
            "metachat.mood.analyzed",
            "metachat.mood.analysis.failed"
        ],
        "analytics_service": [
            "metachat.mood.analyzed",
            "metachat.diary.entry.created",
            "metachat.diary.entry.deleted",
            "metachat.archetype.updated"
        ],
        "archetype_service": [
            "metachat.mood.analyzed",
            "metachat.diary.entry.created",
            "metachat.archetype.assigned",
            "metachat.archetype.updated",
            "metachat.archetype.calculation.triggered"
        ],
        "biometric_service": ["metachat.biometric.data.received"],
        "correlation_service": [
            "metachat.mood.analyzed",
            "metachat.biometric.data.received",
            "metachat.correlation.discovered"
        ]
    }
    
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
