--[[
    LibTotalActionButtons - TotalUI Action Button Library
    Copyright (c) 2024 TotalUI

    This is TotalUI's custom implementation of action buttons.
    NOT derived from LibActionButton-1.0.

    Handles creation and management of action bar buttons with proper:
    - Action execution and drag/drop
    - Cooldown displays
    - Range/power/usability states
    - Keybind display
    - Count/macro text
    - Paging support
--]]

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
    LAB.buttons = LAB.buttons or {}
    LAB.activeButtons = LAB.activeButtons or {}
else
    LAB.buttons = {}
    LAB.activeButtons = {}
end

-- Version info
LAB.VERSION = MINOR_VERSION
LAB.VERSION_STRING = string.format("%s (v%d)", MAJOR_VERSION, MINOR_VERSION)

-----------------------------------
-- WOW VERSION DETECTION
-----------------------------------

-- Detect WoW version (Phase 1 Step 1.2)
local WoWRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
local WoWClassic = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)
local WoWBCC = (WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC)
local WoWWrath = (WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC)
local WoWCata = (WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC)

-- Store in library
LAB.WoWRetail = WoWRetail
LAB.WoWClassic = WoWClassic
LAB.WoWBCC = WoWBCC
LAB.WoWWrath = WoWWrath
LAB.WoWCata = WoWCata

-- Determine version string for display
local versionType
if WoWRetail then
    versionType = "Retail"
elseif WoWCata then
    versionType = "Cataclysm Classic"
elseif WoWWrath then
    versionType = "Wrath Classic"
elseif WoWBCC then
    versionType = "TBC Classic"
elseif WoWClassic then
    versionType = "Classic Era"
else
    versionType = "Unknown"
end

LAB.VERSION_INFO = {
    detectedVersion = versionType,
    isRetail = WoWRetail,
    isClassic = not WoWRetail,
}

-----------------------------------
-- API COMPATIBILITY WRAPPERS
-----------------------------------

-- Retail-only APIs with safe fallbacks (Phase 1 Step 1.3)
local GetActionCharges = GetActionCharges or function() return nil end
local GetActionLossOfControlCooldown = GetActionLossOfControlCooldown or function() return nil end

-- GetSpellCharges moved to C_Spell in 11.x
local GetSpellCharges
if C_Spell and C_Spell.GetSpellCharges then
    GetSpellCharges = function(spellID)
        local chargeInfo = C_Spell.GetSpellCharges(spellID)
        if chargeInfo then
            return chargeInfo.currentCharges, chargeInfo.maxCharges, chargeInfo.cooldownStartTime, chargeInfo.cooldownDuration
        end
        return nil
    end
elseif GetSpellCharges then
    -- Older Retail versions
    GetSpellCharges = GetSpellCharges
else
    -- Classic fallback
    GetSpellCharges = function() return nil end
end

local GetSpellLossOfControlCooldown = GetSpellLossOfControlCooldown or function() return nil end
local GetSpellCount = GetSpellCount or function() return 0 end
local GetItemCharges = GetItemCharges or function() return nil end

-- Pickup functions moved to C_Spell/C_Item in 11.x
local PickupSpellCompat
if C_Spell and C_Spell.PickupSpell then
    PickupSpellCompat = C_Spell.PickupSpell
elseif PickupSpell then
    PickupSpellCompat = PickupSpell
else
    PickupSpellCompat = function() end
end

local PickupItemCompat
if C_Item and C_Item.PickupItem then
    PickupItemCompat = C_Item.PickupItem
elseif PickupItem then
    PickupItemCompat = PickupItem
else
    PickupItemCompat = function() end
end

-- PickupMacro still exists as global
local PickupMacroCompat = PickupMacro or function() end

-- C_ActionBar API compatibility (Retail)
local C_ActionBarCompat = {}
if C_ActionBar then
    C_ActionBarCompat = C_ActionBar
else
    -- Classic fallbacks
    C_ActionBarCompat.IsAssistedCombatAction = function() return false end
    C_ActionBarCompat.SetActionUIButton = function() end
end

-- C_SpellActivationOverlay API compatibility (Retail)
local C_SpellActivationOverlayCompat = {}
if C_SpellActivationOverlay then
    C_SpellActivationOverlayCompat = C_SpellActivationOverlay
else
    -- Classic fallbacks
    C_SpellActivationOverlayCompat.IsSpellOverlayed = function() return false end
end

-- C_NewItems API compatibility (Retail)
local C_NewItemsCompat = {}
if C_NewItems then
    C_NewItemsCompat = C_NewItems
else
    -- Classic fallbacks
    C_NewItemsCompat.IsNewItem = function() return false end
    C_NewItemsCompat.RemoveNewItem = function() end
end

-- GetSpellInfo compatibility (Modern Retail uses C_Spell.GetSpellInfo)
local GetSpellInfoCompat
if C_Spell and C_Spell.GetSpellInfo then
    -- Modern Retail API returns a table
    GetSpellInfoCompat = function(spellID)
        local spellInfo = C_Spell.GetSpellInfo(spellID)
        if spellInfo then
            -- Return values matching classic GetSpellInfo signature
            return spellInfo.name, nil, spellInfo.iconID, spellInfo.castTime,
                   spellInfo.minRange, spellInfo.maxRange, spellInfo.spellID,
                   spellInfo.originalIconID
        end
        return nil
    end
else
    -- Classic or older Retail
    GetSpellInfoCompat = GetSpellInfo or function() return nil end
end

-- GetSpellTexture compatibility (Modern Retail uses C_Spell.GetSpellTexture)
local GetSpellTextureCompat
if C_Spell and C_Spell.GetSpellTexture then
    -- Modern Retail API
    GetSpellTextureCompat = function(spellID)
        return C_Spell.GetSpellTexture(spellID)
    end
else
    -- Classic or older Retail
    GetSpellTextureCompat = GetSpellTexture or function() return nil end
end

-- GetSpellCooldown compatibility (Modern Retail uses C_Spell.GetSpellCooldown)
local GetSpellCooldownCompat
if C_Spell and C_Spell.GetSpellCooldown then
    -- Modern Retail API returns a table
    GetSpellCooldownCompat = function(spellID)
        local cooldownInfo = C_Spell.GetSpellCooldown(spellID)
        if cooldownInfo then
            return cooldownInfo.startTime, cooldownInfo.duration, cooldownInfo.isEnabled, cooldownInfo.modRate
        end
        return 0, 0, 1, 1
    end
else
    -- Classic or older Retail
    GetSpellCooldownCompat = GetSpellCooldown or function() return 0, 0, 1, 1 end
end

-- IsUsableSpell compatibility (Modern Retail uses C_Spell.IsSpellUsable)
local IsUsableSpellCompat
if C_Spell and C_Spell.IsSpellUsable then
    -- Modern Retail API returns a SpellUsableInfo table
    IsUsableSpellCompat = function(spellID)
        local usableInfo = C_Spell.IsSpellUsable(spellID)
        if type(usableInfo) == "table" then
            -- Modern Retail: returns table with isUsable and insufficientPower fields
            return usableInfo.isUsable or false, usableInfo.insufficientPower or false
        elseif type(usableInfo) == "boolean" then
            -- Fallback: if it returns a boolean directly
            return usableInfo, false
        end
        return false, false
    end
else
    -- Classic or older Retail
    IsUsableSpellCompat = IsUsableSpell or function() return false, false end
end

-- IsSpellInRange compatibility (Modern Retail uses C_Spell.IsSpellInRange)
local IsSpellInRangeCompat
if C_Spell and C_Spell.IsSpellInRange then
    -- Modern Retail API
    IsSpellInRangeCompat = function(spellID, unit)
        -- C_Spell.IsSpellInRange returns true/false/nil directly
        return C_Spell.IsSpellInRange(spellID, unit)
    end
else
    -- Classic or older Retail - uses slot-based API
    IsSpellInRangeCompat = IsSpellInRange or function() return nil end
end

-- Store compatibility wrappers
LAB.Compat = {
    GetActionCharges = GetActionCharges,
    GetActionLossOfControlCooldown = GetActionLossOfControlCooldown,
    GetSpellCharges = GetSpellCharges,
    GetSpellLossOfControlCooldown = GetSpellLossOfControlCooldown,
    GetSpellCount = GetSpellCount,
    GetItemCharges = GetItemCharges,
    PickupSpell = PickupSpellCompat,
    PickupItem = PickupItemCompat,
    PickupMacro = PickupMacroCompat,
    GetSpellInfo = GetSpellInfoCompat,
    GetSpellTexture = GetSpellTextureCompat,
    GetSpellCooldown = GetSpellCooldownCompat,
    IsUsableSpell = IsUsableSpellCompat,
    IsSpellInRange = IsSpellInRangeCompat,
    C_ActionBar = C_ActionBarCompat,
    C_SpellActivationOverlay = C_SpellActivationOverlayCompat,
    C_NewItems = C_NewItemsCompat,
    IsSpellOverlayed = IsSpellOverlayed,  -- Classic has global function
}

-----------------------------------
-- DEBUG & LOGGING SYSTEM
-----------------------------------

-- Debug mode (Phase 1 Step 1.4.1)
LAB.debug = false

function LAB:SetDebug(enabled)
    self.debug = enabled
    if enabled then
        print("|cffff9900[LTAB]|r Debug mode enabled")
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

-----------------------------------
-- VALIDATION HELPERS
-----------------------------------

-- Parameter validation (Phase 1 Step 1.4.2)
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
    if value == nil then
        LAB:Error(string.format("%s: %s is required!", functionName, name), 3)
        return false
    end
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
    if value == nil then
        LAB:Error(string.format("%s: %s is required!", functionName, name), 3)
        return false
    end
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

-----------------------------------
-- COMBAT LOCKDOWN HELPERS
-----------------------------------

-- Combat lockdown checks (Phase 1 Step 1.4.3)
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

-----------------------------------
-- MAINTAIN TOTALUI COMPATIBILITY
-----------------------------------

-- Keep reference in TotalUI namespace for backward compatibility
local AddonName, ns = ...
if ns and ns.public then
    local E = ns.public
    E.Libs = E.Libs or {}
    E.Libs.LibTotalActionButtons = LAB
end

-- Debug: Confirm loading
print(string.format("|cff1784d1TotalUI|r: %s loaded (%s)", LAB.VERSION_STRING, versionType))

-----------------------------------
-- CONSTANTS
-----------------------------------

-- Button type enum (Phase 2 Step 2.1)
LAB.ButtonType = {
    ACTION = "action",
    SPELL = "spell",
    ITEM = "item",
    MACRO = "macro",
    CUSTOM = "custom",
    EMPTY = "empty",
}

-----------------------------------
-- BUTTON TYPE: ACTION (Phase 2 Step 2.2)
-----------------------------------

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
        return LAB.Compat.GetActionLossOfControlCooldown(self.buttonAction)
    end,

    -- Spell ID for proc detection
    GetSpellId = function(self)
        local actionType, id = GetActionInfo(self.buttonAction)
        if actionType == "spell" or actionType == "macro" then
            return id
        end
        return nil
    end,
}

LAB.ActionTypeUpdateFunctions = ActionTypeUpdateFunctions

-----------------------------------
-- BUTTON TYPE: SPELL (Phase 2 Step 2.3)
-----------------------------------

-- Helper: Find spell in spellbook
-- Cache global function before defining local version (to avoid infinite recursion)
local FindSpellBookSlotBySpellID_Global = _G.FindSpellBookSlotBySpellID
local function FindSpellBookSlotBySpellID(spellID)
    if not spellID then return nil end

    if WoWRetail and FindSpellBookSlotBySpellID_Global then
        -- Retail has built-in function
        return FindSpellBookSlotBySpellID_Global(spellID, false)
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
        -- Check if spell ID is valid
        if not self.buttonAction or self.buttonAction == 0 then
            return false
        end
        -- Check if spell exists
        local name = LAB.Compat.GetSpellInfo(self.buttonAction)
        return name ~= nil
    end,

    GetActionTexture = function(self)
        if not self.buttonAction or self.buttonAction == 0 then
            return nil
        end
        local texture = LAB.Compat.GetSpellTexture(self.buttonAction)
        if not texture then
            LAB:DebugPrint("GetActionTexture: Invalid spell ID", self.buttonAction)
        end
        return texture
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
        if not self.buttonAction or self.buttonAction == 0 then
            return nil
        end

        -- Modern Retail: Use spell ID directly
        if WoWRetail and LAB.Compat.IsSpellInRange then
            local inRange = LAB.Compat.IsSpellInRange(self.buttonAction, "target")
            -- Modern API returns true/false/nil directly
            return inRange
        end

        -- Classic: Find spell slot first
        local slot = FindSpellBookSlotBySpellID(self.buttonAction)
        if slot and LAB.Compat.IsSpellInRange then
            local inRange = LAB.Compat.IsSpellInRange(slot, BOOKTYPE_SPELL, "target")
            if inRange == 1 then
                return true
            elseif inRange == 0 then
                return false
            end
        end
        return nil
    end,

    IsUsableAction = function(self)
        if not self.buttonAction or self.buttonAction == 0 then
            return false, false
        end
        return LAB.Compat.IsUsableSpell(self.buttonAction)
    end,

    IsCurrentAction = function(self)
        if not self.buttonAction or self.buttonAction == 0 then
            return false
        end
        return IsCurrentSpell(self.buttonAction)
    end,

    IsAutoRepeatAction = function(self)
        if not self.buttonAction or self.buttonAction == 0 then
            return false
        end
        local slot = FindSpellBookSlotBySpellID(self.buttonAction)
        if slot then
            return IsAutoRepeatSpell(slot, BOOKTYPE_SPELL)
        end
        return false
    end,

    IsAttackAction = function(self)
        if not self.buttonAction or self.buttonAction == 0 then
            return false
        end
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
        if not self.buttonAction or self.buttonAction == 0 then
            return false
        end
        return IsConsumableSpell(self.buttonAction)
    end,

    GetCooldown = function(self)
        if not self.buttonAction or self.buttonAction == 0 then
            return 0, 0, 1, 1
        end
        return LAB.Compat.GetSpellCooldown(self.buttonAction)
    end,

    GetLossOfControlCooldown = function(self)
        if not self.buttonAction or self.buttonAction == 0 then
            return nil
        end
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

-----------------------------------
-- BUTTON TYPE: ITEM (Phase 2 Step 2.4)
-----------------------------------

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

-----------------------------------
-- BUTTON TYPE: MACRO (Phase 2 Step 2.5)
-----------------------------------

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

-- Action button state colors
LAB.COLORS = {
    NORMAL = {1, 1, 1},
    OUT_OF_RANGE = {0.8, 0.1, 0.1},
    OUT_OF_POWER = {0.1, 0.3, 0.8},
    NOT_USABLE = {0.4, 0.4, 0.4},
}

-- Events that require button updates
LAB.UPDATE_EVENTS = {
    "ACTIONBAR_SLOT_CHANGED",
    "ACTIONBAR_UPDATE_COOLDOWN",
    "ACTIONBAR_UPDATE_STATE",
    "ACTIONBAR_UPDATE_USABLE",
    "PLAYER_TARGET_CHANGED",
    "PLAYER_ENTERING_WORLD",
    "UPDATE_BINDINGS",
    "UPDATE_SHAPESHIFT_FORM",
    "SPELL_UPDATE_CHARGES",
    "SPELL_UPDATE_USABLE",
    "SPELL_UPDATE_COOLDOWN",
    "PLAYER_EQUIPMENT_CHANGED",
    "LEARNED_SPELL_IN_TAB",
    "UPDATE_MACROS",
    "UNIT_POWER_FREQUENT",
    "UNIT_AURA",
}

-----------------------------------
-- BUTTON CREATION
-----------------------------------

function LAB:CreateButton(actionID, name, parent, config, skipUpdate)
    -- Validate parameters (Phase 1 Step 1.4.4)
    if not LAB.Validate.Number(actionID, "actionID", "CreateButton", 1) then
        return nil
    end

    if not LAB.Validate.String(name, "name", "CreateButton", false) then
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

    self:DebugPrint(string.format("Creating button: %s (action %d)", name, actionID))

    -- Create the button frame using Blizzard's secure template (Phase 1 Step 1.1 - FIX)
    -- We need BOTH ActionBarButtonTemplate (for visuals) AND SecureActionButtonTemplate (for secure actions)
    local button = CreateFrame("CheckButton", name, parent, "ActionBarButtonTemplate, SecureActionButtonTemplate")

    if not button then
        self:Error("CreateButton: Failed to create button frame!", 2)
        return nil
    end

    -- Store button data
    button.id = actionID
    button.config = config or {}
    button.actionID = actionID

    -- Phase 2: Button type system
    button.buttonType = LAB.ButtonType.ACTION  -- Default to action type
    button.buttonAction = actionID
    button.UpdateFunctions = LAB.ActionTypeUpdateFunctions  -- Phase 2 Step 2.2

    -- Initialize button
    self:InitializeButton(button)
    self:SetupButtonAction(button, actionID)
    self:StyleButton(button, config)
    self:RegisterButton(button)

    -- Initial update for action buttons (type-specific buttons skip and do their own update)
    if not skipUpdate then
        self:UpdateButton(button)
    end

    return button
end

function LAB:InitializeButton(button)
    -- Get references to button elements
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

    -- Initialize state
    button._state = {
        hasAction = false,
        inRange = true,
        hasPower = true,
        usable = true,
    }

    -- Initialize state management system (Phase 3)
    button.currentState = "0"  -- Default to state 0
    button.stateTypes = {}     -- Maps state -> button type
    button.stateActions = {}   -- Maps state -> action/spell/item ID

    -- Initialize click behavior (Phase 5)
    -- Default to false (click-on-up), matching WoW's default behavior
    button._clickOnDown = false
    button:SetAttribute('useOnKeyDown', false)

    -- Set up scripts
    self:SetupButtonScripts(button)
end

function LAB:SetupButtonAction(button, actionID)
    -- Set the action on the button (makes it respond to the action slot)
    button:SetAttribute("type", "action")
    button:SetAttribute("action", actionID)

    -- Store action ID
    button.action = actionID
end

function LAB:SetupButtonScripts(button)
    -- OnUpdate for range checking
    button:SetScript("OnUpdate", function(self, elapsed)
        LAB:OnButtonUpdate(self, elapsed)
    end)

    -- OnEvent for action updates
    button:SetScript("OnEvent", function(self, event, ...)
        LAB:OnButtonEvent(self, event, ...)
    end)

    -- OnEnter for tooltips
    button:SetScript("OnEnter", function(self)
        LAB:OnButtonEnter(self)
    end)

    -- OnLeave for tooltips
    button:SetScript("OnLeave", function(self)
        LAB:OnButtonLeave(self)
    end)

    -- Phase 5: Drag & Drop scripts
    button:SetScript("OnDragStart", function(self)
        LAB:OnDragStart(self)
    end)

    button:SetScript("OnReceiveDrag", function(self)
        LAB:OnReceiveDrag(self)
    end)

    -- Phase 5: Visual feedback fixes for click-on-down
    -- These hooks prevent the pushed texture from getting stuck
    button:HookScript("OnMouseDown", function(self)
        if self._clickOnDown and self:GetPushedTexture() then
            self:GetPushedTexture():SetAlpha(1)
        end
    end)

    button:HookScript("OnMouseUp", function(self)
        if self._clickOnDown and self:GetPushedTexture() then
            self:GetPushedTexture():SetAlpha(0)
        end
    end)

    -- Enable drag by default
    LAB:EnableDragNDrop(button, true)
end

function LAB:RegisterButton(button)
    -- Add to registry
    table.insert(self.buttons, button)
    self.activeButtons[button] = true

    -- Register for events
    for _, event in ipairs(self.UPDATE_EVENTS) do
        button:RegisterEvent(event)
    end

    -- NOTE: Initial update is done by type-specific creation functions
    -- Don't call UpdateButton here because UpdateFunctions may not be set yet
end

-----------------------------------
-- TYPE-SPECIFIC BUTTON CREATION (Phase 2 Steps 2.3-2.6)
-----------------------------------

function LAB:CreateSpellButton(spellID, name, parent, config)
    if not LAB.Validate.Number(spellID, "spellID", "CreateSpellButton", 1) then
        return nil
    end

    -- Validate spell exists
    local spellName = LAB.Compat.GetSpellInfo(spellID)
    if not spellName then
        self:Warning(string.format("CreateSpellButton: Spell ID %d does not exist or is not known by this character", spellID))
        -- Still create the button, but it will be empty until spell is learned
    end

    self:DebugPrint(string.format("Creating spell button: %s (spell %d: %s)", name, spellID, spellName or "Unknown"))

    -- Create base button (skip initial update, we'll do it after setting UpdateFunctions)
    local button = self:CreateButton(spellID, name, parent, config, true)
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

function LAB:CreateItemButton(itemID, name, parent, config)
    if not LAB.Validate.Number(itemID, "itemID", "CreateItemButton", 1) then
        return nil
    end

    self:DebugPrint(string.format("Creating item button: %s (item %d)", name, itemID))

    -- Create base button (skip initial update, we'll do it after setting UpdateFunctions)
    local button = self:CreateButton(itemID, name, parent, config, true)
    if not button then return nil end

    button.buttonType = LAB.ButtonType.ITEM
    button.buttonAction = itemID
    button.UpdateFunctions = LAB.ItemTypeUpdateFunctions

    button:SetAttribute("type", "item")
    button:SetAttribute("item", itemID)

    self:UpdateButton(button)
    return button
end

function LAB:CreateMacroButton(macroID, name, parent, config)
    if not LAB.Validate.Number(macroID, "macroID", "CreateMacroButton", 1) then
        return nil
    end

    self:DebugPrint(string.format("Creating macro button: %s (macro %d)", name, macroID))

    -- Create base button (skip initial update, we'll do it after setting UpdateFunctions)
    local button = self:CreateButton(macroID, name, parent, config, true)
    if not button then return nil end

    button.buttonType = LAB.ButtonType.MACRO
    button.buttonAction = macroID
    button.UpdateFunctions = LAB.MacroTypeUpdateFunctions

    button:SetAttribute("type", "macro")
    button:SetAttribute("macro", macroID)

    self:UpdateButton(button)
    return button
end

function LAB:CreateCustomButton(id, name, parent, config, updateFunctions)
    if not LAB.Validate.Number(id, "id", "CreateCustomButton", 1) then
        return nil
    end

    if not updateFunctions or type(updateFunctions) ~= "table" then
        self:Error("CreateCustomButton: updateFunctions must be a table!", 2)
        return nil
    end

    self:DebugPrint(string.format("Creating custom button: %s (id %d)", name, id))

    -- Create base button (skip initial update, we'll do it after setting UpdateFunctions)
    local button = self:CreateButton(id, name, parent, config, true)
    if not button then return nil end

    button.buttonType = LAB.ButtonType.CUSTOM
    button.buttonAction = id
    button.UpdateFunctions = updateFunctions

    -- Custom buttons require user to set attributes
    -- No automatic attribute setting

    self:UpdateButton(button)
    return button
end

-----------------------------------
-- BUTTON STYLING
-----------------------------------

function LAB:SetButtonSize(button, width, height)
    if not button then return end

    height = height or width

    -- Set the main button frame size
    button:SetSize(width, height)

    -- Resize all child elements to match
    if button._icon then
        button._icon:SetSize(width, height)
    end

    if button._border then
        button._border:SetSize(width, height)
    end

    if button._flash then
        button._flash:SetSize(width, height)
    end

    if button._normalTexture then
        button._normalTexture:SetSize(width, height)
    end

    if button._highlight then
        -- Make highlight cover the entire button
        button._highlight:ClearAllPoints()
        button._highlight:SetAllPoints(button)
    end

    -- Phase 1 Step 1.6: Fix pushed texture alignment
    -- Anchor to icon for proper alignment instead of button
    if button._pushedTexture and button._icon then
        button._pushedTexture:ClearAllPoints()
        button._pushedTexture:SetAllPoints(button._icon)
    end

    -- Cooldown frame needs to match icon size for proper coverage
    if button._cooldown and button._icon then
        button._cooldown:ClearAllPoints()
        button._cooldown:SetAllPoints(button._icon)
    end

    -- Store the size in the button for later reference
    button._width = width
    button._height = height
end

function LAB:StyleButton(button, config)
    config = config or button.config or {}

    -- Icon cropping
    if button._icon then
        button._icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end

    -- Hide/show elements based on config
    if config.hideElements then
        if config.hideElements.hotkey and button._hotkey then
            button._hotkey:Hide()
        end
        if config.hideElements.macro and button._name then
            button._name:Hide()
        end
    end

    -- Apply text styling
    if config.text then
        self:ApplyTextConfig(button, config.text)
    end

    -- Apply colors
    if config.colors then
        button._colors = config.colors
    else
        button._colors = {
            range = self.COLORS.OUT_OF_RANGE,
            mana = self.COLORS.OUT_OF_POWER,
            unusable = self.COLORS.NOT_USABLE,
        }
    end

    -- Show grid
    if config.showGrid ~= nil then
        button._showGrid = config.showGrid
    end

    -- Remove default background if configured
    if button._normalTexture then
        button._normalTexture:SetTexture(nil)
        button._normalTexture:SetAlpha(0)
    end

    -- Handle floating background
    local floatingBG = _G[button:GetName() .. "FloatingBG"]
    if floatingBG then
        floatingBG:Hide()
    end
end

function LAB:ApplyTextConfig(button, textConfig)
    -- Hotkey text
    if textConfig.hotkey and button._hotkey then
        local hk = textConfig.hotkey
        if hk.font and hk.font.font then
            button._hotkey:SetFont(hk.font.font, hk.font.size or 12, hk.font.flags or "OUTLINE")
        end
        if hk.color then
            button._hotkey:SetTextColor(hk.color[1] or 1, hk.color[2] or 1, hk.color[3] or 1)
        end
        if hk.position then
            button._hotkey:ClearAllPoints()
            button._hotkey:SetPoint(
                hk.position.anchor or "TOPRIGHT",
                button,
                hk.position.relAnchor or "TOPRIGHT",
                hk.position.offsetX or 0,
                hk.position.offsetY or 0
            )
        end
    end

    -- Count text
    if textConfig.count and button._count then
        local ct = textConfig.count
        if ct.font and ct.font.font then
            button._count:SetFont(ct.font.font, ct.font.size or 14, ct.font.flags or "OUTLINE")
        end
        if ct.color then
            button._count:SetTextColor(ct.color[1] or 1, ct.color[2] or 1, ct.color[3] or 1)
        end
        if ct.position then
            button._count:ClearAllPoints()
            button._count:SetPoint(
                ct.position.anchor or "BOTTOMRIGHT",
                button,
                ct.position.relAnchor or "BOTTOMRIGHT",
                ct.position.offsetX or 0,
                ct.position.offsetY or 0
            )
        end
    end

    -- Macro text
    if textConfig.macro and button._name then
        local mc = textConfig.macro
        if mc.font and mc.font.font then
            button._name:SetFont(mc.font.font, mc.font.size or 12, mc.font.flags or "NONE")
        end
        if mc.color then
            button._name:SetTextColor(mc.color[1] or 1, mc.color[2] or 1, mc.color[3] or 1)
        end
        if mc.position then
            button._name:ClearAllPoints()
            button._name:SetPoint(
                mc.position.anchor or "BOTTOM",
                button,
                mc.position.relAnchor or "BOTTOM",
                mc.position.offsetX or 0,
                mc.position.offsetY or 0
            )
        end
    end
end

-----------------------------------
-- STATE MANAGEMENT (Phase 3)
-----------------------------------

--[[
    State Management System

    Buttons can have multiple "states" that determine their current action.
    Each state can have a different button type and action.

    Common use cases:
    - Action bar paging (Page 1, Page 2, etc.)
    - Stance/form switching (Warrior stances, Druid forms)
    - Vehicle/possess bars

    State "0" is the default/fallback state.

    Example:
        LAB:SetState(button, 0, "action", 1)      -- Default: Action slot 1
        LAB:SetState(button, 1, "spell", 133)     -- Stance 1: Fireball
        LAB:SetState(button, 2, "item", 6948)     -- Stance 2: Hearthstone
        LAB:UpdateState(button, 1)                 -- Switch to stance 1
]]

--- Set the action for a specific state
-- @param button The button to configure
-- @param state The state identifier (0 = default)
-- @param buttonType The button type for this state ("action", "spell", "item", "macro", "custom")
-- @param action The action ID for this state
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

    -- Set secure state attributes for proper click functionality
    if buttonType and action then
        -- Map button type to secure attribute type
        local secureType = buttonType
        if buttonType == LAB.ButtonType.ACTION then
            button:SetAttribute(string.format("*type-s%s", state), "action")
            button:SetAttribute(string.format("*action-s%s", state), action)
        elseif buttonType == LAB.ButtonType.SPELL then
            button:SetAttribute(string.format("*type-s%s", state), "spell")
            button:SetAttribute(string.format("*spell-s%s", state), action)
        elseif buttonType == LAB.ButtonType.ITEM then
            button:SetAttribute(string.format("*type-s%s", state), "item")
            button:SetAttribute(string.format("*item-s%s", state), action)
        elseif buttonType == LAB.ButtonType.MACRO then
            button:SetAttribute(string.format("*type-s%s", state), "macro")
            button:SetAttribute(string.format("*macro-s%s", state), action)
        end
    else
        -- Clear state (empty)
        button:SetAttribute(string.format("*type-s%s", state), nil)
    end

    self:DebugPrint(string.format("SetState: button=%s, state=%s, type=%s, action=%s",
        button:GetName() or "unnamed", state, tostring(buttonType), tostring(action)))

    -- If this is the current state, update the button display
    if not button.currentState then
        button.currentState = "0"
    end
    if button.currentState == state then
        self:UpdateButtonState(button)
    end
end

--- Get the action configured for a specific state
-- If no state is provided, returns the current state
-- @param button The button to query
-- @param state Optional state identifier. If nil, returns current state
-- @return buttonType, action for the specified state, or just currentState if no state param
function LAB:GetState(button, state)
    if not LAB.Validate.Button(button, "GetState") then return nil end

    if not state then
        -- Return current state
        return button.currentState or "0"
    end

    -- Return specific state's type and action
    state = tostring(state)
    local stateType = button.stateTypes and button.stateTypes[state]
    local stateAction = button.stateActions and button.stateActions[state]

    return stateType, stateAction
end

--- Switch the button to a different state
-- @param button The button to update
-- @param newState The state to switch to (e.g., "1", "2")
function LAB:UpdateState(button, newState)
    if not LAB.Validate.Button(button, "UpdateState") then return end

    newState = tostring(newState or 0)

    local oldState = button.currentState or "0"
    button.currentState = newState

    -- Set secure attribute state for click handling
    button:SetAttribute("state", newState)

    self:DebugPrint(string.format("UpdateState: button=%s, old=%s, new=%s",
        button:GetName() or "unnamed", oldState, newState))

    -- Update button display for new state
    self:UpdateButtonState(button)
end

--- Internal: Update button display based on current state
-- This changes the button's type and action to match the current state
-- @param button The button to update
function LAB:UpdateButtonState(button)
    if not button then return end

    local state = button.currentState or "0"
    local buttonType, action = self:GetAction(button, state)

    self:DebugPrint(string.format("UpdateButtonState: button=%s, state=%s, type=%s, action=%s",
        button:GetName() or "unnamed", state, tostring(buttonType), tostring(action)))

    -- Update button type and action
    button.buttonType = buttonType or LAB.ButtonType.EMPTY
    button.buttonAction = action

    -- Update secure attributes for click handling
    if buttonType == LAB.ButtonType.ACTION then
        button:SetAttribute("type", "action")
        button:SetAttribute("action", action)
        button.UpdateFunctions = LAB.ActionTypeUpdateFunctions
    elseif buttonType == LAB.ButtonType.SPELL then
        button:SetAttribute("type", "spell")
        button:SetAttribute("spell", action)
        button.UpdateFunctions = LAB.SpellTypeUpdateFunctions
    elseif buttonType == LAB.ButtonType.ITEM then
        button:SetAttribute("type", "item")
        button:SetAttribute("item", "item:" .. tostring(action))
        button.UpdateFunctions = LAB.ItemTypeUpdateFunctions
    elseif buttonType == LAB.ButtonType.MACRO then
        button:SetAttribute("type", "macro")
        button:SetAttribute("macro", action)
        button.UpdateFunctions = LAB.MacroTypeUpdateFunctions
    else
        -- Empty or unknown type
        button:SetAttribute("type", nil)
        button.UpdateFunctions = {}
    end

    -- Update all visual elements for the new action
    self:UpdateButton(button)
end

--- Get the action for a specific state (or current state)
-- @param button The button to query
-- @param state Optional state identifier
-- @return buttonType, action
function LAB:GetAction(button, state)
    if not button then return LAB.ButtonType.EMPTY, nil end

    state = state or button.currentState or "0"
    state = tostring(state)

    -- Try to get state-specific action
    local stateType = button.stateTypes and button.stateTypes[state]
    local stateAction = button.stateActions and button.stateActions[state]

    -- If state has no action, fall back to default state "0"
    if not stateType and state ~= "0" then
        stateType = button.stateTypes and button.stateTypes["0"]
        stateAction = button.stateActions and button.stateActions["0"]
    end

    -- Final fallback to button's base type/action
    return stateType or button.buttonType or LAB.ButtonType.EMPTY,
           stateAction or button.buttonAction
end

--- Clear all states for a button
-- Resets the button to a single default state
-- @param button The button to clear
function LAB:ClearStates(button)
    if not LAB.Validate.Button(button, "ClearStates") then return end

    button.stateTypes = {}
    button.stateActions = {}
    button.currentState = "0"

    -- Clear secure state attributes
    for i = 0, 20 do
        local state = tostring(i)
        button:SetAttribute(string.format("*type-s%s", state), nil)
        button:SetAttribute(string.format("*action-s%s", state), nil)
        button:SetAttribute(string.format("*spell-s%s", state), nil)
        button:SetAttribute(string.format("*item-s%s", state), nil)
        button:SetAttribute(string.format("*macro-s%s", state), nil)
    end
    button:SetAttribute("state", "0")

    self:DebugPrint("ClearStates: button=" .. (button:GetName() or "unnamed"))
end

--- Enable paging for a button (responds to page changes)
-- @param button The button to configure
-- @param enable Boolean to enable/disable paging
function LAB:EnablePaging(button, enable)
    if not LAB.Validate.Button(button, "EnablePaging") then return end

    button.usePaging = enable

    if enable then
        -- Set initial state based on current page
        local page = GetActionBarPage and GetActionBarPage() or 1
        self:UpdateState(button, tostring(page))
        self:DebugPrint(string.format("EnablePaging: button=%s, initial page=%d",
            button:GetName() or "unnamed", page))
    else
        -- Reset to default state
        self:UpdateState(button, "0")
    end
end

--- Enable stance-based state switching
-- @param button The button to configure
-- @param enable Boolean to enable/disable stance switching
function LAB:EnableStanceState(button, enable)
    if not LAB.Validate.Button(button, "EnableStanceState") then return end

    button.useStance = enable

    if enable then
        -- Set initial state based on current stance/form
        local stance = GetShapeshiftForm and GetShapeshiftForm() or 0
        self:UpdateState(button, tostring(stance))
        self:DebugPrint(string.format("EnableStanceState: button=%s, initial stance=%d",
            button:GetName() or "unnamed", stance))
    else
        -- Reset to default state
        self:UpdateState(button, "0")
    end
end

--- Event handling for state changes
-- This should be called by TotalUI's action bar module when state-changing events occur
function LAB:OnPageChanged(newPage)
    newPage = newPage or (GetActionBarPage and GetActionBarPage() or 1)

    self:DebugPrint("OnPageChanged: newPage=" .. tostring(newPage))

    -- Update all buttons that use paging
    for _, button in pairs(self.buttons or {}) do
        if button.usePaging then
            self:UpdateState(button, tostring(newPage))
        end
    end
end

--- Event handling for stance/form changes
function LAB:OnStanceChanged()
    local stance = GetShapeshiftForm and GetShapeshiftForm() or 0

    self:DebugPrint("OnStanceChanged: stance=" .. tostring(stance))

    -- Update all buttons that use stance switching
    for _, button in pairs(self.buttons or {}) do
        if button.useStance then
            self:UpdateState(button, tostring(stance))
        end
    end
end

--- Event handling for bonus bar changes (possess, vehicle, etc.)
function LAB:OnBonusBarChanged()
    local bonusBar = GetBonusBarOffset and GetBonusBarOffset() or 0

    self:DebugPrint("OnBonusBarChanged: bonusBar=" .. tostring(bonusBar))

    -- Update all buttons that use bonus bar switching
    for _, button in pairs(self.buttons or {}) do
        if button.useBonusBar then
            self:UpdateState(button, tostring(bonusBar))
        end
    end
end

-----------------------------------
-- BUTTON UPDATES
-----------------------------------

function LAB:UpdateButton(button)
    if not button then return end

    self:UpdateAction(button)
    self:UpdateIcon(button)
    self:UpdateCount(button)
    self:UpdateCooldown(button)
    self:UpdateHotkey(button)
    self:UpdateUsable(button)
    self:UpdateRange(button)
    self:UpdateVisualState(button)
    self:UpdateGrid(button)
end

function LAB:UpdateAction(button)
    local action = button.action
    if not action then return end

    -- Use UpdateFunctions for type-specific HasAction check
    local hasAction
    if button.UpdateFunctions and button.UpdateFunctions.HasAction then
        hasAction = button.UpdateFunctions.HasAction(button)
    else
        hasAction = HasAction(action)
    end
    button._state.hasAction = hasAction

    if hasAction then
        -- Action exists
        if button._normalTexture then
            button._normalTexture:SetVertexColor(1, 1, 1, 1)
        end
    else
        -- No action
        if button._normalTexture then
            button._normalTexture:SetVertexColor(1, 1, 1, 0.5)
        end
    end
end

function LAB:UpdateIcon(button)
    if not button or not button._icon then return end

    -- Use UpdateFunctions if available (Phase 2)
    local texture
    if button.UpdateFunctions and button.UpdateFunctions.GetActionTexture then
        texture = button.UpdateFunctions.GetActionTexture(button)
    elseif button.action then
        -- Fallback to old method
        texture = GetActionTexture(button.action)
    end

    if texture then
        -- Modern Retail: texture IDs are numeric and need SetTextureFileID
        -- Classic: textures are string paths and use SetTexture
        if type(texture) == "number" then
            button._icon:SetTexture(texture)  -- SetTexture accepts numbers in modern APIs
        else
            button._icon:SetTexture(texture)
        end
        button._icon:Show()
    else
        button._icon:SetTexture(nil)
        button._icon:Hide()
    end
end

function LAB:UpdateCount(button)
    if not button or not button._count then return end

    -- Use UpdateFunctions if available (Phase 2)
    local count
    if button.UpdateFunctions and button.UpdateFunctions.GetActionCount then
        count = button.UpdateFunctions.GetActionCount(button)
    elseif button.action then
        -- Fallback to old method
        count = GetActionCount(button.action)
    end

    if count and count > 1 then
        button._count:SetText(count)
        button._count:Show()
    else
        button._count:SetText("")
        button._count:Hide()
    end
end

--- Phase 4 Step 4.1: Create charge cooldown frame
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

--- Phase 4 Step 4.1: Enhanced cooldown update with charge support
function LAB:UpdateCooldown(button)
    if not button or not button._cooldown then return end

    local start, duration, enable, modRate
    local charges, maxCharges, chargeStart, chargeDuration

    -- Get cooldown data based on button type
    if button.UpdateFunctions and button.UpdateFunctions.GetCooldown then
        start, duration, enable, modRate = button.UpdateFunctions.GetCooldown(button)
    elseif button.action then
        start, duration, enable = GetActionCooldown(button.action)
    end

    if button.UpdateFunctions and button.UpdateFunctions.GetActionCharges then
        charges, maxCharges, chargeStart, chargeDuration = button.UpdateFunctions.GetActionCharges(button)
    elseif button.action and self.Compat and self.Compat.GetActionCharges then
        charges, maxCharges, chargeStart, chargeDuration = self.Compat.GetActionCharges(button.action)
    end

    -- Handle charge-based abilities
    if charges and maxCharges and maxCharges > 1 then
        -- Create charge cooldown frame if needed (Retail only)
        if not button.chargeCooldown and self.WoWRetail then
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

    -- Check for Loss of Control cooldown (takes priority) - Retail only
    if self.WoWRetail and button.UpdateFunctions and button.UpdateFunctions.GetLossOfControlCooldown then
        local locStart, locDuration = button.UpdateFunctions.GetLossOfControlCooldown(button)
        if locStart and locStart > 0 and locDuration and locDuration > 0 then
            button._cooldown:SetCooldown(locStart, locDuration)
            if button._cooldown.SetEdgeTexture then
                button._cooldown:SetEdgeTexture("Interface\\Cooldown\\edge-LoC")
            end
            if button._cooldown.SetSwipeColor then
                button._cooldown:SetSwipeColor(0.17, 0, 0)
            end
            button._cooldown.currentCooldownType = "LoC"
            button._cooldown:Show()
            return
        end
    end

    -- Normal cooldown
    if start and duration and enable == 1 and duration > 0 then
        button._cooldown:SetCooldown(start, duration)
        if button._cooldown.SetEdgeTexture then
            button._cooldown:SetEdgeTexture("Interface\\Cooldown\\edge")
        end
        if button._cooldown.SetSwipeColor then
            button._cooldown:SetSwipeColor(0, 0, 0, 0.8)
        end
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

-----------------------------------
-- SPELL ACTIVATION OVERLAYS (PROC GLOWS) - Phase 4 Step 4.2
-----------------------------------

--- Register spell overlay events (Retail only)
function LAB:RegisterOverlayEvents()
    if not self.WoWRetail then return end

    if not self.overlayEventFrame then
        self.overlayEventFrame = CreateFrame("Frame")
        self.overlayEventFrame:SetScript("OnEvent", function(frame, event, ...)
            LAB:OnOverlayEvent(event, ...)
        end)
    end

    self.overlayEventFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
    self.overlayEventFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
end

--- Handle overlay events
function LAB:OnOverlayEvent(event, spellID)
    if event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" then
        self:ShowOverlayGlowForSpell(spellID)
    elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" then
        self:HideOverlayGlowForSpell(spellID)
    end
end

--- Show overlay glow for all buttons with this spell
function LAB:ShowOverlayGlowForSpell(spellID)
    -- Update all buttons with this spell
    for _, button in pairs(self.buttons or {}) do
        if button.UpdateFunctions and button.UpdateFunctions.GetSpellId then
            local buttonSpellID = button.UpdateFunctions.GetSpellId(button)
            if buttonSpellID == spellID then
                self:ShowOverlayGlow(button)
            end
        end
    end
end

--- Hide overlay glow for all buttons with this spell
function LAB:HideOverlayGlowForSpell(spellID)
    for _, button in pairs(self.buttons or {}) do
        if button.UpdateFunctions and button.UpdateFunctions.GetSpellId then
            local buttonSpellID = button.UpdateFunctions.GetSpellId(button)
            if buttonSpellID == spellID then
                self:HideOverlayGlow(button)
            end
        end
    end
end

--- Show overlay glow on a button
function LAB:ShowOverlayGlow(button)
    if not self.WoWRetail then return end
    if not button then return end

    -- Create overlay glow if it doesn't exist
    if not button.overlay then
        local overlay = CreateFrame("Frame", nil, button)
        overlay:SetAllPoints()
        overlay:SetFrameLevel(button:GetFrameLevel() + 5)

        -- Create outer glow texture
        local outerGlow = overlay:CreateTexture(nil, "OVERLAY")
        outerGlow:SetAllPoints()
        outerGlow:SetTexture("Interface\\SpellActivationOverlay\\IconAlert")
        outerGlow:SetBlendMode("ADD")
        outerGlow:SetTexCoord(0.00781250, 0.50781250, 0.27734375, 0.52734375)

        -- Create animation group for pulsing effect
        local animGroup = outerGlow:CreateAnimationGroup()
        animGroup:SetLooping("REPEAT")

        -- Scale animation
        local scale1 = animGroup:CreateAnimation("Scale")
        scale1:SetScale(1.5, 1.5)
        scale1:SetDuration(0.2)
        scale1:SetOrder(1)

        local scale2 = animGroup:CreateAnimation("Scale")
        scale2:SetScale(0.666, 0.666)
        scale2:SetDuration(0.2)
        scale2:SetOrder(2)

        -- Alpha animation
        local alpha1 = animGroup:CreateAnimation("Alpha")
        alpha1:SetFromAlpha(0)
        alpha1:SetToAlpha(1)
        alpha1:SetDuration(0.2)
        alpha1:SetOrder(1)

        local alpha2 = animGroup:CreateAnimation("Alpha")
        alpha2:SetFromAlpha(1)
        alpha2:SetToAlpha(0)
        alpha2:SetDuration(0.2)
        alpha2:SetOrder(2)

        overlay.outerGlow = outerGlow
        overlay.animGroup = animGroup
        button.overlay = overlay
    end

    button.overlay:Show()
    button.overlay.animGroup:Play()
end

--- Hide overlay glow on a button
function LAB:HideOverlayGlow(button)
    if button and button.overlay then
        button.overlay.animGroup:Stop()
        button.overlay:Hide()
    end
end

--- Update overlay state for a button
function LAB:UpdateSpellOverlay(button)
    if not self.WoWRetail then return end
    if not button or not button.UpdateFunctions then return end

    local spellID = button.UpdateFunctions.GetSpellId and button.UpdateFunctions.GetSpellId(button)
    if not spellID then
        self:HideOverlayGlow(button)
        return
    end

    -- Check if spell is overlayed
    local isOverlayed = false
    if self.Compat.C_SpellActivationOverlay and self.Compat.C_SpellActivationOverlay.IsSpellOverlayed then
        isOverlayed = self.Compat.C_SpellActivationOverlay.IsSpellOverlayed(spellID)
    elseif self.Compat.IsSpellOverlayed then
        isOverlayed = self.Compat.IsSpellOverlayed(spellID)
    end

    if isOverlayed then
        self:ShowOverlayGlow(button)
    else
        self:HideOverlayGlow(button)
    end
end

-----------------------------------
-- NEW ACTION HIGHLIGHTING - Phase 4 Step 4.3
-----------------------------------

--- Update new action highlight (Retail only)
function LAB:UpdateNewActionHighlight(button)
    if not self.WoWRetail then return end
    if not button or not button.UpdateFunctions then return end
    if not self.Compat.C_NewItems or not self.Compat.C_NewItems.IsNewItem then return end

    -- Get action info
    local actionType, id
    if button.UpdateFunctions.GetSpellId then
        id = button.UpdateFunctions.GetSpellId(button)
        actionType = "spell"
    end

    -- Check if using GetActionInfo
    if not id and button.buttonType == self.ButtonType.ACTION then
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
        isNew = self.Compat.C_NewItems.IsNewItem(id, Enum.NewItemType.Spell)
    elseif actionType == "item" and Enum and Enum.NewItemType then
        isNew = self.Compat.C_NewItems.IsNewItem(id, Enum.NewItemType.Item)
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

-----------------------------------
-- BUTTON UPDATE HELPERS
-----------------------------------

function LAB:UpdateHotkey(button)
    local action = button.action
    if not action or not button._hotkey then return end

    local key = GetBindingKey("ACTIONBUTTON" .. action)
    if key then
        -- Abbreviate the key text
        key = key:gsub("SHIFT%-", "S")
        key = key:gsub("CTRL%-", "C")
        key = key:gsub("ALT%-", "A")
        key = key:gsub("NUMPAD", "N")
        key = key:gsub("PLUS", "+")
        key = key:gsub("MINUS", "-")
        key = key:gsub("MULTIPLY", "*")
        key = key:gsub("DIVIDE", "/")

        button._hotkey:SetText(key)
        button._hotkey:Show()
    else
        button._hotkey:SetText("")
        button._hotkey:Hide()
    end
end

--- Phase 4 Step 4.4: Update equipped item border
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

function LAB:UpdateUsable(button)
    if not button or not button._icon then return end

    -- Update equipped border first (Phase 4 Step 4.4)
    self:UpdateEquippedBorder(button)

    -- Use UpdateFunctions if available (Phase 2)
    local isUsable, notEnoughMana
    if button.UpdateFunctions and button.UpdateFunctions.IsUsableAction then
        isUsable, notEnoughMana = button.UpdateFunctions.IsUsableAction(button)
    elseif button.action then
        -- Fallback to old method
        isUsable, notEnoughMana = IsUsableAction(button.action)
    end

    button._state = button._state or {}
    button._state.usable = isUsable
    button._state.hasPower = not notEnoughMana

    if isUsable then
        -- Usable - normal color
        button._icon:SetVertexColor(1, 1, 1)
    elseif notEnoughMana then
        -- Out of power - blue tint
        local color = button._colors.mana
        button._icon:SetVertexColor(color[1], color[2], color[3])
    else
        -- Not usable - gray
        local color = button._colors.unusable
        button._icon:SetVertexColor(color[1], color[2], color[3])
    end
end

function LAB:UpdateRange(button)
    if not button or not button._icon then return end

    -- Use UpdateFunctions if available (Phase 2)
    local inRange
    if button.UpdateFunctions and button.UpdateFunctions.IsInRange then
        inRange = button.UpdateFunctions.IsInRange(button)
    elseif button.action then
        -- Fallback to old method
        inRange = IsActionInRange(button.action)
    end

    button._state = button._state or {}
    button._state.inRange = inRange

    -- Only apply range coloring if the action is usable
    if not button._state.usable then return end

    if inRange == false then
        -- Out of range - red tint
        local color = button._colors.range
        button._icon:SetVertexColor(color[1], color[2], color[3])
    elseif inRange == true then
        -- In range - normal color
        button._icon:SetVertexColor(1, 1, 1)
    end
    -- nil means no range restriction
end

function LAB:UpdateVisualState(button)
    local action = button.action
    if not action then return end

    -- Update checked state (for toggleable actions)
    if IsCurrentAction(action) or IsAutoRepeatAction(action) then
        button:SetChecked(true)
    else
        button:SetChecked(false)
    end

    -- Update flash (for actions that are flashing)
    if IsAttackAction(action) and IsCurrentAction(action) then
        self:StartFlash(button)
    else
        self:StopFlash(button)
    end
end

function LAB:UpdateGrid(button)
    if button._showGrid then
        -- Show empty button backgrounds
        button:SetAlpha(1)
    else
        -- Hide empty buttons
        if button._state.hasAction then
            button:SetAlpha(1)
        else
            button:SetAlpha(0)
        end
    end
end

-----------------------------------
-- FLASH ANIMATION
-----------------------------------

function LAB:StartFlash(button)
    if not button._flash then return end
    button._isFlashing = true
    button._flashTime = 0
    button._flash:Show()
end

function LAB:StopFlash(button)
    if not button._flash then return end
    button._isFlashing = false
    button._flash:Hide()
end

function LAB:UpdateFlash(button, elapsed)
    if not button._isFlashing or not button._flash then return end

    button._flashTime = (button._flashTime or 0) + elapsed
    local alpha = math.abs(math.sin(button._flashTime * 2 * math.pi))
    button._flash:SetAlpha(alpha)
end

-----------------------------------
-- BUTTON EVENTS
-----------------------------------

function LAB:OnButtonUpdate(button, elapsed)
    -- Update range (frequent check)
    self:UpdateRange(button)

    -- Update flash animation
    if button._isFlashing then
        self:UpdateFlash(button, elapsed)
    end
end

function LAB:OnButtonEvent(button, event, ...)
    if event == "ACTIONBAR_SLOT_CHANGED" then
        local slot = ...
        if slot == 0 or slot == button.action then
            self:UpdateButton(button)
        end
    elseif event == "PLAYER_TARGET_CHANGED" then
        self:UpdateRange(button)
        self:UpdateUsable(button)
    elseif event == "ACTIONBAR_UPDATE_COOLDOWN" or event == "SPELL_UPDATE_COOLDOWN" then
        self:UpdateCooldown(button)
    elseif event == "ACTIONBAR_UPDATE_STATE" or event == "SPELL_UPDATE_USABLE" then
        self:UpdateVisualState(button)
        self:UpdateUsable(button)
    elseif event == "ACTIONBAR_UPDATE_USABLE" then
        self:UpdateUsable(button)
    elseif event == "UPDATE_BINDINGS" then
        self:UpdateHotkey(button)
    elseif event == "SPELL_UPDATE_CHARGES" then
        self:UpdateCount(button)
        self:UpdateCooldown(button)
    elseif event == "UPDATE_MACROS" or event == "LEARNED_SPELL_IN_TAB" then
        self:UpdateButton(button)
    elseif event == "PLAYER_ENTERING_WORLD" or event == "UPDATE_SHAPESHIFT_FORM" then
        self:UpdateButton(button)
    elseif event == "UNIT_POWER_FREQUENT" then
        local unit = ...
        if unit == "player" then
            self:UpdateUsable(button)
        end
    elseif event == "UNIT_AURA" then
        local unit = ...
        if unit == "player" or unit == "target" then
            self:UpdateUsable(button)
        end
    end
end

function LAB:OnButtonEnter(button)
    if not button.action then return end

    -- Show tooltip
    if GetCVarBool("UberTooltips") then
        GameTooltip_SetDefaultAnchor(GameTooltip, button)
    else
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    end

    if GameTooltip:SetAction(button.action) then
        button.UpdateTooltip = function() LAB:OnButtonEnter(button) end
    else
        button.UpdateTooltip = nil
    end
end

function LAB:OnButtonLeave(button)
    GameTooltip:Hide()
    button.UpdateTooltip = nil
end

-----------------------------------
-- PHASE 5: INTERACTION SYSTEMS
-----------------------------------

-----------------------------------
-- STEP 5.1: SECURE DRAG & DROP
-----------------------------------

--- Enable or disable drag and drop for a button
function LAB:EnableDragNDrop(button, enable)
    if not button then return end

    -- Store drag enabled state
    button._dragEnabled = enable

    if enable then
        button:RegisterForDrag("LeftButton")
        -- When drag is enabled, register both click types for proper drag/drop
        button:RegisterForClicks("AnyDown", "AnyUp")
    else
        button:RegisterForDrag()
        -- When drag is disabled, respect the click configuration
        -- This will call SetClickOnDown logic based on version
        self:SetClickOnDown(button, button._clickOnDown or false)
    end
end

--- Handle drag start
function LAB:OnDragStart(button)
    if not button or not button._dragEnabled then return end
    if button._locked then return end  -- Respect lock state
    if InCombatLockdown() then return end  -- No drag in combat

    -- Pick up the action based on button type
    if button.buttonType == self.ButtonType.ACTION then
        if button.action then
            PickupAction(button.action)
        end
    elseif button.buttonType == self.ButtonType.SPELL then
        if button.buttonAction then
            PickupSpellCompat(button.buttonAction)
        end
    elseif button.buttonType == self.ButtonType.ITEM then
        if button.buttonAction then
            PickupItemCompat(button.buttonAction)
        end
    elseif button.buttonType == self.ButtonType.MACRO then
        if button.buttonAction then
            PickupMacroCompat(button.buttonAction)
        end
    end
end

--- Handle receiving a drag
function LAB:OnReceiveDrag(button)
    if not button or not button._dragEnabled then return end
    if button._locked then return end  -- Respect lock state
    if InCombatLockdown() then return end  -- No drag in combat

    -- Place the cursor action on this button
    self:PlaceOnButton(button)
end

-----------------------------------
-- STEP 5.2: BUTTON LOCKING
-----------------------------------

--- Set whether a button is locked (prevents drag/drop)
function LAB:SetLocked(button, locked)
    if not button then return end
    button._locked = locked

    -- Update visual indicator if present
    if button._lockIndicator then
        if locked then
            button._lockIndicator:Show()
        else
            button._lockIndicator:Hide()
        end
    end
end

--- Get whether a button is locked
function LAB:GetLocked(button)
    if not button then return false end
    return button._locked or false
end

--- Create visual lock indicator (optional)
function LAB:CreateLockIndicator(button)
    if not button or button._lockIndicator then return end

    button._lockIndicator = button:CreateTexture(nil, "OVERLAY")
    button._lockIndicator:SetTexture("Interface\\PetBattles\\PetBattle-LockIcon")
    button._lockIndicator:SetSize(16, 16)
    button._lockIndicator:SetPoint("TOPRIGHT", button, "TOPRIGHT", -2, -2)
    button._lockIndicator:Hide()
end

-----------------------------------
-- STEP 5.3: CLICK BEHAVIOR CONFIGURATION
-----------------------------------

--- Set whether button responds to click-on-down vs click-on-up
-- Uses WoW's secure 'useOnKeyDown' attribute which controls when actions execute
function LAB:SetClickOnDown(button, clickOnDown)
    if not button then return end
    button._clickOnDown = clickOnDown

    -- Set the secure attribute that WoW's action system uses
    -- This is the key attribute that controls execution timing
    button:SetAttribute('useOnKeyDown', clickOnDown)

    self:DebugPrint(string.format("SetClickOnDown: %s -> useOnKeyDown = %s",
        button:GetName() or "unnamed", tostring(clickOnDown)))

    -- Register for clicks based on version
    -- Retail: Always register both down and up
    -- Classic: Register only the desired click type
    if WoWRetail then
        button:RegisterForClicks("AnyDown", "AnyUp")
    else
        if clickOnDown then
            button:RegisterForClicks("AnyDown")
        else
            button:RegisterForClicks("AnyUp")
        end
    end
end

--- Get click behavior
function LAB:GetClickOnDown(button)
    if not button then return false end
    return button._clickOnDown or false
end

--- Set global click behavior for all buttons
function LAB:SetGlobalClickOnDown(clickOnDown)
    self.globalClickOnDown = clickOnDown
    for _, button in ipairs(self.buttons) do
        self:SetClickOnDown(button, clickOnDown)
    end
end

-----------------------------------
-- STEP 5.4: CURSOR PICKUP HANDLING
-----------------------------------

--- Pick up button's action to cursor
function LAB:PickupButton(button)
    if not button then return end
    if InCombatLockdown() then return end  -- No pickup in combat

    -- Pick up based on button type
    if button.buttonType == self.ButtonType.ACTION then
        if button.action then
            PickupAction(button.action)
        end
    elseif button.buttonType == self.ButtonType.SPELL then
        if button.buttonAction then
            PickupSpellCompat(button.buttonAction)
        end
    elseif button.buttonType == self.ButtonType.ITEM then
        if button.buttonAction then
            PickupItemCompat(button.buttonAction)
        end
    elseif button.buttonType == self.ButtonType.MACRO then
        if button.buttonAction then
            PickupMacroCompat(button.buttonAction)
        end
    end
end

--- Place cursor contents onto button
function LAB:PlaceOnButton(button)
    if not button then return end
    if InCombatLockdown() then return end  -- No place in combat

    local cursorType, arg1, arg2, arg3 = GetCursorInfo()

    if not cursorType then
        -- Nothing on cursor, do nothing (don't clear the button)
        return
    end

    -- Place based on button type and what's on cursor
    if button.buttonType == self.ButtonType.ACTION then
        if button.action then
            PlaceAction(button.action)
            self:UpdateButton(button)
        end
    else
        -- For non-action buttons, we can try to update the button's action
        if cursorType == "spell" then
            -- When dragging from spellbook: arg1=slot, arg2=bookType, arg3=spellID
            -- When dragging from elsewhere: might be different
            local spellID = arg3 or arg2 or arg1
            if spellID and type(spellID) == "number" then
                button.buttonType = self.ButtonType.SPELL
                button.buttonAction = spellID
                button.UpdateFunctions = self.SpellTypeUpdateFunctions
                button:SetAttribute("type", "spell")
                button:SetAttribute("spell", spellID)
                ClearCursor()
                self:UpdateButton(button)
            end
        elseif cursorType == "item" then
            local itemID = arg3 or arg2 or arg1
            if itemID and type(itemID) == "number" then
                button.buttonType = self.ButtonType.ITEM
                button.buttonAction = itemID
                button.UpdateFunctions = self.ItemTypeUpdateFunctions
                button:SetAttribute("type", "item")
                button:SetAttribute("item", itemID)
                ClearCursor()
                self:UpdateButton(button)
            end
        elseif cursorType == "macro" then
            local macroID = arg1
            if macroID and type(macroID) == "number" then
                button.buttonType = self.ButtonType.MACRO
                button.buttonAction = macroID
                button.UpdateFunctions = self.MacroTypeUpdateFunctions
                button:SetAttribute("type", "macro")
                button:SetAttribute("macro", macroID)
                ClearCursor()
                self:UpdateButton(button)
            end
        end
    end
end

--- Clear a button's action
function LAB:ClearButton(button)
    if not button then return end
    if InCombatLockdown() then return end  -- No clear in combat

    if button.buttonType == self.ButtonType.ACTION and button.action then
        PickupAction(button.action)
        PlaceAction(button.action)  -- This clears it
        self:UpdateButton(button)
    else
        -- For non-action buttons, just clear the type
        button.buttonType = self.ButtonType.EMPTY
        button.buttonAction = nil
        button.UpdateFunctions = nil
        button:SetAttribute("type", nil)
        self:UpdateButton(button)
    end
end

-----------------------------------
-- CONFIGURATION
-----------------------------------

function LAB:UpdateConfig(button, config)
    button.config = config
    self:StyleButton(button, config)
    self:UpdateButton(button)
end

-----------------------------------
-- UTILITY
-----------------------------------

function LAB:GetButton(id)
    for _, button in ipairs(self.buttons) do
        if button.id == id then
            return button
        end
    end
    return nil
end

function LAB:UpdateAllButtons()
    for _, button in ipairs(self.buttons) do
        self:UpdateButton(button)
    end
end

-----------------------------------
-- INITIALIZATION
-----------------------------------

-- Register overlay events for proc glows (Retail only)
LAB:RegisterOverlayEvents()

-- Export
return LAB
