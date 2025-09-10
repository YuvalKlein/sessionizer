# Build script for development
# This script builds the app for development with console logging

Write-Host "🔧 Building for Development..." -ForegroundColor Blue

# Build the web app without production environment variables
Write-Host "🔨 Building Flutter web app for development..." -ForegroundColor Blue
flutter build web

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Development build successful!" -ForegroundColor Green
    Write-Host "📧 Emails will be logged to console (no real sending)" -ForegroundColor Yellow
} else {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    exit 1
}

