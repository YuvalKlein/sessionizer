# Simple Flutter Test
Write-Host "🧪 Testing Flutter Local Environment..." -ForegroundColor Green

# Test if Flutter is running
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080" -Method Head -TimeoutSec 5 -UseBasicParsing -ErrorAction SilentlyContinue
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Flutter server is running" -ForegroundColor Green
        
        # Test page content
        $pageContent = Invoke-WebRequest -Uri "http://localhost:8080" -TimeoutSec 10 -UseBasicParsing
        if ($pageContent.Content -match "ARENNA") {
            Write-Host "✅ Page loads with ARENNA content" -ForegroundColor Green
        } elseif ($pageContent.Content -match "Loading Issue") {
            Write-Host "❌ Page shows Loading Issue - Flutter initialization failed" -ForegroundColor Red
            Write-Host "Check browser console at http://localhost:8080" -ForegroundColor Yellow
        } else {
            Write-Host "⚠️ Page loads but content is unexpected" -ForegroundColor Yellow
        }
        
        Write-Host "`n🌐 Open http://localhost:8080 in your browser to test manually" -ForegroundColor Cyan
    } else {
        Write-Host "❌ Flutter server not responding properly" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Flutter server is not running on port 8080" -ForegroundColor Red
    Write-Host "Run: flutter run -d chrome --web-port=8080" -ForegroundColor Yellow
}


