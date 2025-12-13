$ErrorActionPreference = "Stop"

$services = @(
    @{Name="mood-analysis-service"; Type="python"},
    @{Name="analytics-service"; Type="python"},
    @{Name="archetype-service"; Type="python"},
    @{Name="biometric-service"; Type="python"},
    @{Name="correlation-service"; Type="python"},
    @{Name="api-gateway"; Type="go"},
    @{Name="user-service"; Type="go"},
    @{Name="diary-service"; Type="go"},
    @{Name="matching-service"; Type="go"},
    @{Name="match-request-service"; Type="go"},
    @{Name="chat-service"; Type="go"}
)

$baseDir = "C:\Users\ddkri\OneDrive\Desktop\p\metachat\metachat-all-services"

Write-Host "Starting build of all services..." -ForegroundColor Green

foreach ($service in $services) {
    $serviceName = $service.Name
    $serviceType = $service.Type
    $imageName = "metachat/${serviceName}:latest"
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Building: $serviceName" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    
    if ($serviceType -eq "python") {
        $dockerfilePath = "metachat-${serviceName}/Dockerfile"
        
        Set-Location $baseDir
        docker build -t $imageName -f $dockerfilePath .
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Failed to build $serviceName" -ForegroundColor Red
            exit 1
        }
    } elseif ($serviceType -eq "go") {
        $serviceDir = Join-Path $baseDir "metachat-${serviceName}"
        
        Set-Location $serviceDir
        docker build -t $imageName .
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Failed to build $serviceName" -ForegroundColor Red
            exit 1
        }
    }
    
    Write-Host "Successfully built: $serviceName" -ForegroundColor Green
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "All services built successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Set-Location "C:\Users\ddkri\OneDrive\Desktop\p\metachat"
docker images | Select-String "metachat"

