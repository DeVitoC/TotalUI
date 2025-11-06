--[[
    TotalUI - Utilities
    Helper functions used throughout the addon.
--]]

local AddonName, ns = ...
local E = ns.public

-- Math utilities
function E:Round(num, decimals)
    decimals = decimals or 0
    local mult = 10 ^ decimals
    return math.floor(num * mult + 0.5) / mult
end

function E:Clamp(value, min, max)
    if value < min then
        return min
    elseif value > max then
        return max
    else
        return value
    end
end

-- Color utilities
function E:RGBToHex(r, g, b)
    r = E:Clamp(r, 0, 1)
    g = E:Clamp(g, 0, 1)
    b = E:Clamp(b, 0, 1)
    return string.format("|cff%02x%02x%02x", r * 255, g * 255, b * 255)
end

-- Value formatting
function E:ShortValue(value)
    if value >= 1e9 then
        return string.format("%.1fb", value / 1e9)
    elseif value >= 1e6 then
        return string.format("%.1fm", value / 1e6)
    elseif value >= 1e3 then
        return string.format("%.1fk", value / 1e3)
    else
        return tostring(math.floor(value))
    end
end
