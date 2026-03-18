# Testing Guide for DCC Weekly Activities

## Overview
This guide explains how to set up and run automated tests for the DCC Weekly Activities app. Tests are designed to catch interface breaks and logic errors during the build process.

## Test Files Created

### 1. **RootViewTests.swift**
Comprehensive tests for all UI components and views:

- **RootView Structure Tests**: Validates that all main views can be instantiated
- **ActivityRow Tests**: Tests activity display with various data types
- **ActivityDetailView Tests**: Tests detail view, duration formatting, and member filtering
- **WeeklyDashboardView Tests**: Tests dashboard initialization and data building
- **View State Tests**: Tests loading, error, and auth error states
- **Navigation Tests**: Tests navigation flows and tab structure
- **Edge Case Tests**: Tests empty states, special characters, extreme values
- **Glass Component Tests**: Tests all Liquid Glass UI components
- **Performance Tests**: Tests with large datasets (1000+ activities)

**Total Test Count**: ~40 tests

### 2. **ModelTests.swift**
Tests for all data models and business logic:

- **Activity Model Tests**: Tests initialization, unique IDs, edge cases
- **MemberStats Model Tests**: Tests calculations, totals, averages
- **Trend Calculation Tests**: Tests all trend states (new, up, down, stable)
- **Data Aggregation Tests**: Tests grouping, filtering, sorting
- **Model Edge Cases**: Tests precision, special cases, mixed types

**Total Test Count**: ~35 tests

## Setting Up Test Target in Xcode

### Step 1: Create Test Target

1. Open your project in Xcode
2. Go to **File → New → Target**
3. Select **Unit Testing Bundle**
4. Name it: `DCC-Weekly-Activities Tests`
5. Ensure "Host Application" is set to your main app
6. Click **Finish**

### Step 2: Add Test Files to Target

1. In the Project Navigator, find `RootViewTests.swift` and `ModelTests.swift`
2. Open the File Inspector (⌥⌘1)
3. Under "Target Membership", check the box for your test target
4. Make sure the files are **not** added to the main app target

### Step 3: Configure Test Target Settings

1. Select your project in the Project Navigator
2. Select the **Test Target** from the target list
3. Go to **Build Settings**
4. Search for "Testing" and configure:
   - **Enable Testing Search Paths**: Yes
   - **Enable Testability**: Yes

5. Go to your **main app target** Build Settings
6. Search for "Testability"
7. Set **Enable Testability** to **Yes** (for Debug configuration)

### Step 4: Import Testing Framework

The test files use Swift Testing framework. Ensure your test target has:

```swift
import Testing
@testable import DCC_Weekly_Activities
```

If you see module import errors:
1. Make sure your app module is named `DCC_Weekly_Activities` (with underscores, not hyphens)
2. Check that **Enable Testability** is enabled in your main target

### Step 5: Configure Test Plan (Optional but Recommended)

1. Go to **Product → Scheme → Edit Scheme**
2. Select **Test** from the left sidebar
3. Click the **+** button under "Test Plans"
4. Create a new test plan named "DCC-Tests"
5. Configure:
   - **Code Coverage**: ON (to see test coverage)
   - **Test Language**: System Language
   - **Test Region**: System Region

## Running Tests

### Manual Test Execution

#### Run All Tests
- Press **⌘U** (Command-U)
- Or: **Product → Test**

#### Run Specific Test Suite
1. Open the test file
2. Click the diamond icon next to `@Suite`
3. Or: Right-click the suite and select "Run 'SuiteName'"

#### Run Individual Test
1. Click the diamond icon next to `@Test`
2. Or: Place cursor in test and press **⌃⌥⌘U**

### Automated Test Execution During Build

#### Option 1: Pre-Build Test Scheme (Recommended)

1. Go to **Product → Scheme → Edit Scheme**
2. Select **Build** from left sidebar
3. Click **+** and add **Run Script** phase
4. Add this script:

```bash
# Run tests before building
if [ "$CONFIGURATION" = "Debug" ]; then
    xcodebuild test \
        -scheme "DCC-Weekly-Activities" \
        -destination 'platform=iOS Simulator,name=iPhone 15' \
        -quiet
fi
```

#### Option 2: Build Phase Script (Alternative)

1. Select your main app target
2. Go to **Build Phases**
3. Click **+** → **New Run Script Phase**
4. Drag it to be **first** in the list
5. Add this script:

```bash
# Run tests during build
if [ "${RUN_TESTS_ON_BUILD}" = "YES" ]; then
    echo "Running tests..."
    xcodebuild test \
        -scheme "${SCHEME_NAME}" \
        -destination 'platform=iOS Simulator,name=iPhone 15' \
        -quiet || exit 1
fi
```

6. In your scheme, add environment variable:
   - Key: `RUN_TESTS_ON_BUILD`
   - Value: `YES`

#### Option 3: Test Navigator (Quick Tests)

1. Open **Test Navigator** (⌘6)
2. You'll see all test suites and tests
3. Click the play button next to any suite or test
4. Failed tests show an X, passed tests show a checkmark

## Continuous Integration Setup

### GitHub Actions Example

Create `.github/workflows/test.yml`:

```yaml
name: Run Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Select Xcode
      run: sudo xcode-select -s /Applications/Xcode_15.2.app
    
    - name: Run Tests
      run: |
        xcodebuild test \
          -scheme DCC-Weekly-Activities \
          -destination 'platform=iOS Simulator,name=iPhone 15' \
          -enableCodeCoverage YES \
          | xcpretty
    
    - name: Upload Coverage
      uses: codecov/codecov-action@v3
```

## Test Coverage

### Viewing Coverage

1. Run tests with coverage: **Product → Test** (⌘U)
2. Open **Report Navigator** (⌘9)
3. Select latest test run
4. Click **Coverage** tab
5. See coverage percentages for each file

### Coverage Goals

- **Views**: 80%+ coverage
- **Models**: 95%+ coverage
- **Business Logic**: 100% coverage
- **UI Rendering**: 70%+ coverage

## Understanding Test Results

### Test Output

Tests use the Swift Testing framework with `#expect` assertions:

```swift
@Test("Description of what this tests")
func testName() async throws {
    #expect(value == expectedValue, "Helpful message if this fails")
}
```

### Common Test Failures

#### 1. View Can't Be Instantiated
```
❌ RootView should be instantiable
```
**Fix**: Check that all required @State/@StateObject properties are initialized

#### 2. Calculation Mismatch
```
❌ Total should be 5 + 8 + 10 = 23
```
**Fix**: Check the aggregation logic in MemberStats

#### 3. Missing View Component
```
❌ Cannot find 'SomeView' in scope
```
**Fix**: Ensure the view is defined and accessible to tests

## Test Organization

### Current Test Suites

1. **RootViewTests.swift**
   - RootView Structure Tests (4 tests)
   - ActivityRow Tests (5 tests)
   - ActivityDetailView Tests (6 tests)
   - WeeklyDashboardView Tests (3 tests)
   - View State Tests (3 tests)
   - Navigation Tests (2 tests)
   - Edge Cases Tests (6 tests)
   - Glass Component Tests (4 tests)
   - Performance Tests (2 tests)

2. **ModelTests.swift**
   - Activity Model Tests (8 tests)
   - MemberStats Model Tests (6 tests)
   - Trend Calculation Tests (6 tests)
   - Data Aggregation Tests (4 tests)
   - Model Edge Cases (5 tests)

### Adding New Tests

When you add a new view or feature:

1. Create a new `@Suite` in the appropriate test file:

```swift
@Suite("Your New Feature Tests")
struct YourNewFeatureTests {
    
    @Test("Feature works correctly")
    func featureWorksCorrectly() async throws {
        let feature = YourNewFeature()
        #expect(feature.isWorking)
    }
}
```

2. Run the new test to verify it passes
3. Commit the test with your feature code

## Debugging Failed Tests

### Using Breakpoints

1. Click line number in test file to add breakpoint
2. Run test in debug mode (⌃⌥⌘U)
3. Inspect variables in the debug area

### Using Print Debugging

```swift
@Test("Debug this test")
func debugTest() async throws {
    let value = calculateSomething()
    print("DEBUG: Value is \(value)")
    #expect(value == expected)
}
```

### Test Isolation

If a test fails intermittently:
1. Run it multiple times: Right-click → "Run Test Repeatedly"
2. Check for dependencies on Date(), UUID(), or other non-deterministic values
3. Use fixed test data

## Best Practices

### 1. Test Naming
- Use descriptive names: `activityWithZeroDistance` not `test1`
- Include what you're testing: `dashboardBuildsMemberStats`

### 2. Test Independence
- Each test should run independently
- Don't rely on test execution order
- Reset state between tests

### 3. Arrange-Act-Assert Pattern
```swift
@Test("Good test structure")
func goodTestStructure() async throws {
    // Arrange
    let activity = createTestActivity()
    
    // Act
    let result = processActivity(activity)
    
    // Assert
    #expect(result.isValid)
}
```

### 4. Test Data
- Use realistic test data
- Test edge cases (0, negative, very large)
- Test special characters and unicode

### 5. Performance
- Performance tests should complete quickly (<5 seconds)
- Use smaller datasets when possible
- Mark slow tests with comments

## Troubleshooting

### Issue: Tests Don't Run
**Solution**: 
- Check test target membership
- Verify scheme has tests enabled
- Clean build folder (⇧⌘K)

### Issue: "Module Not Found"
**Solution**:
- Check `@testable import DCC_Weekly_Activities` matches your module name
- Enable Testability in main target
- Build main target first

### Issue: Tests Pass Individually, Fail Together
**Solution**:
- Check for shared state between tests
- Reset singletons/shared instances
- Use dependency injection

### Issue: UI Tests Timing Out
**Solution**:
- These are unit tests, not UI tests
- Don't test actual rendering
- Test view initialization only

## Quick Reference

| Action | Shortcut |
|--------|----------|
| Run All Tests | ⌘U |
| Run Test Under Cursor | ⌃⌥⌘U |
| Re-run Last Test | ⌃⌥⌘G |
| Show Test Navigator | ⌘6 |
| Show Report Navigator | ⌘9 |
| Jump to Test | ⌃6, then select test |

## Next Steps

1. ✅ Create test target in Xcode
2. ✅ Add test files to target
3. ✅ Enable testability in main target
4. ✅ Run all tests (⌘U)
5. ✅ Check coverage report
6. ✅ Set up CI/CD pipeline
7. ✅ Add tests for new features

## Resources

- [Swift Testing Documentation](https://developer.apple.com/documentation/testing)
- [XCTest Framework](https://developer.apple.com/documentation/xctest)
- [Test Plans Guide](https://developer.apple.com/documentation/xcode/organizing-tests-to-improve-feedback)

---

**Last Updated**: February 2026
**Test Count**: 75+ tests across 2 files
**Coverage Goal**: 85%+
