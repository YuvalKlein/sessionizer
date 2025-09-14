#!/bin/bash

# Pre-commit test script for ARENNA Sessionizer
# Run this before committing to catch issues early

echo "🧪 ARENNA Pre-Commit Test Runner"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}🔍 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

print_status "Getting Flutter dependencies..."
flutter pub get

if [ $? -ne 0 ]; then
    print_error "Failed to get dependencies"
    exit 1
fi

print_success "Dependencies updated"

# Run code analysis
print_status "Running code analysis..."
flutter analyze

if [ $? -ne 0 ]; then
    print_error "Code analysis failed - please fix issues before committing"
    exit 1
fi

print_success "Code analysis passed"

# Run unit tests
print_status "Running unit tests..."
flutter test

if [ $? -ne 0 ]; then
    print_error "Unit tests failed - please fix failing tests before committing"
    exit 1
fi

print_success "All unit tests passed"

# Check for common issues
print_status "Checking for common issues..."

# Check for hardcoded test data
if grep -r "yuklein@gmail.com" lib/ --exclude-dir=node_modules >/dev/null 2>&1; then
    print_warning "Hardcoded test emails found in code"
fi

# Check for debug prints
if grep -r "print(" lib/ --exclude-dir=node_modules | grep -v "// TODO" | grep -v "// DEBUG" >/dev/null 2>&1; then
    print_warning "Debug print statements found - consider using AppLogger instead"
fi

# Check for TODO comments
todo_count=$(grep -r "TODO" lib/ --exclude-dir=node_modules | wc -l)
if [ $todo_count -gt 0 ]; then
    print_warning "Found $todo_count TODO comments in code"
fi

print_success "Pre-commit checks completed"

# Try to build (quick check)
print_status "Testing development build..."
flutter build web --dart-define=ENVIRONMENT=development >/dev/null 2>&1

if [ $? -ne 0 ]; then
    print_error "Development build failed"
    exit 1
fi

print_success "Development build successful"

echo ""
echo -e "${GREEN}🎉 All pre-commit checks passed!${NC}"
echo -e "${GREEN}✅ Safe to commit your changes${NC}"
echo ""
echo "📊 Test Summary:"
echo "  - Code analysis: ✅ Passed"
echo "  - Unit tests: ✅ All passed"
echo "  - Build test: ✅ Successful"
echo ""
echo "🚀 Your code is ready for commit!"
