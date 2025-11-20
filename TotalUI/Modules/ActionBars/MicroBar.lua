--[[
    TotalUI - MicroBar Class
    Handles creation and management of the micro menu buttons (system buttons).

    Micro buttons include:
    - Character Info
    - Spellbook & Abilities
    - Talent Tree
    - Achievement
    - Quest Log
    - Guild
    - LFD (Dungeon Finder)
    - Collections (Mounts, Pets, Toys, Heirlooms)
    - Adventure Guide
    - EJ (Encounter Journal)
    - Store
    - Main Menu
    - Bags (sometimes included)
--]]

local AddonName, ns = ...
local E = ns.public

-- Create MicroBar class
local MicroBar = {}
MicroBar.__index = MicroBar

-- Micro button names in order (as they appear in Blizzard UI)
local MICRO_BUTTONS = {
    "CharacterMicroButton",
    "SpellbookMicroButton",
    "TalentMicroButton",
    "AchievementMicroButton",
    "QuestLogMicroButton",
    "GuildMicroButton",
    "LFDMicroButton",
    "CollectionsMicroButton",
    "EJMicroButton",
    "StoreMicroButton",
    "MainMenuMicroButton",
}

-----------------------------------
-- CONSTRUCTOR
-----------------------------------

function MicroBar:New(parent)
    local bar = setmetatable({}, MicroBar)

    bar.parent = parent
    bar.buttons = {}
    bar.db = E.db.actionbar.microbar

    if not bar.db then
        error("MicroBar: No configuration found in database")
        return nil
    end

    bar:Create()

    return bar
end

-----------------------------------
-- FRAME CREATION
-----------------------------------

function MicroBar:Create()
    -- Create main bar frame
    local frameName = "TotalUI_MicroBar"
    self.frame = CreateFrame("Frame", frameName, self.parent or UIParent)
    self.frame:SetFrameStrata("LOW")
    self.frame:SetFrameLevel(5)

    -- Store reference
    self.frame.bar = self

    -- Create backdrop if enabled
    if self.db.backdrop then
        E:CreateBackdrop(self.frame)
    end

    -- Hook and style existing micro buttons
    self:HookMicroButtons()

    -- Initial setup
    self:PositionButtons()
    self:UpdateBarSize()
    self:SetupMouseover()
    self:PositionBar()
end

-----------------------------------
-- MICRO BUTTON HANDLING
-----------------------------------

function MicroBar:HookMicroButtons()
    -- We don't create new buttons, we hook the existing Blizzard micro buttons
    -- and reparent them to our frame for better control

    for i, buttonName in ipairs(MICRO_BUTTONS) do
        local button = _G[buttonName]
        if button then
            -- Store reference
            self.buttons[i] = button

            -- Reparent to our frame
            button:SetParent(self.frame)

            -- Style the button
            self:StyleButton(button, i)

            -- Store original show/hide functions so we can restore them later
            if not button._totalui_originalShow then
                button._totalui_originalShow = button.Show
                button._totalui_originalHide = button.Hide
            end
        else
            E:Print(string.format("MicroBar: Warning - %s not found", buttonName))
        end
    end
end

-----------------------------------
-- BUTTON STYLING
-----------------------------------

function MicroBar:StyleButton(button, buttonID)
    if not button then return end

    -- Clear any existing points
    button:ClearAllPoints()

    -- Set size (Blizzard micro buttons have specific textures, so we try to maintain aspect ratio)
    -- Default Blizzard micro buttons are 28x36, we'll use buttonSize for width
    local width = self.db.buttonSize
    local height = self.db.buttonHeight or (self.db.buttonSize * 1.8) -- Maintain aspect ratio

    button:SetSize(width, height)

    -- Hide any default backgrounds/borders we don't want
    if button.Background then
        button.Background:SetAlpha(0)
    end

    -- Ensure textures scale properly
    local texture = button:GetNormalTexture()
    if texture then
        texture:SetTexCoord(0.2, 0.8, 0.08, 0.92) -- Crop edges for cleaner look
    end

    local pushedTexture = button:GetPushedTexture()
    if pushedTexture then
        pushedTexture:SetTexCoord(0.2, 0.8, 0.08, 0.92)
    end

    local highlightTexture = button:GetHighlightTexture()
    if highlightTexture then
        highlightTexture:SetTexCoord(0.2, 0.8, 0.08, 0.92)
    end
end

-----------------------------------
-- POSITIONING
-----------------------------------

function MicroBar:PositionButtons()
    local db = self.db
    local spacing = db.buttonSpacing
    local backdropSpacing = db.backdropSpacing

    local buttonWidth = db.buttonSize
    local buttonHeight = db.buttonHeight or (db.buttonSize * 1.8)

    for i = 1, #self.buttons do
        local button = self.buttons[i]
        if button then
            button:ClearAllPoints()

            -- Micro buttons are typically laid out horizontally in a single row
            local xOffset = backdropSpacing + ((i - 1) * (buttonWidth + spacing))
            local yOffset = -backdropSpacing

            button:SetPoint("TOPLEFT", self.frame, "TOPLEFT", xOffset, yOffset)
        end
    end
end

function MicroBar:UpdateBarSize()
    local db = self.db
    local numButtons = #self.buttons

    local buttonWidth = db.buttonSize
    local buttonHeight = db.buttonHeight or (db.buttonSize * 1.8)

    local width = (numButtons * buttonWidth) + ((numButtons - 1) * db.buttonSpacing) + (db.backdropSpacing * 2)
    local height = buttonHeight + (db.backdropSpacing * 2)

    self.frame:SetSize(width, height)
end

function MicroBar:PositionBar()
    local db = self.db

    self.frame:ClearAllPoints()
    self.frame:SetPoint(db.point or "TOPRIGHT", UIParent, db.point or "TOPRIGHT", db.xOffset or -4, db.yOffset or -4)
end

-----------------------------------
-- MOUSEOVER FADE
-----------------------------------

function MicroBar:SetupMouseover()
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
            -- Store original scripts
            if not button._totalui_originalOnEnter then
                button._totalui_originalOnEnter = button:GetScript("OnEnter")
                button._totalui_originalOnLeave = button:GetScript("OnLeave")
            end

            -- Set new scripts that trigger bar fade and original functionality
            button:SetScript("OnEnter", function(btn)
                self.frame:GetScript("OnEnter")(self.frame)
                if button._totalui_originalOnEnter then
                    button._totalui_originalOnEnter(btn)
                end
            end)
            button:SetScript("OnLeave", function(btn)
                self.frame:GetScript("OnLeave")(self.frame)
                if button._totalui_originalOnLeave then
                    button._totalui_originalOnLeave(btn)
                end
            end)
        end
    end
end

-----------------------------------
-- UPDATE
-----------------------------------

function MicroBar:Update()
    -- Check combat (micro buttons are not combat restricted, but repositioning frames is)
    if InCombatLockdown() then
        E:QueueAfterCombat(function()
            self:Update()
        end)
        E:Print("MicroBar: Changes will apply after combat")
        return
    end

    -- Update configuration reference
    self.db = E.db.actionbar.microbar

    -- Check if ActionBars module is globally disabled
    if not E.db.actionbar.enable then
        self:Hide()
        return
    end

    if not self.db or not self.db.enabled then
        self:Hide()
        return
    end

    -- Re-style all buttons (in case size changed)
    for i, button in ipairs(self.buttons) do
        if button then
            self:StyleButton(button, i)
        end
    end

    -- Update positioning
    self:PositionButtons()
    self:UpdateBarSize()
    self:SetupMouseover()
    self:PositionBar()

    -- Show frame
    self:Show()
end

-----------------------------------
-- SHOW/HIDE
-----------------------------------

function MicroBar:Show()
    self.frame:Show()

    -- Show all buttons
    for _, button in ipairs(self.buttons) do
        if button and button._totalui_originalShow then
            button._totalui_originalShow(button)
        elseif button then
            button:Show()
        end
    end
end

function MicroBar:Hide()
    self.frame:Hide()

    -- Optionally hide buttons (or leave them visible but move them offscreen)
    -- For now, we'll keep them visible so other addons can still access them
end

-----------------------------------
-- CLEANUP
-----------------------------------

function MicroBar:Destroy()
    -- Restore original parents and scripts for all buttons
    for _, button in ipairs(self.buttons) do
        if button then
            -- Restore parent to Blizzard default
            button:SetParent(UIParent)

            -- Restore original show/hide functions
            if button._totalui_originalShow then
                button.Show = button._totalui_originalShow
                button._totalui_originalShow = nil
            end
            if button._totalui_originalHide then
                button.Hide = button._totalui_originalHide
                button._totalui_originalHide = nil
            end

            -- Restore original OnEnter/OnLeave scripts
            if button._totalui_originalOnEnter then
                button:SetScript("OnEnter", button._totalui_originalOnEnter)
                button._totalui_originalOnEnter = nil
            end
            if button._totalui_originalOnLeave then
                button:SetScript("OnLeave", button._totalui_originalOnLeave)
                button._totalui_originalOnLeave = nil
            end
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
ns.MicroBar = MicroBar
