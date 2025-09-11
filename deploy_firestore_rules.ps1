# Deploy Firestore Rules Script
# This script deploys the appropriate Firestore rules based on the environment

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("development", "production")]
    [string]$Environment
)

Write-Host "🔧 Deploying Firestore rules for $Environment environment..." -ForegroundColor Cyan

if ($Environment -eq "development") {
    Write-Host "📝 Deploying development rules to apiclientapp project..." -ForegroundColor Yellow
    
    # Switch to apiclientapp project
    firebase use apiclientapp
    
    # Deploy development rules
    firebase deploy --only firestore:rules --project apiclientapp
    
    Write-Host "✅ Development Firestore rules deployed successfully!" -ForegroundColor Green
    Write-Host "   - Project: apiclientapp" -ForegroundColor Gray
    Write-Host "   - Database: (default)" -ForegroundColor Gray
    Write-Host "   - Rules: firestore_dev.rules" -ForegroundColor Gray
    
} elseif ($Environment -eq "production") {
    Write-Host "📝 Deploying production rules to play-e37a6 project..." -ForegroundColor Yellow
    
    # Switch to play-e37a6 project
    firebase use play-e37a6
    
    # Deploy production rules
    firebase deploy --only firestore:rules --project play-e37a6
    
    Write-Host "✅ Production Firestore rules deployed successfully!" -ForegroundColor Green
    Write-Host "   - Project: play-e37a6" -ForegroundColor Gray
    Write-Host "   - Database: play" -ForegroundColor Gray
    Write-Host "   - Rules: firestore_prod.rules" -ForegroundColor Gray
}

Write-Host "🎉 Firestore rules deployment complete!" -ForegroundColor Green
