# MetaChat - Flow Diagrams (Mermaid)

> **📚 Для более детального описания flow с пошаговыми инструкциями, временными характеристиками и техническими деталями см. [DETAILED_SERVICE_FLOW.md](./DETAILED_SERVICE_FLOW.md)**  
> **📊 Для расширенных диаграмм со всеми деталями см. [DETAILED_FLOW_DIAGRAMS.md](./DETAILED_FLOW_DIAGRAMS.md)**

## Общая архитектура системы

```mermaid
graph TB
    subgraph Client["📱 Flutter App"]
        Mobile[Mobile Client]
    end

    subgraph Gateway["🚪 API Gateway :8080"]
        GW[HTTP REST API]
    end

    subgraph CoreServices["🔧 Core Services"]
        US[User Service<br/>:50051 gRPC]
        DS[Diary Service<br/>:50052 gRPC]
        MS[Matching Service<br/>:50053 gRPC]
    end

    subgraph AIServices["🤖 AI/ML Services"]
        MAS[Mood Analysis<br/>:8081]
        PRS[Personality Service<br/>:8082]
        ANS[Analytics Service<br/>:8083]
    end

    subgraph DataServices["📊 Data Services"]
        BIO[Biometric Service<br/>:8084]
        COR[Correlation Service<br/>:8085]
    end

    subgraph MessageBus["📨 Kafka"]
        K[Message Broker<br/>:9092]
    end

    subgraph Storage["🗄️ Storage"]
        PG[(PostgreSQL<br/>Event Store)]
        CS[(Cassandra<br/>Read Models)]
        RD[(Redis<br/>Cache)]
    end

    Mobile --> GW
    GW --> US
    GW --> DS
    GW --> MS

    US --> K
    DS --> K
    K --> MAS
    K --> PRS
    K --> ANS
    K --> COR

    MAS --> K
    PRS --> K
    BIO --> K

    US --> PG
    DS --> PG
    US --> CS
    DS --> CS
    MAS --> PG
    PRS --> PG

    style Gateway fill:#e1f5fe
    style AIServices fill:#fff3e0
    style MessageBus fill:#f3e5f5
```

## Поток создания записи в дневнике

```mermaid
sequenceDiagram
    participant C as 📱 Client
    participant GW as 🚪 API Gateway
    participant DS as 📔 Diary Service
    participant K as 📨 Kafka
    participant MA as 🧠 Mood Analysis
    participant PR as 👤 Personality
    participant US as 👥 User Service

    C->>GW: POST /diary/entries
    GW->>DS: gRPC CreateDiaryEntry
    DS->>DS: Save to Event Store
    DS-->>GW: Entry Created
    GW-->>C: 201 Created
    
    DS->>K: publish diary.entry.created
    
    K->>MA: consume diary.entry.created
    MA->>MA: AI: Analyze Sentiment
    MA->>MA: Plutchik: Map to Emotions
    MA->>MA: Extract Topics & Keywords
    MA->>K: publish mood.analyzed
    
    K->>PR: consume mood.analyzed
    PR->>PR: Aggregate User Emotions
    PR->>PR: Update Topic Distribution
    PR->>PR: Check Recalculation Triggers
    
    alt Threshold Reached
        PR->>PR: AI: Classify Big Five
        PR->>K: publish personality.assigned
        K->>US: consume personality.assigned
        US->>US: Update User Profile
    end
```

## AI Pipeline - Mood Analysis

```mermaid
flowchart LR
    subgraph Input
        TEXT[📝 Diary Text]
    end

    subgraph Preprocessing
        CLEAN[Clean Text<br/>Remove URLs]
        TOKEN[Tokenize]
    end

    subgraph AIModel["🤖 AI Model"]
        TRANS[Transformer<br/>HuggingFace]
        SENT[Sentiment<br/>Score]
    end

    subgraph Plutchik["🎭 Plutchik Model"]
        EMO[8 Basic<br/>Emotions]
        VAL[Valence<br/>-1 to +1]
        ARO[Arousal<br/>-1 to +1]
    end

    subgraph TopicExtraction["📊 Topic Analysis"]
        KW[Keywords]
        TOP[Topics]
    end

    subgraph Output
        RESULT[✅ Analysis Result<br/>emotion_vector<br/>valence/arousal<br/>topics/keywords<br/>confidence]
    end

    TEXT --> CLEAN --> TOKEN --> TRANS --> SENT
    SENT --> EMO --> VAL
    EMO --> ARO
    TEXT --> KW --> TOP
    VAL --> RESULT
    ARO --> RESULT
    TOP --> RESULT
```

## AI Pipeline - Big Five Personality Classification

```mermaid
flowchart TB
    subgraph UserData["📊 User Historical Data"]
        ENTRIES[Diary Entries]
        MOODS[Mood Analyses]
        TOKENS[Token Count]
    end

    subgraph Aggregation["📈 Aggregation"]
        AGG_EMO[Averaged<br/>Emotion Vector]
        AGG_TOP[Topic<br/>Distribution]
        STYLE[Stylistic<br/>Metrics]
    end

    subgraph Classifier["🎯 Big Five Classifier"]
        CALC[Factor Calculation<br/>Openness: surprise, anticipation<br/>Conscientiousness: trust, work<br/>Extraversion: joy, social<br/>Agreeableness: trust, joy<br/>Neuroticism: fear, sadness, anger]
    end

    subgraph BigFive["👤 Big Five (OCEAN)"]
        O[Openness<br/>0.0-1.0]
        C[Conscientiousness<br/>0.0-1.0]
        E[Extraversion<br/>0.0-1.0]
        A[Agreeableness<br/>0.0-1.0]
        N[Neuroticism<br/>0.0-1.0]
    end

    subgraph Output
        RESULT[Big Five Scores<br/>+ Dominant Trait<br/>+ Confidence Score]
    end

    ENTRIES --> AGG_EMO
    MOODS --> AGG_EMO
    MOODS --> AGG_TOP
    ENTRIES --> STYLE
    TOKENS --> STYLE

    AGG_EMO --> CALC
    AGG_TOP --> CALC
    STYLE --> CALC

    CALC --> O & C & E & A & N

    O & C & E & A & N --> RESULT
```

## Kafka Event Flow

```mermaid
flowchart LR
    subgraph Producers["📤 Producers"]
        US_P[User Service]
        DS_P[Diary Service]
        MA_P[Mood Analysis]
        PR_P[Personality Service]
        BIO_P[Biometric Service]
    end

    subgraph Topics["📨 Kafka Topics"]
        T1[user-events]
        T2[diary.entry.created]
        T3[diary.entry.updated]
        T4[diary.entry.deleted]
        T5[mood.analyzed]
        T6[mood.analysis.failed]
        T7[personality.assigned]
        T8[personality.updated]
        T9[biometric.data.received]
        T10[correlation.discovered]
    end

    subgraph Consumers["📥 Consumers"]
        MA_C[Mood Analysis]
        PR_C[Personality Service]
        AN_C[Analytics Service]
        COR_C[Correlation Service]
    end

    US_P --> T1
    DS_P --> T2 & T3 & T4
    MA_P --> T5 & T6
    PR_P --> T7 & T8
    BIO_P --> T9

    T2 --> MA_C
    T3 --> MA_C
    T2 --> PR_C
    T5 --> PR_C
    T2 --> AN_C
    T4 --> AN_C
    T5 --> AN_C
    T8 --> AN_C
    T5 --> COR_C
    T9 --> COR_C
```

## Plutchik Emotion Wheel

```mermaid
pie title Emotion Vector Distribution Example
    "Joy" : 25
    "Trust" : 20
    "Fear" : 5
    "Surprise" : 10
    "Sadness" : 5
    "Disgust" : 3
    "Anger" : 7
    "Anticipation" : 25
```

## API Routes Map

```mermaid
graph TD
    subgraph AuthRoutes["🔐 /auth"]
        A1[POST /register]
        A2[POST /login]
        A3[POST /oauth/:provider]
    end

    subgraph UserRoutes["👤 /users"]
        U1[GET /:id]
        U2[PUT /:id]
        U3[GET /]
        U4[POST /:id/personality]
        U5[PUT /:id/personality]
        U6[PUT /:id/modalities]
    end

    subgraph DiaryRoutes["📔 /diary"]
        D1[POST /entries]
        D2[GET /entries/:id]
        D3[PUT /entries/:id]
        D4[DELETE /entries/:id]
        D5[GET /entries]
        D6[GET /entries/user/:userId]
        D7[POST /sessions]
        D8[GET /sessions/:id]
        D9[PUT /sessions/:id/end]
        D10[GET /analytics]
    end

    GW[API Gateway<br/>:8080]

    GW --> AuthRoutes
    GW --> UserRoutes
    GW --> DiaryRoutes

    AuthRoutes --> US[User Service]
    UserRoutes --> US
    DiaryRoutes --> DS[Diary Service]
```

## Personality (Big Five) Triggers

```mermaid
stateDiagram-v2
    [*] --> NoPersonality: New User

    NoPersonality --> CheckTokens: Diary Entry Created
    
    CheckTokens --> CalculatePersonality: tokens >= 50
    CheckTokens --> NoPersonality: tokens < 50
    
    CalculatePersonality --> HasPersonality: confidence >= 0.3
    CalculatePersonality --> NoPersonality: confidence < 0.3
    
    HasPersonality --> CheckRecalc: New Entry/Mood
    
    CheckRecalc --> RecalculatePersonality: tokens_since >= 100<br/>OR days >= 7
    CheckRecalc --> HasPersonality: No trigger
    
    RecalculatePersonality --> PersonalityUpdated: Scores changed
    RecalculatePersonality --> PersonalityStable: No significant change
    
    PersonalityUpdated --> HasPersonality
    PersonalityStable --> HasPersonality
```

## User Matching Algorithm

```mermaid
flowchart TB
    subgraph User1["👤 User A"]
        A_BF[Big Five: O=0.7, C=0.8, E=0.6, A=0.7, N=0.3]
        A_EMO[Emotion Vector]
        A_TOP[Topics: work, achievements]
    end

    subgraph User2["👤 User B"]
        B_BF[Big Five: O=0.6, C=0.9, E=0.5, A=0.8, N=0.2]
        B_EMO[Emotion Vector]
        B_TOP[Topics: work, fitness]
    end

    subgraph Similarity["📊 Similarity Calculation"]
        COS[Cosine Similarity<br/>Emotion Vectors]
        BF_SIM[Big Five Similarity<br/>Cosine Distance<br/>5 factors]
        TOP_O[Topic Overlap<br/>Jaccard Index]
    end

    subgraph Result["✅ Match Score"]
        FINAL[Final Score<br/>= 0.4 * COS<br/>+ 0.3 * BF_SIM<br/>+ 0.3 * TOP_O]
    end

    A_EMO --> COS
    B_EMO --> COS
    A_BF --> BF_SIM
    B_BF --> BF_SIM
    A_TOP --> TOP_O
    B_TOP --> TOP_O

    COS --> FINAL
    BF_SIM --> FINAL
    TOP_O --> FINAL
```

