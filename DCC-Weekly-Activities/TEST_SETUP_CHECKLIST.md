# Test Setup Checklist

## ✅ Quick Setup Guide (5 Minutes)

Follow these steps to get your tests running and catching interface breaks during builds.

### Step 1: Create Test Target (2 minutes)

1. **Open Xcode** and select your project file
2. Click **File → New → Target...**
3. Under **iOS**, select **Unit Testing Bundle**
4. Configure:
   - **Product Name**: `DCC-Weekly-Activities Tests`
   - **Team**: Your development team
   - **Organization Identifier**: Match your app
   - **Host Application**: DCC-Weekly-Activities
5. Click **Finish**
6. When asked "Would you like to create schemes?", click **Yes**

✅ **Verify**: You should see a new test target in your project navigator

---

### Step 2: Add Test Files to Target (1 minute)

1. In Project Navigator, select these files (one at a time):
   - `RootViewTests.swift`
   - `ModelTests.swift`
   - `TestConfiguration.swift`

2. For each file:
   - Open **File Inspector** (right panel, or press ⌥⌘1)
   - Under **Target Membership**, check **DCC-Weekly-Activities Tests**
   - **Uncheck** the main app target (if checked)

✅ **Verify**: Files should have test target icon in Project Navigator

---

### Step 3: Enable Testability (30 seconds)

1. Select your **main app target** (DCC-Weekly-Activities)
2. Go to **Build Settings** tab
3. Search for "testability"
4. Under **Enable Testability**, set to **Yes** (for Debug configuration)

✅ **Verify**: Search results show "Enable Testability: Yes"

---

### Step 4: Fix Module Name (30 seconds)

1. Open **RootViewTests.swift**
2. Look for this line:
   ```swift
   @testable import DCC_Weekly_Activities
   ```
3. If your app module name is different, update it:
   - Go to main target **Build Settings**
   - Search for "Product Module Name"
   - Copy the exact name
   - Update the import statement

✅ **Verify**: No "Module not found" errors

---

### Step 5: Run Tests (30 seconds)

1. Press **⌘U** or click **Product → Test**
2. Wait for tests to run (should take ~5-10 seconds)
3. Check **Test Navigator** (⌘6) for results

✅ **Verify**: You should see ~75 passing tests with green checkmarks

---

### Step 6: Set Up Auto-Run on Build (1 minute)

**Option A: Simple - Run on Debug Builds**

1. Go to **Product → Scheme → Edit Scheme...**
2. Select **Test** from left sidebar
3. Check **Test** for all your test files
4. Under **Options**, check:
   - ✅ **Code Coverage**
   - ✅ **Debug XPC services**
5. Click **Close**

Now: Every time you press **⌘U**, tests will run

**Option B: Advanced - Run Before Every Build**

1. Select your **test target**
2. Go to **Build Phases**
3. Click **+** → **New Run Script Phase**
4. Rename to "Auto-Run Tests"
5. Add this script:

```bash
#!/bin/bash
echo "🧪 Running tests before build..."

if [ "$CONFIGURATION" = "Debug" ]; then
    xcodebuild test \
        -scheme "DCC-Weekly-Activities" \
        -destination 'platform=iOS Simulator,name=iPhone 15' \
        -quiet \
        -only-testing:DCC-Weekly-Activities_Tests
        
    if [ $? -ne 0 ]; then
        echo "❌ Tests failed! Build cancelled."
        exit 1
    else
        echo "✅ All tests passed!"
    fi
fi
```

6. Check **For install builds only** (to skip on archive)

✅ **Verify**: Build will fail if tests fail

---

## Quick Verification

Run this checklist to ensure everything works:

- [ ] Press **⌘U** - tests should run
- [ ] Open **Test Navigator** (⌘6) - see all test suites
- [ ] Click diamond icon next to any test - runs individual test
- [ ] Press **⌘9** - see test report with results
- [ ] Make a breaking change in code - tests should fail
- [ ] Fix the change - tests should pass again

---

## What You Get

### 🎯 Test Coverage

| Component | Tests | What's Covered |
|-----------|-------|----------------|
| **Views** | 25 tests | All screens can render |
| **Models** | 35 tests | Data calculations correct |
| **Business Logic** | 15 tests | Stats, sorting, grouping |
| **Edge Cases** | 10 tests | Zero values, extremes, unicode |
| **Performance** | 2 tests | Large datasets (1000+ items) |

### 🔍 What Tests Catch

✅ **Interface Breaks**
- View can't be instantiated
- Missing required properties
- Type mismatches

✅ **Logic Errors**
- Incorrect calculations
- Wrong sorting
- Missing data

✅ **Edge Cases**
- Empty states
- Null values
- Extreme inputs

✅ **Regressions**
- Changes that break existing features
- Accidental deletions
- Refactoring mistakes

---

## Common Issues & Fixes

### ❌ Issue: "Cannot find module 'DCC_Weekly_Activities'"

**Fix:**
```swift
// Check your module name in Build Settings
// Product Module Name: DCC_Weekly_Activities

// Update import to match:
@testable import DCC_Weekly_Activities
```

### ❌ Issue: Tests don't appear in Test Navigator

**Fix:**
1. Clean build folder: **⇧⌘K**
2. Rebuild test target: **⌘B**
3. Restart Xcode

### ❌ Issue: "Enable Testability" not found

**Fix:**
1. Make sure you're in main **app target**, not test target
2. Check **All** settings (not Basic or Customized)
3. Search for "testability" (lowercase)

### ❌ Issue: Tests run but all fail

**Fix:**
```swift
// Check that your data types match
// Activity model should have these properties:
struct Activity {
    let memberName: String
    let activityName: String
    let distance: Double
    let date: Date
    let averageSpeed: Double
    let elevationGain: Double
    let movingTime: Int
    let type: String
}
```

---

## Quick Test Commands

| Want to... | Press | Or Navigate to... |
|------------|-------|-------------------|
| Run all tests | ⌘U | Product → Test |
| Run one test | Click ◇ icon | Test Navigator → Click test |
| Re-run last test | ⌃⌥⌘G | Product → Perform Action → Run Last Test |
| See test results | ⌘9 | Report Navigator |
| See test coverage | ⌘9 → Coverage tab | Report Navigator → Coverage |
| Debug test | ⌃⌥⌘U | Product → Perform Action → Test Without Building |

---

## Next Steps

### After Setup

1. **Run tests now**: Press ⌘U
2. **Check coverage**: ⌘9 → Coverage tab
3. **Make a change**: Edit any view
4. **Run tests again**: Press ⌘U
5. **See if they catch the break**: Check results

### Adding Your Own Tests

When you add a new feature:

1. **Create test first** (TDD approach):
```swift
@Test("New feature works")
func newFeatureWorks() async throws {
    let feature = MyNewFeature()
    #expect(feature.doesSomething())
}
```

2. **Run test** (it should fail)
3. **Implement feature**
4. **Run test again** (it should pass)

### CI/CD Integration

Add to GitHub Actions:

```yaml
- name: Run Tests
  run: |
    xcodebuild test \
      -scheme DCC-Weekly-Activities \
      -destination 'platform=iOS Simulator,name=iPhone 15'
```

---

## Help & Resources

- 📖 **Full Guide**: See `TESTING_GUIDE.md`
- 🧪 **Test Examples**: Look at `RootViewTests.swift` and `ModelTests.swift`
- 🛠️ **Utilities**: Use helpers from `TestConfiguration.swift`
- 💬 **Questions**: Check Swift Testing documentation

---

## Success Criteria

You're done when:

✅ Press ⌘U and see ~75 tests pass  
✅ Test Navigator shows all test suites  
✅ Coverage report shows >80% coverage  
✅ Tests fail when you break code  
✅ Tests pass when you fix code  

---

**Total Setup Time**: ~5 minutes  
**Test Run Time**: ~5-10 seconds  
**Peace of Mind**: Priceless 😊  

Happy Testing! 🎉
