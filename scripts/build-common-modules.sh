#!/bin/bash

# Build and publish common modules for Docker deployment

set -e

echo "Building common modules..."

# Build event-sourcing module
echo "Building event-sourcing module..."
cd common/event-sourcing
docker build -t metachat/common-event-sourcing:latest .
cd ../..

# Build config/logging module
echo "Building config/logging module..."
cd config/logging
docker build -t metachat/config-logging:latest .
cd ../..

# Build proto/generated module
echo "Building proto/generated module..."
cd metachat/proto/generated
docker build -t metachat/proto-generated:latest .
cd ../../..

echo "All common modules built successfully!"

# Optional: Push to registry (uncomment if needed)
# docker push metachat/common-event-sourcing:latest
# docker push metachat/config-logging:latest
# docker push metachat/proto-generated:latest

echo "Common modules are ready for use in service builds!"