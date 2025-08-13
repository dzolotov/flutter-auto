#!/bin/bash

# Flutter Automotive Demo - Comprehensive Test Runner
# This script runs all tests and generates coverage reports

set -e  # Exit on error

echo "======================================"
echo "Flutter Automotive Demo - Test Runner"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

print_status "Flutter SDK found"

# Clean previous coverage data
print_status "Cleaning previous coverage data..."
rm -rf coverage/
mkdir -p coverage

# Get dependencies
print_status "Getting Flutter dependencies..."
flutter pub get

# Run Flutter analyze
print_status "Running static analysis..."
if flutter analyze --no-fatal-infos; then
    print_status "Static analysis passed"
else
    print_error "Static analysis failed"
    exit 1
fi

# Run unit tests with coverage
print_status "Running unit tests..."
if flutter test test/unit/ --coverage --coverage-path=coverage/unit_lcov.info; then
    print_status "Unit tests passed"
else
    print_error "Unit tests failed"
    exit 1
fi

# Run widget tests with coverage
print_status "Running widget tests..."
if flutter test test/widget/ --coverage --coverage-path=coverage/widget_lcov.info; then
    print_status "Widget tests passed"
else
    print_error "Widget tests failed"
    exit 1
fi

# Run integration tests
print_status "Running integration tests..."
if flutter test test/integration/ --coverage --coverage-path=coverage/integration_lcov.info; then
    print_status "Integration tests passed"
else
    print_error "Integration tests failed"
    exit 1
fi

# Combine coverage data
print_status "Combining coverage data..."
if command -v lcov &> /dev/null; then
    lcov --add-tracefile coverage/unit_lcov.info \
         --add-tracefile coverage/widget_lcov.info \
         --add-tracefile coverage/integration_lcov.info \
         --output-file coverage/lcov.info
    
    # Remove unnecessary files from coverage
    lcov --remove coverage/lcov.info \
         '*/test/*' \
         '*.g.dart' \
         '*.freezed.dart' \
         '*/main.dart' \
         --output-file coverage/lcov_filtered.info
    
    mv coverage/lcov_filtered.info coverage/lcov.info
    
    # Generate HTML report
    print_status "Generating HTML coverage report..."
    genhtml coverage/lcov.info \
            --output-directory coverage/html \
            --title "Automotive Flutter Demo Coverage" \
            --show-details \
            --legend
    
    print_status "HTML coverage report generated at: coverage/html/index.html"
else
    print_warning "lcov not installed. Skipping detailed coverage report generation."
    print_warning "Install lcov for detailed reports: brew install lcov (macOS) or apt-get install lcov (Linux)"
fi

# Generate coverage summary
print_status "Generating coverage summary..."
flutter test --coverage

# Parse coverage percentage
if [ -f "coverage/lcov.info" ]; then
    if command -v lcov &> /dev/null; then
        COVERAGE_PERCENT=$(lcov --summary coverage/lcov.info 2>&1 | grep "lines" | grep -oE '[0-9]+\.[0-9]+%' | head -1)
        
        echo ""
        echo "======================================"
        echo "Coverage Summary"
        echo "======================================"
        echo "Total Coverage: ${COVERAGE_PERCENT}"
        
        # Extract percentage value for comparison
        COVERAGE_VALUE=$(echo $COVERAGE_PERCENT | grep -oE '[0-9]+' | head -1)
        
        if [ "$COVERAGE_VALUE" -ge 80 ]; then
            print_status "Coverage threshold met (≥80%)"
        else
            print_warning "Coverage below threshold (80%). Current: ${COVERAGE_PERCENT}"
            echo ""
            echo "Areas needing more tests:"
            
            # Find files with low coverage
            lcov --list coverage/lcov.info | while read line; do
                if [[ $line == *".dart"* ]]; then
                    FILE=$(echo $line | awk '{print $1}')
                    PERCENT=$(echo $line | awk '{print $2}' | grep -oE '[0-9]+')
                    if [ "$PERCENT" -lt 80 ]; then
                        echo "  - $FILE: ${PERCENT}%"
                    fi
                fi
            done
        fi
    else
        # Fallback: basic line count from lcov.info
        TOTAL_LINES=$(grep -c "DA:" coverage/lcov.info || echo "0")
        COVERED_LINES=$(grep "DA:" coverage/lcov.info | grep -c ",1" || echo "0")
        
        if [ "$TOTAL_LINES" -gt 0 ]; then
            COVERAGE_PERCENT=$((COVERED_LINES * 100 / TOTAL_LINES))
            echo ""
            echo "======================================"
            echo "Coverage Summary"
            echo "======================================"
            echo "Approximate Coverage: ${COVERAGE_PERCENT}%"
            echo "Lines Covered: ${COVERED_LINES}/${TOTAL_LINES}"
        fi
    fi
fi

# Create test report
print_status "Creating test report..."
cat > coverage/test_report.md << EOF
# Automotive Flutter Demo - Test Report

Generated: $(date)

## Test Results

- ✅ Unit Tests: Passed
- ✅ Widget Tests: Passed  
- ✅ Integration Tests: Passed

## Coverage Summary

Total Coverage: ${COVERAGE_PERCENT}

### Coverage by Category

- Services: Tests for CAN bus simulator, physics simulation, etc.
- Widgets: Tests for dashboard components (speedometer, RPM gauge, fuel gauge)
- Integration: End-to-end tests for dashboard functionality

## Recommendations

1. Maintain minimum 80% code coverage
2. Add tests for any new features before deployment
3. Run tests before each commit
4. Review coverage reports regularly

## View Detailed Report

Open \`coverage/html/index.html\` in a browser for detailed coverage report.
EOF

print_status "Test report created at: coverage/test_report.md"

echo ""
echo "======================================"
echo "Test Execution Complete!"
echo "======================================"
echo ""
echo "Next steps:"
echo "1. Review coverage report: open coverage/html/index.html"
echo "2. Fix any failing tests"
echo "3. Add tests for uncovered code"
echo "4. Run tests again before deployment"
echo ""

# Exit with success
exit 0