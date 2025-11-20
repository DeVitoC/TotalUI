--[[
    TotalUI - Cooldown Display Handler
    Manages cooldown animations and text formatting for action buttons.

    Features:
    - Cooldown sweep color customization
    - Loss of Control (LOC) cooldown coloring
    - Cooldown text formatting and positioning
    - Hide/show cooldown bling animation
    - Desaturation on cooldown
--]]

local AddonName, ns = ...
local E = ns.public

-- Create Cooldown handler
local Cooldown = {}
Cooldown.__index = Cooldown

-----------------------------------
-- CONSTRUCTOR
-----------------------------------

function Cooldown:New()
    local handler = setmetatable({}, Cooldown)

    handler.db = E.db.actionbar
    handler.hooked = {}

    handler:Initialize()

    return handler
end

-----------------------------------
-- INITIALIZATION
-----------------------------------

function Cooldown:Initialize()
    -- Hook into cooldown frame creation
    self:HookCooldowns()
end

-----------------------------------
-- COOLDOWN HOOKING
-----------------------------------

function Cooldown:HookCooldowns()
    -- Hook the Cooldown_OnShow to apply our settings
    if not self.hooked.CooldownOnShow then
        hooksecurefunc("CooldownFrame_Set", function(cooldown, start, duration, enable, ...)
            self:OnCooldownSet(cooldown, start, duration, enable)
        end)
        self.hooked.CooldownOnShow = true
    end
end

function Cooldown:OnCooldownSet(cooldown, start, duration, enable)
    if not cooldown or not enable or duration <= 0 then
        return
    end

    -- Only apply to our action button cooldowns
    if not self:IsOurCooldown(cooldown) then
        return
    end

    -- Apply custom cooldown settings
    self:ApplyCooldownSettings(cooldown, start, duration)
end

function Cooldown:IsOurCooldown(cooldown)
    if not cooldown then return false end

    local parent = cooldown:GetParent()
    if not parent then return false end

    local name = parent:GetName()
    if not name then return false end

    -- Check if it's one of our buttons
    if name:match("^TotalUI_Bar%d+Button%d+") or
       name:match("^TotalUI_PetBarButton%d+") or
       name:match("^TotalUI_StanceButton%d+") then
        return true
    end

    return false
end

-----------------------------------
-- COOLDOWN SETTINGS
-----------------------------------

function Cooldown:ApplyCooldownSettings(cooldown, start, duration)
    local db = self.db

    -- Set sweep color
    if db.colorSwipeNormal then
        local c = db.colorSwipeNormal
        cooldown:SetSwipeColor(c.r, c.g, c.b, c.a or 0.8)
    end

    -- Check if this is a Loss of Control effect
    if self:IsLOCCooldown(cooldown) and db.colorSwipeLOC then
        local c = db.colorSwipeLOC
        cooldown:SetSwipeColor(c.r, c.g, c.b, c.a or 1)
    end

    -- Hide/show cooldown bling
    if db.hideCooldownBling then
        cooldown:SetHideCountdownNumbers(false)
        cooldown:SetDrawBling(false)
    else
        cooldown:SetDrawBling(true)
    end

    -- Handle desaturation
    if db.desaturateOnCooldown then
        self:ApplyDesaturation(cooldown, true)
    end
end

function Cooldown:IsLOCCooldown(cooldown)
    -- Loss of Control cooldowns are typically shorter and have specific characteristics
    -- This is a simplified check - in production you'd check against known LOC spell IDs
    if not cooldown then return false end

    local start, duration = cooldown:GetCooldownTimes()
    if start == 0 or duration == 0 then return false end

    -- LOC effects are typically < 10 seconds
    local remaining = (start + duration - GetTime() * 1000) / 1000
    if remaining > 10 then return false end

    -- Check parent button for LOC-specific attributes
    local parent = cooldown:GetParent()
    if parent and parent.isLOC then
        return true
    end

    return false
end

function Cooldown:ApplyDesaturation(cooldown, desaturate)
    local parent = cooldown:GetParent()
    if not parent then return end

    local icon = parent.icon or parent.Icon
    if icon then
        icon:SetDesaturated(desaturate)
    end
end

-----------------------------------
-- COOLDOWN TEXT FORMATTING
-----------------------------------

function Cooldown:FormatTime(seconds)
    if seconds >= 86400 then
        -- Days
        return string.format("%dd", math.floor(seconds / 86400))
    elseif seconds >= 3600 then
        -- Hours
        return string.format("%dh", math.floor(seconds / 3600))
    elseif seconds >= 60 then
        -- Minutes
        return string.format("%dm", math.floor(seconds / 60))
    elseif seconds >= 3 then
        -- Seconds (whole numbers)
        return string.format("%d", math.floor(seconds))
    elseif seconds >= 0 then
        -- Seconds with decimal
        return string.format("%.1f", seconds)
    else
        return ""
    end
end

function Cooldown:GetTimeColor(seconds)
    if seconds < 3 then
        return 1, 0, 0 -- Red
    elseif seconds < 10 then
        return 1, 1, 0 -- Yellow
    else
        return 1, 1, 1 -- White
    end
end

-----------------------------------
-- GLOBAL COOLDOWN UPDATE
-----------------------------------

function Cooldown:UpdateAllCooldowns()
    -- Update all cooldown displays for our buttons
    -- This is called when settings change

    -- Note: We don't need to manually update each cooldown
    -- The hook will handle new cooldowns automatically
    -- This function exists for future use (e.g., forcing a refresh)
end

-----------------------------------
-- UTILITY
-----------------------------------

function Cooldown:EnableCooldownText()
    -- Enable cooldown text display
    -- This would integrate with OmniCC or other cooldown text addons
    -- For now, we rely on Blizzard's built-in cooldown numbers
end

function Cooldown:DisableCooldownText()
    -- Disable cooldown text display
end

function Cooldown:SetCooldownTextFont(font, size, flags)
    -- Set custom font for cooldown text
    -- This requires deeper integration with cooldown text addons
end

-----------------------------------
-- RESET
-----------------------------------

function Cooldown:ResetCooldown(cooldown)
    if not cooldown then return end

    -- Reset to default Blizzard appearance
    cooldown:SetSwipeColor(0, 0, 0, 0.8)
    cooldown:SetDrawBling(true)
    cooldown:SetHideCountdownNumbers(false)

    -- Remove desaturation
    self:ApplyDesaturation(cooldown, false)
end

function Cooldown:ResetAllCooldowns()
    -- Reset all our cooldowns to default
    for cooldown, _ in pairs(self.hooked) do
        if type(cooldown) == "table" and cooldown.Reset then
            self:ResetCooldown(cooldown)
        end
    end
end

-----------------------------------
-- UPDATE
-----------------------------------

function Cooldown:Update()
    -- Update configuration reference
    self.db = E.db.actionbar

    -- Refresh all cooldown settings
    self:UpdateAllCooldowns()
end

-----------------------------------
-- CLEANUP
-----------------------------------

function Cooldown:Destroy()
    -- Reset all cooldowns
    self:ResetAllCooldowns()

    -- Clear hooks
    self.hooked = {}
end

-- Export handler to namespace
ns.Cooldown = Cooldown
