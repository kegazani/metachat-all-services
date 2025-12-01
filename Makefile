.PHONY: build run test clean generate-proto

# Generate gRPC code from proto files
generate-proto:
	@echo "Generating gRPC code..."
	@mkdir -p services/user-service/internal/grpc/generated
	@mkdir -p services/diary-service/internal/grpc/generated
	@mkdir -p services/api-gateway/internal/grpc/generated
	
	@echo "Generating user service proto..."
	@protoc --go_out=services/user-service/internal/grpc/generated \
		--go-grpc_out=services/user-service/internal/grpc/generated \
		--plugin=protoc-gen-go=/Users/kgz/go/bin/protoc-gen-go \
		--plugin=protoc-gen-go-grpc=/Users/kgz/go/bin/protoc-gen-go-grpc \
		proto/user.proto
	
	@echo "Generating diary service proto..."
	@protoc --go_out=services/diary-service/internal/grpc/generated \
		--go-grpc_out=services/diary-service/internal/grpc/generated \
		--plugin=protoc-gen-go=/Users/kgz/go/bin/protoc-gen-go \
		--plugin=protoc-gen-go-grpc=/Users/kgz/go/bin/protoc-gen-go-grpc \
		proto/diary.proto
	
	@echo "Generating API Gateway proto..."
	@protoc --go_out=services/api-gateway/internal/grpc/generated \
		--go-grpc_out=services/api-gateway/internal/grpc/generated \
		--plugin=protoc-gen-go=/Users/kgz/go/bin/protoc-gen-go \
		--plugin=protoc-gen-go-grpc=/Users/kgz/go/bin/protoc-gen-go-grpc \
		proto/user.proto proto/diary.proto
	
	@echo "Proto files generated successfully!"

# Build all services
build:
	@echo "Building all services..."
	@cd services/user-service && go build -o bin/user-service ./cmd/main.go
	@cd services/diary-service && go build -o bin/diary-service ./cmd/main.go
	@cd services/api-gateway && go build -o bin/api-gateway ./cmd/main.go
	@echo "Build completed!"

# Run all services
run:
	@echo "Running all services..."
	@docker-compose -f docker-compose.simple.yml up -d

# Stop all services
stop:
	@echo "Stopping all services..."
	@docker-compose -f docker-compose.simple.yml down

# Test all services
test:
	@echo "Running tests..."
	@cd services/user-service && go test ./...
	@cd services/diary-service && go test ./...
	@cd services/api-gateway && go test ./...

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf services/*/bin
	@rm -rf services/*/internal/grpc/generated
	@echo "Clean completed!"

# Install dependencies
deps:
	@echo "Installing dependencies..."
	@cd services/user-service && go mod tidy
	@cd services/diary-service && go mod tidy
	@cd services/api-gateway && go mod tidy
	@echo "Dependencies installed!"