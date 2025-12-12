from sqlalchemy import Column, String, Float, Integer, DateTime, JSON, Index
from sqlalchemy.sql import func
from datetime import datetime

from src.infrastructure.database import Base


class UserPersonalityData(Base):
    __tablename__ = "user_personality_data"
    
    user_id = Column(String, primary_key=True)
    accumulated_tokens = Column(Integer, nullable=False, default=0)
    aggregated_emotion_vector = Column(JSON, nullable=True)
    topic_distribution = Column(JSON, nullable=True)
    stylistic_metrics = Column(JSON, nullable=True)
    last_updated = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)


class BigFiveCalculation(Base):
    __tablename__ = "big_five_calculations"
    
    id = Column(String, primary_key=True)
    user_id = Column(String, nullable=False, index=True)
    openness = Column(Float, nullable=False)
    conscientiousness = Column(Float, nullable=False)
    extraversion = Column(Float, nullable=False)
    agreeableness = Column(Float, nullable=False)
    neuroticism = Column(Float, nullable=False)
    dominant_trait = Column(String, nullable=False)
    confidence = Column(Float, nullable=False)
    model_version = Column(String, nullable=False)
    tokens_analyzed = Column(Integer, nullable=False)
    used_data = Column(JSON, nullable=True)
    calculated_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    
    __table_args__ = (
        Index("idx_big_five_calc_user_calculated", "user_id", "calculated_at"),
    )

