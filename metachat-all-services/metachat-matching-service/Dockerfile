# Build stage
FROM golang:1.24-alpine AS builder

WORKDIR /app

COPY metachat-matching-service/go.mod ./
RUN apk add --no-cache git && go mod download

COPY metachat-matching-service/ .

RUN go mod tidy

RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main ./cmd/main.go

# Final stage
FROM alpine:latest

WORKDIR /app

# Copy binary from builder stage
COPY --from=builder /app/main .

# Copy configuration files
COPY --from=builder /app/config ./config

EXPOSE 8080

# Command to run the application
CMD ["./main"]