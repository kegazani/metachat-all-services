import grpc
from datetime import datetime
from typing import Dict, Any

from loguru import logger

from src.mood_analyzer import MoodAnalyzer
from src.proto import mood_analysis_pb2, mood_analysis_pb2_grpc


class MoodAnalysisServicer(mood_analysis_pb2_grpc.MoodAnalysisServicer):
    def __init__(self, mood_analyzer: MoodAnalyzer):
        self.mood_analyzer = mood_analyzer

    def AnalyzeText(self, request: mood_analysis_pb2.AnalyzeTextRequest, context: grpc.ServicerContext) -> mood_analysis_pb2.AnalyzeTextResponse:
        """
        Analyze the mood of the given text.
        """
        try:
            # Analyze text mood
            mood_scores = self.mood_analyzer.analyze_text(request.text)
            
            # Create response
            response = mood_analysis_pb2.AnalyzeTextResponse()
            
            # Set mood scores
            for mood, score in mood_scores.items():
                mood_score = response.mood_scores.add()
                mood_score.mood = mood
                mood_score.score = score
            
            # Set dominant mood
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
        """
        Get aggregated mood data for a user over a time range.
        """
        try:
            # Get user mood aggregation
            aggregation = self.mood_analyzer.get_user_mood_aggregation(request.user_id, request.time_range)
            
            # Check for error
            if "error" in aggregation:
                context.set_code(grpc.StatusCode.NOT_FOUND)
                context.set_details(aggregation["error"])
                return mood_analysis_pb2.GetUserMoodAggregationResponse()
            
            # Create response
            response = mood_analysis_pb2.GetUserMoodAggregationResponse()
            response.user_id = aggregation["user_id"]
            response.time_range = aggregation["time_range"]
            response.start_time = aggregation["start_time"]
            response.end_time = aggregation["end_time"]
            response.entry_count = aggregation["entry_count"]
            
            # Set mood aggregations
            for mood, agg in aggregation["mood_aggregations"].items():
                mood_agg = response.mood_aggregations.add()
                mood_agg.mood = mood
                mood_agg.average = agg["average"]
                mood_agg.max = agg["max"]
                mood_agg.min = agg["min"]
                mood_agg.count = agg["count"]
            
            # Set dominant mood counts
            for mood, count in aggregation["dominant_mood_counts"].items():
                dominant_mood_count = response.dominant_mood_counts.add()
                dominant_mood_count.mood = mood
                dominant_mood_count.count = count
            
            # Set overall dominant mood
            if aggregation["overall_dominant_mood"]:
                response.overall_dominant_mood = aggregation["overall_dominant_mood"]
            
            return response
            
        except Exception as e:
            logger.error(f"Error in GetUserMoodAggregation: {str(e)}")
            context.set_code(grpc.StatusCode.INTERNAL)
            context.set_details(f"Internal error: {str(e)}")
            return mood_analysis_pb2.GetUserMoodAggregationResponse()