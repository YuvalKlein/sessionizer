# Firebase Setup Instructions

## ⚠️ IMPORTANT: Security Notice
**NEVER commit `firebase_options.dart` or `google-services.json` to version control!** These files contain API keys that should remain private.

## Setup Steps

### 1. Install FlutterFire CLI
```bash
dart pub global activate flutterfire_cli
```

### 2. Login to Firebase
```bash
firebase login
```

### 3. Configure Firebase for this project
```bash
flutterfire configure --project=play-e37a6
```

This will generate:
- `lib/firebase_options.dart` (with your secure API keys)
- `android/app/google-services.json` (with your secure Android configuration)

### 4. Verify Configuration
- The generated files should contain your project ID: `play-e37a6`
- API keys should be unique and secure
- Files should be automatically ignored by git (check `.gitignore`)

## Template Files
- `lib/firebase_options.dart.template` - Template for Firebase options
- `android/app/google-services.json.template` - Template for Android configuration

## Security Best Practices
1. ✅ Keep Firebase config files local only
2. ✅ Use environment variables for sensitive data in production
3. ✅ Regularly rotate API keys
4. ✅ Monitor for exposed secrets with tools like GitGuardian
5. ✅ Never commit API keys to public repositories

## Troubleshooting
If you see "Firebase not initialized" errors:
1. Run `flutterfire configure --project=play-e37a6`
2. Ensure the generated files are in the correct locations
3. Restart your development server
