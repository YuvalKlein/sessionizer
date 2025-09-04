# Sessionizer App Test Runner
# This script runs all tests for the Sessionizer app

Write-Host "🧪 Starting Sessionizer App Test Suite..." -ForegroundColor Green

# Check if Flutter is available
if (!(Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Flutter not found. Please install Flutter and add it to your PATH." -ForegroundColor Red
    exit 1
}

# Get dependencies
Write-Host "📦 Getting dependencies..." -ForegroundColor Yellow
flutter pub get

# Generate mock files
Write-Host "🔧 Generating mock files..." -ForegroundColor Yellow
flutter packages pub run build_runner build --delete-conflicting-outputs

# Run unit tests
Write-Host "📋 Running unit tests..." -ForegroundColor Cyan
flutter test test/features/auth/presentation/bloc/auth_bloc_test.dart
flutter test test/features/user/presentation/bloc/user_bloc_test.dart
flutter test test/features/booking/presentation/bloc/booking_bloc_test.dart

# Run widget tests
Write-Host "🎨 Running widget tests..." -ForegroundColor Cyan
flutter test test/features/auth/presentation/pages/login_page_test.dart
flutter test test/features/main/presentation/pages/main_screen_clean_test.dart

# Run integration tests
Write-Host "🔗 Running integration tests..." -ForegroundColor Cyan
flutter test integration_test/

# Run all tests together
Write-Host "🚀 Running all tests..." -ForegroundColor Magenta
flutter test

Write-Host "✅ Test suite completed!" -ForegroundColor Green
Write-Host "📊 Check the output above for test results." -ForegroundColor White
