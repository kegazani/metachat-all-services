import os
import yaml
import json
from pathlib import Path
from typing import List
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
                    kwargs["kafka_brokers"] = parsed if isinstance(parsed, list) else [parsed] if parsed else ["127.0.0.1:9092"]
                else:
                    kwargs["kafka_brokers"] = ["127.0.0.1:9092"]
            except (json.JSONDecodeError, ValueError):
                kwargs["kafka_brokers"] = [env_kafka_brokers] if env_kafka_brokers else ["127.0.0.1:9092"]
            os.environ.pop("KAFKA_BROKERS", None)
            os.environ.pop("kafka_brokers", None)
        
        yaml_config = load_yaml_config()
        
        if yaml_config:
            service_config = yaml_config.get("service", {})
            server_config = yaml_config.get("server", {})
            database_config = yaml_config.get("database", {})
            kafka_config = yaml_config.get("kafka", {})
            archetype_config = yaml_config.get("archetype", {})
            thresholds = archetype_config.get("thresholds", {})
            
            kwargs.setdefault("service_name", service_config.get("name", "archetype-service"))
            kwargs.setdefault("log_level", service_config.get("log_level", "INFO"))
            kwargs.setdefault("http_port", server_config.get("http_port", 8001))
            kwargs.setdefault("http_host", server_config.get("http_host", "0.0.0.0"))
            kwargs.setdefault("grpc_port", server_config.get("grpc_port", 50056))
            kwargs.setdefault("database_url", database_config.get("url", "postgresql+asyncpg://metachat:metachat_password@127.0.0.1:5432/metachat_personality"))
            kwargs.setdefault("database_pool_size", database_config.get("pool_size", 10))
            kwargs.setdefault("database_max_overflow", database_config.get("max_overflow", 20))
            kwargs.setdefault("kafka_brokers", kafka_config.get("brokers", ["127.0.0.1:9092"]))
            kwargs.setdefault("kafka_consumer_group", kafka_config.get("consumer_group", "archetype-service"))
            
            topics = kafka_config.get("topics", {})
            kwargs.setdefault("mood_analyzed_topic", topics.get("mood_analyzed", "metachat.mood.analyzed"))
            kwargs.setdefault("diary_entry_created_topic", topics.get("diary_entry_created", "metachat.diary.entry.created"))
            kwargs.setdefault("personality_assigned_topic", topics.get("personality_assigned", "metachat.personality.assigned"))
            kwargs.setdefault("personality_updated_topic", topics.get("personality_updated", "metachat.personality.updated"))
            kwargs.setdefault("personality_calculation_triggered_topic", topics.get("personality_calculation_triggered", "metachat.personality.calculation.triggered"))
            
            personality_config = yaml_config.get("personality", {})
            thresholds = personality_config.get("thresholds", {})
            kwargs.setdefault("initial_tokens_threshold", thresholds.get("initial_tokens", 50))
            kwargs.setdefault("recalculation_tokens_threshold", thresholds.get("recalculation_tokens", 100))
            kwargs.setdefault("min_confidence_threshold", thresholds.get("min_confidence", 0.3))
            kwargs.setdefault("recalculation_interval_days", thresholds.get("recalculation_interval_days", 7))
            kwargs.setdefault("model_version", personality_config.get("model_version", "big-five-v1"))
        
        super().__init__(**kwargs)
    
    service_name: str = "personality-service"
    log_level: str = "INFO"
    
    http_port: int = 8001
    http_host: str = "0.0.0.0"
    grpc_port: int = 50056
    
    database_url: str = "postgresql+asyncpg://metachat:metachat_password@127.0.0.1:5432/metachat_personality"
    database_pool_size: int = 10
    database_max_overflow: int = 20
    
    kafka_brokers: List[str] = ["127.0.0.1:9092"]
    kafka_consumer_group: str = "personality-service"
    
    @field_validator('kafka_brokers', mode='before')
    @classmethod
    def parse_kafka_brokers(cls, v):
        if v is None:
            return ["127.0.0.1:9092"]
        if isinstance(v, str):
            if not v.strip():
                return ["127.0.0.1:9092"]
            try:
                parsed = json.loads(v)
                if isinstance(parsed, list):
                    return parsed
                return [parsed] if parsed else ["127.0.0.1:9092"]
            except (json.JSONDecodeError, ValueError):
                return [v] if v else ["127.0.0.1:9092"]
        if isinstance(v, list):
            return v if v else ["127.0.0.1:9092"]
        return ["127.0.0.1:9092"]
    
    @model_validator(mode='before')
    @classmethod
    def parse_kafka_brokers(cls, data):
        if isinstance(data, dict):
            kafka_bootstrap = os.getenv("KAFKA_BOOTSTRAP_SERVERS")
            if kafka_bootstrap:
                kafka_bootstrap = kafka_bootstrap.replace("localhost", "127.0.0.1")
                if "," in kafka_bootstrap:
                    data["kafka_brokers"] = [b.strip() for b in kafka_bootstrap.split(",")]
                else:
                    data["kafka_brokers"] = [kafka_bootstrap]
            elif "kafka_brokers" in data:
                if isinstance(data["kafka_brokers"], str):
                    data["kafka_brokers"] = [data["kafka_brokers"].replace("localhost", "127.0.0.1")]
                elif isinstance(data["kafka_brokers"], list):
                    data["kafka_brokers"] = [b.replace("localhost", "127.0.0.1") if isinstance(b, str) else b for b in data["kafka_brokers"]]
            
            database_url = os.getenv("DATABASE_URL")
            if database_url:
                data["database_url"] = database_url.replace("localhost", "127.0.0.1")
            elif "database_url" in data and isinstance(data["database_url"], str):
                data["database_url"] = data["database_url"].replace("localhost", "127.0.0.1")
        
        return data
    
    @model_validator(mode='after')
    def ensure_ipv4_addresses(self):
        if "localhost" in self.database_url:
            object.__setattr__(self, 'database_url', self.database_url.replace("localhost", "127.0.0.1"))
        
        if self.kafka_brokers:
            new_brokers = []
            for broker in self.kafka_brokers:
                if isinstance(broker, str) and "localhost" in broker:
                    new_brokers.append(broker.replace("localhost", "127.0.0.1"))
                else:
                    new_brokers.append(broker)
            object.__setattr__(self, 'kafka_brokers', new_brokers)
        
        return self
    
    mood_analyzed_topic: str = "metachat.mood.analyzed"
    diary_entry_created_topic: str = "metachat.diary.entry.created"
    personality_assigned_topic: str = "metachat.personality.assigned"
    personality_updated_topic: str = "metachat.personality.updated"
    personality_calculation_triggered_topic: str = "metachat.personality.calculation.triggered"
    
    archetype_assigned_topic: str = "metachat.archetype.assigned"
    archetype_updated_topic: str = "metachat.archetype.updated"
    archetype_calculation_triggered_topic: str = "metachat.archetype.calculation.triggered"
    
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
    
    initial_tokens_threshold: int = 50
    recalculation_tokens_threshold: int = 100
    min_confidence_threshold: float = 0.3
    recalculation_interval_days: int = 7
    
    model_version: str = "big-five-v1"
