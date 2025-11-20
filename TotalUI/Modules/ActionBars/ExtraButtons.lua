--[[
    TotalUI - ExtraButtons Class
    Handles positioning and styling of special action buttons.

    Manages:
    - Extra Action Button (quest/world content abilities)
    - Zone Action Button (zone-specific abilities)
    - Vehicle Exit Button (leave vehicle/mount)

    These buttons are created by Blizzard but we reposition and style them.
--]]

local AddonName, ns = ...
local E = ns.public

-- Create ExtraButtons class
local ExtraButtons = {}
ExtraButtons.__index = ExtraButtons

-----------------------------------
-- CONSTRUCTOR
-----------------------------------

function ExtraButtons:New()
    local buttons = setmetatable({}, ExtraButtons)

    buttons.db = E.db.actionbar
    buttons.frames = {}

    if not buttons.db then
        error("ExtraButtons: No configuration found in database")
        return nil
    end

    buttons:Initialize()

    return buttons
end

-----------------------------------
-- INITIALIZATION
-----------------------------------

function ExtraButtons:Initialize()
    -- Setup Extra Action Button
    self:SetupExtraActionButton()

    -- Setup Zone Action Button
    self:SetupZoneActionButton()

    -- Setup Vehicle Exit Button
    self:SetupVehicleExitButton()
end

-----------------------------------
-- EXTRA ACTION BUTTON
-----------------------------------

function ExtraButtons:SetupExtraActionButton()
    local db = self.db.extraActionButton

    if not db or not db.enabled then
        return
    end

    -- Get the Blizzard extra action button
    local button = ExtraActionBarFrame or _G.ExtraActionButton1
    if not button then
        E:Print("ExtraButtons: ExtraActionBarFrame not found")
        return
    end

    -- Store reference
    self.frames.extraAction = button

    -- Style and position
    self:StyleExtraActionButton(button, db)
end

function ExtraButtons:StyleExtraActionButton(button, db)
    if not button then return end

    -- Clear existing points
    button:ClearAllPoints()

    -- Set position
    button:SetPoint(db.point or "BOTTOM", UIParent, db.point or "BOTTOM", db.xOffset or 0, db.yOffset or 200)

    -- Set size and scale
    if db.buttonSize then
        button:SetSize(db.buttonSize, db.buttonSize)
    end

    if db.scale then
        button:SetScale(db.scale)
    end

    if db.alpha then
        button:SetAlpha(db.alpha)
    end

    -- Hide Blizzard styling if desired
    if button.style then
        button.style:SetAlpha(0)
    end
end

-----------------------------------
-- ZONE ACTION BUTTON
-----------------------------------

function ExtraButtons:SetupZoneActionButton()
    local db = self.db.zoneActionButton

    if not db or not db.enabled then
        return
    end

    -- Get the Blizzard zone action button
    local button = ZoneAbilityFrame
    if not button then
        E:Print("ExtraButtons: ZoneAbilityFrame not found")
        return
    end

    -- Store reference
    self.frames.zoneAction = button

    -- Style and position
    self:StyleZoneActionButton(button, db)
end

function ExtraButtons:StyleZoneActionButton(button, db)
    if not button then return end

    -- Clear existing points
    button:ClearAllPoints()

    -- Set position
    button:SetPoint(db.point or "BOTTOM", UIParent, db.point or "BOTTOM", db.xOffset or 0, db.yOffset or 260)

    -- Set scale
    if db.scale then
        button:SetScale(db.scale)
    end

    if db.alpha then
        button:SetAlpha(db.alpha)
    end

    -- Hide Blizzard styling if desired
    if button.Style then
        button.Style:SetAlpha(0)
    end
end

-----------------------------------
-- VEHICLE EXIT BUTTON
-----------------------------------

function ExtraButtons:SetupVehicleExitButton()
    local db = self.db.vehicleExitButton

    if not db or not db.enabled then
        return
    end

    -- Get the Blizzard vehicle exit button
    local button = MainMenuBarVehicleLeaveButton
    if not button then
        E:Print("ExtraButtons: MainMenuBarVehicleLeaveButton not found")
        return
    end

    -- Store reference
    self.frames.vehicleExit = button

    -- Style and position
    self:StyleVehicleExitButton(button, db)
end

function ExtraButtons:StyleVehicleExitButton(button, db)
    if not button then return end

    -- Clear existing points
    button:ClearAllPoints()

    -- Set position
    button:SetPoint(db.point or "BOTTOMLEFT", UIParent, db.point or "BOTTOMLEFT", db.xOffset or 100, db.yOffset or 100)

    -- Set size
    if db.buttonSize then
        button:SetSize(db.buttonSize, db.buttonSize)
    end

    -- Set scale
    if db.scale then
        button:SetScale(db.scale)
    end

    if db.alpha then
        button:SetAlpha(db.alpha)
    end
end

-----------------------------------
-- UPDATE
-----------------------------------

function ExtraButtons:Update()
    -- Check combat (button repositioning is combat restricted)
    if InCombatLockdown() then
        E:QueueAfterCombat(function()
            self:Update()
        end)
        E:Print("ExtraButtons: Changes will apply after combat")
        return
    end

    -- Update configuration reference
    self.db = E.db.actionbar

    -- Check if ActionBars module is globally disabled
    if not self.db.enable then
        -- Hide all extra buttons
        if self.frames.extraAction then
            self.frames.extraAction:Hide()
        end
        if self.frames.zoneAction then
            self.frames.zoneAction:Hide()
        end
        if self.frames.vehicleExit then
            self.frames.vehicleExit:Hide()
        end
        return
    end

    -- Update each button
    if self.frames.extraAction then
        local db = self.db.extraActionButton
        if db and db.enabled then
            self:StyleExtraActionButton(self.frames.extraAction, db)
        end
    end

    if self.frames.zoneAction then
        local db = self.db.zoneActionButton
        if db and db.enabled then
            self:StyleZoneActionButton(self.frames.zoneAction, db)
        end
    end

    if self.frames.vehicleExit then
        local db = self.db.vehicleExitButton
        if db and db.enabled then
            self:StyleVehicleExitButton(self.frames.vehicleExit, db)
        end
    end
end

-----------------------------------
-- SHOW/HIDE
-----------------------------------

function ExtraButtons:ShowExtraAction()
    if self.frames.extraAction then
        self.frames.extraAction:Show()
    end
end

function ExtraButtons:HideExtraAction()
    if self.frames.extraAction then
        self.frames.extraAction:Hide()
    end
end

function ExtraButtons:ShowZoneAction()
    if self.frames.zoneAction then
        self.frames.zoneAction:Show()
    end
end

function ExtraButtons:HideZoneAction()
    if self.frames.zoneAction then
        self.frames.zoneAction:Hide()
    end
end

function ExtraButtons:ShowVehicleExit()
    if self.frames.vehicleExit then
        self.frames.vehicleExit:Show()
    end
end

function ExtraButtons:HideVehicleExit()
    if self.frames.vehicleExit then
        self.frames.vehicleExit:Hide()
    end
end

-----------------------------------
-- CLEANUP
-----------------------------------

function ExtraButtons:Destroy()
    -- We don't destroy these buttons since they're Blizzard frames
    -- Just reset them to default positions

    -- Reset extra action button
    if self.frames.extraAction then
        self.frames.extraAction:ClearAllPoints()
        self.frames.extraAction:SetScale(1)
        self.frames.extraAction:SetAlpha(1)
    end

    -- Reset zone action button
    if self.frames.zoneAction then
        self.frames.zoneAction:ClearAllPoints()
        self.frames.zoneAction:SetScale(1)
        self.frames.zoneAction:SetAlpha(1)
    end

    -- Reset vehicle exit button
    if self.frames.vehicleExit then
        self.frames.vehicleExit:ClearAllPoints()
        self.frames.vehicleExit:SetScale(1)
        self.frames.vehicleExit:SetAlpha(1)
    end

    self.frames = {}
end

-- Export class to namespace
ns.ExtraButtons = ExtraButtons
