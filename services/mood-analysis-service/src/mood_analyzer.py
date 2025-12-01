import json
import time
from datetime import datetime, timedelta
from typing import Dict, List, Tuple, Optional
import torch
import numpy as np
import pandas as pd
from transformers import AutoTokenizer, AutoModelForSequenceClassification
from loguru import logger

from src.config import Config


class MoodAnalyzer:
    def __init__(self, config: Config):
        self.config = config
        self.model_name = config.model_name
        self.model_cache_dir = config.model_cache_dir
        
        # Load model and tokenizer
        logger.info(f"Loading model {self.model_name}")
        self.tokenizer = AutoTokenizer.from_pretrained(self.model_name, cache_dir=self.model_cache_dir)
        self.model = AutoModelForSequenceClassification.from_pretrained(self.model_name, cache_dir=self.model_cache_dir)
        
        # Move model to GPU if available
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        self.model.to(self.device)
        
        # Mood labels (this should match the model's output)
        self.mood_labels = [
            "joy", "sadness", "anger", "fear", "surprise", "disgust", "neutral"
        ]
        
        # User mood data cache for aggregation
        self.user_mood_cache = {}
        
        logger.info("MoodAnalyzer initialized")

    def analyze_text(self, text: str) -> Dict[str, float]:
        """
        Analyze the mood of the given text.
        
        Args:
            text: The text to analyze
            
        Returns:
            A dictionary mapping mood labels to confidence scores
        """
        # Tokenize input text
        inputs = self.tokenizer(text, return_tensors="pt", truncation=True, padding=True, max_length=512)
        inputs = {k: v.to(self.device) for k, v in inputs.items()}
        
        # Run inference
        with torch.no_grad():
            outputs = self.model(**inputs)
        
        # Get probabilities
        probabilities = torch.nn.functional.softmax(outputs.logits, dim=-1)[0]
        
        # Convert to dictionary
        mood_scores = {label: float(prob) for label, prob in zip(self.mood_labels, probabilities)}
        
        return mood_scores

    def analyze_diary_entry(self, user_id: str, diary_id: str, text: str, timestamp: datetime) -> Dict:
        """
        Analyze a diary entry and update user mood data.
        
        Args:
            user_id: The ID of the user
            diary_id: The ID of the diary entry
            text: The text of the diary entry
            timestamp: The timestamp of the diary entry
            
        Returns:
            A dictionary containing the mood analysis results
        """
        # Analyze text mood
        mood_scores = self.analyze_text(text)
        
        # Get dominant mood
        dominant_mood = max(mood_scores, key=mood_scores.get)
        dominant_score = mood_scores[dominant_mood]
        
        # Create result
        result = {
            "user_id": user_id,
            "diary_id": diary_id,
            "timestamp": timestamp.isoformat(),
            "mood_scores": mood_scores,
            "dominant_mood": dominant_mood,
            "dominant_score": dominant_score
        }
        
        # Update user mood cache
        self._update_user_mood_cache(user_id, result)
        
        return result

    def get_user_mood_aggregation(self, user_id: str, time_range: str = "day") -> Dict:
        """
        Get aggregated mood data for a user over a time range.
        
        Args:
            user_id: The ID of the user
            time_range: The time range to aggregate ("day", "week", "month")
            
        Returns:
            A dictionary containing aggregated mood data
        """
        if user_id not in self.user_mood_cache:
            return {"error": "No mood data available for this user"}
        
        # Get current time
        now = datetime.now()
        
        # Calculate start time based on time range
        if time_range == "day":
            start_time = now - timedelta(days=1)
        elif time_range == "week":
            start_time = now - timedelta(weeks=1)
        elif time_range == "month":
            start_time = now - timedelta(days=30)
        else:
            return {"error": "Invalid time range. Use 'day', 'week', or 'month'."}
        
        # Filter entries by time range
        entries = [
            entry for entry in self.user_mood_cache[user_id]
            if datetime.fromisoformat(entry["timestamp"]) >= start_time
        ]
        
        if not entries:
            return {"error": f"No mood data available for the specified {time_range}"}
        
        # Aggregate mood scores
        mood_aggregations = {}
        for mood in self.mood_labels:
            scores = [entry["mood_scores"][mood] for entry in entries]
            mood_aggregations[mood] = {
                "average": np.mean(scores),
                "max": np.max(scores),
                "min": np.min(scores),
                "count": len(scores)
            }
        
        # Calculate dominant mood frequency
        dominant_moods = [entry["dominant_mood"] for entry in entries]
        dominant_mood_counts = pd.Series(dominant_moods).value_counts().to_dict()
        
        # Create result
        result = {
            "user_id": user_id,
            "time_range": time_range,
            "start_time": start_time.isoformat(),
            "end_time": now.isoformat(),
            "entry_count": len(entries),
            "mood_aggregations": mood_aggregations,
            "dominant_mood_counts": dominant_mood_counts,
            "overall_dominant_mood": max(dominant_mood_counts, key=dominant_mood_counts.get) if dominant_mood_counts else None
        }
        
        return result

    def _update_user_mood_cache(self, user_id: str, mood_result: Dict):
        """
        Update the user mood cache with a new mood result.
        
        Args:
            user_id: The ID of the user
            mood_result: The mood analysis result
        """
        if user_id not in self.user_mood_cache:
            self.user_mood_cache[user_id] = []
        
        self.user_mood_cache[user_id].append(mood_result)
        
        # Limit cache size to prevent memory issues (keep last 1000 entries)
        if len(self.user_mood_cache[user_id]) > 1000:
            self.user_mood_cache[user_id] = self.user_mood_cache[user_id][-1000:]