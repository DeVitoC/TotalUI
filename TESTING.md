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

## Phase 1C: ActionBars - Global Settings GUI Tests

### Prerequisites
- Phase 1A and 1B tests must all pass
- TotalUI_Options addon must be enabled
- `/reload` to ensure options addon is loaded

---

### Test 53: Open Config GUI
**Command:** `/totalui config`

**Expected:**
- TotalUI Configuration window opens
- Left navigation shows: General, ActionBars, UnitFrames (disabled), etc.
- Top tabs show: Global, ActionBars 1-15, Special Action Bars
- Global tab is selected by default

**Result:**
- ✅ **Pass** if config GUI opens with nested navigation
- ❌ **Fail** if GUI doesn't open or missing navigation elements

---

### Test 54: Basic Settings - Enable ActionBars
**Steps:**
1. Open config: `/totalui config`
2. Click "ActionBars" in left nav (if not already selected)
3. Ensure "Global" tab is selected
4. Find "Enable ActionBars" checkbox
5. Uncheck it - bars should hide
6. Re-check it - bars should reappear

**Expected:**
- Checkbox toggles bars visibility immediately
- No reload required

**Result:**
- ✅ **Pass** if checkbox works instantly
- ❌ **Fail** if no effect or requires reload

---

### Test 55: Basic Settings - Preserve Default Appearance (TotalUI-Specific)
**Steps:**
1. In Global tab, find "Preserve Default Appearance" checkbox
2. Check it
3. Verify action bars keep default WoW visual appearance
4. Test that behavioral settings still work (cooldown, keybinds, etc.)

**Expected:**
- Checking preserves original WoW button textures and styling
- Behavioral enhancements remain functional
- Unchecking restores TotalUI styling

**Result:**
- ✅ **Pass** if appearance toggles correctly
- ❌ **Fail** if no visual change or breaks functionality

---

### Test 56: Basic Settings - Lock ActionBars
**Steps:**
1. In Global tab, find "Lock ActionBars" checkbox
2. Uncheck it
3. Try to drag/move action bars
4. Re-check it
5. Try to drag/move action bars (should be locked)

**Expected:**
- Unchecked: Bars can be moved with mouse
- Checked: Bars cannot be moved

**Result:**
- ✅ **Pass** if lock prevents movement
- ❌ **Fail** if bars always movable or always locked

---

### Test 57: Appearance - Global Fade Alpha & Transparent Settings
**Steps:**
1. Find "Global Fade Alpha" slider
2. Set to 0.5, verify bars become semi-transparent
3. Find "Transparent Buttons" checkbox, toggle it
4. Find "Transparent Backdrops" checkbox, toggle it
5. Verify visual changes to button backgrounds and bar backdrops

**Expected:**
- Fade alpha slider changes bar transparency (0=invisible, 1=opaque)
- Transparent Buttons removes button background texture
- Transparent Backdrops removes bar backdrop panel

**Result:**
- ✅ **Pass** if all three settings produce visual changes
- ❌ **Fail** if no visual effect

---

### Test 58: Appearance - Handle Overlay & Equipped Item
**Steps:**
1. Find "Handle Overlay" checkbox, toggle it
2. Observe button corner overlay changes
3. Find "Equipped Item Highlight" checkbox, ensure checked
4. Equip an item that's on your action bar
5. Verify green/blue border glow on equipped item
6. Find "Equipped Item Color" color picker, change color
7. Verify equipped item border changes color

**Expected:**
- Handle Overlay shows/hides button corner decorations
- Equipped items get colored border glow
- Color picker changes the glow color

**Result:**
- ✅ **Pass** if all appearance options work
- ❌ **Fail** if no visual changes

---

### Test 59: Cooldowns - Desaturate & Flash Settings
**Steps:**
1. Find "Desaturate on Cooldown" checkbox, ensure checked
2. Find "Hide Cooldown Bling" checkbox, test both states
3. Find "Flash Animation" checkbox, test toggle
4. Cast spell with cooldown, verify each setting's effect

**Expected:**
- Desaturate: Icon turns grayscale during cooldown
- Hide Bling: Flash animation on cooldown end is hidden
- Flash Animation: Spell proc flash on button

**Result:**
- ✅ **Pass** if all cooldown appearance settings work
- ❌ **Fail** if effects don't apply

---

### Test 60: Cooldowns - Charge Cooldown & Swipe Colors
**Steps:**
1. Find "Charge Cooldown" checkbox, ensure checked
2. Find "Draw Swipe on Charges" checkbox, toggle it
3. Use spell with charges (e.g., Warlock's Conflagrate)
4. Verify charge cooldown displays correctly
5. Find "Swipe Color (Normal)" color picker, change it
6. Find "Swipe Color (LOC)" color picker, change it
7. Cast spell, verify swipe color matches

**Expected:**
- Charge Cooldown shows individual charge recharge timers
- Draw Swipe displays swipe animation for charges
- Color pickers change the cooldown swipe colors
- LOC color applies to loss-of-control effects

**Result:**
- ✅ **Pass** if charge cooldowns and colors work
- ❌ **Fail** if settings don't affect display

---

### Test 61: Button Colors - Range, Power, Usability
**Steps:**
1. Find button color pickers: "Out of Range", "No Power", "Not Usable", "Usable"
2. Change each color
3. Test with appropriate spells:
   - Out of Range: Target enemy far away
   - No Power: Cast spell without enough mana
   - Not Usable: Use ability that's unusable (wrong target, etc.)
   - Usable: Normal spell ready to cast
4. Find "Apply Range Color to Text" checkbox, toggle it

**Expected:**
- Each color picker changes button tint for that state
- Range color to text applies coloring to button text as well
- Colors update in real-time

**Result:**
- ✅ **Pass** if all 5 color settings work
- ❌ **Fail** if colors don't apply or incorrect states

---

### Test 62: Cast Modifiers
**Steps:**
1. Find "Check Self Cast" checkbox
2. Find "Check Focus Cast" checkbox
3. Find "Right Click Self Cast" checkbox
4. Test spell with each setting:
   - Self Cast: Hold modifier + click spell
   - Focus Cast: Cast spell on focus target
   - Right Click: Right-click spell to self-cast

**Expected:**
- Check Self Cast: Detects self-cast modifier for button coloring
- Check Focus Cast: Detects focus-cast modifier for button coloring
- Right Click Self Cast: Right-click casts spell on yourself

**Result:**
- ✅ **Pass** if modifiers work as expected
- ❌ **Fail** if settings don't affect casting behavior

---

### Test 63: Movement & Misc - Movement Modifier & Flyout Size
**Steps:**
1. Find "Movement Modifier" dropdown (NONE, SHIFT, CTRL, ALT)
2. Set to "SHIFT"
3. Unlock bars, verify must hold SHIFT to move bars
4. Find "Flyout Button Size" slider
5. Set to different values (20-60)
6. Open a flyout menu (spell with multiple ranks/options)
7. Verify flyout button size matches slider value

**Expected:**
- Movement Modifier requires holding key to move unlocked bars
- Flyout Size slider changes size of flyout menu buttons

**Result:**
- ✅ **Pass** if both settings work
- ❌ **Fail** if modifier ignored or flyout size doesn't change

---

### Test 64: Profession Quality (Retail Only)
**Steps:**
1. Find "Show Profession Quality" checkbox
2. Find quality settings: Anchor Point, X/Y Offset, Scale, Alpha
3. Have a crafted item with quality on action bar
4. Toggle "Show Profession Quality" - indicator should show/hide
5. Change Anchor Point - indicator position changes
6. Adjust X/Y Offset - fine-tune position
7. Change Scale - indicator size changes
8. Change Alpha - indicator transparency changes

**Expected:**
- All 6 profession quality settings affect the quality indicator
- Changes apply immediately
- (Classic/TBC: Settings exist but have no effect - that's OK)

**Result:**
- ✅ **Pass** if all 6 settings work on Retail
- ✅ **Pass** on Classic if settings don't error (no effect expected)
- ❌ **Fail** if errors occur or settings don't work on Retail

---

### Test 65: Default Font Settings
**Steps:**
1. Scroll to "Default Font Settings" section
2. Note: Small gray text says "Applied to all bars unless overridden"
3. Find "Font" dropdown with options: Friz Quadrata TT, Arial Narrow, Skurri, Morpheus
4. Change font, verify text on action bars changes
5. Find "Font Size" slider (6-32)
6. Change size, verify button text size changes
7. Find "Font Outline" dropdown: NONE, OUTLINE, THICKOUTLINE, MONOCHROME
8. Change outline, verify text outline changes

**Expected:**
- Font dropdown changes the font face of all bar text
- Font Size slider changes text size globally
- Font Outline changes text outline style
- Changes apply to hotkey, macro, and count text on buttons
- Individual bar settings can override these defaults

**Result:**
- ✅ **Pass** if all 3 font settings work and affect bar text
- ❌ **Fail** if settings don't change text appearance

---

### Test 66: Settings Persistence
**Steps:**
1. Change several Global settings to non-default values:
   - Set Global Fade Alpha to 0.7
   - Enable Preserve Default Appearance
   - Disable Transparent Buttons
   - Change Swipe Color (Normal) to red
   - Set Font Size to 16
2. Type `/reload`
3. Open config: `/totalui config`
4. Navigate to Global tab
5. Verify all changed settings retained their values

**Expected:**
- All settings persist across reload
- Values are exactly as set before reload
- No reset to defaults

**Result:**
- ✅ **Pass** if all settings persist
- ❌ **Fail** if any setting resets to default

---

### Test 67: Navigation - Tab Switching
**Steps:**
1. Open config: `/totalui config`
2. Click "Global" tab - verify Global settings panel shows
3. Click "ActionBars 1-15" tab - verify secondary left nav appears with Bar 1-15
4. Click "Special Action Bars" tab - verify secondary nav shows Pet Bar, Stance Bar, etc.
5. Click individual bars in secondary nav
6. Return to "Global" tab - verify secondary nav hides

**Expected:**
- Tab switching works smoothly
- Secondary navigation shows/hides appropriately
- Content area adjusts width based on secondary nav visibility
- No errors or visual glitches

**Result:**
- ✅ **Pass** if navigation works perfectly
- ❌ **Fail** if tabs don't switch, nav doesn't show/hide, or errors occur

---

### Test 68: Dynamic Tab Sizing
**Steps:**
1. Open config: `/totalui config`
2. Observe the three top tabs: "Global", "ActionBars 1-15", "Special Action Bars"
3. Verify text is not truncated
4. Verify tabs are properly sized (not too small, not overlapping)

**Expected:**
- Tab width adjusts based on text content
- All text fully visible
- Tabs have appropriate spacing between them

**Result:**
- ✅ **Pass** if tabs are properly sized and readable
- ❌ **Fail** if text truncated or tabs overlap

---

## Phase 1C Summary

**Total Tests:** 16 (Tests 53-68)

**Required for Pass:** All 16 tests must pass

**Phase 1C Deliverables:**
- ✅ Comprehensive ConfigGUI with nested navigation
- ✅ All 34 global ActionBar settings implemented
  - 31 ElvUI-parity settings
  - 3 TotalUI-specific settings (preserveDefaultAppearance, font settings)
- ✅ Real-time setting updates (no reload required)
- ✅ Settings persistence across reload/logout
- ✅ Clean 3-tab navigation hierarchy
- ✅ Dynamic tab sizing
- ✅ Secondary nested navigation for individual bars

**Global Settings Tested:**
- **Basic Settings (3):** Enable, Preserve Default Appearance, Lock ActionBars
- **Appearance (6):** Global Fade Alpha, Transparent Buttons, Transparent Backdrops, Handle Overlay, Equipped Item Highlight, Equipped Item Color
- **Cooldowns (7):** Desaturate on Cooldown, Hide Cooldown Bling, Flash Animation, Charge Cooldown, Draw Swipe on Charges, Swipe Color (Normal), Swipe Color (LOC)
- **Button Colors (5):** Out of Range, No Power, Not Usable, Usable, Apply Range Color to Text
- **Cast Modifiers (3):** Check Self Cast, Check Focus Cast, Right Click Self Cast
- **Movement & Misc (2):** Movement Modifier, Flyout Button Size
- **Profession Quality (6):** Enable, Anchor Point, X Offset, Y Offset, Scale, Alpha
- **Default Font Settings (3):** Font, Font Size, Font Outline

**If Tests Fail:**
1. Verify TotalUI_Options addon is enabled
2. Check `/console scriptErrors 1` for Lua errors
3. Ensure Phase 1A and 1B tests still pass
4. Review ConfigGUI.lua and Profile.lua for the failed setting
5. Test in both Retail and Classic if applicable
6. Fix issue and rerun Phase 1C tests

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
