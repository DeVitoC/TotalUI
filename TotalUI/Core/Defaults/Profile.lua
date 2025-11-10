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
        desaturateOnCooldown = true,
        flashAnimation = true,
        equippedItem = true,
        equippedItemColor = {r = 0.1, g = 0.6, b = 0.1},

        -- Colors
        noRangeColor = {r = 0.8, g = 0.1, b = 0.1},
        noPowerColor = {r = 0.1, g = 0.3, b = 0.8},
        notUsableColor = {r = 0.4, g = 0.4, b = 0.4},

        -- Cooldown settings
        colorSwipeNormal = {r = 0, g = 0, b = 0, a = 0.8},
        colorSwipeLOC = {r = 0.8, g = 0.1, b = 0.1},
        hideCooldownBling = false,

        -- Bar 1 (Main Action Bar)
        bar1 = {
            enabled = true,
            buttons = 12,
            buttonsPerRow = 12,
            buttonSize = 32,
            buttonHeight = 32,
            buttonSpacing = 2,
            backdropSpacing = 4,

            -- Visibility
            alpha = 1,
            mouseover = false,
            mouseoverAlpha = 0.2,
            clickThrough = false,
            backdrop = true,
            showGrid = true,
            visibility = "[petbattle][vehicleui][overridebar] hide; show",

            -- Positioning
            point = "BOTTOM",
            xOffset = 0,
            yOffset = 4,

            -- Paging (class-specific action page switching)
            paging = true,

            -- Text display
            hotkeytext = true,
            hotkeyColor = {r = 1, g = 1, b = 1},
            hotkeyFont = "Friz Quadrata TT",
            hotkeyFontSize = 12,
            hotkeyFontOutline = "OUTLINE",
            hotkeyTextPosition = "TOPRIGHT",
            hotkeyTextXOffset = 0,
            hotkeyTextYOffset = 0,

            macrotext = true,
            macroColor = {r = 1, g = 1, b = 1},
            macroFont = "Friz Quadrata TT",
            macroFontSize = 12,
            macroFontOutline = "NONE",
            macroTextPosition = "BOTTOM",
            macroTextXOffset = 0,
            macroTextYOffset = 2,

            counttext = true,
            countColor = {r = 1, g = 1, b = 1},
            countFont = "Friz Quadrata TT",
            countFontSize = 14,
            countFontOutline = "OUTLINE",
            countTextPosition = "BOTTOMRIGHT",
            countTextXOffset = 0,
            countTextYOffset = 2,
        },

        -- Bars 2-5 (Enabled by default)
        bar2 = {
            enabled = true,
            buttons = 12,
            buttonsPerRow = 12,
            buttonSize = 32,
            buttonHeight = 32,
            buttonSpacing = 2,
            backdropSpacing = 2,
            alpha = 1,
            mouseover = false,
            mouseoverAlpha = 0.2,
            backdrop = true,
            showGrid = false,
            visibility = "[petbattle][vehicleui][overridebar] hide; show",
            point = "BOTTOM",
            xOffset = 0,
            yOffset = 40,
            hotkeytext = true,
            macrotext = true,
            counttext = true,
        },

        bar3 = {
            enabled = true,
            buttons = 12,
            buttonsPerRow = 12,
            buttonSize = 32,
            buttonHeight = 32,
            buttonSpacing = 2,
            backdropSpacing = 2,
            alpha = 1,
            mouseover = false,
            mouseoverAlpha = 0.2,
            backdrop = true,
            showGrid = false,
            visibility = "[petbattle][vehicleui][overridebar] hide; show",
            point = "BOTTOM",
            xOffset = 0,
            yOffset = 76,
            hotkeytext = true,
            macrotext = true,
            counttext = true,
        },

        bar4 = {
            enabled = true,
            buttons = 12,
            buttonsPerRow = 1,
            buttonSize = 32,
            buttonHeight = 32,
            buttonSpacing = 2,
            backdropSpacing = 2,
            alpha = 1,
            mouseover = false,
            mouseoverAlpha = 0.2,
            backdrop = true,
            showGrid = false,
            visibility = "[petbattle][vehicleui][overridebar] hide; show",
            point = "RIGHT",
            xOffset = -4,
            yOffset = 0,
            hotkeytext = true,
            macrotext = false,
            counttext = true,
        },

        bar5 = {
            enabled = true,
            buttons = 12,
            buttonsPerRow = 1,
            buttonSize = 32,
            buttonHeight = 32,
            buttonSpacing = 2,
            backdropSpacing = 2,
            alpha = 1,
            mouseover = false,
            mouseoverAlpha = 0.2,
            backdrop = true,
            showGrid = false,
            visibility = "[petbattle][vehicleui][overridebar] hide; show",
            point = "RIGHT",
            xOffset = -40,
            yOffset = 0,
            hotkeytext = true,
            macrotext = false,
            counttext = true,
        },

        -- Bars 6-15 (Disabled by default, for advanced users)
        bar6 = { enabled = false, buttons = 12, buttonsPerRow = 12, buttonSize = 32, buttonHeight = 32, buttonSpacing = 2, backdropSpacing = 2, alpha = 1, mouseover = false, backdrop = true, showGrid = false, visibility = "[petbattle][vehicleui][overridebar] hide; show", point = "BOTTOMLEFT", xOffset = 4, yOffset = 4, hotkeytext = true, macrotext = true, counttext = true },
        bar7 = { enabled = false, buttons = 12, buttonsPerRow = 12, buttonSize = 32, buttonHeight = 32, buttonSpacing = 2, backdropSpacing = 2, alpha = 1, mouseover = false, backdrop = true, showGrid = false, visibility = "[petbattle][vehicleui][overridebar] hide; show", point = "BOTTOMLEFT", xOffset = 4, yOffset = 40, hotkeytext = true, macrotext = true, counttext = true },
        bar8 = { enabled = false, buttons = 12, buttonsPerRow = 12, buttonSize = 32, buttonHeight = 32, buttonSpacing = 2, backdropSpacing = 2, alpha = 1, mouseover = false, backdrop = true, showGrid = false, visibility = "[petbattle][vehicleui][overridebar] hide; show", point = "BOTTOMLEFT", xOffset = 4, yOffset = 76, hotkeytext = true, macrotext = true, counttext = true },
        bar9 = { enabled = false, buttons = 12, buttonsPerRow = 12, buttonSize = 32, buttonHeight = 32, buttonSpacing = 2, backdropSpacing = 2, alpha = 1, mouseover = false, backdrop = true, showGrid = false, visibility = "[petbattle][vehicleui][overridebar] hide; show", point = "BOTTOMLEFT", xOffset = 4, yOffset = 112, hotkeytext = true, macrotext = true, counttext = true },
        bar10 = { enabled = false, buttons = 12, buttonsPerRow = 12, buttonSize = 32, buttonHeight = 32, buttonSpacing = 2, backdropSpacing = 2, alpha = 1, mouseover = false, backdrop = true, showGrid = false, visibility = "[petbattle][vehicleui][overridebar] hide; show", point = "BOTTOMLEFT", xOffset = 4, yOffset = 148, hotkeytext = true, macrotext = true, counttext = true },
        bar11 = { enabled = false, buttons = 12, buttonsPerRow = 12, buttonSize = 32, buttonHeight = 32, buttonSpacing = 2, backdropSpacing = 2, alpha = 1, mouseover = false, backdrop = true, showGrid = false, visibility = "[petbattle][vehicleui][overridebar] hide; show", point = "BOTTOMLEFT", xOffset = 4, yOffset = 184, hotkeytext = true, macrotext = true, counttext = true },
        bar12 = { enabled = false, buttons = 12, buttonsPerRow = 12, buttonSize = 32, buttonHeight = 32, buttonSpacing = 2, backdropSpacing = 2, alpha = 1, mouseover = false, backdrop = true, showGrid = false, visibility = "[petbattle][vehicleui][overridebar] hide; show", point = "BOTTOMLEFT", xOffset = 4, yOffset = 220, hotkeytext = true, macrotext = true, counttext = true },
        bar13 = { enabled = false, buttons = 12, buttonsPerRow = 12, buttonSize = 32, buttonHeight = 32, buttonSpacing = 2, backdropSpacing = 2, alpha = 1, mouseover = false, backdrop = true, showGrid = false, visibility = "[petbattle][vehicleui][overridebar] hide; show", point = "BOTTOMLEFT", xOffset = 4, yOffset = 256, hotkeytext = true, macrotext = true, counttext = true },
        bar14 = { enabled = false, buttons = 12, buttonsPerRow = 12, buttonSize = 32, buttonHeight = 32, buttonSpacing = 2, backdropSpacing = 2, alpha = 1, mouseover = false, backdrop = true, showGrid = false, visibility = "[petbattle][vehicleui][overridebar] hide; show", point = "BOTTOMLEFT", xOffset = 4, yOffset = 292, hotkeytext = true, macrotext = true, counttext = true },
        bar15 = { enabled = false, buttons = 12, buttonsPerRow = 12, buttonSize = 32, buttonHeight = 32, buttonSpacing = 2, backdropSpacing = 2, alpha = 1, mouseover = false, backdrop = true, showGrid = false, visibility = "[petbattle][vehicleui][overridebar] hide; show", point = "BOTTOMLEFT", xOffset = 4, yOffset = 328, hotkeytext = true, macrotext = true, counttext = true },

        -- Special bars
        barPet = {
            enabled = true,
            buttons = 10,
            buttonsPerRow = 10,
            buttonSize = 30,
            buttonHeight = 30,
            buttonSpacing = 2,
            backdropSpacing = 2,
            alpha = 1,
            mouseover = false,
            backdrop = true,
            showGrid = false,
            point = "BOTTOM",
            xOffset = 0,
            yOffset = 112,
            hotkeytext = true,
            hotkeyFontSize = 10,
            counttext = true,
            countFontSize = 12,
        },

        barStance = {
            enabled = true,
            buttonSize = 30,
            buttonHeight = 30,
            buttonSpacing = 2,
            backdropSpacing = 2,
            alpha = 1,
            mouseover = false,
            backdrop = true,
            point = "BOTTOMLEFT",
            xOffset = 4,
            yOffset = 4,
            hotkeytext = false,
        },

        microbar = {
            enabled = true,
            buttonSize = 20,
            buttonHeight = 20,
            buttonSpacing = 2,
            backdropSpacing = 2,
            alpha = 1,
            mouseover = true,
            mouseoverAlpha = 0.2,
            backdrop = true,
            point = "TOPRIGHT",
            xOffset = -4,
            yOffset = -4,
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
E.db = CopyTable(E.ProfileDefaults, E.db)
