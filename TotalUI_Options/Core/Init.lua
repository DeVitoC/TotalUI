--[[
    TotalUI_Options - Options Initialization
    Configuration UI for TotalUI (Phase 13).
--]]

local AddonName, ns = ...

-- Get reference to main addon
local E = _G.TotalUI

if not E then
    error("TotalUI_Options requires TotalUI to be loaded first!")
    return
end

-- Store options namespace
ns.E = E
E.Options = ns

-- Options initialization
local Options = {}
E.OptionsModule = Options

function Options:Initialize()
    print("|cff1784d1TotalUI|r Options initializing...")

    -- Initialize Config GUI
    if ns.ConfigGUI then
        -- ConfigGUI is ready to use (no initialization needed)
        print("|cff1784d1TotalUI|r Config GUI loaded. Type /totalui config to open settings.")
    end

    -- Initialize module options (Blizzard Settings integration - optional)
    if ns.ActionBarsOptions then
        ns.ActionBarsOptions:Initialize()
    end

    print("|cff1784d1TotalUI|r Options loaded. Type /totalui config to configure.")
end

-- Load options when addon is ready
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addon)
    if addon == "TotalUI_Options" then
        Options:Initialize()
        self:UnregisterAllEvents()
    end
end)
