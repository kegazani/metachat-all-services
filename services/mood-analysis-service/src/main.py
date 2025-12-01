import os
import sys
import signal
import time
from concurrent import futures

import grpc
from dotenv import load_dotenv
from loguru import logger

from src.grpc_server import MoodAnalysisServicer
from src.kafka_consumer import KafkaConsumer
from src.kafka_producer import KafkaProducer
from src.mood_analyzer import MoodAnalyzer
from src.config import Config

def main():
    # Load environment variables
    load_dotenv()

    # Load configuration
    config = Config()

    # Initialize logger
    logger.remove()
    logger.add(sys.stderr, level=config.log_level)

    # Initialize components
    mood_analyzer = MoodAnalyzer(config)
    kafka_producer = KafkaProducer(config)
    kafka_consumer = KafkaConsumer(config, mood_analyzer, kafka_producer)

    # Start gRPC server
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    mood_analysis_servicer = MoodAnalysisServicer(mood_analyzer)
    
    # Add servicer to server
    from src.proto import mood_analysis_pb2_grpc
    mood_analysis_pb2_grpc.add_MoodAnalysisServicer_to_server(mood_analysis_servicer, server)
    
    # Start server
    server.add_insecure_port(f"[::]:{config.grpc_port}")
    logger.info(f"Starting gRPC server on port {config.grpc_port}")
    server.start()

    # Start Kafka consumer
    logger.info("Starting Kafka consumer")
    kafka_consumer.start()

    # Graceful shutdown
    def shutdown(signum, frame):
        logger.info("Shutting down...")
        kafka_consumer.stop()
        server.stop(5)  # 5 seconds grace period
        sys.exit(0)

    signal.signal(signal.SIGINT, shutdown)
    signal.signal(signal.SIGTERM, shutdown)

    try:
        while True:
            time.sleep(86400)  # Sleep for a day
    except KeyboardInterrupt:
        shutdown(None, None)

if __name__ == "__main__":
    main()