--[[
    TotalUI - StanceBar Class
    Handles creation and management of the stance/form bar.

    Note: Stance buttons are special secure buttons that change the player's stance/form.
    They work differently from regular action buttons and require SecureActionButtonTemplate.
--]]

local AddonName, ns = ...
local E = ns.public

-- Create StanceBar class
local StanceBar = {}
StanceBar.__index = StanceBar

-----------------------------------
-- CONSTRUCTOR
-----------------------------------

function StanceBar:New(parent)
    local bar = setmetatable({}, StanceBar)

    bar.parent = parent
    bar.buttons = {}
    bar.db = E.db.actionbar.barStance

    if not bar.db then
        error("StanceBar: No configuration found in database")
        return nil
    end

    bar:Create()

    return bar
end

-----------------------------------
-- FRAME CREATION
-----------------------------------

function StanceBar:Create()
    -- Create main bar frame (secure for combat safety)
    local frameName = "TotalUI_StanceBar"
    self.frame = CreateFrame("Frame", frameName, self.parent or UIParent, "SecureHandlerStateTemplate")
    self.frame:SetFrameStrata("LOW")
    self.frame:SetFrameLevel(5)

    -- Store reference
    self.frame.bar = self

    -- Create backdrop if enabled
    if self.db.backdrop then
        E:CreateBackdrop(self.frame)
    end

    -- Create buttons
    self:CreateButtons()

    -- Initial setup
    self:PositionButtons()
    self:UpdateBarSize()
    self:SetupVisibility()
    self:SetupMouseover()
    self:PositionBar()

    -- Register for events
    self:RegisterEvents()
end

function StanceBar:CreateButtons()
    -- Get number of stances/forms for current class
    local numStances = GetNumShapeshiftForms()

    if numStances == 0 then
        -- No stances for this class
        self.frame:Hide()
        return
    end

    -- Create stance buttons (max 10)
    for i = 1, min(numStances, 10) do
        local button = self:CreateButton(i)
        if button then
            self.buttons[i] = button
        end
    end
end

function StanceBar:CreateButton(buttonID)
    -- Create button name
    local buttonName = string.format("TotalUI_StanceButton%d", buttonID)

    -- Create secure button for stance changes
    local button = CreateFrame("CheckButton", buttonName, self.frame, "SecureActionButtonTemplate, ActionButtonTemplate")

    -- Set button attributes for stance changing
    button:SetAttribute("type", "spell")
    button:SetAttribute("*action" .. buttonID, buttonID)

    -- Register for clicks
    button:RegisterForClicks("AnyUp", "AnyDown")

    -- Set size
    button:SetSize(self.db.buttonSize, self.db.buttonHeight or self.db.buttonSize)

    -- Create icon texture
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints(button)
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)  -- Crop edges like ElvUI

    -- Create cooldown frame
    button.cooldown = CreateFrame("Cooldown", buttonName .. "Cooldown", button, "CooldownFrameTemplate")
    button.cooldown:SetAllPoints(button.icon)
    button.cooldown:SetDrawEdge(true)

    -- Create border
    button.border = button:CreateTexture(nil, "OVERLAY")
    button.border:SetAllPoints(button)
    button.border:SetTexture([[Interface\Buttons\UI-ActionButton-Border]])
    button.border:SetBlendMode("ADD")
    button.border:Hide()

    -- Create hotkey text (optional)
    if self.db.hotkeytext then
        button.HotKey = button:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmallGray")
        button.HotKey:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)
        button.HotKey:SetJustifyH("RIGHT")
        button.HotKey:SetText("") -- Will be set by keybinding system
    end

    -- Create normal texture (backdrop)
    button:SetNormalTexture([[Interface\Buttons\UI-Quickslot2]])
    local normal = button:GetNormalTexture()
    if normal then
        normal:SetTexCoord(0.2, 0.8, 0.2, 0.8)
        normal:SetAllPoints(button)
    end

    -- Create pushed texture
    button:SetPushedTexture([[Interface\Buttons\UI-Quickslot-Depress]])
    local pushed = button:GetPushedTexture()
    if pushed then
        pushed:SetAllPoints(button)
    end

    -- Create highlighted texture
    button:SetHighlightTexture([[Interface\Buttons\ButtonHilight-Square]])
    local highlight = button:GetHighlightTexture()
    if highlight then
        highlight:SetAllPoints(button)
        highlight:SetBlendMode("ADD")
    end

    -- Create checked texture (for active stance)
    button:SetCheckedTexture([[Interface\Buttons\CheckButtonHilight]])
    local checked = button:GetCheckedTexture()
    if checked then
        checked:SetAllPoints(button)
        checked:SetBlendMode("ADD")
    end

    -- Button scripts
    button:SetScript("OnEnter", function(self)
        if GetCVar("UberTooltips") == "1" then
            GameTooltip_SetDefaultAnchor(GameTooltip, self)
        else
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        end
        GameTooltip:SetShapeshift(self:GetID())
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Store button ID
    button:SetID(buttonID)

    -- Update button content
    self:UpdateButton(button, buttonID)

    return button
end

-----------------------------------
-- BUTTON UPDATES
-----------------------------------

function StanceBar:UpdateButton(button, buttonID)
    if not button then return end

    local texture, name, isActive, isCastable = GetShapeshiftFormInfo(buttonID)

    if not texture then
        button:Hide()
        return
    end

    -- Update icon
    button.icon:SetTexture(texture)

    -- Update checked state
    if isActive then
        button:SetChecked(true)
    else
        button:SetChecked(false)
    end

    -- Update usability
    if isCastable then
        button.icon:SetVertexColor(1, 1, 1)
    else
        button.icon:SetVertexColor(0.4, 0.4, 0.4)
    end

    -- Update cooldown
    local start, duration, enable = GetShapeshiftFormCooldown(buttonID)
    if button.cooldown then
        CooldownFrame_Set(button.cooldown, start, duration, enable)
    end

    button:Show()
end

function StanceBar:UpdateAllButtons()
    for i, button in ipairs(self.buttons) do
        self:UpdateButton(button, i)
    end
end

-----------------------------------
-- POSITIONING
-----------------------------------

function StanceBar:PositionButtons()
    local db = self.db
    local spacing = db.buttonSpacing
    local backdropSpacing = db.backdropSpacing

    -- Use configured button size
    local buttonWidth = db.buttonSize
    local buttonHeight = db.buttonHeight or db.buttonSize

    -- Determine if we should arrange horizontally or vertically
    -- Default is horizontal
    local buttonsPerRow = #self.buttons

    for i = 1, #self.buttons do
        local button = self.buttons[i]
        if button then
            button:ClearAllPoints()

            -- Calculate position (horizontal layout)
            local xOffset = backdropSpacing + ((i - 1) * (buttonWidth + spacing))
            local yOffset = -backdropSpacing

            -- Set position
            button:SetPoint("TOPLEFT", self.frame, "TOPLEFT", xOffset, yOffset)
        end
    end
end

function StanceBar:UpdateBarSize()
    local db = self.db
    local numButtons = #self.buttons

    if numButtons == 0 then
        self.frame:SetSize(1, 1)
        return
    end

    -- Use configured button size
    local buttonWidth = db.buttonSize
    local buttonHeight = db.buttonHeight or db.buttonSize

    -- Horizontal layout
    local width = (numButtons * buttonWidth) + ((numButtons - 1) * db.buttonSpacing) + (db.backdropSpacing * 2)
    local height = buttonHeight + (db.backdropSpacing * 2)

    self.frame:SetSize(width, height)
end

function StanceBar:PositionBar()
    local db = self.db

    self.frame:ClearAllPoints()
    self.frame:SetPoint(db.point or "BOTTOMLEFT", UIParent, db.point or "BOTTOMLEFT", db.xOffset or 4, db.yOffset or 4)
end

-----------------------------------
-- VISIBILITY
-----------------------------------

function StanceBar:SetupVisibility()
    -- Stance bar should show when player has stances/forms
    -- Hide during pet battles, vehicles, and override bars
    -- Also only show if the player actually has forms (handled by button creation)

    if #self.buttons == 0 then
        self.frame:Hide()
        return
    end

    local visibilityMacro = "[petbattle][overridebar][vehicleui][possessbar] hide; show"

    -- Use secure attribute driver for visibility
    RegisterAttributeDriver(self.frame, "state-visibility", visibilityMacro)
end

-----------------------------------
-- MOUSEOVER FADE
-----------------------------------

function StanceBar:SetupMouseover()
    local db = self.db

    -- Clear any existing scripts
    self.frame:SetScript("OnEnter", nil)
    self.frame:SetScript("OnLeave", nil)

    if not db.mouseover then
        -- No mouseover, set normal alpha
        self.frame:SetAlpha(db.alpha or 1)
        return
    end

    -- Set initial faded alpha
    self.frame:SetAlpha(db.mouseoverAlpha or 0.2)

    -- Fade in on mouse enter
    self.frame:SetScript("OnEnter", function(frame)
        UIFrameFadeIn(frame, 0.2, frame:GetAlpha(), db.alpha or 1)
    end)

    -- Fade out on mouse leave
    self.frame:SetScript("OnLeave", function(frame)
        UIFrameFadeOut(frame, 0.2, frame:GetAlpha(), db.mouseoverAlpha or 0.2)
    end)

    -- Also enable mouseover for all buttons
    for _, button in ipairs(self.buttons) do
        if button then
            button:SetScript("OnEnter", function()
                self.frame:GetScript("OnEnter")(self.frame)
            end)
            button:SetScript("OnLeave", function()
                self.frame:GetScript("OnLeave")(self.frame)
            end)
        end
    end
end

-----------------------------------
-- EVENTS
-----------------------------------

function StanceBar:RegisterEvents()
    -- StanceBar needs to update when stance state changes
    if not self.eventFrame then
        self.eventFrame = CreateFrame("Frame")
    end

    self.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.eventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
    self.eventFrame:RegisterEvent("UPDATE_SHAPESHIFT_USABLE")
    self.eventFrame:RegisterEvent("UPDATE_SHAPESHIFT_COOLDOWN")
    self.eventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    self.eventFrame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
    self.eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    self.eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

    self.eventFrame:SetScript("OnEvent", function(_, event, ...)
        if event == "PLAYER_ENTERING_WORLD" or event == "UPDATE_SHAPESHIFT_FORMS" then
            self:Rebuild()
        elseif event == "UPDATE_SHAPESHIFT_FORM" or event == "ACTIONBAR_PAGE_CHANGED" then
            self:UpdateAllButtons()
        elseif event == "UPDATE_SHAPESHIFT_COOLDOWN" then
            self:UpdateCooldowns()
        elseif event == "UPDATE_SHAPESHIFT_USABLE" then
            self:UpdateUsability()
        end
    end)
end

function StanceBar:Rebuild()
    -- Clear existing buttons
    for _, button in ipairs(self.buttons) do
        button:Hide()
    end
    self.buttons = {}

    -- Recreate buttons
    self:CreateButtons()
    self:PositionButtons()
    self:UpdateBarSize()
    self:SetupVisibility()
end

function StanceBar:UpdateCooldowns()
    for i, button in ipairs(self.buttons) do
        local start, duration, enable = GetShapeshiftFormCooldown(i)
        if button.cooldown then
            CooldownFrame_Set(button.cooldown, start, duration, enable)
        end
    end
end

function StanceBar:UpdateUsability()
    for i, button in ipairs(self.buttons) do
        local _, _, _, isCastable = GetShapeshiftFormInfo(i)
        if isCastable then
            button.icon:SetVertexColor(1, 1, 1)
        else
            button.icon:SetVertexColor(0.4, 0.4, 0.4)
        end
    end
end

-----------------------------------
-- UPDATE
-----------------------------------

function StanceBar:Update()
    -- Check combat
    if InCombatLockdown() then
        E:QueueAfterCombat(function()
            self:Update()
        end)
        E:Print("StanceBar: Changes will apply after combat")
        return
    end

    -- Update configuration reference
    self.db = E.db.actionbar.barStance

    if not self.db or not self.db.enabled then
        self.frame:Hide()
        return
    end

    -- Update all aspects
    self:PositionButtons()
    self:UpdateBarSize()
    self:SetupVisibility()
    self:SetupMouseover()
    self:PositionBar()

    -- Update all buttons
    for _, button in ipairs(self.buttons) do
        if button then
            -- Update button size
            button:SetSize(self.db.buttonSize, self.db.buttonHeight or self.db.buttonSize)

            -- Update icon to match new button size
            if button.icon then
                button.icon:SetAllPoints(button)
            end
            if button.cooldown then
                button.cooldown:SetAllPoints(button.icon)
            end
        end
    end

    self:UpdateAllButtons()

    -- Show/hide frame
    if self.db.enabled and #self.buttons > 0 then
        self.frame:Show()
    else
        self.frame:Hide()
    end
end

-----------------------------------
-- CLEANUP
-----------------------------------

function StanceBar:Destroy()
    -- Unregister events
    if self.eventFrame then
        self.eventFrame:UnregisterAllEvents()
    end

    -- Clean up buttons
    for _, button in ipairs(self.buttons) do
        if button then
            button:Hide()
        end
    end

    -- Hide and clear frame
    if self.frame then
        self.frame:Hide()
        self.frame = nil
    end

    self.buttons = {}
end

-- Export class to namespace
ns.StanceBar = StanceBar
