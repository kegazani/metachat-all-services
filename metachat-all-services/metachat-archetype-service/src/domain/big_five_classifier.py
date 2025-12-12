from typing import Dict, List
import numpy as np
import structlog

logger = structlog.get_logger()


class BigFiveClassifier:
    BIG_FIVE_FACTORS = ["openness", "conscientiousness", "extraversion", "agreeableness", "neuroticism"]
    
    def __init__(self):
        pass
    
    def calculate_big_five_scores(
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
        
        openness = self._calculate_openness(emotion_dict, topic_distribution, stylistic_metrics, valence)
        conscientiousness = self._calculate_conscientiousness(emotion_dict, topic_distribution, stylistic_metrics, valence)
        extraversion = self._calculate_extraversion(emotion_dict, topic_distribution, arousal)
        agreeableness = self._calculate_agreeableness(emotion_dict, topic_distribution, valence)
        neuroticism = self._calculate_neuroticism(emotion_dict, topic_distribution, valence, arousal)
        
        scores["openness"] = max(0.0, min(1.0, openness))
        scores["conscientiousness"] = max(0.0, min(1.0, conscientiousness))
        scores["extraversion"] = max(0.0, min(1.0, extraversion))
        scores["agreeableness"] = max(0.0, min(1.0, agreeableness))
        scores["neuroticism"] = max(0.0, min(1.0, neuroticism))
        
        return scores
    
    def _calculate_openness(
        self,
        emotion_dict: Dict[str, float],
        topic_distribution: Dict[str, float],
        stylistic_metrics: Dict[str, float],
        valence: float
    ) -> float:
        score = 0.0
        
        surprise_score = emotion_dict.get("surprise", 0.0) * 0.3
        anticipation_score = emotion_dict.get("anticipation", 0.0) * 0.2
        
        creative_topics = ["хобби", "путешествия", "учеба"]
        creative_score = sum([topic_distribution.get(topic, 0.0) for topic in creative_topics]) * 0.2
        
        complexity = stylistic_metrics.get("lexical_diversity", 0.5)
        complexity_score = complexity * 0.2
        
        positive_valence = max(0.0, valence) * 0.1
        
        score = surprise_score + anticipation_score + creative_score + complexity_score + positive_valence
        
        return min(1.0, score)
    
    def _calculate_conscientiousness(
        self,
        emotion_dict: Dict[str, float],
        topic_distribution: Dict[str, float],
        stylistic_metrics: Dict[str, float],
        valence: float
    ) -> float:
        score = 0.0
        
        trust_score = emotion_dict.get("trust", 0.0) * 0.25
        
        work_topics = ["работа", "учеба", "достижения"]
        work_score = sum([topic_distribution.get(topic, 0.0) for topic in work_topics]) * 0.3
        
        avg_length = stylistic_metrics.get("average_entry_length", 0)
        length_score = min(1.0, avg_length / 500.0) * 0.25
        
        positive_valence = max(0.0, valence) * 0.2
        
        score = trust_score + work_score + length_score + positive_valence
        
        return min(1.0, score)
    
    def _calculate_extraversion(
        self,
        emotion_dict: Dict[str, float],
        topic_distribution: Dict[str, float],
        arousal: float
    ) -> float:
        score = 0.0
        
        joy_score = emotion_dict.get("joy", 0.0) * 0.3
        surprise_score = emotion_dict.get("surprise", 0.0) * 0.2
        
        social_topics = ["друзья", "отношения", "семья"]
        social_score = sum([topic_distribution.get(topic, 0.0) for topic in social_topics]) * 0.3
        
        high_arousal = max(0.0, arousal) * 0.2
        
        score = joy_score + surprise_score + social_score + high_arousal
        
        return min(1.0, score)
    
    def _calculate_agreeableness(
        self,
        emotion_dict: Dict[str, float],
        topic_distribution: Dict[str, float],
        valence: float
    ) -> float:
        score = 0.0
        
        trust_score = emotion_dict.get("trust", 0.0) * 0.3
        joy_score = emotion_dict.get("joy", 0.0) * 0.2
        
        social_topics = ["семья", "друзья", "отношения"]
        social_score = sum([topic_distribution.get(topic, 0.0) for topic in social_topics]) * 0.3
        
        negative_emotions = emotion_dict.get("anger", 0.0) + emotion_dict.get("disgust", 0.0)
        negative_penalty = negative_emotions * 0.2
        
        positive_valence = max(0.0, valence) * 0.2
        
        score = trust_score + joy_score + social_score + positive_valence - negative_penalty
        
        return max(0.0, min(1.0, score))
    
    def _calculate_neuroticism(
        self,
        emotion_dict: Dict[str, float],
        topic_distribution: Dict[str, float],
        valence: float,
        arousal: float
    ) -> float:
        score = 0.0
        
        fear_score = emotion_dict.get("fear", 0.0) * 0.3
        sadness_score = emotion_dict.get("sadness", 0.0) * 0.25
        anger_score = emotion_dict.get("anger", 0.0) * 0.2
        
        stress_topics = ["стресс", "работа"]
        stress_score = sum([topic_distribution.get(topic, 0.0) for topic in stress_topics]) * 0.15
        
        negative_valence = max(0.0, -valence) * 0.1
        
        score = fear_score + sadness_score + anger_score + stress_score + negative_valence
        
        return min(1.0, score)
    
    def classify(
        self,
        emotion_vector: List[float],
        topic_distribution: Dict[str, float],
        stylistic_metrics: Dict[str, float],
        valence: float,
        arousal: float
    ) -> Dict[str, float]:
        scores = self.calculate_big_five_scores(
            emotion_vector,
            topic_distribution,
            stylistic_metrics,
            valence,
            arousal
        )
        
        return scores
    
    def get_dominant_trait(self, scores: Dict[str, float]) -> str:
        return max(scores.items(), key=lambda x: x[1])[0]
    
    def calculate_confidence(self, scores: Dict[str, float]) -> float:
        variance = np.var(list(scores.values()))
        max_score = max(scores.values())
        min_score = min(scores.values())
        
        spread = max_score - min_score
        confidence = min(1.0, spread * 0.5 + variance * 2.0)
        
        return max(0.3, confidence)

