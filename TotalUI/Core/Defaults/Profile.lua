--[[
    TotalUI - Profile Defaults
    Per-profile default settings (P namespace).
    These settings can be shared across characters using the same profile.
--]]

local AddonName, ns = ...
local E = ns.public

-- Profile defaults
E.ProfileDefaults = {
    -- General UI settings
    general = {
        -- Colors
        bordercolor = {r = 0, g = 0, b = 0},
        backdropcolor = {r = 0.1, g = 0.1, b = 0.1},
        backdropfadecolor = {r = 0.06, g = 0.06, b = 0.06, a = 0.8},

        -- Fonts
        font = "Friz Quadrata TT", -- Default WoW font (will use LSM later)
        fontSize = 12,
        fontOutline = "OUTLINE",

        -- Textures
        statusbar = "ElvUI Blank", -- Will use LSM later
        glossTex = "ElvUI Gloss", -- Will use LSM later

        -- Borders
        thinBorders = false,
        pixelPerfect = true,

        -- Colors
        valuecolor = {r = 0.09, g = 0.52, b = 0.82},

        -- Class colors
        classColors = {}, -- Will be populated from Constants

        -- Debuff colors (custom overrides)
        debuffColors = {}, -- Will be populated from Constants
    },

    -- Phase 1: ActionBars
    actionbar = {
        enable = true,

        -- Global settings
        lockActionBars = false,
        globalFadeAlpha = 1,
        transparentBackdrops = false,
        desaturateOnCooldown = false,
        flashAnimation = true,

        -- Individual bars (Bar 1-15)
        bar1 = {
            enabled = true,
            buttons = 12,
            buttonsPerRow = 12,
            buttonSize = 32,
            buttonSpacing = 2,
            alpha = 1,
            mouseover = false,
            backdrop = true,
            visibility = "[petbattle] hide; show",
            point = "BOTTOM",
            growthDirection = "HORIZONTAL",
        },
        -- Additional bars would follow the same pattern
        -- bar2 = { ... }
        -- ... up to bar15

        -- Special bars
        pet = {
            enabled = true,
            buttons = 10,
            buttonSize = 30,
        },
        stance = {
            enabled = true,
            buttonSize = 30,
        },
        micro = {
            enabled = true,
            buttonSize = 20,
        },
    },

    -- Phase 2: UnitFrames
    unitframe = {
        enable = true,

        -- General settings
        smoothbars = true,
        statusbar = "ElvUI Blank",
        font = "Friz Quadrata TT",
        colors = {
            healthclass = true,
            powerclass = false,
        },

        -- Individual unit frames
        player = {
            enable = true,
            width = 250,
            height = 50,
        },
        target = {
            enable = true,
            width = 250,
            height = 50,
        },
        -- Additional frames: targettarget, pet, focus, party, raid, boss, arena
    },

    -- Phase 3: Nameplates
    nameplate = {
        enable = true,

        -- General settings
        font = "Friz Quadrata TT",
        fontSize = 11,
        statusbar = "ElvUI Blank",

        -- Filters and styling
        filters = {},
        reactions = {
            friendly = {r = 0, g = 1, b = 0},
            neutral = {r = 1, g = 1, b = 0},
            hostile = {r = 1, g = 0, b = 0},
        },
    },

    -- Phase 4: Bags
    bags = {
        enable = true,

        -- General settings
        bagSize = 42,
        bankSize = 42,
        sortInverted = false,
        itemLevel = true,
        qualityColors = true,
        junkIcon = true,
        scrapIcon = true,
    },

    -- Phase 5: Chat
    chat = {
        enable = true,

        -- General settings
        font = "Friz Quadrata TT",
        fontSize = 12,
        tabFont = "Friz Quadrata TT",
        tabFontSize = 12,

        -- Features
        url = true, -- URL detection
        shortChannels = true,
        emoticons = false,
        keywords = {},
    },

    -- Phase 6: DataTexts
    datatexts = {
        enable = true,

        -- General settings
        font = "Friz Quadrata TT",
        fontSize = 12,

        -- Panel assignments
        panels = {
            LeftChatDataPanel = {"System", "Gold"},
            RightChatDataPanel = {"Friends", "Guild"},
        },
    },

    -- Phase 7: DataBars
    databars = {
        -- Experience bar
        experience = {
            enable = true,
            width = 10,
            height = 200,
            orientation = "VERTICAL",
        },

        -- Reputation bar
        reputation = {
            enable = true,
            width = 10,
            height = 200,
            orientation = "VERTICAL",
        },

        -- Honor bar (PvP)
        honor = {
            enable = true,
        },
    },

    -- Phase 8: Auras (Buffs/Debuffs)
    auras = {
        enable = true,

        -- Buffs
        buffs = {
            size = 30,
            spacing = 3,
            growthDirection = "RIGHT_DOWN",
            wrapAfter = 16,
        },

        -- Debuffs
        debuffs = {
            size = 30,
            spacing = 3,
            growthDirection = "RIGHT_DOWN",
            wrapAfter = 16,
        },
    },

    -- Phase 9: Tooltips
    tooltip = {
        enable = true,

        -- General
        fontSize = 12,
        healthBar = true,
        playerTitles = true,
        guildRanks = true,
        itemCount = true,
        spellID = false,

        -- Colors
        borderColor = {r = 0, g = 0, b = 0},
    },

    -- Phase 10: Maps
    maps = {
        -- Minimap
        minimap = {
            enable = true,
            size = 200,
        },

        -- World map
        worldMap = {
            enable = true,
            coordinates = true,
        },
    },

    -- Phase 11: Skins
    skins = {
        enable = true,

        -- What to skin
        blizzard = true,
        ace3 = true,
    },

    -- Phase 12: Miscellaneous
    misc = {
        enable = true,

        -- AFK screen
        afk = true,

        -- Various enhancements
        lootRoll = true,
        raidUtility = true,
    },
}

-- Apply defaults on load
-- TODO: This will be integrated with AceDB later
E.db = E:CopyTable(E.ProfileDefaults, E.db)
