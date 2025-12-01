#!/bin/bash

# Generate gRPC code from proto files

# Set PATH to include Go bin directory
export PATH=$PATH:$GOPATH/bin

# Create directories for generated code
mkdir -p proto/generated/user
mkdir -p proto/generated/diary

# Generate code for user service
protoc --go_out=. --go-grpc_out=. --plugin=protoc-gen-go=/Users/kgz/go/bin/protoc-gen-go --plugin=protoc-gen-go-grpc=/Users/kgz/go/bin/protoc-gen-go-grpc proto/user.proto

# Generate code for diary service
protoc --go_out=. --go-grpc_out=. --plugin=protoc-gen-go=/Users/kgz/go/bin/protoc-gen-go --plugin=protoc-gen-go-grpc=/Users/kgz/go/bin/protoc-gen-go-grpc proto/diary.proto

echo "Proto files generated successfully!"