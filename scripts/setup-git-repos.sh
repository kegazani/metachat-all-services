#!/bin/bash

# Setup Git repositories for common modules and publish them

set -e

echo "Setting up Git repositories for common modules..."

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "Initializing git repository..."
    git init
    git config user.name "MetaChat Developer"
    git config user.email "dev@metachat.com"
fi

# Create and push common/event-sourcing module
echo "Setting up common/event-sourcing module..."
cd common/event-sourcing
if [ ! -d ".git" ]; then
    git init
    git config user.name "MetaChat Developer"
    git config user.email "dev@metachat.com"
    
    git add .
    git commit -m "Initial commit: event sourcing common module"
    
    # Create a dummy remote (in real scenario, this would be GitHub)
    git remote add origin https://github.com/metachat/common-event-sourcing.git
    
    # Tag the version
    git tag v0.0.0
fi
cd ../..

# Create and push config/logging module
echo "Setting up config/logging module..."
cd config/logging
if [ ! -d ".git" ]; then
    git init
    git config user.name "MetaChat Developer"
    git config user.email "dev@metachat.com"
    
    git add .
    git commit -m "Initial commit: logging config module"
    
    # Create a dummy remote (in real scenario, this would be GitHub)
    git remote add origin https://github.com/metachat/config-logging.git
    
    # Tag the version
    git tag v0.0.0
fi
cd ../..

# Create and push proto/generated module
echo "Setting up proto/generated module..."
cd metachat/proto/generated
if [ ! -d ".git" ]; then
    git init
    git config user.name "MetaChat Developer"
    git config user.email "dev@metachat.com"
    
    git add .
    git commit -m "Initial commit: proto generated module"
    
    # Create a dummy remote (in real scenario, this would be GitHub)
    git remote add origin https://github.com/metachat/proto-generated.git
    
    # Tag the version
    git tag v0.0.0
fi
cd ../../..

echo "Git repositories setup complete!"
echo ""
echo "Note: In a real deployment scenario, you would:"
echo "1. Push these repositories to GitHub/GitLab"
echo "2. Update go.mod files to use the actual repository URLs"
echo "3. Run 'go mod tidy' in each service to download dependencies"
echo ""
echo "For local development, you can use the replace directives in go.mod files"