import os
from typing import List, Optional
from pydantic import BaseSettings, Field


class Config(BaseSettings):
    # Server configuration
    grpc_port: int = Field(default=50051, env="GRPC_PORT")
    
    # Kafka configuration
    kafka_brokers: List[str] = Field(default=["kafka:9092"], env="KAFKA_BROKERS")
    kafka_topic_prefix: str = Field(default="metachat", env="KAFKA_TOPIC_PREFIX")
    kafka_consumer_group: str = Field(default="mood-analysis-service", env="KAFKA_CONSUMER_GROUP")
    
    # Topics
    diary_entry_created_topic: str = Field(default="metachat_diary_entry_created", env="DIARY_ENTRY_CREATED_TOPIC")
    diary_entry_updated_topic: str = Field(default="metachat_diary_entry_updated", env="DIARY_ENTRY_UPDATED_TOPIC")
    mood_analyzed_topic: str = Field(default="metachat_mood_analyzed", env="MOOD_ANALYZED_TOPIC")
    
    # Model configuration
    model_name: str = Field(default="DeepPavlov/rubert-base-cased-conversational", env="MODEL_NAME")
    model_cache_dir: str = Field(default="/app/models", env="MODEL_CACHE_DIR")
    
    # Logging configuration
    log_level: str = Field(default="INFO", env="LOG_LEVEL")
    
    # Aggregation configuration
    aggregation_interval: int = Field(default=3600, env="AGGREGATION_INTERVAL")  # in seconds
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"