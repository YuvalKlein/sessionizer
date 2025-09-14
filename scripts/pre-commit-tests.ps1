# Pre-commit test script for ARENNA Sessionizer (PowerShell)
# Run this before committing to catch issues early

Write-Host "🧪 ARENNA Pre-Commit Test Runner" -ForegroundColor Blue
Write-Host "==================================" -ForegroundColor Blue

function Write-Status {
    param($Message)
    Write-Host "🔍 $Message" -ForegroundColor Cyan
}

function Write-Success {
    param($Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Warning {
    param($Message)
    Write-Host "⚠️ $Message" -ForegroundColor Yellow
}

function Write-Error {
    param($Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

# Check if Flutter is installed
try {
    flutter --version | Out-Null
} catch {
    Write-Error "Flutter is not installed or not in PATH"
    exit 1
}

Write-Status "Getting Flutter dependencies..."
flutter pub get

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to get dependencies"
    exit 1
}

Write-Success "Dependencies updated"

# Run code analysis
Write-Status "Running code analysis..."
flutter analyze

if ($LASTEXITCODE -ne 0) {
    Write-Error "Code analysis failed - please fix issues before committing"
    exit 1
}

Write-Success "Code analysis passed"

# Run unit tests
Write-Status "Running unit tests..."
flutter test

if ($LASTEXITCODE -ne 0) {
    Write-Error "Unit tests failed - please fix failing tests before committing"
    exit 1
}

Write-Success "All unit tests passed"

# Check for common issues
Write-Status "Checking for common issues..."

# Check for hardcoded test data
$hardcodedEmails = Select-String -Path "lib\**\*.dart" -Pattern "yuklein@gmail.com" -ErrorAction SilentlyContinue
if ($hardcodedEmails) {
    Write-Warning "Hardcoded test emails found in code"
}

# Check for debug prints
$debugPrints = Select-String -Path "lib\**\*.dart" -Pattern "print\(" -ErrorAction SilentlyContinue | Where-Object { $_.Line -notmatch "# TODO" -and $_.Line -notmatch "# DEBUG" }
if ($debugPrints) {
    Write-Warning "Debug print statements found - consider using AppLogger instead"
}

# Check for TODO comments
$todoComments = Select-String -Path "lib\**\*.dart" -Pattern "TODO" -ErrorAction SilentlyContinue
if ($todoComments) {
    $todoCount = $todoComments.Count
    Write-Warning "Found $todoCount TODO comments in code"
}

Write-Success "Pre-commit checks completed"

# Try to build (quick check)
Write-Status "Testing development build..."
flutter build web --dart-define=ENVIRONMENT=development 2>$null | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Error "Development build failed"
    exit 1
}

Write-Success "Development build successful"

Write-Host ""
Write-Host "🎉 All pre-commit checks passed!" -ForegroundColor Green
Write-Host "✅ Safe to commit your changes" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Test Summary:" -ForegroundColor White
Write-Host "  - Code analysis: ✅ Passed" -ForegroundColor White
Write-Host "  - Unit tests: ✅ All passed" -ForegroundColor White  
Write-Host "  - Build test: ✅ Successful" -ForegroundColor White
Write-Host ""
Write-Host "🚀 Your code is ready for commit!" -ForegroundColor Green
