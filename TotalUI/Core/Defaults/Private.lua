--[[
    TotalUI - Private Defaults
    Character-specific default settings (V namespace).
    These settings are locked to individual characters.
--]]

local AddonName, ns = ...
local E = ns.public

-- Private/Character defaults
E.PrivateDefaults = {
    -- General
    general = {
        -- Installation tracking
        installed = false,
        installVersion = E.Version or "0.1.0",
    },

    -- Module enable/disable (character specific)
    -- Phase 1: ActionBars
    actionbars = {
        enable = true,
    },

    -- Phase 2: UnitFrames
    unitframes = {
        enable = true,
    },

    -- Phase 3: Nameplates
    nameplates = {
        enable = true,
    },

    -- Phase 4: Bags
    bags = {
        enable = true,
    },

    -- Phase 5: Chat
    chat = {
        enable = true,
    },

    -- Phase 6: DataTexts
    datatexts = {
        enable = true,
    },

    -- Phase 7: DataBars
    databars = {
        enable = true,
    },

    -- Phase 8: Auras
    auras = {
        enable = true,
    },

    -- Phase 9: Tooltips
    tooltip = {
        enable = true,
    },

    -- Phase 10: Maps
    maps = {
        enable = true,
    },

    -- Phase 11: Skins
    skins = {
        enable = true,
        -- Specific skin toggles
        blizzard = true,
        ace3 = true,
    },

    -- Phase 12: Miscellaneous
    misc = {
        enable = true,
    },

    -- Font overrides (character specific)
    fonts = {
        -- Will store any character-specific font overrides
    },

    -- Theme/style (character specific)
    theme = {
        -- Character can have their own theme that overrides profile
    },
}

-- Apply defaults on load
-- TODO: This will be integrated with AceDB later
E.private = CopyTable(E.PrivateDefaults, E.private)
