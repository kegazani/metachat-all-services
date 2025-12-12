$ErrorActionPreference = "Stop"

Write-Host "Generating Go files from proto files..." -ForegroundColor Green

$protoDirs = @(
    "analytics",
    "chat",
    "diary",
    "gateway",
    "match_request",
    "matching",
    "mood_analysis",
    "personality",
    "recommendation",
    "user"
)

$protocPath = "protoc"
if (-not (Get-Command protoc -ErrorAction SilentlyContinue)) {
    Write-Host "protoc not found in PATH. Please install Protocol Buffers compiler." -ForegroundColor Red
    Write-Host "Download from: https://github.com/protocolbuffers/protobuf/releases" -ForegroundColor Yellow
    exit 1
}

$goOutPath = $env:GOPATH
if (-not $goOutPath) {
    $goOutPath = "$env:USERPROFILE\go"
}

$protocGenGo = "$goOutPath\bin\protoc-gen-go.exe"
$protocGenGoGrpc = "$goOutPath\bin\protoc-gen-go-grpc.exe"

if (-not (Test-Path $protocGenGo)) {
    Write-Host "protoc-gen-go not found. Installing..." -ForegroundColor Yellow
    go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
}

if (-not (Test-Path $protocGenGoGrpc)) {
    Write-Host "protoc-gen-go-grpc not found. Installing..." -ForegroundColor Yellow
    go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
}

foreach ($dir in $protoDirs) {
    $protoFile = "$dir\$dir.proto"
    
    if (-not (Test-Path $protoFile)) {
        Write-Host "Skipping $protoFile (not found)" -ForegroundColor Yellow
        continue
    }
    
    Write-Host "Generating files for $protoFile..." -ForegroundColor Cyan
    
    $protoPath = "."
    $goPackage = "github.com/kegazani/metachat-proto/$dir"
    
    $protocArgs = @(
        "--proto_path=$protoPath",
        "--proto_path=$env:USERPROFILE\go\pkg\mod\github.com\grpc-ecosystem\grpc-gateway@v1.16.0\third_party\googleapis",
        "--go_out=$protoPath",
        "--go_opt=paths=source_relative",
        "--go-grpc_out=$protoPath",
        "--go-grpc_opt=paths=source_relative",
        $protoFile
    )
    
    try {
        & protoc $protocArgs
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓ Generated $dir.pb.go and ${dir}_grpc.pb.go" -ForegroundColor Green
        } else {
            Write-Host "  ✗ Failed to generate files for $protoFile" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ✗ Error generating $protoFile : $_" -ForegroundColor Red
    }
}

Write-Host "`nGeneration complete!" -ForegroundColor Green

