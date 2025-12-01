from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, List

from src.api.app import app_state

router = APIRouter()


class AnalyzeRequest(BaseModel):
    text: str
    entry_id: Optional[str] = None
    user_id: Optional[str] = None
    tokens_count: int = 0


class AnalyzeResponse(BaseModel):
    entry_id: Optional[str]
    user_id: Optional[str]
    emotion_vector: List[float]
    dominant_emotion: str
    valence: float
    arousal: float
    confidence: float
    model_version: str
    tokens_count: int
    detected_topics: List[str]
    keywords: List[str]


class AnalysisResponse(BaseModel):
    id: str
    entry_id: str
    user_id: str
    emotion_vector: List[float]
    dominant_emotion: str
    valence: float
    arousal: float
    confidence: float
    model_version: str
    tokens_count: int
    detected_topics: List[str]
    keywords: List[str]
    analyzed_at: str


@router.post("/analyze", response_model=AnalyzeResponse)
async def analyze_text(request: AnalyzeRequest):
    try:
        mood_analyzer = app_state.get("mood_analyzer")
        if not mood_analyzer:
            raise HTTPException(status_code=503, detail="Service not ready")
        
        result = mood_analyzer.analyze(
            text=request.text,
            entry_id=request.entry_id or "temp",
            user_id=request.user_id or "temp",
            tokens_count=request.tokens_count
        )
        return AnalyzeResponse(**result)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/analysis/{entry_id}", response_model=AnalysisResponse)
async def get_analysis(entry_id: str):
    try:
        db = app_state.get("db")
        repository = app_state.get("repository")
        
        if not db or not repository:
            raise HTTPException(status_code=503, detail="Service not ready")
        
        async for session in db.get_session():
            analysis = await repository.get_by_entry_id(session, entry_id)
            if not analysis:
                raise HTTPException(status_code=404, detail="Analysis not found")
            
            return AnalysisResponse(
                id=analysis.id,
                entry_id=analysis.entry_id,
                user_id=analysis.user_id,
                emotion_vector=analysis.emotion_vector,
                dominant_emotion=analysis.dominant_emotion,
                valence=analysis.valence,
                arousal=analysis.arousal,
                confidence=analysis.confidence,
                model_version=analysis.model_version,
                tokens_count=analysis.tokens_count,
                detected_topics=analysis.detected_topics or [],
                keywords=analysis.keywords or [],
                analyzed_at=analysis.analyzed_at.isoformat()
            )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/health")
async def health_check():
    return {"status": "healthy", "service": "mood-analysis-service"}

