# LibTotalActionButtons - Implementation Plan (Part 2)

**Continuation from Part 1**

This document contains Phases 2-10 of the implementation plan.

---

## Phase 2: Core Button Type System

**Duration**: 2-3 weeks
**Priority**: HIGH
**Goal**: Implement spell, item, macro, and custom button types

**Dependencies**: Phase 1 complete

**Overview**: Currently only action-type buttons are supported. This phase adds support for all button types that LibActionButton-1.0 provides.

---

### Step 2.1: Design Button Type Architecture

**Time**: 4-6 hours
**Priority**: HIGH

**Goal**: Plan type system structure before implementation

**Design Decisions**:

1. **UpdateFunctions Tables**: Each button type needs its own set of update functions
2. **Type Detection**: How to determine button type
3. **Type Switching**: Can buttons change type?
4. **Backward Compatibility**: Existing action buttons must continue working

**Architecture**:

```lua
-- Button type enum
LAB.ButtonType = {
    ACTION = "action",
    SPELL = "spell",
    ITEM = "item",
    MACRO = "macro",
    CUSTOM = "custom",
    EMPTY = "empty",
}

-- Each button will have:
button.buttonType = "action"  -- Current type
button.buttonAction = 1       -- Type-specific action data
button.UpdateFunctions = ActionTypeUpdateFunctions  -- Type-specific functions
```

**Deliverable**: Type system architecture documented

---

### Step 2.2: Implement Action Type UpdateFunctions

**Time**: 4-6 hours
**Priority**: HIGH

**Goal**: Refactor existing action button code into UpdateFunctions table

**Current State**: Update logic scattered throughout
**Target State**: Organized in ActionTypeUpdateFunctions table

**Implementation**:

```lua
-- =================================================================
-- Action Button Type
-- =================================================================

local ActionTypeUpdateFunctions = {
    -- Query functions
    HasAction = function(self)
        return HasAction(self.buttonAction)
    end,

    GetActionTexture = function(self)
        return GetActionTexture(self.buttonAction)
    end,

    GetActionText = function(self)
        return GetActionText(self.buttonAction)
    end,

    GetActionCount = function(self)
        return GetActionCount(self.buttonAction)
    end,

    GetActionCharges = function(self)
        return LAB.Compat.GetActionCharges(self.buttonAction)
    end,

    -- State functions
    IsInRange = function(self)
        return IsActionInRange(self.buttonAction)
    end,

    IsUsableAction = function(self)
        return IsUsableAction(self.buttonAction)
    end,

    IsCurrentAction = function(self)
        return IsCurrentAction(self.buttonAction)
    end,

    IsAutoRepeatAction = function(self)
        return IsAutoRepeatAction(self.buttonAction)
    end,

    IsAttackAction = function(self)
        return IsAttackAction(self.buttonAction)
    end,

    IsEquippedAction = function(self)
        return IsEquippedAction(self.buttonAction)
    end,

    IsConsumableAction = function(self)
        return IsConsumableAction(self.buttonAction)
    end,

    -- Cooldown functions
    GetCooldown = function(self)
        return GetActionCooldown(self.buttonAction)
    end,

    GetLossOfControlCooldown = function(self)
        if LAB.Compat.GetActionLossOfControlCooldown then
            return LAB.Compat.GetActionLossOfControlCooldown(self.buttonAction)
        end
        return nil
    end,

    -- Spell ID (for overlays)
    GetSpellId = function(self)
        local actionType, id = GetActionInfo(self.buttonAction)
        if actionType == "spell" then
            return id
        end
        return nil
    end,
}

-- Store in library
LAB.ActionTypeUpdateFunctions = ActionTypeUpdateFunctions
```

**Update existing Update functions to use this table**:

```lua
function LAB:UpdateIcon(button)
    if not button or not button.UpdateFunctions then return end

    local texture = button.UpdateFunctions.GetActionTexture(button)

    if texture then
        button._icon:SetTexture(texture)
        button._icon:Show()
    else
        if button.config and button.config.showGrid then
            button._icon:SetTexture("Interface\\Buttons\\UI-Quickslot")
            button._icon:Show()
        else
            button._icon:Hide()
        end
    end
end

-- Similar updates for other Update functions...
```

**Testing**:
```lua
-- Test action type functions
/run local btn = LibStub("LibTotalActionButtons-1.0"):CreateButton(1, "TestAction", UIParent)
/run print("Has Action:", btn.UpdateFunctions.HasAction(btn))
/run print("Texture:", btn.UpdateFunctions.GetActionTexture(btn))
```

**Deliverable**: Action type refactored into UpdateFunctions table

---

### Step 2.3: Implement Spell Type UpdateFunctions

**Time**: 6-8 hours
**Priority**: HIGH

**Goal**: Add support for spell-type buttons (cast spell by spell ID)

**Implementation**:

```lua
-- =================================================================
-- Spell Button Type
-- =================================================================

-- Helper: Find spell in spellbook
local function FindSpellBookSlotBySpellID(spellID)
    if not spellID then return nil end

    if WoWRetail then
        -- Retail has built-in function
        return FindSpellBookSlotBySpellID(spellID, false)
    else
        -- Classic: manual scan
        for i = 1, MAX_SKILLLINE_TABS do
            local name, texture, offset, numSpells = GetSpellTabInfo(i)
            if not name then break end
            for j = offset + 1, offset + numSpells do
                local spellName, spellSubName = GetSpellBookItemName(j, BOOKTYPE_SPELL)
                local currentSpellID = select(2, GetSpellBookItemInfo(j, BOOKTYPE_SPELL))
                if currentSpellID == spellID then
                    return j, BOOKTYPE_SPELL
                end
            end
        end
        return nil
    end
end

local SpellTypeUpdateFunctions = {
    HasAction = function(self)
        return true  -- Spell buttons always have an action
    end,

    GetActionTexture = function(self)
        return GetSpellTexture(self.buttonAction)
    end,

    GetActionText = function(self)
        return ""  -- Spells don't have text like macros
    end,

    GetActionCount = function(self)
        if LAB.Compat.GetSpellCount then
            return LAB.Compat.GetSpellCount(self.buttonAction)
        end
        return 0
    end,

    GetActionCharges = function(self)
        if LAB.Compat.GetSpellCharges then
            return LAB.Compat.GetSpellCharges(self.buttonAction)
        end
        return nil
    end,

    IsInRange = function(self)
        local slot = FindSpellBookSlotBySpellID(self.buttonAction)
        if slot then
            local inRange = IsSpellInRange(slot, BOOKTYPE_SPELL, "target")
            if inRange == 1 then
                return true
            elseif inRange == 0 then
                return false
            end
        end
        return nil
    end,

    IsUsableAction = function(self)
        return IsUsableSpell(self.buttonAction)
    end,

    IsCurrentAction = function(self)
        return IsCurrentSpell(self.buttonAction)
    end,

    IsAutoRepeatAction = function(self)
        local slot = FindSpellBookSlotBySpellID(self.buttonAction)
        if slot then
            return IsAutoRepeatSpell(slot, BOOKTYPE_SPELL)
        end
        return false
    end,

    IsAttackAction = function(self)
        local slot = FindSpellBookSlotBySpellID(self.buttonAction)
        if slot then
            return IsAttackSpell(slot, BOOKTYPE_SPELL)
        end
        return false
    end,

    IsEquippedAction = function(self)
        return false  -- Spells are never equipped
    end,

    IsConsumableAction = function(self)
        return IsConsumableSpell(self.buttonAction)
    end,

    GetCooldown = function(self)
        return GetSpellCooldown(self.buttonAction)
    end,

    GetLossOfControlCooldown = function(self)
        if LAB.Compat.GetSpellLossOfControlCooldown then
            return LAB.Compat.GetSpellLossOfControlCooldown(self.buttonAction)
        end
        return nil
    end,

    GetSpellId = function(self)
        return self.buttonAction  -- Button action IS the spell ID
    end,
}

LAB.SpellTypeUpdateFunctions = SpellTypeUpdateFunctions
```

**Add spell creation method**:

```lua
function LAB:CreateSpellButton(spellID, name, parent, config)
    if not LAB.Validate.Number(spellID, "spellID", "CreateSpellButton", 1) then
        return nil
    end

    -- Create base button
    local button = self:CreateButton(spellID, name, parent, config)
    if not button then return nil end

    -- Set type to spell
    button.buttonType = LAB.ButtonType.SPELL
    button.buttonAction = spellID
    button.UpdateFunctions = LAB.SpellTypeUpdateFunctions

    -- Set secure attributes for spell
    button:SetAttribute("type", "spell")
    button:SetAttribute("spell", spellID)

    -- Initial update
    self:UpdateButton(button)

    return button
end
```

**Testing**:
```lua
-- Test spell button (example: Fireball spell ID 133 for mage)
/run local LAB = LibStub("LibTotalActionButtons-1.0")
/run local btn = LAB:CreateSpellButton(133, "TestSpell", UIParent)
/run btn:SetPoint("CENTER")
/run print("Spell Texture:", btn.UpdateFunctions.GetActionTexture(btn))
```

**Deliverable**: Spell-type buttons functional

---

### Step 2.4: Implement Item Type UpdateFunctions

**Time**: 6-8 hours
**Priority**: HIGH

**Goal**: Add support for item-type buttons (use item by item ID)

**Implementation**:

```lua
-- =================================================================
-- Item Button Type
-- =================================================================

local ItemTypeUpdateFunctions = {
    HasAction = function(self)
        return true  -- Item buttons always have an action
    end,

    GetActionTexture = function(self)
        return GetItemIcon(self.buttonAction)
    end,

    GetActionText = function(self)
        local itemName = GetItemInfo(self.buttonAction)
        return itemName or ""
    end,

    GetActionCount = function(self)
        -- Include bank and charges
        return GetItemCount(self.buttonAction, nil, true)
    end,

    GetActionCharges = function(self)
        -- Items with on-use effects might have charges
        local hasSpell = GetItemSpell(self.buttonAction)
        if hasSpell and LAB.Compat.GetItemCharges then
            return LAB.Compat.GetItemCharges(self.buttonAction)
        end
        return nil
    end,

    IsInRange = function(self)
        return IsItemInRange(self.buttonAction, "target")
    end,

    IsUsableAction = function(self)
        return IsUsableItem(self.buttonAction)
    end,

    IsCurrentAction = function(self)
        return IsCurrentItem(self.buttonAction)
    end,

    IsAutoRepeatAction = function(self)
        return false  -- Items don't auto-repeat
    end,

    IsAttackAction = function(self)
        return false  -- Items aren't attack actions
    end,

    IsEquippedAction = function(self)
        return IsEquippedItem(self.buttonAction)
    end,

    IsConsumableAction = function(self)
        return IsConsumableItem(self.buttonAction)
    end,

    GetCooldown = function(self)
        return GetItemCooldown(self.buttonAction)
    end,

    GetLossOfControlCooldown = function(self)
        return nil  -- Items don't have LoC cooldowns
    end,

    GetSpellId = function(self)
        -- Get spell ID from item's on-use effect
        local spellName, spellID = GetItemSpell(self.buttonAction)
        return spellID
    end,
}

LAB.ItemTypeUpdateFunctions = ItemTypeUpdateFunctions
```

**Add item creation method**:

```lua
function LAB:CreateItemButton(itemID, name, parent, config)
    if not LAB.Validate.Number(itemID, "itemID", "CreateItemButton", 1) then
        return nil
    end

    local button = self:CreateButton(itemID, name, parent, config)
    if not button then return nil end

    button.buttonType = LAB.ButtonType.ITEM
    button.buttonAction = itemID
    button.UpdateFunctions = LAB.ItemTypeUpdateFunctions

    button:SetAttribute("type", "item")
    button:SetAttribute("item", itemID)

    self:UpdateButton(button)
    return button
end
```

**Deliverable**: Item-type buttons functional

---

### Step 2.5: Implement Macro Type UpdateFunctions

**Time**: 4-6 hours
**Priority**: MEDIUM-HIGH

**Implementation**:

```lua
-- =================================================================
-- Macro Button Type
-- =================================================================

local MacroTypeUpdateFunctions = {
    HasAction = function(self)
        return true
    end,

    GetActionTexture = function(self)
        local name, iconTexture = GetMacroInfo(self.buttonAction)
        return iconTexture
    end,

    GetActionText = function(self)
        local name = GetMacroInfo(self.buttonAction)
        return name or ""
    end,

    GetActionCount = function(self)
        return 0  -- Macros don't have counts
    end,

    GetActionCharges = function(self)
        return nil  -- Macros don't have charges
    end,

    IsInRange = function(self)
        return nil  -- Can't determine range for macros
    end,

    IsUsableAction = function(self)
        return true, false  -- Always usable
    end,

    IsCurrentAction = function(self)
        return false  -- Macros don't track current state
    end,

    IsAutoRepeatAction = function(self)
        return false
    end,

    IsAttackAction = function(self)
        return false
    end,

    IsEquippedAction = function(self)
        return false
    end,

    IsConsumableAction = function(self)
        return false
    end,

    GetCooldown = function(self)
        return 0, 0, 0  -- Macros show no cooldown
    end,

    GetLossOfControlCooldown = function(self)
        return nil
    end,

    GetSpellId = function(self)
        return nil  -- Macros don't have spell IDs
    end,
}

LAB.MacroTypeUpdateFunctions = MacroTypeUpdateFunctions
```

**Add macro creation method**:

```lua
function LAB:CreateMacroButton(macroID, name, parent, config)
    if not LAB.Validate.Number(macroID, "macroID", "CreateMacroButton", 1) then
        return nil
    end

    local button = self:CreateButton(macroID, name, parent, config)
    if not button then return nil end

    button.buttonType = LAB.ButtonType.MACRO
    button.buttonAction = macroID
    button.UpdateFunctions = LAB.MacroTypeUpdateFunctions

    button:SetAttribute("type", "macro")
    button:SetAttribute("macro", macroID)

    self:UpdateButton(button)
    return button
end
```

**Deliverable**: Macro-type buttons functional

---

### Step 2.6: Implement Custom Type System

**Time**: 4-6 hours
**Priority**: MEDIUM

**Goal**: Allow addon authors to provide custom UpdateFunctions

**Implementation**:

```lua
function LAB:CreateCustomButton(id, name, parent, config, updateFunctions)
    if not LAB.Validate.Number(id, "id", "CreateCustomButton", 1) then
        return nil
    end

    if not updateFunctions or type(updateFunctions) ~= "table" then
        self:Error("CreateCustomButton: updateFunctions must be a table!", 2)
        return nil
    end

    local button = self:CreateButton(id, name, parent, config)
    if not button then return nil end

    button.buttonType = LAB.ButtonType.CUSTOM
    button.buttonAction = id
    button.UpdateFunctions = updateFunctions

    -- Custom buttons require user to set attributes
    -- No automatic attribute setting

    self:UpdateButton(button)
    return button
end
```

**Deliverable**: Custom button type support

---

### Step 2.7: Update CreateButton to Support Types

**Time**: 2-3 hours
**Priority**: HIGH

**Goal**: Make CreateButton type-aware

**Current signature**: `CreateButton(actionID, name, parent, config)`
**New signature**: `CreateButton(actionID, name, parent, config, buttonType, updateFunctions)`

**Implementation**:

```lua
function LAB:CreateButton(actionID, name, parent, config, buttonType, updateFunctions)
    -- Validation...

    -- Create frame...
    local button = CreateFrame("CheckButton", name, parent, "ActionBarButtonTemplate")

    -- Default to action type if not specified
    buttonType = buttonType or LAB.ButtonType.ACTION

    -- Set button type and update functions
    button.buttonType = buttonType
    button.buttonAction = actionID

    if buttonType == LAB.ButtonType.ACTION then
        button.UpdateFunctions = LAB.ActionTypeUpdateFunctions
        button:SetAttribute("type", "action")
        button:SetAttribute("action", actionID)
    elseif buttonType == LAB.ButtonType.SPELL then
        button.UpdateFunctions = LAB.SpellTypeUpdateFunctions
        button:SetAttribute("type", "spell")
        button:SetAttribute("spell", actionID)
    elseif buttonType == LAB.ButtonType.ITEM then
        button.UpdateFunctions = LAB.ItemTypeUpdateFunctions
        button:SetAttribute("type", "item")
        button:SetAttribute("item", actionID)
    elseif buttonType == LAB.ButtonType.MACRO then
        button.UpdateFunctions = LAB.MacroTypeUpdateFunctions
        button:SetAttribute("type", "macro")
        button:SetAttribute("macro", actionID)
    elseif buttonType == LAB.ButtonType.CUSTOM then
        button.UpdateFunctions = updateFunctions or {}
        -- Custom types don't set attributes automatically
    end

    -- Rest of initialization...
end
```

**Deliverable**: CreateButton supports all types

---

### Step 2.8: Phase 2 Testing

**Time**: 4-6 hours
**Priority**: HIGH

**Test all button types**:

```lua
-- Test action button
/run local LAB = LibStub("LibTotalActionButtons-1.0")
/run local btn1 = LAB:CreateActionButton(1, "TestAction", UIParent); btn1:SetPoint("CENTER", -100, 0)

-- Test spell button (Fireball)
/run local btn2 = LAB:CreateSpellButton(133, "TestSpell", UIParent); btn2:SetPoint("CENTER", 0, 0)

-- Test item button (Hearthstone)
/run local btn3 = LAB:CreateItemButton(6948, "TestItem", UIParent); btn3:SetPoint("CENTER", 100, 0)

-- Test macro button
/run local macroIndex = GetMacroIndexByName("MyMacro"); if macroIndex > 0 then local btn4 = LAB:CreateMacroButton(macroIndex, "TestMacro", UIParent); btn4:SetPoint("CENTER", 0, -50) end
```

**Deliverable**: All button types tested and functional

---

### Phase 2 Completion Checklist

- [ ] Button type architecture designed
- [ ] Action type refactored to UpdateFunctions
- [ ] Spell type implemented and tested
- [ ] Item type implemented and tested
- [ ] Macro type implemented and tested
- [ ] Custom type system implemented
- [ ] CreateButton updated for all types
- [ ] All button types work with existing Update functions
- [ ] No Lua errors for any type
- [ ] Documentation updated

**Time to Complete Phase 2**: 2-3 weeks

**Next Phase**: Phase 3 - State Management System

---

## Phase 3: State Management System

**Duration**: 1-2 weeks
**Priority**: HIGH
**Goal**: Implement state-based action switching for stance/form/page changes

**Dependencies**: Phase 2 complete

**Overview**: Buttons need to change actions based on character state (warrior stance, druid form, action bar page, etc.)

---

### Step 3.1: Design State System Architecture

**Time**: 4-6 hours
**Priority**: HIGH

**Concepts**:

1. **State**: A character condition (stance 1, form 2, page 3, etc.)
2. **State-Action Mapping**: Each state can have a different action
3. **State Types**: Each state can have a different button type
4. **Current State**: Button tracks which state it's currently in

**Architecture**:

```lua
-- Button state data structure
button.stateTypes = {}     -- ["0"] = "action", ["1"] = "spell", etc.
button.stateActions = {}   -- ["0"] = 1, ["1"] = 133, etc.
button.currentState = "0"  -- Current active state
```

**Deliverable**: State system design documented

---

### Step 3.2: Implement SetState Method

**Time**: 6-8 hours
**Priority**: HIGH

**Implementation**:

```lua
function LAB:SetState(button, state, buttonType, action)
    if not LAB.Validate.Button(button, "SetState") then return end

    state = tostring(state or 0)

    -- Initialize state tables if needed
    if not button.stateTypes then
        button.stateTypes = {}
    end
    if not button.stateActions then
        button.stateActions = {}
    end

    -- Store state type and action
    button.stateTypes[state] = buttonType or LAB.ButtonType.EMPTY
    button.stateActions[state] = action

    -- Set secure state attributes
    if buttonType and action then
        button:SetAttribute("state-" .. state .. "-type", buttonType)

        if buttonType == LAB.ButtonType.ACTION then
            button:SetAttribute("state-" .. state .. "-action", action)
        elseif buttonType == LAB.ButtonType.SPELL then
            button:SetAttribute("state-" .. state .. "-spell", action)
        elseif buttonType == LAB.ButtonType.ITEM then
            button:SetAttribute("state-" .. state .. "-item", action)
        elseif buttonType == LAB.ButtonType.MACRO then
            button:SetAttribute("state-" .. state .. "-macro", action)
        end
    end

    self:DebugPrint(string.format("Set state %s: type=%s, action=%s",
        state, tostring(buttonType), tostring(action)))
end
```

**Deliverable**: SetState method functional

---

### Step 3.3: Implement GetState and UpdateState Methods

**Time**: 4-6 hours
**Priority**: HIGH

**Implementation**:

```lua
function LAB:GetState(button, state)
    if not LAB.Validate.Button(button, "GetState") then return nil end

    if not state then
        -- Return current state
        return button:GetAttribute("state")
    end

    -- Return specific state's type and action
    state = tostring(state)
    local stateType = button.stateTypes and button.stateTypes[state]
    local stateAction = button.stateActions and button.stateActions[state]

    return stateType, stateAction
end

function LAB:UpdateState(button, newState)
    if not LAB.Validate.Button(button, "UpdateState") then return end

    if newState then
        button:SetAttribute("state", tostring(newState))
    end

    button.currentState = button:GetAttribute("state") or "0"

    -- Update button display for new state
    self:UpdateButtonState(button)
end

function LAB:UpdateButtonState(button)
    if not button then return end

    local state = button.currentState or "0"
    local kind, action = self:GetAction(button, state)

    -- Update button type and action
    button.buttonType = kind or LAB.ButtonType.EMPTY
    button.buttonAction = action

    -- Set appropriate UpdateFunctions
    if kind == LAB.ButtonType.ACTION then
        button.UpdateFunctions = LAB.ActionTypeUpdateFunctions
    elseif kind == LAB.ButtonType.SPELL then
        button.UpdateFunctions = LAB.SpellTypeUpdateFunctions
    elseif kind == LAB.ButtonType.ITEM then
        button.UpdateFunctions = LAB.ItemTypeUpdateFunctions
    elseif kind == LAB.ButtonType.MACRO then
        button.UpdateFunctions = LAB.MacroTypeUpdateFunctions
    else
        button.UpdateFunctions = {}
    end

    -- Update all visual elements
    self:UpdateButton(button)
end

function LAB:GetAction(button, state)
    if not button then return LAB.ButtonType.EMPTY, nil end

    state = state or button.currentState or "0"
    state = tostring(state)

    local stateType = button.stateTypes and button.stateTypes[state]
    local stateAction = button.stateActions and button.stateActions[state]

    return stateType or button.buttonType or LAB.ButtonType.EMPTY,
           stateAction or button.buttonAction
end
```

**Deliverable**: State query and update methods functional

---

### Step 3.4: Handle Action Bar Page Changes

**Time**: 4-6 hours
**Priority**: HIGH

**Goal**: Respond to page changes and update button states

**Implementation**:

```lua
-- Register for page change events
function LAB:RegisterStateEvents()
    if not self.eventFrame then
        self.eventFrame = CreateFrame("Frame")
        self.eventFrame:SetScript("OnEvent", function(frame, event, ...)
            self:OnEvent(event, ...)
        end)
    end

    self.eventFrame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
    self.eventFrame:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
    self.eventFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")

    -- Stance/form events
    self.eventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    self.eventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
end

function LAB:OnEvent(event, ...)
    if event == "ACTIONBAR_PAGE_CHANGED" then
        local newPage = ...
        self:OnPageChanged(newPage)
    elseif event == "UPDATE_BONUS_ACTIONBAR" then
        self:OnBonusBarChanged()
    elseif event == "UPDATE_SHAPESHIFT_FORM" or event == "UPDATE_SHAPESHIFT_FORMS" then
        self:OnStanceChanged()
    elseif event == "ACTIONBAR_SLOT_CHANGED" then
        local slot = ...
        self:OnSlotChanged(slot)
    end
end

function LAB:OnPageChanged(newPage)
    -- Update all buttons that use action paging
    for button in pairs(self.buttons) do
        if button.usePaging then
            local state = tostring(newPage or GetActionBarPage())
            self:UpdateState(button, state)
        end
    end
end

function LAB:OnStanceChanged()
    local stance = GetShapeshiftForm()

    for button in pairs(self.buttons) do
        if button.useStance then
            self:UpdateState(button, tostring(stance))
        end
    end
end
```

**Deliverable**: Page and stance changes update buttons automatically

---

### Step 3.5: Add State Helper Methods

**Time**: 2-3 hours
**Priority**: MEDIUM

**Implementation**:

```lua
-- Enable paging for a button
function LAB:EnablePaging(button, enable)
    if not button then return end
    button.usePaging = enable

    if enable then
        -- Set initial state based on current page
        local page = GetActionBarPage()
        self:UpdateState(button, tostring(page))
    end
end

-- Enable stance-based state switching
function LAB:EnableStanceState(button, enable)
    if not button then return end
    button.useStance = enable

    if enable then
        -- Set initial state based on current stance
        local stance = GetShapeshiftForm()
        self:UpdateState(button, tostring(stance))
    end
end

-- Clear all states for a button
function LAB:ClearStates(button)
    if not button then return end

    button.stateTypes = {}
    button.stateActions = {}
    button.currentState = "0"

    -- Clear secure state attributes
    for i = 0, 10 do
        local state = tostring(i)
        button:SetAttribute("state-" .. state .. "-type", nil)
        button:SetAttribute("state-" .. state .. "-action", nil)
        button:SetAttribute("state-" .. state .. "-spell", nil)
        button:SetAttribute("state-" .. state .. "-item", nil)
        button:SetAttribute("state-" .. state .. "-macro", nil)
    end
end
```

**Deliverable**: Helper methods for state management

---

### Step 3.6: Phase 3 Testing

**Time**: 4-6 hours
**Priority**: HIGH

**Test state switching**:

```lua
-- Create button with multiple states
/run local LAB = LibStub("LibTotalActionButtons-1.0")
/run local btn = LAB:CreateButton(1, "TestState", UIParent)
/run btn:SetPoint("CENTER")

-- Set up states (0 = default, 1 = stance 1, 2 = stance 2)
/run LAB:SetState(btn, 0, "action", 1)  -- Default: Action slot 1
/run LAB:SetState(btn, 1, "spell", 133)  -- Stance 1: Fireball spell
/run LAB:SetState(btn, 2, "item", 6948)  -- Stance 2: Hearthstone

-- Test state switching
/run LAB:UpdateState(btn, 0)  -- Should show action 1
/run LAB:UpdateState(btn, 1)  -- Should show Fireball
/run LAB:UpdateState(btn, 2)  -- Should show Hearthstone

-- Test GetState
/run local type, action = LAB:GetState(btn, 1); print("State 1:", type, action)

-- Test paging
/run LAB:EnablePaging(btn, true)
-- Change action bar page and verify button updates
```

**Deliverable**: State management fully tested

---

### Phase 3 Completion Checklist

- [ ] State system architecture designed
- [ ] SetState method implemented
- [ ] GetState method implemented
- [ ] UpdateState method implemented
- [ ] GetAction method implemented
- [ ] Page change events handled
- [ ] Stance change events handled
- [ ] Helper methods implemented
- [ ] All state tests passing
- [ ] Documentation updated

**Time to Complete Phase 3**: 1-2 weeks

**Next Phase**: Phase 4 - Visual Enhancements (Blizzard APIs)

---

## Phase 4: Visual Enhancements - Blizzard APIs

**Duration**: 2-3 weeks
**Priority**: HIGH
**Goal**: Implement all Blizzard visual feedback systems

**Dependencies**: Phase 1 complete (version detection critical)

**Overview**: Add proc glows, charge cooldowns, loss of control cooldowns, new action highlights, and other visual enhancements.

---

### Step 4.1: Implement Charge Cooldown Display

**Time**: 6-8 hours
**Priority**: HIGH

**Goal**: Proper charge cooldown with separate cooldown frame

**Implementation**:

```lua
-- Create charge cooldown frame
function LAB:CreateChargeCooldownFrame(button)
    if not button then return end
    if button.chargeCooldown then return end  -- Already exists

    button.chargeCooldown = CreateFrame("Cooldown",
        button:GetName() .. "ChargeCooldown", button, "CooldownFrameTemplate")

    button.chargeCooldown:SetAllPoints(button._icon)
    button.chargeCooldown:SetDrawEdge(false)
    button.chargeCooldown:SetDrawBling(false)
    button.chargeCooldown:SetDrawSwipe(true)
    button.chargeCooldown:SetSwipeColor(0, 0, 0, 0.8)
    button.chargeCooldown:SetFrameLevel(button._cooldown:GetFrameLevel() + 1)
end

-- Enhanced cooldown update with charge support
function LAB:UpdateCooldown(button)
    if not button or not button._cooldown then return end

    local start, duration, enable, modRate
    local charges, maxCharges, chargeStart, chargeDuration

    -- Get cooldown data based on button type
    if button.UpdateFunctions and button.UpdateFunctions.GetCooldown then
        start, duration, enable, modRate = button.UpdateFunctions.GetCooldown(button)
    end

    if button.UpdateFunctions and button.UpdateFunctions.GetActionCharges then
        charges, maxCharges, chargeStart, chargeDuration = button.UpdateFunctions.GetActionCharges(button)
    end

    -- Handle charge-based abilities
    if charges and maxCharges and maxCharges > 1 then
        -- Create charge cooldown frame if needed
        if not button.chargeCooldown and WoWRetail then
            self:CreateChargeCooldownFrame(button)
        end

        if button.chargeCooldown then
            if charges < maxCharges and chargeStart and chargeDuration then
                -- Show next charge cooldown
                button.chargeCooldown:SetCooldown(chargeStart, chargeDuration)
                button.chargeCooldown:Show()
            else
                button.chargeCooldown:Hide()
            end
        end

        -- Main cooldown only shows when all charges depleted
        if charges == 0 and start and duration and enable == 1 then
            button._cooldown:SetCooldown(start, duration)
            button._cooldown:Show()
        else
            button._cooldown:Hide()
        end

        return
    end

    -- Check for Loss of Control cooldown (takes priority)
    if WoWRetail and button.UpdateFunctions and button.UpdateFunctions.GetLossOfControlCooldown then
        local locStart, locDuration = button.UpdateFunctions.GetLossOfControlCooldown(button)
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
    if start and duration and enable == 1 and duration > 0 then
        button._cooldown:SetCooldown(start, duration)
        button._cooldown:SetEdgeTexture("Interface\\Cooldown\\edge")
        button._cooldown:SetSwipeColor(0, 0, 0, 0.8)
        button._cooldown.currentCooldownType = "normal"
        button._cooldown:Show()
    else
        button._cooldown:Hide()
    end

    -- Hide charge cooldown if not charge-based
    if button.chargeCooldown then
        button.chargeCooldown:Hide()
    end
end
```

**Deliverable**: Charge cooldowns display correctly

---

### Step 4.2: Implement Spell Activation Overlays (Proc Glows)

**Time**: 6-8 hours
**Priority**: HIGH (Retail only)

**Goal**: Show glowing proc effects when spells activate

**Implementation**:

```lua
-- Register spell overlay events (Retail only)
function LAB:RegisterOverlayEvents()
    if not WoWRetail then return end

    if not self.eventFrame then
        self.eventFrame = CreateFrame("Frame")
    end

    self.eventFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
    self.eventFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
end

-- Handle overlay events
function LAB:OnOverlayEvent(event, spellID)
    if event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" then
        self:ShowOverlayGlowForSpell(spellID)
    elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" then
        self:HideOverlayGlowForSpell(spellID)
    end
end

function LAB:ShowOverlayGlowForSpell(spellID)
    -- Update all buttons with this spell
    for button in pairs(self.buttons) do
        if button.UpdateFunctions and button.UpdateFunctions.GetSpellId then
            local buttonSpellID = button.UpdateFunctions.GetSpellId(button)
            if buttonSpellID == spellID then
                self:ShowOverlayGlow(button)
            end
        end
    end
end

function LAB:HideOverlayGlowForSpell(spellID)
    for button in pairs(self.buttons) do
        if button.UpdateFunctions and button.UpdateFunctions.GetSpellId then
            local buttonSpellID = button.UpdateFunctions.GetSpellId(button)
            if buttonSpellID == spellID then
                self:HideOverlayGlow(button)
            end
        end
    end
end

function LAB:ShowOverlayGlow(button)
    if not WoWRetail then return end
    if not button then return end

    if not button.SpellActivationAlert then
        button.SpellActivationAlert = CreateFrame("Frame", nil, button,
            "ActionBarButtonSpellActivationAlert")
        button.SpellActivationAlert:SetAllPoints()
        button.SpellActivationAlert:Hide()
    end

    button.SpellActivationAlert:Show()
end

function LAB:HideOverlayGlow(button)
    if button and button.SpellActivationAlert then
        button.SpellActivationAlert:Hide()
    end
end

-- Update overlay state for a button
function LAB:UpdateSpellOverlay(button)
    if not WoWRetail then return end
    if not button or not button.UpdateFunctions then return end

    local spellID = button.UpdateFunctions.GetSpellId and button.UpdateFunctions.GetSpellId(button)
    if not spellID then
        self:HideOverlayGlow(button)
        return
    end

    -- Check if spell is overlayed
    local isOverlayed = false
    if LAB.Compat.C_SpellActivationOverlay and LAB.Compat.C_SpellActivationOverlay.IsSpellOverlayed then
        isOverlayed = LAB.Compat.C_SpellActivationOverlay.IsSpellOverlayed(spellID)
    elseif LAB.Compat.IsSpellOverlayed then
        isOverlayed = LAB.Compat.IsSpellOverlayed(spellID)
    end

    if isOverlayed then
        self:ShowOverlayGlow(button)
    else
        self:HideOverlayGlow(button)
    end
end
```

**Deliverable**: Proc glows working on Retail

---

### Step 4.3: Implement New Action Highlighting

**Time**: 4-6 hours
**Priority**: MEDIUM (Retail only)

**Goal**: Yellow glow on newly learned spells/items

**Implementation**:

```lua
function LAB:UpdateNewActionHighlight(button)
    if not WoWRetail then return end
    if not button or not button.UpdateFunctions then return end
    if not LAB.Compat.C_NewItems or not LAB.Compat.C_NewItems.IsNewItem then return end

    -- Get action info
    local actionType, id
    if button.UpdateFunctions.GetSpellId then
        id = button.UpdateFunctions.GetSpellId(button)
        actionType = "spell"
    end

    -- Check if using GetActionInfo
    if not id and button.buttonType == LAB.ButtonType.ACTION then
        actionType, id = GetActionInfo(button.buttonAction)
    end

    if not actionType or not id then
        if button.NewActionTexture then
            button.NewActionTexture:Hide()
        end
        return
    end

    -- Check if new
    local isNew = false
    if actionType == "spell" and Enum and Enum.NewItemType then
        isNew = LAB.Compat.C_NewItems.IsNewItem(id, Enum.NewItemType.Spell)
    elseif actionType == "item" and Enum and Enum.NewItemType then
        isNew = LAB.Compat.C_NewItems.IsNewItem(id, Enum.NewItemType.Item)
    end

    if isNew then
        if not button.NewActionTexture then
            button.NewActionTexture = button:CreateTexture(nil, "OVERLAY", nil, 1)
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

-- Register new item events
function LAB:RegisterNewItemEvents()
    if not WoWRetail then return end

    self.eventFrame:RegisterEvent("NEW_RECIPE_LEARNED")
    self.eventFrame:RegisterEvent("SPELL_UPDATE_ICON")
end
```

**Deliverable**: New action highlights working

---

### Step 4.4: Implement Equipped Item Borders

**Time**: 2-3 hours
**Priority**: MEDIUM

**Goal**: Green border on equipped items

**Implementation**:

```lua
function LAB:UpdateEquippedBorder(button)
    if not button or not button._border then return end
    if not button.UpdateFunctions or not button.UpdateFunctions.IsEquippedAction then return end

    local isEquipped = button.UpdateFunctions.IsEquippedAction(button)

    if isEquipped then
        button._border:SetVertexColor(0, 1.0, 0, 0.35)  -- Green
        button._border:Show()
    else
        -- Check if border should be shown for other reasons
        -- If not, hide it
        if not button.config or not button.config.showBorder then
            button._border:Hide()
        end
    end
end

-- Integrate into UpdateUsable
function LAB:UpdateUsable(button)
    if not button then return end

    local isUsable, notEnoughPower = false, false
    if button.UpdateFunctions and button.UpdateFunctions.IsUsableAction then
        isUsable, notEnoughPower = button.UpdateFunctions.IsUsableAction(button)
    end

    -- Update equipped border first
    self:UpdateEquippedBorder(button)

    -- Rest of usability logic...
    -- (existing code for range, power, usability coloring)
end
```

**Deliverable**: Equipped items show green border

---

### Step 4.5: Implement Cooldown Customization

**Time**: 3-4 hours
**Priority**: MEDIUM

**Goal**: Configurable cooldown display options

**Implementation**:

```lua
function LAB:ConfigureCooldown(button, config)
    if not button or not button._cooldown then return end

    config = config or button.config or {}

    -- Show/hide cooldown numbers
    if config.showCooldownNumbers ~= nil then
        button._cooldown:SetHideCountdownNumbers(not config.showCooldownNumbers)
    end

    -- Show/hide cooldown bling (finish animation)
    if config.showCooldownBling ~= nil then
        button._cooldown:SetDrawBling(config.showCooldownBling)
    end

    -- Show/hide cooldown edge
    if config.showCooldownEdge ~= nil then
        button._cooldown:SetDrawEdge(config.showCooldownEdge)
    end

    -- Show/hide cooldown swipe
    if config.showCooldownSwipe ~= nil then
        button._cooldown:SetDrawSwipe(config.showCooldownSwipe)
    end

    -- Reverse cooldown (fill instead of drain)
    if config.reverseCooldown ~= nil then
        button._cooldown:SetReverse(config.reverseCooldown)
    end

    -- Custom edge texture
    if config.cooldownEdgeTexture then
        button._cooldown:SetEdgeTexture(config.cooldownEdgeTexture)
    end

    -- Custom swipe color
    if config.cooldownSwipeColor then
        local c = config.cooldownSwipeColor
        button._cooldown:SetSwipeColor(c.r or 0, c.g or 0, c.b or 0, c.a or 0.8)
    end
end
```

**Deliverable**: Cooldown display fully customizable

---

### Step 4.6: Implement Assisted Combat Integration (Retail)

**Time**: 4-6 hours
**Priority**: LOW (Retail only, optional feature)

**Goal**: Rotation helper highlights

**Implementation**:

```lua
function LAB:UpdateAssistedCombat(button)
    if not WoWRetail then return end
    if not button then return end
    if not button.config or not button.config.assistedHighlight then return end

    -- Create assisted combat frame if needed
    if not button.AssistedCombatFrame then
        button.AssistedCombatFrame = CreateFrame("Frame", nil, button,
            "ActionBarButtonAssistedCombatRotationTemplate")
    end

    -- Check if button participates in assisted combat
    if button.buttonType ~= LAB.ButtonType.ACTION then
        button.AssistedCombatFrame:Hide()
        return
    end

    if not LAB.Compat.C_ActionBar or not LAB.Compat.C_ActionBar.IsAssistedCombatAction then
        button.AssistedCombatFrame:Hide()
        return
    end

    local isAssistedAction = LAB.Compat.C_ActionBar.IsAssistedCombatAction(button.buttonAction)
    if not isAssistedAction then
        button.AssistedCombatFrame:Hide()
        return
    end

    -- Check if this is the recommended spell
    local actionType, id = GetActionInfo(button.buttonAction)
    if actionType == "spell" and AssistedCombatManager then
        if id == AssistedCombatManager.lastNextCastSpellID then
            button.AssistedCombatFrame:Show()
        else
            button.AssistedCombatFrame:Hide()
        end
    else
        button.AssistedCombatFrame:Hide()
    end
end

-- Register assisted combat events
function LAB:RegisterAssistedCombatEvents()
    if not WoWRetail or not EventRegistry then return end

    EventRegistry:RegisterCallback(
        "AssistedCombatManager.OnAssistedHighlightSpellChange",
        function()
            for button in pairs(self.buttons) do
                self:UpdateAssistedCombat(button)
            end
        end,
        self
    )
end
```

**Deliverable**: Rotation helper integration (Retail)

---

### Step 4.7: Utilize Template Visual Elements

**Time**: 3-4 hours
**Priority**: MEDIUM

**Goal**: Use SpellHighlightTexture and other template elements

**Implementation**:

```lua
function LAB:InitializeTemplateElements(button)
    if not button then return end

    local name = button:GetName()

    -- Get template elements
    button.SpellHighlightTexture = _G[name .. "SpellHighlightTexture"]
    button.SpellHighlightAnim = _G[name .. "SpellHighlightAnim"]
    button.FlyoutArrowContainer = _G[name .. "FlyoutArrowContainer"]

    if WoWRetail then
        button.SpellCastAnimFrame = _G[name .. "SpellCastAnimFrame"]
    end

    -- Configure spell highlight
    if button.SpellHighlightTexture then
        button.SpellHighlightTexture:Hide()  -- Hide by default
    end

    -- Configure flyout arrow
    if button.FlyoutArrowContainer then
        button.FlyoutArrowContainer:Hide()  -- Hide by default
    end
end
```

**Deliverable**: Template elements initialized and available

---

### Step 4.8: Phase 4 Testing

**Time**: 4-6 hours
**Priority**: HIGH

**Test visual features**:

```lua
-- Test charge cooldowns (Fire Blast for mage)
/run local LAB = LibStub("LibTotalActionButtons-1.0")
/run local btn = LAB:CreateSpellButton(133, "TestCharges", UIParent)
/run btn:SetPoint("CENTER")
-- Use Fire Blast and verify charge cooldown shows

-- Test proc glows (Retail, need reactive spell)
/run local btn2 = LAB:CreateSpellButton(53385, "TestGlow", UIParent)
/run btn2:SetPoint("CENTER", 50, 0)
-- Trigger Ret Paladin proc and verify glow

-- Test new action highlight
-- Learn new spell, verify yellow glow appears

-- Test equipped border
/run local btn3 = LAB:CreateItemButton(19019, "TestEquipped", UIParent)
/run btn3:SetPoint("CENTER", -50, 0)
-- Equip Thunderfury, verify green border

-- Test cooldown customization
/run btn.config = { showCooldownNumbers = false, showCooldownBling = false }
/run LAB:ConfigureCooldown(btn, btn.config)
```

**Deliverable**: All visual enhancements tested

---

### Phase 4 Completion Checklist

- [ ] Charge cooldown frame created
- [ ] Charge cooldowns display correctly
- [ ] Spell overlay events registered (Retail)
- [ ] Proc glows working (Retail)
- [ ] New action highlights working (Retail)
- [ ] Equipped item borders showing
- [ ] Cooldown customization working
- [ ] Assisted combat integrated (Retail)
- [ ] Template elements utilized
- [ ] All visual tests passing
- [ ] Documentation updated

**Time to Complete Phase 4**: 2-3 weeks

**Next Phase**: Phase 5 - Interaction Systems

---

