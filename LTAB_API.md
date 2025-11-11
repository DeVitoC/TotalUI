# LibTotalActionButtons-1.0 API Documentation

Complete public API reference for LibTotalActionButtons, a comprehensive action button library for World of Warcraft addons.

**Version**: 1.0
**Library Name**: `LibTotalActionButtons-1.0`
**Access**: `local LTAB = LibStub("LibTotalActionButtons-1.0")`

---

## Table of Contents

1. [Button Creation](#button-creation)
2. [Button Configuration](#button-configuration)
3. [State Management](#state-management)
4. [Button Updates](#button-updates)
5. [Visual Features](#visual-features)
6. [Flyout System](#flyout-system)
7. [Keybinding](#keybinding)
8. [Callbacks](#callbacks)
9. [Utility Functions](#utility-functions)
10. [Constants](#constants)

---

## Button Creation

### LTAB:CreateActionButton(actionID, name, parent, config)
Creates an action button bound to a specific action slot.

**Parameters:**
- `actionID` (number) - WoW action slot ID (1-120)
- `name` (string) - Unique button name
- `parent` (frame, optional) - Parent frame (defaults to UIParent)
- `config` (table, optional) - Configuration table

**Returns:** Button frame or nil on error

**Example:**
```lua
local button = LTAB:CreateActionButton(1, "MyButton1", UIParent)
button:SetPoint("CENTER", 0, 0)
button:Show()
```

---

### LTAB:CreateSpellButton(spellID, name, parent, config)
Creates a button for a specific spell.

**Parameters:**
- `spellID` (number) - Spell ID
- `name` (string) - Unique button name
- `parent` (frame, optional) - Parent frame
- `config` (table, optional) - Configuration table

**Returns:** Button frame or nil on error

**Example:**
```lua
local button = LTAB:CreateSpellButton(133, "MyFireball", UIParent)
```

---

### LTAB:CreateItemButton(itemID, name, parent, config)
Creates a button for a specific item.

**Parameters:**
- `itemID` (number) - Item ID or item string
- `name` (string) - Unique button name
- `parent` (frame, optional) - Parent frame
- `config` (table, optional) - Configuration table

**Returns:** Button frame or nil on error

**Example:**
```lua
local button = LTAB:CreateItemButton(6948, "MyHearthstone", UIParent)
```

---

### LTAB:CreateMacroButton(macroID, name, parent, config)
Creates a button for a macro.

**Parameters:**
- `macroID` (number) - Macro ID (1-138)
- `name` (string) - Unique button name
- `parent` (frame, optional) - Parent frame
- `config` (table, optional) - Configuration table

**Returns:** Button frame or nil on error

---

### LTAB:CreateCustomButton(id, name, parent, config, updateFunctions)
Creates a custom button with user-defined update functions.

**Parameters:**
- `id` (number) - Unique numeric ID
- `name` (string) - Unique button name
- `parent` (frame, optional) - Parent frame
- `config` (table, optional) - Configuration table
- `updateFunctions` (table) - Table of update function callbacks

**Returns:** Button frame or nil on error

---

## Button Configuration

### Configuration Table Structure
```lua
config = {
    -- Appearance
    showCount = true,           -- Show item/charge count
    showHotkey = true,          -- Show keybinding text
    showMacroName = false,      -- Show macro name
    showTooltip = true,         -- Enable tooltips
    showGrid = false,           -- Show empty button grid

    -- Colors
    colors = {
        range = {r, g, b, a},   -- Out of range color
        mana = {r, g, b, a},    -- Out of power color
        usable = {r, g, b, a},  -- Usable color
        notUsable = {r, g, b, a}, -- Not usable color
    },

    -- Behavior
    clickOnDown = false,        -- Click on button down vs up
    flyoutDirection = "UP",     -- Flyout expansion direction

    -- Advanced (Retail only)
    hideElements = {},          -- Elements to hide
    desaturateUnusable = true,  -- Desaturate unusable buttons
    actionButtonUI = false,     -- Register with ActionButtonUI
    assistedHighlight = false,  -- Enable assisted highlight
    spellCastVFX = true,        -- Enable spell cast VFX
}
```

---

### LTAB:SetButtonSize(button, width, height)
Sets button dimensions.

**Parameters:**
- `button` (frame) - Button frame
- `width` (number) - Width in pixels
- `height` (number, optional) - Height in pixels (defaults to width)

**Example:**
```lua
LTAB:SetButtonSize(button, 36, 36)
```

---

### LTAB:StyleButton(button, config)
Applies styling configuration to a button.

**Parameters:**
- `button` (frame) - Button frame
- `config` (table) - Configuration table

---

### LTAB:SetBorderTexture(button, texture, size, offset)
Sets a custom border texture on a button.

**Parameters:**
- `button` (frame) - Button frame
- `texture` (string) - Texture path
- `size` (number, optional) - Border size
- `offset` (number, optional) - Border offset

**Example:**
```lua
LTAB:SetBorderTexture(button, "Interface\\Buttons\\WHITE8X8", 40, 2)
```

---

## State Management

### LTAB:SetState(button, state, buttonType, action)
Sets what action a button performs in a specific state.

**Parameters:**
- `button` (frame) - Button frame
- `state` (string) - State identifier (e.g., "0", "1", "stealth")
- `buttonType` (string) - Type: "action", "spell", "item", "macro", or "empty"
- `action` (number/string) - Action ID, spell ID, item ID, or macro ID

**Example:**
```lua
-- State 0: Cast Frostbolt
LTAB:SetState(button, "0", "spell", 116)

-- State 1: Cast Fireball
LTAB:SetState(button, "1", "spell", 133)

-- Clear state (empty button)
LTAB:SetState(button, "2", "empty", nil)
```

---

### LTAB:GetState(button, state)
Gets the current or specified state information.

**Parameters:**
- `button` (frame) - Button frame
- `state` (string, optional) - State identifier (nil = current state)

**Returns:**
- If no state param: current state string
- If state param: buttonType, action for that state

**Example:**
```lua
local currentState = LTAB:GetState(button)
local buttonType, action = LTAB:GetState(button, "0")
```

---

### LTAB:UpdateState(button, newState)
Switches button to a different state.

**Parameters:**
- `button` (frame) - Button frame
- `newState` (string) - State to switch to

**Example:**
```lua
LTAB:UpdateState(button, "1")  -- Switch to state 1
```

---

### LTAB:ClearStates(button)
Clears all state configurations from a button.

**Parameters:**
- `button` (frame) - Button frame

---

### LTAB:GetAction(button, state)
Gets the action configured for a specific state.

**Parameters:**
- `button` (frame) - Button frame
- `state` (string, optional) - State identifier (nil = current state)

**Returns:** buttonType, action

---

### LTAB:UpdateAllStates(newState)
Updates all registered buttons to a new state.

**Parameters:**
- `newState` (string) - State to switch all buttons to

---

## Button Updates

### LTAB:UpdateButton(button)
Performs a complete update of all button visuals and state.

**Parameters:**
- `button` (frame) - Button frame

**Updates:**
- Icon
- Count
- Cooldown
- Hotkey
- Usability
- Range
- Visual state
- Grid visibility

---

### LTAB:UpdateLocal(button)
Lightweight visual-only update (no expensive action lookups).

**Parameters:**
- `button` (frame) - Button frame

---

### LTAB:UpdateIcon(button)
Updates button icon texture.

**Parameters:**
- `button` (frame) - Button frame

---

### LTAB:UpdateCount(button)
Updates item/charge count display.

**Parameters:**
- `button` (frame) - Button frame

---

### LTAB:UpdateCooldown(button)
Updates cooldown display and animations.

**Parameters:**
- `button` (frame) - Button frame

---

### LTAB:UpdateHotkey(button)
Updates keybinding text display.

**Parameters:**
- `button` (frame) - Button frame

---

### LTAB:UpdateHotkeys(button)
Updates hotkey for a specific button.

**Parameters:**
- `button` (frame) - Button frame

---

### LTAB:UpdateUsable(button)
Updates button usability state (desaturation, coloring).

**Parameters:**
- `button` (frame) - Button frame

---

### LTAB:UpdateRange(button)
Updates out-of-range indicator.

**Parameters:**
- `button` (frame) - Button frame

---

### LTAB:UpdateVisualState(button)
Updates button checked/pressed visual state.

**Parameters:**
- `button` (frame) - Button frame

---

### LTAB:UpdateGrid(button)
Updates empty button grid visibility.

**Parameters:**
- `button` (frame) - Button frame

---

### LTAB:UpdateTooltip(button)
Updates button tooltip based on configuration.

**Parameters:**
- `button` (frame) - Button frame

---

### LTAB:UpdateAlpha(button)
Updates button transparency.

**Parameters:**
- `button` (frame) - Button frame

---

## Visual Features

### LTAB:ShowOverlayGlow(button)
Shows proc glow animation on a button.

**Parameters:**
- `button` (frame) - Button frame

---

### LTAB:HideOverlayGlow(button)
Hides proc glow animation.

**Parameters:**
- `button` (frame) - Button frame

---

### LTAB:UpdateOverlayGlow(button)
Updates overlay glow state based on spell procs.

**Parameters:**
- `button` (frame) - Button frame

---

### LTAB:ShowSpellAlert(button, spellID)
Shows spell activation alert animation.

**Parameters:**
- `button` (frame) - Button frame
- `spellID` (number, optional) - Spell ID for the alert

**Retail Only**

---

### LTAB:HideSpellAlert(button)
Hides spell alert animation.

**Parameters:**
- `button` (frame) - Button frame

**Retail Only**

---

### LTAB:ShowInterruptDisplay(button)
Shows interrupt animation (star burst effect).

**Parameters:**
- `button` (frame) - Button frame

---

### LTAB:UpdateSpellHighlight(button)
Updates spell highlight animation (yellow glow from spellbook).

**Parameters:**
- `button` (frame) - Button frame

**Retail Only**

---

### LTAB:UpdateFrameLevels(button)
Updates frame stacking levels for all button elements.

**Parameters:**
- `button` (frame) - Button frame

---

### LTAB:UpdateEquippedBorder(button)
Updates item quality border for equipped items.

**Parameters:**
- `button` (frame) - Button frame

---

### LTAB:UpdateNewAction(button)
Updates "new action" highlight marker.

**Parameters:**
- `button` (frame) - Button frame

---

### LTAB:ClearNewActionHighlight(actionID, preventIdenticalActionsUpdate)
Clears new action highlight for a specific action.

**Parameters:**
- `actionID` (number) - Action slot ID
- `preventIdenticalActionsUpdate` (boolean) - Prevent updating identical actions

---

## Flyout System

### LTAB:UpdateFlyout(button)
Updates flyout menu for a button.

**Parameters:**
- `button` (frame) - Button frame

---

### LTAB:SetFlyoutDirection(button, direction)
Sets flyout expansion direction.

**Parameters:**
- `button` (frame) - Button frame
- `direction` (string) - "UP", "DOWN", "LEFT", or "RIGHT"

---

### LTAB:PositionFlyout(button)
Positions flyout menu relative to parent button.

**Parameters:**
- `button` (frame) - Button frame

---

### LTAB:DiscoverFlyoutInfo(flyoutID)
Discovers and caches information about a flyout.

**Parameters:**
- `flyoutID` (number) - Flyout ID

---

### LTAB:SyncFlyoutInfoToSecure()
Synchronizes flyout data to secure environment.

**Retail Only**

---

## Keybinding

### LTAB:UpdateKeybindingDisplay(button)
Updates keybinding text display on a button.

**Parameters:**
- `button` (frame) - Button frame

---

### LTAB:GetBindingForAction(actionID)
Gets the keybinding for a specific action.

**Parameters:**
- `actionID` (number) - Action slot ID

**Returns:** Key binding string (e.g., "1", "SHIFT-2")

---

### LTAB:ClearAllBindings()
Clears all keybindings for action bars.

**Warning:** Affects user's actual keybindings

---

## Callbacks

### LTAB:RegisterCallback(event, callback)
Registers a callback for an event.

**Parameters:**
- `event` (string) - Event name
- `callback` (function) - Callback function

**Events:**
- `"OnButtonCreated"` - (button) - When a button is created
- `"OnButtonUpdate"` - (button) - When a button updates
- `"OnButtonEnter"` - (button) - When mouse enters button
- `"OnButtonLeave"` - (button) - When mouse leaves button
- `"OnButtonContentsChanged"` - (button) - When button action changes
- `"OnKeybindingChanged"` - (oldKey, newKey) - When keybinding changes

**Example:**
```lua
LTAB:RegisterCallback("OnButtonCreated", function(button)
    print("Button created:", button:GetName())
end)
```

---

### LTAB:UnregisterCallback(event, callback)
Unregisters a callback.

**Parameters:**
- `event` (string) - Event name
- `callback` (function) - Callback function to remove

---

### LTAB:UnregisterAllCallbacks(event)
Unregisters all callbacks for an event.

**Parameters:**
- `event` (string) - Event name

---

### LTAB:FireCallback(event, ...)
Manually fires a callback event.

**Parameters:**
- `event` (string) - Event name
- `...` - Arguments to pass to callbacks

---

## Utility Functions

### LTAB:GetAllButtons()
Gets an iterator over all registered buttons.

**Returns:** Iterator function for use in for loops

**Example:**
```lua
for button in LTAB:GetAllButtons() do
    print(button:GetName())
end
```

---

### LTAB:ForAllButtons(func, ...)
Executes a function for all registered buttons.

**Parameters:**
- `func` (function) - Function to execute (receives button as first arg)
- `...` - Additional arguments to pass to function

**Example:**
```lua
LTAB:ForAllButtons(function(button)
    LTAB:UpdateButton(button)
end)
```

---

### LTAB:ForAllButtonsWithSpell(spellID, func, ...)
Executes a function for all buttons with a specific spell.

**Parameters:**
- `spellID` (number) - Spell ID to match
- `func` (function) - Function to execute
- `...` - Additional arguments

---

### LTAB:ForAllButtonsWithItem(itemID, func, ...)
Executes a function for all buttons with a specific item.

**Parameters:**
- `itemID` (number) - Item ID to match
- `func` (function) - Function to execute
- `...` - Additional arguments

---

### LTAB:ForAllButtonsWithAction(actionID, func, ...)
Executes a function for all buttons with a specific action.

**Parameters:**
- `actionID` (number) - Action slot ID to match
- `func` (function) - Function to execute
- `...` - Additional arguments

---

### LTAB:ButtonContentsChanged(button, newAction)
Notifies that button contents have changed.

**Parameters:**
- `button` (frame) - Button frame
- `newAction` (any, optional) - New action identifier

---

### LTAB:SetDebug(enabled)
Enables or disables debug output.

**Parameters:**
- `enabled` (boolean) - Enable debug mode

---

### LTAB:CheckCombat(functionName, errorOnCombat)
Checks if player is in combat and handles accordingly.

**Parameters:**
- `functionName` (string) - Function name for error message
- `errorOnCombat` (boolean) - Whether to throw error in combat

**Returns:** true if in combat, false otherwise

---

## Constants

### LTAB.ButtonType
Button type constants for SetState:
```lua
LTAB.ButtonType.ACTION   -- "action"
LTAB.ButtonType.SPELL    -- "spell"
LTAB.ButtonType.ITEM     -- "item"
LTAB.ButtonType.MACRO    -- "macro"
LTAB.ButtonType.EMPTY    -- "empty"
```

---

### LTAB.VERSION
Library version number (number)

---

### LTAB.VERSION_STRING
Human-readable version string (string)

---

### LTAB.WoWRetail
Boolean indicating if running on Retail WoW

---

### LTAB.WoWClassic
Boolean indicating if running on Classic Era

---

### LTAB.WoWBCC
Boolean indicating if running on Burning Crusade Classic

---

### LTAB.WoWWrath
Boolean indicating if running on Wrath Classic

---

### LTAB.WoWCata
Boolean indicating if running on Cataclysm Classic

---

## Advanced Features (Retail Only)

### LTAB:UpdateAssistedCombatRotationFrame(button)
Updates assisted combat rotation frame indicators.

**Parameters:**
- `button` (frame) - Button frame

---

### LTAB:UpdatedAssistedHighlightFrame(button)
Updates assisted spell highlight frame.

**Parameters:**
- `button` (frame) - Button frame

---

### LTAB:RegisterActionUI(button)
Registers button with Blizzard's ActionButtonUI system.

**Parameters:**
- `button` (frame) - Button frame

---

### LTAB:SpellVFX_PlaySpellCastAnim(button)
Plays spell cast animation VFX.

**Parameters:**
- `button` (frame) - Button frame

---

### LTAB:SpellVFX_StopSpellCastAnim(button)
Stops spell cast animation VFX.

**Parameters:**
- `button` (frame) - Button frame

---

### LTAB:SpellVFX_PlayTargettingReticleAnim(button)
Plays targeting reticle animation.

**Parameters:**
- `button` (frame) - Button frame

---

### LTAB:SpellVFX_StopTargettingReticleAnim(button)
Stops targeting reticle animation.

**Parameters:**
- `button` (frame) - Button frame

---

### LTAB:SpellVFX_PlaySpellInterruptedAnim(button)
Plays spell interrupted animation (star burst).

**Parameters:**
- `button` (frame) - Button frame

---

### LTAB:SpellVFX_ClearReticle(button)
Clears targeting reticle.

**Parameters:**
- `button` (frame) - Button frame

---

### LTAB:SpellVFX_ClearInterruptDisplay(button)
Clears interrupt display animation.

**Parameters:**
- `button` (frame) - Button frame

---

## Additional Methods

### LTAB:SetStateFromHandlerInsecure(button, state, kind, action)
Sets state from insecure handler (for compatibility with LAB-1.0).

**Parameters:**
- `button` (frame) - Button frame
- `state` (string) - State identifier
- `kind` (string) - Action type
- `action` (any) - Action data

---

### LTAB:NewHeader(button, header)
Reassigns button to a new secure header.

**Parameters:**
- `button` (frame) - Button frame
- `header` (frame) - New secure header frame

---

### LTAB:ClearSetPoint(button, ...)
Clears all points and sets new point in one call.

**Parameters:**
- `button` (frame) - Button frame
- `...` - SetPoint arguments

---

## Complete Usage Example

```lua
-- Load library
local LTAB = LibStub("LibTotalActionButtons-1.0")

-- Create a spell button
local button = LTAB:CreateSpellButton(133, "MyFireballButton", UIParent, {
    showCount = true,
    showHotkey = true,
    desaturateUnusable = true,
})

-- Position and size
button:SetPoint("CENTER", 0, 0)
LTAB:SetButtonSize(button, 40, 40)
button:Show()

-- Set up states
LTAB:SetState(button, "0", "spell", 133)  -- Fireball in normal state
LTAB:SetState(button, "1", "spell", 116)  -- Frostbolt in alternate state

-- Register callback
LTAB:RegisterCallback("OnButtonUpdate", function(btn)
    if btn == button then
        print("Button updated!")
    end
end)

-- Switch states
LTAB:UpdateState(button, "1")

-- Update button
LTAB:UpdateButton(button)
```

---

## Notes

- All button creation functions return `nil` on error and print error messages
- Most update functions silently fail if button is `nil`
- Retail-only features will no-op on Classic clients
- Combat restrictions apply to button creation and some updates
- Callbacks use CallbackHandler-1.0 for compatibility

---

**End of API Documentation**
