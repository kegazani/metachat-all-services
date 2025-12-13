$ErrorActionPreference = "Stop"

$pythonServices = @(
    "mood-analysis-service",
    "analytics-service",
    "archetype-service",
    "biometric-service",
    "correlation-service"
)

$baseDir = "C:\Users\ddkri\OneDrive\Desktop\p\metachat\metachat-all-services"

Write-Host "Building Python services..." -ForegroundColor Green

Set-Location $baseDir

foreach ($service in $pythonServices) {
    $imageName = "metachat/${service}:latest"
    $dockerfilePath = "metachat-${service}/Dockerfile"
    
    Write-Host "`nBuilding: $service" -ForegroundColor Cyan
    
    docker build -t $imageName -f $dockerfilePath .
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to build $service" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Successfully built: $service" -ForegroundColor Green
}

Write-Host "`nAll Python services built!" -ForegroundColor Green
Set-Location "C:\Users\ddkri\OneDrive\Desktop\p\metachat"

