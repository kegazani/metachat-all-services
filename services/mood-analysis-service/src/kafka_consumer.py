import json
import threading
import time
from datetime import datetime
from typing import Dict, Any

from confluent_kafka import Consumer, KafkaException, TopicPartition
from loguru import logger

from src.config import Config
from src.mood_analyzer import MoodAnalyzer
from src.kafka_producer import KafkaProducer


class KafkaConsumer:
    def __init__(self, config: Config, mood_analyzer: MoodAnalyzer, kafka_producer: KafkaProducer):
        self.config = config
        self.mood_analyzer = mood_analyzer
        self.kafka_producer = kafka_producer
        
        # Kafka consumer configuration
        self.consumer_config = {
            'bootstrap.servers': ','.join(config.kafka_brokers),
            'group.id': config.kafka_consumer_group,
            'auto.offset.reset': 'earliest',
            'enable.auto.commit': False
        }
        
        # Topics to subscribe to
        self.topics = [
            config.diary_entry_created_topic,
            config.diary_entry_updated_topic
        ]
        
        # Consumer instance
        self.consumer = None
        
        # Running flag
        self.running = False
        
        # Thread for consuming messages
        self.consumer_thread = None
        
        logger.info("KafkaConsumer initialized")

    def start(self):
        """Start the Kafka consumer."""
        if self.running:
            logger.warning("Kafka consumer is already running")
            return
        
        try:
            # Create consumer
            self.consumer = Consumer(self.consumer_config)
            
            # Subscribe to topics
            self.consumer.subscribe(self.topics)
            
            # Set running flag
            self.running = True
            
            # Start consumer thread
            self.consumer_thread = threading.Thread(target=self._consume_messages)
            self.consumer_thread.daemon = True
            self.consumer_thread.start()
            
            logger.info(f"Kafka consumer started, subscribed to topics: {', '.join(self.topics)}")
            
        except KafkaException as e:
            logger.error(f"Failed to start Kafka consumer: {e}")
            raise

    def stop(self):
        """Stop the Kafka consumer."""
        if not self.running:
            logger.warning("Kafka consumer is not running")
            return
        
        # Set running flag to False
        self.running = False
        
        # Wait for consumer thread to finish
        if self.consumer_thread and self.consumer_thread.is_alive():
            self.consumer_thread.join(timeout=5)
        
        # Close consumer
        if self.consumer:
            self.consumer.close()
        
        logger.info("Kafka consumer stopped")

    def _consume_messages(self):
        """Consume messages from Kafka."""
        try:
            while self.running:
                # Poll for messages
                msg = self.consumer.poll(timeout=1.0)
                
                if msg is None:
                    continue
                
                if msg.error():
                    logger.error(f"Consumer error: {msg.error()}")
                    continue
                
                # Process message
                try:
                    self._process_message(msg)
                    
                    # Commit offset
                    self.consumer.commit(asynchronous=False)
                    
                except Exception as e:
                    logger.error(f"Error processing message: {e}")
                    # Continue processing other messages
                    
        except Exception as e:
            logger.error(f"Error in consumer thread: {e}")
        finally:
            if self.consumer:
                self.consumer.close()

    def _process_message(self, msg):
        """Process a single Kafka message."""
        try:
            # Decode message value
            value = msg.value().decode('utf-8')
            
            # Parse JSON
            data = json.loads(value)
            
            # Get topic
            topic = msg.topic()
            
            # Process based on topic
            if topic == self.config.diary_entry_created_topic:
                self._process_diary_entry_created(data)
            elif topic == self.config.diary_entry_updated_topic:
                self._process_diary_entry_updated(data)
            else:
                logger.warning(f"Received message from unknown topic: {topic}")
                
        except json.JSONDecodeError as e:
            logger.error(f"Failed to decode JSON: {e}")
        except Exception as e:
            logger.error(f"Error processing message: {e}")

    def _process_diary_entry_created(self, data: Dict[str, Any]):
        """Process a DiaryEntryCreated event."""
        try:
            # Extract required fields
            user_id = data.get('user_id')
            diary_id = data.get('diary_id')
            content = data.get('content')
            timestamp_str = data.get('created_at')
            
            if not all([user_id, diary_id, content, timestamp_str]):
                logger.error(f"Missing required fields in DiaryEntryCreated event: {data}")
                return
            
            # Parse timestamp
            timestamp = datetime.fromisoformat(timestamp_str.replace('Z', '+00:00'))
            
            # Analyze diary entry
            mood_result = self.mood_analyzer.analyze_diary_entry(user_id, diary_id, content, timestamp)
            
            # Publish MoodAnalyzed event
            self.kafka_producer.publish_mood_analyzed(mood_result)
            
            logger.info(f"Processed DiaryEntryCreated event for diary {diary_id}")
            
        except Exception as e:
            logger.error(f"Error processing DiaryEntryCreated event: {e}")

    def _process_diary_entry_updated(self, data: Dict[str, Any]):
        """Process a DiaryEntryUpdated event."""
        try:
            # Extract required fields
            user_id = data.get('user_id')
            diary_id = data.get('diary_id')
            content = data.get('content')
            timestamp_str = data.get('updated_at')
            
            if not all([user_id, diary_id, content, timestamp_str]):
                logger.error(f"Missing required fields in DiaryEntryUpdated event: {data}")
                return
            
            # Parse timestamp
            timestamp = datetime.fromisoformat(timestamp_str.replace('Z', '+00:00'))
            
            # Analyze diary entry
            mood_result = self.mood_analyzer.analyze_diary_entry(user_id, diary_id, content, timestamp)
            
            # Publish MoodAnalyzed event
            self.kafka_producer.publish_mood_analyzed(mood_result)
            
            logger.info(f"Processed DiaryEntryUpdated event for diary {diary_id}")
            
        except Exception as e:
            logger.error(f"Error processing DiaryEntryUpdated event: {e}")