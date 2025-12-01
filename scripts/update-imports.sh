#!/bin/bash

# Update import paths in all Go files to use new module names

set -e

echo "Updating import paths in all services..."

# Find all .go files in services directory
find services -name "*.go" -type f | while read file; do
    echo "Processing $file..."
    
    # Replace old import paths with new ones
    sed -i '' 's|metachat/common/event-sourcing|github.com/metachat/common/event-sourcing|g' "$file"
    sed -i '' 's|metachat/config/logging|github.com/metachat/config/logging|g' "$file"
    sed -i '' 's|metachat/proto/generated|github.com/metachat/proto/generated|g' "$file"
done

echo "All import paths updated successfully!"