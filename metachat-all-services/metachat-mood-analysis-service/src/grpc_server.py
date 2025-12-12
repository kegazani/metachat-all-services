import grpc
from datetime import datetime
from typing import Dict, Any

from loguru import logger

from src.domain.mood_analyzer import MoodAnalyzer
from src.proto import mood_analysis_pb2, mood_analysis_pb2_grpc


class MoodAnalysisServicer(mood_analysis_pb2_grpc.MoodAnalysisServicer):
    def __init__(self, mood_analyzer: MoodAnalyzer):
        self.mood_analyzer = mood_analyzer

    def AnalyzeText(self, request: mood_analysis_pb2.AnalyzeTextRequest, context: grpc.ServicerContext) -> mood_analysis_pb2.AnalyzeTextResponse:
        try:
            mood_scores = self.mood_analyzer.analyze_text(request.text)
            
            response = mood_analysis_pb2.AnalyzeTextResponse()
            
            for mood, score in mood_scores.items():
                mood_score = response.mood_scores.add()
                mood_score.mood = mood
                mood_score.score = score
            
            dominant_mood = max(mood_scores, key=mood_scores.get)
            response.dominant_mood = dominant_mood
            response.dominant_score = mood_scores[dominant_mood]
            
            return response
            
        except Exception as e:
            logger.error(f"Error in AnalyzeText: {str(e)}")
            context.set_code(grpc.StatusCode.INTERNAL)
            context.set_details(f"Internal error: {str(e)}")
            return mood_analysis_pb2.AnalyzeTextResponse()

    def GetUserMoodAggregation(self, request: mood_analysis_pb2.GetUserMoodAggregationRequest, context: grpc.ServicerContext) -> mood_analysis_pb2.GetUserMoodAggregationResponse:
        try:
            context.set_code(grpc.StatusCode.UNIMPLEMENTED)
            context.set_details("Use REST API /mood/aggregation/{user_id} endpoint instead. Data is stored in database.")
            return mood_analysis_pb2.GetUserMoodAggregationResponse()
            
        except Exception as e:
            logger.error(f"Error in GetUserMoodAggregation: {str(e)}")
            context.set_code(grpc.StatusCode.INTERNAL)
            context.set_details(f"Internal error: {str(e)}")
            return mood_analysis_pb2.GetUserMoodAggregationResponse()