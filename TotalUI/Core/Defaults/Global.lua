--[[
    TotalUI - Global Defaults
    Account-wide default settings (G namespace).
    These settings are shared across all characters.
--]]

local AddonName, ns = ...
local E = ns.public

-- Global/Account-wide defaults
E.GlobalDefaults = {
    -- General account settings
    general = {
        -- Version tracking
        version = E.Version or "0.1.0",
        lastUpdateNotification = 0,

        -- Tutorial/help
        tutorialComplete = false,
        showHelpTips = true,

        -- UI Scale
        autoScale = true,
        uiScale = 0.64,
    },

    -- Phase 6: DataTexts - Custom panels (shared across characters)
    datatexts = {
        customPanels = {
            -- Custom datatext panels will be stored here
        },
    },

    -- Profiles management
    profiles = {
        -- Profile metadata
        -- Character -> Profile assignments are handled by SavedVariables
    },

    -- Phase 13: Import/Export
    importExport = {
        -- Stores exported profile strings
        savedExports = {},
    },

    -- Nameplate filters (Phase 3 - account wide)
    nameplate = {
        filters = {
            -- Custom style filters
        },
    },

    -- Aura filters (Phase 8 - account wide)
    auras = {
        filters = {
            -- Custom aura filters
        },
    },

    -- Chat settings that should persist (Phase 5)
    chat = {
        -- Chat history and settings that persist
        history = {},
    },

    -- Custom media paths
    media = {
        customTextures = {},
        customFonts = {},
        customSounds = {},
    },

    -- Addon communication
    communication = {
        -- Settings for addon communication between guild/party members
        shareSettings = false,
        receiveSettings = false,
    },

    -- Debug mode
    debug = {
        enabled = false,
        verbose = false,
    },
}

-- Apply defaults on load
-- TODO: This will be integrated with AceDB later
E.global = CopyTable(E.GlobalDefaults, E.global)
