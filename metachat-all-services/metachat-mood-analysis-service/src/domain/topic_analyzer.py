from typing import List, Dict
import re
from collections import Counter
import structlog

logger = structlog.get_logger()


class TopicAnalyzer:
    def __init__(self, topics_dictionary: List[str]):
        self.topics_dictionary = topics_dictionary
        self._build_topic_keywords()
        self._build_stop_words()
    
    def _build_stop_words(self):
        self.stop_words = {
            "этот", "это", "как", "что", "который", "когда", "где", "почему", 
            "очень", "было", "был", "была", "были", "будет", "будут", "будь",
            "все", "всего", "всегда", "всех", "всею", "всю", "всё",
            "для", "или", "под", "над", "при", "про", "со", "то", "та",
            "так", "там", "тем", "те", "ту", "ты", "уже", "чем", "чтобы",
            "меня", "мне", "мной", "тебя", "тебе", "тобой", "его", "ему", "им",
            "её", "ей", "ею", "нас", "нам", "нами", "вас", "вам", "вами",
            "них", "ним", "ними", "себя", "себе", "собой",
            "кто", "кого", "кому", "кем", "чем",
            "мой", "моя", "мое", "мои", "твой", "твоя", "твое", "твои",
            "наш", "наша", "наше", "наши", "ваш", "ваша", "ваше", "ваши",
            "их", "его", "её",
            "не", "ни", "да", "нет", "даже", "тоже", "только", "уже",
            "вот", "тут", "там", "здесь", "туда", "сюда", "оттуда", "отсюда",
            "сегодня", "вчера", "завтра", "сейчас", "потом", "теперь",
            "может", "можно", "нужно", "надо", "должен", "должна", "должно", "должны",
            "the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for",
            "of", "with", "by", "from", "as", "is", "was", "were", "be", "been",
            "have", "has", "had", "do", "does", "did", "will", "would", "should",
            "could", "may", "might", "must", "can", "this", "that", "these", "those",
            "i", "you", "he", "she", "it", "we", "they", "me", "him", "her", "us", "them",
            "my", "your", "his", "her", "its", "our", "their", "mine", "yours", "hers", "ours", "theirs",
            "what", "which", "who", "whom", "whose", "where", "when", "why", "how",
            "all", "each", "every", "both", "few", "many", "most", "other", "some", "such",
            "no", "nor", "not", "only", "own", "same", "so", "than", "too", "very",
            "about", "into", "through", "during", "before", "after", "above", "below", "up", "down",
            "out", "off", "over", "under", "again", "further", "then", "once", "here", "there",
            "when", "where", "why", "how", "all", "any", "both", "each", "few", "more",
            "most", "other", "some", "such", "no", "nor", "not", "only", "own", "same",
            "so", "than", "too", "very", "can", "will", "just", "should", "now"
        }
    
    def _build_topic_keywords(self):
        self.topic_keywords = {
            "работа": [
                "работа", "рабочий", "работать", "работаю", "работает", "работали",
                "коллеги", "коллега", "начальник", "начальница", "босс", "руководитель",
                "проект", "проекты", "задача", "задачи", "дедлайн", "дедлайны",
                "офис", "офисный", "зарплата", "зарплату", "зарплаты",
                "карьера", "должность", "должности", "компания", "компании",
                "трудовой", "труд", "труда", "профессия", "профессии",
                "клиент", "клиенты", "встреча", "встречи", "совещание", "совещания",
                "план", "планы", "отчет", "отчеты", "презентация", "презентации"
            ],
            "отношения": [
                "любовь", "любить", "люблю", "любит", "любил", "любила",
                "партнер", "партнерша", "партнеры", "отношения", "отношение",
                "свидание", "свидания", "романтика", "романтический", "романтическая",
                "семья", "семейный", "семейная", "брак", "браке", "браке",
                "встречаться", "встречаюсь", "встречается", "встречались",
                "вместе", "пара", "пары", "дружба", "дружбы",
                "чувства", "чувство", "чувствую", "чувствует", "чувствовал",
                "сердце", "сердца", "душа", "души", "эмоции", "эмоция"
            ],
            "здоровье": [
                "здоровье", "здоровый", "здоровая", "здоровые", "здоров",
                "болезнь", "болезни", "болею", "болеет", "болел", "болела",
                "врач", "врача", "врачи", "доктор", "доктора", "докторы",
                "лечение", "лечусь", "лечится", "лечился", "лечилась",
                "боль", "боли", "болит", "болело", "болела",
                "симптом", "симптомы", "симптомы", "признак", "признаки",
                "лекарство", "лекарства", "таблетка", "таблетки", "медицина",
                "больница", "больницы", "поликлиника", "поликлиники",
                "анализ", "анализы", "обследование", "обследования",
                "диагноз", "диагнозы", "терапия", "терапии"
            ],
            "семья": [
                "семья", "семейный", "семейная", "семейные",
                "родители", "родитель", "мама", "маму", "мамы", "матери",
                "папа", "папу", "папы", "отца", "отец", "отцом",
                "брат", "брата", "братья", "сестра", "сестры", "сестре",
                "родственники", "родственник", "родственница", "родня",
                "дети", "ребенок", "ребенка", "детей", "сын", "сына", "дочь", "дочери",
                "бабушка", "бабушки", "дедушка", "дедушки",
                "домашний", "домашняя", "дом", "дома", "дому"
            ],
            "друзья": [
                "друзья", "друг", "друга", "друзей", "друзьям",
                "подруга", "подруги", "подругу", "подруге",
                "встреча", "встречи", "встречаюсь", "встречается", "встречались",
                "общение", "общаюсь", "общается", "общались", "общался",
                "компания", "компании", "компанию", "в компании",
                "вечеринка", "вечеринки", "вечеринку", "тусовка", "тусовки",
                "время", "времени", "провожу", "проводим", "проводили",
                "разговор", "разговоры", "беседа", "беседы", "беседую"
            ],
            "финансы": [
                "деньги", "денег", "деньгам", "деньгами",
                "зарплата", "зарплату", "зарплаты", "зарплате",
                "покупка", "покупки", "покупаю", "покупает", "покупал", "покупала",
                "трата", "траты", "трачу", "тратит", "тратил", "тратила",
                "бюджет", "бюджета", "бюджете", "бюджеты",
                "кредит", "кредита", "кредиты", "кредиту",
                "долг", "долга", "долги", "долгу", "должен", "должна",
                "экономия", "экономлю", "экономит", "экономил",
                "платеж", "платежи", "плачу", "платит", "платил",
                "счет", "счета", "счета", "счету", "счетами",
                "банк", "банка", "банки", "банку", "банковский"
            ],
            "хобби": [
                "хобби", "увлечение", "увлечения", "увлекаюсь", "увлекается",
                "интерес", "интересы", "интересуюсь", "интересуется",
                "занятие", "занятия", "занимаюсь", "занимается", "занимался",
                "творчество", "творческий", "творческая", "творю", "творит",
                "спорт", "спортивный", "спортивная", "тренировка", "тренировки",
                "музыка", "музыкальный", "музыкальная", "играю", "играет",
                "книги", "книга", "книгу", "читаю", "читает", "читал", "читала",
                "фильм", "фильмы", "кино", "смотрю", "смотрит", "смотрел",
                "рисую", "рисует", "рисовал", "рисование", "рисования"
            ],
            "стресс": [
                "стресс", "стресса", "стрессу", "стрессовый",
                "напряжение", "напряжения", "напряженный", "напряженная",
                "тревога", "тревоги", "тревожный", "тревожная", "тревожусь",
                "беспокойство", "беспокоюсь", "беспокоится", "беспокоился",
                "паника", "паники", "паникую", "паникует", "паниковал",
                "нервы", "нервный", "нервная", "нервничаю", "нервничает",
                "усталость", "устал", "устала", "устали", "устаю", "устает",
                "усталый", "усталая", "усталые", "утомлен", "утомлена",
                "проблема", "проблемы", "сложно", "сложный", "сложная",
                "трудно", "трудный", "трудная", "тяжело", "тяжелый", "тяжелая"
            ],
            "учеба": [
                "учеба", "учусь", "учится", "учился", "училась",
                "университет", "университета", "университете", "университеты",
                "экзамен", "экзамена", "экзамены", "экзамену", "экзаменам",
                "зачет", "зачета", "зачеты", "зачету", "зачетам",
                "лекция", "лекции", "лекцию", "лекций",
                "студент", "студента", "студенты", "студентка", "студентки",
                "образование", "образования", "образовательный",
                "учитель", "учителя", "учителя", "преподаватель", "преподавателя",
                "урок", "уроки", "урока", "уроков", "занятие", "занятия",
                "диплом", "диплома", "дипломы", "диссертация", "диссертации"
            ],
            "путешествия": [
                "путешествие", "путешествия", "путешествую", "путешествует",
                "поездка", "поездки", "поездку", "поездке", "ездил", "ездила",
                "отпуск", "отпуска", "отпуску", "отпуске", "отдых", "отдыха",
                "отдыхаю", "отдыхает", "отдыхал", "отдыхала",
                "поезд", "поезда", "самолет", "самолета", "самолеты",
                "отель", "отеля", "отели", "гостиница", "гостиницы",
                "страна", "страны", "страну", "город", "города", "городе",
                "море", "моря", "пляж", "пляжа", "пляжи",
                "билет", "билеты", "билета", "виза", "визы"
            ]
        }
    
    def _normalize_word(self, word: str) -> str:
        word = word.lower().strip()
        word = re.sub(r'[^\w\s]', '', word)
        return word
    
    def _extract_words(self, text: str) -> List[str]:
        text_clean = re.sub(r'[^\w\s]', ' ', text.lower())
        russian_words = re.findall(r'\b[а-яё]{3,}\b', text_clean)
        english_words = re.findall(r'\b[a-z]{3,}\b', text_clean)
        return russian_words + english_words
    
    def extract_topics(self, text: str) -> List[str]:
        if not text or not text.strip():
            logger.debug("extract_topics: empty text")
            return []
        
        text_lower = text.lower()
        text_words = set(self._extract_words(text))
        text_full = text_lower
        
        logger.debug(
            "extract_topics: processing",
            text_length=len(text),
            text_words_count=len(text_words),
            text_preview=text[:50]
        )
        
        if not text_words and not text_full:
            logger.debug("extract_topics: no words extracted")
            return []
        
        topic_scores = {}
        
        for topic in self.topics_dictionary:
            keywords = self.topic_keywords.get(topic, [])
            if not keywords:
                continue
            
            keyword_set = set(keyword.lower() for keyword in keywords)
            word_matches = len(text_words.intersection(keyword_set))
            
            substring_matches = 0
            for keyword in keywords:
                keyword_lower = keyword.lower()
                if keyword_lower in text_full and keyword_lower not in text_words:
                    substring_matches += 1
            
            total_matches = word_matches + substring_matches
            
            if total_matches > 0:
                score = total_matches / max(len(keywords), 1)
                topic_scores[topic] = (score, total_matches)
                logger.debug(
                    "extract_topics: topic matched",
                    topic=topic,
                    matches=total_matches,
                    score=score
                )
        
        if not topic_scores:
            logger.debug("extract_topics: no topics matched")
            return []
        
        sorted_topics = sorted(topic_scores.items(), key=lambda x: (x[1][1], x[1][0]), reverse=True)
        
        detected_topics = [topic for topic, (score, matches) in sorted_topics if matches >= 1]
        
        logger.debug(
            "extract_topics: result",
            detected_topics=detected_topics,
            count=len(detected_topics)
        )
        
        return detected_topics[:5] if detected_topics else []
    
    def extract_keywords(self, text: str, max_keywords: int = 10) -> List[str]:
        if not text or not text.strip():
            return []
        
        words = self._extract_words(text)
        
        if not words:
            return []
        
        word_freq = Counter(words)
        
        filtered_words = [
            (word, freq) for word, freq in word_freq.items() 
            if word not in self.stop_words and len(word) >= 3
        ]
        
        if not filtered_words:
            return []
        
        filtered_words.sort(key=lambda x: (x[1], len(x[0])), reverse=True)
        
        keywords = [word for word, _ in filtered_words[:max_keywords]]
        
        return keywords if keywords else []
    
    def calculate_topic_scores(self, text: str) -> Dict[str, float]:
        if not text or not text.strip():
            return {topic: 0.0 for topic in self.topics_dictionary}
        
        text_words = set(self._extract_words(text))
        scores = {}
        
        for topic in self.topics_dictionary:
            keywords = self.topic_keywords.get(topic, [])
            if not keywords:
                scores[topic] = 0.0
                continue
            
            keyword_set = set(keyword.lower() for keyword in keywords)
            matches = len(text_words.intersection(keyword_set))
            scores[topic] = min(1.0, matches / len(keywords)) if keywords else 0.0
        
        return scores
