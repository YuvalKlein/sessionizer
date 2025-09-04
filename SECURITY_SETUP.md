# 🔒 Secure Environment Variables Setup

This document explains how to securely manage sensitive configuration data like Google Client IDs in your Flutter application.

## 📁 Files Created

- `keys.json` - Contains your sensitive environment variables (DO NOT COMMIT)
- `lib/core/config/app_config.dart` - Configuration class for accessing environment variables
- `scripts/build_web.dart` - Script to replace placeholders with actual values
- `build_web.ps1` - PowerShell build script for Windows
- `.gitignore` - Updated to exclude sensitive files

## 🚀 How to Use

### 1. **Development (Local)**
```bash
# Run with environment variables
flutter run lib/main_new.dart -d chrome --dart-define-from-file=keys.json
```

### 2. **Production Build**
```powershell
# Use the PowerShell script (Windows)
.\build_web.ps1

# Or manually:
dart run scripts/build_web.dart
flutter build web --release --dart-define-from-file=keys.json
firebase deploy --only hosting
```

## 🔐 Security Benefits

✅ **No hardcoded secrets** in source code  
✅ **Environment variables** managed separately  
✅ **Git-safe** - sensitive files are in .gitignore  
✅ **Build-time replacement** - Client ID injected during build  
✅ **Fallback values** - Default values for development  

## 📝 Adding New Environment Variables

1. **Add to `keys.json`:**
```json
{
  "GOOGLE_CLIENT_ID": "your-client-id",
  "FIREBASE_API_KEY": "your-api-key",
  "ANOTHER_SECRET": "your-secret"
}
```

2. **Add to `lib/core/config/app_config.dart`:**
```dart
static const String firebaseApiKey = String.fromEnvironment(
  'FIREBASE_API_KEY',
  defaultValue: 'your-default-value',
);
```

3. **Use in your code:**
```dart
import 'package:myapp/core/config/app_config.dart';

// Use the environment variable
final apiKey = AppConfig.firebaseApiKey;
```

## ⚠️ Important Security Notes

- **Never commit `keys.json`** to version control
- **Use different keys** for development and production
- **Rotate keys regularly** for security
- **Use CI/CD secrets** for automated deployments
- **Monitor key usage** in Google Cloud Console

## 🛠️ Troubleshooting

If you get "ClientID not set" errors:
1. Check that `keys.json` exists and has the correct Client ID
2. Verify the build script ran successfully
3. Make sure you're using `--dart-define-from-file=keys.json` when running

## 📚 Additional Resources

- [Flutter Environment Variables](https://docs.flutter.dev/deployment/environment-variables)
- [Google OAuth Security Best Practices](https://developers.google.com/identity/protocols/oauth2/security-best-practices)
- [Firebase Security Rules](https://firebase.google.com/docs/rules)
