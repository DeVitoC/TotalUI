# TotalUI Testing Suite

This is the QA test suite for TotalUI. Run these tests in order after any changes to verify functionality.

## Installation & Setup

1. Copy `TotalUI` and `TotalUI_Options` folders to `<WoW>/Interface/AddOns/`
2. Enable Lua errors: `/console scriptErrors 1`
3. **Enable taint log:** `/console taintLog 2`
4. Reload: `/reload`

**Note:** Keep taint logging enabled throughout ALL tests to detect any taint issues early.

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

## Phase 1A: ActionBars - Bar 1 Tests

### Prerequisites
LibTotalActionButtons-1.0 must be loaded in the .toc file (included with TotalUI).

---

### Test 18: LibTotalActionButtons Loaded
**Command:** `/run print("LTAB:", TotalUI.Libs.LibTotalActionButtons and "Loaded" or "Missing")`

**Expected:** Prints `LTAB: Loaded`

**Result:**
- ✅ **Pass** if prints "LTAB: Loaded"
- ❌ **Fail** if prints "LTAB: Missing" (check .toc file)

---

### Test 19: ActionBars Module Initialized
**Command:** `/run local AB = TotalUI:GetModule("ActionBars"); print("Initialized:", AB and AB.initialized or "false")`

**Expected:** Prints `Initialized: true`

**Result:**
- ✅ **Pass** if prints "Initialized: true"
- ❌ **Fail** if prints "false" or error

---

### Test 20: Bar 1 Created
**Command:** `/run local AB = TotalUI:GetModule("ActionBars"); print("Bar 1:", AB.bars[1] and "Created" or "Missing")`

**Expected:** Prints `Bar 1: Created`

**Result:**
- ✅ **Pass** if prints "Bar 1: Created"
- ❌ **Fail** if prints "Bar 1: Missing"

---

### Test 21: Bar 1 Visible
**Steps:**
1. Look at the bottom of your screen
2. You should see a bar with 12 buttons

**Expected:**
- Bar 1 appears at bottom center of screen
- 12 buttons in a horizontal row
- Buttons show your current actions from default action bar
- Keybinds visible (1, 2, 3, etc.)

**Result:**
- ✅ **Pass** if Bar 1 visible with 12 buttons
- ❌ **Fail** if no bar or wrong number of buttons

---

### Test 22: Bar 1 Buttons Count
**Command:** `/run local AB = TotalUI:GetModule("ActionBars"); print("Buttons:", #AB.bars[1].buttons)`

**Expected:** Prints `Buttons: 12`

**Result:**
- ✅ **Pass** if prints 12
- ❌ **Fail** if different number or error

---

### Test 23: Drag and Drop Actions
**Steps:**
1. Open spellbook
2. Drag a spell to one of the Bar 1 buttons
3. Click the button to cast the spell

**Expected:**
- Spell icon appears on button
- Clicking button casts the spell
- Keybind works (pressing the key casts spell)

**Result:**
- ✅ **Pass** if drag/drop works and button functions
- ❌ **Fail** if can't drag or button doesn't work

---

### Test 24: Button Cooldowns
**Steps:**
1. Place a spell with cooldown on a button
2. Cast the spell
3. Watch the button

**Expected:**
- Cooldown spiral animation appears
- Cooldown timer counts down
- Button becomes usable again when cooldown ends

**Result:**
- ✅ **Pass** if cooldown displays correctly
- ❌ **Fail** if no cooldown animation

---

### Test 25: Button States - Out of Range
**Steps:**
1. Place a ranged attack spell on a button
2. Target an enemy
3. Walk out of range

**Expected:**
- Button turns red when out of range
- Button returns to normal color when in range

**Result:**
- ✅ **Pass** if button color changes with range
- ❌ **Fail** if button doesn't change color

---

### Test 26: Button States - Not Enough Power
**Steps:**
1. Place an expensive spell on a button
2. Wait until you don't have enough mana/energy/rage

**Expected:**
- Button turns blue when insufficient power
- Button returns to normal when power restored

**Result:**
- ✅ **Pass** if button color changes with power
- ❌ **Fail** if button doesn't change color

---

### Test 27: Bar 1 Configuration - Button Size
**Steps:**
1. Run: `/run TotalUI.db.actionbar.bar1.buttonSize = 40; TotalUI.db.actionbar.bar1.buttonHeight = 40`
2. Run: `/reload`

**Expected:**
- Buttons are larger (40x40 pixels, square)
- Bar adjusts size accordingly

**Result:**
- ✅ **Pass** if buttons are larger and square
- ❌ **Fail** if no change or buttons are squished

**Cleanup:** Run `/run TotalUI.db.actionbar.bar1.buttonSize = 32; TotalUI.db.actionbar.bar1.buttonHeight = 32` then `/reload`

---

### Test 28: Bar 1 Configuration - Buttons Per Row
**Steps:**
1. Run: `/run TotalUI.db.actionbar.bar1.buttonsPerRow = 6`
2. Run: `/reload`

**Expected:**
- Buttons arrange in 2 rows of 6
- Bar is wider and taller

**Result:**
- ✅ **Pass** if buttons arrange in 2 rows
- ❌ **Fail** if still single row

**Cleanup:** Run `/run TotalUI.db.actionbar.bar1.buttonsPerRow = 12` and `/reload`

---

### Test 29: Bar 1 Configuration - Mouseover
**Steps:**
1. Run: `/run TotalUI.db.actionbar.bar1.mouseover = true; TotalUI.db.actionbar.bar1.mouseoverAlpha = 0.2`
2. Run: `/reload`
3. Move mouse away from bar
4. Move mouse over bar

**Expected:**
- Bar fades to 20% opacity when mouse away
- Bar fades to 100% opacity when mouse over
- Smooth fade transition

**Result:**
- ✅ **Pass** if mouseover fade works
- ❌ **Fail** if no fade or instant transition

**Cleanup:** Run `/run TotalUI.db.actionbar.bar1.mouseover = false` and `/reload`

---

### Test 30: Bar 1 Configuration - Show Grid
**Steps:**
1. Remove all actions from Bar 1 (right-click buttons)
2. Run: `/run TotalUI.db.actionbar.bar1.showGrid = false`
3. Run: `/reload`

**Expected:**
- Empty buttons hide completely
- Buttons with actions still visible

**Result:**
- ✅ **Pass** if empty buttons hide
- ❌ **Fail** if empty buttons still show

**Cleanup:** Run `/run TotalUI.db.actionbar.bar1.showGrid = true` and `/reload` then re-add actions

---

### Test 31: Combat Safety - Drag and Drop
**NOTE:** In TWW 11.0.7 (current retail), dragging during combat IS allowed. This matches Blizzard's default UI behavior. Midnight expansion may introduce stricter combat lockdown.

**Steps:**
1. Attack a training dummy (enter combat)
2. While in combat, drag a spell to change button actions
3. Verify the button changes and spell works
4. Leave combat

**Expected:**
- During combat: Can drag and drop normally (current retail behavior)
- Button changes take effect immediately
- No errors occur

**Result:**
- ✅ **Pass** if can drag during combat without errors
- ❌ **Fail** if errors occur or buttons don't work

**Cleanup:** None needed

---

### Test 32: Combat Safety - No Errors
**Steps:**
1. Enter combat (attack dummy)
2. Try various actions:
   - Drag a spell to button
   - Click buttons
   - Use keybinds
   - Run `/totalui actionbar status`
3. Check for Lua errors

**Expected:** No Lua errors during combat

**Result:**
- ✅ **Pass** if no errors during combat
- ❌ **Fail** if Lua errors occur

---

### Test 33: Visibility Driver - Vehicle
**Steps:**
1. Enter a vehicle (find a demolisher, siege engine, or vehicle quest)
2. Check if Bar 1 is visible

**Expected:**
- Bar 1 hides when in vehicle
- Bar 1 reappears when exiting vehicle

**Result:**
- ✅ **Pass** if bar hides/shows correctly
- ❌ **Fail** if bar doesn't hide or doesn't reappear

---

### Test 34: Class Paging (Class-Specific)
**For Druids:**
**Steps:**
1. Shift to Bear Form
2. Shift to Cat Form
3. Shift back to Caster Form

**Expected:**
- Bar 1 shows different actions in each form
- Actions change immediately when shifting

**For Warriors:**
**Steps:**
1. Change stances (Battle/Defensive/Berserker)

**Expected:**
- Bar 1 shows different actions in each stance

**For Other Classes:**
**Expected:**
- Bar 1 shows consistent actions (no form/stance paging)

**Result:**
- ✅ **Pass** if paging works for your class
- ❌ **Fail** if actions don't change when they should
- ⚠️ **N/A** if your class doesn't have forms/stances

---

### Test 35: Slash Commands - Toggle Bar
**Command:** `/totalui actionbar toggle 1`

**Expected:**
- First time: "Bar 1: Disabled" and bar hides
- Second time: "Bar 1: Enabled" and bar appears

**Result:**
- ✅ **Pass** if toggle works both ways
- ❌ **Fail** if command doesn't work or bar doesn't hide/show

---

### Test 36: Slash Commands - Status
**Command:** `/totalui actionbar status`

**Expected:**
```
TotalUI: ActionBar Status:
TotalUI:   Bar 1: Enabled
TotalUI:   Bar 2: Enabled
TotalUI:   Bar 3: Enabled
TotalUI:   Bar 4: Enabled
TotalUI:   Bar 5: Enabled
```

**Result:**
- ✅ **Pass** if shows status for all 5 bars
- ❌ **Fail** if command doesn't work or incomplete list

---

### Test 37: Database Persistence
**Steps:**
1. Change setting: `/run TotalUI.db.actionbar.bar1.buttonSize = 40`
2. Run: `/reload`
3. Check: `/run print(TotalUI.db.actionbar.bar1.buttonSize)`
4. Log out completely
5. Log back in
6. Check again: `/run print(TotalUI.db.actionbar.bar1.buttonSize)`

**Expected:**
- After reload: Prints `40`
- After logout/login: Prints `40`

**Result:**
- ✅ **Pass** if setting persists across logout
- ❌ **Fail** if setting reverts to default

**Cleanup:** Run `/run TotalUI.db.actionbar.bar1.buttonSize = 32` then `/reload`

---

### Test 38: Macro Text Display
**Steps:**
1. Create a macro with a name
2. Place macro on a Bar 1 button

**Expected:**
- Macro name appears on button (bottom of button)
- Name uses configured font and color

**Result:**
- ✅ **Pass** if macro name displays
- ❌ **Fail** if no text or wrong position

---

### Test 39: Item Count Display
**Steps:**
1. Place a consumable item (potion, food) on a button
2. Check button

**Expected:**
- Item count appears on button (bottom right corner)
- Count updates when using/gaining items

**Result:**
- ✅ **Pass** if count displays and updates
- ❌ **Fail** if no count or doesn't update

---

### Test 40: No Taint
**Steps:**
1. Run full Phase 0 and Phase 1A tests
2. Check for any taint errors with `/run print(GetCVarBool("taintLog"))`
3. If taintLog enabled, check WoW logs for ADDON_ACTION_BLOCKED

**Expected:** No taint errors related to TotalUI

**Result:**
- ✅ **Pass** if no taint errors
- ❌ **Fail** if ADDON_ACTION_BLOCKED errors appear

---

## Phase 1A Summary

**Total Tests:** 23 (Tests 18-40)

**Required for Pass:** All 23 tests must pass

**Known Limitations in Phase 1A:**
- Only Bar 1 implemented (Bars 2-15 in later phases)
- No special bars (Pet, Stance, Micro) yet
- Configuration UI not available (must use Lua commands)
- No bar mover tool yet

**If Tests Fail:**
1. Verify LibTotalActionButtons-1.0 is loaded in .toc file
2. Check `/console scriptErrors 1` for errors
3. Run `/totalui status` to check addon state
4. Review failed test and check related code
5. Fix issue and rerun all Phase 0 and Phase 1A tests

---

## Phase 1B: ActionBars - Settings UI Tests

### Prerequisites
- Phase 1A tests must all pass
- TotalUI_Options addon must be enabled
- `/reload` to ensure options addon is loaded

---

### Test 41: Options Addon Loaded
**Command:** `/run print("Options:", TotalUI.Options and "Loaded" or "Missing")`

**Expected:** Prints `Options: Loaded`

**Result:**
- ✅ **Pass** if prints "Options: Loaded"
- ❌ **Fail** if prints "Options: Missing" (enable TotalUI_Options addon)

---

### Test 42: Settings Panel Registration
**Steps:**
1. Type `/settings`
2. In search box, type "TotalUI"
3. Look for "TotalUI ActionBars" in results

**Expected:**
- "TotalUI ActionBars" appears in search results
- Category has subcategories (Global Settings, Bar 1, Bar 2, etc.)

**Result:**
- ✅ **Pass** if TotalUI ActionBars appears with subcategories
- ❌ **Fail** if not found or no subcategories

---

### Test 43: Open Settings via Command
**Command:** `/totalui config`

**Expected:**
- Settings window opens
- TotalUI ActionBars section is displayed
- Message in chat: "Opening settings panel..."

**Result:**
- ✅ **Pass** if settings open to TotalUI section
- ❌ **Fail** if settings don't open or wrong section

---

### Test 44: Global Settings - Enable ActionBars
**Steps:**
1. Open settings: `/totalui config`
2. Navigate to "Global Settings" subcategory
3. Find "Enable ActionBars" checkbox
4. Uncheck it
5. Check if bars disappear
6. Re-check it
7. Check if bars reappear

**Expected:**
- Unchecking hides all action bars immediately
- Re-checking shows bars immediately (no reload needed)

**Result:**
- ✅ **Pass** if checkbox toggles bars on/off
- ❌ **Fail** if no change or requires reload

---

### Test 45: Global Settings - Desaturate on Cooldown
**Steps:**
1. In Global Settings, check "Desaturate on Cooldown"
2. Place a spell with cooldown on a button
3. Cast the spell
4. Watch button icon during cooldown

**Expected:**
- Icon becomes grayscale/desaturated during cooldown
- Icon returns to color when cooldown ends

**Result:**
- ✅ **Pass** if icon desaturates
- ❌ **Fail** if icon stays colored

---

### Test 46: Global Settings - Hide Cooldown Bling
**Steps:**
1. In Global Settings, check "Hide Cooldown Bling"
2. Cast a spell with cooldown
3. Watch for the "bling" flash animation when cooldown completes

**Expected:**
- No bling animation when cooldown completes
- Unchecking brings bling back

**Result:**
- ✅ **Pass** if bling is hidden/shown appropriately
- ❌ **Fail** if bling always shows or never shows

---

### Test 47: Settings Persistence - Across Reload
**Steps:**
1. Change multiple settings in various categories
2. Note your changes
3. Run `/reload`
4. Open settings again
5. Verify all changes persisted

**Expected:**
- All setting changes persist after reload
- Visual state matches saved settings

**Result:**
- ✅ **Pass** if all settings persist
- ❌ **Fail** if any settings revert to default

---

### Test 48: Settings Persistence - Across Logout
**Steps:**
1. Change several settings
2. Note your changes
3. Completely log out of character
4. Log back in
5. Open settings and verify changes

**Expected:**
- All setting changes persist after logout/login
- Visual state matches saved settings

**Result:**
- ✅ **Pass** if all settings persist
- ❌ **Fail** if any settings revert to default

---

### Test 49: Settings - No Lua Errors
**Steps:**
1. Open settings: `/totalui config`
2. Navigate through all subcategories
3. Toggle every checkbox
4. Move every slider
5. Check for Lua errors

**Expected:** No Lua errors during any setting changes

**Result:**
- ✅ **Pass** if no errors occur
- ❌ **Fail** if any Lua errors appear

---

### Test 50: Settings - Performance
**Steps:**
1. Open settings
2. Rapidly change multiple settings:
   - Toggle Bar 1 on/off 5 times
   - Drag button size slider back and forth rapidly
   - Toggle multiple bars on/off quickly
3. Watch for lag, stuttering, or errors

**Expected:**
- No lag or stuttering
- All changes apply smoothly
- No Lua errors

**Result:**
- ✅ **Pass** if smooth performance
- ❌ **Fail** if lag, stuttering, or errors occur

---

### Test 51: Settings - Combat Restrictions
**Steps:**
1. Enter combat (attack training dummy)
2. While in combat, try to change settings:
   - Toggle a bar on/off
   - Change button size
   - Adjust buttons per row
3. Leave combat
4. Check if changes were queued and applied

**Expected:**
- During combat: Some changes may be blocked or queued
- After combat: Queued changes apply automatically
- OR: Changes apply immediately if non-combat-restricted

**Result:**
- ✅ **Pass** if combat restrictions work properly
- ❌ **Fail** if changes cause errors in combat

---

### Test 52: Settings - Default Values Match Code
**Steps:**
1. Check a fresh character (or reset settings)
2. Open each settings category
3. Verify default values match Profile.lua:
   - Bar 1-5: enabled = true
   - Bar 6-15: enabled = false
   - Button size: 32
   - Buttons per row: 12
   - Pet bar: enabled = true
   - Micro bar: mouseover = true

**Expected:** All default values in UI match Profile.lua defaults

**Result:**
- ✅ **Pass** if all defaults match
- ❌ **Fail** if any defaults differ

---

## Phase 1B Summary

**Total Tests:** 12 (Tests 41-52)

**Required for Pass:** All 12 tests must pass

**Phase 1B Deliverables:**
- ✅ Settings UI integrated with Blizzard Settings API
- ✅ All 15 action bars configurable
- ✅ Pet bar, stance bar, micro bar settings
- ✅ Extra action buttons settings
- ✅ Global ActionBars settings
- ✅ Real-time setting updates (no reload required)
- ✅ Settings persistence across reload/logout
- ✅ Settings accessible via `/totalui config` or `/settings`

**If Tests Fail:**
1. Verify TotalUI_Options addon is enabled
2. Check `/console scriptErrors 1` for errors
3. Ensure Phase 1A tests still pass
4. Review failed test and check ActionBars.lua options file
5. Fix issue and rerun Phase 1B tests

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
