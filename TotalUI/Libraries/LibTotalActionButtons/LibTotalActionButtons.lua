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
    LAB.actionButtons = LAB.actionButtons or {}
    LAB.nonActionButtons = LAB.nonActionButtons or {}
    LAB.actionButtonsNonUI = LAB.actionButtonsNonUI or {}
    LAB.NumChargeCooldowns = LAB.NumChargeCooldowns or 0

    -- Convert old array-style button tables to set-style (button as key)
    -- This handles upgrades from versions that used ipairs/table.insert
    local function convertToSet(tbl)
        local needsConversion = false
        -- Check if table has numeric indices
        for i = 1, #tbl do
            if tbl[i] then
                needsConversion = true
                break
            end
        end

        if needsConversion then
            local buttons = {}
            for i = 1, #tbl do
                if tbl[i] then
                    buttons[tbl[i]] = true
                end
            end
            -- Clear old array entries
            for i = 1, #tbl do
                tbl[i] = nil
            end
            -- Copy set entries back
            for button, v in pairs(buttons) do
                tbl[button] = v
            end
        end
    end

    convertToSet(LAB.buttons)
    convertToSet(LAB.activeButtons)
else
    LAB.buttons = {}
    LAB.activeButtons = {}
    LAB.actionButtons = {}
    LAB.nonActionButtons = {}
    LAB.actionButtonsNonUI = {}
    LAB.NumChargeCooldowns = 0
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
        if not self.buttonAction or self.buttonAction == 0 then
            return false
        end
        return HasAction(self.buttonAction)
    end,

    GetActionTexture = function(self)
        if not self.buttonAction or self.buttonAction == 0 then
            return nil
        end
        return GetActionTexture(self.buttonAction)
    end,

    GetActionText = function(self)
        if not self.buttonAction or self.buttonAction == 0 then
            return nil
        end
        return GetActionText(self.buttonAction)
    end,

    GetActionCount = function(self)
        if not self.buttonAction or self.buttonAction == 0 then
            return 0
        end
        return GetActionCount(self.buttonAction)
    end,

    GetActionCharges = function(self)
        if not self.buttonAction or self.buttonAction == 0 then
            return nil
        end
        return LAB.Compat.GetActionCharges(self.buttonAction)
    end,

    -- State functions
    IsInRange = function(self)
        if not self.buttonAction or self.buttonAction == 0 then
            return nil
        end
        return IsActionInRange(self.buttonAction)
    end,

    IsUsableAction = function(self)
        if not self.buttonAction or self.buttonAction == 0 then
            return false
        end
        return IsUsableAction(self.buttonAction)
    end,

    IsCurrentAction = function(self)
        if not self.buttonAction or self.buttonAction == 0 then
            return false
        end
        return IsCurrentAction(self.buttonAction)
    end,

    IsAutoRepeatAction = function(self)
        if not self.buttonAction or self.buttonAction == 0 then
            return false
        end
        return IsAutoRepeatAction(self.buttonAction)
    end,

    IsAttackAction = function(self)
        if not self.buttonAction or self.buttonAction == 0 then
            return false
        end
        return IsAttackAction(self.buttonAction)
    end,

    IsEquippedAction = function(self)
        if not self.buttonAction or self.buttonAction == 0 then
            return false
        end
        return IsEquippedAction(self.buttonAction)
    end,

    IsConsumableAction = function(self)
        if not self.buttonAction or self.buttonAction == 0 then
            return false
        end
        return IsConsumableAction(self.buttonAction)
    end,

    -- Cooldown functions
    GetCooldown = function(self)
        if not self.buttonAction or self.buttonAction == 0 then
            return 0, 0, 0
        end
        return GetActionCooldown(self.buttonAction)
    end,

    GetLossOfControlCooldown = function(self)
        if not self.buttonAction or self.buttonAction == 0 then
            return 0, 0
        end
        return LAB.Compat.GetActionLossOfControlCooldown(self.buttonAction)
    end,

    -- Spell ID for proc detection
    GetSpellId = function(self)
        if not self.buttonAction or self.buttonAction == 0 then
            return nil
        end
        local actionType, id = GetActionInfo(self.buttonAction)
        if actionType == "spell" or actionType == "macro" then
            return id
        end
        return nil
    end,

    -- Phase 13 Feature #1: Get passive cooldown spell ID (trinkets, etc.)
    GetPassiveCooldownSpellID = function(self)
        -- Validate buttonAction first
        if not self.buttonAction or self.buttonAction == 0 then
            return nil
        end

        -- Only available on Retail with the required APIs
        if not (C_UnitAuras and C_UnitAuras.GetCooldownAuraBySpellID and
                C_ActionBar and C_ActionBar.GetItemActionOnEquipSpellID) then
            return nil
        end

        local actionType, actionID = GetActionInfo(self.buttonAction)
        local onEquipPassiveSpellID

        -- Check if this action has an on-equip passive spell (items)
        if actionID then
            onEquipPassiveSpellID = C_ActionBar.GetItemActionOnEquipSpellID(self.buttonAction)
        end

        if onEquipPassiveSpellID then
            return C_UnitAuras.GetCooldownAuraBySpellID(onEquipPassiveSpellID)
        else
            -- Check if the spell itself has a passive cooldown
            local spellID = self.UpdateFunctions.GetSpellId(self)
            if spellID then
                return C_UnitAuras.GetCooldownAuraBySpellID(spellID)
            end
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
        if not self.buttonAction or self.buttonAction == 0 then
            return nil
        end
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
        if not self.buttonAction then
            return false
        end
        return true  -- Item buttons always have an action
    end,

    GetActionTexture = function(self)
        if not self.buttonAction then
            return nil
        end
        return GetItemIcon(self.buttonAction)
    end,

    GetActionText = function(self)
        if not self.buttonAction then
            return ""
        end
        local itemName = GetItemInfo(self.buttonAction)
        return itemName or ""
    end,

    GetActionCount = function(self)
        if not self.buttonAction then
            return 0
        end
        -- Include bank and charges
        return GetItemCount(self.buttonAction, nil, true)
    end,

    GetActionCharges = function(self)
        if not self.buttonAction then
            return nil
        end
        -- Items with on-use effects might have charges
        local hasSpell = GetItemSpell(self.buttonAction)
        if hasSpell and LAB.Compat.GetItemCharges then
            return LAB.Compat.GetItemCharges(self.buttonAction)
        end
        return nil
    end,

    IsInRange = function(self)
        if not self.buttonAction then
            return nil
        end
        return IsItemInRange(self.buttonAction, "target")
    end,

    IsUsableAction = function(self)
        if not self.buttonAction then
            return false
        end
        return IsUsableItem(self.buttonAction)
    end,

    IsCurrentAction = function(self)
        if not self.buttonAction then
            return false
        end
        return IsCurrentItem(self.buttonAction)
    end,

    IsAutoRepeatAction = function(self)
        return false  -- Items don't auto-repeat
    end,

    IsAttackAction = function(self)
        return false  -- Items aren't attack actions
    end,

    IsEquippedAction = function(self)
        if not self.buttonAction then
            return false
        end
        return IsEquippedItem(self.buttonAction)
    end,

    IsConsumableAction = function(self)
        if not self.buttonAction then
            return false
        end
        return IsConsumableItem(self.buttonAction)
    end,

    GetCooldown = function(self)
        if not self.buttonAction then
            return 0, 0, 0
        end
        return GetItemCooldown(self.buttonAction)
    end,

    GetLossOfControlCooldown = function(self)
        return nil  -- Items don't have LoC cooldowns
    end,

    GetSpellId = function(self)
        if not self.buttonAction then
            return nil
        end
        -- Get spell ID from item's on-use effect
        local spellName, spellID = GetItemSpell(self.buttonAction)
        return spellID
    end,

    GetItemId = function(self)
        -- Return the item ID or item string
        -- buttonAction can be itemID (number) or item string/link
        if type(self.buttonAction) == "number" then
            return self.buttonAction
        elseif type(self.buttonAction) == "string" then
            -- Extract itemID from item string (e.g., "item:12345" or item link)
            local itemID = tonumber(string.match(self.buttonAction, "item:(%d+)"))
            if itemID then
                return itemID
            end
            -- Try to get info and extract itemID
            local itemString = GetItemInfo(self.buttonAction)
            if itemString then
                itemID = tonumber(string.match(itemString, "item:(%d+)"))
                return itemID
            end
        end
        return nil
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

    -- Phase 12: Store header if parent is a secure header
    if parent and parent.WrapScript then
        button.header = parent
    end

    -- Initialize button
    self:InitializeButton(button)
    self:SetupButtonAction(button, actionID)
    self:StyleButton(button, config)
    self:RegisterButton(button)

    -- Phase 12: Set up secure features if button has a secure header
    if button.header then
        -- Initialize secure state attributes
        button:SetAttribute("state", "0")
        button:SetAttribute("labtype-0", "action")
        button:SetAttribute("labaction-0", actionID)

        -- Set up secure snippets for combat functionality
        self:SetupSecureSnippets(button)

        -- Wrap OnClick for action change detection and flyout handling
        self:WrapOnClick(button)

        -- Mark that button uses custom flyout system
        button:SetAttribute("LABUseCustomFlyout", true)
    end

    -- Initial update for action buttons (type-specific buttons skip and do their own update)
    if not skipUpdate then
        self:UpdateButton(button)
    end

    -- Fire OnButtonCreated callback (Phase 7)
    self:FireCallback("OnButtonCreated", button)

    return button
end

function LAB:InitializeButton(button)
    -- Get references to button elements
    button._icon = button.icon or _G[button:GetName() .. "Icon"]
    button._count = button.Count or _G[button:GetName() .. "Count"]
    button._hotkey = button.HotKey or _G[button:GetName() .. "HotKey"]
    button._name = button.Name or _G[button:GetName() .. "Name"]
    button._border = button.Border or _G[button:GetName() .. "Border"]

    -- Create Count fontstring if it doesn't exist
    if not button._count then
        button._count = button:CreateFontString(button:GetName() .. "Count", "OVERLAY", "NumberFontNormal")
        button._count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
    end

    -- Create HotKey fontstring if it doesn't exist
    if not button._hotkey then
        button._hotkey = button:CreateFontString(button:GetName() .. "HotKey", "OVERLAY", "NumberFontNormalSmallGray")
        button._hotkey:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -2)
    end

    -- Create Name fontstring if it doesn't exist
    if not button._name then
        button._name = button:CreateFontString(button:GetName() .. "Name", "OVERLAY", "GameFontNormalSmall")
        button._name:SetPoint("BOTTOM", button, "BOTTOM", 0, 2)
    end

    -- Template cooldown frames don't allow frame level changes (WoW limitation)
    -- Create our own cooldown frame for proper frame level control
    local templateCooldown = button.cooldown or _G[button:GetName() .. "Cooldown"]
    if templateCooldown and not button._cooldown then
        -- Hide the template's cooldown since we can't control its frame level
        templateCooldown:Hide()
        templateCooldown:SetAlpha(0)

        -- Create our own cooldown frame with controllable frame level
        button._cooldown = CreateFrame("Cooldown", button:GetName() .. "LABCooldown", button, "CooldownFrameTemplate")
        button._cooldown:SetAllPoints(button._icon)
        button._cooldown:SetDrawEdge(true)
        button._cooldown:SetDrawSwipe(true)
        button._cooldown:SetFrameLevel(button:GetFrameLevel() + 1)
    elseif not button._cooldown then
        -- Fallback to template cooldown if it exists
        button._cooldown = templateCooldown
    end

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

    -- Override the ActionBarButtonTemplate's SetTooltip method to prevent it from
    -- trying to use button.action for non-ACTION button types
    button.SetTooltip = function(self)
        -- Use our type-aware tooltip logic instead of Blizzard's
        LAB:OnButtonEnter(self)
    end

    -- Override Blizzard's UpdateUsable to prevent conflicts with our UpdateUsable
    -- Blizzard's ActionButton code tries to call UpdateUsable and expects button.action to be valid
    -- We handle usable state through our own update system
    button.UpdateUsable = function(self)
        -- Redirect to our UpdateUsable implementation
        LAB:UpdateUsable(self)
    end

    -- Phase 9: Initialize advanced features
    self:InitSpellCastAnimFrame(button)
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

    -- OnAttributeChanged for secure attribute handling (Feature 14)
    button:SetScript("OnAttributeChanged", function(self, name, value)
        LAB:OnAttributeChanged(self, name, value)
    end)

    -- Enable drag by default
    LAB:EnableDragNDrop(button, true)
end

function LAB:RegisterButton(button)
    -- Add to registry (use button as key for set-style iteration)
    self.buttons[button] = true
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

--- Create an action button (convenience wrapper for CreateButton)
-- @param actionID number The action slot ID (1-120)
-- @param name string Unique name for the button
-- @param parent frame Parent frame (defaults to UIParent)
-- @param config table Optional configuration table
-- @return button The created button frame or nil on error
function LAB:CreateActionButton(actionID, name, parent, config)
    -- CreateButton already creates action buttons by default
    return self:CreateButton(actionID, name, parent, config)
end

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

    -- Track as active button (Phase 8 optimization)
    self:TrackActiveButton(button)

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

    -- Track as active button (Phase 8 optimization)
    self:TrackActiveButton(button)

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

    -- Track as active button (Phase 8 optimization)
    self:TrackActiveButton(button)

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

    -- Track as active button (Phase 8 optimization)
    self:TrackActiveButton(button)

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

    -- Fire OnButtonStateChanged callback (Phase 7)
    self:FireCallback("OnButtonStateChanged", button, newState, oldState)
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

    -- Clear ALL type-specific properties first
    -- IMPORTANT: We can't set button.action to nil because Blizzard's ActionBarButtonTemplate
    -- code (in ActionButton.lua) will try to call C_TooltipInfo.GetAction(nil) which errors.
    -- Instead, we set it to 0 which is an invalid action slot that won't error.
    button.action = 0  -- Invalid action slot (safe for Blizzard's code)
    button.spellID = nil
    button.itemID = nil
    button.macroID = nil

    -- Clear old secure attributes to prevent interference
    button:SetAttribute("action", nil)
    button:SetAttribute("spell", nil)
    button:SetAttribute("item", nil)
    button:SetAttribute("macro", nil)

    self:DebugPrint(string.format("  After clear: action=%s spellID=%s", tostring(button.action), tostring(button.spellID)))

    -- Update button type and action
    button.buttonType = buttonType or LAB.ButtonType.EMPTY
    button.buttonAction = action

    self:DebugPrint(string.format("  Set buttonAction=%s", tostring(button.buttonAction)))

    -- Update secure attributes for click handling and set type-specific properties
    if buttonType == LAB.ButtonType.ACTION then
        button:SetAttribute("type", "action")
        button:SetAttribute("action", action)
        button.action = action  -- ONLY set action property for ACTION type
        button.UpdateFunctions = LAB.ActionTypeUpdateFunctions
        self:DebugPrint(string.format("  Set ACTION: action=%s", tostring(button.action)))

        -- Phase 13 Feature #5: Auto-register with Blizzard's action UI system
        if button.config and button.config.actionButtonUI and self.WoWRetail then
            self:RegisterActionUI(button)
        end
    elseif buttonType == LAB.ButtonType.SPELL then
        button:SetAttribute("type", "spell")
        button:SetAttribute("spell", action)
        button.spellID = action  -- ONLY set spellID property for SPELL type
        -- Keep button.action = 0 (invalid) to prevent Blizzard's code from using it
        button.UpdateFunctions = LAB.SpellTypeUpdateFunctions
        self:DebugPrint(string.format("  Set SPELL: spellID=%s action=%s", tostring(button.spellID), tostring(button.action)))
    elseif buttonType == LAB.ButtonType.ITEM then
        button:SetAttribute("type", "item")
        button:SetAttribute("item", "item:" .. tostring(action))
        button.itemID = action  -- ONLY set itemID property for ITEM type
        -- Keep button.action = 0 (invalid) to prevent Blizzard's code from using it
        button.UpdateFunctions = LAB.ItemTypeUpdateFunctions
        self:DebugPrint(string.format("  Set ITEM: itemID=%s action=%s", tostring(button.itemID), tostring(button.action)))
    elseif buttonType == LAB.ButtonType.MACRO then
        button:SetAttribute("type", "macro")
        button:SetAttribute("macro", action)
        button.macroID = action  -- ONLY set macroID property for MACRO type
        -- Keep button.action = 0 (invalid) to prevent Blizzard's code from using it
        button.UpdateFunctions = LAB.MacroTypeUpdateFunctions
        self:DebugPrint(string.format("  Set MACRO: macroID=%s action=%s", tostring(button.macroID), tostring(button.action)))
    else
        -- Empty or unknown type
        button:SetAttribute("type", nil)
        button.UpdateFunctions = {}
        self:DebugPrint(string.format("  Set EMPTY"))
    end

    self:DebugPrint(string.format("  After if-else: action=%s spellID=%s", tostring(button.action), tostring(button.spellID)))
    self:DebugPrint(string.format("  Before UpdateButton: action=%s spellID=%s", tostring(button.action), tostring(button.spellID)))

    -- Update all visual elements for the new action
    self:UpdateButton(button)

    self:DebugPrint(string.format("  After UpdateButton: action=%s spellID=%s", tostring(button.action), tostring(button.spellID)))
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

    local finalType = stateType or button.buttonType or LAB.ButtonType.EMPTY
    local finalAction = stateAction or button.buttonAction

    -- Final fallback to button's base type/action
    return finalType, finalAction
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

    -- Phase 13 Feature #3 & #4: Auto-update assisted combat frames (Retail only)
    if self.WoWRetail then
        self:UpdateAssistedCombatRotationFrame(button)
        self:UpdatedAssistedHighlightFrame(button)
    end

    -- Fire OnButtonUpdate callback (Phase 7)
    self:FireCallback("OnButtonUpdate", button)
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

    -- Track action identity for content change detection (Phase 7)
    local actionType, actionID
    if hasAction then
        actionType, actionID = GetActionInfo(action)
    end

    local previousHasAction = button._state.hasAction
    local previousActionType = button._state.actionType
    local previousActionID = button._state.actionID

    button._state.hasAction = hasAction
    button._state.actionType = actionType
    button._state.actionID = actionID

    -- Fire callback if contents changed (empty<->filled OR different action)
    local contentsChanged = (previousHasAction ~= hasAction) or
                           (hasAction and (previousActionType ~= actionType or previousActionID ~= actionID))

    if contentsChanged then
        self:FireCallback("OnButtonContentsChanged", button)
    end

    -- Update button tracking registries for optimization
    if hasAction then
        LAB.activeButtons[button] = true

        -- Separate action buttons from non-action buttons for efficient event routing
        if button.buttonType == "action" then
            LAB.actionButtons[button] = true
            LAB.nonActionButtons[button] = nil
        else
            LAB.actionButtons[button] = nil
            LAB.nonActionButtons[button] = true
        end

        -- Action exists: ensure normal texture uses default appearance
        if button._normalTexture then
            button._normalTexture:SetVertexColor(1, 1, 1, 1)
        end
    else
        LAB.activeButtons[button] = nil
        LAB.actionButtons[button] = nil
        LAB.nonActionButtons[button] = nil

        -- No action: UpdateGrid will handle showing/hiding the grid
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
    if not button then return end

    -- If _count doesn't exist, this is a critical error - log it
    if not button._count then
        self:Error(string.format("UpdateCount: button._count is nil for button %s", button:GetName() or "unnamed"))
        return
    end

    -- Check if count should be shown
    local showCount = true
    if button.config and button.config.showCount ~= nil then
        showCount = button.config.showCount
    end

    -- Check for charges first (for charge-based abilities)
    local charges, maxCharges
    if button.UpdateFunctions and button.UpdateFunctions.GetActionCharges then
        charges, maxCharges = button.UpdateFunctions.GetActionCharges(button)
    elseif button.action and self.Compat and self.Compat.GetActionCharges then
        charges, maxCharges = self.Compat.GetActionCharges(button.action)
    end

    -- If it's a charge-based ability, show current charges
    if charges and maxCharges and maxCharges > 1 then
        if showCount then
            button._count:SetText(charges)
            button._count:Show()
        else
            button._count:SetText("")
            button._count:Hide()
        end
        return
    end

    -- Otherwise, check for regular item counts
    local count
    if button.UpdateFunctions and button.UpdateFunctions.GetActionCount then
        count = button.UpdateFunctions.GetActionCount(button)
    elseif button.action then
        -- Fallback to old method
        count = GetActionCount(button.action)
    end

    -- Debug: Log the count value
    self:DebugPrint(string.format("UpdateCount: button=%s, count=%s, showCount=%s",
        button:GetName() or "unnamed", tostring(count), tostring(showCount)))

    if count and count > 0 and showCount then
        -- Show count for items (standard WoW only shows count > 1, but for testing we show all)
        button._count:SetText(count)
        button._count:Show()
    else
        -- No items - hide count
        button._count:SetText("")
        button._count:Hide()
    end
end

--- Phase 4 Step 4.1: Create charge cooldown frame
local function CreateChargeCooldownFrame(parent)
    LAB.NumChargeCooldowns = LAB.NumChargeCooldowns + 1
    local cooldown = CreateFrame("Cooldown",
        "LABChargeCooldown" .. LAB.NumChargeCooldowns, parent, "CooldownFrameTemplate")

    -- Position relative to icon with small inset (matches LAB-1.0)
    cooldown:SetPoint("TOPLEFT", parent._icon, "TOPLEFT", 2, -2)
    cooldown:SetPoint("BOTTOMRIGHT", parent._icon, "BOTTOMRIGHT", -2, 2)
    cooldown:SetHideCountdownNumbers(true)
    cooldown:SetDrawSwipe(false)
    cooldown:SetFrameLevel(parent:GetFrameLevel())
    return cooldown
end

local function ClearChargeCooldown(button)
    if button.chargeCooldown then
        if CooldownFrame_Clear then
            CooldownFrame_Clear(button.chargeCooldown)
        else
            button.chargeCooldown:Hide()
        end
    end
end

local function StartChargeCooldown(button, chargeStart, chargeDuration, chargeModRate)
    if chargeStart == 0 then
        ClearChargeCooldown(button)
        return
    end

    button.chargeCooldown = button.chargeCooldown or CreateChargeCooldownFrame(button)

    if CooldownFrame_Set then
        CooldownFrame_Set(button.chargeCooldown, chargeStart, chargeDuration, true, true, chargeModRate)
    else
        button.chargeCooldown:SetCooldown(chargeStart, chargeDuration)
    end
end

--- Phase 4 Step 4.1: Enhanced cooldown update with charge support
function LAB:UpdateCooldown(button)
    if not button or not button._cooldown then return end

    local locStart, locDuration
    local start, duration, enable, modRate
    local charges, maxCharges, chargeStart, chargeDuration, chargeModRate

    -- Check for Loss of Control cooldown first (Retail only)
    if self.WoWRetail and button.UpdateFunctions and button.UpdateFunctions.GetLossOfControlCooldown then
        locStart, locDuration = button.UpdateFunctions.GetLossOfControlCooldown(button)
    end

    -- Get cooldown data based on button type
    if button.UpdateFunctions and button.UpdateFunctions.GetCooldown then
        start, duration, enable, modRate = button.UpdateFunctions.GetCooldown(button)
    elseif button.action then
        start, duration, enable = GetActionCooldown(button.action)
    end

    -- Get charge data
    if button.UpdateFunctions and button.UpdateFunctions.GetActionCharges then
        charges, maxCharges, chargeStart, chargeDuration = button.UpdateFunctions.GetActionCharges(button)
        chargeModRate = modRate
    elseif button.action and self.Compat and self.Compat.GetActionCharges then
        charges, maxCharges, chargeStart, chargeDuration = self.Compat.GetActionCharges(button.action)
        chargeModRate = modRate
    end

    -- Phase 13 Feature #2: Check for passive cooldowns (trinkets, etc.)
    if self.WoWRetail and button.UpdateFunctions and button.UpdateFunctions.GetPassiveCooldownSpellID then
        local passiveCooldownSpellID = button.UpdateFunctions.GetPassiveCooldownSpellID(button)
        if passiveCooldownSpellID and passiveCooldownSpellID ~= 0 and C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
            local auraData = C_UnitAuras.GetPlayerAuraBySpellID(passiveCooldownSpellID)
            if auraData then
                -- Use aura cooldown data instead
                local currentTime = GetTime()
                local howMuchTimeHasPassed = currentTime - auraData.expirationTime + auraData.duration
                start = currentTime - howMuchTimeHasPassed
                duration = auraData.duration
                enable = 1
                modRate = 1
            end
        end
    end

    -- Set draw bling based on cooldown visibility
    if button._cooldown.SetDrawBling then
        button._cooldown:SetDrawBling(button._cooldown:GetEffectiveAlpha() > 0.5)
    end

    -- Check if LoC cooldown takes priority
    local hasLocCooldown = locStart and locDuration and locStart > 0 and locDuration > 0
    local hasCooldown = enable and start and duration and start > 0 and duration > 0

    if hasLocCooldown and ((not hasCooldown) or ((locStart + locDuration) > (start + duration))) then
        -- Loss of Control cooldown wins
        if button._cooldown.currentCooldownType ~= "LoC" then
            if button._cooldown.SetEdgeTexture then
                button._cooldown:SetEdgeTexture("Interface\\Cooldown\\edge-LoC")
            end
            if button._cooldown.SetSwipeColor then
                button._cooldown:SetSwipeColor(0.17, 0, 0)
            end
            button._cooldown.currentCooldownType = "LoC"
        end

        if CooldownFrame_Set then
            CooldownFrame_Set(button._cooldown, locStart, locDuration, true, true, modRate)
        else
            button._cooldown:SetCooldown(locStart, locDuration)
        end
        ClearChargeCooldown(button)
    else
        -- Normal or charge cooldown
        if button._cooldown.currentCooldownType ~= "normal" then
            if button._cooldown.SetEdgeTexture then
                button._cooldown:SetEdgeTexture("Interface\\Cooldown\\edge")
            end
            if button._cooldown.SetSwipeColor then
                button._cooldown:SetSwipeColor(0, 0, 0)
            end
            button._cooldown.currentCooldownType = "normal"
        end

        -- Handle charge cooldowns
        if charges and maxCharges and maxCharges > 1 and charges < maxCharges then
            if chargeStart and chargeDuration then
                StartChargeCooldown(button, chargeStart, chargeDuration, chargeModRate)
            end
        else
            ClearChargeCooldown(button)
        end

        -- Set main cooldown
        if CooldownFrame_Set then
            CooldownFrame_Set(button._cooldown, start, duration, enable, false, modRate)
        else
            if start and duration and enable == 1 then
                button._cooldown:SetCooldown(start, duration)
            else
                button._cooldown:Hide()
            end
        end
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
    -- buttons is a set where keys are button objects, values are true
    for button in pairs(self.buttons or {}) do
        if button and button.UpdateFunctions and button.UpdateFunctions.GetSpellId then
            local buttonSpellID = button.UpdateFunctions.GetSpellId(button)
            if buttonSpellID == spellID then
                self:ShowOverlayGlow(button)
            end
        end
    end
end

--- Hide overlay glow for all buttons with this spell
function LAB:HideOverlayGlowForSpell(spellID)
    -- buttons is a set where keys are button objects, values are true
    for button in pairs(self.buttons or {}) do
        if button and button.UpdateFunctions and button.UpdateFunctions.GetSpellId then
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

--- Standalone overlay glow helper functions (matches LAB-1.0 API)
local IsSpellOverlayed = C_SpellActivationOverlay and C_SpellActivationOverlay.IsSpellOverlayed or IsSpellOverlayed

function LAB:UpdateOverlayGlow(button)
    if not button or not button.UpdateFunctions then return end

    local spellID = button.UpdateFunctions.GetSpellId and button.UpdateFunctions.GetSpellId(button)
    if spellID and IsSpellOverlayed and IsSpellOverlayed(spellID) then
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

--- LAB-1.0 compatible alias
function LAB:UpdateNewAction(button)
    return self:UpdateNewActionHighlight(button)
end

-----------------------------------
-- BUTTON UPDATE HELPERS
-----------------------------------

function LAB:UpdateHotkey(button)
    local action = button.action
    if not action or not button._hotkey then return end

    -- Check if hotkey should be shown
    local showHotkey = true
    if button.config and button.config.showHotkey ~= nil then
        showHotkey = button.config.showHotkey
    end

    -- Check if hideElements.hotkey is set
    local hideHotkey = false
    if button.config and button.config.hideElements and button.config.hideElements.hotkey then
        hideHotkey = true
    end

    local key = button.UpdateFunctions and button.UpdateFunctions.GetHotkey and button.UpdateFunctions.GetHotkey(button)
    if not key and action then
        key = GetBindingKey("ACTIONBUTTON" .. action)
    end

    if not key or key == "" or hideHotkey or not showHotkey then
        -- Use RANGE_INDICATOR as placeholder for range coloring
        button._hotkey:SetText(RANGE_INDICATOR or "•")
        button._hotkey:Hide()
    else
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
    end
end

--- LAB-1.0 compatible alias
function LAB:UpdateHotkeys(button)
    return self:UpdateHotkey(button)
end

--- Phase 4 Step 4.4: Update equipped item border and quality borders
function LAB:UpdateEquippedBorder(button)
    if not button or not button._border then return end

    -- Don't override custom borders set via SetBorderTexture
    if button._customBorder then return end

    local showBorder = false
    local r, g, b, a = 1, 1, 1, 0.5

    -- Check if item is equipped (takes priority)
    if button.UpdateFunctions and button.UpdateFunctions.IsEquippedAction then
        local isEquipped = button.UpdateFunctions.IsEquippedAction(button)
        if isEquipped then
            r, g, b, a = 0, 1.0, 0, 0.35  -- Green for equipped
            showBorder = true
        end
    end

    -- Check for item quality border (if not equipped)
    if not showBorder and button.UpdateFunctions then
        local itemID
        if button.UpdateFunctions.GetItemId then
            itemID = button.UpdateFunctions.GetItemId(button)
        end

        if itemID then
            local quality = select(3, GetItemInfo(itemID))
            if quality and quality > Enum.ItemQuality.Common then
                -- Show quality border for uncommon+ items
                local qualityColor = ITEM_QUALITY_COLORS[quality]
                if qualityColor then
                    r, g, b, a = qualityColor.r, qualityColor.g, qualityColor.b, 0.5
                    showBorder = true
                end
            end
        end
    end

    -- Apply border
    if showBorder and (not button.config or button.config.showBorder ~= false) then
        button._border:SetVertexColor(r, g, b, a)
        button._border:Show()
    else
        button._border:Hide()
    end
end

--- Set border texture/style (Feature 16: Border style/texture support)
-- Pass nil for texture to clear custom border and return to automatic border behavior
-- For solid textures, creates 4-edge border. For border textures, uses single overlay.
function LAB:SetBorderTexture(button, texture, size, offset)
    if not button then return end

    -- If texture is nil, clear custom border flag and return to automatic behavior
    if texture == nil then
        button._customBorder = nil

        -- Clean up edge borders if they exist
        if button._borderEdges then
            for _, edge in pairs(button._borderEdges) do
                edge:Hide()
            end
        end

        -- Show original border and update it
        if button._border then
            button._border:Show()
        end

        self:UpdateEquippedBorder(button)
        return
    end

    -- Mark that a custom border has been set
    button._customBorder = true

    -- Determine border thickness (how much larger than button)
    local buttonSize = button:GetWidth()
    local borderThickness = 2
    if size and size > buttonSize then
        borderThickness = (size - buttonSize) / 2
    end

    -- For solid textures like WHITE8X8, create 4-edge border system
    if texture:find("WHITE8X8") or texture:find("white") then
        -- Hide the original border texture
        if button._border then
            button._border:Hide()
        end

        -- Create edge border textures if they don't exist
        if not button._borderEdges then
            button._borderEdges = {}

            -- Top edge
            button._borderEdges.top = button:CreateTexture(nil, "OVERLAY", nil, 7)
            button._borderEdges.top:SetTexture(texture)

            -- Bottom edge
            button._borderEdges.bottom = button:CreateTexture(nil, "OVERLAY", nil, 7)
            button._borderEdges.bottom:SetTexture(texture)

            -- Left edge
            button._borderEdges.left = button:CreateTexture(nil, "OVERLAY", nil, 7)
            button._borderEdges.left:SetTexture(texture)

            -- Right edge
            button._borderEdges.right = button:CreateTexture(nil, "OVERLAY", nil, 7)
            button._borderEdges.right:SetTexture(texture)
        else
            -- Update existing edge textures
            for _, edge in pairs(button._borderEdges) do
                edge:SetTexture(texture)
            end
        end

        -- Position the edges to create a frame border
        local offsetX = offset and offset.x or 0
        local offsetY = offset and offset.y or 0

        -- Top edge - horizontal bar above button
        button._borderEdges.top:ClearAllPoints()
        button._borderEdges.top:SetPoint("BOTTOMLEFT", button, "TOPLEFT", offsetX, offsetY)
        button._borderEdges.top:SetPoint("BOTTOMRIGHT", button, "TOPRIGHT", offsetX, offsetY)
        button._borderEdges.top:SetHeight(borderThickness)

        -- Bottom edge - horizontal bar below button
        button._borderEdges.bottom:ClearAllPoints()
        button._borderEdges.bottom:SetPoint("TOPLEFT", button, "BOTTOMLEFT", offsetX, offsetY)
        button._borderEdges.bottom:SetPoint("TOPRIGHT", button, "BOTTOMRIGHT", offsetX, offsetY)
        button._borderEdges.bottom:SetHeight(borderThickness)

        -- Left edge - vertical bar on left side (including top/bottom edges)
        button._borderEdges.left:ClearAllPoints()
        button._borderEdges.left:SetPoint("TOPRIGHT", button, "TOPLEFT", offsetX, offsetY + borderThickness)
        button._borderEdges.left:SetPoint("BOTTOMRIGHT", button, "BOTTOMLEFT", offsetX, offsetY - borderThickness)
        button._borderEdges.left:SetWidth(borderThickness)

        -- Right edge - vertical bar on right side (including top/bottom edges)
        button._borderEdges.right:ClearAllPoints()
        button._borderEdges.right:SetPoint("TOPLEFT", button, "TOPRIGHT", offsetX, offsetY + borderThickness)
        button._borderEdges.right:SetPoint("BOTTOMLEFT", button, "BOTTOMRIGHT", offsetX, offsetY - borderThickness)
        button._borderEdges.right:SetWidth(borderThickness)

        -- Show all edges
        for _, edge in pairs(button._borderEdges) do
            edge:Show()
        end

        -- Store reference to edges on button._border for color setting compatibility
        -- When users call button._border:SetVertexColor(), forward to edges
        if button._border then
            local originalSetVertexColor = button._border.SetVertexColor
            button._border.SetVertexColor = function(self, r, g, b, a)
                if button._borderEdges then
                    for _, edge in pairs(button._borderEdges) do
                        edge:SetVertexColor(r, g, b, a)
                    end
                else
                    originalSetVertexColor(self, r, g, b, a)
                end
            end
        end

    else
        -- For non-solid textures (actual border textures), use the original single-texture approach
        if not button._border then return end

        -- Hide edge borders if they exist
        if button._borderEdges then
            for _, edge in pairs(button._borderEdges) do
                edge:Hide()
            end
        end

        -- Show and configure the original border texture
        button._border:Show()
        button._border:SetTexture(texture)

        if size then
            button._border:SetSize(size, size)
        end

        -- Position border relative to icon
        button._border:ClearAllPoints()
        if offset then
            button._border:SetPoint("CENTER", button._icon or button, "CENTER", offset.x or 0, offset.y or 0)
        else
            if button._icon then
                button._border:SetAllPoints(button._icon)
            end
        end

        button._border:SetDrawLayer("OVERLAY", 7)
    end
end

--- Update frame levels for all button elements (Feature 23: Frame level management)
function LAB:UpdateFrameLevels(button)
    if not button then return end

    local baseLevel = button:GetFrameLevel()

    -- Set relative frame levels for all elements
    if button._icon then
        button._icon:SetDrawLayer("ARTWORK", 0)
    end

    if button._normalTexture then
        button._normalTexture:SetDrawLayer("BACKGROUND", 0)
    end

    if button._border then
        button._border:SetDrawLayer("BORDER", 0)
    end

    if button._count then
        button._count:SetDrawLayer("OVERLAY", 1)
    end

    if button._hotkey then
        button._hotkey:SetDrawLayer("OVERLAY", 1)
    end

    if button._name then
        button._name:SetDrawLayer("OVERLAY", 1)
    end

    if button._cooldown then
        -- Cooldown frames from ActionBarButtonTemplate are tricky
        -- They often resist frame level changes due to template management
        -- Try multiple approaches to ensure proper layering

        -- Approach 1: Set parent explicitly
        if button._cooldown:GetParent() ~= button then
            button._cooldown:SetParent(button)
        end

        -- Approach 2: Set frame level (may not work with some templates)
        button._cooldown:SetFrameLevel(baseLevel + 1)

        -- Approach 3: If frame level didn't stick, try using SetFrameStrata
        -- to at least ensure it's in the correct strata
        C_Timer.After(0, function()
            if button._cooldown and button._cooldown:GetFrameLevel() == baseLevel then
                -- Frame level didn't change, cooldown is resisting
                -- Force it by changing the button's base level
                button:SetFrameLevel(baseLevel)
                if button._cooldown.SetFrameLevel then
                    button._cooldown:SetFrameLevel(baseLevel + 1)
                end
            end
        end)
    end

    if button.chargeCooldown then
        if button.chargeCooldown:GetParent() ~= button then
            button.chargeCooldown:SetParent(button)
        end
        button.chargeCooldown:SetFrameLevel(baseLevel + 2)
    end

    if button._overlayGlow then
        button._overlayGlow:SetFrameLevel(baseLevel + 5)
    end

    if button.NewActionTexture then
        button.NewActionTexture:SetDrawLayer("OVERLAY", 2)
    end
end

--- Show interrupt display (Feature 20: Interrupt display support)
function LAB:ShowInterruptDisplay(button)
    if not button then return end

    -- Create interrupt display if it doesn't exist or if it's missing animGroup
    if not button.InterruptDisplay or not button.InterruptDisplay.animGroup then
        -- Clean up old version if it exists
        if button.InterruptDisplay then
            if button.InterruptDisplay.Hide then
                button.InterruptDisplay:Hide()
            end
            button.InterruptDisplay = nil
        end

        -- Create a frame to hold the texture (frames can have animations, textures can't)
        button.InterruptDisplay = CreateFrame("Frame", nil, button)
        button.InterruptDisplay:SetAllPoints(button._icon or button)
        button.InterruptDisplay:SetFrameLevel(button:GetFrameLevel() + 10)

        -- Create the star texture
        local starTexture = button.InterruptDisplay:CreateTexture(nil, "OVERLAY")
        starTexture:SetAllPoints()
        starTexture:SetTexture("Interface\\Cooldown\\star4")
        starTexture:SetBlendMode("ADD")
        button.InterruptDisplay.texture = starTexture

        -- Create animation group for the star burst effect
        local animGroup = button.InterruptDisplay:CreateAnimationGroup()
        button.InterruptDisplay.animGroup = animGroup

        -- Scale animation (burst outward) - longer and more dramatic
        local scale = animGroup:CreateAnimation("Scale")
        scale:SetOrder(1)
        scale:SetDuration(0.6)
        scale:SetScale(2.0, 2.0)
        scale:SetOrigin("CENTER", 0, 0)

        -- Alpha fade in - quick
        local fadeIn = animGroup:CreateAnimation("Alpha")
        fadeIn:SetOrder(1)
        fadeIn:SetDuration(0.2)
        fadeIn:SetFromAlpha(0)
        fadeIn:SetToAlpha(1)

        -- Alpha fade out - slower
        local fadeOut = animGroup:CreateAnimation("Alpha")
        fadeOut:SetOrder(2)
        fadeOut:SetDuration(0.8)
        fadeOut:SetFromAlpha(1)
        fadeOut:SetToAlpha(0)

        -- Rotation animation (spin) - full rotation
        local rotate = animGroup:CreateAnimation("Rotation")
        rotate:SetOrder(1)
        rotate:SetDuration(1.0)
        rotate:SetDegrees(180)
        rotate:SetOrigin("CENTER", 0, 0)

        -- Reset after animation finishes
        animGroup:SetScript("OnFinished", function()
            button.InterruptDisplay:SetAlpha(0)
        end)

        -- Start hidden
        button.InterruptDisplay:SetAlpha(0)
    end

    -- Play the star burst animation
    button.InterruptDisplay:Show()
    button.InterruptDisplay:SetAlpha(1)
    if button.InterruptDisplay.texture then
        button.InterruptDisplay.texture:Show()
        button.InterruptDisplay.texture:SetAlpha(1)
    end

    -- Debug: verify frame is visible
    print("InterruptDisplay shown:", button.InterruptDisplay:IsShown())
    print("Texture shown:", button.InterruptDisplay.texture:IsShown())
    print("Frame level:", button.InterruptDisplay:GetFrameLevel())
    print("Playing animation...")

    button.InterruptDisplay.animGroup:Stop()
    button.InterruptDisplay.animGroup:Play()

    -- Debug: check if animation is playing
    print("Animation playing:", button.InterruptDisplay.animGroup:IsPlaying())
end

--- Hide interrupt display
function LAB:HideInterruptDisplay(button)
    if button and button.InterruptDisplay then
        button.InterruptDisplay:SetAlpha(0)
    end
end

--- Spell activation alert handling (Feature 17 & 22: Spell activation alerts + frame management)
local spellAlertFramePool = {}
local activeSpellAlerts = {}

function LAB:GetSpellAlertFrame()
    -- Try to get a frame from the pool
    for i, frame in ipairs(spellAlertFramePool) do
        if not frame:IsShown() then
            return frame
        end
    end

    -- Create new frame if pool is empty
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:SetSize(256, 256)
    frame.texture = frame:CreateTexture(nil, "OVERLAY", nil, 7)
    frame.texture:SetAllPoints()
    frame.texture:SetBlendMode("ADD")
    frame.animGroup = frame.texture:CreateAnimationGroup()

    -- Create animation
    local anim = frame.animGroup:CreateAnimation("Alpha")
    anim:SetFromAlpha(1)
    anim:SetToAlpha(0)
    anim:SetDuration(0.5)
    anim:SetSmoothing("OUT")

    frame.animGroup:SetScript("OnFinished", function(ag)
        ag:GetParent():Hide()
    end)

    table.insert(spellAlertFramePool, frame)
    return frame
end

function LAB:ShowSpellAlert(button, spellID)
    if not self.WoWRetail or not button then return end

    local overlayData
    if C_SpellActivationOverlay and C_SpellActivationOverlay.GetOverlayInfo then
        overlayData = C_SpellActivationOverlay.GetOverlayInfo(spellID)
    end

    -- If no overlay data, create default for testing/manual triggering
    if not overlayData then
        overlayData = {
            texture = "Interface\\Cooldown\\star4",
            scale = 1.5,
            r = 1.0,
            g = 0.8,
            b = 0.0
        }
    end

    local frame = self:GetSpellAlertFrame()
    frame.texture:SetTexture(overlayData.texture or "Interface\\Cooldown\\star4")
    frame:SetPoint("CENTER", button, "CENTER")
    frame:SetScale(overlayData.scale or 1.0)

    -- Set color if provided
    if overlayData.r then
        frame.texture:SetVertexColor(overlayData.r, overlayData.g or 1.0, overlayData.b or 1.0)
    end

    frame:Show()
    frame.animGroup:Play()

    activeSpellAlerts[button] = frame
end

function LAB:HideSpellAlert(button)
    local frame = activeSpellAlerts[button]
    if frame then
        frame:Hide()
        frame.animGroup:Stop()
        activeSpellAlerts[button] = nil
    end
end

function LAB:UpdateSpellActivationAlert(button)
    if not self.WoWRetail or not button or not button.UpdateFunctions then return end

    local spellID = button.UpdateFunctions.GetSpellId and button.UpdateFunctions.GetSpellId(button)
    if not spellID then
        self:HideSpellAlert(button)
        return
    end

    -- Check if spell has activation overlay
    local isOverlayed = false
    if C_SpellActivationOverlay and C_SpellActivationOverlay.IsSpellOverlayed then
        isOverlayed = C_SpellActivationOverlay.IsSpellOverlayed(spellID)
    elseif IsSpellOverlayed then
        isOverlayed = IsSpellOverlayed(spellID)
    end

    if isOverlayed then
        self:ShowSpellAlert(button, spellID)
    else
        self:HideSpellAlert(button)
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

    -- Get mana coloring mode from config (Phase 6)
    local manaColoringMode = "button" -- default
    if button.config and button.config.outOfManaColoring then
        manaColoringMode = button.config.outOfManaColoring
    end

    -- Get desaturation setting from config (default true)
    local desaturateUnusable = true
    if button.config and button.config.desaturateUnusable ~= nil then
        desaturateUnusable = button.config.desaturateUnusable
    end

    -- Check if button is out of range for desaturation
    local outOfRange = button._state.outOfRange or false

    -- Guard against uninitialized button (called before StyleButton)
    if not button._colors then
        -- Just set basic usability without colors
        if isUsable then
            button._icon:SetDesaturated(false)
            button._icon:SetVertexColor(1, 1, 1)
        else
            button._icon:SetDesaturated(desaturateUnusable)
            button._icon:SetVertexColor(0.4, 0.4, 0.4)
        end
        return
    end

    if isUsable then
        -- Usable - normal color, no desaturation
        button._icon:SetDesaturated(false)
        button._icon:SetVertexColor(1, 1, 1)
        -- Also restore hotkey color if it was tinted
        if button._hotkey then
            if button.config and button.config.text and button.config.text.hotkey and button.config.text.hotkey.color then
                local hkColor = button.config.text.hotkey.color
                button._hotkey:SetVertexColor(hkColor.r or 1, hkColor.g or 1, hkColor.b or 1, hkColor.a or 1)
            else
                button._hotkey:SetVertexColor(1, 1, 1, 1)
            end
        end
    elseif notEnoughMana then
        -- Out of power - apply coloring based on mode
        local color = button._colors.mana
        if manaColoringMode == "button" then
            button._icon:SetDesaturated(desaturateUnusable)
            button._icon:SetVertexColor(color[1], color[2], color[3])
        elseif manaColoringMode == "hotkey" and button._hotkey then
            button._icon:SetDesaturated(false)
            button._icon:SetVertexColor(1, 1, 1) -- Keep icon normal
            button._hotkey:SetVertexColor(color[1], color[2], color[3])
        else
            button._icon:SetDesaturated(false)
        end
        -- "none" mode - don't color anything
    else
        -- Not usable - gray and possibly desaturate
        local color = button._colors.unusable
        button._icon:SetDesaturated(desaturateUnusable)
        button._icon:SetVertexColor(color[1], color[2], color[3])
    end

    -- Handle out of range coloring with desaturation
    if outOfRange and manaColoringMode == "button" then
        button._icon:SetDesaturated(true)
        local rangeColor = button._colors.range
        button._icon:SetVertexColor(rangeColor[1], rangeColor[2], rangeColor[3])
    end
end

function LAB:UpdateRange(button)
    if not button or not button._icon then return end

    -- Initialize rangeTimer if not set (used for throttling)
    if button.rangeTimer == nil then
        button.rangeTimer = -1
    end

    -- Use UpdateFunctions if available (Phase 2)
    local inRange
    if button.UpdateFunctions and button.UpdateFunctions.IsInRange then
        inRange = button.UpdateFunctions.IsInRange(button)
    elseif button.action then
        -- Fallback to old method
        inRange = IsActionInRange(button.action)
    end

    button._state = button._state or {}
    local previousInRange = button._state.inRange
    button._state.inRange = inRange
    button._state.outOfRange = (inRange == false)

    -- Only apply range coloring if the action is usable
    if not button._state.usable then return end

    -- Get range coloring mode from config (Phase 6)
    local coloringMode = "button" -- default
    if button.config and button.config.outOfRangeColoring then
        coloringMode = button.config.outOfRangeColoring
    end

    -- Don't color anything if mode is "none"
    if coloringMode == "none" then
        return
    end

    -- Guard against uninitialized button (called before StyleButton)
    if not button._colors then
        return
    end

    local color = button._colors.range

    if inRange == false then
        -- Out of range - apply coloring based on mode
        if coloringMode == "button" then
            button._icon:SetVertexColor(color[1], color[2], color[3])
        elseif coloringMode == "hotkey" and button._hotkey then
            -- Show RANGE_INDICATOR when out of range
            if button._hotkey:GetText() == RANGE_INDICATOR then
                button._hotkey:Show()
            end
            button._hotkey:SetVertexColor(color[1], color[2], color[3])
        end
    elseif inRange == true then
        -- In range - restore normal colors
        if coloringMode == "button" then
            button._icon:SetVertexColor(1, 1, 1)
        elseif coloringMode == "hotkey" and button._hotkey then
            -- Hide RANGE_INDICATOR when in range
            if button._hotkey:GetText() == RANGE_INDICATOR then
                button._hotkey:Hide()
            end
            -- Restore hotkey to its configured color or white
            if button.config and button.config.text and button.config.text.hotkey and button.config.text.hotkey.color then
                local hkColor = button.config.text.hotkey.color
                button._hotkey:SetVertexColor(hkColor.r or 1, hkColor.g or 1, hkColor.b or 1, hkColor.a or 1)
            else
                button._hotkey:SetVertexColor(1, 1, 1, 1)
            end
        end
    end
    -- nil means no range restriction
end

--- Update range timer for throttled range checking (matches LAB-1.0)
function LAB:UpdateRangeTimer(button, elapsed)
    if not button or not button.rangeTimer then return end

    -- Reset timer if button has no action
    if not button._state or not button._state.hasAction then
        button.rangeTimer = nil
        return
    end

    -- Throttle range updates to every 0.2 seconds
    if button.rangeTimer < 0 then
        self:UpdateRange(button)
        button.rangeTimer = 0.2
    else
        button.rangeTimer = button.rangeTimer - elapsed
    end
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
    if not button then return end

    if button._state.hasAction then
        -- Has action: always show button normally
        button:SetAlpha(1)
        if button._normalTexture then
            button._normalTexture:SetAlpha(1)
        end
    else
        -- No action: show grid or hide based on _showGrid
        if button._showGrid then
            -- Show grid: show button with reduced opacity for empty state
            button:SetAlpha(1)
            if button._normalTexture then
                button._normalTexture:SetAlpha(0.5)
            end
        else
            -- Hide grid: hide the normal texture but keep button interactive
            button:SetAlpha(1)  -- Keep button frame visible for interaction
            if button._normalTexture then
                button._normalTexture:SetAlpha(0)  -- Hide only the visual texture
            end
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

--- Handle secure attribute changes (Feature 14: OnAttributeChanged handler)
function LAB:OnAttributeChanged(button, name, value)
    if not button then return end

    -- Update button when certain attributes change
    if name == "type" then
        -- Type changed - update button type and action
        if value == "spell" then
            button.buttonType = self.ButtonType.SPELL
            button.UpdateFunctions = self.SpellTypeUpdateFunctions
        elseif value == "item" then
            button.buttonType = self.ButtonType.ITEM
            button.UpdateFunctions = self.ItemTypeUpdateFunctions
        elseif value == "macro" then
            button.buttonType = self.ButtonType.MACRO
            button.UpdateFunctions = self.MacroTypeUpdateFunctions
        elseif value == "action" then
            button.buttonType = self.ButtonType.ACTION
            button.UpdateFunctions = self.ActionTypeUpdateFunctions
        end
        if not InCombatLockdown() then
            self:UpdateButton(button)
        end
    elseif name == "spell" then
        -- Spell ID changed - update buttonAction
        button.buttonType = self.ButtonType.SPELL
        button.buttonAction = tonumber(value)
        button.UpdateFunctions = self.SpellTypeUpdateFunctions
        if not InCombatLockdown() then
            self:UpdateButton(button)
        end
    elseif name == "item" then
        -- Item changed - update buttonAction
        button.buttonType = self.ButtonType.ITEM
        button.buttonAction = value
        button.UpdateFunctions = self.ItemTypeUpdateFunctions
        if not InCombatLockdown() then
            self:UpdateButton(button)
        end
    elseif name == "macro" then
        -- Macro changed - update buttonAction
        button.buttonType = self.ButtonType.MACRO
        button.buttonAction = tonumber(value)
        button.UpdateFunctions = self.MacroTypeUpdateFunctions
        if not InCombatLockdown() then
            self:UpdateButton(button)
        end
    elseif name == "action" then
        -- Action changed - update buttonAction
        button.buttonType = self.ButtonType.ACTION
        button.action = tonumber(value)
        button.buttonAction = tonumber(value)
        button.UpdateFunctions = self.ActionTypeUpdateFunctions
        if not InCombatLockdown() then
            self:UpdateButton(button)
        end
    elseif name == "state" then
        -- State attribute changed
        if not InCombatLockdown() then
            self:UpdateButton(button)
        end
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
    -- Debug: show what we're seeing
    if self.debug then
        print(string.format("OnButtonEnter: type=%s action=%s spellID=%s itemID=%s macroID=%s",
            tostring(button.buttonType), tostring(button.action), tostring(button.spellID),
            tostring(button.itemID), tostring(button.macroID)))
    end

    -- Show tooltip based on button type
    if GetCVarBool("UberTooltips") then
        GameTooltip_SetDefaultAnchor(GameTooltip, button)
    else
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    end

    local hasTooltip = false

    -- Set tooltip based on button type using type-specific properties
    if button.buttonType == LAB.ButtonType.ACTION and button.action then
        if self.debug then print(string.format("  -> Using ACTION tooltip with action=%s", tostring(button.action))) end
        hasTooltip = GameTooltip:SetAction(button.action)
        if self.debug then print(string.format("  -> SetAction returned: %s", tostring(hasTooltip))) end
    elseif button.buttonType == LAB.ButtonType.SPELL and button.spellID then
        if self.debug then print(string.format("  -> Using SPELL tooltip with spellID=%s", tostring(button.spellID))) end
        if self.debug then print(string.format("  -> GameTooltip owner before: %s", tostring(GameTooltip:GetOwner() and GameTooltip:GetOwner():GetName() or "nil"))) end
        hasTooltip = GameTooltip:SetSpellByID(button.spellID)
        if self.debug then print(string.format("  -> SetSpellByID returned: %s", tostring(hasTooltip))) end
        if self.debug then print(string.format("  -> GameTooltip owner after: %s", tostring(GameTooltip:GetOwner() and GameTooltip:GetOwner():GetName() or "nil"))) end
        if self.debug then print(string.format("  -> GameTooltip text: %s", tostring(_G["GameTooltipTextLeft1"] and _G["GameTooltipTextLeft1"]:GetText() or "nil"))) end
    elseif button.buttonType == LAB.ButtonType.ITEM and button.itemID then
        if self.debug then print(string.format("  -> Using ITEM tooltip with itemID=%s", tostring(button.itemID))) end
        hasTooltip = GameTooltip:SetItemByID(button.itemID)
        if self.debug then print(string.format("  -> SetItemByID returned: %s", tostring(hasTooltip))) end
    elseif button.buttonType == LAB.ButtonType.MACRO and button.macroID then
        if self.debug then print(string.format("  -> Using MACRO tooltip with macroID=%s", tostring(button.macroID))) end
        hasTooltip = GameTooltip:SetAction(button.macroID)
        if self.debug then print(string.format("  -> SetAction returned: %s", tostring(hasTooltip))) end
    end

    if hasTooltip then
        button.UpdateTooltip = function() LAB:OnButtonEnter(button) end
    else
        button.UpdateTooltip = nil
    end

    -- Fire OnButtonEnter callback (Phase 7)
    self:FireCallback("OnButtonEnter", button)
end

function LAB:OnButtonLeave(button)
    GameTooltip:Hide()
    button.UpdateTooltip = nil

    -- Fire OnButtonLeave callback (Phase 7)
    self:FireCallback("OnButtonLeave", button)
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

    -- Remove from active tracking (Phase 8 optimization)
    self:UntrackActiveButton(button)
end

-----------------------------------
-- PHASE 6: CONFIGURATION & CUSTOMIZATION
-----------------------------------

-----------------------------------
-- STEP 6.1: DEFAULT CONFIGURATION
-----------------------------------

LAB.DefaultConfig = {
    -- Visual elements
    showGrid = false,
    showCooldown = true,
    showCooldownNumbers = true,
    showCount = true,
    showHotkey = true,
    showMacroText = true,
    showTooltip = "enabled",  -- "enabled", "disabled", "nocombat"

    -- Element hiding
    hideElements = {
        macro = false,
        hotkey = false,
        equipped = false,
    },

    -- Colors
    colors = {
        range = { r = 0.8, g = 0.1, b = 0.1 },
        power = { r = 0.1, g = 0.3, b = 1.0 },
        usable = { r = 1.0, g = 1.0, b = 1.0 },
        unusable = { r = 0.4, g = 0.4, b = 0.4 },
    },

    -- Text configuration
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
            size = 16,
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

    -- Coloring options
    outOfRangeColoring = "button",  -- "button" or "hotkey"
    outOfManaColoring = "button",   -- "button" or "hotkey"
    desaturateUnusable = false,

    -- Interaction
    allowDragAndDrop = true,
    locked = false,
    clickOnDown = false,
}

-----------------------------------
-- STEP 6.2: DEEP CONFIG MERGING
-----------------------------------

--- Deep merge two tables (source into dest)
function LAB:DeepMerge(dest, source)
    if type(dest) ~= "table" or type(source) ~= "table" then
        return source
    end

    for k, v in pairs(source) do
        if type(v) == "table" and type(dest[k]) == "table" then
            dest[k] = self:DeepMerge(dest[k], v)
        else
            dest[k] = v
        end
    end

    return dest
end

--- Create a deep copy of a table
function LAB:DeepCopy(tbl)
    if type(tbl) ~= "table" then
        return tbl
    end

    local copy = {}
    for k, v in pairs(tbl) do
        copy[k] = self:DeepCopy(v)
    end

    return copy
end

--- Update button configuration with deep merging
function LAB:UpdateConfig(button, config)
    if not button then return end

    -- Deep copy default config
    local mergedConfig = self:DeepCopy(self.DefaultConfig)

    -- Deep merge user config
    if config then
        mergedConfig = self:DeepMerge(mergedConfig, config)
    end

    -- Store merged config
    button.config = mergedConfig

    -- Apply configuration
    self:ApplyConfig(button)
end

--- Apply configuration to button
function LAB:ApplyConfig(button)
    if not button or not button.config then return end

    local config = button.config

    -- Apply grid visibility
    if config.showGrid ~= nil then
        button._showGrid = config.showGrid
    end

    -- Apply element visibility
    self:ApplyElementVisibility(button, config)

    -- Apply text configuration
    self:ApplyTextConfig(button, config)

    -- Apply interaction settings
    if config.allowDragAndDrop ~= nil then
        self:EnableDragNDrop(button, config.allowDragAndDrop)
    end

    if config.locked ~= nil then
        self:SetLocked(button, config.locked)
    end

    if config.clickOnDown ~= nil then
        self:SetClickOnDown(button, config.clickOnDown)
    end

    -- Restyle and update
    self:StyleButton(button, config)
    self:UpdateButton(button)
end

--- Apply element visibility from config
function LAB:ApplyElementVisibility(button, config)
    if not button or not config then return end

    -- Apply show/hide for each element
    if button._hotkey then
        if config.hideElements.hotkey or not config.showHotkey then
            button._hotkey:Hide()
        else
            button._hotkey:Show()
        end
    end

    if button._count then
        if not config.showCount then
            button._count:Hide()
        else
            button._count:Show()
        end
    end

    if button._name then
        if config.hideElements.macro or not config.showMacroText then
            button._name:Hide()
        else
            button._name:Show()
        end
    end

    if button._cooldown then
        if not config.showCooldown then
            button._cooldown:Hide()
        else
            button._cooldown:Show()
        end
    end
end

--- Apply text configuration
function LAB:ApplyTextConfig(button, config)
    if not button or not config or not config.text then return end

    -- Apply hotkey text config
    if button._hotkey and config.text.hotkey then
        local hkConfig = config.text.hotkey
        if hkConfig.font and hkConfig.size and hkConfig.flags then
            button._hotkey:SetFont(hkConfig.font, hkConfig.size, hkConfig.flags)
        end
        if hkConfig.color then
            button._hotkey:SetTextColor(hkConfig.color.r, hkConfig.color.g, hkConfig.color.b, hkConfig.color.a or 1)
        end
        if hkConfig.justifyH then
            button._hotkey:SetJustifyH(hkConfig.justifyH)
        end
        if hkConfig.position then
            button._hotkey:ClearAllPoints()
            button._hotkey:SetPoint(
                hkConfig.position.anchor,
                button,
                hkConfig.position.relAnchor,
                hkConfig.position.offsetX,
                hkConfig.position.offsetY
            )
        end
    end

    -- Apply count text config
    if button._count and config.text.count then
        local countConfig = config.text.count
        if countConfig.font and countConfig.size and countConfig.flags then
            button._count:SetFont(countConfig.font, countConfig.size, countConfig.flags)
        end
        if countConfig.color then
            button._count:SetTextColor(countConfig.color.r, countConfig.color.g, countConfig.color.b, countConfig.color.a or 1)
        end
        if countConfig.justifyH then
            button._count:SetJustifyH(countConfig.justifyH)
        end
        if countConfig.position then
            button._count:ClearAllPoints()
            button._count:SetPoint(
                countConfig.position.anchor,
                button,
                countConfig.position.relAnchor,
                countConfig.position.offsetX,
                countConfig.position.offsetY
            )
        end
    end

    -- Apply macro text config
    if button._name and config.text.macro then
        local macroConfig = config.text.macro
        if macroConfig.font and macroConfig.size and macroConfig.flags then
            button._name:SetFont(macroConfig.font, macroConfig.size, macroConfig.flags)
        end
        if macroConfig.color then
            button._name:SetTextColor(macroConfig.color.r, macroConfig.color.g, macroConfig.color.b, macroConfig.color.a or 1)
        end
        if macroConfig.justifyH then
            button._name:SetJustifyH(macroConfig.justifyH)
        end
        if macroConfig.position then
            button._name:ClearAllPoints()
            button._name:SetPoint(
                macroConfig.position.anchor,
                button,
                macroConfig.position.relAnchor,
                macroConfig.position.offsetX,
                macroConfig.position.offsetY
            )
        end
    end
end

-----------------------------------
-- STEP 6.3: PER-ELEMENT SHOW/HIDE METHODS
-----------------------------------

--- Show or hide the grid on empty buttons
function LAB:SetShowGrid(button, show)
    if not button then return end
    button.config = button.config or {}
    button.config.showGrid = show
    button._showGrid = show  -- UpdateGrid checks this value
    self:UpdateButton(button)
end

--- Show or hide cooldown displays
function LAB:SetShowCooldown(button, show)
    if not button or not button._cooldown then return end
    button.config = button.config or {}
    button.config.showCooldown = show

    if show then
        button._cooldown:Show()
    else
        button._cooldown:Hide()
    end
end

--- Show or hide count text
function LAB:SetShowCount(button, show)
    if not button or not button._count then return end
    button.config = button.config or {}
    button.config.showCount = show

    if show then
        button._count:Show()
    else
        button._count:Hide()
    end
    self:UpdateButton(button)
end

--- Show or hide hotkey text
function LAB:SetShowHotkey(button, show)
    if not button or not button._hotkey then return end
    button.config = button.config or {}
    button.config.showHotkey = show

    if show then
        button._hotkey:Show()
    else
        button._hotkey:Hide()
    end
    self:UpdateButton(button)
end

--- Show or hide macro text
function LAB:SetShowMacroText(button, show)
    if not button or not button._name then return end
    button.config = button.config or {}
    button.config.showMacroText = show

    if show then
        button._name:Show()
    else
        button._name:Hide()
    end
    self:UpdateButton(button)
end

--- Set tooltip mode
-- @param mode "enabled", "disabled", or "nocombat"
function LAB:SetShowTooltip(button, mode)
    if not button then return end
    button.config = button.config or {}
    button.config.showTooltip = mode
end

-----------------------------------
-- STEP 6.4: RANGE/MANA COLORING OPTIONS
-----------------------------------

--- Set out of range coloring mode
-- @param mode "button" or "hotkey"
function LAB:SetOutOfRangeColoring(button, mode)
    if not button then return end
    button.config = button.config or {}
    button.config.outOfRangeColoring = mode
    self:UpdateButton(button)
end

--- Set out of mana coloring mode
-- @param mode "button" or "hotkey"
function LAB:SetOutOfManaColoring(button, mode)
    if not button then return end
    button.config = button.config or {}
    button.config.outOfManaColoring = mode
    self:UpdateButton(button)
end

--- Set desaturation for unusable actions
function LAB:SetDesaturateUnusable(button, desaturate)
    if not button then return end
    button.config = button.config or {}
    button.config.desaturateUnusable = desaturate
    self:UpdateButton(button)
end

--- Set custom color for a specific state
-- @param colorType "range", "power", "usable", or "unusable"
-- @param r, g, b Color values 0-1
function LAB:SetStateColor(button, colorType, r, g, b)
    if not button then return end
    button.config = button.config or {}
    button.config.colors = button.config.colors or {}
    button.config.colors[colorType] = { r = r, g = g, b = b }

    -- Also update button._colors (array format used by update functions)
    button._colors = button._colors or {}
    button._colors[colorType] = { r, g, b }

    self:UpdateButton(button)
end

-----------------------------------
-- STEP 6.5: TEXT ALIGNMENT OPTIONS
-----------------------------------

--- Set text justification
-- @param element "hotkey", "count", or "macro"
-- @param justifyH "LEFT", "CENTER", or "RIGHT"
function LAB:SetTextJustifyH(button, element, justifyH)
    if not button then return end
    button.config = button.config or {}
    button.config.text = button.config.text or {}
    button.config.text[element] = button.config.text[element] or {}
    button.config.text[element].justifyH = justifyH

    local textElement = element == "hotkey" and button._hotkey
                     or element == "count" and button._count
                     or element == "macro" and button._name

    if textElement then
        textElement:SetJustifyH(justifyH)
    end
end

--- Set text font
-- @param element "hotkey", "count", or "macro"
-- @param font Font path
-- @param size Font size
-- @param flags Font flags ("OUTLINE", "THICKOUTLINE", "MONOCHROME", etc.)
function LAB:SetTextFont(button, element, font, size, flags)
    if not button then return end
    button.config = button.config or {}
    button.config.text = button.config.text or {}
    button.config.text[element] = button.config.text[element] or {}
    button.config.text[element].font = font
    button.config.text[element].size = size
    button.config.text[element].flags = flags

    local textElement = element == "hotkey" and button._hotkey
                     or element == "count" and button._count
                     or element == "macro" and button._name

    if textElement then
        textElement:SetFont(font, size, flags)
    end
end

--- Set text color
-- @param element "hotkey", "count", or "macro"
-- @param r, g, b, a Color values 0-1
function LAB:SetTextColor(button, element, r, g, b, a)
    if not button then return end
    button.config = button.config or {}
    button.config.text = button.config.text or {}
    button.config.text[element] = button.config.text[element] or {}
    button.config.text[element].color = { r = r, g = g, b = b, a = a or 1 }

    local textElement = element == "hotkey" and button._hotkey
                     or element == "count" and button._count
                     or element == "macro" and button._name

    if textElement then
        textElement:SetTextColor(r, g, b, a or 1)
    end
end

--- Set text position
-- @param element "hotkey", "count", or "macro"
-- @param anchor Anchor point
-- @param relAnchor Relative anchor point
-- @param offsetX X offset
-- @param offsetY Y offset
function LAB:SetTextPosition(button, element, anchor, relAnchor, offsetX, offsetY)
    if not button then return end
    button.config = button.config or {}
    button.config.text = button.config.text or {}
    button.config.text[element] = button.config.text[element] or {}
    button.config.text[element].position = {
        anchor = anchor,
        relAnchor = relAnchor,
        offsetX = offsetX,
        offsetY = offsetY,
    }

    local textElement = element == "hotkey" and button._hotkey
                     or element == "count" and button._count
                     or element == "macro" and button._name

    if textElement then
        textElement:ClearAllPoints()
        textElement:SetPoint(anchor, button, relAnchor, offsetX, offsetY)
    end
end

-----------------------------------
-- PHASE 7: INTEGRATION & EXTENSIBILITY
-----------------------------------

-----------------------------------
-- STEP 7.1: CALLBACKHANDLER INTEGRATION
-----------------------------------

-- Try to load CallbackHandler-1.0
local CBH = LibStub and LibStub("CallbackHandler-1.0", true)

if CBH then
    -- Initialize callbacks if CallbackHandler is available
    -- This creates RegisterCallback, UnregisterCallback, and UnregisterAllCallbacks methods on LAB
    LAB.callbacks = LAB.callbacks or CBH:New(LAB)

    --- Fire a callback event
    -- @param event The event name
    -- @param ... Event arguments
    function LAB:FireCallback(event, ...)
        if self.callbacks then
            self.callbacks:Fire(event, ...)
        end
    end
else
    -- Fallback if CallbackHandler is not available
    function LAB:FireCallback(event, ...)
        -- No-op if no callback handler
    end

    -- Create stub methods if CallbackHandler not available
    function LAB:RegisterCallback(event, callback, arg)
        -- No-op
    end

    function LAB:UnregisterCallback(event, callback)
        -- No-op
    end
end

-----------------------------------
-- STEP 7.2: MASQUE SUPPORT
-----------------------------------

-- Try to load Masque (or ButtonFacade for legacy support)
local MSQ = LibStub and (LibStub("Masque", true) or LibStub("ButtonFacade", true))

LAB.MasqueGroup = nil

--- Initialize Masque support
function LAB:InitializeMasque()
    if not MSQ then return end

    -- Create a Masque group for LibTotalActionButtons
    if not self.MasqueGroup then
        self.MasqueGroup = MSQ:Group("LibTotalActionButtons")
    end
end

--- Add button to Masque skinning
-- @param button The button to skin
function LAB:AddToMasque(button)
    if not MSQ or not button then return end

    -- Initialize Masque if needed
    self:InitializeMasque()

    if not self.MasqueGroup then return end

    -- Create button data structure for Masque
    local buttonData = {
        Icon = button._icon,
        Cooldown = button._cooldown,
        Count = button._count,
        HotKey = button._hotkey,
        Name = button._name,
        Flash = button._flash,
        Border = button._border,
        Normal = button:GetNormalTexture(),
        Pushed = button:GetPushedTexture(),
        Highlight = button:GetHighlightTexture(),
        Checked = button:GetCheckedTexture(),
    }

    -- Add to Masque group
    self.MasqueGroup:AddButton(button, buttonData)

    -- Mark button as Masque-skinned
    button._masqueSkinned = true
end

--- Remove button from Masque skinning
-- @param button The button to unskin
function LAB:RemoveFromMasque(button)
    if not MSQ or not button or not self.MasqueGroup then return end

    self.MasqueGroup:RemoveButton(button)
    button._masqueSkinned = false
end

--- Update Masque skin for a button
-- @param button The button to update
function LAB:UpdateMasqueSkin(button)
    if not button or not button._masqueSkinned then return end

    -- Re-add to refresh skin
    self:AddToMasque(button)
end

-----------------------------------
-- STEP 7.3: LIBKEYBOUND INTEGRATION
-----------------------------------

--- Enable LibKeyBound support for a button
-- @param button The button to enable keybinding for
function LAB:EnableKeyBound(button)
    if not button then return end

    -- Try to load LibKeyBound (it might be Load on Demand)
    local LKB = LibStub and LibStub("LibKeyBound-1.0", true)
    if not LKB then return end

    -- Set up LibKeyBound methods on button
    button.GetBindingAction = function(self)
        return self.buttonType
    end

    button.GetActionName = function(self)
        local actionType = self.buttonType

        if actionType == "action" then
            return "Action Button " .. (self.action or 0)
        elseif actionType == "spell" then
            local spellName = GetSpellInfo(self.spellID or 0)
            return spellName or "Spell"
        elseif actionType == "item" then
            local itemName = GetItemInfo(self.itemID or 0)
            return itemName or "Item"
        elseif actionType == "macro" then
            return GetMacroInfo(self.macroID or 0) or "Macro"
        elseif actionType == "custom" then
            return self.customName or "Custom Action"
        end

        return "Unknown"
    end

    button.GetHotkey = function(self)
        return self._hotkey and self._hotkey:GetText() or ""
    end

    button.SetKey = function(self, key)
        if not key or key == "" then
            self._hotkey:SetText("")
            return
        end

        -- Set the binding
        local actionType = self.buttonType

        if actionType == "action" and self.action then
            SetBinding(key, "ACTIONBUTTON" .. self.action)
        end

        -- Update hotkey display
        LAB:UpdateHotkey(self)
    end

    -- Mark button as LibKeyBound enabled
    button._libKeyBoundEnabled = true
end

--- Disable LibKeyBound support for a button
-- @param button The button to disable keybinding for
function LAB:DisableKeyBound(button)
    if not button then return end

    button.GetBindingAction = nil
    button.GetActionName = nil
    button.GetHotkey = nil
    button.SetKey = nil

    button._libKeyBoundEnabled = false
end

-----------------------------------
-- STEP 7.4: ACTION UI REGISTRATION (RETAIL)
-----------------------------------

--- Register action button with Blizzard Action UI system (Retail only)
-- @param button The button to register
function LAB:RegisterActionUI(button)
    if not button or not WoWRetail then return end

    -- Only register action-type buttons
    if button.buttonType ~= "action" or not button.action then
        return
    end

    -- Check if API is available
    if not C_ActionBar or not C_ActionBar.SetActionUIButton then
        return
    end

    -- Register with Blizzard
    local slot = button.action
    local cooldown = button._cooldown

    if slot and cooldown then
        C_ActionBar.SetActionUIButton(slot, button, cooldown)
        button._actionUIRegistered = true
    end
end

--- Unregister action button from Blizzard Action UI system (Retail only)
-- @param button The button to unregister
function LAB:UnregisterActionUI(button)
    if not button or not WoWRetail then return end

    -- Only unregister if it was registered
    if not button._actionUIRegistered then return end

    -- Check if API is available
    if not C_ActionBar or not C_ActionBar.ClearActionUIButton then
        return
    end

    local slot = button.action
    if slot then
        C_ActionBar.ClearActionUIButton(slot)
        button._actionUIRegistered = false
    end
end

-----------------------------------
-- PHASE 8: PERFORMANCE OPTIMIZATION
-----------------------------------

-----------------------------------
-- STEP 8.1: CENTRALIZED EVENT HANDLING
-----------------------------------

-- Global event frame for all buttons (reduces per-button overhead)
local EventFrame = CreateFrame("Frame")
LAB.EventFrame = EventFrame

-- Table to track which events need which updates
local EventHandlers = {
    -- Action bar events
    ACTIONBAR_SLOT_CHANGED = function(self, slot)
        for _, button in ipairs(LAB.activeButtons) do
            if button.buttonType == "action" and button.action == slot then
                LAB:UpdateButton(button)
            end
        end
    end,

    ACTIONBAR_UPDATE_COOLDOWN = function(self)
        for _, button in ipairs(LAB.activeButtons) do
            if button.buttonType == "action" then
                LAB:UpdateCooldown(button)
            end
        end
    end,

    ACTIONBAR_UPDATE_USABLE = function(self)
        for _, button in ipairs(LAB.activeButtons) do
            LAB:UpdateUsable(button)
        end
    end,

    -- Spell events
    SPELL_UPDATE_COOLDOWN = function(self)
        for _, button in ipairs(LAB.activeButtons) do
            if button.buttonType == "spell" then
                LAB:UpdateCooldown(button)
            end
        end
    end,

    SPELL_UPDATE_CHARGES = function(self)
        for _, button in ipairs(LAB.activeButtons) do
            if button.buttonType == "spell" and button.spellID then
                LAB:UpdateCharges(button)
            end
        end
    end,

    SPELL_UPDATE_USABLE = function(self)
        for _, button in ipairs(LAB.activeButtons) do
            if button.buttonType == "spell" then
                LAB:UpdateUsable(button)
            end
        end
    end,

    -- Item events
    BAG_UPDATE_COOLDOWN = function(self)
        for _, button in ipairs(LAB.activeButtons) do
            if button.buttonType == "item" then
                LAB:UpdateCooldown(button)
            end
        end
    end,

    ITEM_LOCK_CHANGED = function(self, bag, slot)
        for _, button in ipairs(LAB.activeButtons) do
            if button.buttonType == "item" then
                LAB:UpdateButton(button)
            end
        end
    end,

    -- Unit events
    UNIT_INVENTORY_CHANGED = function(self, unit)
        if unit == "player" then
            for _, button in ipairs(LAB.activeButtons) do
                if button.buttonType == "item" then
                    LAB:UpdateEquipped(button)
                end
            end
        end
    end,

    -- Player events
    PLAYER_TARGET_CHANGED = function(self)
        -- Range updates are throttled via OnUpdate
    end,

    PLAYER_ENTERING_WORLD = function(self)
        for _, button in ipairs(LAB.buttons) do
            LAB:UpdateButton(button)
        end
    end,
}

EventFrame:SetScript("OnEvent", function(self, event, ...)
    local handler = EventHandlers[event]
    if handler then
        handler(self, ...)
    end
end)

-- Register all events
for event in pairs(EventHandlers) do
    EventFrame:RegisterEvent(event)
end

-----------------------------------
-- STEP 8.2: BATCH UPDATE FUNCTIONS
-----------------------------------

--- Execute a function for all buttons
-- @param func Function to execute (receives button as first arg)
-- @param ... Additional arguments to pass to function
function LAB:ForAllButtons(func, ...)
    if type(func) ~= "function" then return end

    -- self.buttons is a set where keys are button objects
    for button in pairs(self.buttons) do
        func(button, ...)
    end
end

--- Execute a function for all buttons with a specific spell
-- @param spellID The spell ID to match
-- @param func Function to execute (receives button as first arg)
-- @param ... Additional arguments to pass to function
function LAB:ForAllButtonsWithSpell(spellID, func, ...)
    if not spellID or type(func) ~= "function" then return end

    -- self.activeButtons is a set where keys are button objects
    for button in pairs(self.activeButtons) do
        if button.buttonType == self.ButtonType.SPELL and button.buttonAction == spellID then
            func(button, ...)
        end
    end
end

--- Execute a function for all buttons with a specific item
-- @param itemID The item ID to match
-- @param func Function to execute (receives button as first arg)
-- @param ... Additional arguments to pass to function
function LAB:ForAllButtonsWithItem(itemID, func, ...)
    if not itemID or type(func) ~= "function" then return end

    -- self.activeButtons is a set where keys are button objects
    for button in pairs(self.activeButtons) do
        if button.buttonType == self.ButtonType.ITEM and button.buttonAction == itemID then
            func(button, ...)
        end
    end
end

--- Execute a function for all buttons with a specific action
-- @param actionID The action slot to match
-- @param func Function to execute (receives button as first arg)
-- @param ... Additional arguments to pass to function
function LAB:ForAllButtonsWithAction(actionID, func, ...)
    if not actionID or type(func) ~= "function" then return end

    -- self.activeButtons is a set where keys are button objects
    for button in pairs(self.activeButtons) do
        if button.buttonType == self.ButtonType.ACTION and button.buttonAction == actionID then
            func(button, ...)
        end
    end
end

-----------------------------------
-- STEP 8.3: RANGE UPDATE THROTTLING
-----------------------------------

-- Range update throttle (0.2 seconds)
local RANGE_UPDATE_INTERVAL = 0.2
local rangeUpdateTimer = 0

EventFrame:SetScript("OnUpdate", function(self, elapsed)
    rangeUpdateTimer = rangeUpdateTimer + elapsed

    if rangeUpdateTimer >= RANGE_UPDATE_INTERVAL then
        rangeUpdateTimer = 0

        -- Update range for all active buttons
        for _, button in ipairs(LAB.activeButtons) do
            LAB:UpdateRange(button)
        end
    end
end)

-----------------------------------
-- STEP 8.4: ACTIVE BUTTON TRACKING
-----------------------------------

-- Active buttons are already tracked in LAB.activeButtons table (created in Phase 1)
-- This was initialized at the top of the file

--- Add button to active tracking (called when button gets content)
-- @param button The button to track as active
function LAB:TrackActiveButton(button)
    if not button then return end

    -- activeButtons is a set where keys are button objects
    self.activeButtons[button] = true
end

--- Remove button from active tracking (called when button is cleared)
-- @param button The button to remove from active tracking
function LAB:UntrackActiveButton(button)
    if not button then return end

    -- activeButtons is a set where keys are button objects
    self.activeButtons[button] = nil
end

--- Check if button has content (action, spell, item, macro, or custom)
-- @param button The button to check
-- @return boolean True if button has content
function LAB:ButtonHasContent(button)
    if not button then return false end

    local buttonType = button.buttonType
    if buttonType == "action" then
        -- For action buttons, check if action slot has content
        if not button.action or button.action == 0 then return false end
        return HasAction(button.action)
    elseif buttonType == "spell" then
        return button.spellID ~= nil
    elseif buttonType == "item" then
        return button.itemID ~= nil
    elseif buttonType == "macro" then
        return button.macroID ~= nil
    elseif buttonType == "custom" then
        return button.customAction ~= nil
    end

    return false
end

-----------------------------------
-- STEP 8.5: LAZY INITIALIZATION
-----------------------------------

--- Lazily create charge cooldown frame when needed
-- @param button The button to create charge cooldown for
function LAB:EnsureChargeCooldown(button)
    if not button then return nil end
    if button.chargeCooldown then return button.chargeCooldown end

    -- Only create if WoW Retail
    if not self.WoWRetail then return nil end

    -- Create charge cooldown frame
    local chargeCooldown = CreateFrame("Cooldown", button:GetName() .. "ChargeCooldown", button, "CooldownFrameTemplate")
    chargeCooldown:SetAllPoints(button._icon)
    chargeCooldown:SetDrawEdge(true)
    chargeCooldown:SetDrawSwipe(true)
    chargeCooldown:SetHideCountdownNumbers(false)

    -- Set frame level higher than regular cooldown
    local baseLevel = button:GetFrameLevel()
    chargeCooldown:SetFrameLevel(baseLevel + 2)

    button.chargeCooldown = chargeCooldown
    return chargeCooldown
end

--- Lazily create overlay glow when needed
-- @param button The button to create overlay for
function LAB:EnsureOverlay(button)
    if not button then return nil end
    if button._overlay then return button._overlay end

    -- Only create if WoW Retail
    if not self.WoWRetail then return nil end

    -- Overlay is created via ActionBarActionEventsFrame.Update when spell procs
    -- We don't need to create it manually, just track it
    return nil
end

-----------------------------------
-- PHASE 9: ADVANCED FEATURES
-----------------------------------

-----------------------------------
-- STEP 9.2: GLOBAL GRID SYSTEM
-----------------------------------

-- Grid counter for tracking show/hide requests
LAB.gridCounter = 0

--- Show grid on all empty buttons
-- Increments counter to support multiple callers
function LAB:ShowGrid()
    self.gridCounter = self.gridCounter + 1

    self:DebugPrint("ShowGrid called, counter: " .. self.gridCounter)

    -- Update all buttons
    for _, button in ipairs(self.buttons) do
        if button._normalTexture then
            -- Only show grid if button has no action
            if not self:ButtonHasContent(button) then
                -- Set the default action button texture
                button._normalTexture:SetTexture("Interface\\Buttons\\UI-Quickslot2")
                button._normalTexture:SetVertexColor(1.0, 1.0, 1.0, 1.0)
                button._normalTexture:SetAlpha(0.5)
                button._normalTexture:Show()
            end
        end
    end
end

--- Hide grid on all empty buttons
-- Decrements counter, only hides when counter reaches 0
function LAB:HideGrid()
    if self.gridCounter > 0 then
        self.gridCounter = self.gridCounter - 1
    end

    self:DebugPrint("HideGrid called, counter: " .. self.gridCounter)

    -- Only hide if counter is 0 (no more callers need grid)
    if self.gridCounter == 0 then
        for _, button in ipairs(self.buttons) do
            if button._normalTexture and not self:ButtonHasContent(button) then
                button._normalTexture:SetTexture(nil)
                button._normalTexture:SetAlpha(0)
                button._normalTexture:Hide()
            end
        end
    end
end

--- Force show grid on specific button
-- @param button The button to show grid on
-- @param show boolean Whether to show or hide grid
function LAB:SetShowGrid(button, show)
    if not button or not button._normalTexture then return end

    button._showGrid = show

    if show then
        if not self:ButtonHasContent(button) then
            button._normalTexture:SetVertexColor(1.0, 1.0, 1.0, 0.5)
            button._normalTexture:Show()
        end
    else
        if not self:ButtonHasContent(button) and self.gridCounter == 0 then
            button._normalTexture:Hide()
        end
    end
end

-----------------------------------
-- STEP 9.3: TOOLTIP ENHANCEMENTS
-----------------------------------

--- Set tooltip mode for button
-- @param button The button
-- @param mode string "enabled", "disabled", or "nocombat"
function LAB:SetTooltipMode(button, mode)
    if not button then return end

    button._tooltipMode = mode or "enabled"

    self:DebugPrint(string.format("SetTooltipMode: %s -> %s", button:GetName(), mode))
end

--- Check if tooltip should be shown
-- @param button The button
-- @return boolean Whether tooltip should be shown
function LAB:ShouldShowTooltip(button)
    if not button then return false end

    local mode = button._tooltipMode or "enabled"

    if mode == "disabled" then
        return false
    elseif mode == "nocombat" then
        return not InCombatLockdown()
    else
        return true
    end
end

--- Enhanced OnEnter handler for tooltips
function LAB:OnButtonEnter(button)
    if not button then return end

    -- Fire callback
    self:FireCallback("OnButtonEnter", button)

    -- Show tooltip if enabled
    if self:ShouldShowTooltip(button) then
        if button.buttonType == "action" and button.action then
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            GameTooltip:SetAction(button.action)
            GameTooltip:Show()
        elseif button.buttonType == "spell" and button.buttonAction then
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            GameTooltip:SetSpellByID(button.buttonAction)
            GameTooltip:Show()
        elseif button.buttonType == "item" and button.buttonAction then
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            GameTooltip:SetItemByID(button.buttonAction)
            GameTooltip:Show()
        elseif button.buttonType == "macro" and button.buttonAction then
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            local name, _, body = GetMacroInfo(button.buttonAction)
            if name then
                GameTooltip:SetText(name, 1, 1, 1)
                GameTooltip:AddLine(body, nil, nil, nil, true)
                GameTooltip:Show()
            end
        end
    end
end

--- Enhanced OnLeave handler for tooltips
function LAB:OnButtonLeave(button)
    if not button then return end

    -- Fire callback
    self:FireCallback("OnButtonLeave", button)

    -- Hide tooltip
    GameTooltip:Hide()
end

-----------------------------------
-- STEP 9.4: SPELL HIGHLIGHT ANIMATIONS (Retail)
-----------------------------------


-----------------------------------
-- STEP 9.5: SPELL CAST VFX (Retail)
-----------------------------------

--- Initialize spell cast animation frame for button
-- @param button The button
function LAB:InitSpellCastAnimFrame(button)
    if not button or not self.WoWRetail then return end

    -- SpellCastAnimFrame is part of ActionBarButtonTemplate
    button._spellCastAnim = button.SpellCastAnimFrame or _G[button:GetName() .. "SpellCastAnimFrame"]

    if button._spellCastAnim then
        self:DebugPrint("SpellCastAnimFrame found for " .. button:GetName())
    end
end

--- Show spell cast animation
-- @param button The button
function LAB:ShowSpellCastAnim(button)
    if not button or not self.WoWRetail or not button._spellCastAnim then return end

    if button._spellCastAnim.Show then
        button._spellCastAnim:Show()
        self:DebugPrint("Showing SpellCastAnim for " .. button:GetName())
    end
end

--- Hide spell cast animation
-- @param button The button
function LAB:HideSpellCastAnim(button)
    if not button or not self.WoWRetail or not button._spellCastAnim then return end

    if button._spellCastAnim.Hide then
        button._spellCastAnim:Hide()
    end
end

-----------------------------------
-- STEP 9.1: FLYOUT SYSTEM (Complex)
-----------------------------------

-- Flyout button pool for reuse
LAB.flyoutButtons = {}
LAB.flyoutButtonPool = {}

--- Create a flyout button
-- @param parent The parent button
-- @param index The index in the flyout
-- @return button The flyout button
function LAB:CreateFlyoutButton(parent, index)
    local name = parent:GetName() .. "Flyout" .. index

    -- Don't use ActionBarButtonTemplate - it conflicts with Blizzard's action bar code
    -- Use SecureActionButtonTemplate only
    local button = CreateFrame("CheckButton", name, UIParent, "SecureActionButtonTemplate")

    if not button then
        self:Error("CreateFlyoutButton: Failed to create flyout button!", 2)
        return nil
    end

    -- Manually create button elements (since we're not using ActionBarButtonTemplate)
    button:SetSize(36, 36)

    -- Create icon
    button.icon = button:CreateTexture(name .. "Icon", "BACKGROUND")
    button.icon:SetAllPoints()
    button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    -- Create count
    button.Count = button:CreateFontString(name .. "Count", "OVERLAY", "NumberFontNormal")
    button.Count:SetPoint("BOTTOMRIGHT", -2, 2)

    -- Create hotkey
    button.HotKey = button:CreateFontString(name .. "HotKey", "OVERLAY", "NumberFontNormalSmallGray")
    button.HotKey:SetPoint("TOPLEFT", 1, -2)

    -- Create name
    button.Name = button:CreateFontString(name .. "Name", "OVERLAY", "GameFontHighlightSmallOutline")
    button.Name:SetPoint("BOTTOM", 0, 2)

    -- Create border
    button.Border = button:CreateTexture(name .. "Border", "OVERLAY")
    button.Border:SetAllPoints(button.icon)
    button.Border:Hide()

    -- Create normal texture
    button.NormalTexture = button:CreateTexture(name .. "NormalTexture", "ARTWORK")
    button.NormalTexture:SetAllPoints()
    button.NormalTexture:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    button:SetNormalTexture(button.NormalTexture)

    -- Set highlight
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

    -- Set pushed texture
    button:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")

    -- Initialize button elements
    self:InitializeButton(button)
    self:StyleButton(button)  -- Create _colors and apply default styling

    -- Store reference
    button._flyoutParent = parent
    button._flyoutIndex = index
    button.buttonType = LAB.ButtonType.ACTION

    -- Unregister from all Blizzard template events
    button:UnregisterAllEvents()

    -- Override Blizzard's OnEvent to use our event handling
    -- This prevents Blizzard's ActionButton code from running which expects action slots
    button:SetScript("OnEvent", function(self, event, ...)
        LAB:OnButtonEvent(self, event, ...)
    end)

    -- Register for our events
    for _, event in ipairs(self.UPDATE_EVENTS) do
        button:RegisterEvent(event)
    end

    -- Fire callback for flyout button creation (Phase 11 Item 26)
    self:FireCallback("OnFlyoutButtonCreated", button)

    return button
end

--- Release flyout button (hide and clean up)
-- @param button The flyout button to release
function LAB:ReleaseFlyoutButton(button)
    if not button then return end

    button:Hide()
    button:SetParent(nil)
    button:ClearAllPoints()
    button._flyoutParent = nil
    button._flyoutIndex = nil

    -- Note: We no longer pool buttons since frames can't be renamed
    -- The button will be garbage collected when no longer referenced
end

--- Get flyout info for action
-- @param actionID The action ID
-- @return boolean, numSlots, direction Whether action is flyout, number of slots, direction
function LAB:GetFlyoutInfo(actionID)
    if not actionID or actionID == 0 then return false, 0, nil end

    -- Check if action is a flyout
    local actionType, id = GetActionInfo(actionID)

    if actionType == "flyout" then
        local name, description, numSlots, isKnown = GetFlyoutInfo(id)
        local direction = "UP" -- Default direction

        return true, numSlots, direction
    end

    return false, 0, nil
end

--- Show flyout for button
-- @param button The button
function LAB:ShowFlyout(button)
    if not button or not button.buttonType == "action" or not button.action then return end

    local isFlyout, numSlots, direction = self:GetFlyoutInfo(button.action)

    if not isFlyout or numSlots == 0 then return end

    self:DebugPrint(string.format("ShowFlyout: %s slots=%d dir=%s", button:GetName(), numSlots, direction))

    -- Hide any existing flyout
    self:HideFlyout(button)

    -- Create flyout buttons
    local flyoutButtons = {}

    for i = 1, numSlots do
        local flyoutButton = self:CreateFlyoutButton(button, i)

        if flyoutButton then
            -- Get the flyout ID from the action
            local actionType, flyoutID = GetActionInfo(button.action)

            if actionType == "flyout" and flyoutID then
                -- Get flyout slot info - note this uses flyoutID, not action ID
                local spellID, overrideSpellID, isKnown, spellName, slotSpecID = GetFlyoutSlotInfo(flyoutID, i)

                if spellID and isKnown then
                    -- Set up flyout button as a spell button
                    flyoutButton.buttonType = LAB.ButtonType.SPELL
                    flyoutButton.buttonAction = spellID
                    flyoutButton.UpdateFunctions = LAB.SpellTypeUpdateFunctions
                    flyoutButton.action = nil  -- Clear action slot reference
                    flyoutButton:SetAttribute("type", "spell")
                    flyoutButton:SetAttribute("spell", spellID)

                    -- Position flyout button
                    self:PositionFlyoutButton(button, flyoutButton, i, numSlots, direction)

                    -- Update and show
                    self:UpdateButton(flyoutButton)
                    flyoutButton:Show()

                    table.insert(flyoutButtons, flyoutButton)
                else
                    -- Slot doesn't exist or spell not known - release button back to pool
                    self:ReleaseFlyoutButton(flyoutButton)
                end
            else
                -- Not a flyout - release button
                self:ReleaseFlyoutButton(flyoutButton)
            end
        end
    end

    -- Store flyout buttons on parent
    button._flyoutButtons = flyoutButtons

    -- Create/show flyout arrow (Feature 18: Complete flyout system)
    if not button._flyoutArrow then
        button._flyoutArrow = button:CreateTexture(nil, "OVERLAY", nil, 1)
        button._flyoutArrow:SetSize(16, 16)
        -- Position based on direction
        if direction == "UP" then
            button._flyoutArrow:SetPoint("TOP", button, "TOP", 0, 4)
            button._flyoutArrow:SetTexture("Interface\\Buttons\\Arrow-Up-Up")
        elseif direction == "DOWN" then
            button._flyoutArrow:SetPoint("BOTTOM", button, "BOTTOM", 0, -4)
            button._flyoutArrow:SetTexture("Interface\\Buttons\\Arrow-Down-Up")
        elseif direction == "LEFT" then
            button._flyoutArrow:SetPoint("LEFT", button, "LEFT", -4, 0)
            button._flyoutArrow:SetTexture("Interface\\Buttons\\Arrow-Left-Up")
        else -- RIGHT
            button._flyoutArrow:SetPoint("RIGHT", button, "RIGHT", 4, 0)
            button._flyoutArrow:SetTexture("Interface\\Buttons\\Arrow-Right-Up")
        end
    end
    button._flyoutArrow:Show()
end

--- Hide flyout for button
-- @param button The button
function LAB:HideFlyout(button)
    if not button or not button._flyoutButtons then return end

    for _, flyoutButton in ipairs(button._flyoutButtons) do
        self:ReleaseFlyoutButton(flyoutButton)
    end

    button._flyoutButtons = nil

    -- Hide flyout arrow
    if button._flyoutArrow then
        button._flyoutArrow:Hide()
    end
end

--- Position flyout button relative to parent
-- @param parent The parent button
-- @param flyoutButton The flyout button
-- @param index The flyout index
-- @param numSlots Total number of flyout slots
-- @param direction The flyout direction (UP/DOWN/LEFT/RIGHT)
function LAB:PositionFlyoutButton(parent, flyoutButton, index, numSlots, direction)
    if not parent or not flyoutButton then return end

    local size = parent:GetWidth()
    local spacing = 2
    direction = direction or "UP"

    flyoutButton:SetSize(size, size)

    if direction == "UP" then
        flyoutButton:SetPoint("BOTTOM", parent, "TOP", 0, (index - 1) * (size + spacing))
    elseif direction == "DOWN" then
        flyoutButton:SetPoint("TOP", parent, "BOTTOM", 0, -(index - 1) * (size + spacing))
    elseif direction == "LEFT" then
        flyoutButton:SetPoint("RIGHT", parent, "LEFT", -(index - 1) * (size + spacing), 0)
    elseif direction == "RIGHT" then
        flyoutButton:SetPoint("LEFT", parent, "RIGHT", (index - 1) * (size + spacing), 0)
    end
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
-- PHASE 11: COMPLETE FEATURE PARITY (27 ITEMS)
-----------------------------------

--[[
    Phase 11 implements the remaining 27 features to achieve 100% feature parity with LibActionButton-1.0

    HIGH PRIORITY (11): Core functionality
    MEDIUM PRIORITY (9): Retail-specific features
    LOW PRIORITY (7): Legacy/optional features
]]

-----------------------------------
-- PHASE 11 - HIGH PRIORITY (Items 1-11)
-----------------------------------

--- Get all registered buttons (returns iterator)
-- @return iterator function for all buttons
-- Phase 11 Item 1
function LAB:GetAllButtons()
    return pairs(self.buttons)
end

--- Update state on all buttons
-- @param newState The new state to apply to all buttons
-- Phase 11 Item 2
function LAB:UpdateAllStates(newState)
    if not newState then return end

    for button in pairs(self.buttons) do
        if button._currentState ~= newState then
            self:UpdateState(button, newState)
        end
    end
end

--- Update button tooltip display
-- @param button The button to update tooltip for
-- Phase 11 Item 3
function LAB:UpdateTooltip(button)
    if not button then return end

    -- Check tooltip config and update button's tooltip mode
    local tooltipMode = "enabled" -- default
    if button.config and button.config.tooltip then
        tooltipMode = button.config.tooltip
    end

    -- Store tooltip mode on button for ShouldShowTooltip to use
    button._tooltipMode = tooltipMode

    -- If tooltip is currently showing and should be hidden, hide it
    if GameTooltip:GetOwner() == button then
        if tooltipMode == "disabled" or (tooltipMode == "nocombat" and InCombatLockdown()) then
            GameTooltip:Hide()
        else
            -- Re-trigger OnEnter to update tooltip
            self:OnButtonEnter(button)
        end
    end
end

--- Local update - updates visual state only without full action lookup
-- @param button The button to update
-- Phase 11 Item 4
function LAB:UpdateLocal(button)
    if not button then return end

    -- Update only visual states, don't do expensive action lookups
    self:UpdateUsable(button)
    self:UpdateRange(button)
    self:UpdateCooldown(button)
    self:UpdateCount(button)
end

--- Update button alpha transparency
-- @param button The button to update
-- Phase 11 Item 5
function LAB:UpdateAlpha(button)
    if not button then return end

    local alpha = 1.0 -- default

    -- Check for config alpha
    if button.config and button.config.alpha then
        alpha = button.config.alpha
    end

    -- Reduce alpha for out of range (if configured)
    if button._state and button._state.outOfRange then
        if button.config and button.config.outOfRangeAlpha then
            alpha = alpha * button.config.outOfRangeAlpha
        end
    end

    -- Apply alpha
    button:SetAlpha(alpha)
end

--- Global table tracking new action highlights (matches LAB-1.0)
LAB.ACTION_HIGHLIGHT_MARKS = LAB.ACTION_HIGHLIGHT_MARKS or setmetatable({}, { __index = ACTION_HIGHLIGHT_MARKS or {} })

--- Clear new action highlight from specific action(s)
-- @param action The action ID to clear highlight from
-- @param preventIdenticalActionsFromClearing Don't clear from identical actions
-- @param value The mark value (optional)
-- Phase 11 Item 6
function LAB:ClearNewActionHighlight(action, preventIdenticalActionsFromClearing, value)
    if not action then return end

    -- Clear from ACTION_HIGHLIGHT_MARKS
    if not preventIdenticalActionsFromClearing then
        self.ACTION_HIGHLIGHT_MARKS[action] = nil
    end

    -- Clear from all buttons with this action
    for button in pairs(self.buttons) do
        if button.buttonType == "action" and button.action == action then
            if button.NewActionTexture then
                button.NewActionTexture:Hide()
            end

            -- Fire callback if needed
            if not preventIdenticalActionsFromClearing then
                self:FireCallback("OnButtonContentsChanged", button)
            end
        end
    end
end

--- Update cooldown number visibility
-- @param button The button to update
-- Phase 11 Item 7
function LAB:UpdateCooldownNumberHidden(button)
    if not button or not button._cooldown then return end

    local hideNumbers = false

    -- Check button config first
    if button.config and button.config.cooldownCount ~= nil then
        -- Explicit config overrides CVar
        hideNumbers = not button.config.cooldownCount
    else
        -- Use CVar setting (default behavior)
        local cvarValue = GetCVar("countdownForCooldowns")
        if cvarValue then
            hideNumbers = (cvarValue == "0")
        end
    end

    -- Apply to cooldown frame
    if button._cooldown.SetHideCountdownNumbers then
        button._cooldown:SetHideCountdownNumbers(hideNumbers)
    end

    -- Also apply to charge cooldown if it exists
    if button.chargeCooldown and button.chargeCooldown.SetHideCountdownNumbers then
        button.chargeCooldown:SetHideCountdownNumbers(hideNumbers)
    end
end

--- Fire ButtonContentsChanged callback when button contents change
-- This is called from UpdateAction and SetState
-- @param button The button whose contents changed
-- @param state The state that changed (optional)
-- @param buttonType The button type (optional)
-- @param action The action value (optional)
-- Phase 11 Item 10 (implemented inline in UpdateAction and SetState)
function LAB:ButtonContentsChanged(button, state, buttonType, action)
    if not button then return end

    self:FireCallback("OnButtonContentsChanged", button, state or button._currentState, buttonType or button.buttonType, action or button.buttonAction)
end

-----------------------------------
-- PHASE 11 - KEYBINDING METHODS (Items 8-9, 11)
-----------------------------------

--- Get all key bindings for a button (button instance method)
-- @return table of key binding strings
-- Phase 11 Item 8
-- Note: This is set up in EnableKeyBound, adding standalone method here
function LAB:GetAllBindings(button)
    if not button or not button.action then return {} end

    local bindings = {}
    -- WoW allows up to 36 bindings per action
    for i = 1, 36 do
        local hotkey = GetBindingKey("ACTIONBUTTON" .. button.action, i)
        if hotkey then
            table.insert(bindings, hotkey)
        end
    end

    return bindings
end

--- Clear all key bindings for a button (button instance method)
-- Phase 11 Item 9
function LAB:ClearAllBindings(button)
    if not button or not button.action then return end

    local bindings = self:GetAllBindings(button)

    for _, key in ipairs(bindings) do
        SetBinding(key, nil)
    end

    SaveBindings(GetCurrentBindingSet())
    self:UpdateHotkey(button)

    -- Fire callback
    self:FireCallback("OnKeybindingChanged", button, nil)
end

-- Note: OnKeybindingChanged callback is fired in EnableKeyBound's SetKey method
-- Phase 11 Item 11 - callback already implemented in existing EnableKeyBound

-----------------------------------
-- PHASE 11 - MEDIUM PRIORITY (Items 12-21) - Retail Features
-----------------------------------

--- Update spell highlight animation (proc glows)
-- @param button The button to update
-- Phase 11 Item 12
function LAB:UpdateSpellHighlight(button)
    if not self.WoWRetail or not button then return end

    -- Check if button has SpellHighlightAnim (from template)
    if not button.SpellHighlightAnim then return end

    local spellID = button.UpdateFunctions and button.UpdateFunctions.GetSpellId and button.UpdateFunctions.GetSpellId(button)
    if not spellID then
        button.SpellHighlightAnim:Stop()
        return
    end

    -- Check if spell should be highlighted
    local shouldHighlight = false

    if IsSpellOverlayed and IsSpellOverlayed(spellID) then
        shouldHighlight = true
    elseif C_SpellActivationOverlay and C_SpellActivationOverlay.IsSpellOverlayed then
        shouldHighlight = C_SpellActivationOverlay.IsSpellOverlayed(spellID)
    end

    if shouldHighlight then
        button.SpellHighlightAnim:Play()
    else
        button.SpellHighlightAnim:Stop()
    end
end

--- Update assisted combat rotation frame (Retail only)
-- @param button The button to update
-- Phase 11 Item 13
function LAB:UpdateAssistedCombatRotationFrame(button)
    if not self.WoWRetail or not button then return end

    -- Check if feature is enabled in config
    if not button.config or not button.config.actionButtonUI or not button.config.assistedHighlight then
        if button.AssistedCombatRotationFrame then
            button.AssistedCombatRotationFrame:Hide()
        end
        return
    end

    -- Only for action buttons
    if button.buttonType ~= "action" or not button.action then
        return
    end

    -- Check if this action is part of assisted combat rotation
    local isAssisted = false
    if C_ActionBar and C_ActionBar.IsAssistedCombatAction then
        isAssisted = C_ActionBar.IsAssistedCombatAction(button.action)
    end

    if isAssisted then
        -- Create frame if it doesn't exist
        if not button.AssistedCombatRotationFrame then
            button.AssistedCombatRotationFrame = CreateFrame("Frame", nil, button)
            button.AssistedCombatRotationFrame:SetAllPoints(button._icon or button)

            -- Create texture
            button.AssistedCombatRotationFrame.Texture = button.AssistedCombatRotationFrame:CreateTexture(nil, "OVERLAY", nil, 3)
            button.AssistedCombatRotationFrame.Texture:SetAllPoints()
            button.AssistedCombatRotationFrame.Texture:SetTexture("Interface\\Cooldown\\star4")
            button.AssistedCombatRotationFrame.Texture:SetBlendMode("ADD")

            -- Fire callback for frame creation
            self:FireCallback("OnAssistedCombatRotationFrameCreated", button, button.AssistedCombatRotationFrame)
        end

        button.AssistedCombatRotationFrame:Show()
    else
        if button.AssistedCombatRotationFrame then
            button.AssistedCombatRotationFrame:Hide()
        end
    end
end

--- Update assisted combat highlight frame (Retail only)
-- @param button The button to update
-- Phase 11 Item 14
function LAB:UpdatedAssistedHighlightFrame(button)
    if not self.WoWRetail or not button then return end

    -- Check if feature is enabled in config
    if not button.config or not button.config.actionButtonUI or not button.config.assistedHighlight then
        if button.AssistedHighlightFrame then
            button.AssistedHighlightFrame:Hide()
        end
        return
    end

    -- Only for action buttons
    if button.buttonType ~= "action" or not button.action then
        return
    end

    -- Check if this action should be highlighted
    local shouldHighlight = false
    if C_ActionBar and C_ActionBar.IsAssistedCombatAction then
        shouldHighlight = C_ActionBar.IsAssistedCombatAction(button.action)
    end

    if shouldHighlight then
        -- Create frame if it doesn't exist
        if not button.AssistedHighlightFrame then
            button.AssistedHighlightFrame = CreateFrame("Frame", nil, button)
            button.AssistedHighlightFrame:SetAllPoints(button._icon or button)
            button.AssistedHighlightFrame:SetFrameLevel(button:GetFrameLevel() + 4)

            -- Create pulse texture
            button.AssistedHighlightFrame.Texture = button.AssistedHighlightFrame:CreateTexture(nil, "OVERLAY", nil, 4)
            button.AssistedHighlightFrame.Texture:SetAllPoints()
            button.AssistedHighlightFrame.Texture:SetColorTexture(1, 1, 1, 0.3)
            button.AssistedHighlightFrame.Texture:SetBlendMode("ADD")

            -- Create animation
            button.AssistedHighlightFrame.AnimGroup = button.AssistedHighlightFrame.Texture:CreateAnimationGroup()
            local anim = button.AssistedHighlightFrame.AnimGroup:CreateAnimation("Alpha")
            anim:SetFromAlpha(0.3)
            anim:SetToAlpha(0.7)
            anim:SetDuration(0.5)
            anim:SetSmoothing("IN_OUT")
            button.AssistedHighlightFrame.AnimGroup:SetLooping("BOUNCE")

            -- Fire callback for frame creation
            self:FireCallback("OnAssistedCombatHighlightFrameCreated", button, button.AssistedHighlightFrame)
        end

        button.AssistedHighlightFrame:Show()
        button.AssistedHighlightFrame.AnimGroup:Play()
    else
        if button.AssistedHighlightFrame then
            button.AssistedHighlightFrame.AnimGroup:Stop()
            button.AssistedHighlightFrame:Hide()
        end
    end
end

-----------------------------------
-- PHASE 11 - SPELLVFX SYSTEM (Items 15-21) - Retail Only
-----------------------------------

--- Clear targeting reticle animation
-- @param button The button to clear reticle from
-- Phase 11 Item 15
function LAB:SpellVFX_ClearReticle(button)
    if not self.WoWRetail or not button then return end

    if button.SpellReticleTargetIndicator then
        button.SpellReticleTargetIndicator:Hide()
    end
end

--- Clear interrupt display (alias to existing method)
-- @param button The button to clear interrupt from
-- Phase 11 Item 16
function LAB:SpellVFX_ClearInterruptDisplay(button)
    -- This is an alias to our existing HideInterruptDisplay method
    self:HideInterruptDisplay(button)
end

--- Play spell cast animation
-- @param button The button to play animation on
-- Phase 11 Item 17
function LAB:SpellVFX_PlaySpellCastAnim(button)
    if not self.WoWRetail or not button then return end

    -- Check if VFX is enabled
    if not button.config or not button.config.spellCastVFX then return end

    if button.SpellCastAnimFrame then
        button.SpellCastAnimFrame:Show()
        if button.SpellCastAnimFrame.Anim then
            button.SpellCastAnimFrame.Anim:Play()
        end
    end
end

--- Play targeting reticle animation
-- @param button The button to play reticle on
-- Phase 11 Item 18
function LAB:SpellVFX_PlayTargettingReticleAnim(button)
    if not self.WoWRetail or not button then return end

    -- Check if VFX is enabled
    if not button.config or not button.config.spellCastVFX then return end

    if button.SpellReticleTargetIndicator then
        button.SpellReticleTargetIndicator:Show()
        if button.SpellReticleTargetIndicator.Anim then
            button.SpellReticleTargetIndicator.Anim:Play()
        end
    end
end

--- Stop targeting reticle animation
-- @param button The button to stop reticle on
-- Phase 11 Item 19
function LAB:SpellVFX_StopTargettingReticleAnim(button)
    if not self.WoWRetail or not button then return end

    if button.SpellReticleTargetIndicator then
        if button.SpellReticleTargetIndicator.Anim then
            button.SpellReticleTargetIndicator.Anim:Stop()
        end
        button.SpellReticleTargetIndicator:Hide()
    end
end

--- Stop spell cast animation
-- @param button The button to stop animation on
-- Phase 11 Item 20
function LAB:SpellVFX_StopSpellCastAnim(button)
    if not self.WoWRetail or not button then return end

    if button.SpellCastAnimFrame then
        if button.SpellCastAnimFrame.Anim then
            button.SpellCastAnimFrame.Anim:Stop()
        end
        button.SpellCastAnimFrame:Hide()
    end
end

--- Play spell interrupted animation
-- @param button The button to play interrupt on
-- Phase 11 Item 21
function LAB:SpellVFX_PlaySpellInterruptedAnim(button)
    if not self.WoWRetail or not button then return end

    -- Check if VFX is enabled
    if not button.config or not button.config.spellCastVFX then return end

    -- Use our existing ShowInterruptDisplay method
    self:ShowInterruptDisplay(button)
end

-----------------------------------
-- PHASE 11 - LOW PRIORITY (Items 22-28) - Legacy/Optional
-----------------------------------

--- Add button to ButtonFacade skinning group (legacy)
-- @param button The button to skin
-- @param group The ButtonFacade group
-- Phase 11 Item 22
function LAB:AddToButtonFacade(button, group)
    if not button then return end

    -- Try to get ButtonFacade library
    local BF = LibStub and LibStub("ButtonFacade", true)
    if not BF then
        self:DebugPrint("ButtonFacade not found, skipping AddToButtonFacade")
        return
    end

    -- Create button data structure for ButtonFacade
    local buttonData = {
        Button = button,
        Icon = button._icon,
        Cooldown = button._cooldown,
        Normal = button._normalTexture,
        Border = button._border,
        Count = button._count,
        HotKey = button._hotkey,
        Name = button._name,
    }

    -- Register with ButtonFacade
    if group and group.AddButton then
        group:AddButton(button, buttonData)
    elseif BF.Group and BF:Group("LibTotalActionButtons") then
        BF:Group("LibTotalActionButtons"):AddButton(button, buttonData)
    end
end

--- Get the spell flyout frame reference
-- @return The flyout frame or nil
-- Phase 11 Item 23
function LAB:GetSpellFlyoutFrame()
    return self.flyoutFrame or nil
end

--- Update flyout display when contents change
-- @param button The button to update flyout for
-- Phase 11 Item 24
function LAB:UpdateFlyout(button)
    if not button then return end

    -- Check if button has a flyout
    local isFlyout, numSlots, direction = self:GetFlyoutInfo(button.action)

    if not isFlyout then
        -- Hide flyout if it was showing
        self:HideFlyout(button)

        -- Hide flyout arrow
        if button._flyoutArrow then
            button._flyoutArrow:Hide()
        end
        return
    end

    -- Update flyout arrow visibility
    if not button._flyoutArrow then
        button._flyoutArrow = button:CreateTexture(nil, "OVERLAY", nil, 1)
        button._flyoutArrow:SetSize(16, 16)
    end

    -- Position arrow based on direction
    button._flyoutArrow:ClearAllPoints()
    if direction == "UP" then
        button._flyoutArrow:SetPoint("TOP", button, "TOP", 0, 4)
        button._flyoutArrow:SetTexture("Interface\\Buttons\\Arrow-Up-Up")
    elseif direction == "DOWN" then
        button._flyoutArrow:SetPoint("BOTTOM", button, "BOTTOM", 0, -4)
        button._flyoutArrow:SetTexture("Interface\\Buttons\\Arrow-Down-Up")
    elseif direction == "LEFT" then
        button._flyoutArrow:SetPoint("LEFT", button, "LEFT", -4, 0)
        button._flyoutArrow:SetTexture("Interface\\Buttons\\Arrow-Left-Up")
    else -- RIGHT
        button._flyoutArrow:SetPoint("RIGHT", button, "RIGHT", 4, 0)
        button._flyoutArrow:SetTexture("Interface\\Buttons\\Arrow-Right-Up")
    end

    button._flyoutArrow:Show()

    -- If flyout is currently showing, refresh it
    if button._flyoutButtons and #button._flyoutButtons > 0 then
        self:HideFlyout(button)
        self:ShowFlyout(button)
    end
end

-- Initialize FlyoutInfo registry (Phase 11 Item 25)
LAB.FlyoutInfo = LAB.FlyoutInfo or {}

--- Discover and cache flyout spell information
-- @param flyoutID The flyout ID to discover
-- Phase 11 Item 25
function LAB:DiscoverFlyoutInfo(flyoutID)
    if not flyoutID or not GetFlyoutInfo then return end

    local name, description, numSlots, isKnown = GetFlyoutInfo(flyoutID)
    if not name then return end

    -- Cache flyout info
    self.FlyoutInfo[flyoutID] = {
        name = name,
        description = description,
        numSlots = numSlots,
        isKnown = isKnown,
        slots = {}
    }

    -- Discover slot info
    for i = 1, numSlots do
        local spellID, overrideSpellID, isSlotKnown, spellName, slotSpecID = GetFlyoutSlotInfo(flyoutID, i)
        if spellID then
            -- Phase 13 Feature #8: Filter out empty pet slots
            if GetCallPetSpellInfo then
                local petIndex, petName = GetCallPetSpellInfo(spellID)
                if petIndex and (not petName or petName == "") then
                    -- Empty pet slot - don't show it
                    isSlotKnown = false
                end
            end

            self.FlyoutInfo[flyoutID].slots[i] = {
                spellID = spellID,
                overrideSpellID = overrideSpellID,
                isKnown = isSlotKnown,
                spellName = spellName,
                slotSpecID = slotSpecID,
            }
        end
    end
end

-- Phase 11 Item 26: OnFlyoutButtonCreated callback
-- This is now fired in CreateFlyoutButton method

-- Phase 11 Items 27-28: Assisted combat callbacks
-- These are now fired in UpdateAssistedCombatRotationFrame and UpdatedAssistedHighlightFrame

-----------------------------------
-- PHASE 12: SECURE TEMPLATE ARCHITECTURE (6 ITEMS)
-----------------------------------

--[[
    Phase 12 implements secure template features for combat functionality:

    SIMPLE METHODS (3):
    1. ClearSetPoint - Convenience method
    2. SetStateFromHandlerInsecure - Data storage for secure handlers
    3. NewHeader - Reassign button to different header

    SECURE TEMPLATE SYSTEM (3):
    4. SetupSecureSnippets - Secure Lua code for combat
    5. WrapOnClick - Secure click handler wrapping
    6. Secure Flyout Handler - Flyouts that work in combat

    These features enable buttons to work properly during combat.
]]

-----------------------------------
-- PHASE 12 - SIMPLE METHODS (Items 1-3)
-----------------------------------

--- Clear all points and set new point(s) in one call
-- @param button The button to reposition
-- @param ... SetPoint arguments (point, relativeTo, relativePoint, x, y)
-- Phase 12 Item 1
function LAB:ClearSetPoint(button, ...)
    if not button then return end

    button:ClearAllPoints()
    button:SetPoint(...)
end

--- Set state data from secure handler (called by secure snippets)
-- This is the data storage counterpart to SetState
-- @param button The button to update
-- @param state The state identifier
-- @param kind The button type (action, spell, item, macro, custom, empty)
-- @param action The action value (actionID, spellID, itemID, macroID, or custom data)
-- Phase 12 Item 2
function LAB:SetStateFromHandlerInsecure(button, state, kind, action)
    if not button then return end

    state = tostring(state or "0")
    kind = kind or "empty"

    -- Validate kind
    local validKinds = {
        empty = true,
        action = true,
        spell = true,
        item = true,
        macro = true,
        custom = true,
    }

    if not validKinds[kind] then
        self:Error("SetStateFromHandlerInsecure: unknown action type: " .. tostring(kind), 2)
        return
    end

    -- Validate action for non-empty states
    if kind ~= "empty" and kind ~= "custom" and action == nil then
        self:Error("SetStateFromHandlerInsecure: action required for non-empty states", 2)
        return
    end

    -- Validate action data type
    if kind ~= "empty" and kind ~= "custom" and action ~= nil then
        if type(action) ~= "number" and type(action) ~= "string" then
            self:Error("SetStateFromHandlerInsecure: invalid action data type, only strings and numbers allowed", 2)
            return
        end
    end

    if kind == "custom" and action ~= nil and type(action) ~= "table" then
        self:Error("SetStateFromHandlerInsecure: custom actions must be tables", 2)
        return
    end

    -- Handle item format conversion
    if kind == "item" then
        if tonumber(action) then
            -- Convert number to item string format
            action = string.format("item:%s", action)
        else
            -- Extract item string from item link if needed
            local itemString = string.match(tostring(action), "^|c[^|]+|H(item[%d:]+)|h%[")
            if itemString then
                action = itemString
            end
        end
    end

    -- Initialize state tables if needed
    if not button.stateTypes then
        button.stateTypes = {}
    end
    if not button.stateActions then
        button.stateActions = {}
    end

    -- Store state data
    -- NOTE: This does NOT trigger UpdateState or UpdateAction
    -- Secure handler code is responsible for calling those
    button.stateTypes[state] = kind
    button.stateActions[state] = action

    self:DebugPrint(string.format("SetStateFromHandlerInsecure: button=%s, state=%s, kind=%s, action=%s",
        button:GetName() or "unnamed", state, kind, tostring(action)))
end

--- Reassign button to a different secure header
-- @param button The button to reassign
-- @param header The new secure header parent
-- Phase 12 Item 3
function LAB:NewHeader(button, header)
    if not button or not header then
        self:Error("NewHeader: button and header are required", 2)
        return
    end

    local oldheader = button.header
    button.header = header
    button:SetParent(header)

    -- If button has secure snippets, set them up with new header
    if button._hasSecureSnippets then
        self:SetupSecureSnippets(button)
    end

    -- If button has wrapped click, re-wrap with new header
    if button._hasWrappedClick then
        self:WrapOnClick(button, oldheader)
    end

    self:DebugPrint(string.format("NewHeader: button=%s, old=%s, new=%s",
        button:GetName() or "unnamed",
        oldheader and oldheader:GetName() or "nil",
        header:GetName() or "unnamed"))
end

-----------------------------------
-- PHASE 12 - SECURE TEMPLATE SYSTEM (Items 4-6)
-----------------------------------

--- Set up secure Lua snippets for combat-safe operation
-- This enables state switching, drag & drop, and updates during combat
-- @param button The button to set up secure snippets for
-- Phase 12 Item 4
function LAB:SetupSecureSnippets(button)
    if not button or not button.header then
        self:Error("SetupSecureSnippets: button with secure header required", 2)
        return
    end

    -- Mark that button has secure snippets
    button._hasSecureSnippets = true

    -- Set up custom action handler (for custom button types)
    if button.UpdateFunctions and button.UpdateFunctions.RunCustom then
        button:SetAttribute("_custom", button.UpdateFunctions.RunCustom)
    end

    -- Secure UpdateState snippet - runs during combat when state changes
    button:SetAttribute("UpdateState", [[
        local state = ...
        self:SetAttribute("state", state)

        -- Get the type and action for this state
        local type = self:GetAttribute(format("labtype-%s", state)) or "empty"
        local action = self:GetAttribute(format("labaction-%s", state))

        -- Update secure attributes based on type
        self:SetAttribute("type", type)

        if type ~= "empty" and type ~= "custom" then
            -- For action, spell, item, macro types, set the appropriate attribute
            local action_field = (type == "pet") and "action" or type
            self:SetAttribute(action_field, action)
            self:SetAttribute("action_field", action_field)
        end

        -- Handle press-and-hold spells (Retail feature)
        if IsPressHoldReleaseSpell then
            local pressAndHold = false

            if type == "action" then
                self:SetAttribute("typerelease", "actionrelease")
                local actionType, id, subType = GetActionInfo(action)
                if actionType == "spell" then
                    pressAndHold = IsPressHoldReleaseSpell(id)
                elseif actionType == "macro" then
                    if subType == "spell" then
                        pressAndHold = IsPressHoldReleaseSpell(id)
                    end
                end
            elseif type == "spell" then
                self:SetAttribute("typerelease", nil)
                pressAndHold = IsPressHoldReleaseSpell(action)
            else
                self:SetAttribute("typerelease", nil)
            end

            self:SetAttribute("pressAndHoldAction", pressAndHold)
        end

        -- Call OnStateChanged handler if defined
        local onStateChanged = self:GetAttribute("OnStateChanged")
        if onStateChanged then
            self:Run(onStateChanged, state, type, action)
        end
    ]])

    -- State update trigger from header
    button:SetAttribute("_childupdate-state", [[
        self:RunAttribute("UpdateState", message)
        self:CallMethod("UpdateAction")
    ]])

    -- Secure PickupButton snippet - handles pickup during drag
    button:SetAttribute("PickupButton", [[
        local kind, value = ...
        if kind == "empty" then
            return "clear"
        elseif kind == "action" or kind == "pet" then
            local actionType = (kind == "pet") and "petaction" or kind
            return actionType, value
        elseif kind == "spell" or kind == "item" or kind == "macro" then
            return "clear", kind, value
        else
            print("LibTotalActionButtons: Unknown type: " .. tostring(kind))
            return false
        end
    ]])

    -- Secure OnDragStart - handles drag during combat
    button:SetAttribute("OnDragStart", [[
        if (self:GetAttribute("buttonlock") and not IsModifiedClick("PICKUPACTION")) or self:GetAttribute("LABdisableDragNDrop") then
            return false
        end

        local state = self:GetAttribute("state")
        local type = self:GetAttribute("type")

        -- Can't drag empty or custom buttons
        if type == "empty" or type == "custom" then
            return false
        end

        -- Get the action value
        local action_field = self:GetAttribute("action_field")
        local action = self:GetAttribute(action_field)

        -- Non-action buttons need to clear themselves when dragged
        if type ~= "action" and type ~= "pet" then
            self:SetAttribute(format("labtype-%s", state), "empty")
            self:SetAttribute(format("labaction-%s", state), nil)
            self:RunAttribute("UpdateState", state)
            self:CallMethod("ButtonContentsChanged", state, "empty", nil)
        end

        -- Return pickup info
        return self:RunAttribute("PickupButton", type, action)
    ]])

    -- Secure OnReceiveDrag - handles drop during combat
    button:SetAttribute("OnReceiveDrag", [[
        if self:GetAttribute("LABdisableDragNDrop") then
            return false
        end

        local kind, value, subtype, extra = ...
        if not kind or not value then return false end

        local state = self:GetAttribute("state")
        local buttonType = self:GetAttribute("type")
        local buttonAction = nil

        if buttonType == "custom" then return false end

        -- Action buttons handle themselves
        -- Other buttons need manual update
        if buttonType ~= "action" and buttonType ~= "pet" then
            -- For spell type, 4th value contains actual spell ID
            if kind == "spell" then
                if extra then
                    value = extra
                else
                    print("LibTotalActionButtons: No spell ID in drag data")
                end
            elseif kind == "item" and value then
                value = format("item:%d", value)
            end

            -- Get old action before replacing
            if buttonType ~= "empty" then
                buttonAction = self:GetAttribute(self:GetAttribute("action_field"))
            end

            -- Set new action
            self:SetAttribute(format("labtype-%s", state), kind)
            self:SetAttribute(format("labaction-%s", state), value)
            self:RunAttribute("UpdateState", state)
            self:CallMethod("ButtonContentsChanged", state, kind, value)
        else
            -- Get action from action button
            buttonAction = self:GetAttribute("action")
        end

        return self:RunAttribute("PickupButton", buttonType, buttonAction)
    ]])

    -- Set up drag/drop scripts using header wrapping
    button:SetScript("OnDragStart", nil)
    button.header:WrapScript(button, "OnDragStart", [[
        return self:RunAttribute("OnDragStart")
    ]])

    -- Wrap twice for post-script execution
    button.header:WrapScript(button, "OnDragStart", [[
        return "message", "update"
    ]], [[
        self:RunAttribute("UpdateState", self:GetAttribute("state"))
    ]])

    button:SetScript("OnReceiveDrag", nil)
    button.header:WrapScript(button, "OnReceiveDrag", [[
        return self:RunAttribute("OnReceiveDrag", kind, value, ...)
    ]])

    -- Wrap twice for post-script execution
    button.header:WrapScript(button, "OnReceiveDrag", [[
        return "message", "update"
    ]], [[
        self:RunAttribute("UpdateState", self:GetAttribute("state"))
    ]])

    self:DebugPrint(string.format("SetupSecureSnippets: %s configured", button:GetName() or "unnamed"))
end

--- Wrap button's OnClick handler with secure code
-- Enables action change detection, flyout handling, and drag prevention during combat
-- @param button The button to wrap OnClick for
-- @param unwrapheader Optional old header to unwrap from
-- Phase 12 Item 5
function LAB:WrapOnClick(button, unwrapheader)
    if not button or not button.header then
        self:Error("WrapOnClick: button with secure header required", 2)
        return
    end

    -- Mark that button has wrapped click
    button._hasWrappedClick = true

    -- Unwrap from old header if provided
    if unwrapheader and unwrapheader.UnwrapScript then
        local wrapheader
        repeat
            wrapheader = unwrapheader:UnwrapScript(button, "OnClick")
        until (not wrapheader or wrapheader == unwrapheader)
    end

    -- Get reference to flyout handler if available
    if self.flyoutHandler then
        button.header:SetFrameRef("flyoutHandler", self.flyoutHandler)
    end

    -- Wrap OnClick to catch action changes and handle flyouts
    button.header:WrapScript(button, "OnClick", [[
        if self:GetAttribute("type") == "action" then
            local type, action = GetActionInfo(self:GetAttribute("action"))

            -- Handle flyout actions
            if type == "flyout" and self:GetAttribute("LABUseCustomFlyout") then
                local flyoutHandler = owner:GetFrameRef("flyoutHandler")
                if not down and flyoutHandler then
                    flyoutHandler:SetAttribute("flyoutParentHandle", self)
                    flyoutHandler:RunAttribute("HandleFlyout", action)
                end

                self:CallMethod("UpdateFlyout")
                return false
            end

            -- Hide flyout if showing
            local flyoutHandler = owner:GetFrameRef("flyoutHandler")
            if flyoutHandler then
                flyoutHandler:Hide()
            end

            -- Handle pickup clicks - disable on-down to prevent accidental casts
            if button ~= "Keybind" and ((self:GetAttribute("unlockedpreventdrag") and not self:GetAttribute("buttonlock")) or IsModifiedClick("PICKUPACTION")) and not self:GetAttribute("LABdisableDragNDrop") then
                local useOnkeyDown = self:GetAttribute("useOnKeyDown")
                if useOnkeyDown ~= false then
                    self:SetAttribute("LABToggledOnDown", true)
                    self:SetAttribute("LABToggledOnDownBackup", useOnkeyDown)
                    self:SetAttribute("useOnKeyDown", false)
                end
            end

            return (button == "Keybind") and "LeftButton" or nil, format("%s|%s", tostring(type), tostring(action))
        end

        -- Hide flyout for non-action clicks
        local flyoutHandler = owner:GetFrameRef("flyoutHandler")
        if flyoutHandler and (not down or self:GetParent() ~= flyoutHandler) then
            flyoutHandler:Hide()
        end

        if button == "Keybind" then
            return "LeftButton"
        end
    ]], [[
        -- Post-click: Check if action changed
        local type, action = GetActionInfo(self:GetAttribute("action"))
        if message ~= format("%s|%s", tostring(type), tostring(action)) then
            self:RunAttribute("UpdateState", self:GetAttribute("state"))
        end

        -- Restore on-down if we toggled it
        local toggledOnDown = self:GetAttribute("LABToggledOnDown")
        if toggledOnDown then
            self:SetAttribute("LABToggledOnDown", nil)
            self:SetAttribute("useOnKeyDown", self:GetAttribute("LABToggledOnDownBackup"))
            self:SetAttribute("LABToggledOnDownBackup", nil)
        end
    ]])

    self:DebugPrint(string.format("WrapOnClick: %s configured", button:GetName() or "unnamed"))
end

--- Initialize secure flyout handler for combat-safe flyouts
-- Phase 12 Item 6
function LAB:InitializeSecureFlyoutHandler()
    if self.flyoutHandler then
        return -- Already initialized
    end

    -- Check if we should use custom flyouts
    local useCustomFlyout = self.WoWRetail or (FlyoutButtonMixin and not ActionButton_UpdateFlyout)
    if not useCustomFlyout then
        self:DebugPrint("InitializeSecureFlyoutHandler: Custom flyouts not needed")
        return
    end

    -- Create secure flyout handler frame
    self.flyoutHandler = CreateFrame("Frame", "LABFlyoutHandlerFrame", UIParent, "SecureHandlerBaseTemplate")
    self.flyoutHandler:Hide()

    -- Create background
    self.flyoutHandler.Background = CreateFrame("Frame", nil, self.flyoutHandler)
    self.flyoutHandler.Background:SetAllPoints()

    -- Create background textures
    self.flyoutHandler.Background.End = self.flyoutHandler.Background:CreateTexture(nil, "BACKGROUND")
    self.flyoutHandler.Background.HorizontalMiddle = self.flyoutHandler.Background:CreateTexture(nil, "BACKGROUND")
    self.flyoutHandler.Background.VerticalMiddle = self.flyoutHandler.Background:CreateTexture(nil, "BACKGROUND")
    self.flyoutHandler.Background.Start = self.flyoutHandler.Background:CreateTexture(nil, "BACKGROUND")

    -- Set up background atlases if available
    if self.WoWRetail then
        self.flyoutHandler.Background.End:SetAtlas("UI-HUD-ActionBar-IconFrame-FlyoutButton", true)
        self.flyoutHandler.Background.HorizontalMiddle:SetAtlas("_UI-HUD-ActionBar-IconFrame-FlyoutMidLeft", true)
        self.flyoutHandler.Background.VerticalMiddle:SetAtlas("!UI-HUD-ActionBar-IconFrame-FlyoutMid", true)
        self.flyoutHandler.Background.Start:SetAtlas("UI-HUD-ActionBar-IconFrame-FlyoutBottom", true)
    end

    -- Set up secure flyout handling snippet
    self.flyoutHandler:SetAttribute("HandleFlyout", [[
        local flyoutID = ...
        local info = LAB_FlyoutInfo[flyoutID]

        if not info then
            print("LibTotalActionButtons: Flyout missing with ID " .. flyoutID)
            return
        end

        -- Show flyout buttons based on discovered spells
        local usedSlots = 0
        local direction = self:GetAttribute("flyoutDirection") or "UP"

        for i = 1, info.numSlots do
            local slotInfo = info.slots[i]
            if slotInfo and slotInfo.isKnown then
                usedSlots = usedSlots + 1
                local button = self:GetFrameRef("flyoutButton" .. usedSlots)
                if button then
                    button:SetAttribute("type", "spell")
                    button:SetAttribute("spell", slotInfo.spellID)
                    button:Show()

                    -- Position button based on direction
                    button:ClearAllPoints()
                    if direction == "UP" then
                        button:SetPoint("BOTTOM", self, "TOP", 0, (usedSlots - 1) * 40)
                    elseif direction == "DOWN" then
                        button:SetPoint("TOP", self, "BOTTOM", 0, -(usedSlots - 1) * 40)
                    elseif direction == "LEFT" then
                        button:SetPoint("RIGHT", self, "LEFT", -(usedSlots - 1) * 40, 0)
                    else -- RIGHT
                        button:SetPoint("LEFT", self, "RIGHT", (usedSlots - 1) * 40, 0)
                    end

                    button:CallMethod("UpdateAction")
                end
            end
        end

        -- Hide unused slots
        for i = usedSlots + 1, self:GetAttribute("numFlyoutButtons") do
            local button = self:GetFrameRef("flyoutButton" .. i)
            if button then
                button:Hide()
            end
        end

        -- Show the flyout frame
        if usedSlots > 0 then
            self:Show()
        end
    ]])

    -- Set up show/hide handlers
    self.flyoutHandler:SetScript("OnShow", function(frame)
        if frame:GetParent() and frame:GetParent().UpdateFlyout then
            frame:GetParent():UpdateFlyout()
        end
    end)

    self.flyoutHandler:SetScript("OnHide", function(frame)
        if frame:GetParent() and frame:GetParent().UpdateFlyout then
            frame:GetParent():UpdateFlyout()
        end
    end)

    -- Initialize flyout button count
    self.flyoutHandler:SetAttribute("numFlyoutButtons", 0)

    -- Phase 13 Feature #6: Register events for automatic flyout updates
    if not self.flyoutEventFrame then
        self.flyoutEventFrame = CreateFrame("Frame")
        self.flyoutEventFrame:SetScript("OnEvent", function(frame, event, ...)
            LAB:OnFlyoutEvent(event, ...)
        end)
    end

    self.flyoutEventFrame:RegisterEvent("PLAYER_LOGIN")
    self.flyoutEventFrame:RegisterEvent("SPELLS_CHANGED")
    if self.WoWRetail then
        self.flyoutEventFrame:RegisterEvent("SPELL_FLYOUT_UPDATE")
    end

    self:DebugPrint("InitializeSecureFlyoutHandler: Secure flyout handler created with auto-update events")
end

-- Phase 13 Feature #6: Handle flyout update events
function LAB:OnFlyoutEvent(event, ...)
    if InCombatLockdown() then
        -- Queue update for after combat
        self.flyoutUpdateQueued = true
        return
    end

    -- Update all discovered flyouts
    for flyoutID in pairs(self.FlyoutInfo) do
        self:DiscoverFlyoutInfo(flyoutID)
    end

    -- Sync to secure environment
    self:SyncFlyoutInfoToSecure()

    self:DebugPrint("OnFlyoutEvent: Flyouts updated for event " .. tostring(event))
end

--- Sync FlyoutInfo data to secure environment (must be called before combat)
-- Phase 12 Item 6 (continued)
function LAB:SyncFlyoutInfoToSecure()
    if not self.flyoutHandler then
        return
    end

    -- Build secure environment data string
    local data = "LAB_FlyoutInfo = newtable();\n"

    for flyoutID, info in pairs(self.FlyoutInfo) do
        if info and info.numSlots then
            data = data .. string.format("LAB_FlyoutInfo[%d] = newtable();", flyoutID)
            data = data .. string.format("LAB_FlyoutInfo[%d].numSlots = %d;", flyoutID, info.numSlots)
            data = data .. string.format("LAB_FlyoutInfo[%d].slots = newtable();", flyoutID)

            for slotID, slotInfo in pairs(info.slots) do
                if slotInfo and slotInfo.spellID then
                    data = data .. string.format("LAB_FlyoutInfo[%d].slots[%d] = newtable();", flyoutID, slotID)
                    data = data .. string.format("LAB_FlyoutInfo[%d].slots[%d].spellID = %d;", flyoutID, slotID, slotInfo.spellID)
                    data = data .. string.format("LAB_FlyoutInfo[%d].slots[%d].isKnown = %s;", flyoutID, slotID, slotInfo.isKnown and "true" or "nil")
                end
            end
        end
    end

    -- Execute in secure environment
    self.flyoutHandler:Execute(data)

    self:DebugPrint("SyncFlyoutInfoToSecure: Synced " .. tostring(self:tcount(self.FlyoutInfo)) .. " flyouts")
end

--- Count table entries (helper for debug output)
function LAB:tcount(tbl)
    local count = 0
    for _ in pairs(tbl or {}) do
        count = count + 1
    end
    return count
end

-----------------------------------
-- INITIALIZATION
-----------------------------------

-- Register overlay events for proc glows (Retail only)
LAB:RegisterOverlayEvents()

-- Phase 13 Feature #7: Set up on-bar highlight hooks for spellbook integration
LAB.ON_BAR_HIGHLIGHT_MARK_TYPE = nil
LAB.ON_BAR_HIGHLIGHT_MARK_ID = nil

if UpdateOnBarHighlightMarksBySpell then
    hooksecurefunc("UpdateOnBarHighlightMarksBySpell", function(spellID)
        LAB.ON_BAR_HIGHLIGHT_MARK_TYPE = "spell"
        LAB.ON_BAR_HIGHLIGHT_MARK_ID = tonumber(spellID)
        for button in pairs(LAB.buttons) do
            LAB:UpdateSpellHighlight(button)
        end
    end)
end

if UpdateOnBarHighlightMarksByFlyout then
    hooksecurefunc("UpdateOnBarHighlightMarksByFlyout", function(flyoutID)
        LAB.ON_BAR_HIGHLIGHT_MARK_TYPE = "flyout"
        LAB.ON_BAR_HIGHLIGHT_MARK_ID = tonumber(flyoutID)
        for button in pairs(LAB.buttons) do
            LAB:UpdateSpellHighlight(button)
        end
    end)
end

if ClearOnBarHighlightMarks then
    hooksecurefunc("ClearOnBarHighlightMarks", function()
        LAB.ON_BAR_HIGHLIGHT_MARK_TYPE = nil
        LAB.ON_BAR_HIGHLIGHT_MARK_ID = nil
        for button in pairs(LAB.buttons) do
            LAB:UpdateSpellHighlight(button)
        end
    end)
end

if ActionBarController_UpdateAllSpellHighlights then
    hooksecurefunc("ActionBarController_UpdateAllSpellHighlights", function()
        for button in pairs(LAB.buttons) do
            LAB:UpdateSpellHighlight(button)
        end
    end)
end

-- Initialize secure flyout handler (Phase 12 Item 6)
LAB:InitializeSecureFlyoutHandler()

-- Export
return LAB
