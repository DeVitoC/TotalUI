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
local GetSpellCharges = GetSpellCharges or function() return nil end
local GetSpellLossOfControlCooldown = GetSpellLossOfControlCooldown or function() return nil end
local GetSpellCount = GetSpellCount or function() return 0 end
local GetItemCharges = GetItemCharges or function() return nil end

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

-- Store compatibility wrappers
LAB.Compat = {
    GetActionCharges = GetActionCharges,
    GetActionLossOfControlCooldown = GetActionLossOfControlCooldown,
    GetSpellCharges = GetSpellCharges,
    GetSpellLossOfControlCooldown = GetSpellLossOfControlCooldown,
    GetSpellCount = GetSpellCount,
    GetItemCharges = GetItemCharges,
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

function LAB:CreateButton(actionID, name, parent, config)
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
    -- NOTE: Template should be passed as a string, not comma-separated
    local button = CreateFrame("CheckButton", name, parent, "ActionBarButtonTemplate")

    if not button then
        self:Error("CreateButton: Failed to create button frame!", 2)
        return nil
    end

    -- Store button data
    button.id = actionID
    button.config = config or {}
    button.actionID = actionID

    -- Initialize button
    self:InitializeButton(button)
    self:SetupButtonAction(button, actionID)
    self:StyleButton(button, config)
    self:RegisterButton(button)

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
end

function LAB:RegisterButton(button)
    -- Add to registry
    table.insert(self.buttons, button)
    self.activeButtons[button] = true

    -- Register for events
    for _, event in ipairs(self.UPDATE_EVENTS) do
        button:RegisterEvent(event)
    end

    -- Initial update
    self:UpdateButton(button)
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
    self:UpdateState(button)
    self:UpdateGrid(button)
end

function LAB:UpdateAction(button)
    local action = button.action
    if not action then return end

    local hasAction = HasAction(action)
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
    local action = button.action
    if not action or not button._icon then return end

    local texture = GetActionTexture(action)
    if texture then
        button._icon:SetTexture(texture)
        button._icon:Show()
    else
        button._icon:SetTexture(nil)
        button._icon:Hide()
    end
end

function LAB:UpdateCount(button)
    local action = button.action
    if not action or not button._count then return end

    local count = GetActionCount(action)
    if count and count > 1 then
        button._count:SetText(count)
        button._count:Show()
    else
        button._count:SetText("")
        button._count:Hide()
    end
end

function LAB:UpdateCooldown(button)
    local action = button.action
    if not action or not button._cooldown then return end

    local start, duration, enable = GetActionCooldown(action)
    if start and duration and enable == 1 then
        button._cooldown:SetCooldown(start, duration)
    else
        button._cooldown:Clear()
    end

    -- Handle charges using compatibility wrapper (Phase 1 Step 1.3)
    if self.Compat and self.Compat.GetActionCharges then
        local charges, maxCharges, chargeStart, chargeDuration = self.Compat.GetActionCharges(action)
        if charges and maxCharges and maxCharges > 1 then
            -- Show charge count
            if charges < maxCharges and button._count then
                button._count:SetText(charges)
                button._count:Show()
            end
        end
    end
end

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

function LAB:UpdateUsable(button)
    local action = button.action
    if not action or not button._icon then return end

    local isUsable, notEnoughMana = IsUsableAction(action)
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
    local action = button.action
    if not action or not button._icon then return end

    local inRange = IsActionInRange(action)
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

function LAB:UpdateState(button)
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
        self:UpdateState(button)
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

-- Export
return LAB
