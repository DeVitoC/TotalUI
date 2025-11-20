--[[
    TotalUI - ActionBar Class
    Handles creation and management of individual action bars.
--]]

local AddonName, ns = ...
local E = ns.public

-- Create ActionBar class
local ActionBar = {}
ActionBar.__index = ActionBar

-- Class Action Page Mappings (for Bar 1 paging)
local CLASS_PAGING = {
    DRUID = "[bonusbar:1,nostealth] 7; [bonusbar:1,stealth] 8; [bonusbar:2] 8; [bonusbar:3] 9; [bonusbar:4] 10;",
    WARRIOR = "[bonusbar:1] 7; [bonusbar:2] 8; [bonusbar:3] 9;",
    PRIEST = "[bonusbar:1] 7;",
    ROGUE = "[bonusbar:1] 7; [form:1] 7; [form:2] 7; [form:3] 7;",
    WARLOCK = "[form:1] 7;",
    MONK = "[bonusbar:1] 7; [bonusbar:2] 8; [bonusbar:3] 9;",
    DEMONHUNTER = "[bonusbar:1] 7;",
    EVOKER = "[bonusbar:1] 7;",
}

-- Constructor
function ActionBar:New(id, parent)
    local bar = setmetatable({}, ActionBar)

    bar.id = id
    bar.parent = parent
    bar.buttons = {}
    bar.db = E.db.actionbar["bar" .. id]

    if not bar.db then
        error(string.format("ActionBar %d: No configuration found in database", id))
        return nil
    end

    bar:Create()

    return bar
end

-----------------------------------
-- FRAME CREATION
-----------------------------------

function ActionBar:Create()
    -- Create main bar frame (secure for combat safety)
    local frameName = "TotalUI_Bar" .. self.id
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
    self:SetupPaging()
    self:SetupMouseover()
    self:PositionBar()

    -- Register for updates
    self:RegisterEvents()
end

function ActionBar:CreateButtons()
    -- Check if LibTotalActionButtons is available
    local LTAB = E.Libs.LibTotalActionButtons

    if not LTAB then
        E:Print(string.format("Bar %d: LibTotalActionButtons not available, buttons will not function correctly", self.id))
        return
    end

    -- Create buttons
    for i = 1, self.db.buttons do
        local button = self:CreateButton(i, LTAB)
        if button then
            self.buttons[i] = button
        end
    end
end

function ActionBar:CreateButton(buttonID, LTAB)
    -- Calculate action ID (which WoW action slot this button represents)
    local actionID = self:GetActionID(buttonID)

    -- Create button name
    local buttonName = string.format("TotalUI_Bar%dButton%d", self.id, buttonID)

    -- Build config for LibTotalActionButtons
    local config = self:BuildButtonConfig()

    -- Create button using LibTotalActionButtons
    local button = LTAB:CreateButton(actionID, buttonName, self.frame, config)

    if not button then
        E:Print(string.format("Bar %d Button %d: Failed to create", self.id, buttonID))
        return nil
    end

    -- Set size using LibTotalActionButtons (properly resizes all button elements)
    LTAB:SetButtonSize(button, self.db.buttonSize, self.db.buttonHeight or self.db.buttonSize)

    -- Additional styling
    self:StyleButton(button, buttonID)
    self:ConfigureButton(button, buttonID)

    return button
end

function ActionBar:GetActionID(buttonID)
    -- WoW action IDs:
    -- Bar 1 = actions 1-12
    -- Bar 2 = actions 13-24
    -- Bar 3 = actions 25-36
    -- etc.
    return ((self.id - 1) * 12) + buttonID
end

-----------------------------------
-- BUTTON CONFIG
-----------------------------------

function ActionBar:BuildButtonConfig()
    local db = self.db
    local globalDB = E.db.actionbar

    -- Helper to convert {r,g,b} to array
    local function colorToArray(c)
        return {c.r or 1, c.g or 1, c.b or 1}
    end

    -- Build LibActionButton config
    return {
        clickOnDown = true,
        showGrid = db.showGrid,
        desaturateUnusable = globalDB.desaturateOnCooldown,
        colors = {
            range = colorToArray(globalDB.noRangeColor),
            mana = colorToArray(globalDB.noPowerColor),
            unusable = colorToArray(globalDB.notUsableColor),
        },
        hideElements = {
            equipped = not globalDB.equippedItem,
            hotkey = not db.hotkeytext,
            macro = not db.macrotext,
        },
        keyBoundTarget = false, -- We handle keybinds
        outOfRangeColoring = "button",
        outOfManaColoring = "button",
        text = {
            hotkey = {
                font = E.LSM:Fetch("font", db.hotkeyFont or E.db.general.font),
                size = db.hotkeyFontSize or 12,
                flags = db.hotkeyFontOutline or "OUTLINE",
                color = db.hotkeyColor and colorToArray(db.hotkeyColor) or {1, 1, 1},
                position = {
                    anchor = db.hotkeyTextPosition or "TOPRIGHT",
                    relAnchor = db.hotkeyTextPosition or "TOPRIGHT",
                    offsetX = db.hotkeyTextXOffset or 0,
                    offsetY = db.hotkeyTextYOffset or 0,
                },
            },
            count = {
                font = E.LSM:Fetch("font", db.countFont or E.db.general.font),
                size = db.countFontSize or 14,
                flags = db.countFontOutline or "OUTLINE",
                color = db.countColor and colorToArray(db.countColor) or {1, 1, 1},
                position = {
                    anchor = db.countTextPosition or "BOTTOMRIGHT",
                    relAnchor = db.countTextPosition or "BOTTOMRIGHT",
                    offsetX = db.countTextXOffset or 0,
                    offsetY = db.countTextYOffset or 2,
                },
            },
            macro = {
                font = E.LSM:Fetch("font", db.macroFont or E.db.general.font),
                size = db.macroFontSize or 12,
                flags = db.macroFontOutline or "NONE",
                color = db.macroColor and colorToArray(db.macroColor) or {1, 1, 1},
                position = {
                    anchor = db.macroTextPosition or "BOTTOM",
                    relAnchor = db.macroTextPosition or "BOTTOM",
                    offsetX = db.macroTextXOffset or 0,
                    offsetY = db.macroTextYOffset or 2,
                },
            },
        },
    }
end

-----------------------------------
-- BUTTON STYLING
-----------------------------------

function ActionBar:StyleButton(button, buttonID)
    -- LibTotalActionButtons handles most styling
    -- This function is for any bar-specific customization

    -- Ensure border is visible and styled correctly
    local border = button._border or button.Border or _G[button:GetName() .. "Border"]
    if border then
        border:SetTexture([[Interface\Buttons\UI-ActionButton-Border]])
        border:SetBlendMode("ADD")
    end
end

function ActionBar:ConfigureButton(button, buttonID)
    -- Additional button configuration can go here
    -- (keybindings, tooltips, etc.)
end

-----------------------------------
-- POSITIONING
-----------------------------------

function ActionBar:PositionButtons()
    local db = self.db
    local buttonsPerRow = db.buttonsPerRow
    local spacing = db.buttonSpacing
    local backdropSpacing = db.backdropSpacing

    -- Use configured button size (SetButtonSize ensures buttons are actually this size)
    local buttonWidth = db.buttonSize
    local buttonHeight = db.buttonHeight or db.buttonSize

    for i = 1, #self.buttons do
        local button = self.buttons[i]
        if button then
            button:ClearAllPoints()

            -- Calculate row and column
            local row = math.floor((i - 1) / buttonsPerRow)
            local col = (i - 1) % buttonsPerRow

            -- Calculate position
            local xOffset = backdropSpacing + (col * (buttonWidth + spacing))
            local yOffset = -(backdropSpacing + (row * (buttonHeight + spacing)))

            -- Set position
            button:SetPoint("TOPLEFT", self.frame, "TOPLEFT", xOffset, yOffset)
        end
    end
end

function ActionBar:UpdateBarSize()
    local db = self.db
    local numRows = math.ceil(db.buttons / db.buttonsPerRow)
    local numCols = math.min(db.buttons, db.buttonsPerRow)

    -- Use configured button size (SetButtonSize ensures buttons are actually this size)
    local buttonWidth = db.buttonSize
    local buttonHeight = db.buttonHeight or db.buttonSize

    local width = (numCols * buttonWidth) + ((numCols - 1) * db.buttonSpacing) + (db.backdropSpacing * 2)
    local height = (numRows * buttonHeight) + ((numRows - 1) * db.buttonSpacing) + (db.backdropSpacing * 2)

    self.frame:SetSize(width, height)
end

function ActionBar:PositionBar()
    local db = self.db

    self.frame:ClearAllPoints()
    self.frame:SetPoint(db.point or "BOTTOM", UIParent, db.point or "BOTTOM", db.xOffset or 0, db.yOffset or 0)
end

-----------------------------------
-- VISIBILITY & PAGING
-----------------------------------

function ActionBar:SetupVisibility()
    if not self.db.visibility or self.db.visibility == "" then
        self.frame:Show()
        return
    end

    -- Use secure attribute driver for visibility
    RegisterAttributeDriver(self.frame, "state-visibility", self.db.visibility)
end

function ActionBar:SetupPaging()
    -- Only Bar 1 typically uses paging
    if self.id ~= 1 or not self.db.paging then
        return
    end

    local _, playerClass = UnitClass("player")
    local pagingString = CLASS_PAGING[playerClass]

    if pagingString then
        -- Set up paging driver - this changes the frame's page state based on form/stance
        -- The page string format: "[condition] pageNum; [condition] pageNum; defaultPage"
        -- For Druid: bear=7, cat=8, moonkin=9, treant=10
        RegisterStateDriver(self.frame, "page", pagingString)

        -- Set up a secure snippet on the frame to update button actions when page changes
        self.frame:SetAttribute("_onstate-page", [[
            local page = tonumber(newstate) or 1
            for i = 1, 12 do
                local button = self:GetFrameRef("button"..i)
                if button then
                    -- Calculate new action ID: (page-1)*12 + buttonNum
                    -- Page 1, button 1 = action 1
                    -- Page 7, button 1 = action 73 (bear form)
                    local action = (page - 1) * 12 + i
                    button:SetAttribute("action", action)
                    button:CallMethod("UpdateAction")
                end
            end
        ]])

        -- Register button frame refs so the secure snippet can access them
        for i, button in ipairs(self.buttons) do
            if button then
                self.frame:SetFrameRef("button"..i, button)
            end
        end
    end
end

-----------------------------------
-- MOUSEOVER FADE
-----------------------------------

function ActionBar:SetupMouseover()
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

function ActionBar:RegisterEvents()
    -- Events can be registered here if needed
    -- For now, LibActionButton handles most button updates automatically
end

-----------------------------------
-- UPDATE
-----------------------------------

function ActionBar:Update()
    -- DEBUG
    print(string.format("Bar %d Update() called - global enable: %s, visible: %s", self.id, tostring(E.db.actionbar.enable), tostring(self.frame:IsVisible())))

    -- Check combat
    if InCombatLockdown() then
        E:QueueAfterCombat(function()
            self:Update()
        end)
        E:Print(string.format("Bar %d: Changes will apply after combat", self.id))
        return
    end

    -- Update configuration reference
    self.db = E.db.actionbar["bar" .. self.id]

    -- Check if ActionBars module is globally disabled
    if not E.db.actionbar.enable then
        print(string.format("Bar %d: HIDING due to global disable", self.id))
        -- Unregister any attribute drivers that might show the frame
        UnregisterAttributeDriver(self.frame, "state-visibility")
        UnregisterStateDriver(self.frame, "page")
        self.frame:Hide()
        return
    end

    if not self.db or not self.db.enabled then
        -- Unregister any attribute drivers that might show the frame
        UnregisterAttributeDriver(self.frame, "state-visibility")
        UnregisterStateDriver(self.frame, "page")
        self.frame:Hide()
        return
    end

    -- Update all aspects
    self:PositionButtons()
    self:UpdateBarSize()
    self:SetupVisibility()
    self:SetupPaging()
    self:SetupMouseover()
    self:PositionBar()

    -- Update all buttons
    local LTAB = E.Libs.LibTotalActionButtons
    for _, button in ipairs(self.buttons) do
        if button and LTAB then
            -- Update button size using LibTotalActionButtons
            LTAB:SetButtonSize(button, self.db.buttonSize, self.db.buttonHeight or self.db.buttonSize)

            -- Update button config via LibTotalActionButtons
            LTAB:UpdateConfig(button, self:BuildButtonConfig())

            -- Additional styling
            self:StyleButton(button)

            -- Force visual update to apply new config (e.g., desaturation changes)
            LTAB:UpdateUsable(button)
        end
    end

    -- Show/hide frame
    if self.db.enabled then
        self.frame:Show()
    else
        self.frame:Hide()
    end
end

-----------------------------------
-- CLEANUP
-----------------------------------

function ActionBar:Destroy()
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
ns.ActionBar = ActionBar
