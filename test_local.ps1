# Test script for local Flutter development
Write-Host "Testing Local Flutter Environment..." -ForegroundColor Green

# Test 1: Check if Flutter is running
Write-Host "`n1. Checking if Flutter is running on port 8080..." -ForegroundColor Yellow
$response = try { 
    Invoke-WebRequest -Uri "http://localhost:8080" -Method Head -TimeoutSec 5 -UseBasicParsing
    $response.StatusCode 
} catch { 
    "Failed: $($_.Exception.Message)" 
}
Write-Host "   Status: $response" -ForegroundColor $(if($response -eq 200) {"Green"} else {"Red"})

# Test 2: Check if main.dart.js is accessible
Write-Host "`n2. Checking if main.dart.js is accessible..." -ForegroundColor Yellow
$jsResponse = try { 
    Invoke-WebRequest -Uri "http://localhost:8080/main.dart.js" -Method Head -TimeoutSec 5 -UseBasicParsing
    $jsResponse.StatusCode 
} catch { 
    "Failed: $($_.Exception.Message)" 
}
Write-Host "   Status: $jsResponse" -ForegroundColor $(if($jsResponse -eq 200) {"Green"} else {"Red"})

# Test 3: Check if Flutter.js is accessible
Write-Host "`n3. Checking if flutter.js is accessible..." -ForegroundColor Yellow
$flutterJsResponse = try { 
    Invoke-WebRequest -Uri "http://localhost:8080/flutter.js" -Method Head -TimeoutSec 5 -UseBasicParsing
    $flutterJsResponse.StatusCode 
} catch { 
    "Failed: $($_.Exception.Message)" 
}
Write-Host "   Status: $flutterJsResponse" -ForegroundColor $(if($flutterJsResponse -eq 200) {"Green"} else {"Red"})

# Test 4: Test basic page load
Write-Host "`n4. Testing basic page load..." -ForegroundColor Yellow
$pageContent = try { 
    $content = Invoke-WebRequest -Uri "http://localhost:8080" -TimeoutSec 10 -UseBasicParsing
    if($content.Content -match "ARENNA") { "Page loads with ARENNA title" } else { "Page loads but missing ARENNA" }
} catch { 
    "Failed: $($_.Exception.Message)" 
}
Write-Host "   Result: $pageContent" -ForegroundColor $(if($pageContent -match "ARENNA") {"Green"} else {"Red"})

Write-Host "`nLocal Test Complete!" -ForegroundColor Green
Write-Host "If all tests show Green, the local environment is working." -ForegroundColor Cyan
Write-Host "Open http://localhost:8080 in your browser to test manually." -ForegroundColor Cyan


