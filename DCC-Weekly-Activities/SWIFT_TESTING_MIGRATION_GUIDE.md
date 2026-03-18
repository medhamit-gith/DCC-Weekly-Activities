# Swift Testing Framework Migration Guide

## Overview

This project has been fully migrated from **XCTest** to the modern **Swift Testing** framework. All future tests must use Swift Testing.

**Migration Date:** February 21, 2026  
**Files Converted:** 4 test files  
**Total Tests:** 50+ test cases

---

## ✅ What Was Changed

### Files Converted to Swift Testing

1. **ModelTests.swift** - Data model tests (Activity, MemberStats)
2. **ModelTests_XCTest.swift** - Fixed to use Swift Testing instead of XCTest
3. **RootViewTests.swift** - Already using Swift Testing ✓
4. **SampleTests.swift** - Already using Swift Testing ✓
5. **TestConfiguration.swift** - Test utilities and helpers

### Key Changes Made

#### Import Statements
```swift
// ❌ OLD (XCTest)
import XCTest
@testable import DCC_Weekly_Activities

// ✅ NEW (Swift Testing)
import Testing
import Foundation
@testable import DCC_Weekly_Activities
```

#### Test Structure
```swift
// ❌ OLD (XCTest)
final class ActivityModelTests: XCTestCase {
    func testActivityInitialization() {
        // test code
    }
}

// ✅ NEW (Swift Testing)
@Suite("Activity Model Tests")
struct ActivityModelTests {
    @Test("Activity initialization")
    func activityInitialization() async throws {
        // test code
    }
}
```

#### Assertions
```swift
// ❌ OLD (XCTest)
XCTAssertEqual(value, expected)
XCTAssertTrue(condition)
XCTAssertNotNil(object)
XCTAssertGreaterThan(a, b)

// ✅ NEW (Swift Testing)
#expect(value == expected)
#expect(condition)
#expect(object != nil)
#expect(a > b)
```

#### Setup and Teardown
```swift
// ❌ OLD (XCTest)
final class MyTests: XCTestCase {
    var testData: [String]!
    
    override func setUp() {
        super.setUp()
        testData = ["a", "b", "c"]
    }
}

// ✅ NEW (Swift Testing)
@Suite("My Tests")
struct MyTests {
    // Use a helper method instead
    func createTestData() -> [String] {
        ["a", "b", "c"]
    }
    
    @Test("Test with data")
    func testWithData() {
        let testData = createTestData()
        // use testData
    }
}
```

---

## 🎯 Writing New Tests - Quick Reference

### Basic Test Template

```swift
import Testing
import Foundation
@testable import DCC_Weekly_Activities

@Suite("Feature Name Tests")
struct FeatureTests {
    
    @Test("What this test validates")
    func descriptiveTestName() async throws {
        // Arrange - Set up test data
        let input = "test"
        
        // Act - Perform the action
        let result = process(input)
        
        // Assert - Verify the result
        #expect(result == expected)
    }
}
```

### Common Assertion Patterns

```swift
// Equality
#expect(actual == expected)
#expect(actual != unexpected)

// Optionals
#expect(value != nil, "Value should not be nil")
let unwrapped = try #require(optionalValue)

// Collections
#expect(array.isEmpty)
#expect(array.count == 5)
#expect(array.contains(item))
#expect(array.allSatisfy { $0 > 0 })

// Numeric comparisons
#expect(value > 0)
#expect(abs(actual - expected) < 0.01) // For floating point

// Boolean conditions
#expect(condition == true)
#expect(!condition)

// Custom messages
#expect(value == expected, "Expected \(expected) but got \(value)")
```

### Testing Async Code

```swift
@Test("Async operation")
func testAsyncOperation() async throws {
    let result = await fetchData()
    #expect(result.count > 0)
}
```

### Testing Errors

```swift
@Test("Error thrown for invalid input")
func testErrorThrown() async throws {
    #expect(throws: ValidationError.self) {
        try validateInput("")
    }
}
```

### Parameterized Tests

```swift
@Test("Multiple inputs", arguments: [
    ("input1", "expected1"),
    ("input2", "expected2"),
    ("input3", "expected3")
])
func testMultipleInputs(input: String, expected: String) async throws {
    let result = process(input)
    #expect(result == expected)
}
```

### Test Data Factory Pattern

```swift
// Always use TestDataFactory for consistent test data
@Test("Using test factory")
func testWithFactory() async throws {
    let activity = TestDataFactory.sampleRunActivity
    #expect(activity.type == "Run")
}

// For custom data
@Test("Custom test data")
func testWithCustomData() async throws {
    let activity = TestDataFactory.createSampleActivity(
        memberName: "Test User",
        distance: 10.0,
        type: "Ride"
    )
    #expect(activity.distance == 10.0)
}
```

---

## 📋 Migration Checklist for New Tests

When writing any new test:

- [ ] Use `import Testing` instead of `import XCTest`
- [ ] Use `@Suite` struct instead of `class XCTestCase`
- [ ] Use `@Test` annotation with descriptive names
- [ ] Use `#expect()` instead of `XCTAssert*()`
- [ ] Use `try #require()` instead of `XCTUnwrap()`
- [ ] Mark tests as `async throws` when appropriate
- [ ] Use helper methods instead of `setUp()`/`tearDown()`
- [ ] Include descriptive test names in natural language
- [ ] Add custom messages to assertions when helpful

---

## 🎨 Best Practices

### ✅ DO

1. **Use descriptive suite and test names**
   ```swift
   @Suite("User Authentication Flow")
   struct UserAuthTests {
       @Test("User can log in with valid credentials")
       func userCanLogInWithValidCredentials() async throws {
           // ...
       }
   }
   ```

2. **Test one thing per test**
   ```swift
   @Test("Activity calculates distance correctly")
   func activityCalculatesDistance() async throws {
       let activity = TestDataFactory.sampleRunActivity
       #expect(activity.distance == 5.0)
   }
   ```

3. **Use helper methods for setup**
   ```swift
   func createSampleActivities() -> [Activity] {
       [
           TestDataFactory.sampleRunActivity,
           TestDataFactory.sampleRideActivity
       ]
   }
   ```

4. **Test edge cases**
   ```swift
   @Test("Activity handles zero distance")
   func activityHandlesZeroDistance() async throws {
       let activity = TestDataFactory.activityWithZeroValues
       #expect(activity.distance == 0.0)
   }
   ```

### ❌ DON'T

1. **Don't use XCTest assertions**
   ```swift
   // ❌ WRONG
   XCTAssertEqual(value, expected)
   
   // ✅ RIGHT
   #expect(value == expected)
   ```

2. **Don't use test classes**
   ```swift
   // ❌ WRONG
   final class MyTests: XCTestCase { }
   
   // ✅ RIGHT
   @Suite("My Tests")
   struct MyTests { }
   ```

3. **Don't use instance variables for test data**
   ```swift
   // ❌ WRONG
   struct MyTests {
       var testData: [String] = []  // Don't do this
   }
   
   // ✅ RIGHT
   struct MyTests {
       func createTestData() -> [String] {
           ["a", "b", "c"]
       }
   }
   ```

4. **Don't skip adding descriptive names**
   ```swift
   // ❌ WRONG
   @Test func test1() { }
   
   // ✅ RIGHT
   @Test("User profile displays correct name")
   func userProfileDisplaysCorrectName() { }
   ```

---

## 🔍 Complete XCTest to Swift Testing Mapping

| XCTest | Swift Testing | Notes |
|--------|---------------|-------|
| `final class MyTests: XCTestCase` | `@Suite("My Tests") struct MyTests` | Use structs with @Suite |
| `func testSomething()` | `@Test("Something") func something()` | Use @Test annotation |
| `XCTAssertEqual(a, b)` | `#expect(a == b)` | Use #expect macro |
| `XCTAssertNotEqual(a, b)` | `#expect(a != b)` | Use #expect with != |
| `XCTAssertTrue(condition)` | `#expect(condition)` | Direct boolean check |
| `XCTAssertFalse(condition)` | `#expect(!condition)` | Negate with ! |
| `XCTAssertNil(value)` | `#expect(value == nil)` | Check for nil |
| `XCTAssertNotNil(value)` | `#expect(value != nil)` | Check not nil |
| `XCTUnwrap(optional)` | `try #require(optional)` | Unwrap optionals |
| `XCTAssertGreaterThan(a, b)` | `#expect(a > b)` | Direct comparison |
| `XCTAssertLessThan(a, b)` | `#expect(a < b)` | Direct comparison |
| `XCTAssertEqual(a, b, accuracy: 0.01)` | `#expect(abs(a - b) < 0.01)` | For floating point |
| `XCTAssertThrowsError` | `#expect(throws: Error.self) { }` | Error testing |
| `setUp()` / `tearDown()` | Helper methods | Use functions instead |
| `setUpWithError()` | N/A | Use helper methods |
| `addTeardownBlock { }` | N/A | Use defer if needed |

---

## 📊 Test Organization

### Current Test Structure

```
DCC-Weekly-Activities Tests/
├── ModelTests.swift              ✅ Core data model tests
├── ModelTests_XCTest.swift       ✅ Extended model tests
├── RootViewTests.swift           ✅ View hierarchy tests
├── SampleTests.swift             ✅ Example/reference tests
└── TestConfiguration.swift       ✅ Shared utilities
```

### Test Suites in the Project

1. **Activity Model Tests** - Testing Activity struct
2. **MemberStats Model Tests** - Testing MemberStats calculations
3. **Trend Calculation Tests** - Testing trend algorithms
4. **Data Aggregation Tests** - Testing data grouping/sorting
5. **Edge Case Tests** - Testing boundary conditions
6. **RootView Structure Tests** - Testing view initialization
7. **ActivityRow Tests** - Testing row display logic
8. **ActivityDetailView Tests** - Testing detail views
9. **WeeklyDashboardView Tests** - Testing dashboard logic
10. **View State Tests** - Testing loading/error states
11. **Navigation Tests** - Testing navigation flows
12. **Glass Component Tests** - Testing glass UI components
13. **Performance Tests** - Testing with large datasets

---

## 🚀 Running Tests

### In Xcode

1. **Run all tests:** ⌘U
2. **Run specific suite:** Click diamond next to @Suite
3. **Run specific test:** Click diamond next to @Test
4. **View results:** ⌘6 (Test Navigator)

### Command Line

```bash
# Run all tests
xcodebuild test -scheme "DCC-Weekly-Activities" -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test
xcodebuild test -scheme "DCC-Weekly-Activities" -only-testing:DCC-Weekly-ActivitiesTests/ActivityModelTests
```

---

## 📚 Examples from the Project

### Simple Test
```swift
@Test("Activity default initialization")
func activityDefaultInitialization() async throws {
    let activity = Activity(
        memberName: "John Doe",
        activityName: "Morning Run",
        distance: 5.0,
        date: Date(),
        averageSpeed: 10.0,
        elevationGain: 50.0,
        movingTime: 1800
    )
    
    #expect(activity.memberName == "John Doe")
    #expect(activity.distance == 5.0)
    #expect(activity.type == "Ride", "Default type should be Ride")
}
```

### Test with Helper Method
```swift
@Suite("MemberStats Model Tests")
struct MemberStatsModelTests {
    
    func createSampleActivities() -> [Activity] {
        [
            Activity(memberName: "Alice", activityName: "Run 1", distance: 5.0, ...),
            Activity(memberName: "Alice", activityName: "Run 2", distance: 8.0, ...),
            Activity(memberName: "Alice", activityName: "Run 3", distance: 10.0, ...)
        ]
    }
    
    @Test("MemberStats calculates totals")
    func memberStatsCalculatesTotals() async throws {
        let sampleActivities = createSampleActivities()
        let stats = MemberStats(memberName: "Alice", activities: sampleActivities)
        
        #expect(stats.totalRides == 3)
        #expect(stats.totalKM == 23.0, "Total should be 5 + 8 + 10 = 23")
    }
}
```

### Edge Case Test
```swift
@Test("Activity with zero values")
func activityWithZeroValues() async throws {
    let activity = Activity(
        memberName: "Rest Day",
        activityName: "Recovery Walk",
        distance: 0.0,
        date: Date(),
        averageSpeed: 0.0,
        elevationGain: 0.0,
        movingTime: 0,
        type: "Walk"
    )
    
    #expect(activity.distance == 0.0)
    #expect(activity.averageSpeed == 0.0)
}
```

---

## 🎓 Additional Resources

### Apple Documentation
- [Swift Testing Overview](https://developer.apple.com/documentation/testing)
- [Writing Tests with Swift Testing](https://developer.apple.com/documentation/testing/writing-tests)
- [Migrating from XCTest](https://developer.apple.com/documentation/testing/migrating-from-xctest)

### Key Advantages of Swift Testing

1. **Modern Swift syntax** - Uses macros, structured concurrency
2. **Better error messages** - More descriptive failure output
3. **Flexible organization** - Suites don't need inheritance
4. **Parameterized tests** - Test multiple inputs easily
5. **Better performance** - Faster test execution
6. **Type safety** - Catch more errors at compile time

---

## ⚠️ Important Notes

### Breaking Changes to Avoid

1. **Never use XCTest in new tests** - Only Swift Testing going forward
2. **Don't import both frameworks** - Pick one (Swift Testing)
3. **Test files must use Testing framework** - No exceptions

### Migration Verification

All test files have been verified to:
- ✅ Import `Testing` instead of `XCTest`
- ✅ Use `@Suite` and `@Test` annotations
- ✅ Use `#expect()` assertions
- ✅ Follow async/await patterns
- ✅ Use helper methods instead of setUp/tearDown
- ✅ Include descriptive test names

---

## 📝 Quick Start for New Tests

1. **Create new test file:**
   ```swift
   import Testing
   import Foundation
   @testable import DCC_Weekly_Activities
   
   @Suite("New Feature Tests")
   struct NewFeatureTests {
       
       @Test("Feature behavior")
       func featureBehavior() async throws {
           // Arrange
           let input = createTestInput()
           
           // Act
           let result = performAction(input)
           
           // Assert
           #expect(result.isValid)
       }
   }
   ```

2. **Add it to test target** in Xcode

3. **Run tests** with ⌘U

4. **Verify in Test Navigator** (⌘6)

---

## 🔧 Troubleshooting

### Common Issues

**Problem:** `No such module 'Testing'`
**Solution:** Make sure you're using Xcode 15+ and targeting iOS 16+/macOS 13+

**Problem:** `Cannot find 'XCTAssertEqual' in scope`
**Solution:** You're still using XCTest syntax. Change to `#expect()`

**Problem:** `Type 'MyTests' does not conform to protocol 'XCTestCase'`
**Solution:** Remove `: XCTestCase` and add `@Suite` annotation

**Problem:** Tests not showing up in Test Navigator
**Solution:** Make sure file is added to test target and uses `@Test` annotation

---

## ✨ Summary

**Swift Testing is now the standard for this project.** All new tests must use:

- ✅ `import Testing`
- ✅ `@Suite` for test organization
- ✅ `@Test` for individual tests
- ✅ `#expect()` for assertions
- ✅ `try #require()` for unwrapping
- ✅ Descriptive names in natural language
- ✅ Helper methods instead of setUp/tearDown

**See `SampleTests.swift` for comprehensive examples and patterns.**

---

*Last Updated: February 21, 2026*
*Migration Status: ✅ Complete - All test files converted*
