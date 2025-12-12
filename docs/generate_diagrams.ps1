# PowerShell script for generating diagrams on Windows

Write-Host "Generating diagrams from Mermaid files..." -ForegroundColor Green

if (-not (Get-Command mmdc -ErrorAction SilentlyContinue)) {
    Write-Host "Mermaid CLI not found. Installing..." -ForegroundColor Yellow
    npm install -g @mermaid-js/mermaid-cli
}

$OutputDir = "images"
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

Write-Host "Processing DETAILED_FLOW_DIAGRAMS.md..." -ForegroundColor Cyan
mmdc -i DETAILED_FLOW_DIAGRAMS.md -o "$OutputDir/detailed_flow_diagrams/" -b transparent

Write-Host "Processing FLOW_DIAGRAMS.md..." -ForegroundColor Cyan
mmdc -i FLOW_DIAGRAMS.md -o "$OutputDir/flow_diagrams/" -b transparent

Write-Host "Diagrams generated in $OutputDir/" -ForegroundColor Green
Write-Host "Done!" -ForegroundColor Green


