# MetaChat Services Deployment Guide

This guide explains how to deploy MetaChat microservices with isolated common modules.

## Overview

MetaChat project has been restructured to support deployment of services as isolated containers with shared common modules. The project now uses:

- **Separate Go modules** for common components
- **Docker containers** for each service
- **Git repositories** for version control of common modules

## Architecture

```
metachat/
├── common/event-sourcing/          # Event sourcing common module
├── config/logging/                # Logging configuration module
├── metachat/proto/generated/        # Generated protobuf module
├── services/
│   ├── user-service/            # User microservice
│   ├── diary-service/           # Diary microservice
│   ├── api-gateway/             # API Gateway
│   ├── matching-service/         # Matching microservice
│   └── mood-analysis-service/    # Mood analysis service (Python)
└── scripts/                       # Build and deployment scripts
```

## Common Modules

### 1. Event Sourcing Module (`common/event-sourcing`)
- **Module**: `github.com/metachat/common/event-sourcing`
- **Purpose**: Event sourcing infrastructure
- **Components**:
  - Aggregates (User, Diary)
  - Events
  - Serializers
  - Event stores

### 2. Logging Module (`config/logging`)
- **Module**: `github.com/metachat/config/logging`
- **Purpose**: Centralized logging configuration
- **Components**:
  - Logrus configuration
  - Structured logging

### 3. Protobuf Module (`metachat/proto/generated`)
- **Module**: `github.com/metachat/proto/generated`
- **Purpose**: Generated gRPC protobuf files
- **Components**:
  - User service protobuf
  - Diary service protobuf

## Services

### 1. User Service
- **Port**: 8080 (HTTP), 50051 (gRPC)
- **Database**: Cassandra
- **Dependencies**: EventStore, Kafka
- **Module**: `metachat/user-service`

### 2. Diary Service
- **Port**: 8080 (HTTP), 50051 (gRPC)
- **Database**: Cassandra
- **Dependencies**: EventStore, Kafka
- **Module**: `metachat/diary-service`

### 3. API Gateway
- **Port**: 8080 (HTTP)
- **Dependencies**: User Service, Diary Service
- **Module**: `metachat/api-gateway`

## Deployment Options

### Option 1: Local Development with Replace Directives

For local development, use the setup script to configure replace directives:

```bash
./scripts/setup-local-dev.sh
```

This will configure `go.mod` files to use local replace directives:
```go
replace github.com/metachat/common/event-sourcing => ../../common/event-sourcing
replace github.com/metachat/config/logging => ../../config/logging
replace github.com/metachat/proto/generated => ../../metachat/proto/generated
```

### Option 2: Production Deployment with External Modules

For production deployment, publish common modules to Git repositories:

```bash
# Setup Git repositories
./scripts/setup-git-repos.sh

# Build and publish common modules
./scripts/build-common-modules.sh

# Update service go.mod files to remove replace directives
# Deploy services using docker-compose.isolated.yml
```

## Build and Deployment Scripts

### 1. `scripts/setup-local-dev.sh`
Configures local development environment with replace directives.

### 2. `scripts/setup-git-repos.sh`
Initializes Git repositories for common modules and creates version tags.

### 3. `scripts/build-common-modules.sh`
Builds Docker images for common modules.

### 4. `scripts/update-imports.sh`
Updates import paths in all Go files to use new module names.

### 5. `scripts/generate-proto.sh`
Regenerates protobuf files from .proto definitions.

## Docker Deployment

### Local Development
```bash
# Build all services
docker-compose -f docker-compose.yml up --build
```

### Production Deployment
```bash
# Build and deploy isolated services
docker-compose -f docker-compose.isolated.yml up --build
```

## Service Dependencies

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   API Gateway   │    │   User Service  │    │  Diary Service  │
│   (8080)       │    │   (8080,50051) │    │  (8080,50051) │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼─────────────────────┘
                                 │
                    ┌─────────────────┐    ┌─────────────────┐
                    │  EventStoreDB   │    │    Cassandra     │
                    │   (2113,1113)   │    │    (9042)      │
                    └─────────────────┘    └─────────────────┘
                                 │                       │
                                 └─────────────────────┼─────────────────────┘
                                                         │
                                            ┌─────────────────┐
                                            │     Kafka       │
                                            │    (9092)      │
                                            └─────────────────┘
```

## Environment Variables

### User Service
- `EVENTSTORE_URL`: EventStoreDB connection URL
- `CASSANDRA_HOSTS`: Cassandra hosts
- `KAFKA_BROKERS`: Kafka broker URLs
- `JWT_SECRET`: JWT signing secret

### Diary Service
- `EVENTSTORE_URL`: EventStoreDB connection URL
- `CASSANDRA_HOSTS`: Cassandra hosts
- `KAFKA_BROKERS`: Kafka broker URLs

### API Gateway
- `USER_SERVICE_URL`: User service gRPC URL
- `DIARY_SERVICE_URL`: Diary service gRPC URL

## Monitoring and Logging

All services use structured logging with:
- **Format**: JSON
- **Level**: Configurable via environment
- **Output**: Standard output
- **Correlation IDs**: For request tracing

## Health Checks

Each service exposes health endpoints:
- `/health` - Basic health check
- `/ready` - Readiness check
- `/metrics` - Prometheus metrics

## Scaling Considerations

### Horizontal Scaling
- Stateless services can be scaled horizontally
- Use load balancer for API Gateway
- Consider database connection pooling

### Vertical Scaling
- Increase resource limits in docker-compose.yml
- Monitor resource usage with Prometheus
- Consider service-specific optimizations

## Troubleshooting

### Common Issues
1. **Module Import Errors**: Ensure common modules are properly published
2. **Database Connection**: Check network connectivity
3. **gRPC Communication**: Verify service discovery
4. **Kafka Messages**: Check topic configuration

### Debug Commands
```bash
# Check service logs
docker-compose logs [service-name]

# Enter service container
docker-compose exec [service-name] sh

# Test service connectivity
docker-compose exec user-service curl localhost:8080/health
```

## Security Considerations

1. **Network Isolation**: Use Docker networks
2. **Secrets Management**: Use environment variables
3. **TLS Configuration**: Enable for production
4. **Access Control**: Implement authentication/authorization

## Backup and Recovery

1. **Database Backups**: Regular Cassandra snapshots
2. **Event Store Backups**: EventStoreDB backups
3. **Configuration Backup**: Version control all configs
4. **Disaster Recovery**: Document recovery procedures

## Performance Optimization

1. **Connection Pooling**: Database and gRPC connections
2. **Caching**: Implement where appropriate
3. **Async Processing**: Use Kafka for event streaming
4. **Resource Monitoring**: Track CPU, memory, I/O