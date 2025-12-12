Изучаю документацию в `docs` об AI-сервисах.


[5 tools called]


Сводка по AI-сервисам из документации:

## AI/ML сервисы (все кроме diary, user и gateway)

### 1. **Mood Analysis Service** (Python, Port 8081)
**Роль:** Анализ настроения из записей дневника

**Технологии:**
- Transformer модель (HuggingFace)
- Plutchik Model (8 базовых эмоций)
- Topic Analyzer

**Поток обработки:**
```
Text Input → Preprocessing → Transformer Model → Sentiment Score → 
Plutchik Model → Emotion Vector [8 float values] → Topic Analyzer → 
Output (emotion_vector, valence, arousal, topics, keywords, confidence)
```

**8 базовых эмоций (Plutchik):**
- joy (Радость)
- trust (Доверие)
- fear (Страх)
- surprise (Удивление)
- sadness (Грусть)
- disgust (Отвращение)
- anger (Гнев)
- anticipation (Предвкушение)

**Kafka:**
- Потребляет: `metachat.diary.entry.created`, `metachat.diary.entry.updated`
- Публикует: `metachat.mood.analyzed`, `metachat.mood.analysis.failed`

---

### 2. **Personality Service (Big Five)** (Python, Port 8082)
**Роль:** Классификация пользователей по модели Big Five (OCEAN)

**Технологии:**
- Big Five Classifier
- NumPy для вычислений

**5 факторов личности (Big Five / OCEAN):**
- **Openness (O)** - Открытость опыту (0.0-1.0)
- **Conscientiousness (C)** - Добросовестность (0.0-1.0)
- **Extraversion (E)** - Экстраверсия (0.0-1.0)
- **Agreeableness (A)** - Доброжелательность (0.0-1.0)
- **Neuroticism (N)** - Нейротизм (0.0-1.0)

**Алгоритм классификации:**
```
Factor Calculation:
  Openness: surprise, anticipation, creative topics
  Conscientiousness: trust, work topics, entry length
  Extraversion: joy, surprise, social topics, high arousal
  Agreeableness: trust, joy, social topics, low negative emotions
  Neuroticism: fear, sadness, anger, stress topics
```

**Триггеры пересчета:**
- Первый расчет: 50 токенов
- Пересчет: каждые 100 токенов или каждые 7 дней
- Минимальная уверенность: 0.3

**Kafka:**
- Потребляет: `metachat.mood.analyzed`, `metachat.diary.entry.created`
- Публикует: `metachat.personality.assigned`, `metachat.personality.updated`, `metachat.personality.calculation.triggered`

---

### 3. **Analytics Service** (Python, Port 8083)
**Роль:** Сбор и агрегация статистики

**Kafka (Consumer only):**
- Потребляет: `metachat.mood.analyzed`, `metachat.diary.entry.created`, `metachat.diary.entry.deleted`, `metachat.personality.updated`

---

### 4. **Biometric Service** (Python, Port 8084)
**Роль:** Обработка биометрических данных

**API Endpoints:**
- `POST /biometric/data` - Прием биометрических данных
- `GET /biometric/data/{user_id}` - Получение данных пользователя

**Метрики:**
- heart_rate (пульс)
- sleep_data (данные сна)
- activity (активность)

**Kafka:**
- Публикует: `metachat.biometric.data.received`

**Хранение:** PostgreSQL

---

### 5. **Correlation Service** (Python, Port 8085)
**Роль:** Обнаружение корреляций между настроением и биометрией

**Технологии:**
- NumPy, SciPy для статистического анализа
- Pearson correlation

**Типы корреляций:**
- `heart_rate_valence` - Корреляция пульса и валентности настроения
- `sleep_arousal` - Корреляция сна и уровня возбуждения
- `activity_valence` - Корреляция активности и валентности

**Требования для анализа:**
- Минимум 14 дней данных
- Минимум 10+ записей
- Значимость: p-value < 0.05, |r| > 0.3

**Kafka:**
- Потребляет: `metachat.mood.analyzed`, `metachat.biometric.data.received`
- Публикует: `metachat.correlation.discovered`

**Реализация:**
- Кэширование данных настроения и биометрии для каждого пользователя
- Автоматическое обнаружение значимых корреляций

---

## Полный поток AI обработки

```
1. Пользователь создает запись → Diary Service
2. Diary Service → Kafka: diary.entry.created
3. Mood Analysis Service → AI анализ текста → Kafka: mood.analyzed
4. Personality Service → AI классификация (Big Five) → Kafka: personality.updated
5. Analytics Service → сбор статистики
6. Biometric Service → обработка биометрии → Kafka: biometric.data.received
7. Correlation Service → статистический анализ корреляций → Kafka: correlation.discovered
```

Все AI-сервисы написаны на Python с использованием FastAPI, работают через Kafka и взаимодействуют с основными сервисами (User, Diary) через события.