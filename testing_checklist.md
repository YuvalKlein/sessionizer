# Pre-Deployment Testing Checklist

## 🔍 **Before ANY Deployment**

### 1. **Local Testing**
- [ ] `flutter run -d chrome --web-port=8080` works
- [ ] App loads and shows login page
- [ ] Firebase connects successfully
- [ ] Google Sign-In button appears
- [ ] No console errors in browser dev tools

### 2. **Unit Tests**
- [ ] `flutter test` passes all tests
- [ ] No failing unit tests
- [ ] Core functionality tests pass

### 3. **Integration Testing**
- [ ] Fix any failing integration tests BEFORE deployment
- [ ] Test authentication flow
- [ ] Test booking creation
- [ ] Test session management

### 4. **Cross-Browser Testing**
- [ ] Chrome (desktop)
- [ ] Safari (desktop)
- [ ] Firefox (desktop)
- [ ] Mobile Chrome
- [ ] Mobile Safari (iOS)

### 5. **iOS Safari Specific Testing**
- [ ] Test on actual iPhone
- [ ] Test viewport behavior
- [ ] Test Google Sign-In popup
- [ ] Test touch interactions
- [ ] Test loading performance

### 6. **Build Testing**
- [ ] `flutter build web --release` succeeds
- [ ] Built files work in local server
- [ ] No build warnings or errors

## 🚀 **Deployment Process**

### 1. **Pre-Deployment**
```bash
# Run all tests
flutter test

# Build and test locally
flutter build web --release
cd build/web && python -m http.server 8000

# Test the built version at http://localhost:8000
```

### 2. **Deployment**
```bash
# Commit changes
git add .
git commit -m "Description of changes"

# Push to repository
git push origin yuvalSchedule

# Deploy to Firebase
firebase deploy --only hosting
```

### 3. **Post-Deployment**
- [ ] Test production URL immediately
- [ ] Test on multiple devices/browsers
- [ ] Monitor for any errors
- [ ] Have rollback plan ready

## ⚠️ **Never Deploy If:**
- Any tests are failing
- Local environment doesn't work
- Build process fails
- Haven't tested changes locally

## 📱 **iPhone Testing Commands**
```bash
# Test iOS Safari compatibility
flutter run -d chrome --web-port=8080
# Then test in iPhone Safari at: http://[your-ip]:8080
```


