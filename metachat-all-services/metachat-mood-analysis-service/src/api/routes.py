from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, List

from src.api.state import app_state

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
        db = app_state.get("db")
        repository = app_state.get("repository")
        
        if not mood_analyzer:
            raise HTTPException(status_code=503, detail="Service not ready")
        
        entry_id = request.entry_id or "temp"
        user_id = request.user_id or "temp"
        
        result = mood_analyzer.analyze(
            text=request.text,
            entry_id=entry_id,
            user_id=user_id,
            tokens_count=request.tokens_count
        )
        
        if db and repository and entry_id != "temp" and user_id != "temp":
            try:
                async with db.async_session_maker() as session:
                    existing = await repository.get_by_entry_id(session, entry_id)
                    if existing:
                        await session.delete(existing)
                        await session.commit()
                    
                    saved_analysis = await repository.save_analysis(session, result)
                    
                    emotion_vector = list(saved_analysis.emotion_vector) if saved_analysis.emotion_vector else []
                    detected_topics = list(saved_analysis.detected_topics) if saved_analysis.detected_topics else []
                    keywords = list(saved_analysis.keywords) if saved_analysis.keywords else []
                    
                    return AnalyzeResponse(
                        entry_id=saved_analysis.entry_id,
                        user_id=saved_analysis.user_id,
                        emotion_vector=emotion_vector,
                        dominant_emotion=saved_analysis.dominant_emotion,
                        valence=float(saved_analysis.valence),
                        arousal=float(saved_analysis.arousal),
                        confidence=float(saved_analysis.confidence),
                        model_version=saved_analysis.model_version,
                        tokens_count=int(saved_analysis.tokens_count),
                        detected_topics=detected_topics,
                        keywords=keywords
                    )
            except Exception as e:
                pass
        
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
        
        async with db.async_session_maker() as session:
            analysis = await repository.get_by_entry_id(session, entry_id)
            if not analysis:
                raise HTTPException(status_code=404, detail="Analysis not found")
            
            emotion_vector = list(analysis.emotion_vector) if analysis.emotion_vector else []
            detected_topics = list(analysis.detected_topics) if analysis.detected_topics else []
            keywords = list(analysis.keywords) if analysis.keywords else []
            
            return AnalysisResponse(
                id=analysis.id,
                entry_id=analysis.entry_id,
                user_id=analysis.user_id,
                emotion_vector=emotion_vector,
                dominant_emotion=analysis.dominant_emotion,
                valence=float(analysis.valence),
                arousal=float(analysis.arousal),
                confidence=float(analysis.confidence),
                model_version=analysis.model_version,
                tokens_count=int(analysis.tokens_count),
                detected_topics=detected_topics,
                keywords=keywords,
                analyzed_at=analysis.analyzed_at.isoformat()
            )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/health")
async def health_check():
    return {"status": "healthy", "service": "mood-analysis-service"}

