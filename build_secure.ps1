# Secure Build Script for Sessionizer
# This script builds the Flutter web app with environment variables

param(
    [string]$Environment = "development"
)

Write-Host "🔧 Building for $Environment environment" -ForegroundColor Cyan

# Check if .env file exists
if (-not (Test-Path ".env")) {
    Write-Host "❌ Error: .env file not found" -ForegroundColor Red
    Write-Host "Please create a .env file based on env.example" -ForegroundColor Yellow
    exit 1
}

# Read environment variables from .env file
$envVars = @{}
Get-Content ".env" | ForEach-Object {
    if ($_ -match "^([^#][^=]+)=(.*)$") {
        $envVars[$matches[1]] = $matches[2]
    }
}

# Get required environment variables
$googleClientId = $envVars["GOOGLE_CLIENT_ID"]
$firebaseApiKey = if ($Environment -eq "production") { 
    $envVars["FIREBASE_API_KEY_PROD"] 
} else { 
    $envVars["FIREBASE_API_KEY_DEV"] 
}

if (-not $googleClientId) {
    Write-Host "❌ Error: GOOGLE_CLIENT_ID not found in .env file" -ForegroundColor Red
    exit 1
}

if (-not $firebaseApiKey) {
    Write-Host "❌ Error: FIREBASE_API_KEY_$($Environment.ToUpper()) not found in .env file" -ForegroundColor Red
    exit 1
}

# Update index.html with Google Client ID
$indexFile = "web/index.html"
if (Test-Path $indexFile) {
    $indexContent = Get-Content $indexFile -Raw
    $indexContent = $indexContent -replace "GOOGLE_CLIENT_ID_PLACEHOLDER", $googleClientId
    Set-Content $indexFile $indexContent
    Write-Host "✅ Updated web/index.html with Google Client ID" -ForegroundColor Green
} else {
    Write-Host "❌ Error: web/index.html file not found" -ForegroundColor Red
    exit 1
}

# Build the Flutter web app
Write-Host "🚀 Building Flutter web app..." -ForegroundColor Cyan
$buildCommand = "flutter build web --dart-define=FIREBASE_API_KEY=$firebaseApiKey --dart-define=ENVIRONMENT=$Environment"

try {
    Invoke-Expression $buildCommand
    Write-Host "✅ Build completed successfully!" -ForegroundColor Green
    Write-Host "🔒 All secrets are securely managed via environment variables" -ForegroundColor Green
} catch {
    Write-Host "❌ Build failed: $_" -ForegroundColor Red
    exit 1
}
