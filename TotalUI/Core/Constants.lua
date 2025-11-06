--[[
    TotalUI - Constants
    Global constants and lookup tables used throughout the addon.
--]]

local AddonName, ns = ...
local E = ns.public

-- Class colors (from RAID_CLASS_COLORS)
E.ClassColors = {}
local RAID_CLASS_COLORS = _G.RAID_CLASS_COLORS

if RAID_CLASS_COLORS then
    for class, color in pairs(RAID_CLASS_COLORS) do
        E.ClassColors[class] = {
            r = color.r,
            g = color.g,
            b = color.b,
            colorStr = color.colorStr
        }
    end
end

-- Power type colors
E.PowerColors = {
    ["MANA"] = {r = 0.31, g = 0.45, b = 0.63},
    ["RAGE"] = {r = 0.69, g = 0.31, b = 0.31},
    ["FOCUS"] = {r = 0.71, g = 0.43, b = 0.27},
    ["ENERGY"] = {r = 0.65, g = 0.63, b = 0.35},
    ["CHI"] = {r = 0.71, g = 1.0, b = 0.92},
    ["RUNES"] = {r = 0.55, g = 0.57, b = 0.61},
    ["RUNIC_POWER"] = {r = 0.0, g = 0.82, b = 1.0},
    ["SOUL_SHARDS"] = {r = 0.50, g = 0.32, b = 0.55},
    ["LUNAR_POWER"] = {r = 0.30, g = 0.52, b = 0.90},
    ["HOLY_POWER"] = {r = 0.95, g = 0.90, b = 0.60},
    ["MAELSTROM"] = {r = 0.0, g = 0.5, b = 1.0},
    ["INSANITY"] = {r = 0.40, g = 0, b = 0.80},
    ["FURY"] = {r = 0.788, g = 0.259, b = 0.992},
    ["PAIN"] = {r = 1.0, g = 0.61, b = 0.0},
    ["ESSENCE"] = {r = 1.0, g = 1.0, b = 0.82},
}

-- Reaction colors (friendly, neutral, hostile)
E.ReactionColors = {
    [1] = {r = 0.78, g = 0.25, b = 0.25}, -- Hated (Hostile)
    [2] = {r = 0.78, g = 0.25, b = 0.25}, -- Hostile
    [3] = {r = 0.75, g = 0.27, b = 0},    -- Unfriendly
    [4] = {r = 0.9, g = 0.7, b = 0},      -- Neutral
    [5] = {r = 0, g = 0.6, b = 0.1},      -- Friendly
    [6] = {r = 0, g = 0.6, b = 0.1},      -- Honored
    [7] = {r = 0, g = 0.6, b = 0.1},      -- Revered
    [8] = {r = 0, g = 0.6, b = 0.1},      -- Exalted
}

-- Debuff type colors
E.DebuffColors = {
    ["Magic"] = {r = 0.2, g = 0.6, b = 1.0},
    ["Curse"] = {r = 0.6, g = 0.0, b = 1.0},
    ["Disease"] = {r = 0.6, g = 0.4, b = 0.0},
    ["Poison"] = {r = 0.0, g = 0.6, b = 0.0},
    ["Bleed"] = {r = 1.0, g = 0.0, b = 0.0},
    ["none"] = {r = 0.8, g = 0.0, b = 0.0},
}

-- Quality/Rarity colors (will be populated during initialization)
E.QualityColors = {}

-- Function to initialize quality colors (called after addon loads)
function E:InitializeQualityColors()
    if C_Item and C_Item.GetItemQualityColor then
        for i = 0, 8 do
            local r, g, b = C_Item.GetItemQualityColor(i)
            self.QualityColors[i] = {r = r, g = g, b = b}
        end
    else
        -- Fallback quality colors if C_Item not available
        self.QualityColors = {
            [0] = {r = 0.61, g = 0.61, b = 0.61}, -- Poor (Gray)
            [1] = {r = 1.00, g = 1.00, b = 1.00}, -- Common (White)
            [2] = {r = 0.12, g = 1.00, b = 0.00}, -- Uncommon (Green)
            [3] = {r = 0.00, g = 0.44, b = 0.87}, -- Rare (Blue)
            [4] = {r = 0.64, g = 0.21, b = 0.93}, -- Epic (Purple)
            [5] = {r = 1.00, g = 0.50, b = 0.00}, -- Legendary (Orange)
            [6] = {r = 0.90, g = 0.80, b = 0.50}, -- Artifact (Gold)
            [7] = {r = 0.00, g = 0.80, b = 1.00}, -- Heirloom (Light Blue)
            [8] = {r = 0.00, g = 0.80, b = 1.00}, -- WoW Token (Light Blue)
        }
    end
end

-- Unit classification
E.Classification = {
    worldboss = "Boss",
    rareelite = "Rare Elite",
    elite = "Elite",
    rare = "Rare",
    normal = "",
    trivial = "",
    minus = "",
}

-- Common textures
E.Media = {
    Blank = [[Interface\Buttons\WHITE8X8]],
    GlowTex = [[Interface\ChatFrame\ChatFrameBackground]],
    ArrowUp = [[Interface\Buttons\Arrow-Up-Up]],
    ArrowDown = [[Interface\Buttons\Arrow-Down-Up]],
}

-- Direction constants
E.Points = {
    "TOPLEFT",
    "TOPRIGHT",
    "BOTTOMLEFT",
    "BOTTOMRIGHT",
    "TOP",
    "BOTTOM",
    "LEFT",
    "RIGHT",
    "CENTER",
}

-- Version check
E.VersionCheck = {
    LastCheck = 0,
    CheckInterval = 86400, -- 24 hours in seconds
}
