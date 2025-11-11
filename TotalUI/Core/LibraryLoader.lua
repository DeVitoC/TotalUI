--[[
    TotalUI - Library Loader
    Handles library loading and provides fallbacks when libraries are missing.
--]]

local AddonName, ns = ...
local E = ns.public

-- Library loading status
E.LibsLoaded = {
    LibStub = false,
    AceAddon = false,
    AceDB = false,
    AceConfig = false,
    AceConfigDialog = false,
    AceDBOptions = false,
    AceEvent = false,
    AceHook = false,
    AceGUI = false,
    AceConsole = false,
    LibSharedMedia = false,
    LibTotalActionButtons = false,
}

-----------------------------------
-- LIBRARY DETECTION
-----------------------------------

-- Check if LibStub is available
if LibStub then
    E.Libs.LibStub = LibStub
    E.LibsLoaded.LibStub = true

    -- Try to load Ace3 libraries
    local function TryLoadLib(libName)
        local success, lib = pcall(LibStub, libName, true)
        if success and lib then
            E.Libs[libName] = lib
            E.LibsLoaded[libName:gsub("%-.*", "")] = true
            return lib
        end
        return nil
    end

    -- Load Ace3 libraries
    TryLoadLib("AceAddon-3.0")
    TryLoadLib("AceDB-3.0")
    TryLoadLib("AceConfig-3.0")
    TryLoadLib("AceConfigDialog-3.0")
    TryLoadLib("AceDBOptions-3.0")
    TryLoadLib("AceEvent-3.0")
    TryLoadLib("AceHook-3.0")
    TryLoadLib("AceGUI-3.0")
    TryLoadLib("AceConsole-3.0")
    TryLoadLib("AceTimer-3.0")
    TryLoadLib("AceLocale-3.0")

    -- Load LibSharedMedia
    local LSM = TryLoadLib("LibSharedMedia-3.0")
    if LSM then
        E.LSM = LSM
        E.LibsLoaded.LibSharedMedia = true
    end

    -- Load LibTotalActionButtons (for Phase 1)
    -- Our custom action button library
    local LTAB = TryLoadLib("LibTotalActionButtons-1.0")
    if LTAB then
        E.Libs.LibTotalActionButtons = LTAB
        E.LibsLoaded.LibTotalActionButtons = true
    end
else
    E:Print("Warning: LibStub not found. Some features will be limited.")
end

-----------------------------------
-- ACEADDON INTEGRATION
-----------------------------------

if E.Libs["AceAddon-3.0"] then
    -- Create addon using AceAddon
    local AceAddon = E.Libs["AceAddon-3.0"]

    -- Replace simple module system with AceAddon
    function E:NewModule(name, ...)
        if AceAddon.NewModule then
            -- Use AceAddon's module system
            return AceAddon:NewModule(name, ...)
        else
            -- Fallback to simple system
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
    end

    function E:GetModule(name)
        if AceAddon.GetModule then
            local success, module = pcall(AceAddon.GetModule, AceAddon, name)
            if success then
                return module
            end
        end
        return self.modules[name]
    end

    -- Enable AceEvent if available
    if E.Libs["AceEvent-3.0"] then
        local AceEvent = E.Libs["AceEvent-3.0"]
        -- Embed AceEvent into E
        for k, v in pairs(AceEvent) do
            if type(v) == "function" then
                E[k] = v
            end
        end
    end

    -- Enable AceHook if available
    if E.Libs["AceHook-3.0"] then
        local AceHook = E.Libs["AceHook-3.0"]
        -- Embed AceHook into E
        for k, v in pairs(AceHook) do
            if type(v) == "function" then
                E[k] = v
            end
        end
    end

    -- Enable AceTimer if available
    if E.Libs["AceTimer-3.0"] then
        local AceTimer = E.Libs["AceTimer-3.0"]
        -- Embed AceTimer into E
        for k, v in pairs(AceTimer) do
            if type(v) == "function" then
                E[k] = v
            end
        end
    end
end

-----------------------------------
-- ACEDB INTEGRATION
-----------------------------------

if E.Libs["AceDB-3.0"] then
    E.DatabaseReady = false

    function E:InitializeDatabase()
        local AceDB = E.Libs["AceDB-3.0"]

        -- Create database defaults
        local defaults = {
            profile = E.ProfileDefaults,
            global = E.GlobalDefaults,
            char = E.PrivateDefaults,
        }

        -- Initialize database
        E.data = AceDB:New("TotalUIDB", defaults, true)

        if E.data then
            E.db = E.data.profile
            E.global = E.data.global
            E.private = E.data.char

            E.DatabaseReady = true

            -- Fire callback for database ready
            if E.callbacks then
                E.callbacks:Fire("DatabaseReady")
            end

            return true
        else
            E:Print("Failed to initialize database")
            return false
        end
    end
else
    -- Fallback: Use simple SavedVariables
    function E:InitializeDatabase()
        if not TotalUIDB then
            TotalUIDB = {
                profileKeys = {},
                profiles = {
                    ["Default"] = E:CopyTable(E.ProfileDefaults, {})
                },
                global = E:CopyTable(E.GlobalDefaults, {}),
                char = {}
            }
        end

        -- Set up character key
        local charKey = E.myrealm .. "-" .. E.myname
        if not TotalUIDB.char[charKey] then
            TotalUIDB.char[charKey] = E:CopyTable(E.PrivateDefaults, {})
        end

        -- Set profile key if not set
        if not TotalUIDB.profileKeys[charKey] then
            TotalUIDB.profileKeys[charKey] = "Default"
        end

        -- Get current profile
        local profileKey = TotalUIDB.profileKeys[charKey]
        if not TotalUIDB.profiles[profileKey] then
            TotalUIDB.profiles[profileKey] = E:CopyTable(E.ProfileDefaults, {})
        end

        -- Set up quick access
        E.db = TotalUIDB.profiles[profileKey]
        E.global = TotalUIDB.global
        E.private = TotalUIDB.char[charKey]

        E.DatabaseReady = true

        if E.callbacks then
            E.callbacks:Fire("DatabaseReady")
        end

        return true
    end
end

-----------------------------------
-- LIBSHAREDMEDIA INTEGRATION
-----------------------------------

if E.LSM then
    -- Register default media
    function E:RegisterMedia()
        local LSM = E.LSM

        -- Register fonts (add your custom fonts to Media/Fonts/)
        -- LSM:Register("font", "totalUI Default", [[Interface\AddOns\totalUI\Media\Fonts\Default.ttf]])

        -- Register textures (add your custom textures to Media/Textures/)
        -- LSM:Register("statusbar", "totalUI Clean", [[Interface\AddOns\totalUI\Media\Textures\Clean.tga]])
        -- LSM:Register("border", "totalUI Border", [[Interface\AddOns\totalUI\Media\Textures\Border.tga]])

        -- Register sounds (add your custom sounds to Media/Sounds/)
        -- LSM:Register("sound", "totalUI Alert", [[Interface\AddOns\totalUI\Media\Sounds\Alert.ogg]])

        -- For now, register WoW default media
        LSM:Register("font", "Friz Quadrata TT", [[Fonts\FRIZQT__.TTF]])
        LSM:Register("statusbar", "Blizzard", [[Interface\TargetingFrame\UI-StatusBar]])
    end
else
    -- Fallback: Provide basic media table
    E.LSM = {
        mediaType = {
            font = {},
            statusbar = {},
            sound = {},
            border = {},
        }
    }

    function E:RegisterMedia()
        -- Register default WoW media paths
        E.LSM.mediaType.font["Friz Quadrata TT"] = [[Fonts\FRIZQT__.TTF]]
        E.LSM.mediaType.statusbar["Blizzard"] = [[Interface\TargetingFrame\UI-StatusBar]]
    end

    -- Fetch function fallback
    function E.LSM:Fetch(mediaType, name)
        if self.mediaType[mediaType] and self.mediaType[mediaType][name] then
            return self.mediaType[mediaType][name]
        end
        -- Return default based on type
        if mediaType == "font" then
            return [[Fonts\FRIZQT__.TTF]]
        elseif mediaType == "statusbar" then
            return [[Interface\TargetingFrame\UI-StatusBar]]
        end
        return nil
    end
end

-----------------------------------
-- CONSOLE COMMANDS
-----------------------------------

-- Command handler (must be defined before registration)
function E:HandleCommand(msg)
    msg = msg or ""
    -- Trim whitespace
    msg = msg:match("^%s*(.-)%s*$")
    local cmd = msg:lower()

    if cmd == "" or cmd == "help" then
        self:Print("TotalUI Commands:")
        self:Print("/totalui config - Open configuration")
        self:Print("/totalui version - Show version info")
        self:Print("/totalui status - Show addon status")
        self:Print("/totalui toggle [module] - Toggle module on/off")
    elseif cmd == "config" then
        -- Open config (Phase 13)
        self:Print("Configuration UI not yet implemented (Phase 13)")
    elseif cmd == "version" then
        self:Print("TotalUI version " .. (self.Version or "Unknown"))
        if self.Compat then
            self.Compat:PrintVersionInfo()
        end
    elseif cmd == "status" then
        self:PrintStatus()
    else
        self:Print("Unknown command. Type /totalui help for commands.")
    end
end

function E:PrintStatus()
    self:Print("Addon Status:")
    self:Print("  Initialized:", self.initialized)
    self:Print("  Database Ready:", self.DatabaseReady)
    self:Print("  Libraries Loaded:")
    for lib, loaded in pairs(self.LibsLoaded) do
        self:Print("    " .. lib .. ":", loaded)
    end
end

-----------------------------------
-- INITIALIZATION HELPER
-----------------------------------

function E:InitializeLibraries()
    -- Register media
    self:RegisterMedia()

    -- Initialize database
    self:InitializeDatabase()

    -- Register slash commands
    self:RegisterSlashCommands()

    return true
end

-- Register slash commands
function E:RegisterSlashCommands()
    if self.Libs["AceConsole-3.0"] then
        local AceConsole = self.Libs["AceConsole-3.0"]

        -- Register slash commands using AceConsole
        AceConsole:RegisterChatCommand("totalui", function(msg)
            local success, err = pcall(E.HandleCommand, E, msg)
            if not success then
                print("|cff1784d1TotalUI|r: Command error:", err)
            end
        end)
        AceConsole:RegisterChatCommand("tui", function(msg)
            local success, err = pcall(E.HandleCommand, E, msg)
            if not success then
                print("|cff1784d1TotalUI|r: Command error:", err)
            end
        end)
    else
        -- Fallback: Manual slash command registration
        _G.SLASH_TOTALUI1 = "/totalui"
        _G.SLASH_TOTALUI2 = "/tui"
        _G.SlashCmdList["TOTALUI"] = function(msg)
            local success, err = pcall(E.HandleCommand, E, msg)
            if not success then
                print("|cff1784d1TotalUI|r: Command error:", err)
            end
        end
    end
end
