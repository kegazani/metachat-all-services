import asyncio
import sys
import os
from pathlib import Path
from concurrent import futures

import grpc
from grpc import aio
import structlog

sys.path.insert(0, str(Path(__file__).parent.parent / "proto" / "generated"))

from src.config import Config
from src.infrastructure.database import Database
from src.infrastructure.repository import PersonalityRepository

logger = structlog.get_logger()

try:
    from personality_pb2 import GetProfileProgressRequest, GetProfileProgressResponse
    from personality_pb2_grpc import PersonalityServiceServicer, add_PersonalityServiceServicer_to_server
except ImportError:
    logger.warning("Proto files not generated. Run: python -m grpc_tools.protoc -I. --python_out=. --grpc_python_out=. proto/personality.proto")
    sys.exit(1)


class PersonalityServiceServicerImpl(PersonalityServiceServicer):
    def __init__(self, repository: PersonalityRepository, db: Database):
        self.repository = repository
        self.db = db
    
    async def GetProfileProgress(self, request: GetProfileProgressRequest, context) -> GetProfileProgressResponse:
        try:
            user_id = request.user_id
            logger.info("Getting profile progress", user_id=user_id)
            
            async for session in self.db.get_session():
                try:
                    progress = await self.repository.get_profile_progress(session, user_id)
                    if not progress:
                        context.set_code(grpc.StatusCode.NOT_FOUND)
                        context.set_details("User not found")
                        return GetProfileProgressResponse()
                    
                    return GetProfileProgressResponse(
                        tokens_analyzed=progress["tokens_analyzed"],
                        tokens_required_for_first=progress["tokens_required_for_first"],
                        tokens_required_for_recalc=progress["tokens_required_for_recalc"],
                        days_since_last_calc=progress["days_since_last_calc"],
                        days_until_recalc=progress["days_until_recalc"],
                        is_first_calculation=progress["is_first_calculation"],
                        progress_percentage=progress["progress_percentage"]
                    )
                finally:
                    await session.close()
        except Exception as e:
            logger.error("Error getting profile progress", error=str(e), exc_info=True)
            context.set_code(grpc.StatusCode.INTERNAL)
            context.set_details(f"Internal error: {str(e)}")
            return GetProfileProgressResponse()


async def serve():
    config = Config()
    
    db = Database(config.database_url)
    await db.initialize()
    
    repository = PersonalityRepository(db)
    
    server = aio.server(futures.ThreadPoolExecutor(max_workers=10))
    
    servicer = PersonalityServiceServicerImpl(repository, db)
    add_PersonalityServiceServicer_to_server(servicer, server)
    
    grpc_port = config.grpc_port
    listen_addr = f'0.0.0.0:{grpc_port}'
    server.add_insecure_port(listen_addr)
    
    logger.info("Starting gRPC server", port=grpc_port)
    await server.start()
    
    try:
        await server.wait_for_termination()
    except KeyboardInterrupt:
        logger.info("Shutting down gRPC server")
        await server.stop(5)


if __name__ == '__main__':
    asyncio.run(serve())

