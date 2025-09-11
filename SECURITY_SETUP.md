# Security Setup Guide

This guide explains how to securely manage API keys and sensitive configuration in the Sessionizer project.

## 🔒 Security Issues Resolved

The following security alerts have been resolved:
- ✅ Removed hardcoded Google API keys from Firebase options files
- ✅ Implemented environment variable-based configuration
- ✅ Added proper .gitignore rules for sensitive files
- ✅ Created secure build scripts

## 🛠️ Setup Instructions

### 1. Create Environment File

Copy the example environment file and fill in your actual values:

```bash
cp env.example .env
```

### 2. Configure Your .env File

Edit `.env` with your actual API keys:

```env
# Firebase Configuration
FIREBASE_API_KEY_DEV=your_actual_development_firebase_api_key
FIREBASE_API_KEY_PROD=your_actual_production_firebase_api_key

# SendGrid API Key
SENDGRID_API_KEY=your_actual_sendgrid_api_key

# Google OAuth Client ID
GOOGLE_CLIENT_ID=your_actual_google_client_id
```

### 3. Generate Firebase Options Files

Run the secure build script to generate the Firebase options files:

```bash
# For development
dart run scripts/build_secure.dart development

# For production
dart run scripts/build_secure.dart production
```

Or use the PowerShell script:

```powershell
# For development
.\build_secure.ps1 -Environment development

# For production
.\build_secure.ps1 -Environment production
```

### 4. Build the Application

The build script will automatically:
- ✅ Read API keys from environment variables
- ✅ Update Firebase options files with secure configuration
- ✅ Build the Flutter web app with proper environment variables

## 🔐 Security Features

### Environment Variable Management
- All API keys are stored in `.env` file (not committed to git)
- Firebase options files use `String.fromEnvironment()` for secure key injection
- Build scripts validate that all required keys are present

### Git Security
- `.env` files are ignored by git
- Firebase options files with real keys are ignored
- Template files are kept for reference
- Sensitive files are properly excluded from version control

### Build Process
- API keys are injected at build time via `--dart-define`
- No hardcoded secrets in source code
- Environment-specific configuration support

## 🚨 Important Security Notes

1. **Never commit `.env` files** - They contain sensitive API keys
2. **Use different API keys** for development and production
3. **Rotate API keys regularly** for enhanced security
4. **Keep template files** for reference but don't commit actual config files
5. **Use environment variables** in CI/CD pipelines instead of hardcoded values

## 🔄 API Key Rotation

If you need to rotate API keys:

1. Update the keys in your `.env` file
2. Regenerate the Firebase options files
3. Rebuild the application
4. Deploy the updated version

## 📁 File Structure

```
├── .env                          # Your actual API keys (ignored by git)
├── env.example                   # Template for environment variables
├── lib/
│   ├── firebase_options_development.dart      # Generated (ignored by git)
│   ├── firebase_options_production.dart       # Generated (ignored by git)
│   ├── firebase_options_development.dart.template  # Template
│   └── firebase_options_production.dart.template   # Template
├── scripts/
│   ├── build_secure.dart         # Secure build script
│   └── build_web.dart           # Legacy build script
└── build_secure.ps1             # PowerShell build script
```

## ✅ Verification

To verify your setup is secure:

1. Check that `.env` is in `.gitignore`
2. Verify Firebase options files use `String.fromEnvironment()`
3. Confirm no hardcoded API keys in source code
4. Test that build process works with environment variables

Your application is now secure and ready for deployment! 🎉