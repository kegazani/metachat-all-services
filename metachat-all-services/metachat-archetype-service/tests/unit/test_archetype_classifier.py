import pytest
from src.domain.archetype_classifier import ArchetypeClassifier


def test_calculate_archetype_scores():
    classifier = ArchetypeClassifier()
    emotion_vector = [0.8, 0.3, 0.1, 0.2, 0.1, 0.0, 0.1, 0.4]
    topic_distribution = {"работа": 0.5, "хобби": 0.3}
    stylistic_metrics = {"average_entry_length": 300, "lexical_diversity": 0.6}
    
    scores = classifier.calculate_archetype_scores(
        emotion_vector, topic_distribution, stylistic_metrics, 0.6, 0.4
    )
    
    assert len(scores) == 12
    assert all(0 <= score <= 1 for score in scores.values())


def test_classify():
    classifier = ArchetypeClassifier()
    emotion_vector = [0.8, 0.3, 0.1, 0.2, 0.1, 0.0, 0.1, 0.4]
    topic_distribution = {"работа": 0.5}
    stylistic_metrics = {}
    
    archetype, probabilities, confidence = classifier.classify(
        emotion_vector, topic_distribution, stylistic_metrics, 0.6, 0.4
    )
    
    assert archetype in probabilities
    assert 0 <= confidence <= 1

