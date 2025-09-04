# Create all feature directories
$features = @("user", "booking", "session", "availability", "location", "schedulable_session", "session_type")

foreach ($feature in $features) {
    # Create main directories
    New-Item -ItemType Directory -Path "lib\features\$feature\data" -Force
    New-Item -ItemType Directory -Path "lib\features\$feature\domain" -Force
    New-Item -ItemType Directory -Path "lib\features\$feature\presentation" -Force
    
    # Create data subdirectories
    New-Item -ItemType Directory -Path "lib\features\$feature\data\datasources" -Force
    New-Item -ItemType Directory -Path "lib\features\$feature\data\models" -Force
    New-Item -ItemType Directory -Path "lib\features\$feature\data\repositories" -Force
    
    # Create domain subdirectories
    New-Item -ItemType Directory -Path "lib\features\$feature\domain\entities" -Force
    New-Item -ItemType Directory -Path "lib\features\$feature\domain\repositories" -Force
    New-Item -ItemType Directory -Path "lib\features\$feature\domain\usecases" -Force
    
    # Create presentation subdirectories
    New-Item -ItemType Directory -Path "lib\features\$feature\presentation\bloc" -Force
    New-Item -ItemType Directory -Path "lib\features\$feature\presentation\pages" -Force
    New-Item -ItemType Directory -Path "lib\features\$feature\presentation\widgets" -Force
    
    Write-Host "Created structure for $feature feature"
}

Write-Host "All feature directories created successfully!"
