from typing import Dict, List
from enum import Enum


class Archetype(str, Enum):
    INNOCENT = "Innocent"
    SAGE = "Sage"
    EXPLORER = "Explorer"
    REBEL = "Rebel"
    MAGICIAN = "Magician"
    HERO = "Hero"
    LOVER = "Lover"
    JESTER = "Jester"
    EVERYMAN = "Everyman"
    CAREGIVER = "Caregiver"
    CREATOR = "Creator"
    RULER = "Ruler"


ARCHETYPE_PATTERNS: Dict[str, Dict] = {
    Archetype.INNOCENT: {
        "emotions": ["joy", "trust"],
        "topics": ["семья", "друзья", "хобби"],
        "valence": "positive",
        "arousal": "low",
        "style": {"length": "short", "complexity": "low"}
    },
    Archetype.SAGE: {
        "emotions": ["trust", "anticipation"],
        "topics": ["учеба", "работа"],
        "valence": "neutral",
        "arousal": "low",
        "style": {"length": "long", "complexity": "high"}
    },
    Archetype.EXPLORER: {
        "emotions": ["joy", "anticipation", "surprise"],
        "topics": ["путешествия", "хобби"],
        "valence": "positive",
        "arousal": "high",
        "style": {"length": "medium", "complexity": "medium"}
    },
    Archetype.REBEL: {
        "emotions": ["anger", "disgust"],
        "topics": ["работа", "стресс"],
        "valence": "negative",
        "arousal": "high",
        "style": {"length": "short", "complexity": "low"}
    },
    Archetype.MAGICIAN: {
        "emotions": ["anticipation", "surprise", "trust"],
        "topics": ["хобби", "работа"],
        "valence": "positive",
        "arousal": "medium",
        "style": {"length": "medium", "complexity": "high"}
    },
    Archetype.HERO: {
        "emotions": ["joy", "anticipation", "trust"],
        "topics": ["работа", "достижения"],
        "valence": "positive",
        "arousal": "high",
        "style": {"length": "medium", "complexity": "medium"}
    },
    Archetype.LOVER: {
        "emotions": ["joy", "trust", "anticipation"],
        "topics": ["отношения", "семья"],
        "valence": "positive",
        "arousal": "medium",
        "style": {"length": "medium", "complexity": "low"}
    },
    Archetype.JESTER: {
        "emotions": ["joy", "surprise"],
        "topics": ["друзья", "хобби"],
        "valence": "positive",
        "arousal": "high",
        "style": {"length": "short", "complexity": "low"}
    },
    Archetype.EVERYMAN: {
        "emotions": ["trust", "anticipation"],
        "topics": ["работа", "семья"],
        "valence": "neutral",
        "arousal": "low",
        "style": {"length": "medium", "complexity": "low"}
    },
    Archetype.CAREGIVER: {
        "emotions": ["trust", "joy"],
        "topics": ["семья", "друзья", "здоровье"],
        "valence": "positive",
        "arousal": "low",
        "style": {"length": "medium", "complexity": "medium"}
    },
    Archetype.CREATOR: {
        "emotions": ["joy", "anticipation", "trust"],
        "topics": ["хобби", "работа"],
        "valence": "positive",
        "arousal": "medium",
        "style": {"length": "long", "complexity": "high"}
    },
    Archetype.RULER: {
        "emotions": ["trust", "anticipation"],
        "topics": ["работа", "финансы"],
        "valence": "neutral",
        "arousal": "low",
        "style": {"length": "medium", "complexity": "medium"}
    }
}


def get_all_archetypes() -> List[str]:
    return [archetype.value for archetype in Archetype]

