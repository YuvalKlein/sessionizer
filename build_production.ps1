# Build script for production deployment
# This script builds the app with production environment variables

Write-Host "🚀 Building for Production..." -ForegroundColor Green

# Set production environment variables
# Note: SENDGRID_API_KEY should be set as environment variable or passed as parameter
$env:SENDGRID_FROM_EMAIL = "noreply@arenna.link"
$env:SENDGRID_FROM_NAME = "ARENNA"

Write-Host "📧 Environment variables set for production" -ForegroundColor Yellow

# Build the web app
Write-Host "🔨 Building Flutter web app..." -ForegroundColor Blue
flutter build web --dart-define=SENDGRID_FROM_EMAIL=$env:SENDGRID_FROM_EMAIL --dart-define=SENDGRID_FROM_NAME=$env:SENDGRID_FROM_NAME

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Build successful!" -ForegroundColor Green
    Write-Host "🚀 Ready for deployment with real email sending" -ForegroundColor Green
} else {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    exit 1
}
