# MetaChat Platform

MetaChat is a distributed microservices platform for AI-powered diary and journaling with user profiling and archetype analysis.

## Architecture

The platform consists of the following main components:

### Services

1. **User Service**: Manages user profiles, archetypes, and modalities (gRPC)
2. **Diary Service**: Handles diary entries, sessions, and content analysis (gRPC)
3. **API Gateway**: Handles all HTTP requests and forwards them to backend services via gRPC

### Data Stores

1. **Event Store**: PostgreSQL database for event sourcing
2. **Read Models**: Cassandra database for optimized read operations
3. **Message Broker**: Apache Kafka for event-driven communication

### Monitoring & Observability

1. **ELK Stack**: Elasticsearch, Logstash, and Kibana for centralized logging
2. **Prometheus**: Metrics collection and alerting
3. **Grafana**: Dashboards for monitoring and business metrics
4. **Alertmanager**: Alert routing and management

## Quick Start

### Prerequisites

- Docker and Docker Compose
- Go 1.19+
- Make (optional, for using Makefile)

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/your-org/metachat.git
   cd metachat
   ```

2. Start the services:
   ```bash
   # Use the simplified docker-compose file
   docker-compose -f docker-compose.simple.yml up -d
   ```

3. Access Points:
   - **API Gateway**: http://localhost:8080 (HTTP API for all services)
   - **User Service (gRPC)**: localhost:50051
   - **Diary Service (gRPC)**: localhost:50052
   - **Kibana**: http://localhost:5601
   - **Grafana**: http://localhost:3000 (admin/admin)
   - **Prometheus**: http://localhost:9090
   - **Alertmanager**: http://localhost:9093

## API Documentation

All HTTP requests are handled by the API Gateway on port 8080. The gateway forwards requests to backend services via gRPC.

### User Service (gRPC on port 50051)

#### Create User
```
POST /users
Content-Type: application/json

{
  "username": "johndoe",
  "email": "john@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "dateOfBirth": "1990-01-01"
}
```

#### Get User by ID
```
GET /users/{id}
```

#### Update User Profile
```
PUT /users/{id}
Content-Type: application/json

{
  "firstName": "John",
  "lastName": "Doe",
  "dateOfBirth": "1990-01-01",
  "avatar": "base64-encoded-image",
  "bio": "Software developer and AI enthusiast"
}
```

#### Assign Archetype
```
POST /users/{id}/archetype
Content-Type: application/json

{
  "archetypeId": "thinker",
  "archetypeName": "The Thinker",
  "confidence": 0.85,
  "description": "Analytical and introspective personality type"
}
```

#### Update Archetype
```
PUT /users/{id}/archetype
Content-Type: application/json

{
  "archetypeId": "thinker",
  "archetypeName": "The Thinker",
  "confidence": 0.90,
  "description": "Updated description"
}
```

#### Update Modalities
```
PUT /users/{id}/modalities
Content-Type: application/json

{
  "modalities": {
    "visual": 0.8,
    "auditory": 0.6,
    "kinesthetic": 0.4
  }
}
```

#### List Users
```
GET /users?page=1&limit=10
```

### Diary Service (gRPC on port 50052)

#### Create Diary Entry
```
POST /diary/entries
Content-Type: application/json

{
  "userId": "user-id",
  "title": "My First Entry",
  "content": "Today was a good day...",
  "tokenCount": 150,
  "sessionId": "session-id",
  "tags": ["reflection", "gratitude"]
}
```

#### Get Diary Entry by ID
```
GET /diary/entries/{id}
```

#### Update Diary Entry
```
PUT /diary/entries/{id}
Content-Type: application/json

{
  "title": "Updated Title",
  "content": "Updated content...",
  "tokenCount": 200,
  "tags": ["reflection", "gratitude", "growth"]
}
```

#### Delete Diary Entry
```
DELETE /diary/entries/{id}
```

#### Start Diary Session
```
POST /diary/sessions
Content-Type: application/json

{
  "userId": "user-id",
  "startTime": "2023-01-01T10:00:00Z"
}
```

#### End Diary Session
```
PUT /diary/sessions/{id}/end
Content-Type: application/json

{
  "endTime": "2023-01-01T11:00:00Z"
}
```

#### Get Diary Session by ID
```
GET /diary/sessions/{id}
```

#### Get Diary Entries by User ID
```
GET /diary/entries/user/{userId}
```

#### Get Diary Sessions by User ID
```
GET /diary/sessions/user/{userId}
```

#### Get Diary Entries by User ID and Time Range
```
GET /diary/entries/user/{userId}?startTime=2023-01-01&endTime=2023-12-31
```

#### Get Diary Analytics
```
GET /diary/analytics?userId={userId}&period=week
```

## Development

### Project Structure

```
metachat/
├── services/
│   ├── user-service/
│   │   ├── cmd/
│   │   ├── internal/
│   │   │   ├── grpc/
│   │   │   ├── kafka/
│   │   │   ├── metrics/
│   │   │   ├── models/
│   │   │   ├── repository/
│   │   │   └── service/
│   │   └── go.mod
│   ├── diary-service/
│   │   ├── cmd/
│   │   ├── internal/
│   │   │   ├── grpc/
│   │   │   ├── kafka/
│   │   │   ├── metrics/
│   │   │   ├── models/
│   │   │   ├── repository/
│   │   │   └── service/
│   │   └── go.mod
│   └── api-gateway/
│       ├── cmd/
│       ├── internal/
│       │   ├── handlers/
│       │   └── service/
│       └── go.mod
├── proto/
│   ├── user.proto
│   ├── diary.proto
│   └── gateway.proto
├── common/
│   └── event-sourcing/
├── config/
│   ├── logging/
│   ├── prometheus/
│   ├── alertmanager/
│   ├── grafana/
│   └── logstash/
├── docker-compose.simple.yml
├── docker-compose.infrastructure.yml
├── docker-compose.monitoring.yml
├── docker-compose.elk.yml
└── Makefile
```

### Running Tests

```bash
# Run all tests
make test

# Run tests for a specific service
make test-user-service
make test-diary-service

# Run tests with coverage
make test-coverage
```

### Building and Deployment

```bash
# Build all services
make build

# Build a specific service
make build-user-service
make build-diary-service

# Build Docker images
make docker-build

# Deploy to Kubernetes
make deploy
```

## Monitoring and Observability

### Metrics

The platform exposes the following metrics:

#### Service Metrics
- HTTP request rate, latency, and error rate (API Gateway)
- gRPC request rate, latency, and error rate (Backend Services)
- Database operation latency and error rate
- Kafka message production and consumption rate

#### Business Metrics
- User creation and update rate
- Archetype assignment rate
- Diary entry creation, update, and deletion rate
- Diary session start and end rate

### Logging

All services use structured logging with the following fields:
- `timestamp`: Event timestamp
- `level`: Log level (debug, info, warn, error)
- `service`: Service name
- `environment`: Environment (dev, staging, prod)
- `message`: Log message
- `fields`: Additional context-specific fields

Logs are shipped to Elasticsearch via Logstash and can be viewed in Kibana.

### Alerting

The platform is configured with the following alerts:

#### Service Alerts
- Service down
- High error rate (>5%)
- High latency (95th percentile > 500ms)

#### Database Alerts
- Cassandra down
- High pending compactions

#### Message Broker Alerts
- Kafka down
- Under-replicated partitions

Alerts are routed via Alertmanager and can be configured to send notifications via email, Slack, PagerDuty, etc.

## Event Sourcing

The platform uses event sourcing to capture all changes to application state as a sequence of events. This provides:

- Complete audit history
- Temporal queries (state at any point in time)
- Decoupling of read and write models
- Scalability through event-driven architecture

### Events

#### User Events
- `UserCreated`: Emitted when a new user is created
- `UserProfileUpdated`: Emitted when a user's profile is updated
- `ArchetypeAssigned`: Emitted when an archetype is assigned to a user
- `ArchetypeUpdated`: Emitted when a user's archetype is updated
- `ModalitiesUpdated`: Emitted when a user's modalities are updated

#### Diary Events
- `DiaryEntryCreated`: Emitted when a new diary entry is created
- `DiaryEntryUpdated`: Emitted when a diary entry is updated
- `DiaryEntryDeleted`: Emitted when a diary entry is deleted
- `DiarySessionStarted`: Emitted when a diary session is started
- `DiarySessionEnded`: Emitted when a diary session is ended

### Read Models

Read models are optimized views of the data for efficient querying. They are updated asynchronously by consuming events from Kafka.

#### User Read Models
- `UserReadModel`: User profile information
- `UserArchetypeReadModel`: User archetype information
- `UserModalityReadModel`: User modality information

#### Diary Read Models
- `DiaryEntryReadModel`: Diary entry information
- `DiarySessionReadModel`: Diary session information

## Configuration

### Environment Variables

#### API Gateway
- `PORT`: Service port (default: 8080)
- `USER_SERVICE_ADDRESS`: User service gRPC address (default: localhost:50051)
- `DIARY_SERVICE_ADDRESS`: Diary service gRPC address (default: localhost:50052)
- `LOG_LEVEL`: Log level (debug, info, warn, error)
- `LOG_FORMAT`: Log format (json, text)
- `LOG_OUTPUT`: Log output (stdout, file path)
- `ENVIRONMENT`: Environment (dev, staging, prod)

#### User Service
- `PORT`: Service port (default: 50051)
- `DB_HOST`: Event store database host
- `DB_PORT`: Event store database port
- `DB_USER`: Event store database user
- `DB_PASSWORD`: Event store database password
- `DB_NAME`: Event store database name
- `CASSANDRA_HOSTS`: Cassandra hosts (comma-separated)
- `CASSANDRA_KEYSPACE`: Cassandra keyspace
- `KAFKA_BOOTSTRAP_SERVERS`: Kafka bootstrap servers
- `KAFKA_USER_EVENTS_TOPIC`: Kafka topic for user events
- `LOG_LEVEL`: Log level (debug, info, warn, error)
- `LOG_FORMAT`: Log format (json, text)
- `LOG_OUTPUT`: Log output (stdout, file path)
- `ENVIRONMENT`: Environment (dev, staging, prod)

#### Diary Service
- `PORT`: Service port (default: 50052)
- `DB_HOST`: Event store database host
- `DB_PORT`: Event store database port
- `DB_USER`: Event store database user
- `DB_PASSWORD`: Event store database password
- `DB_NAME`: Event store database name
- `CASSANDRA_HOSTS`: Cassandra hosts (comma-separated)
- `CASSANDRA_KEYSPACE`: Cassandra keyspace
- `KAFKA_BOOTSTRAP_SERVERS`: Kafka bootstrap servers
- `KAFKA_DIARY_EVENTS_TOPIC`: Kafka topic for diary events
- `LOG_LEVEL`: Log level (debug, info, warn, error)
- `LOG_FORMAT`: Log format (json, text)
- `LOG_OUTPUT`: Log output (stdout, file path)
- `ENVIRONMENT`: Environment (dev, staging, prod)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.