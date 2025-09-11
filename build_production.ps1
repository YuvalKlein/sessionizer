# Build script for production environment
# This script builds the app with production environment variables

Write-Host "Building for Production..." -ForegroundColor Green

# Set production environment variables
# Note: SENDGRID_API_KEY should be set as environment variable or passed as parameter
$env:ENVIRONMENT = "production"
$env:SENDGRID_FROM_EMAIL = "noreply@arenna.link"
$env:SENDGRID_FROM_NAME = "ARENNA"

Write-Host "Environment variables set for production" -ForegroundColor Yellow
Write-Host "Using play-e37a6 Firebase project (existing, unchanged)" -ForegroundColor Yellow
Write-Host "Using existing Firestore structure (unchanged)" -ForegroundColor Yellow
Write-Host "Development uses apiclientapp project separately" -ForegroundColor Green

# Build the web app
Write-Host "Building Flutter web app..." -ForegroundColor Blue
flutter build web --dart-define=ENVIRONMENT=production --dart-define=SENDGRID_FROM_EMAIL=$env:SENDGRID_FROM_EMAIL --dart-define=SENDGRID_FROM_NAME=$env:SENDGRID_FROM_NAME

if ($LASTEXITCODE -eq 0) {
    Write-Host "Production build successful!" -ForegroundColor Green
    Write-Host "Ready for deployment with play-e37a6 project" -ForegroundColor Green
    Write-Host "Using sessionizer/ProdData collections" -ForegroundColor Green
    Write-Host "Real emails will be sent via SendGrid" -ForegroundColor Green
} else {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}