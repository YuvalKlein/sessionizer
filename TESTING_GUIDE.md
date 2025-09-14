# 🧪 ARENNA Testing Guide

## 🎯 **Testing Strategy**

This project follows a comprehensive testing strategy to prevent breaking changes and ensure code quality.

### **📊 Current Test Coverage: 68 Tests**

- ✅ **Unit Tests**: 68 tests covering critical business logic
- ✅ **Widget Tests**: Coming soon
- ✅ **Integration Tests**: Coming soon
- ✅ **CI/CD Pipeline**: Automated testing on every commit

## 🧪 **Test Categories**

### **1. Unit Tests (68 tests)**

**📋 Cancellation Policy Tests (11 tests)**
```bash
flutter test test/features/session_type/domain/entities/
flutter test test/core/services/cancellation_policy_service_test.dart
```
- Fee calculations (percentage vs fixed dollar)
- Time conversions (hours, minutes, days)
- Policy agreement storage and retrieval
- Edge cases and boundary testing

**🔒 Booking Validation Tests (13 tests)**
```bash
flutter test test/core/utils/booking_validator_test.dart
```
- Minimum hours ahead validation
- Maximum days ahead constraints
- Cancellation window detection
- Past booking prevention

**🔐 Authentication Tests (14 tests)**
```bash
flutter test test/features/auth/domain/usecases/
```
- Sign in/sign up use case testing
- Error handling validation
- Parameter validation
- Role-based user creation

**⚙️ Service Integration Tests (30 tests)**
```bash
flutter test test/core/services/
flutter test test/core/config/
```
- Google Calendar service behavior
- Email service interface validation
- Environment configuration testing
- Critical production bug prevention

## 🚀 **Running Tests**

### **Run All Tests**
```bash
flutter test
```

### **Run Specific Test Categories**
```bash
# Unit tests only
flutter test test/features/ test/core/

# Specific feature tests
flutter test test/features/session_type/
flutter test test/features/auth/

# Service tests
flutter test test/core/services/
```

### **Run Tests with Coverage**
```bash
flutter test --coverage
```

### **Pre-Commit Testing (Recommended)**
```bash
# Windows
.\scripts\pre-commit-tests.ps1

# Linux/Mac
./scripts/pre-commit-tests.sh
```

## 🛡️ **Critical Business Logic Protected**

### **Cancellation Fee Calculations**
```dart
// ✅ Protected by tests:
sessionType.getActualCancellationFee()
// - Percentage calculations (50% of $120 = $60)
// - Fixed dollar amounts ($25 regardless of price)
// - Edge cases (0%, 100%, rounding)
```

### **Booking Validation**
```dart
// ✅ Protected by tests:
BookingValidator.validateBooking()
// - Time constraints (min/max hours ahead)
// - Past booking prevention
// - Cancellation window detection
```

### **Environment Configuration**
```dart
// ✅ Protected by tests:
EnvironmentConfig.databaseId // Must be '(default)' for both dev/prod
EnvironmentConfig.collectionPrefix // 'DevData' vs 'ProdData'
// - Prevents production database connection errors
// - Ensures proper environment separation
```

## 🔄 **Continuous Integration**

### **GitHub Actions Workflow**
- ✅ **Automated testing** on every push/PR
- ✅ **Build verification** for both dev and production
- ✅ **Code analysis** to catch style issues
- ✅ **Security checks** for secrets and hardcoded data
- ✅ **Coverage reporting** to track test coverage

### **Branch Protection**
- Tests must pass before merging to main branches
- Code analysis must pass
- Build must succeed

## 📝 **Writing New Tests**

### **Unit Test Template**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/path/to/your/class.dart';

void main() {
  group('YourClass', () {
    test('should do something when condition is met', () {
      // Arrange
      final instance = YourClass();
      
      // Act
      final result = instance.doSomething();
      
      // Assert
      expect(result, equals(expectedValue));
    });
  });
}
```

### **Mock-based Test Template**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([YourDependency])
void main() {
  late YourClass instance;
  late MockYourDependency mockDependency;

  setUp(() {
    mockDependency = MockYourDependency();
    instance = YourClass(mockDependency);
  });

  test('should call dependency correctly', () async {
    // Arrange
    when(mockDependency.method()).thenAnswer((_) async => 'result');
    
    // Act
    final result = await instance.useMethod();
    
    // Assert
    verify(mockDependency.method()).called(1);
    expect(result, equals('expected'));
  });
}
```

## 🚨 **Test-Driven Development Workflow**

### **For New Features:**
1. **Write failing test** first (Red)
2. **Write minimal code** to make it pass (Green)
3. **Refactor** while keeping tests green (Refactor)
4. **Repeat** for each requirement

### **For Bug Fixes:**
1. **Write test** that reproduces the bug
2. **Verify test fails** (confirms bug exists)
3. **Fix the bug** until test passes
4. **Verify** all other tests still pass

## 📊 **Test Quality Guidelines**

### **Good Tests Are:**
- ✅ **Fast**: Run in seconds, not minutes
- ✅ **Isolated**: Don't depend on external services
- ✅ **Deterministic**: Same input always gives same output
- ✅ **Readable**: Clear arrange/act/assert structure
- ✅ **Focused**: Test one thing at a time

### **Test Naming Convention:**
```dart
test('should [expected behavior] when [condition]', () {
  // Example:
  // 'should return 60 when calculating 50% of $120'
  // 'should reject booking when time is in the past'
});
```

## 🔧 **Troubleshooting Tests**

### **Common Issues:**

**Tests fail after dependency changes:**
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

**Mock generation issues:**
```bash
flutter packages pub run build_runner build
```

**Test compilation errors:**
```bash
flutter clean
flutter pub get
flutter test
```

## 📈 **Benefits Achieved**

### **Before Testing:**
- ❌ Changes broke existing features
- ❌ Manual regression testing required
- ❌ Production bugs from environment issues
- ❌ No confidence in code changes

### **After Testing (68 tests):**
- ✅ **Immediate feedback** on breaking changes
- ✅ **Automated regression testing**
- ✅ **Production bug prevention**
- ✅ **Confidence** to make changes safely
- ✅ **Faster development** (no manual testing loops)

## 🎯 **Success Metrics**

- **68 tests passing** ✅
- **Critical business logic protected** ✅
- **Environment configuration validated** ✅
- **Authentication flows tested** ✅
- **Service interfaces verified** ✅

## 🚀 **Next Steps**

1. **Widget Tests**: Test critical UI components
2. **Integration Tests**: Test complete user flows
3. **Performance Tests**: Ensure app remains fast
4. **Accessibility Tests**: Ensure app is accessible

---

*This testing strategy solves the core problem: "Each time we make changes, something else breaks"*

**Now we have 68 tests that will catch breaking changes immediately!** 🛡️