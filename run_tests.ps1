# Simple test runner for ARENNA Sessionizer

Write-Host "Running ARENNA Tests..." -ForegroundColor Blue
Write-Host "======================" -ForegroundColor Blue

# Run Flutter tests
Write-Host "Running unit tests..." -ForegroundColor Cyan
flutter test

if ($LASTEXITCODE -eq 0) {
    Write-Host "All tests passed!" -ForegroundColor Green
    Write-Host "Code is ready for commit/deploy!" -ForegroundColor Green
} else {
    Write-Host "Tests failed!" -ForegroundColor Red
    Write-Host "Do not commit until tests pass!" -ForegroundColor Red
    exit 1
}