# Developer Guide for TotalUI

Quick reference for developers implementing phases 1-13.

## Core Principles

1. **Always use the compatibility layer** - Never call WoW APIs directly
2. **Access settings through E.db/E.global/E.private** - Never touch TotalUIDB directly
3. **Use LSM for media** - Never hardcode font/texture paths
4. **Register callbacks for settings changes** - Make features live-update
5. **Respect combat restrictions** - Use E:QueueAfterCombat() for protected operations

## Quick Reference

### Accessing the Addon

```lua
local AddonName, ns = ...
local E = ns.public  -- This is TotalUI
```

### Creating a Module

```lua
local MyModule = E:NewModule("MyModuleName")

function MyModule:Initialize()
    -- Check if enabled
    if not E.private.mymodule.enable then return end

    -- Your initialization code
    self:CreateFrames()
    self:RegisterEvents()

    self.initialized = true
end

function MyModule:Update()
    if not self.initialized then return end
    -- Update when settings change
end
```

### Database Access

```lua
-- Profile settings (can be shared across characters)
E.db.actionbar.bar1.enabled
E.db.unitframe.player.width

-- Global settings (account-wide)
E.global.datatexts.customPanels
E.global.general.version

-- Private settings (character-locked)
E.private.actionbars.enable
E.private.skins.blizzard
```

### API Wrapper Usage

**Instead of this (bad):**
```lua
local info = GetContainerItemInfo(0, 1)
local name = GetItemInfo(itemID)
local spellName = GetSpellInfo(spellID)
```

**Do this (good):**
```lua
local info = E.Compat:GetContainerItemInfo(0, 1)
local name = E.Compat:GetItemName(itemID)
local spellName = E.Compat:GetSpellName(spellID)
```

### Frame Creation

```lua
-- Create frame with proper backdrop support
local frame = E:CreateFrame("Frame", "MyFrameName", UIParent)

-- Add backdrop (uses database colors)
E:CreateBackdrop(frame)

-- Or use template
E:SetTemplate(frame, "Default")

-- Create status bar (uses LSM texture)
local bar = E:CreateStatusBar(frame)

-- Create font string (uses LSM font)
local text = E:CreateFontString(frame, "OVERLAY", 12, "OUTLINE")
text:SetText("Hello World")
```

### Media (Fonts, Textures, Sounds)

```lua
-- Fetch font from LSM
local fontPath = E.LSM:Fetch("font", E.db.general.font)

-- Fetch texture from LSM
local texturePath = E.LSM:Fetch("statusbar", E.db.general.statusbar)

-- Register custom media (in LibraryLoader.lua)
E.LSM:Register("font", "MyFont", [[Interface\AddOns\TotalUI\Media\Fonts\MyFont.ttf]])
```

### Event Handling

```lua
-- Register normal event
self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnPlayerEnter")

function MyModule:OnPlayerEnter()
    -- Handle event
end

-- Register bucket event (throttled)
E:RegisterBucketEvent("UNIT_HEALTH", 0.5, function(unit)
    -- Called at most every 0.5 seconds
end)

-- Register custom callback
E.callbacks:Register("EnterCombat", function()
    print("Entered combat!")
end)

-- Available callbacks:
-- "EnterCombat", "LeaveCombat"
-- "AddonLoaded", "DatabaseReady"
-- "ResolutionChanged", "ZoneChanged"
```

### Combat Handling

```lua
-- Check combat state
if E.inCombat then
    -- Queue for after combat
    E:QueueAfterCombat(function()
        -- This runs when you leave combat
        self:RepositionBars()
    end)
else
    -- Safe to run now
    self:RepositionBars()
end

-- Callbacks
E.callbacks:Register("EnterCombat", function()
    -- Hide movable anchors, etc.
end)

E.callbacks:Register("LeaveCombat", function()
    -- Process queued updates
end)
```

### Color Utilities

```lua
-- Get class color
local r, g, b = E:GetClassColor("WARRIOR")
local r, g, b = E:GetClassColor(E.myclass)

-- RGB to Hex
local hexColor = E:RGBToHex(1, 0, 0)  -- "|cffff0000"

-- Hex to RGB
local r, g, b = E:HexToRGB("ff0000")

-- Unit color (class or reaction)
local r, g, b = E:GetUnitColor("target", true)

-- Difficulty color
local r, g, b = E:GetDifficultyColor(targetLevel)
```

### Value Formatting

```lua
-- Short value (1234567 -> "1.2m")
local short = E:ShortValue(value)

-- Time format (3661 -> "1h")
local time = E:FormatTime(seconds)

-- Round number
local rounded = E:Round(123.456, 2)  -- 123.46

-- Clamp value
local clamped = E:Clamp(value, 0, 100)
```

### Table Utilities

```lua
-- Deep copy table
local copy = E:CopyTable(sourceTable, destTable)

-- Table length
local count = E:TableLength(myTable)
```

### Settings Changes

```lua
-- When settings change, fire callbacks
E:FireConfigCallbacks()

-- Modules can listen
E:RegisterConfigCallback(function()
    MyModule:Update()
end)

-- Or in module:
E.callbacks:Register("ConfigChanged", function()
    self:Update()
end)
```

### Utility Functions

```lua
-- Positioning
E:Point(frame, "CENTER", UIParent, "CENTER", 0, 0)
E:Size(frame, 200, 100)
E:SetOutsidePoint(border, "TOPLEFT", frame)

-- Frame manipulation
E:Hide(frame)
E:Show(frame)
E:Toggle(frame)
E:Kill(frame)  -- Completely disable

-- Scale
local scaled = E:Scale(value)

-- Opposite anchor
local opposite = E:GetOppositeAnchor("TOPLEFT")  -- "BOTTOMRIGHT"
```

### Smooth Animations

```lua
-- Smooth status bar
E:SmoothBar(healthBar)

-- Update smoothly
E:SetSmoothValue(healthBar, newValue)
```

## Module Template

```lua
--[[
    TotalUI - MyModule (Phase X)
    Description of what this module does.
--]]

local AddonName, ns = ...
local E = ns.public

-- Create module
local MyModule = E:NewModule("MyModule")

-- Module-level variables
local frames = {}

-----------------------------------
-- INITIALIZATION
-----------------------------------

function MyModule:Initialize()
    -- Check if enabled
    if not E.private.mymodule.enable then
        return
    end

    -- Create UI
    self:CreateFrames()

    -- Register events
    self:RegisterEvents()

    -- Register callbacks
    E.callbacks:Register("EnterCombat", function()
        self:OnEnterCombat()
    end)

    E.callbacks:Register("DatabaseReady", function()
        self:Update()
    end)

    self.initialized = true
    E:Print("MyModule loaded")
end

-----------------------------------
-- FRAME CREATION
-----------------------------------

function MyModule:CreateFrames()
    -- Create main frame
    local frame = E:CreateFrame("Frame", "TotalUI_MyModule", UIParent)
    frame:SetSize(200, 100)
    frame:SetPoint("CENTER")

    -- Add backdrop
    E:CreateBackdrop(frame)

    -- Create status bar
    local bar = E:CreateStatusBar(frame)
    bar:SetPoint("TOPLEFT", 2, -2)
    bar:SetPoint("BOTTOMRIGHT", -2, 2)

    -- Create text
    local text = E:CreateFontString(frame, "OVERLAY")
    text:SetPoint("CENTER")
    text:SetText("Hello")

    -- Store references
    frames.main = frame
    frames.bar = bar
    frames.text = text
end

-----------------------------------
-- EVENT HANDLERS
-----------------------------------

function MyModule:RegisterEvents()
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "Update")
    self:RegisterEvent("PLAYER_LEVEL_UP", "OnLevelUp")

    -- Bucket event example
    E:RegisterBucketEvent("UNIT_HEALTH", 0.2, function(unit)
        if unit == "player" then
            self:UpdateHealth()
        end
    end)
end

function MyModule:OnLevelUp(event, level)
    -- Handle level up
    self:Update()
end

function MyModule:OnEnterCombat()
    -- Handle combat start
end

-----------------------------------
-- UPDATE FUNCTIONS
-----------------------------------

function MyModule:Update()
    if not self.initialized then return end

    self:UpdateVisibility()
    self:UpdatePosition()
    self:UpdateAppearance()
end

function MyModule:UpdateVisibility()
    local db = E.db.mymodule
    if db.enabled then
        frames.main:Show()
    else
        frames.main:Hide()
    end
end

function MyModule:UpdatePosition()
    local db = E.db.mymodule
    E:Point(frames.main, db.point, UIParent, db.point, db.x, db.y)
end

function MyModule:UpdateAppearance()
    local db = E.db.mymodule
    E:Size(frames.main, db.width, db.height)

    -- Update backdrop colors
    if frames.main.backdrop then
        E.Compat:SetBackdropColor(
            frames.main.backdrop,
            db.color.r, db.color.g, db.color.b, db.color.a
        )
    end
end

function MyModule:UpdateHealth()
    local current = UnitHealth("player")
    local max = UnitHealthMax("player")

    frames.bar:SetMinMaxValues(0, max)
    E:SetSmoothValue(frames.bar, current)

    frames.text:SetText(E:ShortValue(current) .. " / " .. E:ShortValue(max))
end

-----------------------------------
-- RETURN MODULE
-----------------------------------

return MyModule
```

## Best Practices

1. **Module Enable/Disable:**
   - Always check `E.private.modulename.enable` in Initialize
   - Return early if disabled

2. **Combat Safety:**
   - Check `E.inCombat` before protected operations
   - Use `E:QueueAfterCombat()` when necessary
   - Never modify action buttons in combat

3. **Performance:**
   - Use bucket events for high-frequency events
   - Cache database values if accessed frequently
   - Unregister events when not needed

4. **Memory:**
   - Clean up frames when module is disabled
   - Unregister callbacks on disable
   - Use weak tables for caches

5. **Settings:**
   - Always provide defaults in `Core/Defaults/Profile.lua`
   - Use database for all configurable values
   - Support live updates when possible

6. **Compatibility:**
   - Test on current WoW version
   - Use compatibility wrappers for all WoW APIs
   - Don't assume features exist (check first)

7. **Errors:**
   - Use pcall for risky operations
   - Provide meaningful error messages
   - Don't break other modules if one fails

## Common Patterns

### Frame Positioning

```lua
-- Anchor to another frame
E:Point(frame, "TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, -5)

-- Center on screen
E:Point(frame, "CENTER", UIParent, "CENTER", 0, 0)

-- Multiple points
frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -10)
frame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -10, 10)
```

### Conditional Visibility

```lua
-- Hide in pet battles
if C_PetBattles.IsInBattle() then
    frame:Hide()
    return
end

-- Hide for specific classes
if E.myclass ~= "WARRIOR" then
    frame:Hide()
    return
end

-- Hide in instances
local inInstance, instanceType = IsInInstance()
if inInstance and instanceType == "raid" then
    frame:Hide()
end
```

### Update Throttling

```lua
-- Throttle updates
local lastUpdate = 0
local updateInterval = 0.5

function MyModule:OnUpdate(elapsed)
    lastUpdate = lastUpdate + elapsed

    if lastUpdate >= updateInterval then
        self:Update()
        lastUpdate = 0
    end
end
```

## Testing Your Module

```lua
-- Test initialization
/run TotalUI:GetModule("MyModule"):Initialize()

-- Test update
/run TotalUI:GetModule("MyModule"):Update()

-- Toggle visibility
/run TotalUI.db.mymodule.enabled = not TotalUI.db.mymodule.enabled; TotalUI:GetModule("MyModule"):Update()

-- Print settings
/run for k,v in pairs(TotalUI.db.mymodule) do print(k,v) end

-- Force reload
/run TotalUI:GetModule("MyModule"):Update()
/reload
```

## Getting Help

- Check existing modules for examples
- Review [PHASE0_COMPLETE.md](PHASE0_COMPLETE.md) for API details
- Review [ADDON_DEVELOPMENT_ACTION_PLAN.md](ADDON_DEVELOPMENT_ACTION_PLAN.md) for requirements
- Test with [TESTING.md](TESTING.md) procedures

## Phase-Specific Notes

- **Phase 1 (ActionBars)**: Use LibActionButton, SecureActionButtonTemplate
- **Phase 2 (UnitFrames)**: Framework TBD (custom implementation likely)
- **Phase 3 (Nameplates)**: Hook NamePlateFramePool
- **Phase 4-12**: Follow patterns from earlier phases
- **Phase 13 (Config)**: Use AceConfig for options GUI

Happy coding!
