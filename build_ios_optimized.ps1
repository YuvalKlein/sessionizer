# iOS-Optimized Build Script for Flutter Web
# This script builds the Flutter web app with specific optimizations for iOS Safari

Write-Host "🍎 Building Flutter Web App with iOS Safari Optimizations..." -ForegroundColor Green

# Clean previous build
Write-Host "🧹 Cleaning previous build..." -ForegroundColor Yellow
flutter clean

# Get dependencies
Write-Host "📦 Getting dependencies..." -ForegroundColor Yellow
flutter pub get

# Build with iOS-specific optimizations
Write-Host "🔨 Building with iOS optimizations..." -ForegroundColor Yellow
flutter build web `
  --dart-define=FLUTTER_WEB_USE_SKIA=false `
  --dart-define=FLUTTER_WEB_AUTO_DETECT=false `
  --dart-define=FLUTTER_WEB_USE_HTML_RENDERER=true `
  --release

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Build completed successfully!" -ForegroundColor Green
    Write-Host "📱 iOS Safari optimizations applied:" -ForegroundColor Cyan
    Write-Host "   - HTML renderer forced for better iOS compatibility" -ForegroundColor White
    Write-Host "   - Modern Flutter loader with timeout handling" -ForegroundColor White
    Write-Host "   - Enhanced loading screen for iOS devices" -ForegroundColor White
    Write-Host "   - Touch and viewport optimizations" -ForegroundColor White
    Write-Host "   - Improved error handling and fallbacks" -ForegroundColor White
    Write-Host ""
    Write-Host "📂 Build output available in: build/web" -ForegroundColor Cyan
    Write-Host "🚀 Ready for deployment to Firebase Hosting" -ForegroundColor Green
} else {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    exit 1
}
