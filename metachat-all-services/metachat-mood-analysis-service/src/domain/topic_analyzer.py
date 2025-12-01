from typing import List, Dict
import re
from collections import Counter
from sklearn.feature_extraction.text import TfidfVectorizer
import numpy as np


class TopicAnalyzer:
    def __init__(self, topics_dictionary: List[str]):
        self.topics_dictionary = topics_dictionary
        self.vectorizer = TfidfVectorizer(
            max_features=100,
            ngram_range=(1, 2),
            stop_words=None
        )
        self._build_topic_keywords()
    
    def _build_topic_keywords(self):
        self.topic_keywords = {
            "работа": ["работа", "рабочий", "коллеги", "начальник", "проект", "задача", "дедлайн", "офис", "зарплата"],
            "отношения": ["любовь", "партнер", "отношения", "свидание", "романтика", "семья", "брак"],
            "здоровье": ["здоровье", "болезнь", "врач", "лечение", "боль", "симптом", "лекарство", "больница"],
            "семья": ["семья", "родители", "мама", "папа", "брат", "сестра", "родственники", "дети"],
            "друзья": ["друзья", "друг", "подруга", "встреча", "общение", "компания", "вечеринка"],
            "финансы": ["деньги", "зарплата", "покупка", "трата", "бюджет", "кредит", "долг", "экономия"],
            "хобби": ["хобби", "увлечение", "интерес", "занятие", "творчество", "спорт", "музыка", "книги"],
            "стресс": ["стресс", "напряжение", "тревога", "беспокойство", "паника", "нервы", "усталость"],
            "учеба": ["учеба", "университет", "экзамен", "зачет", "лекция", "студент", "образование"],
            "путешествия": ["путешествие", "поездка", "отпуск", "отпуск", "отпуск", "отпуск", "отпуск"]
        }
    
    def extract_topics(self, text: str) -> List[str]:
        text_lower = text.lower()
        detected_topics = []
        
        for topic in self.topics_dictionary:
            keywords = self.topic_keywords.get(topic, [])
            matches = sum(1 for keyword in keywords if keyword in text_lower)
            if matches >= 2:
                detected_topics.append(topic)
        
        return detected_topics[:5]
    
    def extract_keywords(self, text: str, max_keywords: int = 10) -> List[str]:
        words = re.findall(r'\b[а-яё]{4,}\b', text.lower())
        word_freq = Counter(words)
        common_words = {"этот", "это", "как", "что", "который", "когда", "где", "почему", "очень", "было", "был", "была", "были"}
        
        filtered_words = [(word, freq) for word, freq in word_freq.items() if word not in common_words]
        filtered_words.sort(key=lambda x: x[1], reverse=True)
        
        return [word for word, _ in filtered_words[:max_keywords]]
    
    def calculate_topic_scores(self, text: str) -> Dict[str, float]:
        scores = {}
        text_lower = text.lower()
        
        for topic in self.topics_dictionary:
            keywords = self.topic_keywords.get(topic, [])
            if not keywords:
                scores[topic] = 0.0
                continue
            
            matches = sum(1 for keyword in keywords if keyword in text_lower)
            scores[topic] = min(1.0, matches / len(keywords)) if keywords else 0.0
        
        return scores

