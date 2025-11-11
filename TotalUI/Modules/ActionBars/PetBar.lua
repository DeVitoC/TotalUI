--[[
    TotalUI - PetBar Class
    Handles creation and management of the pet action bar.
--]]

local AddonName, ns = ...
local E = ns.public

-- Create PetBar class
local PetBar = {}
PetBar.__index = PetBar

-----------------------------------
-- CONSTRUCTOR
-----------------------------------

function PetBar:New(parent)
    local bar = setmetatable({}, PetBar)

    bar.parent = parent
    bar.buttons = {}
    bar.db = E.db.actionbar.barPet

    if not bar.db then
        error("PetBar: No configuration found in database")
        return nil
    end

    bar:Create()

    return bar
end

-----------------------------------
-- FRAME CREATION
-----------------------------------

function PetBar:Create()
    -- Create main bar frame (secure for combat safety)
    local frameName = "TotalUI_PetBar"
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

function PetBar:CreateButtons()
    -- Check if LibTotalActionButtons is available
    local LTAB = E.Libs.LibTotalActionButtons

    if not LTAB then
        E:Print("PetBar: LibTotalActionButtons not available, buttons will not function correctly")
        return
    end

    -- Create pet action buttons
    for i = 1, self.db.buttons do
        local button = self:CreateButton(i, LTAB)
        if button then
            self.buttons[i] = button
        end
    end
end

function PetBar:CreateButton(buttonID, LTAB)
    -- Pet action IDs are special:
    -- They use PET_ACTION_* constants and range from 1-10
    -- We don't need to calculate offset like regular action bars
    local petActionID = buttonID

    -- Create button name
    local buttonName = string.format("TotalUI_PetBarButton%d", buttonID)

    -- Build config for LibTotalActionButtons
    local config = self:BuildButtonConfig()

    -- Create button using LibTotalActionButtons
    -- For pet buttons, we need to set the type to "PET" and action to the pet action slot
    local button = LTAB:CreateButton(petActionID, buttonName, self.frame, config)

    if not button then
        E:Print(string.format("PetBar Button %d: Failed to create", buttonID))
        return nil
    end

    -- Set the button type to PET
    -- This tells LibTotalActionButtons to use pet action APIs instead of regular action APIs
    LTAB:SetButtonType(button, LTAB.ButtonType.PET, petActionID)

    -- Set size using LibTotalActionButtons (properly resizes all button elements)
    LTAB:SetButtonSize(button, self.db.buttonSize, self.db.buttonHeight or self.db.buttonSize)

    -- Additional styling
    self:StyleButton(button, buttonID)

    return button
end

-----------------------------------
-- BUTTON CONFIG
-----------------------------------

function PetBar:BuildButtonConfig()
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
        colors = {
            range = colorToArray(globalDB.noRangeColor),
            mana = colorToArray(globalDB.noPowerColor),
            unusable = colorToArray(globalDB.notUsableColor),
        },
        hideElements = {
            equipped = true,  -- Pet abilities don't show equipped status
            hotkey = not db.hotkeytext,
            macro = true,  -- Pet buttons don't have macro names
        },
        keyBoundTarget = false, -- We handle keybinds
        outOfRangeColoring = "button",
        outOfManaColoring = "button",
        text = {
            hotkey = {
                font = E.LSM:Fetch("font", db.hotkeyFont or E.db.general.font),
                size = db.hotkeyFontSize or 10,
                flags = db.hotkeyFontOutline or "OUTLINE",
                color = db.hotkeyColor and colorToArray(db.hotkeyColor) or {1, 1, 1},
                position = {
                    anchor = "TOPRIGHT",
                    relAnchor = "TOPRIGHT",
                    offsetX = 0,
                    offsetY = 0,
                },
            },
            count = {
                font = E.LSM:Fetch("font", db.countFont or E.db.general.font),
                size = db.countFontSize or 12,
                flags = db.countFontOutline or "OUTLINE",
                color = db.countColor and colorToArray(db.countColor) or {1, 1, 1},
                position = {
                    anchor = "BOTTOMRIGHT",
                    relAnchor = "BOTTOMRIGHT",
                    offsetX = 0,
                    offsetY = 2,
                },
            },
        },
    }
end

-----------------------------------
-- BUTTON STYLING
-----------------------------------

function PetBar:StyleButton(button, buttonID)
    -- LibTotalActionButtons handles most styling
    -- This function is for any bar-specific customization

    -- Ensure border is visible and styled correctly
    local border = button._border or button.Border or _G[button:GetName() .. "Border"]
    if border then
        border:SetTexture([[Interface\Buttons\UI-ActionButton-Border]])
        border:SetBlendMode("ADD")
    end
end

-----------------------------------
-- POSITIONING
-----------------------------------

function PetBar:PositionButtons()
    local db = self.db
    local buttonsPerRow = db.buttonsPerRow
    local spacing = db.buttonSpacing
    local backdropSpacing = db.backdropSpacing

    -- Use configured button size
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

function PetBar:UpdateBarSize()
    local db = self.db
    local numRows = math.ceil(db.buttons / db.buttonsPerRow)
    local numCols = math.min(db.buttons, db.buttonsPerRow)

    -- Use configured button size
    local buttonWidth = db.buttonSize
    local buttonHeight = db.buttonHeight or db.buttonSize

    local width = (numCols * buttonWidth) + ((numCols - 1) * db.buttonSpacing) + (db.backdropSpacing * 2)
    local height = (numRows * buttonHeight) + ((numRows - 1) * db.buttonSpacing) + (db.backdropSpacing * 2)

    self.frame:SetSize(width, height)
end

function PetBar:PositionBar()
    local db = self.db

    self.frame:ClearAllPoints()
    self.frame:SetPoint(db.point or "BOTTOM", UIParent, db.point or "BOTTOM", db.xOffset or 0, db.yOffset or 112)
end

-----------------------------------
-- VISIBILITY
-----------------------------------

function PetBar:SetupVisibility()
    -- Pet bar should show when player has a pet
    -- Hide during pet battles, vehicles, and override bars
    local visibilityMacro = "[petbattle][overridebar][vehicleui][possessbar] hide; [pet] show; hide"

    -- Use secure attribute driver for visibility
    RegisterAttributeDriver(self.frame, "state-visibility", visibilityMacro)
end

-----------------------------------
-- MOUSEOVER FADE
-----------------------------------

function PetBar:SetupMouseover()
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

function PetBar:RegisterEvents()
    -- PetBar needs to update when pet state changes
    if not self.eventFrame then
        self.eventFrame = CreateFrame("Frame")
    end

    self.eventFrame:RegisterEvent("UNIT_PET")
    self.eventFrame:RegisterEvent("PLAYER_CONTROL_LOST")
    self.eventFrame:RegisterEvent("PLAYER_CONTROL_GAINED")
    self.eventFrame:RegisterEvent("PLAYER_FARSIGHT_FOCUS_CHANGED")
    self.eventFrame:RegisterEvent("PET_BAR_UPDATE")
    self.eventFrame:RegisterEvent("PET_BAR_UPDATE_COOLDOWN")

    self.eventFrame:SetScript("OnEvent", function(_, event, ...)
        if event == "UNIT_PET" then
            local unit = ...
            if unit == "player" then
                self:OnPetChanged()
            end
        elseif event == "PET_BAR_UPDATE" or event == "PET_BAR_UPDATE_COOLDOWN" then
            self:UpdateButtons()
        elseif event == "PLAYER_CONTROL_LOST" or event == "PLAYER_CONTROL_GAINED" or event == "PLAYER_FARSIGHT_FOCUS_CHANGED" then
            self:UpdateVisibility()
        end
    end)
end

function PetBar:OnPetChanged()
    -- Pet summoned or dismissed
    self:UpdateButtons()
    self:UpdateVisibility()
end

function PetBar:UpdateVisibility()
    -- Visibility is handled by the attribute driver
    -- This function is for any additional logic needed
end

function PetBar:UpdateButtons()
    -- Update all buttons
    local LTAB = E.Libs.LibTotalActionButtons
    if not LTAB then return end

    for _, button in ipairs(self.buttons) do
        if button then
            LTAB:UpdateButton(button)
        end
    end
end

-----------------------------------
-- UPDATE
-----------------------------------

function PetBar:Update()
    -- Check combat
    if InCombatLockdown() then
        E:QueueAfterCombat(function()
            self:Update()
        end)
        E:Print("PetBar: Changes will apply after combat")
        return
    end

    -- Update configuration reference
    self.db = E.db.actionbar.barPet

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
    local LTAB = E.Libs.LibTotalActionButtons
    for _, button in ipairs(self.buttons) do
        if button and LTAB then
            -- Update button size using LibTotalActionButtons
            LTAB:SetButtonSize(button, self.db.buttonSize, self.db.buttonHeight or self.db.buttonSize)

            -- Update button config via LibTotalActionButtons
            LTAB:UpdateConfig(button, self:BuildButtonConfig())

            -- Additional styling
            self:StyleButton(button)
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

function PetBar:Destroy()
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
ns.PetBar = PetBar
