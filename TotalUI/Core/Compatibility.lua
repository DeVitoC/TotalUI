--[[
    TotalUI - Compatibility Layer
    API wrappers to handle changes between WoW versions and future-proof the addon.

    This file provides a consistent internal API regardless of which WoW version is running.
    When Blizzard changes APIs, only this file needs to be updated.
--]]

local AddonName, ns = ...
local E = ns.public

-- Create compatibility namespace
E.Compat = {}
local Compat = E.Compat

-- Version detection
Compat.IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
Compat.IsClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
Compat.IsTBC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
Compat.IsWrath = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC
Compat.IsCata = WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC

-- Expansion detection for Retail
Compat.ExpansionLevel = GetExpansionLevel and GetExpansionLevel() or 0
Compat.BuildInfo = select(4, GetBuildInfo())

-- Feature flags (APIs that may not exist in all versions)
Compat.HasContainerAPI = C_Container ~= nil
Compat.HasItemAPI = C_Item ~= nil
Compat.HasSpellAPI = C_Spell ~= nil
Compat.HasTooltipInfo = C_TooltipInfo ~= nil
Compat.HasCurrencyInfo = C_CurrencyInfo ~= nil
Compat.HasBackdropTemplate = BackdropTemplateMixin ~= nil

-----------------------------------
-- CONTAINER/BAG API WRAPPERS
-----------------------------------

-- Get number of bag slots
function Compat:GetContainerNumSlots(bagID)
    if self.HasContainerAPI then
        return C_Container.GetContainerNumSlots(bagID)
    else
        return GetContainerNumSlots(bagID)
    end
end

-- Get item info from container slot
function Compat:GetContainerItemInfo(bagID, slotID)
    if self.HasContainerAPI then
        local itemInfo = C_Container.GetContainerItemInfo(bagID, slotID)
        if itemInfo then
            return itemInfo.iconFileID, itemInfo.stackCount, itemInfo.isLocked,
                   itemInfo.quality, itemInfo.isReadable, itemInfo.hasLoot,
                   itemInfo.hyperlink, itemInfo.isFiltered, itemInfo.hasNoValue,
                   itemInfo.itemID, itemInfo.isBound
        end
        return nil
    else
        return GetContainerItemInfo(bagID, slotID)
    end
end

-- Get item link from container slot
function Compat:GetContainerItemLink(bagID, slotID)
    if self.HasContainerAPI then
        return C_Container.GetContainerItemLink(bagID, slotID)
    else
        return GetContainerItemLink(bagID, slotID)
    end
end

-- Get item ID from container slot
function Compat:GetContainerItemID(bagID, slotID)
    if self.HasContainerAPI then
        return C_Container.GetContainerItemID(bagID, slotID)
    else
        -- Fallback: parse from item link
        local itemLink = self:GetContainerItemLink(bagID, slotID)
        if itemLink then
            return tonumber(itemLink:match("item:(%d+)"))
        end
        return nil
    end
end

-- Use container item
function Compat:UseContainerItem(bagID, slotID, onSelf)
    if self.HasContainerAPI then
        return C_Container.UseContainerItem(bagID, slotID, onSelf)
    else
        return UseContainerItem(bagID, slotID, onSelf)
    end
end

-- Pick up container item
function Compat:PickupContainerItem(bagID, slotID)
    if self.HasContainerAPI then
        return C_Container.PickupContainerItem(bagID, slotID)
    else
        return PickupContainerItem(bagID, slotID)
    end
end

-- Get container num free slots
function Compat:GetContainerNumFreeSlots(bagID)
    if self.HasContainerAPI then
        return C_Container.GetContainerNumFreeSlots(bagID)
    else
        return GetContainerNumFreeSlots(bagID)
    end
end

-----------------------------------
-- ITEM API WRAPPERS
-----------------------------------

-- Get item info
function Compat:GetItemInfo(itemID)
    if self.HasItemAPI then
        return C_Item.GetItemInfo(itemID)
    else
        return GetItemInfo(itemID)
    end
end

-- Get item quality
function Compat:GetItemQuality(itemID)
    if self.HasItemAPI then
        local itemQuality = C_Item.GetItemQuality(itemID)
        return itemQuality
    else
        local _, _, quality = GetItemInfo(itemID)
        return quality
    end
end

-- Get item quality color
function Compat:GetItemQualityColor(quality)
    if self.HasItemAPI then
        return C_Item.GetItemQualityColor(quality)
    else
        return GetItemQualityColor(quality)
    end
end

-- Get item name
function Compat:GetItemName(itemID)
    if self.HasItemAPI then
        return C_Item.GetItemNameByID(itemID)
    else
        local name = GetItemInfo(itemID)
        return name
    end
end

-- Get item count
function Compat:GetItemCount(itemID, includeBank, includeCharges)
    return GetItemCount(itemID, includeBank, includeCharges)
end

-- Does item exist (is cached)
function Compat:DoesItemExist(itemID)
    if self.HasItemAPI then
        return C_Item.DoesItemExist(itemID)
    else
        local name = GetItemInfo(itemID)
        return name ~= nil
    end
end

-----------------------------------
-- SPELL API WRAPPERS
-----------------------------------

-- Get spell info
function Compat:GetSpellInfo(spellID)
    if self.HasSpellAPI and C_Spell.GetSpellInfo then
        local spellInfo = C_Spell.GetSpellInfo(spellID)
        if spellInfo then
            return spellInfo.name, nil, spellInfo.iconID, spellInfo.castTime,
                   spellInfo.minRange, spellInfo.maxRange, spellInfo.spellID
        end
        return nil
    else
        return GetSpellInfo(spellID)
    end
end

-- Get spell name
function Compat:GetSpellName(spellID)
    local name = self:GetSpellInfo(spellID)
    return name
end

-- Get spell texture/icon
function Compat:GetSpellTexture(spellID)
    if self.HasSpellAPI and C_Spell.GetSpellTexture then
        return C_Spell.GetSpellTexture(spellID)
    else
        local _, _, icon = GetSpellInfo(spellID)
        return icon
    end
end

-- Is spell known
function Compat:IsSpellKnown(spellID)
    if self.HasSpellAPI and C_Spell.IsSpellKnown then
        return C_Spell.IsSpellKnown(spellID)
    else
        return IsSpellKnown(spellID)
    end
end

-----------------------------------
-- CURRENCY API WRAPPERS
-----------------------------------

-- Get currency info
function Compat:GetCurrencyInfo(currencyID)
    if self.HasCurrencyInfo and C_CurrencyInfo.GetCurrencyInfo then
        local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
        if info then
            return info.name, info.quantity, info.iconFileID, info.maxQuantity
        end
        return nil
    else
        return GetCurrencyInfo(currencyID)
    end
end

-- Get currency link
function Compat:GetCurrencyLink(currencyID)
    if self.HasCurrencyInfo and C_CurrencyInfo.GetCurrencyLink then
        return C_CurrencyInfo.GetCurrencyLink(currencyID)
    else
        return GetCurrencyLink(currencyID)
    end
end

-----------------------------------
-- TOOLTIP API WRAPPERS
-----------------------------------

-- Set tooltip to item
function Compat:SetTooltipItem(tooltip, itemID)
    if self.HasTooltipInfo then
        -- New API (11.0+)
        if C_TooltipInfo.GetItemByID then
            tooltip:SetItemByID(itemID)
        end
    else
        -- Old API
        tooltip:SetHyperlink("item:" .. itemID)
    end
end

-- Set tooltip to spell
function Compat:SetTooltipSpell(tooltip, spellID)
    if self.HasTooltipInfo then
        -- New API (11.0+)
        if C_TooltipInfo.GetSpellByID then
            tooltip:SetSpellByID(spellID)
        end
    else
        -- Old API
        tooltip:SetSpellByID(spellID)
    end
end

-- Set tooltip to unit
function Compat:SetTooltipUnit(tooltip, unit)
    tooltip:SetUnit(unit)
end

-----------------------------------
-- UNIT API WRAPPERS
-----------------------------------

-- Get unit power type
function Compat:GetUnitPowerType(unit)
    local powerType, powerToken = UnitPowerType(unit)
    return powerType, powerToken
end

-- Get unit power
function Compat:GetUnitPower(unit, powerType)
    return UnitPower(unit, powerType)
end

-- Get unit max power
function Compat:GetUnitPowerMax(unit, powerType)
    return UnitPowerMax(unit, powerType)
end

-- Get unit class
function Compat:GetUnitClass(unit)
    local className, classFile, classID = UnitClass(unit)
    return className, classFile, classID
end

-- Get unit name
function Compat:GetUnitName(unit)
    local name, realm = UnitName(unit)
    return name, realm
end

-----------------------------------
-- FRAME/UI API WRAPPERS
-----------------------------------

-- Create frame with backdrop template
function Compat:CreateFrame(frameType, name, parent, template)
    if self.HasBackdropTemplate then
        -- If a template is provided that doesn't include BackdropTemplate, append it
        if template and type(template) == "string" and not template:find("BackdropTemplate") then
            template = template .. ", BackdropTemplate"
        elseif not template then
            template = "BackdropTemplate"
        end
    end

    return CreateFrame(frameType, name, parent, template)
end

-- Set backdrop (handles both old and new APIs)
function Compat:SetBackdrop(frame, backdrop)
    if frame.SetBackdrop then
        frame:SetBackdrop(backdrop)
    end
end

-- Set backdrop color
function Compat:SetBackdropColor(frame, r, g, b, a)
    if frame.SetBackdropColor then
        frame:SetBackdropColor(r, g, b, a)
    end
end

-- Set backdrop border color
function Compat:SetBackdropBorderColor(frame, r, g, b, a)
    if frame.SetBackdropBorderColor then
        frame:SetBackdropBorderColor(r, g, b, a)
    end
end

-----------------------------------
-- AURA API WRAPPERS
-----------------------------------

-- Get unit buff (handles both old UnitBuff and new C_UnitAuras)
function Compat:GetUnitBuff(unit, index, filter)
    -- Try new API first (10.0+)
    if C_UnitAuras and C_UnitAuras.GetBuffDataByIndex then
        local auraData = C_UnitAuras.GetBuffDataByIndex(unit, index, filter)
        if auraData then
            return auraData.name, auraData.icon, auraData.applications,
                   auraData.dispelName, auraData.duration, auraData.expirationTime,
                   auraData.sourceUnit, auraData.isStealable, auraData.nameplateShowPersonal,
                   auraData.spellId
        end
        return nil
    else
        -- Old API
        return UnitBuff(unit, index, filter)
    end
end

-- Get unit debuff
function Compat:GetUnitDebuff(unit, index, filter)
    -- Try new API first (10.0+)
    if C_UnitAuras and C_UnitAuras.GetDebuffDataByIndex then
        local auraData = C_UnitAuras.GetDebuffDataByIndex(unit, index, filter)
        if auraData then
            return auraData.name, auraData.icon, auraData.applications,
                   auraData.dispelName, auraData.duration, auraData.expirationTime,
                   auraData.sourceUnit, auraData.isStealable, auraData.nameplateShowPersonal,
                   auraData.spellId
        end
        return nil
    else
        -- Old API
        return UnitDebuff(unit, index, filter)
    end
end

-----------------------------------
-- PROFILE/DATABASE WRAPPERS
-----------------------------------

-- These will be populated after AceDB is integrated
-- They provide a consistent way to access profile data

function Compat:GetProfile()
    -- Returns the active profile (P namespace)
    if E.db then
        return E.db
    end
    return E.ProfileDefaults
end

function Compat:GetGlobalDB()
    -- Returns global/account-wide settings (G namespace)
    if E.global then
        return E.global
    end
    return E.GlobalDefaults
end

function Compat:GetPrivateDB()
    -- Returns character-specific settings (V namespace)
    if E.private then
        return E.private
    end
    return E.PrivateDefaults
end

function Compat:GetDatabase()
    -- Returns the full database object
    if E.data then
        return E.data
    end
    return nil
end

-----------------------------------
-- UTILITY WRAPPERS
-----------------------------------

-- Safe way to get screen resolution
function Compat:GetScreenResolution()
    local resolution = GetCurrentResolution()
    if resolution and resolution > 0 then
        local resolutions = {GetScreenResolutions()}
        return resolutions[resolution]
    end
    return GetCVar("gxWindowedResolution") or "1920x1080"
end

-- Get UI scale
function Compat:GetUIScale()
    return UIParent:GetEffectiveScale()
end

-- Get screen dimensions
function Compat:GetScreenDimensions()
    local width, height = GetPhysicalScreenSize()
    return width, height
end

-----------------------------------
-- VERSION INFORMATION
-----------------------------------

function Compat:GetVersionInfo()
    return {
        isRetail = self.IsRetail,
        isClassic = self.IsClassic,
        isTBC = self.IsTBC,
        isWrath = self.IsWrath,
        isCata = self.IsCata,
        expansion = self.ExpansionLevel,
        build = self.BuildInfo,
        hasContainerAPI = self.HasContainerAPI,
        hasItemAPI = self.HasItemAPI,
        hasSpellAPI = self.HasSpellAPI,
        hasTooltipInfo = self.HasTooltipInfo,
        hasCurrencyInfo = self.HasCurrencyInfo,
        hasBackdropTemplate = self.HasBackdropTemplate,
    }
end

function Compat:PrintVersionInfo()
    local info = self:GetVersionInfo()
    E:Print("Compatibility Layer Information:")
    E:Print("  Retail:", info.isRetail)
    E:Print("  Classic:", info.isClassic)
    E:Print("  Expansion:", info.expansion)
    E:Print("  Build:", info.build)
    E:Print("  Container API:", info.hasContainerAPI)
    E:Print("  Item API:", info.hasItemAPI)
    E:Print("  Spell API:", info.hasSpellAPI)
    E:Print("  Tooltip Info:", info.hasTooltipInfo)
    E:Print("  Backdrop Template:", info.hasBackdropTemplate)
end

-- Store this for easy access throughout the addon
E.IsRetail = Compat.IsRetail
E.IsClassic = Compat.IsClassic
