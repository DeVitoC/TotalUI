--[[
    TotalUI - Core Initialization
    This file initializes the addon namespace and sets up the basic structure.
--]]

local AddonName, ns = ...

-- Create addon namespace
ns.private = {}  -- Private functions/data
ns.public = {}   -- Public API

-- Create global accessor
local E = ns.public
_G.TotalUI = E

-- Store addon name
E.AddonName = AddonName

-- Safely get version
local success, version = pcall(GetAddOnMetadata, AddonName, "Version")
if success then
    E.Version = version or "0.1.0"
else
    E.Version = "0.1.0"
end

-- Will be populated by other files
E.Libs = {}      -- Libraries
E.Config = {}    -- Configuration
E.Modules = {}   -- Modules registry
E.db = {}        -- Profile database (P)
E.global = {}    -- Global database (G)
E.private = {}   -- Private/character database (V)

-- Player information
E.myclass = select(2, UnitClass("player"))
E.myname = UnitName("player")
E.myrealm = GetRealmName()
E.myfaction = UnitFactionGroup("player")
E.mylevel = UnitLevel("player")

-- Client information
E.wowpatch, E.wowbuild, E.wowdate, E.wowtoc = GetBuildInfo()

-- Hidden frame for hiding Blizzard UI elements
E.HiddenFrame = CreateFrame("Frame")
E.HiddenFrame:Hide()

-- Initialization flag
E.initialized = false

-- Simple module system (will use Ace3 later when libraries are integrated)
E.modules = {}

function E:NewModule(name)
    if self.modules[name] then
        return self.modules[name]
    end

    local module = {
        name = name,
        initialized = false
    }

    self.modules[name] = module
    return module
end

function E:GetModule(name)
    return self.modules[name]
end

-- Event handler
local eventFrame = CreateFrame("Frame")
E.eventFrame = eventFrame

-- Initialize on ADDON_LOADED
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addon = ...
        if addon == AddonName then
            E:Initialize()
        end
    elseif event == "PLAYER_LOGIN" then
        E:OnLogin()
    end
end)

-- Initialization function
function E:Initialize()
    -- Initialize quality colors
    if self.InitializeQualityColors then
        self:InitializeQualityColors()
    end

    -- Initialize libraries and database
    if self.InitializeLibraries then
        self:InitializeLibraries()
    end

    print("|cff1784d1TotalUI|r version " .. (self.Version or "Unknown") .. " loaded!")

    self.initialized = true
end

-- Player login handler
function E:OnLogin()
    -- Initialize if not already done
    if not self.initialized then
        self:Initialize()
    end

    -- Initialize modules FIRST
    for name, module in pairs(self.modules) do
        if module.Initialize then
            local success, err = pcall(module.Initialize, module)
            if not success then
                print("|cff1784d1TotalUI|r: Error initializing module " .. name .. ": " .. tostring(err))
            end
        end
    end

    -- Load options addon AFTER modules are initialized
    local loadFunc = C_AddOns and C_AddOns.LoadAddOn or LoadAddOn
    local loaded, reason = loadFunc("TotalUI_Options")
    if loaded then
        self:Print("Options loaded")
    elseif reason then
        -- Only print if there's an actual error (not just "not installed")
        if reason ~= "DISABLED" and reason ~= "MISSING" then
            self:Print("Options failed to load:", reason)
        end
    end
end

-- Debug print function
function E:Print(...)
    print("|cff1784d1TotalUI|r:", ...)
end

-- Check if addon already loaded (in case ADDON_LOADED fired before we registered)
-- Use C_AddOns API for Retail, fallback to global for Classic
local IsAddOnLoadedFunc = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
if IsAddOnLoadedFunc and IsAddOnLoadedFunc(AddonName) then
    E:Initialize()
end
