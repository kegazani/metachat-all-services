from typing import Dict, List, Optional
import numpy as np
from datetime import datetime

from src.domain.archetypes import ARCHETYPE_PATTERNS, get_all_archetypes
import structlog

logger = structlog.get_logger()


class ArchetypeClassifier:
    def __init__(self):
        self.archetypes = get_all_archetypes()
    
    def calculate_archetype_scores(
        self,
        emotion_vector: List[float],
        topic_distribution: Dict[str, float],
        stylistic_metrics: Dict[str, float],
        valence: float,
        arousal: float
    ) -> Dict[str, float]:
        scores = {}
        
        emotion_names = ["joy", "trust", "fear", "surprise", "sadness", "disgust", "anger", "anticipation"]
        emotion_dict = {name: emotion_vector[i] for i, name in enumerate(emotion_names)}
        
        for archetype_name in self.archetypes:
            pattern = ARCHETYPE_PATTERNS[archetype_name]
            score = 0.0
            
            emotion_score = self._match_emotions(emotion_dict, pattern["emotions"])
            topic_score = self._match_topics(topic_distribution, pattern["topics"])
            valence_score = self._match_valence(valence, pattern["valence"])
            arousal_score = self._match_arousal(arousal, pattern["arousal"])
            style_score = self._match_style(stylistic_metrics, pattern["style"])
            
            score = (
                emotion_score * 0.3 +
                topic_score * 0.25 +
                valence_score * 0.15 +
                arousal_score * 0.15 +
                style_score * 0.15
            )
            
            scores[archetype_name] = score
        
        total = sum(scores.values())
        if total > 0:
            scores = {k: v / total for k, v in scores.items()}
        
        return scores
    
    def _match_emotions(self, emotion_dict: Dict[str, float], pattern_emotions: List[str]) -> float:
        if not pattern_emotions:
            return 0.0
        
        scores = [emotion_dict.get(emotion, 0.0) for emotion in pattern_emotions]
        return np.mean(scores) if scores else 0.0
    
    def _match_topics(self, topic_distribution: Dict[str, float], pattern_topics: List[str]) -> float:
        if not pattern_topics or not topic_distribution:
            return 0.0
        
        scores = [topic_distribution.get(topic, 0.0) for topic in pattern_topics]
        return np.mean(scores) if scores else 0.0
    
    def _match_valence(self, valence: float, pattern_valence: str) -> float:
        if pattern_valence == "positive":
            return max(0.0, valence)
        elif pattern_valence == "negative":
            return max(0.0, -valence)
        else:
            return 1.0 - abs(valence)
    
    def _match_arousal(self, arousal: float, pattern_arousal: str) -> float:
        if pattern_arousal == "high":
            return max(0.0, arousal)
        elif pattern_arousal == "low":
            return max(0.0, -arousal)
        else:
            return 1.0 - abs(arousal)
    
    def _match_style(self, stylistic_metrics: Dict[str, float], pattern_style: Dict[str, str]) -> float:
        if not stylistic_metrics:
            return 0.5
        
        score = 0.0
        count = 0
        
        if "length" in pattern_style:
            avg_length = stylistic_metrics.get("average_entry_length", 0)
            pattern_length = pattern_style["length"]
            
            if pattern_length == "short" and avg_length < 200:
                score += 1.0
            elif pattern_length == "medium" and 200 <= avg_length < 500:
                score += 1.0
            elif pattern_length == "long" and avg_length >= 500:
                score += 1.0
            count += 1
        
        if "complexity" in pattern_style:
            complexity = stylistic_metrics.get("lexical_diversity", 0)
            pattern_complexity = pattern_style["complexity"]
            
            if pattern_complexity == "low" and complexity < 0.5:
                score += 1.0
            elif pattern_complexity == "medium" and 0.5 <= complexity < 0.7:
                score += 1.0
            elif pattern_complexity == "high" and complexity >= 0.7:
                score += 1.0
            count += 1
        
        return score / count if count > 0 else 0.5
    
    def classify(
        self,
        emotion_vector: List[float],
        topic_distribution: Dict[str, float],
        stylistic_metrics: Dict[str, float],
        valence: float,
        arousal: float
    ) -> tuple[str, Dict[str, float], float]:
        scores = self.calculate_archetype_scores(
            emotion_vector,
            topic_distribution,
            stylistic_metrics,
            valence,
            arousal
        )
        
        sorted_scores = sorted(scores.items(), key=lambda x: x[1], reverse=True)
        dominant_archetype = sorted_scores[0][0]
        top_score = sorted_scores[0][1]
        
        if len(sorted_scores) > 1:
            second_score = sorted_scores[1][1]
            gap = top_score - second_score
            avg_score = np.mean([s[1] for s in sorted_scores])
            
            gap_ratio = gap / max(top_score, 0.001) if top_score > 0 else 0.0
            
            base_multiplier = 2.0 + gap_ratio * 2.0
            
            confidence = min(1.0, top_score * base_multiplier + gap * 2.0)
            
            if gap_ratio > 0.5:
                confidence = max(confidence, 0.4)
            elif gap_ratio > 0.3:
                confidence = max(confidence, 0.35)
            elif gap_ratio > 0.15:
                confidence = max(confidence, 0.3)
            
            if top_score > 0.12:
                confidence = max(confidence, 0.3)
            
            confidence = min(1.0, confidence)
        else:
            confidence = top_score
        
        return dominant_archetype, scores, confidence

