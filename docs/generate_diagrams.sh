#!/bin/bash

echo "Generating diagrams from Mermaid files..."

if ! command -v mmdc &> /dev/null; then
    echo "Mermaid CLI not found. Installing..."
    npm install -g @mermaid-js/mermaid-cli
fi

OUTPUT_DIR="images"
mkdir -p "$OUTPUT_DIR"

echo "Processing DETAILED_FLOW_DIAGRAMS.md..."
mmdc -i DETAILED_FLOW_DIAGRAMS.md -o "$OUTPUT_DIR/detailed_flow_diagrams/" -b transparent

echo "Processing FLOW_DIAGRAMS.md..."
mmdc -i FLOW_DIAGRAMS.md -o "$OUTPUT_DIR/flow_diagrams/" -b transparent

echo "Diagrams generated in $OUTPUT_DIR/"
echo "Done!"


