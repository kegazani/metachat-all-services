import pytest
from src.domain.plutchik_model import PlutchikModel


def test_map_sentiment_to_emotions_positive():
    emotions = PlutchikModel.map_sentiment_to_emotions("positive", 0.8)
    assert len(emotions) == 8
    assert emotions[0] > 0
    assert emotions[1] > 0


def test_calculate_valence():
    emotion_vector = [0.8, 0.3, 0.1, 0.2, 0.1, 0.0, 0.1, 0.4]
    valence = PlutchikModel.calculate_valence(emotion_vector)
    assert -1.0 <= valence <= 1.0


def test_get_dominant_emotion():
    emotion_vector = [0.8, 0.3, 0.1, 0.2, 0.1, 0.0, 0.1, 0.4]
    dominant = PlutchikModel.get_dominant_emotion(emotion_vector)
    assert dominant == "joy"

