from typing import Dict, List, Tuple
import numpy as np


class PlutchikModel:
    EMOTIONS = ["joy", "trust", "fear", "surprise", "sadness", "disgust", "anger", "anticipation"]
    
    EMOTION_INDICES = {emotion: idx for idx, emotion in enumerate(EMOTIONS)}
    
    VALENCE_MAP = {
        "joy": 1.0,
        "trust": 0.5,
        "fear": -0.5,
        "surprise": 0.0,
        "sadness": -1.0,
        "disgust": -0.8,
        "anger": -0.9,
        "anticipation": 0.3
    }
    
    AROUSAL_MAP = {
        "joy": 0.6,
        "trust": 0.2,
        "fear": 0.9,
        "surprise": 0.8,
        "sadness": -0.3,
        "disgust": -0.2,
        "anger": 0.7,
        "anticipation": 0.5
    }
    
    @staticmethod
    def map_sentiment_to_emotions(sentiment: str, confidence: float) -> List[float]:
        emotion_vector = [0.0] * 8
        
        if sentiment == "positive":
            emotion_vector[PlutchikModel.EMOTION_INDICES["joy"]] = confidence * 0.6
            emotion_vector[PlutchikModel.EMOTION_INDICES["trust"]] = confidence * 0.4
            emotion_vector[PlutchikModel.EMOTION_INDICES["anticipation"]] = confidence * 0.3
        elif sentiment == "negative":
            emotion_vector[PlutchikModel.EMOTION_INDICES["sadness"]] = confidence * 0.5
            emotion_vector[PlutchikModel.EMOTION_INDICES["anger"]] = confidence * 0.4
            emotion_vector[PlutchikModel.EMOTION_INDICES["fear"]] = confidence * 0.3
            emotion_vector[PlutchikModel.EMOTION_INDICES["disgust"]] = confidence * 0.2
        else:
            emotion_vector[PlutchikModel.EMOTION_INDICES["surprise"]] = confidence * 0.3
            emotion_vector[PlutchikModel.EMOTION_INDICES["trust"]] = confidence * 0.2
        
        total = sum(emotion_vector)
        if total > 0:
            emotion_vector = [e / total for e in emotion_vector]
        
        return emotion_vector
    
    @staticmethod
    def calculate_valence(emotion_vector: List[float]) -> float:
        valence = sum(
            emotion_vector[idx] * PlutchikModel.VALENCE_MAP[emotion]
            for idx, emotion in enumerate(PlutchikModel.EMOTIONS)
        )
        return max(-1.0, min(1.0, valence))
    
    @staticmethod
    def calculate_arousal(emotion_vector: List[float]) -> float:
        arousal = sum(
            emotion_vector[idx] * PlutchikModel.AROUSAL_MAP[emotion]
            for idx, emotion in enumerate(PlutchikModel.EMOTIONS)
        )
        return max(-1.0, min(1.0, arousal))
    
    @staticmethod
    def get_dominant_emotion(emotion_vector: List[float]) -> str:
        max_idx = np.argmax(emotion_vector)
        return PlutchikModel.EMOTIONS[max_idx]
    
    @staticmethod
    def normalize_emotion_vector(emotion_vector: List[float]) -> List[float]:
        total = sum(emotion_vector)
        if total == 0:
            return [0.0] * 8
        return [e / total for e in emotion_vector]

