# Build script for Flutter web with secure environment variables
Write-Host "🔒 Building Flutter web app with secure environment variables..." -ForegroundColor Green

# Step 1: Update web/index.html with the Client ID from keys.json
Write-Host "📝 Updating web/index.html with Google Client ID..." -ForegroundColor Yellow
dart run scripts/build_web.dart

# Step 2: Build Flutter web app with environment variables
Write-Host "🏗️ Building Flutter web app..." -ForegroundColor Yellow
flutter build web --release --dart-define-from-file=keys.json

# Step 3: Deploy to Firebase (optional)
Write-Host "🚀 Deploying to Firebase..." -ForegroundColor Yellow
firebase deploy --only hosting

Write-Host "✅ Build and deployment completed successfully!" -ForegroundColor Green
Write-Host "🔒 Your Google Client ID is now securely managed!" -ForegroundColor Cyan
