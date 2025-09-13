# Build script for development environment
# This script builds the app with development environment variables

Write-Host "Building for Development..." -ForegroundColor Green

# Set development environment variables
$env:ENVIRONMENT = "development"
$env:SENDGRID_FROM_EMAIL = "noreply@arenna.link"
$env:SENDGRID_FROM_NAME = "ARENNA (Dev)"

Write-Host "Environment variables set for development" -ForegroundColor Yellow
Write-Host "Using apiclientapp Firebase project" -ForegroundColor Yellow
Write-Host "Using sessionizer/DevData collections in Firestore" -ForegroundColor Yellow
Write-Host "Beta users on live site will use sessionizer/ProdData collections" -ForegroundColor Green

# Build the web app
Write-Host "Building Flutter web app..." -ForegroundColor Blue
flutter build web --dart-define=ENVIRONMENT=development --dart-define=SENDGRID_FROM_EMAIL=$env:SENDGRID_FROM_EMAIL --dart-define=SENDGRID_FROM_NAME=$env:SENDGRID_FROM_NAME

if ($LASTEXITCODE -eq 0) {
    Write-Host "Development build successful!" -ForegroundColor Green
    Write-Host "Ready for local development with apiclientapp project" -ForegroundColor Green
    Write-Host "Using sessionizer/DevData collections (isolated from beta users)" -ForegroundColor Green
    Write-Host "Beta users on live site use sessionizer/ProdData collections" -ForegroundColor Green
    Write-Host "Emails will be sent via Firebase Functions" -ForegroundColor Yellow
} else {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}