# LibTotalActionButtons - Comprehensive Implementation Plan

**Document Purpose**: Detailed step-by-step action plan to implement all features identified in the Feature Gap Analysis.

**Date Created**: 2025-11-07
**Current LTAB Version**: 1 (initial implementation)
**Target Completion**: Full feature parity with LibActionButton-1.0 + Blizzard API enhancements

**Total Estimated Time**: 16-22 weeks (4-5.5 months)

---

## Table of Contents

1. [Overview](#overview)
2. [Project Phases](#project-phases)
3. [Phase 0: Preparation & Planning](#phase-0-preparation--planning)
4. [Phase 1: Critical Foundation](#phase-1-critical-foundation)
5. [Phase 2: Core Button Type System](#phase-2-core-button-type-system)
6. [Phase 3: State Management System](#phase-3-state-management-system)
7. [Phase 4: Visual Enhancements - Blizzard APIs](#phase-4-visual-enhancements---blizzard-apis)
8. [Phase 5: Interaction Systems](#phase-5-interaction-systems)
9. [Phase 6: Configuration & Customization](#phase-6-configuration--customization)
10. [Phase 7: Integration & Extensibility](#phase-7-integration--extensibility)
11. [Phase 8: Performance Optimization](#phase-8-performance-optimization)
12. [Phase 9: Advanced Features](#phase-9-advanced-features)
13. [Phase 10: Testing & Documentation](#phase-10-testing--documentation)
14. [Dependencies & Prerequisites](#dependencies--prerequisites)
15. [Testing Strategy](#testing-strategy)
16. [Risk Management](#risk-management)

---

## Overview

### Current State
- **662 lines of code**
- **~25-30% feature complete** compared to LibActionButton-1.0
- **Action buttons only** - no spell/item/macro support
- **No WoW version detection**
- **Critical bugs**: Template creation, pushed texture alignment

### Target State
- **Full feature parity** with LibActionButton-1.0
- **All Blizzard APIs** leveraged for maximum functionality
- **All WoW versions supported** (Retail, Classic, TBC, Wrath, Cata)
- **Production-ready** with comprehensive testing
- **Well-documented** for maintainability

### Success Criteria
1. ✅ Works on all WoW versions without errors
2. ✅ All button types functional (action, spell, item, macro, custom)
3. ✅ State management system working for stance/form switching
4. ✅ All visual effects implemented (overlays, highlights, etc.)
5. ✅ Drag & drop functional
6. ✅ Complete configuration system
7. ✅ Extensible via callbacks
8. ✅ Optimized performance
9. ✅ 100% test coverage of critical paths
10. ✅ Complete API documentation

---

## Project Phases

### High-Level Timeline

| Phase | Name | Duration | Priority | Dependencies |
|-------|------|----------|----------|--------------|
| 0 | Preparation & Planning | 2-3 days | SETUP | None |
| 1 | Critical Foundation | 1-2 weeks | CRITICAL | Phase 0 |
| 2 | Core Button Type System | 2-3 weeks | HIGH | Phase 1 |
| 3 | State Management System | 1-2 weeks | HIGH | Phase 2 |
| 4 | Visual Enhancements - Blizzard APIs | 2-3 weeks | HIGH | Phase 1 |
| 5 | Interaction Systems | 1-2 weeks | MEDIUM | Phase 1 |
| 6 | Configuration & Customization | 1-2 weeks | MEDIUM | Phase 2 |
| 7 | Integration & Extensibility | 2-3 weeks | MEDIUM | Phase 2 |
| 8 | Performance Optimization | 1 week | MEDIUM-LOW | Phase 2 |
| 9 | Advanced Features | 2-3 weeks | LOW | Phase 3, 4 |
| 10 | Testing & Documentation | Ongoing | HIGH | All phases |

**Total**: 16-22 weeks

### Parallel Work Opportunities

Some phases can be worked on in parallel:
- **Phases 4 & 5** can overlap after Phase 1
- **Phases 6 & 7** can overlap after Phase 2
- **Phase 8** can be ongoing throughout
- **Phase 10** is continuous

---

## Phase 0: Preparation & Planning

**Duration**: 2-3 days
**Priority**: SETUP
**Goal**: Set up development environment, testing infrastructure, and planning documents

### Step 0.1: Development Environment Setup

**Time**: 1-2 hours

**Tasks**:
1. ✅ Create backup of current LibTotalActionButtons.lua
2. ✅ Set up version control branching strategy
3. ✅ Create development branch: `feature/ltab-enhancements`
4. ✅ Document current working state

**Commands**:
```bash
# Backup current implementation
cp TotalUI/Libraries/LibTotalActionButtons/LibTotalActionButtons.lua \
   TotalUI/Libraries/LibTotalActionButtons/LibTotalActionButtons.lua.backup

# Create feature branch
git checkout -b feature/ltab-enhancements

# Create checkpoint
git add .
git commit -m "Checkpoint: LTAB before major enhancements"
```

**Deliverable**: Clean development environment with backups

---

### Step 0.2: Testing Environment Setup

**Time**: 2-4 hours

**Tasks**:
1. Create testing framework structure
2. Set up WoW version testing VMs/containers (if available)
3. Create test character profiles for each class
4. Document testing procedures

**Create Test Files**:

**File**: `/TotalUI/Tests/LibTotalActionButtons_Tests.lua`
```lua
-- Test framework for LibTotalActionButtons
local AddonName, ns = ...
local E = ns.public

local Tests = {
    passed = 0,
    failed = 0,
    results = {}
}

function Tests:Run(testName, testFunc)
    local success, err = pcall(testFunc)
    if success then
        self.passed = self.passed + 1
        table.insert(self.results, {name = testName, status = "PASS"})
        print("|cff00ff00[PASS]|r " .. testName)
    else
        self.failed = self.failed + 1
        table.insert(self.results, {name = testName, status = "FAIL", error = err})
        print("|cffff0000[FAIL]|r " .. testName .. ": " .. tostring(err))
    end
end

function Tests:Summary()
    print("=====================================")
    print(string.format("Tests: %d passed, %d failed", self.passed, self.failed))
    print("=====================================")
end

E.Tests.LTAB = Tests
```

**Deliverable**: Testing framework ready for use

---

### Step 0.3: Documentation Structure

**Time**: 1-2 hours

**Tasks**:
1. Create API documentation template
2. Create changelog document
3. Set up progress tracking system

**Create Files**:
- `LibTotalActionButtons_API.md` - API documentation
- `LibTotalActionButtons_Changelog.md` - Version history
- `LibTotalActionButtons_Implementation_Plan.md` - This file

**Deliverable**: Documentation templates ready

---

### Step 0.4: Code Organization Planning

**Time**: 2-3 hours

**Tasks**:
1. Plan file structure (split into multiple files if needed)
2. Define naming conventions
3. Plan module organization
4. Create code style guide

**Proposed Structure** (if splitting files):
```
TotalUI/Libraries/LibTotalActionButtons/
├── LibTotalActionButtons.lua           # Main entry point
├── Core/
│   ├── Version.lua                     # Version detection
│   ├── Constants.lua                   # Constants and enums
│   ├── Compatibility.lua               # API wrappers
│   └── Config.lua                      # Default configuration
├── ButtonTypes/
│   ├── ActionButton.lua                # Action type
│   ├── SpellButton.lua                 # Spell type
│   ├── ItemButton.lua                  # Item type
│   ├── MacroButton.lua                 # Macro type
│   └── CustomButton.lua                # Custom type
├── Systems/
│   ├── StateManagement.lua             # State system
│   ├── EventHandler.lua                # Centralized events
│   ├── UpdateFunctions.lua             # Update logic
│   └── Visual.lua                      # Visual effects
├── Integration/
│   ├── Callbacks.lua                   # CallbackHandler integration
│   ├── Masque.lua                      # Masque support
│   └── LibKeyBound.lua                 # LibKeyBound support
└── Utils/
    ├── Helpers.lua                     # Helper functions
    └── Validation.lua                  # Error checking
```

**Decision**: For now, keep single file for simplicity. Can refactor later if needed.

**Deliverable**: Code organization plan

---

### Step 0.5: Reference Materials Gathering

**Time**: 1 hour

**Tasks**:
1. ✅ LibActionButton-1.0 available at: `TotalUI/Libraries/LibActionButton-1.0/`
2. ✅ Feature Gap Analysis at: `LibTotalActionButtons_FeatureGap.md`
3. Bookmark WoW API documentation
4. Create quick reference guide for common APIs

**Quick Reference Created**: See Appendix A in FeatureGap.md

**Deliverable**: All reference materials accessible

---

## Phase 1: Critical Foundation

**Duration**: 1-2 weeks
**Priority**: CRITICAL
**Goal**: Fix critical bugs, add version detection, implement error handling, and establish LibStub integration

**Dependencies**: Phase 0

---

### Step 1.1: Fix Critical Bug - Template Creation

**Time**: 2-4 hours
**Priority**: CRITICAL

**Current Issue** (Line 83-84):
```lua
local button = CreateFrame("CheckButton", name, parent,
    "ActionBarButtonTemplate, SecureActionButtonTemplate")
```

**Problem**: Template parameter syntax may be incorrect.

**Investigation Steps**:
1. Test current implementation in-game
2. Check Blizzard documentation for multi-template syntax
3. Review LibActionButton-1.0's approach
4. Test different template application methods

**Possible Solutions**:

**Option A**: Single template with mixin
```lua
local button = CreateFrame("CheckButton", name, parent, "ActionBarButtonTemplate")
Mixin(button, SecureActionButtonMixin)
```

**Option B**: Apply templates separately
```lua
local button = CreateFrame("CheckButton", name, parent, "ActionBarButtonTemplate")
-- SecureActionButtonTemplate attributes applied via SetAttribute
```

**Option C**: Verify current syntax works
```lua
-- If comma-separated works, document it
local button = CreateFrame("CheckButton", name, parent,
    "ActionBarButtonTemplate,SecureActionButtonTemplate")  -- No space after comma
```

**Testing**:
```lua
-- Create test button
local testBtn = CreateFrame("CheckButton", "TestButton", UIParent,
    "ActionBarButtonTemplate")

-- Verify all expected elements exist
print("Icon:", testBtn.icon or _G["TestButtonIcon"])
print("Cooldown:", testBtn.cooldown or _G["TestButtonCooldown"])
print("Border:", testBtn.Border or _G["TestButtonBorder"])
-- etc.
```

**Implementation**:
1. Test current implementation
2. If broken, apply fix
3. Verify all template elements accessible
4. Document correct approach

**Deliverable**: Template creation working correctly

---

### Step 1.2: Add WoW Version Detection

**Time**: 4-6 hours
**Priority**: CRITICAL

**Goal**: Detect WoW version and create compatibility layer

**File**: `LibTotalActionButtons.lua`
**Location**: Top of file, after namespace declaration

**Implementation**:

```lua
-- =================================================================
-- WoW Version Detection
-- =================================================================

local WoWRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
local WoWClassic = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)
local WoWBCC = (WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC)
local WoWWrath = (WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC)
local WoWCata = (WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC)

-- Determine "family" for broader checks
local WoWClassicFamily = WoWClassic or WoWBCC or WoWWrath or WoWCata

-- Store in library table
LAB.WoWRetail = WoWRetail
LAB.WoWClassic = WoWClassic
LAB.WoWBCC = WoWBCC
LAB.WoWWrath = WoWWrath
LAB.WoWCata = WoWCata
LAB.WoWClassicFamily = WoWClassicFamily

-- Version info for debugging
LAB.VERSION_INFO = {
    WoW_PROJECT_ID = WOW_PROJECT_ID,
    detectedVersion = WoWRetail and "Retail" or
                      WoWCata and "Cataclysm Classic" or
                      WoWWrath and "Wrath Classic" or
                      WoWBCC and "TBC Classic" or
                      WoWClassic and "Classic Era" or
                      "Unknown"
}

-- Debug output
if E.db and E.db.general and E.db.general.debugMode then
    E:Print(string.format("LibTotalActionButtons: Detected %s (ID: %d)",
        LAB.VERSION_INFO.detectedVersion, WOW_PROJECT_ID))
end
```

**Testing**:
```lua
-- Test command
/run print("WoW Version:", LibStub and LibStub("LibTotalActionButtons-1.0").VERSION_INFO.detectedVersion or "N/A")
```

**Deliverable**: Version detection working on all WoW versions

---

### Step 1.3: API Compatibility Wrappers

**Time**: 3-4 hours
**Priority**: CRITICAL

**Goal**: Create wrappers for version-specific APIs

**Implementation**:

```lua
-- =================================================================
-- API Compatibility Wrappers
-- =================================================================

-- Retail-only APIs - provide safe fallbacks for Classic
local GetActionCharges = GetActionCharges or function() return nil end
local GetActionLossOfControlCooldown = GetActionLossOfControlCooldown or function() return nil end
local GetSpellCharges = GetSpellCharges or function() return nil end
local GetSpellLossOfControlCooldown = GetSpellLossOfControlCooldown or function() return nil end

-- C_ActionBar namespace (Retail only)
local C_ActionBarCompat = WoWRetail and C_ActionBar or {
    IsAssistedCombatAction = function() return false end,
    GetItemActionOnEquipSpellID = function() return nil end,
    SetActionUIButton = function() end,
}

-- C_SpellActivationOverlay namespace (Retail only)
local C_SpellActivationOverlayCompat = WoWRetail and C_SpellActivationOverlay or {
    IsSpellOverlayed = function() return false end,
}

-- C_NewItems namespace (Retail only)
local C_NewItemsCompat = WoWRetail and C_NewItems or {
    IsNewItem = function() return false end,
}

-- Store in library
LAB.Compat = {
    GetActionCharges = GetActionCharges,
    GetActionLossOfControlCooldown = GetActionLossOfControlCooldown,
    GetSpellCharges = GetSpellCharges,
    GetSpellLossOfControlCooldown = GetSpellLossOfControlCooldown,
    C_ActionBar = C_ActionBarCompat,
    C_SpellActivationOverlay = C_SpellActivationOverlayCompat,
    C_NewItems = C_NewItemsCompat,
}

-- Legacy API check (some Retail versions have IsSpellOverlayed as global)
if WoWRetail and IsSpellOverlayed and not C_SpellActivationOverlay then
    LAB.Compat.IsSpellOverlayed = IsSpellOverlayed
elseif WoWRetail and C_SpellActivationOverlay then
    LAB.Compat.IsSpellOverlayed = C_SpellActivationOverlay.IsSpellOverlayed
else
    LAB.Compat.IsSpellOverlayed = function() return false end
end
```

**Testing**:
```lua
-- Test on Retail
/run local LAB = LibStub("LibTotalActionButtons-1.0"); print("Charges API:", LAB.Compat.GetActionCharges and "Available" or "Missing")

-- Test on Classic (should not error)
/run local LAB = LibStub("LibTotalActionButtons-1.0"); print("Version:", LAB.WoWRetail and "Retail" or "Classic")
```

**Deliverable**: Safe API wrappers for all WoW versions

---

### Step 1.4: Comprehensive Error Handling System

**Time**: 6-8 hours
**Priority**: CRITICAL

**Goal**: Add parameter validation, error messages, and debug logging

**Sub-Step 1.4.1**: Add Debug Logging System

```lua
-- =================================================================
-- Debug & Logging System
-- =================================================================

LAB.debug = false

function LAB:SetDebug(enabled)
    self.debug = enabled
    if enabled then
        E:Print("LibTotalActionButtons: Debug mode enabled")
    end
end

function LAB:DebugPrint(...)
    if self.debug then
        print("|cffff9900[LTAB Debug]|r", ...)
    end
end

function LAB:Error(message, level)
    level = level or 2
    error("LibTotalActionButtons: " .. message, level)
end

function LAB:Warning(message)
    if self.debug then
        print("|cffffaa00[LTAB Warning]|r", message)
    end
end
```

**Sub-Step 1.4.2**: Add Parameter Validation

```lua
-- =================================================================
-- Validation Helpers
-- =================================================================

local function ValidateButton(button, functionName)
    if not button then
        LAB:Error(functionName .. ": button parameter is nil!", 3)
        return false
    end
    if type(button) ~= "table" then
        LAB:Error(functionName .. ": button must be a frame/table!", 3)
        return false
    end
    return true
end

local function ValidateNumber(value, name, functionName, min, max)
    if not value then return true end  -- Optional parameter
    if type(value) ~= "number" then
        LAB:Error(string.format("%s: %s must be a number!", functionName, name), 3)
        return false
    end
    if min and value < min then
        LAB:Error(string.format("%s: %s must be >= %d!", functionName, name, min), 3)
        return false
    end
    if max and value > max then
        LAB:Error(string.format("%s: %s must be <= %d!", functionName, name, max), 3)
        return false
    end
    return true
end

local function ValidateString(value, name, functionName, allowEmpty)
    if not value then return true end  -- Optional parameter
    if type(value) ~= "string" then
        LAB:Error(string.format("%s: %s must be a string!", functionName, name), 3)
        return false
    end
    if not allowEmpty and value == "" then
        LAB:Error(string.format("%s: %s cannot be empty!", functionName, name), 3)
        return false
    end
    return true
end

LAB.Validate = {
    Button = ValidateButton,
    Number = ValidateNumber,
    String = ValidateString,
}
```

**Sub-Step 1.4.3**: Add Combat Lockdown Checks

```lua
-- =================================================================
-- Combat Lockdown Helpers
-- =================================================================

function LAB:CheckCombat(functionName, errorOnCombat)
    if InCombatLockdown() then
        if errorOnCombat then
            self:Error(functionName .. ": Cannot be called during combat!", 3)
        else
            self:Warning(functionName .. ": Skipped during combat")
        end
        return true  -- In combat
    end
    return false  -- Not in combat
end

function LAB:SafeProtectedCall(func, ...)
    if InCombatLockdown() then
        self:Warning("Attempted protected call during combat - skipped")
        return false
    end

    local success, err = pcall(func, ...)
    if not success then
        self:Warning("Protected call failed: " .. tostring(err))
        return false
    end

    return true
end
```

**Sub-Step 1.4.4**: Update Existing Functions with Validation

**Example**: Update `CreateButton` function

```lua
function LAB:CreateButton(actionID, name, parent, config)
    -- Validate parameters
    if not ValidateNumber(actionID, "actionID", "CreateButton", 1) then
        return nil
    end

    if not ValidateString(name, "name", "CreateButton", false) then
        return nil
    end

    if parent and type(parent) ~= "table" then
        self:Error("CreateButton: parent must be a frame!", 2)
        return nil
    end

    -- Check if button already exists
    if _G[name] then
        self:Warning(string.format("CreateButton: Button '%s' already exists!", name))
    end

    -- Rest of function...
    self:DebugPrint(string.format("Creating button: %s (action %d)", name, actionID))

    -- ... existing code ...
end
```

**Sub-Step 1.4.5**: Add Protected API Calls

```lua
-- =================================================================
-- Safe API Call Wrappers
-- =================================================================

function LAB:SafeGetActionInfo(actionID)
    if not actionID or type(actionID) ~= "number" then
        return nil
    end

    local success, actionType, id, subType = pcall(GetActionInfo, actionID)
    if success then
        return actionType, id, subType
    else
        self:DebugPrint("GetActionInfo failed for action:", actionID)
        return nil
    end
end

-- Add more safe wrappers as needed
```

**Testing**:
```lua
-- Test error handling
/run LibStub("LibTotalActionButtons-1.0"):CreateButton(nil, "Test", UIParent)  -- Should error
/run LibStub("LibTotalActionButtons-1.0"):CreateButton(1, "", UIParent)  -- Should error
/run LibStub("LibTotalActionButtons-1.0"):CreateButton(1, "Test", "invalid")  -- Should error

-- Test debug mode
/run LibStub("LibTotalActionButtons-1.0"):SetDebug(true)
/run LibStub("LibTotalActionButtons-1.0"):CreateButton(1, "TestDebug", UIParent)
```

**Deliverable**: Comprehensive error handling throughout library

---

### Step 1.5: LibStub Integration

**Time**: 4-6 hours
**Priority**: CRITICAL

**Goal**: Convert to proper LibStub library format

**Current State**: Stored in `E.Libs.LibTotalActionButtons`
**Target State**: Registered with LibStub as `"LibTotalActionButtons-1.0"`

**Sub-Step 1.5.1**: Add LibStub Declaration

**Replace current library initialization**:

```lua
-- Current (TotalUI namespace)
local AddonName, ns = ...
local E = ns.public
E.Libs = E.Libs or {}
local LAB = {
    VERSION = 1,
    buttons = {},
    activeButtons = {},
}
E.Libs.LibTotalActionButtons = LAB
```

**With LibStub registration**:

```lua
local MAJOR_VERSION = "LibTotalActionButtons-1.0"
local MINOR_VERSION = 1

-- Require LibStub
local LibStub = _G.LibStub
if not LibStub then
    error(MAJOR_VERSION .. " requires LibStub to be loaded first.")
    return
end

-- Register library
local LAB, oldversion = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if not LAB then
    return  -- Already loaded newer/same version
end

-- Preserve existing data on upgrade
if oldversion then
    -- Preserve button registry
    LAB.buttons = LAB.buttons or {}
    LAB.activeButtons = LAB.activeButtons or {}
else
    -- First load
    LAB.buttons = {}
    LAB.activeButtons = {}
end

-- Version info
LAB.VERSION = MINOR_VERSION
LAB.VERSION_STRING = string.format("%s (v%d)", MAJOR_VERSION, MINOR_VERSION)
```

**Sub-Step 1.5.2**: Maintain TotalUI Compatibility

**Keep reference in TotalUI namespace**:

```lua
-- After LibStub registration
local AddonName, ns = ...
if ns and ns.public then
    local E = ns.public
    E.Libs = E.Libs or {}
    E.Libs.LibTotalActionButtons = LAB  -- Keep reference for TotalUI
end
```

**Sub-Step 1.5.3**: Update Module Initialization

**Update ActionBars.lua to use LibStub**:

```lua
-- OLD
function AB:Initialize()
    if not E.Libs.LibTotalActionButtons then
        E:Print("ActionBars: LibTotalActionButtons not loaded.")
        return
    end

    local LAB = E.Libs.LibTotalActionButtons
    -- ...
end
```

```lua
-- NEW
function AB:Initialize()
    local LAB = LibStub("LibTotalActionButtons-1.0", true)  -- true = silent fail
    if not LAB then
        E:Print("ActionBars: LibTotalActionButtons not loaded.")
        return
    end

    -- Store reference for convenience
    self.LAB = LAB
    -- ...
end
```

**Sub-Step 1.5.4**: Version Upgrade Handling

```lua
-- Handle version upgrades
if oldversion then
    LAB:DebugPrint(string.format("Upgrading from version %d to %d", oldversion, MINOR_VERSION))

    -- Migrate button registry if structure changed
    -- (Add migration code here when needed)

    -- Update all existing buttons
    for button in pairs(LAB.buttons) do
        -- Update button with new functionality
    end
end
```

**Testing**:
```lua
-- Test LibStub registration
/run print("LTAB via LibStub:", LibStub("LibTotalActionButtons-1.0") and "Loaded" or "Not found")
/run print("LTAB Version:", LibStub("LibTotalActionButtons-1.0").VERSION_STRING)

-- Test upgrade (reload addon twice)
/reload
/run print("After reload:", LibStub("LibTotalActionButtons-1.0").VERSION)
```

**Deliverable**: Library properly registered with LibStub

---

### Step 1.6: Fix Pushed Texture Alignment Bug

**Time**: 2-4 hours
**Priority**: HIGH

**Current Issue**: Pushed texture (click-and-hold highlight) is off-center

**Investigation Steps**:

1. **Check current implementation**:
```lua
-- Lines 208-212
if button._pushedTexture then
    button._pushedTexture:ClearAllPoints()
    button._pushedTexture:SetAllPoints(button)
end
```

2. **Test with template default**:
```lua
-- Remove our custom anchoring, let template handle it
if button._pushedTexture then
    -- Don't modify - test if template handles it correctly
end
```

3. **Check if texture exists**:
```lua
local function DebugPushedTexture(button)
    print("Pushed Texture:", button._pushedTexture)
    if button._pushedTexture then
        local points = button._pushedTexture:GetNumPoints()
        print("  Points:", points)
        for i = 1, points do
            local point, relativeTo, relativePoint, x, y = button._pushedTexture:GetPoint(i)
            print(string.format("  Point %d: %s to %s %s (%d, %d)",
                i, point, tostring(relativeTo), relativePoint, x or 0, y or 0))
        end
        local w, h = button._pushedTexture:GetSize()
        print(string.format("  Size: %.1f x %.1f", w, h))
    end
end
```

**Possible Fixes**:

**Fix Option A**: Anchor to icon instead of button
```lua
if button._pushedTexture and button._icon then
    button._pushedTexture:ClearAllPoints()
    button._pushedTexture:SetAllPoints(button._icon)
end
```

**Fix Option B**: Manual size/position
```lua
if button._pushedTexture then
    button._pushedTexture:ClearAllPoints()
    button._pushedTexture:SetPoint("CENTER", button, "CENTER", 0, 0)
    button._pushedTexture:SetSize(width, height)
end
```

**Fix Option C**: Let template handle it
```lua
-- Simply don't touch it - ActionBarButtonTemplate may handle it
```

**Testing Process**:
1. Create test button
2. Click and hold
3. Screenshot pushed state
4. Try each fix option
5. Document which works

**Deliverable**: Pushed texture properly aligned

---

### Step 1.7: Phase 1 Integration Testing

**Time**: 4-6 hours
**Priority**: HIGH

**Goal**: Verify all Phase 1 changes work together

**Test Cases**:

1. **Version Detection**
   - [ ] Detects Retail correctly
   - [ ] Detects Classic variants correctly
   - [ ] Version info accessible

2. **API Compatibility**
   - [ ] Retail-only APIs don't error on Classic
   - [ ] Wrappers return appropriate values
   - [ ] No Lua errors on any version

3. **Error Handling**
   - [ ] Invalid parameters produce clear errors
   - [ ] Debug mode shows helpful messages
   - [ ] Combat lockdown handled gracefully

4. **LibStub Integration**
   - [ ] Library accessible via LibStub
   - [ ] Version number correct
   - [ ] Upgrade path works (test with /reload)
   - [ ] Still accessible from TotalUI namespace

5. **Bug Fixes**
   - [ ] Template creation works
   - [ ] All button elements accessible
   - [ ] Pushed texture aligned correctly

**Test Script**:

```lua
-- Comprehensive Phase 1 Test
/run local LAB = LibStub("LibTotalActionButtons-1.0"); \
    print("=== Phase 1 Tests ==="); \
    print("Version:", LAB.VERSION_STRING); \
    print("WoW Type:", LAB.VERSION_INFO.detectedVersion); \
    print("Retail APIs:", LAB.Compat.GetActionCharges and "Available" or "Wrapped"); \
    LAB:SetDebug(true); \
    local btn = LAB:CreateButton(1, "Phase1Test", UIParent); \
    print("Button Created:", btn and "Success" or "Failed"); \
    if btn then \
        print("Icon:", btn._icon and "OK" or "MISSING"); \
        print("Cooldown:", btn._cooldown and "OK" or "MISSING"); \
        print("Pushed:", btn._pushedTexture and "OK" or "MISSING"); \
    end
```

**Deliverable**: All Phase 1 features tested and working

---

### Phase 1 Completion Checklist

- [ ] Template creation bug fixed
- [ ] WoW version detection working
- [ ] API compatibility wrappers implemented
- [ ] Error handling system complete
- [ ] LibStub integration complete
- [ ] Pushed texture alignment fixed
- [ ] All Phase 1 tests passing
- [ ] No Lua errors on Retail
- [ ] No Lua errors on Classic (if testable)
- [ ] Documentation updated

**Time to Complete Phase 1**: 1-2 weeks

**Next Phase**: Phase 2 - Core Button Type System

---

