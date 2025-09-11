# 🌍 Environment Setup Guide

This guide explains how to set up and use the development and production environments for the ARENNA application.

## 📋 Overview

The application now supports two distinct environments:

- **Development Environment**: Uses `DevData` collections in Firestore
- **Production Environment**: Uses `ProdData` collections in Firestore

## 🏗️ Architecture

### Firestore Database Structure

**Old Structure:**
```
sessionizer/
├── users/
├── bookable_sessions/
├── bookings/
└── ...
```

**New Structure:**
```
sessionizer/
├── DevData/ (document)
│   ├── users/ (collection)
│   ├── bookable_sessions/ (collection)
│   ├── bookings/ (collection)
│   └── ...
└── ProdData/ (document)
    ├── users/ (collection)
    ├── bookable_sessions/ (collection)
    ├── bookings/ (collection)
    └── ...
```

### Environment Detection

The application automatically detects the environment based on build-time flags:

- `--dart-define=ENVIRONMENT=development` → Development mode
- `--dart-define=ENVIRONMENT=production` → Production mode

## 🚀 Build Commands

### Development Build
```powershell
.\build_development.ps1
```
- Uses `DevData` collections
- Console email logging
- Debug logging enabled
- App name: "ARENNA (Dev)"

### Production Build
```powershell
.\build_production.ps1
```
- Uses `ProdData` collections
- Real SendGrid emails
- Optimized for production
- App name: "ARENNA"

## 🔧 Configuration

### Environment Configuration (`lib/core/config/environment.dart`)

```dart
// Environment detection
static Environment get current {
  const String envString = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
  return envString.toLowerCase() == 'production' ? Environment.production : Environment.development;
}

// Collection prefix
static String get collectionPrefix {
  return isDevelopment ? 'DevData' : 'ProdData';
}
```

### Firestore Collections (`lib/core/config/firestore_collections.dart`)

The `FirestoreCollections` class automatically uses the correct environment prefix:

```dart
static String get _rootCollection => EnvironmentConfig.collectionPrefix;
```

## 📊 Data Migration

### Migrating Existing Data

To migrate your existing data from the old structure to the new environment-based structure:

```bash
dart run scripts/migrate_firestore_data.dart
```

This script will:
1. Copy all data from `sessionizer/{collection}` to `DevData/{collection}`
2. Copy all data from `sessionizer/{collection}` to `ProdData/{collection}`

### Manual Migration

If you prefer to migrate manually:

1. **Export data** from `sessionizer` collections
2. **Import data** to `sessionizer/DevData/{collection}` (development)
3. **Import data** to `sessionizer/ProdData/{collection}` (production)

## 🎯 Usage Examples

### Development Workflow

1. **Build for development:**
   ```powershell
   .\build_development.ps1
   ```

2. **Run locally:**
   ```bash
   flutter run -d chrome --web-port=8080
   ```

3. **Test with DevData collections** - all data is isolated from production

### Production Workflow

1. **Build for production:**
   ```powershell
   .\build_production.ps1
   ```

2. **Deploy to Firebase:**
   ```bash
   firebase deploy --only hosting:arenna
   ```

3. **Production data** is stored in `ProdData` collections

## 🔒 Security Considerations

### API Keys
- **Development**: No real API keys needed (console logging)
- **Production**: SendGrid API key stored in Firebase Functions secrets

### Data Isolation
- **Development data** is completely separate from production
- **No risk** of accidentally affecting production data during development
- **Easy testing** with realistic data in development environment

## 📝 Environment Variables

### Development
```bash
ENVIRONMENT=development
SENDGRID_FROM_EMAIL=noreply@arenna.link
SENDGRID_FROM_NAME=ARENNA (Dev)
```

### Production
```bash
ENVIRONMENT=production
SENDGRID_FROM_EMAIL=noreply@arenna.link
SENDGRID_FROM_NAME=ARENNA
SENDGRID_API_KEY=SG.xxx (stored in Firebase Functions secrets)
```

## 🐛 Troubleshooting

### Common Issues

1. **Wrong environment detected:**
   - Check build flags: `--dart-define=ENVIRONMENT=development`
   - Verify `EnvironmentConfig.current` output

2. **Data not found:**
   - Ensure data migration was completed
   - Check Firestore console for `DevData`/`ProdData` collections

3. **Email not sending:**
   - Development: Check console logs
   - Production: Verify SendGrid API key in Firebase Functions

### Debug Information

Add this to your app to see current environment:

```dart
EnvironmentConfig.printEnvironmentInfo();
```

## 📚 Best Practices

1. **Always use development** for local testing
2. **Test data migration** before switching to production
3. **Keep environments separate** - never mix DevData and ProdData
4. **Use version control** for environment-specific configurations
5. **Monitor Firebase usage** for both environments

## 🔄 Switching Environments

To switch between environments:

1. **Stop the current app**
2. **Run the appropriate build script**
3. **Restart the app**

The environment is determined at build time, not runtime.

---

For more information, see the individual configuration files:
- `lib/core/config/environment.dart`
- `lib/core/config/firestore_collections.dart`
- `lib/core/config/environment_config.dart`
