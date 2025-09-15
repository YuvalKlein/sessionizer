# Clear browser cache and test Flutter app
Write-Host "🧹 Clearing browser cache and testing Flutter app..." -ForegroundColor Green

# Wait for Flutter to start
Start-Sleep -Seconds 10

# Test if server is running
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080" -UseBasicParsing -TimeoutSec 5
    Write-Host "✅ Server responds with status: $($response.StatusCode)" -ForegroundColor Green
    
    # Check content
    if ($response.Content -match "Loading Issue") {
        Write-Host "❌ Still showing error page" -ForegroundColor Red
        Write-Host "🔧 This might be a browser cache issue" -ForegroundColor Yellow
    } elseif ($response.Content -match "ARENNA") {
        Write-Host "✅ Page contains ARENNA content" -ForegroundColor Green
    }
    
    # Open in new incognito window to bypass cache
    Write-Host "🌐 Opening in Chrome incognito mode (bypasses cache)..." -ForegroundColor Cyan
    Start-Process chrome "--incognito http://localhost:8080"
    
} catch {
    Write-Host "❌ Server not responding: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "⏳ Waiting longer for Flutter to start..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    
    try {
        $response2 = Invoke-WebRequest -Uri "http://localhost:8080" -UseBasicParsing -TimeoutSec 5
        Write-Host "✅ Server now responds: $($response2.StatusCode)" -ForegroundColor Green
        Start-Process chrome "--incognito http://localhost:8080"
    } catch {
        Write-Host "❌ Server still not responding after 20 seconds" -ForegroundColor Red
    }
}

