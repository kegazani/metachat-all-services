from sqlalchemy import Column, String, Float, Integer, DateTime, ARRAY, Index
from sqlalchemy.sql import func
from datetime import datetime

from src.infrastructure.database import Base


class MoodAnalysis(Base):
    __tablename__ = "mood_analysis"
    
    id = Column(String, primary_key=True)
    entry_id = Column(String, nullable=False, index=True)
    user_id = Column(String, nullable=False, index=True)
    
    emotion_vector = Column(ARRAY(Float), nullable=False)
    dominant_emotion = Column(String, nullable=False)
    valence = Column(Float, nullable=False)
    arousal = Column(Float, nullable=False)
    confidence = Column(Float, nullable=False)
    model_version = Column(String, nullable=False)
    tokens_count = Column(Integer, nullable=False)
    detected_topics = Column(ARRAY(String), nullable=True)
    keywords = Column(ARRAY(String), nullable=True)
    
    analyzed_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    
    __table_args__ = (
        Index("idx_mood_analysis_user_analyzed", "user_id", "analyzed_at"),
        Index("idx_mood_analysis_entry", "entry_id"),
    )

