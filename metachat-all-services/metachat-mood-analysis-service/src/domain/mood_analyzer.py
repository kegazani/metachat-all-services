import re
import torch
import numpy as np
from typing import Dict, List, Optional
from transformers import AutoTokenizer, AutoModelForSequenceClassification
import structlog

from src.config import Config
from src.domain.plutchik_model import PlutchikModel
from src.domain.topic_analyzer import TopicAnalyzer

logger = structlog.get_logger()


class MoodAnalyzer:
    def __init__(self, config: Config):
        self.config = config
        self.model_name = config.model_name
        self.model_cache_dir = config.model_cache_dir
        self.model_version = config.model_version
        
        logger.info("Loading sentiment model", model_name=self.model_name)
        self.tokenizer = AutoTokenizer.from_pretrained(
            self.model_name,
            cache_dir=self.model_cache_dir
        )
        self.model = AutoModelForSequenceClassification.from_pretrained(
            self.model_name,
            cache_dir=self.model_cache_dir
        )
        
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        self.model.to(self.device)
        self.model.eval()
        
        self.plutchik = PlutchikModel()
        self.topic_analyzer = TopicAnalyzer(config.topics_dictionary)
        
        logger.info("MoodAnalyzer initialized", device=str(self.device))
    
    def preprocess_text(self, text: str) -> str:
        text = re.sub(r'http\S+|www\S+|https\S+', '', text, flags=re.MULTILINE)
        text = re.sub(r'[^\w\s]', ' ', text)
        text = re.sub(r'\s+', ' ', text)
        return text.strip()
    
    def analyze_sentiment(self, text: str) -> tuple[str, float]:
        preprocessed = self.preprocess_text(text)
        
        inputs = self.tokenizer(
            preprocessed,
            return_tensors="pt",
            truncation=True,
            padding=True,
            max_length=512
        )
        inputs = {k: v.to(self.device) for k, v in inputs.items()}
        
        with torch.no_grad():
            outputs = self.model(**inputs)
        
        probabilities = torch.nn.functional.softmax(outputs.logits, dim=-1)[0]
        sentiment_labels = ["negative", "neutral", "positive"]
        
        max_idx = torch.argmax(probabilities).item()
        sentiment = sentiment_labels[max_idx]
        confidence = float(probabilities[max_idx])
        
        return sentiment, confidence
    
    def analyze(self, text: str, entry_id: str, user_id: str, tokens_count: int) -> Dict:
        try:
            sentiment, sentiment_confidence = self.analyze_sentiment(text)
            
            emotion_vector = self.plutchik.map_sentiment_to_emotions(sentiment, sentiment_confidence)
            emotion_vector = self.plutchik.normalize_emotion_vector(emotion_vector)
            emotion_vector = [float(v) for v in emotion_vector]
            
            dominant_emotion = self.plutchik.get_dominant_emotion(emotion_vector)
            valence = float(self.plutchik.calculate_valence(emotion_vector))
            arousal = float(self.plutchik.calculate_arousal(emotion_vector))
            
            logger.debug(
                "Extracting topics and keywords",
                entry_id=entry_id,
                text_preview=text[:100] if text else "",
                text_length=len(text) if text else 0
            )
            
            detected_topics = self.topic_analyzer.extract_topics(text)
            keywords = self.topic_analyzer.extract_keywords(text)
            
            if detected_topics is None:
                detected_topics = []
            if keywords is None:
                keywords = []
            
            if not isinstance(detected_topics, list):
                detected_topics = []
            if not isinstance(keywords, list):
                keywords = []
            
            logger.debug(
                "Topics and keywords extracted",
                entry_id=entry_id,
                detected_topics=detected_topics,
                keywords=keywords,
                topics_count=len(detected_topics),
                keywords_count=len(keywords),
                topics_type=type(detected_topics).__name__,
                keywords_type=type(keywords).__name__
            )
            
            overall_confidence = float(sentiment_confidence * 0.8 + (max(emotion_vector) * 0.2))
            
            result = {
                "entry_id": entry_id,
                "user_id": user_id,
                "emotion_vector": emotion_vector,
                "dominant_emotion": dominant_emotion,
                "valence": valence,
                "arousal": arousal,
                "confidence": overall_confidence,
                "model_version": self.model_version,
                "tokens_count": int(tokens_count),
                "detected_topics": detected_topics,
                "keywords": keywords
            }
            
            logger.info(
                "Mood analysis completed",
                entry_id=entry_id,
                user_id=user_id,
                dominant_emotion=dominant_emotion,
                confidence=overall_confidence,
                detected_topics=detected_topics,
                keywords=keywords,
                text_length=len(text) if text else 0
            )
            
            return result
            
        except Exception as e:
            logger.error(
                "Mood analysis failed",
                entry_id=entry_id,
                user_id=user_id,
                error=str(e),
                exc_info=True
            )
            raise
    
    def analyze_text(self, text: str) -> Dict[str, float]:
        sentiment, confidence = self.analyze_sentiment(text)
        emotion_vector = self.plutchik.map_sentiment_to_emotions(sentiment, confidence)
        emotion_vector = self.plutchik.normalize_emotion_vector(emotion_vector)
        
        return {emotion: float(score) for emotion, score in zip(self.plutchik.EMOTIONS, emotion_vector)}

