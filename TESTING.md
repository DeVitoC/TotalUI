# TotalUI Testing Suite

This is the QA test suite for TotalUI. Run these tests in order after any changes to verify functionality.

## Installation

1. Copy `TotalUI` and `TotalUI_Options` folders to `<WoW>/Interface/AddOns/`
2. Enable Lua errors: `/console scriptErrors 1`
3. Reload: `/reload`

---

## Phase 0: Foundation Tests

### Test 1: Addon Loads Without Errors
**Command:** `/reload`

**Expected:**
- No red Lua error messages appear
- See "TotalUI version 0.1.0 loaded!" in chat (single message only)

**Result:**
- ✅ **Pass** if version message appears and no errors
- ❌ **Fail** if missing message or Lua errors occur

---

### Test 2: Global Table Exists
**Command:** `/run print(TotalUI)`

**Expected:** Prints `table: 0x[address]` (e.g., `table: 0x12345678`)

**Result:**
- ✅ **Pass** if shows table address
- ❌ **Fail** if prints `nil` or error

---

### Test 3: Status Command Works
**Command:** `/totalui status`

**Expected:**
```
TotalUI: Addon Status:
TotalUI:   Initialized: true
TotalUI:   Database Ready: true
TotalUI:   Libraries Loaded:
TotalUI:     LibStub: true
TotalUI:     AceAddon: false
TotalUI:     AceDB: true
[etc...]
```

**Result:**
- ✅ **Pass** if command executes and shows "Initialized: true" and "Database Ready: true"
- ❌ **Fail** if command doesn't work or either value is false

---

### Test 4: Version Command Works
**Command:** `/totalui version`

**Expected:**
```
TotalUI: TotalUI version 0.1.0
TotalUI: Compatibility Layer Information:
TotalUI:   Retail: true
TotalUI:   Classic: false
TotalUI:   Expansion: 10
TotalUI:   Build: [your build number]
[etc...]
```

**Result:**
- ✅ **Pass** if shows version and compatibility info
- ❌ **Fail** if command doesn't work or incomplete output

---

### Test 5: Help Command Works
**Command:** `/totalui help`

**Expected:**
```
TotalUI: TotalUI Commands:
TotalUI: /totalui config - Open configuration
TotalUI: /totalui version - Show version info
TotalUI: /totalui status - Show addon status
TotalUI: /totalui toggle [module] - Toggle module on/off
```

**Result:**
- ✅ **Pass** if shows all four commands
- ❌ **Fail** if command doesn't work or incomplete list

---

### Test 6: Database Access - Profile
**Command:** `/run print(TotalUI.db.general.font)`

**Expected:** Prints `Friz Quadrata TT` or similar font name

**Result:**
- ✅ **Pass** if prints a font name
- ❌ **Fail** if prints `nil` or error

---

### Test 7: Database Access - Global
**Command:** `/run print(TotalUI.global.general.version)`

**Expected:** Prints `0.1.0` or version number

**Result:**
- ✅ **Pass** if prints version string
- ❌ **Fail** if prints `nil` or error

---

### Test 8: Database Access - Private
**Command:** `/run print(TotalUI.private.actionbars.enable)`

**Expected:** Prints `true`

**Result:**
- ✅ **Pass** if prints `true`
- ❌ **Fail** if prints `nil` or `false`

---

### Test 9: Compatibility Layer - Version Detection
**Command:** `/run print(TotalUI.Compat.IsRetail)`

**Expected:** Prints `true` (if on Retail) or `false` (if on Classic)

**Result:**
- ✅ **Pass** if prints boolean value matching your WoW version
- ❌ **Fail** if prints `nil` or error

---

### Test 10: Compatibility Layer - API Wrapper
**Command:** `/run print(TotalUI.Compat:GetItemName(6948))`

**Expected:** Prints `Hearthstone`

**Result:**
- ✅ **Pass** if prints item name
- ❌ **Fail** if prints `nil` or error

---

### Test 11: Utilities - Color Conversion
**Command:** `/run local hex = TotalUI:RGBToHex(1, 0, 0); print("Hex digits: " .. hex:sub(5, 10))`

**Expected:** Prints `Hex digits: ff0000` (red in hexadecimal)

**Result:**
- ✅ **Pass** if prints `ff0000`
- ❌ **Fail** if error or wrong format

---

### Test 12: Utilities - Value Formatting
**Command:** `/run print(TotalUI:ShortValue(1234567))`

**Expected:** Prints `1.2m`

**Result:**
- ✅ **Pass** if prints shortened value
- ❌ **Fail** if error or wrong format

---

### Test 13: Event System - Combat Tracking
**Steps:**
1. Run: `/run print("Combat state:", TotalUI.inCombat)`
2. Attack a training dummy or enemy
3. Run command again while in combat
4. Stop combat
5. Run command again

**Expected:**
- First run: `Combat state: false`
- During combat: `Combat state: true`
- After combat: `Combat state: false`

**Result:**
- ✅ **Pass** if combat state changes correctly
- ❌ **Fail** if always false or error

---

### Test 14: Frame Creation
**Command:** `/run local f = TotalUI:CreateFrame("Frame", "TestFrame", UIParent); f:SetSize(100, 100); f:SetPoint("CENTER"); f:Show(); print("Frame created")`

**Expected:**
- Prints `Frame created`
- A small invisible frame exists (won't see it, but no error)

**Result:**
- ✅ **Pass** if no error and prints success message
- ❌ **Fail** if Lua error occurs

---

### Test 15: Modules Load
**Command:** `/run for name, module in pairs(TotalUI.modules) do print(name, module.initialized) end`

**Expected:** Prints list of modules with initialization status:
```
ActionBars   true
UnitFrames   true
Nameplates   true
Bags         true
Chat         true
DataTexts    true
DataBars     true
Auras        true
Tooltip      true
Maps         true
Skins        true
Misc         true
```

**Result:**
- ✅ **Pass** if all 12 modules listed with `true`
- ❌ **Fail** if any module missing or shows `false`

---

### Test 16: No Saved Variables Errors
**Steps:**
1. `/reload`
2. Check for any errors
3. Exit WoW completely
4. Restart WoW
5. Check for any errors

**Expected:** No Lua errors on reload or restart

**Result:**
- ✅ **Pass** if no errors on reload or restart
- ❌ **Fail** if Lua errors occur

---

### Test 17: Slash Command Alias Works
**Command:** `/tui status`

**Expected:** Same output as `/totalui status`

**Result:**
- ✅ **Pass** if shows status output
- ❌ **Fail** if command doesn't work

---

## Phase 0 Summary

**Total Tests:** 17

**Required for Pass:** All 17 tests must pass

**If Tests Fail:**
1. Note which test(s) failed
2. Check for Lua errors with `/console scriptErrors 1`
3. Review the specific system that failed
4. Fix the issue
5. Rerun all tests from Test 1

---

## Phase 1: ActionBars Tests
**Status:** Not yet implemented

_Tests will be added when Phase 1 is complete_

---

## Phase 2: UnitFrames Tests
**Status:** Not yet implemented

_Tests will be added when Phase 2 is complete_

---

## Phase 3: Nameplates Tests
**Status:** Not yet implemented

_Tests will be added when Phase 3 is complete_

---

## Notes

- Run this full test suite after **any code changes**
- Run before **every commit**
- Run after **installing/updating libraries**
- All Phase 0 tests should continue passing even after implementing later phases
- If a test fails, stop and fix it before continuing - broken foundation causes cascading failures
