# LibTotalActionButtons Feature Gap Analysis

**Document Purpose**: Comprehensive comparison between LibActionButton-1.0 (LAB-1.0) and our LibTotalActionButtons (LTAB) implementation to guide development roadmap.

**Date**: 2025-11-07
**LAB-1.0 Version Analyzed**: Latest from repository
**LTAB Current Version**: 1 (initial implementation)

---

## Table of Contents
1. [Executive Summary](#executive-summary)
2. [Architecture & Foundation](#architecture--foundation)
3. [Button Type System](#button-type-system)
4. [State Management System](#state-management-system)
5. [WoW Version Support](#wow-version-support)
6. [Visual Features & Effects](#visual-features--effects)
7. [Interaction Systems](#interaction-systems)
8. [Configuration & Customization](#configuration--customization)
9. [Integration & Extensibility](#integration--extensibility)
10. [Performance & Optimization](#performance--optimization)
11. [Error Handling & Validation](#error-handling--validation)
12. [Critical Bugs in Current Implementation](#critical-bugs-in-current-implementation)
13. [Development Roadmap](#development-roadmap)

---

## Executive Summary

### Current Status
- **LTAB Lines of Code**: 662
- **LAB-1.0 Lines of Code**: 2,786
- **Feature Completion**: ~25-30%
- **Production Ready**: No

### Critical Gaps
1. ❌ No WoW version detection/compatibility
2. ❌ Only supports action-type buttons
3. ❌ No state management system
4. ❌ No drag & drop functionality
5. ❌ No spell activation overlays
6. ❌ No flyout menu support
7. ❌ Limited error handling
8. ⚠️ Template creation bug (line 83-84)

### What Works
- ✅ Basic button creation and registration
- ✅ Icon, count, cooldown, keybind display
- ✅ Range/power/usability state coloring
- ✅ Event-driven updates
- ✅ Basic visual customization
- ✅ Tooltip support

---

## Architecture & Foundation

### Library Structure

#### LAB-1.0 Has:
```lua
-- LibStub integration with version management
local MAJOR_VERSION = "LibActionButton-1.0"
local MINOR_VERSION = 94
if not LibStub then error(MAJOR_VERSION .. " requires LibStub.") end
local lib, oldversion = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if not lib then return end

-- Proper version upgrade handling
if oldversion then
    -- Migrate from old version
end

-- Embedded libraries
local CBH = LibStub("CallbackHandler-1.0")
lib.eventFrame = lib.eventFrame or CreateFrame("Frame")
lib.eventFrame:SetScript("OnEvent", OnEvent)

-- Button registry
lib.buttonRegistry = lib.buttonRegistry or {}
lib.ActiveButtons = lib.ActiveButtons or {}
lib.actionButtons = lib.actionButtons or {}
lib.nonActionButtons = lib.nonActionButtons or {}
lib.numButtons = lib.numButtons or 0
```

#### LTAB Has:
```lua
-- Simple namespace assignment
local AddonName, ns = ...
if not ns or not ns.public then
    error("LibTotalActionButtons: Namespace not initialized!")
    return
end

local E = ns.public
if not E.Libs then
    E.Libs = {}
end

local LAB = {
    VERSION = 1,
    buttons = {},
    activeButtons = {},
}
E.Libs.LibTotalActionButtons = LAB
```

#### Missing:
- ❌ No LibStub integration
- ❌ No version management (MAJOR/MINOR)
- ❌ No upgrade path handling
- ❌ No CallbackHandler integration
- ❌ No separate registries for different button types
- ❌ No button counting system
- ❌ No dedicated event frame with centralized event handling

**Impact**: Cannot be used by other addons, no callback system, no version control

---

## Button Type System

### LAB-1.0 Button Types

#### 1. Action Buttons (`type = "action"`)
**Purpose**: Standard action bar buttons tied to action slots

**Implementation**:
```lua
ActionTypeUpdateFunctions = {
    HasAction = function(self) return HasAction(self.action) end,
    GetActionText = function(self) return GetActionText(self.action) end,
    GetActionTexture = function(self) return GetActionTexture(self.action) end,
    GetActionCharges = function(self) return GetActionCharges(self.action) end,
    GetActionCount = function(self) return GetActionCount(self.action) end,
    IsAttackAction = function(self) return IsAttackAction(self.action) end,
    IsEquippedAction = function(self) return IsEquippedAction(self.action) end,
    IsCurrentAction = function(self) return IsCurrentAction(self.action) end,
    IsAutoRepeatAction = function(self) return IsAutoRepeatAction(self.action) end,
    IsUsableAction = function(self) return IsUsableAction(self.action) end,
    IsConsumableAction = function(self) return IsConsumableAction(self.action) end,
    IsInRange = function(self) return IsActionInRange(self.action) end,
    IsActionInRange = function(self) return IsActionInRange(self.action) end,
    HasRange = function(self) return HasActionRange(self.action) end,
    GetSpellId = function(self) return select(2, GetActionInfo(self.action)) end,
    GetCooldown = function(self) return GetActionCooldown(self.action) end,
    GetLossOfControlCooldown = function(self) return GetActionLossOfControlCooldown(self.action) end,
}
```

#### 2. Spell Buttons (`type = "spell"`)
**Purpose**: Buttons that cast spells by spell ID

**Implementation**:
```lua
SpellTypeUpdateFunctions = {
    HasAction = function(self) return true end,
    GetActionText = function(self) return "" end,
    GetActionTexture = function(self)
        local texture = GetSpellTexture(self.action_spell)
        return texture
    end,
    GetActionCharges = function(self)
        local charges, maxCharges, start, duration = GetSpellCharges(self.action_spell)
        return charges, maxCharges, start, duration
    end,
    GetActionCount = function(self)
        return GetSpellCount(self.action_spell)
    end,
    IsAttackAction = function(self) return IsAttackSpell(FindSpellBookSlotBySpellID(self.action_spell), "spell") end,
    IsEquippedAction = function(self) return false end,
    IsCurrentAction = function(self) return IsCurrentSpell(self.action_spell) end,
    IsAutoRepeatAction = function(self) return IsAutoRepeatSpell(FindSpellBookSlotBySpellID(self.action_spell), "spell") end,
    IsUsableAction = function(self)
        local usable, nomana = IsUsableSpell(self.action_spell)
        return usable, nomana
    end,
    IsConsumableAction = function(self) return IsConsumableSpell(self.action_spell) end,
    IsInRange = function(self)
        local inRange = IsSpellInRange(FindSpellBookSlotBySpellID(self.action_spell), "spell", "target")
        if inRange == 1 then
            return true
        elseif inRange == 0 then
            return false
        else
            return nil
        end
    end,
    HasRange = function(self)
        local hasRange = HasSpellRange(FindSpellBookSlotBySpellID(self.action_spell), "spell")
        if hasRange then
            return true
        else
            return false
        end
    end,
    GetSpellId = function(self) return self.action_spell end,
    GetCooldown = function(self) return GetSpellCooldown(self.action_spell) end,
    GetLossOfControlCooldown = function(self) return GetSpellLossOfControlCooldown(self.action_spell) end,
}
```

#### 3. Item Buttons (`type = "item"`)
**Purpose**: Buttons that use items by item ID

**Implementation**:
```lua
ItemTypeUpdateFunctions = {
    HasAction = function(self) return true end,
    GetActionText = function(self) return "" end,
    GetActionTexture = function(self) return GetItemIcon(self.action_item) end,
    GetActionCharges = function(self) return GetItemSpell(self.action_item) and GetItemCharges(self.action_item) end,
    GetActionCount = function(self) return GetItemCount(self.action_item, nil, true) end,
    IsAttackAction = function(self) return false end,
    IsEquippedAction = function(self) return IsEquippedItem(self.action_item) end,
    IsCurrentAction = function(self) return IsCurrentItem(self.action_item) end,
    IsAutoRepeatAction = function(self) return false end,
    IsUsableAction = function(self) return IsUsableItem(self.action_item) end,
    IsConsumableAction = function(self) return IsConsumableItem(self.action_item) end,
    IsInRange = function(self) return IsItemInRange(self.action_item, "target") end,
    HasRange = function(self) return ItemHasRange(self.action_item) end,
    GetSpellId = function(self) return nil end,
    GetCooldown = function(self) return GetItemCooldown(self.action_item) end,
    GetLossOfControlCooldown = function(self) return nil end,
}
```

#### 4. Macro Buttons (`type = "macro"`)
**Purpose**: Buttons that execute macros by macro index

**Implementation**:
```lua
MacroTypeUpdateFunctions = {
    HasAction = function(self) return true end,
    GetActionText = function(self) return (GetMacroInfo(self.action_macro)) end,
    GetActionTexture = function(self) return (select(2, GetMacroInfo(self.action_macro))) end,
    GetActionCharges = function(self) return nil end,
    GetActionCount = function(self) return 0 end,
    IsAttackAction = function(self) return false end,
    IsEquippedAction = function(self) return false end,
    IsCurrentAction = function(self) return false end,
    IsAutoRepeatAction = function(self) return false end,
    IsUsableAction = function(self) return true end,
    IsConsumableAction = function(self) return false end,
    IsInRange = function(self) return nil end,
    HasRange = function(self) return false end,
    GetSpellId = function(self) return nil end,
    GetCooldown = function(self) return 0, 0, 0 end,
    GetLossOfControlCooldown = function(self) return nil end,
}
```

#### 5. Custom Buttons (`type = "custom"`)
**Purpose**: Buttons with user-defined callback functions for all operations

**Implementation**:
```lua
-- User provides UpdateFunctions table with custom implementations
button:SetAttribute("type", type)
button:SetAttribute(type, action)
UpdateButtonState(button)
```

### LTAB Button Types

#### Current Implementation:
```lua
-- Only action type supported
function LAB:CreateButton(actionID, name, parent, config)
    local button = CreateFrame("CheckButton", name, parent,
        "ActionBarButtonTemplate, SecureActionButtonTemplate")

    button.id = actionID
    button.actionID = actionID
    -- ...
end

function LAB:SetupButtonAction(button, actionID)
    button:SetAttribute("type", "action")
    button:SetAttribute("action", actionID)
end
```

#### Missing:
- ❌ No spell button type
- ❌ No item button type
- ❌ No macro button type
- ❌ No custom button type with callbacks
- ❌ No type-specific update function tables
- ❌ No abstraction layer for different button behaviors

**Impact**: Can only use action slot buttons, cannot create standalone spell/item/macro buttons

---

## State Management System

### LAB-1.0 State System

#### Multi-State Support
**Purpose**: Allow buttons to show different actions based on character state (stance, form, stealth, etc.)

**Implementation**:
```lua
function Generic:SetState(state, kind, action)
    state = tostring(state or 0)

    if not state then
        self.state_types = nil
        self.state_actions = nil
        return
    end

    if not self.state_types then
        self.state_types = {}
    end
    if not self.state_actions then
        self.state_actions = {}
    end

    -- kind can be "action", "spell", "item", "macro", etc.
    self.state_types[state] = kind
    self.state_actions[state] = action

    if self.state_types[state] ~= kind or self.state_actions[state] ~= action then
        self.state_types[state] = kind
        self.state_actions[state] = action
        if state ~= tostring(self:GetAttribute("state")) then
            self:SetAttribute("state-"..state.."-type", kind)
            if kind == "action" or kind == "spell" or kind == "item" or kind == "macro" then
                self:SetAttribute("state-"..state.."-"..kind, action)
            end
        end
    end
end

function Generic:GetState(state)
    if not state then
        return self:GetAttribute("state")
    end

    state = tostring(state)
    return self.state_types and self.state_types[state], self.state_actions and self.state_actions[state]
end

function Generic:UpdateState(state)
    if state then
        self:SetAttribute("state", state)
    end
    UpdateButtonState(self)
end

function Generic:GetAction(state)
    if state then
        return self.state_types and self.state_types[tostring(state)] or "empty",
               self.state_actions and self.state_actions[tostring(state)]
    else
        state = self:GetAttribute("state") or 0
        return self.state_types and self.state_types[tostring(state)] or self._state_type or "empty",
               self.state_actions and self.state_actions[tostring(state)] or self._state_action
    end
end
```

#### State-Based Action Updates
```lua
function UpdateButtonState(self)
    local kind, action = self:GetAction()

    if kind == "empty" then
        self._state_type = "empty"
        self._state_action = 0
        self.action = 0
        self.action_spell = 0
        self.action_item = 0
        self.action_macro = 0
    elseif kind == "action" then
        self._state_type = "action"
        self._state_action = action
        self.action = action
        self.UpdateFunctions = ActionTypeUpdateFunctions
    elseif kind == "spell" then
        self._state_type = "spell"
        self._state_action = action
        self.action_spell = action
        self.UpdateFunctions = SpellTypeUpdateFunctions
    elseif kind == "item" then
        self._state_type = "item"
        self._state_action = action
        self.action_item = action
        self.UpdateFunctions = ItemTypeUpdateFunctions
    elseif kind == "macro" then
        self._state_type = "macro"
        self._state_action = action
        self.action_macro = action
        self.UpdateFunctions = MacroTypeUpdateFunctions
    end

    Update(self)
end
```

#### State Change Events
```lua
-- Handles ACTIONBAR_PAGE_CHANGED
function OnEvent(frame, event, ...)
    if event == "ACTIONBAR_PAGE_CHANGED" then
        for button in next, lib.buttonRegistry do
            if button._state_type == "action" then
                UpdateButtonState(button)
            end
        end
    end
    -- ...
end
```

### LTAB State System

#### Current Implementation:
```lua
-- No state system - only direct action binding
function LAB:SetupButtonAction(button, actionID)
    button:SetAttribute("type", "action")
    button:SetAttribute("action", actionID)
end

-- Single state stored
button._state = {
    hasAction = false,
    inRange = true,
    hasPower = true,
    usable = true,
    -- ...
}
```

#### Missing:
- ❌ No multi-state support
- ❌ No state type/action tables
- ❌ No SetState/GetState methods
- ❌ No UpdateState functionality
- ❌ No state-based action switching
- ❌ No secure state attributes
- ❌ No stance/form detection
- ❌ No page change handling

**Impact**: Buttons cannot change actions based on stance/form/page, severely limiting functionality for druids, warriors, rogues, etc.

---

## WoW Version Support

### LAB-1.0 Version Detection

#### API Level Detection
```lua
local WoWRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
local WoWClassic = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)
local WoWBCC = (WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC)
local WoWWrath = (WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC)
local WoWCata = (WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC)
```

#### Conditional Features
```lua
-- Overlay glow disabled on Classic
if WoWRetail then
    function lib.ShowOverlayGlow(self)
        -- Modern overlay glow
        if self.overlay then
            self.overlay:Show()
        end
    end
else
    -- Classic: no overlay glow
    function lib.ShowOverlayGlow(self) end
    function lib.HideOverlayGlow(self) end
end

-- Flyout handling differs
if WoWRetail then
    -- Use modern flyout API
    function UpdateFlyout(self)
        local flyoutID = self:GetAttribute("flyoutID")
        if flyoutID and flyoutID > 0 then
            -- Modern implementation
        end
    end
else
    -- Classic: limited flyout support
    function UpdateFlyout(self)
        -- Simplified or disabled
    end
end

-- Loss of Control cooldowns (Retail only)
if WoWRetail then
    Generic.GetLossOfControlCooldown = function(self)
        return self.UpdateFunctions.GetLossOfControlCooldown(self)
    end
else
    Generic.GetLossOfControlCooldown = function(self)
        return nil
    end
end

-- Spell activation overlays
if WoWRetail then
    lib.eventFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
    lib.eventFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
else
    -- Not available in Classic
end
```

#### API Compatibility Wrappers
```lua
-- Handle API differences
local GetActionCharges = GetActionCharges or function() return nil end
local GetActionLossOfControlCooldown = GetActionLossOfControlCooldown or function() return nil end
local GetSpellCharges = GetSpellCharges or function() return nil end
local GetSpellLossOfControlCooldown = GetSpellLossOfControlCooldown or function() return nil end

-- Spell book scanning differs
if WoWRetail then
    FindSpellBookSlotBySpellID = function(spellID)
        return FindSpellBookSlotBySpellID(spellID, false)
    end
else
    FindSpellBookSlotBySpellID = function(spellID)
        for i = 1, MAX_SKILLLINE_TABS do
            local name, texture, offset, numSpells = GetSpellTabInfo(i)
            if not name then break end
            for j = offset + 1, offset + numSpells do
                local spell = GetSpellBookItemName(j, BOOKTYPE_SPELL)
                if spell and GetSpellBookItemInfo(j, BOOKTYPE_SPELL) == spellID then
                    return j
                end
            end
        end
        return nil
    end
end
```

### LTAB Version Support

#### Current Implementation:
```lua
-- No version detection at all
local AddonName, ns = ...
-- Assumes single WoW version
```

#### Missing:
- ❌ No WoW_PROJECT_ID checking
- ❌ No version-specific feature flags
- ❌ No API compatibility wrappers
- ❌ No conditional event registration
- ❌ No conditional function definitions
- ❌ Unknown if code works on Classic/Retail/BCC/Wrath/Cata

**Impact**: Likely broken on Classic versions, untested compatibility, potential Lua errors on different WoW versions

---

## Visual Features & Effects

### LAB-1.0 Visual Systems

#### 1. Spell Activation Overlays (Proc Glows)

**Purpose**: Show glowing effects when spells proc or become available

**Implementation**:
```lua
-- Retail only
if WoWRetail then
    lib.eventFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
    lib.eventFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")

    function lib.ShowOverlayGlow(self)
        if self.overlay then
            self.overlay:Show()
        end
    end

    function lib.HideOverlayGlow(self)
        if self.overlay then
            self.overlay:Hide()
        end
    end

    function UpdateOverlayGlow(self)
        local spellID = self:GetSpellId()
        if spellID and IsSpellOverlayed(spellID) then
            lib.ShowOverlayGlow(self)
        else
            lib.HideOverlayGlow(self)
        end
    end

    -- Event handler
    if event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" then
        local spellID = ...
        for button in next, lib.buttonRegistry do
            if button:GetSpellId() == spellID then
                lib.ShowOverlayGlow(button)
            end
        end
    elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" then
        local spellID = ...
        for button in next, lib.buttonRegistry do
            if button:GetSpellId() == spellID then
                lib.HideOverlayGlow(button)
            end
        end
    end
end
```

#### 2. New Action Highlighting

**Purpose**: Show yellow glow on newly learned spells/abilities

**Implementation**:
```lua
function Generic:UpdateNewAction()
    if C_NewItems and C_NewItems.IsNewItem then
        local actionType, id = GetActionInfo(self.action)
        local isNew = false

        if actionType == "spell" then
            isNew = C_NewItems.IsNewItem(id, Enum.NewItemType.Spell)
        elseif actionType == "item" then
            isNew = C_NewItems.IsNewItem(id, Enum.NewItemType.Item)
        end

        if isNew then
            if not self.NewActionTexture then
                self.NewActionTexture = self:CreateTexture(nil, "OVERLAY")
                self.NewActionTexture:SetAtlas("bags-glow-white")
                self.NewActionTexture:SetBlendMode("ADD")
                self.NewActionTexture:SetAllPoints()
            end
            self.NewActionTexture:Show()
        else
            if self.NewActionTexture then
                self.NewActionTexture:Hide()
            end
        end
    end
end

-- Event handling
if event == "NEW_RECIPE_LEARNED" or event == "SPELL_UPDATE_ICON" then
    for button in next, lib.buttonRegistry do
        button:UpdateNewAction()
    end
end
```

#### 3. Equipped Item Border

**Purpose**: Show green border on buttons with equipped items

**Implementation**:
```lua
function UpdateUsable(self)
    local isUsable, notEnoughMana = self:IsUsableAction()
    local isEquipped = self:IsEquippedAction()

    if isEquipped then
        if self.Border and not self.config.hideElements.equipped then
            self.Border:SetVertexColor(0, 1.0, 0, 0.35)
            self.Border:Show()
        end
    else
        if self.Border then
            self.Border:Hide()
        end
    end

    -- ...
end
```

#### 4. Cooldown Edge Effects

**Purpose**: Show cooldown numbers and edge glow

**Implementation**:
```lua
function UpdateCooldown(self)
    local start, duration, enable, modRate = self:GetCooldown()

    if self._cooldown then
        if self.config.showCooldown then
            self._cooldown:Show()
            if enable == 1 then
                self._cooldown:SetCooldown(start, duration, modRate)
            else
                self._cooldown:Hide()
            end
        else
            self._cooldown:Hide()
        end

        -- Edge effects
        if self._cooldown.currentCooldownType == COOLDOWN_TYPE_LOSS_OF_CONTROL then
            self._cooldown:SetEdgeTexture("Interface\\Cooldown\\edge-LoC")
        else
            self._cooldown:SetEdgeTexture("Interface\\Cooldown\\edge")
        end

        -- Numbers
        if self.config.showCooldownNumbers then
            self._cooldown:SetHideCountdownNumbers(false)
        else
            self._cooldown:SetHideCountdownNumbers(true)
        end
    end
end
```

#### 5. Charge Cooldowns

**Purpose**: Show separate cooldown display for spell charges

**Implementation**:
```lua
function UpdateCount(self)
    if not self:HasAction() then
        self._count:SetText("")
        return
    end

    local charges, maxCharges, chargeStart, chargeDuration = self:GetActionCharges()

    if charges and maxCharges and maxCharges > 1 then
        -- Show charge count
        if self.config.showCount then
            self._count:SetText(charges)
        end

        -- Show charge cooldown on separate frame
        if self.chargeCooldown then
            if charges < maxCharges then
                self.chargeCooldown:SetCooldown(chargeStart, chargeDuration)
                self.chargeCooldown:Show()
            else
                self.chargeCooldown:Hide()
            end
        end
    else
        -- Regular count (item stacks, etc.)
        local count = self:GetActionCount()
        if count and count > 1 then
            self._count:SetText(count)
        else
            self._count:SetText("")
        end
    end
end
```

#### 6. Range Coloring Options

**Purpose**: Color button or hotkey text when out of range

**Implementation**:
```lua
function UpdateRangeIndicator(self)
    local inRange = self:IsInRange()
    local color = self.config.colors.range

    if self.config.outOfRangeColoring == "button" then
        -- Color entire button
        if inRange == false then
            self.icon:SetVertexColor(color.r, color.g, color.b)
        else
            self.icon:SetVertexColor(1.0, 1.0, 1.0)
        end
    elseif self.config.outOfRangeColoring == "hotkey" then
        -- Color only hotkey text
        if inRange == false then
            self._hotkey:SetVertexColor(color.r, color.g, color.b)
        else
            self._hotkey:SetVertexColor(1.0, 1.0, 1.0)
        end
    end
end
```

#### 7. Desaturation

**Purpose**: Gray out unusable actions

**Implementation**:
```lua
function UpdateUsable(self)
    local isUsable, notEnoughMana = self:IsUsableAction()

    if self.config.desaturateUnusable then
        if not isUsable then
            self.icon:SetDesaturated(true)
        else
            self.icon:SetDesaturated(false)
        end
    end

    -- ...
end
```

#### 8. Spell Cast Flash/VFX

**Purpose**: Show visual effects when spells are cast

**Implementation**:
```lua
function Generic:UpdateFlash()
    local isAttack = self:IsAttackAction()
    local isAutoRepeat = self:IsAutoRepeatAction()
    local isCurrent = self:IsCurrentAction()

    if (isAttack or isAutoRepeat) and isCurrent then
        if self._flash then
            self._flash:Show()
            -- Flash animation
            if not self.flashing then
                self.flashing = true
                ActionButton_StartFlash(self)
            end
        end
    else
        if self._flash then
            self._flash:Hide()
            if self.flashing then
                self.flashing = false
                ActionButton_StopFlash(self)
            end
        end
    end
end
```

#### 9. Assisted Combat Highlights (Retail)

**Purpose**: Show rotation helper highlights

**Implementation**:
```lua
if WoWRetail then
    function UpdateAssistedCombat(self)
        if self.AssistedCombatFrame then
            if IsPlayerInAssistedCombat() then
                local actionType, id = GetActionInfo(self.action)
                if actionType == "spell" then
                    local shouldHighlight = ShouldShowAssistedCombatHighlight(id)
                    if shouldHighlight then
                        self.AssistedCombatFrame:Show()
                    else
                        self.AssistedCombatFrame:Hide()
                    end
                end
            else
                self.AssistedCombatFrame:Hide()
            end
        end
    end
end
```

### LTAB Visual Systems

#### Current Implementation:
```lua
function LAB:UpdateRangeIndicator(button)
    if not button then return end

    local inRange = IsActionInRange(button.actionID)
    local color = button.config.colors and button.config.colors.range or { r = 1, g = 0, b = 0 }

    if inRange == false then
        -- Color icon only
        if button._icon then
            button._icon:SetVertexColor(color.r, color.g, color.b)
        end
    else
        if button._icon then
            button._icon:SetVertexColor(1.0, 1.0, 1.0)
        end
    end
end

function LAB:UpdateUsable(button)
    -- Similar basic implementation for power/usability
end

function LAB:UpdateCooldown(button)
    -- Basic cooldown with partial charge support
    local charges, maxCharges, chargeStart, chargeDuration
    if E.Compat and E.Compat.GetActionCharges then
        charges, maxCharges, chargeStart, chargeDuration = E.Compat.GetActionCharges(button.actionID)
    end

    -- No separate charge cooldown display
end
```

#### Missing:
- ❌ No spell activation overlay/proc glows
- ❌ No new action highlighting
- ❌ No equipped item borders
- ❌ No cooldown edge effects
- ❌ No separate charge cooldown frame
- ❌ No range coloring options (button vs hotkey)
- ❌ No desaturation support
- ❌ No spell cast flash/VFX
- ❌ No assisted combat highlights
- ❌ No LibButtonGlow integration

**Impact**: Buttons lack visual feedback and polish, poor user experience

---

## Interaction Systems

### LAB-1.0 Interaction Features

#### 1. Drag and Drop System

**Purpose**: Move abilities between buttons, pick up from cursor

**Implementation**:
```lua
function Generic:UpdateDragAndDrop()
    if InCombatLockdown() then return end

    if self.config.allowDragAndDrop then
        self:RegisterForDrag("LeftButton", "RightButton")
        self:SetScript("PreClick", Generic_PreClick)
        self:SetScript("PostClick", Generic_PostClick)
    else
        self:RegisterForDrag()
        self:SetScript("PreClick", nil)
        self:SetScript("PostClick", nil)
    end
end

function Generic:EnableDragNDrop(enable)
    if InCombatLockdown() then
        error("LibActionButton-1.0: You can only toggle DragNDrop out of combat!", 2)
    end

    if enable then
        self.config.allowDragAndDrop = true
    else
        self.config.allowDragAndDrop = false
    end

    self:UpdateDragAndDrop()
end

function Generic_PreClick(self, button)
    if self._state_type == "action" and InCombatLockdown() then
        return
    end

    -- Handle pickup from button
    if button == "LeftButton" and not IsModifiedClick() then
        if self.config.allowDragAndDrop then
            PickupAction(self.action)
        end
    end
end

function Generic_PostClick(self, button)
    if self._state_type == "action" then
        UpdateButtonState(self)
    end
end

-- Secure OnDragStart
function Generic:OnDragStart(button)
    if InCombatLockdown() then return end

    if self._state_type == "action" then
        PickupAction(self.action)
    elseif self._state_type == "spell" then
        PickupSpell(self.action_spell)
    elseif self._state_type == "item" then
        PickupItem(self.action_item)
    elseif self._state_type == "macro" then
        PickupMacro(self.action_macro)
    end
end

-- Secure OnReceiveDrag
function Generic:OnReceiveDrag()
    if InCombatLockdown() then return end

    if self._state_type == "action" then
        PlaceAction(self.action)
        UpdateButtonState(self)
    end
end
```

#### 2. Button Locking

**Purpose**: Prevent accidental changes to buttons

**Implementation**:
```lua
function Generic:SetLocked(locked)
    if InCombatLockdown() then return end

    self.config.locked = locked

    if locked then
        self:EnableDragNDrop(false)
    else
        self:EnableDragNDrop(true)
    end
end

function Generic:GetLocked()
    return self.config.locked
end
```

#### 3. Click Behavior Configuration

**Purpose**: Configure when button activates (down vs up)

**Implementation**:
```lua
function Generic:SetClickOnDown(clickOnDown)
    if InCombatLockdown() then return end

    self.config.clickOnDown = clickOnDown

    if clickOnDown then
        self:RegisterForClicks("AnyDown")
    else
        self:RegisterForClicks("AnyUp")
    end
end
```

#### 4. Keybinding Integration

**Purpose**: LibKeyBound integration for in-game keybinding

**Implementation**:
```lua
-- LibKeyBound support
Generic.GetBindingAction = function(self)
    return self.config.keyBoundTarget or "CLICK "..self:GetName()..":LeftButton"
end

Generic.GetActionName = function(self)
    local kind, action = self:GetAction()
    if kind == "spell" then
        local spellName = GetSpellInfo(action)
        return spellName
    elseif kind == "item" then
        local itemName = GetItemInfo(action)
        return itemName
    elseif kind == "macro" then
        local macroName = GetMacroInfo(action)
        return macroName
    end
    return nil
end

Generic.GetHotkey = function(self)
    local key = GetBindingKey(self:GetBindingAction())
    if key then
        return KeyBoundKeyName(key)
    end
    return ""
end

-- Register with LibKeyBound when available
if LibStub then
    local LKB = LibStub("LibKeyBound-1.0", true)
    if LKB then
        LKB:RegisterButton(Generic)
    end
end
```

#### 5. Cursor Pickup Handling

**Purpose**: Handle different cursor types (spell, item, macro, etc.)

**Implementation**:
```lua
function Generic:SetCursor()
    local kind, action = self:GetAction()

    if kind == "action" then
        return "action", action
    elseif kind == "spell" then
        return "spell", action
    elseif kind == "item" then
        return "item", action
    elseif kind == "macro" then
        return "macro", action
    end
end
```

### LTAB Interaction Systems

#### Current Implementation:
```lua
-- No drag and drop
-- No button locking
-- No click behavior config
-- No LibKeyBound integration
-- No cursor handling

-- Only basic secure attributes
function LAB:SetupButtonAction(button, actionID)
    button:SetAttribute("type", "action")
    button:SetAttribute("action", actionID)
end
```

#### Missing:
- ❌ No drag and drop support
- ❌ No OnDragStart/OnReceiveDrag handlers
- ❌ No button locking
- ❌ No click behavior configuration
- ❌ No LibKeyBound integration
- ❌ No cursor pickup handling
- ❌ No combat lockdown checks for secure operations

**Impact**: Cannot move abilities, cannot prevent accidental changes, no in-game keybinding

---

## Configuration & Customization

### LAB-1.0 Configuration System

#### Default Configuration
```lua
local DefaultConfig = {
    -- Visual elements
    showGrid = false,
    showCooldown = true,
    showCooldownNumbers = true,
    showCount = true,
    showHotkey = true,
    showTooltip = true,

    -- Text configuration
    hideElements = {
        macro = false,
        hotkey = false,
        equipped = false,
    },

    -- Coloring
    outOfRangeColoring = "button",  -- "button" or "hotkey"
    outOfManaColoring = "button",   -- "button" or "hotkey"
    desaturateUnusable = false,

    -- Colors
    colors = {
        range = { r = 0.8, g = 0.1, b = 0.1 },
        power = { r = 0.1, g = 0.3, b = 1.0 },
        usable = { r = 1.0, g = 1.0, b = 1.0 },
        unusable = { r = 0.4, g = 0.4, b = 0.4 },
    },

    -- Font configuration
    text = {
        hotkey = {
            font = "Fonts\\FRIZQT__.TTF",
            size = 12,
            flags = "OUTLINE",
            color = { r = 1, g = 1, b = 1, a = 1 },
            position = {
                anchor = "TOPRIGHT",
                relAnchor = "TOPRIGHT",
                offsetX = -2,
                offsetY = -2,
            },
            justifyH = "RIGHT",
        },
        count = {
            font = "Fonts\\FRIZQT__.TTF",
            size = 12,
            flags = "OUTLINE",
            color = { r = 1, g = 1, b = 1, a = 1 },
            position = {
                anchor = "BOTTOMRIGHT",
                relAnchor = "BOTTOMRIGHT",
                offsetX = -2,
                offsetY = 2,
            },
            justifyH = "RIGHT",
        },
        macro = {
            font = "Fonts\\FRIZQT__.TTF",
            size = 10,
            flags = "OUTLINE",
            color = { r = 1, g = 1, b = 1, a = 1 },
            position = {
                anchor = "BOTTOM",
                relAnchor = "BOTTOM",
                offsetX = 0,
                offsetY = 2,
            },
            justifyH = "CENTER",
        },
    },

    -- Interaction
    allowDragAndDrop = true,
    locked = false,
    clickOnDown = false,
    tooltip = "enabled",  -- "enabled", "disabled", "nocombat"

    -- Advanced
    keyBoundTarget = nil,
    keyBoundClickButton = "LeftButton",
    borderIfEmpty = false,

    -- Integration
    Masque = nil,
    ButtonFacade = nil,

    -- Assisted combat (Retail)
    assistedHighlight = true,

    -- Action button UI integration
    actionButtonUI = false,
}
```

#### Configuration Merging
```lua
function Generic:UpdateConfig(config)
    if not config then return end

    -- Deep merge
    for k, v in pairs(config) do
        if type(v) == "table" then
            if not self.config[k] then
                self.config[k] = {}
            end
            for sk, sv in pairs(v) do
                self.config[k][sk] = sv
            end
        else
            self.config[k] = v
        end
    end

    -- Apply changes
    self:UpdateUsable()
    self:UpdateCooldown()
    self:UpdateCount()
    self:UpdateHotkey()
    self:UpdateDragAndDrop()
    -- ...
end
```

#### Per-Element Show/Hide
```lua
function Generic:SetShowGrid(show)
    self.config.showGrid = show
    self:UpdateGrid()
end

function Generic:SetShowCooldown(show)
    self.config.showCooldown = show
    self:UpdateCooldown()
end

function Generic:SetShowCount(show)
    self.config.showCount = show
    self:UpdateCount()
end

function Generic:SetShowHotkey(show)
    self.config.showHotkey = show
    self:UpdateHotkey()
end

function Generic:SetShowTooltip(show)
    if show == "enabled" or show == true then
        self.config.tooltip = "enabled"
    elseif show == "disabled" or show == false then
        self.config.tooltip = "disabled"
    elseif show == "nocombat" then
        self.config.tooltip = "nocombat"
    end
end
```

### LTAB Configuration System

#### Current Implementation:
```lua
-- Minimal config in button creation
function LAB:StyleButton(button, config)
    if not button or not config then return end

    -- Text styling
    local textConfig = config.text or {}

    if textConfig.hotkey then
        self:ConfigureText(button._hotkey, textConfig.hotkey)
    end

    if textConfig.count then
        self:ConfigureText(button._count, textConfig.count)
    end

    if textConfig.macro then
        self:ConfigureText(button._name, textConfig.macro)
    end

    -- Colors
    button.config = config
end

-- No default config
-- No config merging
-- No per-element show/hide methods
```

#### Missing:
- ❌ No comprehensive default config
- ❌ No deep config merging
- ❌ No per-element show/hide methods
- ❌ No tooltip configuration
- ❌ No color scheme system
- ❌ No range/mana coloring options
- ❌ No desaturation config
- ❌ No text alignment (justifyH)
- ❌ No UpdateConfig method
- ❌ No integration configs (Masque, etc.)

**Impact**: Limited customization, manual config management required

---

## Integration & Extensibility

### LAB-1.0 Integration Systems

#### 1. CallbackHandler Integration

**Purpose**: Allow other addons to hook into button events

**Implementation**:
```lua
local CBH = LibStub("CallbackHandler-1.0")

-- Embed callbacks into library
lib.callbacks = lib.callbacks or CBH:New(lib)

-- Fire callbacks
lib.callbacks:Fire("OnButtonCreated", button)
lib.callbacks:Fire("OnButtonUpdate", button)
lib.callbacks:Fire("OnButtonContentsChanged", button, state)

-- Usage by other addons:
-- LibActionButton:RegisterCallback("OnButtonCreated", function(event, button)
--     -- Do something with new button
-- end)
```

#### Available Callbacks:
```lua
-- OnButtonCreated: Fired when new button is created
-- OnButtonUpdate: Fired when button updates
-- OnButtonContentsChanged: Fired when button action changes
-- OnButtonStateChanged: Fired when button state changes
-- OnButtonEnter: Fired on mouse enter
-- OnButtonLeave: Fired on mouse leave
```

#### 2. Masque Support

**Purpose**: Allow Masque addon to skin buttons

**Implementation**:
```lua
function Generic:AddToMasque(group)
    if not Masque then return end

    self.MasqueGroup = group

    local buttonData = {
        Button = self,
        Icon = self._icon,
        Cooldown = self._cooldown,
        Count = self._count,
        HotKey = self._hotkey,
        Name = self._name,
        Border = self._border,
        Flash = self._flash,
        Normal = self._normalTexture,
        Pushed = self._pushedTexture,
        Checked = self:GetCheckedTexture(),
        Highlight = self._highlight,
    }

    group:AddButton(self, buttonData)

    -- Update texture management to work with Masque
    self.config.Masque = group
end

function UpdateIcon(self)
    local texture = self:GetActionTexture()

    if texture then
        self._icon:SetTexture(texture)
        self._icon:Show()

        -- Masque integration
        if self.config.Masque then
            -- Let Masque handle icon texture
            self.config.Masque:ReSkin()
        end
    else
        self._icon:Hide()
    end
end
```

#### 3. ButtonFacade Support (Legacy)

**Purpose**: Backward compatibility with older ButtonFacade addon

**Implementation**:
```lua
function Generic:AddToButtonFacade(group)
    if not ButtonFacade then return end

    self.LBFGroup = group

    local buttonData = {
        Icon = self._icon,
        Cooldown = self._cooldown,
        Count = self._count,
        HotKey = self._hotkey,
        Name = self._name,
        Border = self._border,
        -- ...
    }

    group:AddButton(self, buttonData)
    self.config.ButtonFacade = group
end
```

#### 4. LibKeyBound Integration

**Purpose**: In-game keybinding interface

**Implementation**:
```lua
Generic.GetBindingAction = function(self)
    return self.config.keyBoundTarget or "CLICK "..self:GetName()..":LeftButton"
end

Generic.GetActionName = function(self)
    local kind, action = self:GetAction()
    if kind == "spell" then
        return GetSpellInfo(action)
    elseif kind == "item" then
        return GetItemInfo(action)
    elseif kind == "macro" then
        return GetMacroInfo(action)
    end
    return nil
end

Generic.GetHotkey = function(self)
    local key = GetBindingKey(self:GetBindingAction())
    return key and KeyBoundKeyName(key) or ""
end

-- Auto-register with LibKeyBound
if LibStub then
    local LKB = LibStub("LibKeyBound-1.0", true)
    if LKB then
        LKB:RegisterButton(Generic)
    end
end
```

#### 5. Action Button UI Registration (Retail)

**Purpose**: Register buttons with Blizzard's action button system

**Implementation**:
```lua
if WoWRetail and C_ActionBar then
    function Generic:RegisterWithActionButtonUI()
        if self.config.actionButtonUI and self._state_type == "action" then
            C_ActionBar.SetActionButtonUI(self.action, self)
        end
    end
end
```

#### 6. Assisted Combat Integration (Retail)

**Purpose**: Integrate with rotation helper system

**Implementation**:
```lua
if WoWRetail then
    function Generic:UpdateAssistedCombat()
        if not self.config.assistedHighlight then return end

        if self.AssistedCombatFrame then
            if IsPlayerInAssistedCombat() then
                local actionType, id = GetActionInfo(self.action)
                if actionType == "spell" then
                    if ShouldShowAssistedCombatHighlight(id) then
                        self.AssistedCombatFrame:Show()
                    else
                        self.AssistedCombatFrame:Hide()
                    end
                end
            else
                self.AssistedCombatFrame:Hide()
            end
        end
    end

    lib.eventFrame:RegisterEvent("ASSISTED_COMBAT_UPDATE")
end
```

### LTAB Integration Systems

#### Current Implementation:
```lua
-- No callback system
-- No Masque support
-- No ButtonFacade support
-- No LibKeyBound integration
-- No action button UI registration
-- No assisted combat integration

-- Only stored in TotalUI namespace
E.Libs.LibTotalActionButtons = LAB
```

#### Missing:
- ❌ No CallbackHandler integration
- ❌ No callback firing
- ❌ No Masque support
- ❌ No ButtonFacade support
- ❌ No LibKeyBound integration
- ❌ No action button UI registration
- ❌ No assisted combat integration
- ❌ Cannot be used by other addons

**Impact**: Not extensible, cannot be used by other addons, no skinning support

---

## Performance & Optimization

### LAB-1.0 Optimization Techniques

#### 1. Batch Updates

**Purpose**: Update multiple buttons efficiently

**Implementation**:
```lua
-- Update all buttons with function
function lib:ForAllButtons(func, ...)
    if type(func) ~= "function" then return end

    for button in next, lib.buttonRegistry do
        func(button, ...)
    end
end

-- Targeted updates by spell
function lib:ForAllButtonsWithSpell(spell, func, ...)
    if type(func) ~= "function" then return end

    for button in next, lib.buttonRegistry do
        if button:GetSpellId() == spell then
            func(button, ...)
        end
    end
end

-- Usage:
lib:ForAllButtons(UpdateCount)
lib:ForAllButtonsWithSpell(spellID, UpdateOverlayGlow)
```

#### 2. Throttled Range Updates

**Purpose**: Don't update range indicator every frame

**Implementation**:
```lua
local rangeTimer = 0
local RANGE_INDICATOR_UPDATE_INTERVAL = 0.2

lib.eventFrame:SetScript("OnUpdate", function(self, elapsed)
    rangeTimer = rangeTimer + elapsed

    if rangeTimer >= RANGE_INDICATOR_UPDATE_INTERVAL then
        for button in next, lib.ActiveButtons do
            UpdateRangeIndicator(button)
        end
        rangeTimer = 0
    end
end)
```

#### 3. Active Button Tracking

**Purpose**: Only update buttons that have actions

**Implementation**:
```lua
function lib:RegisterButton(button)
    lib.buttonRegistry[button] = true
    lib.numButtons = lib.numButtons + 1

    if button:HasAction() then
        lib.ActiveButtons[button] = true

        if button._state_type == "action" then
            lib.actionButtons[button] = true
        else
            lib.nonActionButtons[button] = true
        end
    end
end

-- Event handling only updates active buttons
function OnEvent(frame, event, ...)
    if event == "SPELL_UPDATE_COOLDOWN" then
        for button in next, lib.ActiveButtons do
            UpdateCooldown(button)
        end
    end
end
```

#### 4. Efficient Event Registration

**Purpose**: Only register events that are needed

**Implementation**:
```lua
-- Register events on library event frame
lib.eventFrame = lib.eventFrame or CreateFrame("Frame")

local events = {
    "ACTIONBAR_SLOT_CHANGED",
    "SPELL_UPDATE_COOLDOWN",
    "SPELL_UPDATE_CHARGES",
    "UPDATE_BINDINGS",
    -- Only register version-specific events
}

if WoWRetail then
    table.insert(events, "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
    table.insert(events, "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
    table.insert(events, "ASSISTED_COMBAT_UPDATE")
end

for _, event in ipairs(events) do
    lib.eventFrame:RegisterEvent(event)
end
```

#### 5. Lazy Initialization

**Purpose**: Don't create elements until needed

**Implementation**:
```lua
function UpdateOverlayGlow(self)
    if not self.overlay then
        -- Create overlay only when needed
        self.overlay = CreateFrame("Frame", nil, self, "ActionBarButtonSpellActivationAlert")
        self.overlay:SetAllPoints()
        self.overlay:Hide()
    end

    -- Use overlay
end
```

#### 6. Memory Pooling (Flyouts)

**Purpose**: Reuse flyout buttons instead of creating new ones

**Implementation**:
```lua
lib.FlyoutButtons = lib.FlyoutButtons or {}

function GetFlyoutButton(index)
    if not lib.FlyoutButtons[index] then
        local button = CreateFrame("CheckButton", "LAB_FlyoutButton"..index, UIParent, "ActionBarFlyoutButtonTemplate")
        lib.FlyoutButtons[index] = button
    end

    return lib.FlyoutButtons[index]
end
```

### LTAB Optimization

#### Current Implementation:
```lua
-- Individual button updates only
function LAB:UpdateButton(button)
    if not button then return end

    self:UpdateIcon(button)
    self:UpdateCount(button)
    self:UpdateCooldown(button)
    self:UpdateUsable(button)
    self:UpdateRangeIndicator(button)
    self:UpdateHotkey(button)
end

-- Individual event handlers on each button
button:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
button:RegisterEvent("SPELL_UPDATE_COOLDOWN")
-- ... etc
```

#### Missing:
- ❌ No batch update functions
- ❌ No targeted updates by spell
- ❌ No range update throttling (updates every frame)
- ❌ No active button tracking
- ❌ No centralized event frame
- ❌ No lazy initialization
- ❌ No object pooling
- ❌ Each button registers events individually (inefficient)

**Impact**: Higher CPU usage, more memory, slower performance with many buttons

---

## Error Handling & Validation

### LAB-1.0 Error Handling

#### 1. Library Loading Validation
```lua
local MAJOR_VERSION = "LibActionButton-1.0"
local MINOR_VERSION = 94

if not LibStub then
    error(MAJOR_VERSION .. " requires LibStub.", 2)
end

local lib, oldversion = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if not lib then return end  -- Already loaded newer version

if not CallbackHandler then
    error(MAJOR_VERSION .. " requires CallbackHandler-1.0.", 2)
end
```

#### 2. Parameter Validation
```lua
function lib:CreateButton(id, name, parent, config)
    if type(id) ~= "number" and type(id) ~= "string" then
        error("Usage: CreateButton(id, name, parent): 'id' must be a number or string!", 2)
    end

    if type(name) ~= "string" or name == "" then
        error("Usage: CreateButton(id, name, parent): 'name' must be a valid string!", 2)
    end

    if parent and type(parent) ~= "table" then
        error("Usage: CreateButton(id, name, parent): 'parent' must be a frame!", 2)
    end

    -- ...
end
```

#### 3. Combat Lockdown Checks
```lua
function Generic:EnableDragNDrop(enable)
    if InCombatLockdown() then
        error("LibActionButton-1.0: You can only toggle DragNDrop out of combat!", 2)
    end
    -- ...
end

function Generic:SetState(state, kind, action)
    if InCombatLockdown() then
        error("LibActionButton-1.0: Cannot change button state during combat!", 2)
    end
    -- ...
end
```

#### 4. Protected API Calls
```lua
function UpdateFlyout(self)
    local flyoutID = self:GetAttribute("flyoutID")
    if flyoutID and flyoutID > 0 then
        -- Use pcall to safely call API that might error
        local success, _, _, numSlots, isKnown = pcall(GetFlyoutInfo, flyoutID)
        if success and numSlots and numSlots > 0 then
            -- Process flyout
        else
            -- Handle error gracefully
            self.FlyoutBorder:Hide()
            self.FlyoutArrow:Hide()
        end
    end
end
```

#### 5. Type Assertions
```lua
function Generic:UpdateConfig(config)
    assert(type(config) == "table", "UpdateConfig: config must be a table")

    for k, v in pairs(config) do
        if k == "text" then
            assert(type(v) == "table", "UpdateConfig: text config must be a table")
        elseif k == "colors" then
            assert(type(v) == "table", "UpdateConfig: colors must be a table")
        end
    end

    -- ...
end
```

#### 6. Graceful Degradation
```lua
function UpdateIcon(self)
    local texture = self:GetActionTexture()

    if self._icon then
        if texture then
            self._icon:SetTexture(texture)
            self._icon:Show()
        else
            self._icon:SetTexture(nil)
            self._icon:Hide()
        end
    else
        -- Icon reference missing, log warning
        if lib.debug then
            print("LibActionButton: Warning - Button missing icon element:", self:GetName())
        end
    end
end
```

#### 7. Debug Mode
```lua
lib.debug = false

function lib:SetDebug(enabled)
    self.debug = enabled
end

function DebugPrint(...)
    if lib.debug then
        print("|cffff0000LibActionButton Debug:|r", ...)
    end
end
```

### LTAB Error Handling

#### Current Implementation:
```lua
-- Load-time namespace check
if not ns or not ns.public then
    error("LibTotalActionButtons: Namespace not initialized!")
    return
end

-- Nil checks with silent returns
function LAB:UpdateButton(button)
    if not button then return end
    -- ...
end

function LAB:SetButtonSize(button, width, height)
    if not button then return end
    -- ...
end

-- No parameter validation
-- No combat lockdown checks
-- No protected calls
-- No type assertions
-- No debug mode
```

#### Missing:
- ❌ No parameter type validation
- ❌ No parameter value validation
- ❌ No error messages for invalid input
- ❌ No combat lockdown checks
- ❌ No protected API calls
- ❌ No type assertions
- ❌ No graceful degradation
- ❌ No debug mode
- ❌ No LibStub version checking
- ⚠️ Silent failures make debugging difficult

**Impact**: Hard to debug issues, potential taint, unclear error messages for users

---

## Critical Bugs in Current Implementation

### Bug 1: Template String Issue

**Location**: Line 83-84

**Current Code**:
```lua
local button = CreateFrame("CheckButton", name, parent,
    "ActionBarButtonTemplate, SecureActionButtonTemplate")
```

**Problem**: The template parameter should be multiple separate templates, not a comma-separated string.

**Correct Code**:
```lua
local button = CreateFrame("CheckButton", name, parent, "ActionBarButtonTemplate")
SecureHandlerSetFrameRef(button, "SecureActionButtonTemplate")
-- OR use proper multi-template syntax if supported
```

**Impact**: May cause template inheritance issues, button may not have all expected elements

---

### Bug 2: Unvalidated Compat API Usage

**Location**: Lines 420-429

**Current Code**:
```lua
if E.Compat and E.Compat.GetActionCharges then
    charges, maxCharges, chargeStart, chargeDuration = E.Compat.GetActionCharges(button.actionID)
end

if charges and maxCharges and maxCharges > 1 then
    -- Use charges
end
```

**Problem**: No validation that E.Compat.GetActionCharges returns valid data types

**Potential Fix**:
```lua
if E.Compat and E.Compat.GetActionCharges then
    local c, mc, cs, cd = E.Compat.GetActionCharges(button.actionID)
    if type(c) == "number" and type(mc) == "number" and type(cs) == "number" and type(cd) == "number" then
        charges, maxCharges, chargeStart, chargeDuration = c, mc, cs, cd
    end
end
```

**Impact**: Could cause Lua errors if compat API returns unexpected values

---

### Bug 3: No OnEvent Error Handling

**Location**: Lines 140-175 (event handler)

**Current Code**:
```lua
button:SetScript("OnEvent", function(self, event, ...)
    if event == "ACTIONBAR_SLOT_CHANGED" then
        local slot = ...
        if slot == self.actionID then
            LAB:UpdateButton(self)
        end
    elseif event == "SPELL_UPDATE_COOLDOWN" then
        LAB:UpdateCooldown(self)
    -- ... more events
end)
```

**Problem**: If any update function errors, the entire event handler fails

**Potential Fix**:
```lua
button:SetScript("OnEvent", function(self, event, ...)
    local success, err = pcall(function()
        if event == "ACTIONBAR_SLOT_CHANGED" then
            -- ...
        end
    end)

    if not success and LAB.debug then
        print("LibTotalActionButtons: Error in event handler:", err)
    end
end)
```

**Impact**: One broken button update can break event handling for that button

---

### Bug 4: Missing Grid System

**Location**: Throughout

**Problem**: Grid mode (showing empty buttons) is partially implemented but incomplete

**Current Code**:
```lua
-- In UpdateIcon
if not texture then
    if button.config and button.config.showGrid then
        button._icon:SetTexture("Interface\\Buttons\\UI-Quickslot")
        button._icon:Show()
    else
        button._icon:Hide()
    end
end
```

**Missing**:
- No global grid counter
- No ShowGrid()/HideGrid() functions
- No grid state tracking
- Individual button grid config only

**Impact**: Cannot properly implement action bar grid mode

---

### Bug 5: Pushed Texture Misalignment

**Location**: Lines 208-212

**Current Code**:
```lua
if button._pushedTexture then
    button._pushedTexture:ClearAllPoints()
    button._pushedTexture:SetAllPoints(button)
end
```

**Problem**: User reported pushed texture is still off-center (from previous session)

**Potential Issue**:
- Pushed texture might need different anchoring
- Template may be setting pushed texture differently
- Needs investigation

**Impact**: Visual misalignment when clicking buttons

---

## Development Roadmap

### Phase 1: Critical Foundation (1-2 weeks)

**Priority: CRITICAL**

#### 1.1 Fix Critical Bugs
- [ ] Fix CreateFrame template string issue
- [ ] Add error handling to event handlers
- [ ] Validate compat API returns
- [ ] Debug and fix pushed texture alignment

#### 1.2 Add WoW Version Support
- [ ] Add WoW_PROJECT_ID detection
- [ ] Create version flags (WoWRetail, WoWClassic, etc.)
- [ ] Add API compatibility wrappers
- [ ] Test on Retail and Classic

#### 1.3 Implement Error Handling
- [ ] Add parameter validation to all public methods
- [ ] Add combat lockdown checks
- [ ] Add protected calls for fallible APIs
- [ ] Add debug mode and logging
- [ ] Add graceful error messages

#### 1.4 LibStub Integration
- [ ] Convert to LibStub library format
- [ ] Add MAJOR/MINOR version system
- [ ] Add upgrade path handling
- [ ] Test with other LibStub libraries

**Deliverable**: Stable, version-aware library with proper error handling

---

### Phase 2: Core Functionality (2-3 weeks)

**Priority: HIGH**

#### 2.1 Button Type System
- [ ] Implement spell button type
- [ ] Implement item button type
- [ ] Implement macro button type
- [ ] Implement custom button type
- [ ] Create type-specific UpdateFunctions tables
- [ ] Add type abstraction layer

#### 2.2 State Management
- [ ] Implement SetState/GetState methods
- [ ] Add state type/action tables
- [ ] Add UpdateState functionality
- [ ] Add secure state attributes
- [ ] Implement page change handling
- [ ] Add ACTIONBAR_PAGE_CHANGED event

#### 2.3 Configuration System
- [ ] Create comprehensive default config
- [ ] Implement deep config merging
- [ ] Add per-element show/hide methods
- [ ] Add UpdateConfig method
- [ ] Add tooltip configuration
- [ ] Add color scheme system

**Deliverable**: Multi-type buttons with state management and robust configuration

---

### Phase 3: Visual Polish (2-3 weeks)

**Priority: MEDIUM-HIGH**

#### 3.1 Advanced Cooldowns
- [ ] Create separate charge cooldown frame
- [ ] Implement charge cooldown display
- [ ] Add loss of control cooldowns (Retail)
- [ ] Add cooldown edge effects
- [ ] Add cooldown number configuration

#### 3.2 Visual Effects
- [ ] Implement spell activation overlays (Retail)
- [ ] Add LibButtonGlow integration
- [ ] Add new action highlighting
- [ ] Add equipped item borders
- [ ] Add desaturation support
- [ ] Implement spell cast flash/VFX

#### 3.3 Range/Usability Enhancements
- [ ] Add range coloring options (button vs hotkey)
- [ ] Add mana coloring options (button vs hotkey)
- [ ] Improve color customization
- [ ] Add color state transitions

**Deliverable**: Polished visual feedback matching modern action bars

---

### Phase 4: Interaction Systems (1-2 weeks)

**Priority: MEDIUM**

#### 4.1 Drag and Drop
- [ ] Implement secure OnDragStart handler
- [ ] Implement secure OnReceiveDrag handler
- [ ] Add PreClick/PostClick scripts
- [ ] Add combat lockdown handling
- [ ] Add cursor pickup handling
- [ ] Test all button types

#### 4.2 Button Locking
- [ ] Implement SetLocked/GetLocked
- [ ] Add lock integration with drag/drop
- [ ] Add visual lock indicator (optional)

#### 4.3 Click Behavior
- [ ] Add SetClickOnDown configuration
- [ ] Add click registration management
- [ ] Test click responsiveness

**Deliverable**: Full drag/drop support and click customization

---

### Phase 5: Integration & Extensibility (2-3 weeks)

**Priority: MEDIUM**

#### 5.1 Callback System
- [ ] Integrate CallbackHandler-1.0
- [ ] Implement OnButtonCreated callback
- [ ] Implement OnButtonUpdate callback
- [ ] Implement OnButtonContentsChanged callback
- [ ] Implement OnButtonStateChanged callback
- [ ] Add callback documentation

#### 5.2 Masque Support
- [ ] Implement AddToMasque method
- [ ] Create button data structure for Masque
- [ ] Test with Masque addon
- [ ] Handle Masque texture updates

#### 5.3 LibKeyBound Integration
- [ ] Implement GetBindingAction method
- [ ] Implement GetActionName method
- [ ] Implement GetHotkey method
- [ ] Register with LibKeyBound
- [ ] Test in-game keybinding

#### 5.4 Retail Integrations
- [ ] Add action button UI registration
- [ ] Add assisted combat integration
- [ ] Test rotation helper highlights

**Deliverable**: Extensible library that works with popular addons

---

### Phase 6: Performance & Optimization (1 week)

**Priority: MEDIUM-LOW**

#### 6.1 Event Optimization
- [ ] Create centralized event frame
- [ ] Move event registration to library level
- [ ] Implement event routing to buttons
- [ ] Reduce per-button event overhead

#### 6.2 Update Optimization
- [ ] Implement ForAllButtons batch updates
- [ ] Implement ForAllButtonsWithSpell targeted updates
- [ ] Add range update throttling
- [ ] Implement active button tracking
- [ ] Add lazy initialization for optional elements

#### 6.3 Memory Optimization
- [ ] Implement object pooling for flyouts
- [ ] Optimize button registry
- [ ] Profile memory usage
- [ ] Reduce unnecessary allocations

**Deliverable**: Optimized performance with many buttons

---

### Phase 7: Advanced Features (2-3 weeks)

**Priority: LOW**

#### 7.1 Flyout System
- [ ] Implement flyout menu handling
- [ ] Create flyout button pool
- [ ] Add flyout direction configuration
- [ ] Add Retail flyout support
- [ ] Add Classic fallback
- [ ] Test with multi-spell abilities

#### 7.2 Grid System
- [ ] Implement global grid counter
- [ ] Add ShowGrid/HideGrid functions
- [ ] Add grid state tracking
- [ ] Add pet grid mode
- [ ] Integrate with button visibility

#### 7.3 Tooltip Enhancements
- [ ] Add combat-aware tooltips
- [ ] Add tooltip show conditions
- [ ] Add custom tooltip callbacks

**Deliverable**: Complete feature parity with LibActionButton-1.0

---

### Phase 8: Testing & Documentation (1-2 weeks)

**Priority: ONGOING**

#### 8.1 Comprehensive Testing
- [ ] Test all button types
- [ ] Test all states
- [ ] Test on Retail
- [ ] Test on Classic Era
- [ ] Test on Wrath Classic
- [ ] Test on Cataclysm Classic
- [ ] Test with Masque
- [ ] Test with LibKeyBound
- [ ] Load testing (100+ buttons)
- [ ] Combat lockdown testing

#### 8.2 Documentation
- [ ] API documentation
- [ ] Configuration guide
- [ ] Integration guide (for other addons)
- [ ] Migration guide from LibActionButton-1.0
- [ ] Example usage code
- [ ] Performance best practices

#### 8.3 Code Quality
- [ ] Code review
- [ ] Refactoring pass
- [ ] Comment cleanup
- [ ] Style consistency
- [ ] Memory leak checks

**Deliverable**: Production-ready library with full documentation

---

## Estimated Total Time

### By Priority:
- **Critical (Phase 1)**: 1-2 weeks
- **High (Phase 2)**: 2-3 weeks
- **Medium-High (Phase 3)**: 2-3 weeks
- **Medium (Phases 4-5)**: 3-5 weeks
- **Medium-Low (Phase 6)**: 1 week
- **Low (Phase 7)**: 2-3 weeks
- **Ongoing (Phase 8)**: 1-2 weeks throughout

### Total Estimate: 12-19 weeks (3-5 months)

---

## Recommended Approach

Given the scope, I recommend:

### Option A: Phased Development
1. Complete Phase 1 (Critical) immediately
2. Complete Phase 2 (Core Functionality)
3. Integrate into TotalUI and test with real usage
4. Continue with Phases 3-8 based on user feedback

### Option B: Hybrid Approach
1. Use LibActionButton-1.0 for now
2. Complete Phase 1 (Critical) for LibTotalActionButtons
3. Gradually implement Phases 2-7 alongside TotalUI development
4. Switch to LibTotalActionButtons when at feature parity
5. This allows TotalUI progress while building custom library

### Option C: Minimal Viable Enhancement
1. Complete Phase 1 (Critical)
2. Complete Phase 2.1 only (button types)
3. Add just enough Phase 3 for acceptable visuals
4. Ship with limited but working feature set
5. Enhance based on user requests

---

## Conclusion

LibTotalActionButtons is currently a **proof-of-concept** with basic functionality. To reach production quality, it needs:

1. **Critical fixes** (bugs, version support, error handling)
2. **Core features** (multi-type buttons, state system, config)
3. **Visual polish** (overlays, highlights, cooldowns)
4. **Interaction** (drag/drop, locking)
5. **Integration** (callbacks, Masque, LibKeyBound)
6. **Optimization** (performance, memory)
7. **Advanced features** (flyouts, grid, tooltips)

This represents **approximately 3-5 months of focused development** to achieve full feature parity with LibActionButton-1.0.

**My recommendation**: Start with Phase 1 (1-2 weeks) to fix critical issues and add version support, then evaluate whether to continue custom development or use LibActionButton-1.0 while building out other TotalUI modules.

---

# Appendix A: Blizzard Action Button API Analysis

## Executive Summary

This appendix analyzes Blizzard's native Action Button UI APIs to identify additional customization opportunities beyond what LibActionButton-1.0 provides. The goal is to ensure LibTotalActionButtons leverages all available Blizzard APIs for maximum functionality and visual polish.

### Key Findings:
- **40+ Blizzard APIs** related to action buttons
- **10 major visual systems** available (overlays, highlights, animations, etc.)
- **Retail has 15+ exclusive APIs** not available in Classic
- **Critical gaps**: Spell overlays, charge cooldowns, LoC cooldowns, new action highlights
- **Estimated effort**: 2-3 weeks to implement all Blizzard API enhancements

---

## 1. Core Action Button APIs (All Versions)

### Basic Action Queries

#### Standard Functions
```lua
-- Action existence and info
HasAction(slot) → boolean
GetActionInfo(slot) → actionType, id, subType
    -- actionType: "spell", "item", "macro", "companion", "equipmentset", etc.
    -- id: spell ID, item ID, macro index, etc.
    -- subType: usually nil, sometimes used for specific types

GetActionTexture(slot) → texturePath or itemID
GetActionText(slot) → text  -- Macro name or item name
GetActionCount(slot) → count  -- Item/reagent stack count
```

#### Cooldown APIs
```lua
GetActionCooldown(slot) → start, duration, enable, modRate
    -- start: GetTime() when cooldown started
    -- duration: cooldown length in seconds
    -- enable: 1 if cooldown is active, 0 if not
    -- modRate: cooldown rate modifier (haste, etc.)

-- Retail 6.2+
GetActionCharges(slot) → charges, maxCharges, cooldownStart, cooldownDuration, chargeModRate
    -- Returns nil if action doesn't have charges
    -- Example: Fire Blast (2 charges), Roll (2 charges)

-- Retail 5.1+
GetActionLossOfControlCooldown(slot) → start, duration
    -- Returns cooldown from loss of control effects (silence, stun, etc.)
    -- Different from normal cooldown - should be displayed separately
```

#### State Checking
```lua
IsActionInRange(slot, unit) → inRange
    -- Returns: 1 (in range), 0 (out of range), nil (no range requirement)
    -- unit parameter optional, defaults to "target"

IsUsableAction(slot) → isUsable, notEnoughPower
    -- isUsable: true if action can be used
    -- notEnoughPower: true if unusable due to mana/rage/energy/etc.

IsCurrentAction(slot) → boolean
    -- True if action is actively being used (channeling, auto-attack, etc.)

IsAutoRepeatAction(slot) → boolean
    -- True if action is auto-repeating (auto-attack, shoot)

IsAttackAction(slot) → boolean
    -- True if action is an attack (for flash animation)

IsEquippedAction(slot) → boolean
    -- True if action's item is currently equipped

IsConsumableAction(slot) → boolean
    -- True if action consumes items/reagents

IsStackableAction(slot) → boolean
    -- True if action has stackable count

IsItemAction(slot) → boolean
    -- True if action is an item
```

#### Action Manipulation (Protected - Cannot use in combat)
```lua
PickupAction(slot)
    -- Picks up action onto cursor
    -- Protected: Cannot call in combat

PlaceAction(slot)
    -- Places cursor action into slot
    -- Protected: Cannot call in combat

UseAction(slot, unit, button)
    -- Executes the action
    -- Protected: Combat restrictions apply
```

### Currently Used in LibTotalActionButtons

**From LibTotalActionButtons.lua (lines 420-505):**
```lua
-- Basic queries
HasAction(actionID)
GetActionTexture(actionID)
GetActionCount(actionID)
GetActionCooldown(actionID)

-- State checks
IsActionInRange(actionID)
IsUsableAction(actionID)
IsCurrentAction(actionID)
IsAutoRepeatAction(actionID)

-- Partial charge support
if E.Compat and E.Compat.GetActionCharges then
    charges, maxCharges, chargeStart, chargeDuration = E.Compat.GetActionCharges(actionID)
end
```

### Missing APIs from Core Set

**Not Currently Used:**
- `GetActionInfo()` - Could be used for better type detection
- `GetActionText()` - Could show macro names
- `IsEquippedAction()` - For equipped item borders (green glow)
- `IsConsumableAction()` - Could affect visual styling
- `IsStackableAction()` - For count display logic
- `IsItemAction()` - For item-specific styling
- `GetActionLossOfControlCooldown()` - **Critical missing feature**

---

## 2. Modern Retail C_ActionBar API

### Available in Retail Only

**Namespace:** `C_ActionBar.*`

#### Action Bar State Management
```lua
C_ActionBar.IsAssistedCombatAction(slot) → boolean
    -- Returns true if action is part of assisted combat rotation helper
    -- Used for highlighting abilities in single-button rotation mode
    -- Retail recent expansion feature

C_ActionBar.GetItemActionOnEquipSpellID(slot) → spellID
    -- Returns passive spell ID for equipped items
    -- Example: Trinket on-equip effects

C_ActionBar.SetActionUIButton(slot, button, cooldownFrame)
    -- Registers button with Blizzard's action button tracking system
    -- Allows Blizzard UI to manage your custom buttons
    -- Retail integration feature
```

#### Possible Additional C_ActionBar Functions

**Note:** These likely exist but aren't documented in our search results:
```lua
C_ActionBar.GetBonusBarOffset() → offset
    -- Gets bonus bar page offset (stance bar, possess bar, etc.)

C_ActionBar.GetActionBarToggles() → toggles
    -- Gets which action bars are currently visible

C_ActionBar.HasAction(slot) → boolean
    -- Alternative to global HasAction()
```

### Currently Used in LibTotalActionButtons

**None** - No C_ActionBar APIs are currently used

### Missing Retail APIs

**High Priority:**
- `C_ActionBar.IsAssistedCombatAction()` - For assisted combat highlights
- `C_ActionBar.SetActionUIButton()` - For Blizzard UI integration

**Medium Priority:**
- `C_ActionBar.GetItemActionOnEquipSpellID()` - For passive spell tracking

---

## 3. Spell Overlay System (Retail)

### Purpose
Show glowing proc effects when abilities light up (reactive abilities, procs, etc.)

### APIs

#### C_SpellActivationOverlay Namespace (Modern)
```lua
C_SpellActivationOverlay.IsSpellOverlayed(spellID) → boolean
    -- Returns true if spell is currently proc'ing
    -- Used to show/hide overlay glow
```

#### Legacy API (Older Retail)
```lua
IsSpellOverlayed(spellID) → boolean
    -- Same as C_SpellActivationOverlay version
    -- Still works in modern Retail
```

#### Events
```lua
SPELL_ACTIVATION_OVERLAY_GLOW_SHOW
    -- Fired when a spell starts glowing
    -- Args: spellID

SPELL_ACTIVATION_OVERLAY_GLOW_HIDE
    -- Fired when spell glow ends
    -- Args: spellID
```

### Template
```xml
ActionBarButtonSpellActivationAlert
    -- Blizzard template for overlay glow frame
    -- Provides proper animations and visual style
```

### Implementation Example

**From LibActionButton-1.0:**
```lua
if WoWRetail then
    lib.eventFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
    lib.eventFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")

    function lib.ShowOverlayGlow(self)
        if not self.overlay then
            self.overlay = CreateFrame("Frame", nil, self,
                "ActionBarButtonSpellActivationAlert")
            self.overlay:SetAllPoints()
        end
        self.overlay:Show()
    end

    function lib.HideOverlayGlow(self)
        if self.overlay then
            self.overlay:Hide()
        end
    end

    function UpdateOverlayGlow(self)
        local spellID = self:GetSpellId()
        if spellID and IsSpellOverlayed(spellID) then
            lib.ShowOverlayGlow(self)
        else
            lib.HideOverlayGlow(self)
        end
    end
end
```

### Currently Used in LibTotalActionButtons

**None** - No overlay system implemented

### Visual Impact

**Critical Missing Feature:**
- Players rely on proc glows for rotation optimization
- Especially important for classes with reactive abilities (Ret Paladin, Arms Warrior, etc.)
- High visual impact and user expectation

---

## 4. Charge System (Retail 6.2+)

### Purpose
Display charges and charge cooldowns for abilities like Roll, Fire Blast, Arcane Missiles, etc.

### APIs

```lua
GetActionCharges(slot) → charges, maxCharges, cooldownStart, cooldownDuration, chargeModRate
    -- charges: current charges available (0 to maxCharges)
    -- maxCharges: maximum charges for the ability
    -- cooldownStart: GetTime() when current charge started cooldown
    -- cooldownDuration: time to gain next charge
    -- chargeModRate: haste modifier on charge gain

GetSpellCharges(spellID) → charges, maxCharges, cooldownStart, cooldownDuration
    -- Same as GetActionCharges but for spell ID directly
```

### Advanced Implementation

**Proper charge display requires:**

1. **Separate Cooldown Frame**
```lua
button.chargeCooldown = CreateFrame("Cooldown",
    button:GetName() .. "ChargeCooldown", button, "CooldownFrameTemplate")
button.chargeCooldown:SetAllPoints(button.icon)
button.chargeCooldown:SetDrawEdge(false)
button.chargeCooldown:SetDrawBling(false)
```

2. **Charge vs Regular Cooldown Logic**
```lua
function UpdateCooldown(self)
    local charges, maxCharges, chargeStart, chargeDuration = GetActionCharges(self.action)

    if charges and maxCharges and maxCharges > 1 then
        -- Has charges system
        if charges < maxCharges then
            -- Show charge cooldown (next charge timer)
            self.chargeCooldown:SetCooldown(chargeStart, chargeDuration)
            self.chargeCooldown:Show()
        else
            -- All charges available
            self.chargeCooldown:Hide()
        end

        -- Don't show main cooldown unless all charges depleted
        if charges == 0 then
            -- Show full recharge time on main cooldown
            local start, duration = GetActionCooldown(self.action)
            self.cooldown:SetCooldown(start, duration)
        else
            self.cooldown:Hide()
        end
    else
        -- Regular cooldown
        local start, duration = GetActionCooldown(self.action)
        if start > 0 and duration > 0 then
            self.cooldown:SetCooldown(start, duration)
        end
    end
end
```

3. **Charge Count Display**
```lua
function UpdateCount(self)
    local charges, maxCharges = GetActionCharges(self.action)

    if charges and maxCharges and maxCharges > 1 then
        -- Show charge count
        self._count:SetText(charges)
    else
        -- Show item stack count
        local count = GetActionCount(self.action)
        if count > 1 then
            self._count:SetText(count)
        else
            self._count:SetText("")
        end
    end
end
```

### Currently Used in LibTotalActionButtons

**Partial Implementation (Lines 420-429):**
```lua
local charges, maxCharges, chargeStart, chargeDuration
if E.Compat and E.Compat.GetActionCharges then
    charges, maxCharges, chargeStart, chargeDuration = E.Compat.GetActionCharges(button.actionID)
end

if charges and maxCharges and maxCharges > 1 then
    button._count:SetText(charges)
else
    button._count:SetText(count)
end
```

**Issues:**
- ❌ No separate charge cooldown frame
- ❌ Shows charge count but not charge cooldown timer
- ❌ Main cooldown not hidden when charges available
- ⚠️ Incorrect visual representation

### Visual Impact

**High Priority Fix:**
- Charge-based abilities show incorrect cooldown
- Players see full cooldown even when charges available
- Confusing and frustrating UX

---

## 5. Loss of Control Cooldowns (Retail 5.1+)

### Purpose
Show debuff cooldowns on abilities (silence, interrupt, stun effects preventing ability use)

### APIs

```lua
GetActionLossOfControlCooldown(slot) → start, duration
    -- Returns cooldown applied by loss of control effects
    -- Separate from normal action cooldown
    -- Example: Silenced, can't cast spells

GetSpellLossOfControlCooldown(spellID) → start, duration
    -- Same for spell ID directly
```

### Advanced Implementation

**Visual Distinction Required:**

1. **Different Cooldown Edge Texture**
```lua
function UpdateLoCCooldown(self)
    local start, duration = GetActionLossOfControlCooldown(self.action)

    if start and start > 0 and duration and duration > 0 then
        self.cooldown:SetCooldown(start, duration)
        -- Use red edge for LoC cooldowns
        self.cooldown:SetEdgeTexture("Interface\\Cooldown\\edge-LoC")
        self.cooldown:SetSwipeColor(0.17, 0, 0)  -- Dark red swipe
        self.cooldown.currentCooldownType = COOLDOWN_TYPE_LOSS_OF_CONTROL
    else
        -- Normal cooldown
        local start, duration = GetActionCooldown(self.action)
        if start > 0 and duration > 0 then
            self.cooldown:SetCooldown(start, duration)
            self.cooldown:SetEdgeTexture("Interface\\Cooldown\\edge")
            self.cooldown:SetSwipeColor(0, 0, 0)  -- Black swipe
            self.cooldown.currentCooldownType = COOLDOWN_TYPE_NORMAL
        end
    end
end
```

2. **Priority System**
```lua
-- LoC cooldowns should override normal cooldowns visually
-- Player needs to know WHY ability is unavailable
```

### Currently Used in LibTotalActionButtons

**None** - Not implemented

### Visual Impact

**Medium-High Priority:**
- Important for PvP (interrupts, silences)
- Important for PvE (boss mechanics)
- Players need to know difference between ability cooldown vs debuff

---

## 6. New Action Highlighting (Retail)

### Purpose
Show yellow glow on newly learned spells and abilities

### APIs

```lua
C_NewItems.IsNewItem(id, itemType) → boolean
    -- id: spell ID or item ID
    -- itemType: Enum.NewItemType.Spell or Enum.NewItemType.Item
    -- Returns true if item/spell is newly acquired
```

### Events

```lua
NEW_RECIPE_LEARNED
    -- Fired when new ability/recipe learned

SPELL_UPDATE_ICON
    -- Fired when spell icons update
    -- Can indicate new spell
```

### Implementation Example

**From LibActionButton-1.0:**
```lua
function Generic:UpdateNewAction()
    if C_NewItems and C_NewItems.IsNewItem then
        local actionType, id = GetActionInfo(self.action)
        local isNew = false

        if actionType == "spell" then
            isNew = C_NewItems.IsNewItem(id, Enum.NewItemType.Spell)
        elseif actionType == "item" then
            isNew = C_NewItems.IsNewItem(id, Enum.NewItemType.Item)
        end

        if isNew then
            if not self.NewActionTexture then
                self.NewActionTexture = self:CreateTexture(nil, "OVERLAY")
                self.NewActionTexture:SetAtlas("bags-glow-white")
                self.NewActionTexture:SetBlendMode("ADD")
                self.NewActionTexture:SetAllPoints()
            end
            self.NewActionTexture:Show()
        else
            if self.NewActionTexture then
                self.NewActionTexture:Hide()
            end
        end
    end
end
```

### Visual Elements

**Atlas Texture:**
- `"bags-glow-white"` - Yellow/white glow effect
- Blend mode: `"ADD"` - Additive blending for glow
- Should pulse/animate

### Currently Used in LibTotalActionButtons

**None** - Not implemented

### Visual Impact

**Medium Priority:**
- Quality of life feature
- Helps players find newly learned abilities
- Expected behavior from Blizzard UI

---

## 7. Assisted Combat / Rotation Helper (Retail - Recent)

### Purpose
Highlight abilities in single-button rotation helper mode

### APIs

```lua
C_ActionBar.IsAssistedCombatAction(slot) → boolean
    -- Returns true if action participates in assisted combat system
    -- Used to determine which buttons to highlight

AssistedCombatManager.lastNextCastSpellID
    -- Current spell ID recommended by rotation helper
    -- Global table accessible
```

### Events (EventRegistry)

```lua
EventRegistry:RegisterCallback(
    "AssistedCombatManager.OnSetActionSpell",
    function(spellID) end
)

EventRegistry:RegisterCallback(
    "AssistedCombatManager.OnAssistedHighlightSpellChange",
    function() end
)

EventRegistry:RegisterCallback(
    "AssistedCombatManager.OnSetUseAssistedHighlight",
    function(enabled) end
)
```

### Template

```xml
ActionBarButtonAssistedCombatRotationTemplate
    -- Provides rotation helper highlight frame
    -- Shows glowing border for recommended ability
```

### Implementation Example

**From LibActionButton-1.0:**
```lua
if WoWRetail then
    function UpdateAssistedCombat(self)
        if not self.config.assistedHighlight then return end

        if self.AssistedCombatFrame then
            if IsPlayerInAssistedCombat() then
                local actionType, id = GetActionInfo(self.action)
                if actionType == "spell" then
                    if C_ActionBar.IsAssistedCombatAction(self.action) then
                        if id == AssistedCombatManager.lastNextCastSpellID then
                            self.AssistedCombatFrame:Show()
                        else
                            self.AssistedCombatFrame:Hide()
                        end
                    end
                end
            else
                self.AssistedCombatFrame:Hide()
            end
        end
    end

    EventRegistry:RegisterCallback(
        "AssistedCombatManager.OnAssistedHighlightSpellChange",
        function()
            for button in next, lib.buttonRegistry do
                UpdateAssistedCombat(button)
            end
        end
    )
end
```

### Currently Used in LibTotalActionButtons

**None** - Not implemented

### Visual Impact

**Low-Medium Priority:**
- Recent Retail feature
- Optional feature (can be disabled)
- Useful for new players learning rotations
- Not critical for addon functionality

---

## 8. ActionButtonTemplate Visual Elements

### Elements Provided by Blizzard Template

**From ActionBarButtonTemplate XML:**

```xml
<CheckButton name="ActionBarButtonTemplate">
    <Layers>
        <Layer level="BACKGROUND">
            <Texture name="$parentIcon"/>
                -- Main ability icon

            <Texture name="$parentFlash"/>
                -- Flash animation for auto-attack
        </Layer>

        <Layer level="BORDER">
            <Texture name="$parentBorder"/>
                -- Border overlay (for equipped, unusable, etc.)

            <Texture name="$parentNormalTexture"/>
                -- Button background texture
        </Layer>

        <Layer level="OVERLAY">
            <FontString name="$parentName"/>
                -- Macro name text

            <FontString name="$parentHotKey"/>
                -- Keybind display

            <FontString name="$parentCount"/>
                -- Stack/charge count

            <Texture name="$parentNewActionTexture"/>
                -- New action yellow glow (Retail)
        </Layer>
    </Layers>

    <Frames>
        <Cooldown name="$parentCooldown"/>
            -- Main cooldown spiral

        <Frame name="$parentSpellHighlightTexture"/>
            -- Spell proc highlight border

        <Frame name="$parentSpellHighlightAnim"/>
            -- Spell highlight animation controller

        <Frame name="$parentFlyoutArrowContainer"/>
            -- Flyout menu indicator (arrow)

        <Frame name="$parentAssistedCombatRotationFrame"/> (Retail)
            -- Rotation helper highlight

        <Frame name="$parentSpellCastAnimFrame"/> (Retail)
            -- Spell cast animation
    </Frames>
</CheckButton>
```

### Elements Used in LibTotalActionButtons

**Currently Used (Lines 105-114):**
```lua
button._icon = button.icon or _G[button:GetName() .. "Icon"]
button._count = button.Count or _G[button:GetName() .. "Count"]
button._hotkey = button.HotKey or _G[button:GetName() .. "HotKey"]
button._name = button.Name or _G[button:GetName() .. "Name"]
button._border = button.Border or _G[button:GetName() .. "Border"]
button._cooldown = button.cooldown or _G[button:GetName() .. "Cooldown"]
button._normalTexture = button.NormalTexture or button:GetNormalTexture()
button._flash = button.Flash or _G[button:GetName() .. "Flash"]
button._highlight = button:GetHighlightTexture()
button._pushedTexture = button:GetPushedTexture()
```

### Missing Template Elements

**Not Currently Used:**
- ❌ `SpellHighlightTexture` - Proc highlight border
- ❌ `SpellHighlightAnim` - Highlight animation
- ❌ `FlyoutArrowContainer` - Flyout indicator
- ❌ `NewActionTexture` - New action glow (Retail)
- ❌ `AssistedCombatRotationFrame` - Rotation helper (Retail)
- ❌ `SpellCastAnimFrame` - Cast animation (Retail)

### Impact

**Medium Priority:**
- Template provides these elements automatically
- Just need to reference and configure them
- Minimal code to leverage built-in functionality

---

## 9. Blizzard Helper Functions

### ActionButton_* Global Functions

**Available for use:**

```lua
ActionButton_Update(button)
    -- Main update function for action button
    -- Updates icon, cooldown, count, usability, etc.

ActionButton_UpdateCooldown(button)
    -- Updates cooldown display

ActionButton_UpdateUsable(button)
    -- Updates usability coloring

ActionButton_UpdateCount(button)
    -- Updates stack count display

ActionButton_UpdateState(button)
    -- Updates checked/current state

ActionButton_UpdateFlash(button)
    -- Updates flash animation for auto-attack

ActionButton_UpdateFlyout(button)
    -- Updates flyout indicator

ActionButton_UpdateRangeIndicator(button)
    -- Updates range checking on timer

ActionButton_UpdateOverlayGlow(button) (Retail)
    -- Updates spell proc overlay glow

ActionButton_StartFlash(button)
    -- Starts flash animation

ActionButton_StopFlash(button)
    -- Stops flash animation

ActionButton_GetPagedID(button)
    -- Gets paged action ID for button
```

### Usage Consideration

**Pros:**
- Leverages Blizzard's tested code
- Automatic updates with WoW patches
- Less code to maintain

**Cons:**
- Less customization control
- May override custom styling
- Harder to debug issues

### Currently Used in LibTotalActionButtons

**None** - Custom implementations only

### Recommendation

**Consider hybrid approach:**
- Use Blizzard functions as fallback
- Override where customization needed
- Reduces code duplication

---

## 10. Cooldown Frame APIs

### CooldownFrame Methods

```lua
-- Setting cooldown
Cooldown:SetCooldown(start, duration, modRate)
    -- start: GetTime() when cooldown started
    -- duration: length in seconds
    -- modRate: optional haste modifier

-- Visual customization
Cooldown:SetEdgeTexture(texturePath)
    -- Custom edge texture
    -- Default: "Interface\\Cooldown\\edge"
    -- LoC: "Interface\\Cooldown\\edge-LoC"

Cooldown:SetSwipeColor(r, g, b, a)
    -- Color of swipe animation
    -- Default: black (0, 0, 0, 0.8)
    -- LoC: dark red (0.17, 0, 0)

Cooldown:SetDrawEdge(enabled)
    -- Show/hide edge glow

Cooldown:SetDrawBling(enabled)
    -- Show/hide cooldown finish bling

Cooldown:SetDrawSwipe(enabled)
    -- Show/hide swipe animation

Cooldown:SetHideCountdownNumbers(hide)
    -- Show/hide cooldown numbers

Cooldown:SetReverse(reverse)
    -- Reverse cooldown direction (fill vs drain)
```

### Currently Used in LibTotalActionButtons

**Basic usage only (Lines 408-419):**
```lua
if start > 0 and duration > 0 then
    button._cooldown:SetCooldown(start, duration)
    button._cooldown:Show()
else
    button._cooldown:Hide()
end
```

### Missing Customization

**Available but unused:**
- ❌ Edge texture customization
- ❌ Swipe color customization
- ❌ Cooldown number visibility control
- ❌ Bling disable option
- ❌ Reverse cooldown option

### Impact

**Low-Medium Priority:**
- Nice-to-have customization options
- Players often want to hide cooldown numbers
- Visual polish features

---

## 11. Spell/Item Helper APIs

### For Multi-Type Button Support

**Spell APIs:**
```lua
GetSpellInfo(spellID) → name, rank, icon, castTime, minRange, maxRange, spellID, originalIcon
GetSpellTexture(spellID) → texturePath
GetSpellCooldown(spellID) → start, duration, enable, modRate
GetSpellCharges(spellID) → charges, maxCharges, start, duration
GetSpellCount(spellID) → count
IsSpellInRange(spellID, unit) → inRange
IsUsableSpell(spellID) → isUsable, notEnoughMana
IsCurrentSpell(spellID) → boolean
HasSpellRange(spellID) → boolean
IsAttackSpell(spellID) → boolean
IsAutoRepeatSpell(spellID) → boolean
IsConsumableSpell(spellID) → boolean
FindSpellBookSlotBySpellID(spellID) → slot, bookType
```

**Item APIs:**
```lua
GetItemInfo(itemID) → name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, ...
GetItemIcon(itemID) → texturePath
GetItemCooldown(itemID) → start, duration, enable
GetItemCount(itemID, includeBank, includeCharges) → count
GetItemSpell(itemID) → name, spellID  -- For item with on-use effect
IsItemInRange(itemID, unit) → inRange
IsUsableItem(itemID) → usable, noMana
IsCurrentItem(itemID) → boolean
IsEquippedItem(itemID) → boolean
IsConsumableItem(itemID) → boolean
ItemHasRange(itemID) → boolean
```

**Macro APIs:**
```lua
GetMacroInfo(macroID) → name, iconTexture, body, isLocal
GetMacroIndexByName(name) → macroID
```

### Currently Used in LibTotalActionButtons

**None** - Only action-type buttons supported

### Required for Multi-Type Buttons

**Essential for Phase 2:**
- Button type system (spell/item/macro/custom)
- Type-specific UpdateFunctions tables
- See "Button Type System" section in main document

---

## 12. Version Detection & Compatibility

### WoW Version Constants

```lua
WOW_PROJECT_ID
    -- Enum value for current WoW version

-- Constants:
WOW_PROJECT_MAINLINE = 1        -- Retail
WOW_PROJECT_CLASSIC = 2         -- Classic Era
WOW_PROJECT_BURNING_CRUSADE_CLASSIC = 5  -- TBC
WOW_PROJECT_WRATH_CLASSIC = 11   -- Wrath
WOW_PROJECT_CATACLYSM_CLASSIC = 14  -- Cataclysm
```

### Version Detection Pattern

```lua
local WoWRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
local WoWClassic = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)
local WoWBCC = (WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC)
local WoWWrath = (WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC)
local WoWCata = (WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC)
```

### API Compatibility Wrappers

```lua
-- Functions that don't exist in all versions
local GetActionCharges = GetActionCharges or function() return nil end
local GetActionLossOfControlCooldown = GetActionLossOfControlCooldown or function() return nil end
local GetSpellCharges = GetSpellCharges or function() return nil end
local GetSpellLossOfControlCooldown = GetSpellLossOfControlCooldown or function() return nil end
```

### Conditional Feature Registration

```lua
-- Only register Retail-specific events
if WoWRetail then
    lib.eventFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
    lib.eventFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
    lib.eventFrame:RegisterEvent("ASSISTED_COMBAT_UPDATE")
end
```

### Currently Used in LibTotalActionButtons

**None** - No version detection at all

### Impact

**CRITICAL MISSING FEATURE:**
- Cannot safely use Retail-only APIs
- Will error on Classic if Retail features used
- Cannot optimize for version-specific features
- Blocks implementation of many enhancements

---

## 13. Priority Implementation Roadmap

### Phase 1: Critical Foundation (1-2 days)

**Must implement first:**

1. **Add WoW Version Detection**
   ```lua
   local WoWRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
   local WoWClassic = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)
   -- ... other versions
   ```

2. **Add API Compatibility Wrappers**
   ```lua
   local GetActionCharges = GetActionCharges or function() return nil end
   local GetActionLossOfControlCooldown = GetActionLossOfControlCooldown or function() return nil end
   -- ... other Retail-only APIs
   ```

3. **Fix Template Creation Bug**
   - Current: `"ActionBarButtonTemplate, SecureActionButtonTemplate"`
   - Investigate proper multi-template syntax

**Deliverable:** Safe foundation for version-specific features

---

### Phase 2: Visual Enhancement - Charge Cooldowns (1 day)

**Already have API call, need visual:**

1. **Create Charge Cooldown Frame**
   ```lua
   function LAB:CreateChargeCooldownFrame(button)
       button.chargeCooldown = CreateFrame("Cooldown",
           button:GetName() .. "ChargeCooldown", button, "CooldownFrameTemplate")
       button.chargeCooldown:SetAllPoints(button._icon)
       button.chargeCooldown:SetDrawEdge(false)
       button.chargeCooldown:SetDrawBling(false)
   end
   ```

2. **Update Cooldown Logic**
   - Show charge cooldown when charges < max
   - Show main cooldown only when charges = 0
   - Hide cooldown when charges = max

3. **Update Count Display**
   - Show charge count, not item count, for charge abilities

**Deliverable:** Accurate charge display (Fire Blast, Roll, etc.)

---

### Phase 3: Visual Enhancement - Spell Overlays (1-2 days)

**High visual impact:**

1. **Register Events (Retail only)**
   ```lua
   if WoWRetail then
       lib.eventFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
       lib.eventFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
   end
   ```

2. **Create Overlay Frame**
   ```lua
   function LAB:CreateSpellOverlay(button)
       if not button.SpellActivationAlert then
           button.SpellActivationAlert = CreateFrame("Frame", nil, button,
               "ActionBarButtonSpellActivationAlert")
           button.SpellActivationAlert:SetAllPoints()
       end
   end
   ```

3. **Update Overlay on Events**
   ```lua
   function LAB:UpdateSpellOverlay(button)
       if WoWRetail and C_SpellActivationOverlay then
           local spellID = -- get from action
           if C_SpellActivationOverlay.IsSpellOverlayed(spellID) then
               button.SpellActivationAlert:Show()
           else
               button.SpellActivationAlert:Hide()
           end
       end
   end
   ```

4. **Get Spell ID from Action**
   - Need `GetActionInfo()` to get spell ID
   - Store in button for quick access

**Deliverable:** Proc glows for reactive abilities

---

### Phase 4: Visual Enhancement - LoC Cooldowns (1 day)

**Important for PvP/PvE:**

1. **Add LoC Cooldown Check**
   ```lua
   if WoWRetail and GetActionLossOfControlCooldown then
       local locStart, locDuration = GetActionLossOfControlCooldown(actionID)
       if locStart and locStart > 0 and locDuration and locDuration > 0 then
           -- Use LoC cooldown
       end
   end
   ```

2. **Visual Distinction**
   ```lua
   button._cooldown:SetEdgeTexture("Interface\\Cooldown\\edge-LoC")
   button._cooldown:SetSwipeColor(0.17, 0, 0)  -- Dark red
   ```

3. **Priority System**
   - LoC cooldown overrides normal cooldown display
   - Resume normal cooldown when LoC ends

**Deliverable:** Clear visual distinction for debuff cooldowns

---

### Phase 5: Visual Enhancement - New Action Highlights (1 day)

**Quality of life:**

1. **Check for New Actions**
   ```lua
   function LAB:UpdateNewAction(button)
       if WoWRetail and C_NewItems then
           local actionType, id = GetActionInfo(button.action)
           local isNew = false

           if actionType == "spell" then
               isNew = C_NewItems.IsNewItem(id, Enum.NewItemType.Spell)
           elseif actionType == "item" then
               isNew = C_NewItems.IsNewItem(id, Enum.NewItemType.Item)
           end

           if isNew then
               if not button.NewActionTexture then
                   button.NewActionTexture = button:CreateTexture(nil, "OVERLAY")
                   button.NewActionTexture:SetAtlas("bags-glow-white")
                   button.NewActionTexture:SetBlendMode("ADD")
                   button.NewActionTexture:SetAllPoints()
               end
               button.NewActionTexture:Show()
           else
               if button.NewActionTexture then
                   button.NewActionTexture:Hide()
               end
           end
       end
   end
   ```

2. **Register Events**
   ```lua
   if WoWRetail then
       lib.eventFrame:RegisterEvent("NEW_RECIPE_LEARNED")
       lib.eventFrame:RegisterEvent("SPELL_UPDATE_ICON")
   end
   ```

**Deliverable:** Yellow glow on newly learned abilities

---

### Phase 6: Additional Features - Equipped Item Border (0.5 days)

**Easy win:**

1. **Check Equipped Status**
   ```lua
   function LAB:UpdateEquipped(button)
       local isEquipped = IsEquippedAction(button.action)

       if isEquipped and button._border then
           button._border:SetVertexColor(0, 1.0, 0, 0.35)  -- Green
           button._border:Show()
       else
           if button._border then
               button._border:Hide()
           end
       end
   end
   ```

2. **Integrate into Usable Update**
   - Call during usability check
   - Visual indicator for equipped items

**Deliverable:** Green border on equipped item buttons

---

### Phase 7: Additional Features - Cooldown Customization (0.5 days)

**Configuration options:**

1. **Add Config Options**
   ```lua
   config.showCooldownNumbers = true  -- Show/hide numbers
   config.cooldownEdgeTexture = "default"  -- or "minimal", "none"
   config.cooldownBling = true  -- Finish animation
   ```

2. **Apply to Cooldown Frame**
   ```lua
   button._cooldown:SetHideCountdownNumbers(not config.showCooldownNumbers)
   button._cooldown:SetDrawBling(config.cooldownBling)
   if config.cooldownEdgeTexture == "none" then
       button._cooldown:SetDrawEdge(false)
   end
   ```

**Deliverable:** Cooldown display customization

---

### Phase 8: Advanced Features - Assisted Combat (1-2 days)

**Retail rotation helper:**

1. **Check Assisted Combat**
   ```lua
   if WoWRetail and C_ActionBar then
       function LAB:UpdateAssistedCombat(button)
           if not button.AssistedCombatFrame then
               button.AssistedCombatFrame = CreateFrame("Frame", nil, button,
                   "ActionBarButtonAssistedCombatRotationTemplate")
           end

           if C_ActionBar.IsAssistedCombatAction(button.action) then
               local actionType, id = GetActionInfo(button.action)
               if actionType == "spell" and id == AssistedCombatManager.lastNextCastSpellID then
                   button.AssistedCombatFrame:Show()
               else
                   button.AssistedCombatFrame:Hide()
               end
           else
               button.AssistedCombatFrame:Hide()
           end
       end
   end
   ```

2. **Register EventRegistry Callbacks**
   ```lua
   EventRegistry:RegisterCallback(
       "AssistedCombatManager.OnAssistedHighlightSpellChange",
       function()
           -- Update all buttons
       end
   )
   ```

**Deliverable:** Rotation helper integration

---

### Phase 9: Advanced Features - Template Elements (1 day)

**Leverage unused template elements:**

1. **Reference Template Elements**
   ```lua
   button.SpellHighlightTexture = _G[button:GetName() .. "SpellHighlightTexture"]
   button.SpellHighlightAnim = _G[button:GetName() .. "SpellHighlightAnim"]
   button.FlyoutArrowContainer = _G[button:GetName() .. "FlyoutArrowContainer"]
   if WoWRetail then
       button.SpellCastAnimFrame = _G[button:GetName() .. "SpellCastAnimFrame"]
   end
   ```

2. **Configure as Needed**
   - Spell highlight for procs
   - Flyout arrow for multi-spell buttons
   - Cast animation for spell casts

**Deliverable:** Full template utilization

---

## 14. Estimated Effort Summary

### By Phase:

| Phase | Feature | Priority | Effort | Impact |
|-------|---------|----------|--------|--------|
| 1 | Version Detection & Wrappers | CRITICAL | 1-2 days | Enables everything else |
| 2 | Charge Cooldown Display | HIGH | 1 day | High user impact |
| 3 | Spell Activation Overlays | HIGH | 1-2 days | Critical visual feedback |
| 4 | LoC Cooldowns | MEDIUM-HIGH | 1 day | Important for PvP/PvE |
| 5 | New Action Highlights | MEDIUM | 1 day | Quality of life |
| 6 | Equipped Item Borders | LOW-MEDIUM | 0.5 days | Visual clarity |
| 7 | Cooldown Customization | LOW-MEDIUM | 0.5 days | User preference |
| 8 | Assisted Combat | LOW | 1-2 days | Retail recent feature |
| 9 | Template Elements | LOW | 1 day | Full feature coverage |

### Total Estimated Effort: 8-11 days (2-3 weeks)

### Recommended Immediate Action:

**Week 1:**
- Phase 1: Version detection (foundation)
- Phase 2: Charge cooldowns (quick win)
- Phase 3: Spell overlays (high impact)

**Week 2:**
- Phase 4: LoC cooldowns
- Phase 5: New action highlights
- Phase 6: Equipped borders
- Phase 7: Cooldown customization

**Week 3 (Optional):**
- Phase 8: Assisted combat
- Phase 9: Template elements

---

## 15. Code Examples for Implementation

### Version Detection Module

**Add to top of LibTotalActionButtons.lua:**

```lua
-- ============================================
-- WoW Version Detection
-- ============================================

local WoWRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
local WoWClassic = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)
local WoWBCC = (WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC)
local WoWWrath = (WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC)
local WoWCata = (WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC)

-- API Compatibility Wrappers
local GetActionCharges = GetActionCharges or function() return nil end
local GetActionLossOfControlCooldown = GetActionLossOfControlCooldown or function() return nil end
local GetSpellCharges = GetSpellCharges or function() return nil end
local GetSpellLossOfControlCooldown = GetSpellLossOfControlCooldown or function() return nil end

-- Store in library for external access
LAB.WoWRetail = WoWRetail
LAB.WoWClassic = WoWClassic
LAB.WoWBCC = WoWBCC
LAB.WoWWrath = WoWWrath
LAB.WoWCata = WoWCata
```

### Enhanced Cooldown Update

**Replace UpdateCooldown function:**

```lua
function LAB:UpdateCooldown(button)
    if not button or not button._cooldown then return end

    local start, duration, enable, modRate = GetActionCooldown(button.actionID)
    local charges, maxCharges, chargeStart, chargeDuration = GetActionCharges(button.actionID)

    -- Handle charge-based abilities
    if charges and maxCharges and maxCharges > 1 then
        -- Create charge cooldown frame if needed
        if not button.chargeCooldown and WoWRetail then
            button.chargeCooldown = CreateFrame("Cooldown",
                button:GetName() .. "ChargeCooldown", button, "CooldownFrameTemplate")
            button.chargeCooldown:SetAllPoints(button._icon)
            button.chargeCooldown:SetDrawEdge(false)
            button.chargeCooldown:SetDrawBling(false)
        end

        if button.chargeCooldown then
            if charges < maxCharges then
                -- Show next charge timer
                button.chargeCooldown:SetCooldown(chargeStart, chargeDuration)
                button.chargeCooldown:Show()
            else
                button.chargeCooldown:Hide()
            end
        end

        -- Only show main cooldown if completely depleted
        if charges == 0 and start > 0 and duration > 0 then
            button._cooldown:SetCooldown(start, duration)
            button._cooldown:Show()
        else
            button._cooldown:Hide()
        end

        return
    end

    -- Check for Loss of Control cooldown (Retail only)
    if WoWRetail and GetActionLossOfControlCooldown then
        local locStart, locDuration = GetActionLossOfControlCooldown(button.actionID)
        if locStart and locStart > 0 and locDuration and locDuration > 0 then
            button._cooldown:SetCooldown(locStart, locDuration)
            button._cooldown:SetEdgeTexture("Interface\\Cooldown\\edge-LoC")
            button._cooldown:SetSwipeColor(0.17, 0, 0)
            button._cooldown.currentCooldownType = "LoC"
            button._cooldown:Show()
            return
        end
    end

    -- Normal cooldown
    if start > 0 and duration > 0 and enable == 1 then
        button._cooldown:SetCooldown(start, duration)
        button._cooldown:SetEdgeTexture("Interface\\Cooldown\\edge")
        button._cooldown:SetSwipeColor(0, 0, 0)
        button._cooldown.currentCooldownType = "normal"
        button._cooldown:Show()
    else
        button._cooldown:Hide()
    end
end
```

### Spell Overlay System

**Add new function:**

```lua
function LAB:UpdateSpellOverlay(button)
    if not WoWRetail then return end
    if not button then return end

    -- Get spell ID from action
    local actionType, id = GetActionInfo(button.actionID)
    if actionType ~= "spell" then
        if button.SpellActivationAlert then
            button.SpellActivationAlert:Hide()
        end
        return
    end

    local spellID = id

    -- Check if spell is overlayed
    local isOverlayed = false
    if C_SpellActivationOverlay and C_SpellActivationOverlay.IsSpellOverlayed then
        isOverlayed = C_SpellActivationOverlay.IsSpellOverlayed(spellID)
    elseif IsSpellOverlayed then
        isOverlayed = IsSpellOverlayed(spellID)
    end

    if isOverlayed then
        -- Create overlay if needed
        if not button.SpellActivationAlert then
            button.SpellActivationAlert = CreateFrame("Frame", nil, button,
                "ActionBarButtonSpellActivationAlert")
            button.SpellActivationAlert:SetAllPoints()
        end
        button.SpellActivationAlert:Show()
    else
        if button.SpellActivationAlert then
            button.SpellActivationAlert:Hide()
        end
    end
end
```

### New Action Highlight

**Add new function:**

```lua
function LAB:UpdateNewAction(button)
    if not WoWRetail then return end
    if not button then return end
    if not C_NewItems or not C_NewItems.IsNewItem then return end

    local actionType, id = GetActionInfo(button.actionID)
    local isNew = false

    if actionType == "spell" then
        isNew = C_NewItems.IsNewItem(id, Enum.NewItemType.Spell)
    elseif actionType == "item" then
        isNew = C_NewItems.IsNewItem(id, Enum.NewItemType.Item)
    end

    if isNew then
        if not button.NewActionTexture then
            button.NewActionTexture = button:CreateTexture(nil, "OVERLAY")
            button.NewActionTexture:SetAtlas("bags-glow-white")
            button.NewActionTexture:SetBlendMode("ADD")
            button.NewActionTexture:SetAllPoints()
        end
        button.NewActionTexture:Show()
    else
        if button.NewActionTexture then
            button.NewActionTexture:Hide()
        end
    end
end
```

### Equipped Item Border

**Add to UpdateUsable function:**

```lua
function LAB:UpdateUsable(button)
    if not button then return end

    local isUsable, notEnoughPower = IsUsableAction(button.actionID)
    local isEquipped = IsEquippedAction(button.actionID)

    -- Equipped item border (green)
    if isEquipped and button._border then
        button._border:SetVertexColor(0, 1.0, 0, 0.35)
        button._border:Show()
    elseif button._border then
        button._border:Hide()
    end

    -- Rest of usability logic...
end
```

---

## 16. API Reference Quick List

### Essential APIs to Implement

**Phase 1 (Critical):**
- [ ] `WOW_PROJECT_ID` detection
- [ ] API compatibility wrappers

**Phase 2 (High Priority):**
- [ ] `GetActionCharges()` - Enhanced implementation
- [ ] `C_SpellActivationOverlay.IsSpellOverlayed()` - Spell overlays
- [ ] `GetActionLossOfControlCooldown()` - LoC cooldowns
- [ ] `GetActionInfo()` - For spell ID extraction

**Phase 3 (Medium Priority):**
- [ ] `C_NewItems.IsNewItem()` - New action highlights
- [ ] `IsEquippedAction()` - Equipped borders
- [ ] Cooldown:SetEdgeTexture() - Cooldown customization
- [ ] Cooldown:SetHideCountdownNumbers() - Number visibility

**Phase 4 (Lower Priority):**
- [ ] `C_ActionBar.IsAssistedCombatAction()` - Rotation helper
- [ ] Template elements (SpellHighlightTexture, etc.)
- [ ] `EventRegistry` callbacks - Modern event system

---

## Conclusion

Blizzard provides extensive APIs for action button customization that LibTotalActionButtons is not currently leveraging. Implementing these features will:

1. **Match modern WoW UI expectations** - Proc glows, charge displays, etc.
2. **Improve visual feedback** - Better cooldown display, new action highlights
3. **Support all WoW versions** - Version detection enables safe feature use
4. **Reduce code complexity** - Leverage tested Blizzard systems
5. **Future-proof the library** - Version-aware architecture

**Total estimated effort: 2-3 weeks** for comprehensive Blizzard API integration.

**Recommended starting point: Phase 1 (Version Detection)** - This unblocks all other enhancements and prevents errors on Classic.
