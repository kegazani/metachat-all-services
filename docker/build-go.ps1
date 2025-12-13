$ErrorActionPreference = "Stop"

$goServices = @(
    "diary-service",
    "matching-service",
    "match-request-service",
    "chat-service"
)

$baseDir = "C:\Users\ddkri\OneDrive\Desktop\p\metachat\metachat-all-services"

Write-Host "Building Go services..." -ForegroundColor Green

Set-Location $baseDir

foreach ($service in $goServices) {
    $serviceDir = "metachat-${service}"
    $imageName = "metachat/${service}:latest"
    
    Write-Host "`nBuilding: $service" -ForegroundColor Cyan
    
    docker build -t $imageName `
        -f ../docker/Dockerfile.go-service `
        --build-arg SERVICE_DIR=$serviceDir `
        .
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to build $service" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Successfully built: $service" -ForegroundColor Green
}

Write-Host "`nAll Go services built!" -ForegroundColor Green
Set-Location "C:\Users\ddkri\OneDrive\Desktop\p\metachat"
