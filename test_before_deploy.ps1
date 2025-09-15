# Pre-Deployment Test Suite
param(
    [switch]$SkipBuild,
    [switch]$SkipUnitTests,
    [int]$Port = 8080
)

Write-Host "🧪 Starting Pre-Deployment Test Suite..." -ForegroundColor Green

$ErrorActionPreference = "Continue"
$TestsPassed = $true
$TestResults = @()

function Add-TestResult {
    param($TestName, $Status, $Message = "")
    $TestResults += @{
        Name = $TestName
        Status = $Status
        Message = $Message
        Timestamp = Get-Date
    }
    
    $color = if ($Status -eq "PASS") { "Green" } elseif ($Status -eq "FAIL") { "Red" } else { "Yellow" }
    Write-Host "[$Status] $TestName $(if($Message) { "- $Message" })" -ForegroundColor $color
    
    if ($Status -eq "FAIL") {
        $script:TestsPassed = $false
    }
}

# Test 1: Flutter Doctor
Write-Host "`n1. 🔍 Checking Flutter Environment..." -ForegroundColor Yellow
try {
    $doctorOutput = flutter doctor --machine 2>$null | ConvertFrom-Json
    $hasErrors = $doctorOutput | Where-Object { $_.status -eq "error" }
    
    if ($hasErrors) {
        Add-TestResult "Flutter Doctor" "FAIL" "Flutter environment has errors"
    } else {
        Add-TestResult "Flutter Doctor" "PASS" "Flutter environment is healthy"
    }
} catch {
    Add-TestResult "Flutter Doctor" "FAIL" "Could not run flutter doctor: $($_.Exception.Message)"
}

# Test 2: Unit Tests (if not skipped)
if (-not $SkipUnitTests) {
    Write-Host "`n2. 🧪 Running Unit Tests..." -ForegroundColor Yellow
    try {
        $testOutput = flutter test --machine 2>&1
        if ($LASTEXITCODE -eq 0) {
            Add-TestResult "Unit Tests" "PASS" "All unit tests passed"
        } else {
            Add-TestResult "Unit Tests" "FAIL" "Some unit tests failed"
            Write-Host "Test Output:" -ForegroundColor Red
            Write-Host $testOutput -ForegroundColor Red
        }
    } catch {
        Add-TestResult "Unit Tests" "FAIL" "Could not run tests: $($_.Exception.Message)"
    }
} else {
    Add-TestResult "Unit Tests" "SKIP" "Skipped by user request"
}

# Test 3: Clean Build (if not skipped)
if (-not $SkipBuild) {
    Write-Host "`n3. 🔨 Testing Build Process..." -ForegroundColor Yellow
    try {
        flutter clean | Out-Null
        flutter pub get | Out-Null
        
        $buildOutput = flutter build web --dart-define=ENVIRONMENT=development 2>&1
        if ($LASTEXITCODE -eq 0) {
            Add-TestResult "Build Process" "PASS" "Build completed successfully"
        } else {
            Add-TestResult "Build Process" "FAIL" "Build failed"
            Write-Host "Build Output:" -ForegroundColor Red
            Write-Host $buildOutput -ForegroundColor Red
        }
    } catch {
        Add-TestResult "Build Process" "FAIL" "Build error: $($_.Exception.Message)"
    }
} else {
    Add-TestResult "Build Process" "SKIP" "Skipped by user request"
}

# Test 4: Start Development Server
Write-Host "`n4. 🌐 Testing Development Server..." -ForegroundColor Yellow

# Kill any existing Flutter processes
Get-Process -Name "dart" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

try {
    # Start Flutter in background
    $flutterJob = Start-Job -ScriptBlock {
        param($Port)
        Set-Location $using:PWD
        flutter run -d chrome --web-port=$Port --dart-define=ENVIRONMENT=development
    } -ArgumentList $Port
    
    # Wait for server to start
    $timeout = 60
    $elapsed = 0
    $serverStarted = $false
    
    while ($elapsed -lt $timeout -and -not $serverStarted) {
        Start-Sleep -Seconds 2
        $elapsed += 2
        
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:$Port" -Method Head -TimeoutSec 5 -UseBasicParsing -ErrorAction SilentlyContinue
            if ($response.StatusCode -eq 200) {
                $serverStarted = $true
                Add-TestResult "Development Server" "PASS" "Server started on port $Port"
            }
        } catch {
            # Server not ready yet
        }
        
        # Check if job failed
        if ($flutterJob.State -eq "Failed") {
            break
        }
    }
    
    if (-not $serverStarted) {
        Add-TestResult "Development Server" "FAIL" "Server failed to start within $timeout seconds"
    }
    
    # Test 5: Flutter Initialization Test
    if ($serverStarted) {
        Write-Host "`n5. 🔧 Testing Flutter Initialization..." -ForegroundColor Yellow
        
        try {
            # Copy our test file to the web directory
            Copy-Item "test_flutter_initialization.html" -Destination "build/web/" -ErrorAction SilentlyContinue
            
            # Test basic page load
            $pageContent = Invoke-WebRequest -Uri "http://localhost:$Port" -TimeoutSec 10 -UseBasicParsing
            if ($pageContent.Content -match "ARENNA" -or $pageContent.Content -match "Loading") {
                Add-TestResult "Page Load" "PASS" "Main page loads correctly"
            } else {
                Add-TestResult "Page Load" "FAIL" "Main page content not found"
            }
            
            # Test for JavaScript errors by checking console logs
            $initTestUrl = "http://localhost:$Port/test_flutter_initialization.html"
            Add-TestResult "Flutter Init Test" "INFO" "Manual test available at: $initTestUrl"
            
        } catch {
            Add-TestResult "Flutter Initialization" "FAIL" "Could not test initialization: $($_.Exception.Message)"
        }
    }
    
    # Clean up
    if ($flutterJob) {
        Stop-Job $flutterJob -ErrorAction SilentlyContinue
        Remove-Job $flutterJob -Force -ErrorAction SilentlyContinue
    }
    
} catch {
    Add-TestResult "Development Server" "FAIL" "Server test error: $($_.Exception.Message)"
}

# Kill any remaining Flutter processes
Get-Process -Name "dart" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

# Test 6: Check for Common Issues
Write-Host "`n6. 🔍 Checking for Common Issues..." -ForegroundColor Yellow

# Check web/index.html for known issues
if (Test-Path "web/index.html") {
    $indexContent = Get-Content "web/index.html" -Raw
    
    # Check for deprecated APIs
    if ($indexContent -match "FlutterLoader\.loadEntrypoint") {
        Add-TestResult "Deprecated API Check" "WARN" "Using deprecated loadEntrypoint (but should work)"
    } elseif ($indexContent -match "FlutterLoader\.load") {
        Add-TestResult "Deprecated API Check" "INFO" "Using new FlutterLoader.load API"
    } else {
        Add-TestResult "Deprecated API Check" "FAIL" "No Flutter loader initialization found"
    }
    
    # Check for service worker version
    if ($indexContent -match "serviceWorkerVersion") {
        Add-TestResult "Service Worker Check" "PASS" "Service worker version handling found"
    } else {
        Add-TestResult "Service Worker Check" "FAIL" "Service worker version handling missing"
    }
    
    # Check for iOS optimizations
    if ($indexContent -match "isIOSSafari") {
        Add-TestResult "iOS Compatibility" "PASS" "iOS Safari optimizations present"
    } else {
        Add-TestResult "iOS Compatibility" "WARN" "No iOS Safari optimizations found"
    }
} else {
    Add-TestResult "HTML Structure" "FAIL" "web/index.html not found"
}

# Generate Final Report
Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "📊 FINAL TEST REPORT" -ForegroundColor Cyan
Write-Host "="*60 -ForegroundColor Cyan

$passCount = ($TestResults | Where-Object { $_.Status -eq "PASS" }).Count
$failCount = ($TestResults | Where-Object { $_.Status -eq "FAIL" }).Count
$warnCount = ($TestResults | Where-Object { $_.Status -eq "WARN" }).Count
$skipCount = ($TestResults | Where-Object { $_.Status -eq "SKIP" }).Count

Write-Host "✅ Passed: $passCount" -ForegroundColor Green
Write-Host "❌ Failed: $failCount" -ForegroundColor Red
Write-Host "⚠️  Warnings: $warnCount" -ForegroundColor Yellow
Write-Host "⏭️  Skipped: $skipCount" -ForegroundColor Gray
Write-Host "📝 Total: $($TestResults.Count)" -ForegroundColor Cyan

if ($TestsPassed) {
    Write-Host "`n🎉 ALL CRITICAL TESTS PASSED - SAFE TO DEPLOY!" -ForegroundColor Green -BackgroundColor Black
    Write-Host "You can now run: firebase deploy --only hosting" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n🚨 TESTS FAILED - DO NOT DEPLOY!" -ForegroundColor Red -BackgroundColor Black
    Write-Host "Please fix the failing tests before deployment." -ForegroundColor Red
    
    Write-Host "`nFailed Tests:" -ForegroundColor Red
    $TestResults | Where-Object { $_.Status -eq "FAIL" } | ForEach-Object {
        Write-Host "  • $($_.Name): $($_.Message)" -ForegroundColor Red
    }
    
    exit 1
}

