--[[
    TotalUI_Options - Comprehensive Config GUI
    Professional multi-category configuration interface
--]]

local AddonName, ns = ...
local E = ns.E

-- Create ConfigGUI module
local ConfigGUI = {}
E.ConfigGUI = ConfigGUI

-- GUI state
local configFrame = nil
local currentCategory = "ActionBars"
local currentTab = "Global"
local currentBar = nil  -- Current selected bar in nested navigation
local queuedUpdates = {}

-----------------------------------
-- COMBAT QUEUE HANDLING
-----------------------------------

local function QueueUpdate(updateFunc)
    table.insert(queuedUpdates, updateFunc)
end

local function ProcessQueuedUpdates()
    if #queuedUpdates == 0 then return end
    print("|cff1784d1TotalUI|r Applying queued setting changes...")
    for _, updateFunc in ipairs(queuedUpdates) do
        updateFunc()
    end
    queuedUpdates = {}
end

-- Combat event handler
local combatFrame = CreateFrame("Frame")
combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
combatFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_ENABLED" then
        ProcessQueuedUpdates()
    end
end)

-----------------------------------
-- CATEGORY DEFINITIONS
-----------------------------------

local categories = {
    {id = "General", name = "General", icon = "Interface\\Icons\\INV_Misc_Gear_01"},
    {id = "ActionBars", name = "ActionBars", icon = "Interface\\Icons\\INV_Misc_GroupLooking"},
    {id = "UnitFrames", name = "UnitFrames", icon = "Interface\\Icons\\Achievement_BG_returnXflags_def_WSG", disabled = true},
    {id = "Nameplates", name = "Nameplates", icon = "Interface\\Icons\\Achievement_BG_kill_flag_carrier", disabled = true},
    {id = "Bags", name = "Bags", icon = "Interface\\Icons\\INV_Misc_Bag_08", disabled = true},
    {id = "Chat", name = "Chat", icon = "Interface\\Icons\\Ability_Warrior_RallyingCry", disabled = true},
}

-- ActionBars tabs (top level)
local actionBarTabs = {
    "Global",
    "ActionBars 1-15",
    "Special Action Bars"
}

-- Secondary navigation for ActionBars 1-15
local regularBarsList = {
    "Bar 1", "Bar 2", "Bar 3", "Bar 4", "Bar 5",
    "Bar 6", "Bar 7", "Bar 8", "Bar 9", "Bar 10",
    "Bar 11", "Bar 12", "Bar 13", "Bar 14", "Bar 15"
}

-- Secondary navigation for Special Action Bars
local specialBarsList = {
    "Pet Bar", "Stance Bar", "Micro Bar", "Extra Buttons"
}

-----------------------------------
-- WIDGET CREATION HELPERS
-----------------------------------

local function CreateCheckbox(parent, label, tooltip, getValue, setValue)
    local checkbox = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    checkbox:SetSize(24, 24)

    local text = checkbox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    text:SetPoint("LEFT", checkbox, "RIGHT", 5, 1)
    text:SetText(label)

    checkbox:SetChecked(getValue())

    if tooltip then
        checkbox:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(label, 1, 1, 1)
            GameTooltip:AddLine(tooltip, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        checkbox:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    checkbox:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        local updateFunc = function() setValue(checked) end

        if InCombatLockdown() then
            QueueUpdate(updateFunc)
            print("|cff1784d1TotalUI|r Setting queued (in combat)")
        else
            updateFunc()
        end

        PlaySound(checked and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
    end)

    return checkbox
end

local function CreateSlider(parent, label, min, max, step, getValue, setValue, tooltip)
    local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    slider:SetSize(200, 20)
    slider:SetMinMaxValues(min, max)
    slider:SetValueStep(step)
    slider:SetValue(getValue())
    slider:SetObeyStepOnDrag(true)

    -- Label
    local labelText = slider:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    labelText:SetPoint("BOTTOMLEFT", slider, "TOPLEFT", 0, 2)
    labelText:SetText(label)

    -- Value display
    local valueText = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    valueText:SetPoint("BOTTOMRIGHT", slider, "TOPRIGHT", 0, 2)
    valueText:SetText(getValue())

    slider:SetScript("OnValueChanged", function(self, value)
        value = floor(value / step + 0.5) * step
        valueText:SetText(value)

        local updateFunc = function() setValue(value) end

        if InCombatLockdown() then
            QueueUpdate(updateFunc)
        else
            updateFunc()
        end
    end)

    if tooltip then
        slider:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(label, 1, 1, 1)
            GameTooltip:AddLine(tooltip, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        slider:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    return slider
end

local function CreateDropdown(parent, label, options, getValue, setValue, tooltip)
    local dropdown = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    dropdown:SetSize(200, 40)

    -- Label
    local labelText = dropdown:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    labelText:SetPoint("BOTTOMLEFT", dropdown, "TOPLEFT", 0, 2)
    labelText:SetText(label)

    UIDropDownMenu_SetWidth(dropdown, 150)
    UIDropDownMenu_SetText(dropdown, getValue())

    UIDropDownMenu_Initialize(dropdown, function(self, level)
        for _, option in ipairs(options) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option
            info.func = function()
                local updateFunc = function() setValue(option) end
                if InCombatLockdown() then
                    QueueUpdate(updateFunc)
                else
                    updateFunc()
                end
                UIDropDownMenu_SetText(dropdown, option)
            end
            info.checked = (getValue() == option)
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    if tooltip then
        dropdown:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(label, 1, 1, 1)
            GameTooltip:AddLine(tooltip, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        dropdown:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    return dropdown
end

local function CreateColorPicker(parent, label, getColor, setColor, tooltip, hasAlpha)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(40, 20)

    -- Label
    local labelText = button:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    labelText:SetPoint("RIGHT", button, "LEFT", -5, 0)
    labelText:SetText(label)

    -- Color swatch background
    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 1)

    -- Color swatch
    local swatch = button:CreateTexture(nil, "ARTWORK")
    swatch:SetSize(36, 16)
    swatch:SetPoint("CENTER")

    local function UpdateColor()
        local color = getColor()
        if hasAlpha then
            swatch:SetColorTexture(color.r, color.g, color.b, color.a or 1)
        else
            swatch:SetColorTexture(color.r, color.g, color.b, 1)
        end
    end
    UpdateColor()

    button:SetScript("OnClick", function()
        local color = getColor()
        local r, g, b, a = color.r, color.g, color.b, color.a or 1

        local function OnColorSelect(restore)
            local newR, newG, newB, newA
            if restore then
                newR, newG, newB, newA = r, g, b, a
            else
                newR, newG, newB = ColorPickerFrame:GetColorRGB()
                if hasAlpha then
                    newA = ColorPickerFrame:GetColorAlpha()
                end
            end

            local updateFunc = function()
                local newColor = hasAlpha and {r = newR, g = newG, b = newB, a = newA} or {r = newR, g = newG, b = newB}
                setColor(newColor)
                UpdateColor()
            end

            if InCombatLockdown() then
                QueueUpdate(updateFunc)
            else
                updateFunc()
            end
        end

        ColorPickerFrame:SetupColorPickerAndShow({
            r = r, g = g, b = b,
            opacity = hasAlpha and a or nil,
            hasOpacity = hasAlpha,
            swatchFunc = OnColorSelect,
            opacityFunc = OnColorSelect,
            cancelFunc = OnColorSelect,
        })
    end)

    if tooltip then
        button:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(label, 1, 1, 1)
            GameTooltip:AddLine(tooltip, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    return button
end

local function CreateSectionHeader(parent, text, yOffset, xOffset)
    local header = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", xOffset or 10, yOffset)
    header:SetText("|cff1784d1" .. text .. "|r")
    return header
end

-----------------------------------
-- CONTENT PANELS
-----------------------------------

local function CreateGlobalActionBarsPanel(parent)
    local yOffsetLeft = -10
    local yOffsetRight = -10
    local content = parent
    local db = E.db.actionbar
    local leftX = 10
    local rightX = 435  -- Right column starts at 435px

    -- Note: No main header needed - tab name "Global" indicates this is global settings

    -- Enable ActionBars (left column)
    local enableCB = CreateCheckbox(content, "Enable ActionBars", "Enable or disable the TotalUI ActionBars module",
        function() return db.enable end,
        function(value)
            db.enable = value
            if E.modules.ActionBars then E.modules.ActionBars:Update() end
        end)
    enableCB:SetPoint("TOPLEFT", leftX, yOffsetLeft)
    yOffsetLeft = yOffsetLeft - 30

    -- Preserve Default Appearance (TotalUI-specific)
    local preserveCB = CreateCheckbox(content, "Preserve Default Appearance", "Keep default WoW actionbar appearance while enabling behavioral enhancements",
        function() return db.preserveDefaultAppearance end,
        function(value)
            db.preserveDefaultAppearance = value
            if E.modules.ActionBars then E.modules.ActionBars:Update() end
        end)
    preserveCB:SetPoint("TOPLEFT", leftX, yOffsetLeft)
    yOffsetLeft = yOffsetLeft - 30

    -- Lock ActionBars (left column)
    local lockCB = CreateCheckbox(content, "Lock ActionBars", "Prevent action bars from being moved",
        function() return db.lockActionBars end,
        function(value) db.lockActionBars = value end)
    lockCB:SetPoint("TOPLEFT", leftX, yOffsetLeft)
    yOffsetLeft = yOffsetLeft - 40

    -----------------------------------
    -- APPEARANCE SECTION (Left Column)
    -----------------------------------
    CreateSectionHeader(content, "Appearance", yOffsetLeft)
    yOffsetLeft = yOffsetLeft - 40

    -- Global Fade Alpha
    local fadeSlider = CreateSlider(content, "Global Fade Alpha", 0, 1, 0.05,
        function() return db.globalFadeAlpha end,
        function(value)
            db.globalFadeAlpha = value
            if E.modules.ActionBars then E.modules.ActionBars:Update() end
        end,
        "Alpha transparency for faded action bars")
    fadeSlider:SetPoint("TOPLEFT", leftX, yOffsetLeft)
    yOffsetLeft = yOffsetLeft - 50

    -- Transparent Buttons
    local transparentCB = CreateCheckbox(content, "Transparent Buttons", "Make button backgrounds transparent",
        function() return db.transparent end,
        function(value)
            db.transparent = value
            if E.modules.ActionBars then E.modules.ActionBars:Update() end
        end)
    transparentCB:SetPoint("TOPLEFT", leftX, yOffsetLeft)
    yOffsetLeft = yOffsetLeft - 30

    -- Transparent Backdrops
    local transBackdropCB = CreateCheckbox(content, "Transparent Backdrops", "Make bar backdrops transparent",
        function() return db.transparentBackdrops end,
        function(value)
            db.transparentBackdrops = value
            if E.modules.ActionBars then E.modules.ActionBars:Update() end
        end)
    transBackdropCB:SetPoint("TOPLEFT", leftX, yOffsetLeft)
    yOffsetLeft = yOffsetLeft - 30

    -- Handle Overlay
    local handleOverlayCB = CreateCheckbox(content, "Handle Overlay", "Show handle overlay on buttons",
        function() return db.handleOverlay end,
        function(value)
            db.handleOverlay = value
            if E.modules.ActionBars then E.modules.ActionBars:Update() end
        end)
    handleOverlayCB:SetPoint("TOPLEFT", leftX, yOffsetLeft)
    yOffsetLeft = yOffsetLeft - 30

    -- Equipped Item Highlight
    local equippedCB = CreateCheckbox(content, "Equipped Item Highlight", "Highlight equipped items on action bars",
        function() return db.equippedItem end,
        function(value)
            db.equippedItem = value
            if E.modules.ActionBars then E.modules.ActionBars:Update() end
        end)
    equippedCB:SetPoint("TOPLEFT", leftX, yOffsetLeft)
    yOffsetLeft = yOffsetLeft - 30

    -- Equipped Item Color (slightly indented as sub-setting)
    local equippedColorLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    equippedColorLabel:SetPoint("TOPLEFT", leftX + 20, yOffsetLeft)
    equippedColorLabel:SetText("Equipped Item Color")
    local equippedColor = CreateColorPicker(content, "",
        function() return db.equippedItemColor end,
        function(value)
            db.equippedItemColor = value
            if E.modules.ActionBars then E.modules.ActionBars:Update() end
        end,
        "Color for equipped item highlights")
    equippedColor:SetPoint("TOPLEFT", leftX + 170, yOffsetLeft - 2)
    yOffsetLeft = yOffsetLeft - 40

    -----------------------------------
    -- COOLDOWN SECTION (Left Column)
    -----------------------------------
    CreateSectionHeader(content, "Cooldowns", yOffsetLeft)
    yOffsetLeft = yOffsetLeft - 30

    -- Desaturate on Cooldown
    local desaturateCB = CreateCheckbox(content, "Desaturate on Cooldown", "Desaturate button icons when on cooldown",
        function() return db.desaturateOnCooldown end,
        function(value)
            db.desaturateOnCooldown = value
            if E.modules.ActionBars and E.modules.ActionBars.cooldown then
                E.modules.ActionBars.cooldown:Update()
            end
        end)
    desaturateCB:SetPoint("TOPLEFT", leftX, yOffsetLeft)
    yOffsetLeft = yOffsetLeft - 30

    -- Hide Cooldown Bling
    local blingCB = CreateCheckbox(content, "Hide Cooldown Bling", "Hide the flash animation when cooldowns complete",
        function() return db.hideCooldownBling end,
        function(value)
            db.hideCooldownBling = value
            if E.modules.ActionBars and E.modules.ActionBars.cooldown then
                E.modules.ActionBars.cooldown:Update()
            end
        end)
    blingCB:SetPoint("TOPLEFT", leftX, yOffsetLeft)
    yOffsetLeft = yOffsetLeft - 30

    -- Flash Animation
    local flashCB = CreateCheckbox(content, "Flash Animation", "Show flash animation on button state changes",
        function() return db.flashAnimation end,
        function(value)
            db.flashAnimation = value
            if E.modules.ActionBars then E.modules.ActionBars:Update() end
        end)
    flashCB:SetPoint("TOPLEFT", leftX, yOffsetLeft)
    yOffsetLeft = yOffsetLeft - 30

    -- Charge Cooldown
    local chargeCB = CreateCheckbox(content, "Charge Cooldown", "Show cooldown for charge-based abilities",
        function() return db.chargeCooldown end,
        function(value)
            db.chargeCooldown = value
            if E.modules.ActionBars and E.modules.ActionBars.cooldown then
                E.modules.ActionBars.cooldown:Update()
            end
        end)
    chargeCB:SetPoint("TOPLEFT", leftX, yOffsetLeft)
    yOffsetLeft = yOffsetLeft - 30

    -- Use Draw Swipe on Charges
    local drawSwipeCB = CreateCheckbox(content, "Draw Swipe on Charges", "Use swipe animation for charge cooldowns",
        function() return db.useDrawSwipeOnCharges end,
        function(value)
            db.useDrawSwipeOnCharges = value
            if E.modules.ActionBars and E.modules.ActionBars.cooldown then
                E.modules.ActionBars.cooldown:Update()
            end
        end)
    drawSwipeCB:SetPoint("TOPLEFT", leftX, yOffsetLeft)
    yOffsetLeft = yOffsetLeft - 30

    -- Normal Swipe Color (slightly indented as sub-setting)
    local swipeNormalLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    swipeNormalLabel:SetPoint("TOPLEFT", leftX + 20, yOffsetLeft)
    swipeNormalLabel:SetText("Swipe Color (Normal)")
    local swipeColor = CreateColorPicker(content, "",
        function() return db.colorSwipeNormal end,
        function(value)
            db.colorSwipeNormal = value
            if E.modules.ActionBars and E.modules.ActionBars.cooldown then
                E.modules.ActionBars.cooldown:Update()
            end
        end,
        "Color of cooldown swipe animation", true)
    swipeColor:SetPoint("TOPLEFT", leftX + 170, yOffsetLeft - 2)
    yOffsetLeft = yOffsetLeft - 30

    -- LOC Swipe Color (slightly indented as sub-setting)
    local swipeLOCLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    swipeLOCLabel:SetPoint("TOPLEFT", leftX + 20, yOffsetLeft)
    swipeLOCLabel:SetText("Swipe Color (LOC)")
    local locSwipeColor = CreateColorPicker(content, "",
        function() return db.colorSwipeLOC end,
        function(value)
            db.colorSwipeLOC = value
            if E.modules.ActionBars and E.modules.ActionBars.cooldown then
                E.modules.ActionBars.cooldown:Update()
            end
        end,
        "Color of loss of control cooldown swipe")
    locSwipeColor:SetPoint("TOPLEFT", leftX + 170, yOffsetLeft - 2)
    yOffsetLeft = yOffsetLeft - 40

    -----------------------------------
    -- BUTTON COLORS SECTION (Left Column)
    -----------------------------------
    CreateSectionHeader(content, "Button Colors", yOffsetLeft)
    yOffsetLeft = yOffsetLeft - 30

    -- No Range Color
    local noRangeLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    noRangeLabel:SetPoint("TOPLEFT", leftX, yOffsetLeft)
    noRangeLabel:SetText("Out of Range")
    local noRangeColor = CreateColorPicker(content, "",
        function() return db.noRangeColor end,
        function(value)
            db.noRangeColor = value
            if E.modules.ActionBars then E.modules.ActionBars:Update() end
        end,
        "Button color when target is out of range")
    noRangeColor:SetPoint("TOPLEFT", leftX + 150, yOffsetLeft - 2)
    yOffsetLeft = yOffsetLeft - 30

    -- No Power Color
    local noPowerLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    noPowerLabel:SetPoint("TOPLEFT", leftX, yOffsetLeft)
    noPowerLabel:SetText("No Power")
    local noPowerColor = CreateColorPicker(content, "",
        function() return db.noPowerColor end,
        function(value)
            db.noPowerColor = value
            if E.modules.ActionBars then E.modules.ActionBars:Update() end
        end,
        "Button color when not enough power/mana")
    noPowerColor:SetPoint("TOPLEFT", leftX + 150, yOffsetLeft - 2)
    yOffsetLeft = yOffsetLeft - 30

    -- Not Usable Color
    local notUsableLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    notUsableLabel:SetPoint("TOPLEFT", leftX, yOffsetLeft)
    notUsableLabel:SetText("Not Usable")
    local notUsableColor = CreateColorPicker(content, "",
        function() return db.notUsableColor end,
        function(value)
            db.notUsableColor = value
            if E.modules.ActionBars then E.modules.ActionBars:Update() end
        end,
        "Button color when ability is not usable")
    notUsableColor:SetPoint("TOPLEFT", leftX + 150, yOffsetLeft - 2)
    yOffsetLeft = yOffsetLeft - 30

    -- Usable Color
    local usableLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    usableLabel:SetPoint("TOPLEFT", leftX, yOffsetLeft)
    usableLabel:SetText("Usable")
    local usableColor = CreateColorPicker(content, "",
        function() return db.usableColor end,
        function(value)
            db.usableColor = value
            if E.modules.ActionBars then E.modules.ActionBars:Update() end
        end,
        "Button color when ability is usable")
    usableColor:SetPoint("TOPLEFT", leftX + 150, yOffsetLeft - 2)
    yOffsetLeft = yOffsetLeft - 30

    -- Use Range Color on Text
    local rangeTextCB = CreateCheckbox(content, "Apply Range Color to Text", "Apply range coloring to button text as well",
        function() return db.useRangeColorText end,
        function(value)
            db.useRangeColorText = value
            if E.modules.ActionBars then E.modules.ActionBars:Update() end
        end)
    rangeTextCB:SetPoint("TOPLEFT", leftX, yOffsetLeft)
    yOffsetLeft = yOffsetLeft - 40

    -----------------------------------
    -- CAST MODIFIERS SECTION (Right Column)
    -----------------------------------
    CreateSectionHeader(content, "Cast Modifiers", yOffsetRight, rightX)
    yOffsetRight = yOffsetRight - 30

    -- Check Self Cast
    local selfCastCB = CreateCheckbox(content, "Check Self Cast", "Enable self-cast detection for button coloring",
        function() return db.checkSelfCast end,
        function(value) db.checkSelfCast = value end)
    selfCastCB:SetPoint("TOPLEFT", rightX, yOffsetRight)
    yOffsetRight = yOffsetRight - 30

    -- Check Focus Cast
    local focusCastCB = CreateCheckbox(content, "Check Focus Cast", "Enable focus-cast detection for button coloring",
        function() return db.checkFocusCast end,
        function(value) db.checkFocusCast = value end)
    focusCastCB:SetPoint("TOPLEFT", rightX, yOffsetRight)
    yOffsetRight = yOffsetRight - 30

    -- Right Click Self Cast
    local rightClickCB = CreateCheckbox(content, "Right Click Self Cast", "Allow right-clicking to self-cast abilities",
        function() return db.rightClickSelfCast end,
        function(value) db.rightClickSelfCast = value end)
    rightClickCB:SetPoint("TOPLEFT", rightX, yOffsetRight)
    yOffsetRight = yOffsetRight - 40

    -----------------------------------
    -- MOVEMENT & MISC SECTION (Right Column)
    -----------------------------------
    CreateSectionHeader(content, "Movement & Misc", yOffsetRight, rightX)
    yOffsetRight = yOffsetRight - 40

    -- Movement Modifier
    local movementDD = CreateDropdown(content, "Movement Modifier", {"NONE", "SHIFT", "CTRL", "ALT"},
        function() return db.movementModifier end,
        function(value) db.movementModifier = value end,
        "Modifier key required to move unlocked bars")
    movementDD:SetPoint("TOPLEFT", rightX, yOffsetRight)
    yOffsetRight = yOffsetRight - 50

    -- Flyout Size
    local flyoutSlider = CreateSlider(content, "Flyout Button Size", 20, 60, 1,
        function() return db.flyoutSize end,
        function(value)
            db.flyoutSize = value
            if E.modules.ActionBars then E.modules.ActionBars:Update() end
        end,
        "Size of flyout menu buttons")
    flyoutSlider:SetPoint("TOPLEFT", rightX, yOffsetRight)
    yOffsetRight = yOffsetRight - 50

    -----------------------------------
    -- PROFESSION QUALITY SECTION (Right Column)
    -----------------------------------
    CreateSectionHeader(content, "Profession Quality (Retail)", yOffsetRight, rightX)
    yOffsetRight = yOffsetRight - 40

    -- Enable Profession Quality
    local profQualCB = CreateCheckbox(content, "Show Profession Quality", "Display profession quality indicators on action buttons",
        function() return db.professionQuality.enable end,
        function(value)
            db.professionQuality.enable = value
            if E.modules.ActionBars then E.modules.ActionBars:Update() end
        end)
    profQualCB:SetPoint("TOPLEFT", rightX, yOffsetRight)
    yOffsetRight = yOffsetRight - 40

    -- Profession Quality Anchor Point
    local profPointDD = CreateDropdown(content, "Quality Anchor Point",
        {"CENTER", "TOP", "BOTTOM", "LEFT", "RIGHT", "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT"},
        function() return db.professionQuality.point end,
        function(value)
            db.professionQuality.point = value
            if E.modules.ActionBars then E.modules.ActionBars:Update() end
        end,
        "Where to anchor the profession quality indicator")
    profPointDD:SetPoint("TOPLEFT", rightX, yOffsetRight)
    yOffsetRight = yOffsetRight - 50

    -- Profession Quality X Offset
    local profXSlider = CreateSlider(content, "Quality X Offset", -20, 20, 1,
        function() return db.professionQuality.xOffset end,
        function(value)
            db.professionQuality.xOffset = value
            if E.modules.ActionBars then E.modules.ActionBars:Update() end
        end,
        "Horizontal offset for quality indicator")
    profXSlider:SetPoint("TOPLEFT", rightX, yOffsetRight)
    yOffsetRight = yOffsetRight - 50

    -- Profession Quality Y Offset
    local profYSlider = CreateSlider(content, "Quality Y Offset", -20, 20, 1,
        function() return db.professionQuality.yOffset end,
        function(value)
            db.professionQuality.yOffset = value
            if E.modules.ActionBars then E.modules.ActionBars:Update() end
        end,
        "Vertical offset for quality indicator")
    profYSlider:SetPoint("TOPLEFT", rightX, yOffsetRight)
    yOffsetRight = yOffsetRight - 50

    -- Profession Quality Scale
    local profScaleSlider = CreateSlider(content, "Quality Scale", 0.5, 2, 0.1,
        function() return db.professionQuality.scale end,
        function(value)
            db.professionQuality.scale = value
            if E.modules.ActionBars then E.modules.ActionBars:Update() end
        end,
        "Size of quality indicator")
    profScaleSlider:SetPoint("TOPLEFT", rightX, yOffsetRight)
    yOffsetRight = yOffsetRight - 50

    -- Profession Quality Alpha
    local profAlphaSlider = CreateSlider(content, "Quality Alpha", 0, 1, 0.05,
        function() return db.professionQuality.alpha end,
        function(value)
            db.professionQuality.alpha = value
            if E.modules.ActionBars then E.modules.ActionBars:Update() end
        end,
        "Transparency of quality indicator")
    profAlphaSlider:SetPoint("TOPLEFT", rightX, yOffsetRight)
    yOffsetRight = yOffsetRight - 60

    -----------------------------------
    -- DEFAULT FONT SETTINGS SECTION (Right Column)
    -----------------------------------
    CreateSectionHeader(content, "Default Font Settings", yOffsetRight, rightX)
    yOffsetRight = yOffsetRight - 30

    local fontNote = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    fontNote:SetPoint("TOPLEFT", rightX, yOffsetRight)
    fontNote:SetText("|cff808080Applied to all bars unless overridden|r")
    yOffsetRight = yOffsetRight - 25

    -- Font Face
    local fontDD = CreateDropdown(content, "Font",
        {"Friz Quadrata TT", "Arial Narrow", "Skurri", "Morpheus"},
        function() return db.font end,
        function(value)
            db.font = value
            if E.modules.ActionBars then E.modules.ActionBars:Update() end
        end,
        "Default font face for action bar text")
    fontDD:SetPoint("TOPLEFT", rightX, yOffsetRight)
    yOffsetRight = yOffsetRight - 50

    -- Font Size
    local fontSizeSlider = CreateSlider(content, "Font Size", 6, 32, 1,
        function() return db.fontSize end,
        function(value)
            db.fontSize = value
            if E.modules.ActionBars then E.modules.ActionBars:Update() end
        end,
        "Default font size for action bar text")
    fontSizeSlider:SetPoint("TOPLEFT", rightX, yOffsetRight)
    yOffsetRight = yOffsetRight - 50

    -- Font Outline
    local fontOutlineDD = CreateDropdown(content, "Font Outline",
        {"NONE", "OUTLINE", "THICKOUTLINE", "MONOCHROME"},
        function() return db.fontOutline end,
        function(value)
            db.fontOutline = value
            if E.modules.ActionBars then E.modules.ActionBars:Update() end
        end,
        "Default font outline style")
    fontOutlineDD:SetPoint("TOPLEFT", rightX, yOffsetRight)
    yOffsetRight = yOffsetRight - 50

    -- Set scroll child height based on content
    local maxHeight = math.max(math.abs(yOffsetLeft), math.abs(yOffsetRight)) + 50
    content:SetHeight(maxHeight)
end

local function CreateBarPanel(parent, barID)
    local yOffset = -10
    local barKey = "bar" .. barID
    local db = E.db.actionbar[barKey]

    if not db then
        local errorText = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        errorText:SetPoint("TOPLEFT", 10, yOffset)
        errorText:SetText("|cffff0000Error: Bar " .. barID .. " configuration not found|r")
        return
    end

    -- Helper function to update this bar
    local function UpdateBar()
        if E.modules.ActionBars then
            local bar = E.modules.ActionBars:GetBar(barID)
            if bar then bar:Update() end
        end
    end

    -- Main Header
    CreateSectionHeader(parent, "Bar " .. barID .. " Settings", yOffset)
    yOffset = yOffset - 30

    -- Enable Bar
    local enableCB = CreateCheckbox(parent, "Enable Bar " .. barID, "Enable or disable this action bar",
        function() return db.enabled end,
        function(value)
            db.enabled = value
            UpdateBar()
        end)
    enableCB:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 40

    -----------------------------------
    -- BUTTON LAYOUT SECTION
    -----------------------------------
    CreateSectionHeader(parent, "Button Layout", yOffset)
    yOffset = yOffset - 40

    -- Buttons Count
    if db.buttons then
        local buttonsSlider = CreateSlider(parent, "Number of Buttons", 1, 12, 1,
            function() return db.buttons end,
            function(value)
                db.buttons = value
                UpdateBar()
            end,
            "How many buttons to show on this bar")
        buttonsSlider:SetPoint("TOPLEFT", 10, yOffset)
        yOffset = yOffset - 50
    end

    -- Buttons Per Row
    local rowSlider = CreateSlider(parent, "Buttons Per Row", 1, 12, 1,
        function() return db.buttonsPerRow end,
        function(value)
            db.buttonsPerRow = value
            UpdateBar()
        end,
        "Number of buttons per row before wrapping")
    rowSlider:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 50

    -- Button Width
    local sizeSlider = CreateSlider(parent, "Button Width", 20, 60, 1,
        function() return db.buttonSize end,
        function(value)
            db.buttonSize = value
            if db.keepSizeRatio then
                db.buttonHeight = value
            end
            UpdateBar()
        end,
        "Width of each button")
    sizeSlider:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 50

    -- Button Height
    if db.buttonHeight then
        local heightSlider = CreateSlider(parent, "Button Height", 20, 60, 1,
            function() return db.buttonHeight end,
            function(value)
                db.buttonHeight = value
                UpdateBar()
            end,
            "Height of each button")
        heightSlider:SetPoint("TOPLEFT", 10, yOffset)
        yOffset = yOffset - 50
    end

    -- Keep Size Ratio
    if db.keepSizeRatio ~= nil then
        local ratioCB = CreateCheckbox(parent, "Keep Size Ratio", "Maintain 1:1 aspect ratio for buttons",
            function() return db.keepSizeRatio end,
            function(value)
                db.keepSizeRatio = value
                if value then
                    db.buttonHeight = db.buttonSize
                end
                UpdateBar()
            end)
        ratioCB:SetPoint("TOPLEFT", 10, yOffset)
        yOffset = yOffset - 30
    end

    -- Button Spacing
    local spacingSlider = CreateSlider(parent, "Button Spacing", 0, 10, 1,
        function() return db.buttonSpacing end,
        function(value)
            db.buttonSpacing = value
            UpdateBar()
        end,
        "Space between buttons")
    spacingSlider:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 50

    -- Backdrop
    local backdropCB = CreateCheckbox(parent, "Show Backdrop", "Show background panel behind bar",
        function() return db.backdrop end,
        function(value)
            db.backdrop = value
            UpdateBar()
        end)
    backdropCB:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 30

    -- Backdrop Spacing
    if db.backdropSpacing then
        local backdropSpacingSlider = CreateSlider(parent, "Backdrop Spacing", 0, 10, 1,
            function() return db.backdropSpacing end,
            function(value)
                db.backdropSpacing = value
                UpdateBar()
            end,
            "Padding between backdrop and buttons")
        backdropSpacingSlider:SetPoint("TOPLEFT", 10, yOffset)
        yOffset = yOffset - 50
    end

    -----------------------------------
    -- VISIBILITY & ALPHA SECTION
    -----------------------------------
    CreateSectionHeader(parent, "Visibility & Alpha", yOffset)
    yOffset = yOffset - 40

    -- Alpha
    local alphaSlider = CreateSlider(parent, "Alpha", 0, 1, 0.05,
        function() return db.alpha end,
        function(value)
            db.alpha = value
            UpdateBar()
        end,
        "Transparency of the action bar")
    alphaSlider:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 50

    -- Mouseover
    local mouseoverCB = CreateCheckbox(parent, "Mouseover", "Only show at full alpha when moused over",
        function() return db.mouseover end,
        function(value)
            db.mouseover = value
            UpdateBar()
        end)
    mouseoverCB:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 30

    -- Mouseover Alpha
    if db.mouseoverAlpha then
        local mouseAlphaSlider = CreateSlider(parent, "Mouseover Alpha", 0, 1, 0.05,
            function() return db.mouseoverAlpha end,
            function(value)
                db.mouseoverAlpha = value
                UpdateBar()
            end,
            "Alpha when not moused over (if mouseover enabled)")
        mouseAlphaSlider:SetPoint("TOPLEFT", 10, yOffset)
        yOffset = yOffset - 50
    end

    -- Click Through
    if db.clickThrough ~= nil then
        local clickCB = CreateCheckbox(parent, "Click Through", "Allow clicking through bar when not in combat",
            function() return db.clickThrough end,
            function(value)
                db.clickThrough = value
                UpdateBar()
            end)
        clickCB:SetPoint("TOPLEFT", 10, yOffset)
        yOffset = yOffset - 30
    end

    -- Inherit Global Fade
    if db.inheritGlobalFade ~= nil then
        local fadeCB = CreateCheckbox(parent, "Inherit Global Fade", "Use global fade alpha setting",
            function() return db.inheritGlobalFade end,
            function(value)
                db.inheritGlobalFade = value
                UpdateBar()
            end)
        fadeCB:SetPoint("TOPLEFT", 10, yOffset)
        yOffset = yOffset - 30
    end

    -- Show Grid
    if db.showGrid ~= nil then
        local gridCB = CreateCheckbox(parent, "Show Empty Buttons", "Show empty button slots",
            function() return db.showGrid end,
            function(value)
                db.showGrid = value
                UpdateBar()
            end)
        gridCB:SetPoint("TOPLEFT", 10, yOffset)
        yOffset = yOffset - 30
    end

    -- Visibility Macro
    if db.visibility then
        local visText = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        visText:SetPoint("TOPLEFT", 10, yOffset)
        visText:SetText("Visibility Macro:")
        yOffset = yOffset - 20

        local visNote = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        visNote:SetPoint("TOPLEFT", 10, yOffset)
        visNote:SetText("|cff808080Edit visibility conditions in Profile.lua (advanced)|r")
        yOffset = yOffset - 30
    end

    -----------------------------------
    -- POSITIONING SECTION
    -----------------------------------
    CreateSectionHeader(parent, "Positioning", yOffset)
    yOffset = yOffset - 40

    -- Anchor Point (if applicable)
    if db.point then
        local pointDD = CreateDropdown(parent, "Anchor Point",
            {"CENTER", "TOP", "BOTTOM", "LEFT", "RIGHT", "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT"},
            function() return db.point end,
            function(value)
                db.point = value
                UpdateBar()
            end,
            "Where to anchor the action bar")
        pointDD:SetPoint("TOPLEFT", 10, yOffset)
        yOffset = yOffset - 50
    end

    -- X Offset
    if db.xOffset then
        local xSlider = CreateSlider(parent, "X Offset", -500, 500, 1,
            function() return db.xOffset end,
            function(value)
                db.xOffset = value
                UpdateBar()
            end,
            "Horizontal position offset")
        xSlider:SetPoint("TOPLEFT", 10, yOffset)
        yOffset = yOffset - 50
    end

    -- Y Offset
    if db.yOffset then
        local ySlider = CreateSlider(parent, "Y Offset", -500, 500, 1,
            function() return db.yOffset end,
            function(value)
                db.yOffset = value
                UpdateBar()
            end,
            "Vertical position offset")
        ySlider:SetPoint("TOPLEFT", 10, yOffset)
        yOffset = yOffset - 50
    end

    -----------------------------------
    -- BAR-SPECIFIC FEATURES
    -----------------------------------
    if db.paging ~= nil or db.targetReticle ~= nil or db.flyoutDirection then
        CreateSectionHeader(parent, "Bar Features", yOffset)
        yOffset = yOffset - 30
    end

    -- Paging (Bar 1 only)
    if db.paging ~= nil then
        local pagingCB = CreateCheckbox(parent, "Enable Paging", "Allow automatic page switching based on stance/form",
            function() return db.paging end,
            function(value)
                db.paging = value
                UpdateBar()
            end)
        pagingCB:SetPoint("TOPLEFT", 10, yOffset)
        yOffset = yOffset - 30
    end

    -- Target Reticle (Bar 1 only)
    if db.targetReticle ~= nil then
        local reticleCB = CreateCheckbox(parent, "Target Reticle", "Show targeting reticle on buttons",
            function() return db.targetReticle end,
            function(value)
                db.targetReticle = value
                UpdateBar()
            end)
        reticleCB:SetPoint("TOPLEFT", 10, yOffset)
        yOffset = yOffset - 30
    end

    -- Flyout Direction
    if db.flyoutDirection then
        local flyoutDD = CreateDropdown(parent, "Flyout Direction", {"UP", "DOWN", "LEFT", "RIGHT"},
            function() return db.flyoutDirection end,
            function(value)
                db.flyoutDirection = value
                UpdateBar()
            end,
            "Direction for flyout menus")
        flyoutDD:SetPoint("TOPLEFT", 10, yOffset)
        yOffset = yOffset - 50
    end

    -----------------------------------
    -- TEXT DISPLAY SECTION
    -----------------------------------
    CreateSectionHeader(parent, "Button Text", yOffset)
    yOffset = yOffset - 30

    -- Hotkey Text
    if db.hotkeytext ~= nil then
        local hotkeyCB = CreateCheckbox(parent, "Show Hotkey Text", "Display keybind text on buttons",
            function() return db.hotkeytext end,
            function(value)
                db.hotkeytext = value
                UpdateBar()
            end)
        hotkeyCB:SetPoint("TOPLEFT", 10, yOffset)
        yOffset = yOffset - 30

        -- Detailed hotkey customization (bar1 only)
        if db.hotkeyColor then
            local hotkeyColorPicker = CreateColorPicker(parent, "Hotkey Color",
                function() return db.hotkeyColor end,
                function(value)
                    db.hotkeyColor = value
                    UpdateBar()
                end,
                "Color of hotkey text")
            hotkeyColorPicker:SetPoint("TOPLEFT", 10, yOffset)
            yOffset = yOffset - 30

            -- Hotkey Font Size
            local hotkeyFontSizeSlider = CreateSlider(parent, "Hotkey Font Size", 6, 32, 1,
                function() return db.hotkeyFontSize end,
                function(value)
                    db.hotkeyFontSize = value
                    UpdateBar()
                end,
                "Size of hotkey text")
            hotkeyFontSizeSlider:SetPoint("TOPLEFT", 10, yOffset)
            yOffset = yOffset - 50

            -- Hotkey Font Outline
            local hotkeyOutlineDD = CreateDropdown(parent, "Hotkey Outline", {"NONE", "OUTLINE", "THICKOUTLINE", "MONOCHROME"},
                function() return db.hotkeyFontOutline end,
                function(value)
                    db.hotkeyFontOutline = value
                    UpdateBar()
                end,
                "Outline style for hotkey text")
            hotkeyOutlineDD:SetPoint("TOPLEFT", 10, yOffset)
            yOffset = yOffset - 50

            -- Hotkey Text Position
            local hotkeyPosDD = CreateDropdown(parent, "Hotkey Position",
                {"CENTER", "TOP", "BOTTOM", "LEFT", "RIGHT", "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT"},
                function() return db.hotkeyTextPosition end,
                function(value)
                    db.hotkeyTextPosition = value
                    UpdateBar()
                end,
                "Anchor position for hotkey text")
            hotkeyPosDD:SetPoint("TOPLEFT", 10, yOffset)
            yOffset = yOffset - 50

            -- Hotkey X Offset
            local hotkeyXSlider = CreateSlider(parent, "Hotkey X Offset", -20, 20, 1,
                function() return db.hotkeyTextXOffset end,
                function(value)
                    db.hotkeyTextXOffset = value
                    UpdateBar()
                end,
                "Horizontal offset for hotkey text")
            hotkeyXSlider:SetPoint("TOPLEFT", 10, yOffset)
            yOffset = yOffset - 50

            -- Hotkey Y Offset
            local hotkeyYSlider = CreateSlider(parent, "Hotkey Y Offset", -20, 20, 1,
                function() return db.hotkeyTextYOffset end,
                function(value)
                    db.hotkeyTextYOffset = value
                    UpdateBar()
                end,
                "Vertical offset for hotkey text")
            hotkeyYSlider:SetPoint("TOPLEFT", 10, yOffset)
            yOffset = yOffset - 50
        end
    end

    -- Macro Text
    if db.macrotext ~= nil then
        local macroCB = CreateCheckbox(parent, "Show Macro Text", "Display macro names on buttons",
            function() return db.macrotext end,
            function(value)
                db.macrotext = value
                UpdateBar()
            end)
        macroCB:SetPoint("TOPLEFT", 10, yOffset)
        yOffset = yOffset - 30

        -- Detailed macro customization (bar1 only)
        if db.macroColor then
            local macroColorPicker = CreateColorPicker(parent, "Macro Color",
                function() return db.macroColor end,
                function(value)
                    db.macroColor = value
                    UpdateBar()
                end,
                "Color of macro text")
            macroColorPicker:SetPoint("TOPLEFT", 10, yOffset)
            yOffset = yOffset - 30

            -- Macro Font Size
            local macroFontSizeSlider = CreateSlider(parent, "Macro Font Size", 6, 32, 1,
                function() return db.macroFontSize end,
                function(value)
                    db.macroFontSize = value
                    UpdateBar()
                end,
                "Size of macro text")
            macroFontSizeSlider:SetPoint("TOPLEFT", 10, yOffset)
            yOffset = yOffset - 50

            -- Macro Font Outline
            local macroOutlineDD = CreateDropdown(parent, "Macro Outline", {"NONE", "OUTLINE", "THICKOUTLINE", "MONOCHROME"},
                function() return db.macroFontOutline end,
                function(value)
                    db.macroFontOutline = value
                    UpdateBar()
                end,
                "Outline style for macro text")
            macroOutlineDD:SetPoint("TOPLEFT", 10, yOffset)
            yOffset = yOffset - 50

            -- Macro Text Position
            local macroPosDD = CreateDropdown(parent, "Macro Position",
                {"CENTER", "TOP", "BOTTOM", "LEFT", "RIGHT", "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT"},
                function() return db.macroTextPosition end,
                function(value)
                    db.macroTextPosition = value
                    UpdateBar()
                end,
                "Anchor position for macro text")
            macroPosDD:SetPoint("TOPLEFT", 10, yOffset)
            yOffset = yOffset - 50

            -- Macro X Offset
            local macroXSlider = CreateSlider(parent, "Macro X Offset", -20, 20, 1,
                function() return db.macroTextXOffset end,
                function(value)
                    db.macroTextXOffset = value
                    UpdateBar()
                end,
                "Horizontal offset for macro text")
            macroXSlider:SetPoint("TOPLEFT", 10, yOffset)
            yOffset = yOffset - 50

            -- Macro Y Offset
            local macroYSlider = CreateSlider(parent, "Macro Y Offset", -20, 20, 1,
                function() return db.macroTextYOffset end,
                function(value)
                    db.macroTextYOffset = value
                    UpdateBar()
                end,
                "Vertical offset for macro text")
            macroYSlider:SetPoint("TOPLEFT", 10, yOffset)
            yOffset = yOffset - 50
        end
    end

    -- Count Text
    if db.counttext ~= nil then
        local countCB = CreateCheckbox(parent, "Show Count Text", "Display item/charge counts on buttons",
            function() return db.counttext end,
            function(value)
                db.counttext = value
                UpdateBar()
            end)
        countCB:SetPoint("TOPLEFT", 10, yOffset)
        yOffset = yOffset - 30

        -- Detailed count customization (bar1 only)
        if db.countColor then
            local countColorPicker = CreateColorPicker(parent, "Count Color",
                function() return db.countColor end,
                function(value)
                    db.countColor = value
                    UpdateBar()
                end,
                "Color of count text")
            countColorPicker:SetPoint("TOPLEFT", 10, yOffset)
            yOffset = yOffset - 30

            -- Count Font Size
            local countFontSizeSlider = CreateSlider(parent, "Count Font Size", 6, 32, 1,
                function() return db.countFontSize end,
                function(value)
                    db.countFontSize = value
                    UpdateBar()
                end,
                "Size of count text")
            countFontSizeSlider:SetPoint("TOPLEFT", 10, yOffset)
            yOffset = yOffset - 50

            -- Count Font Outline
            local countOutlineDD = CreateDropdown(parent, "Count Outline", {"NONE", "OUTLINE", "THICKOUTLINE", "MONOCHROME"},
                function() return db.countFontOutline end,
                function(value)
                    db.countFontOutline = value
                    UpdateBar()
                end,
                "Outline style for count text")
            countOutlineDD:SetPoint("TOPLEFT", 10, yOffset)
            yOffset = yOffset - 50

            -- Count Text Position
            local countPosDD = CreateDropdown(parent, "Count Position",
                {"CENTER", "TOP", "BOTTOM", "LEFT", "RIGHT", "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT"},
                function() return db.countTextPosition end,
                function(value)
                    db.countTextPosition = value
                    UpdateBar()
                end,
                "Anchor position for count text")
            countPosDD:SetPoint("TOPLEFT", 10, yOffset)
            yOffset = yOffset - 50

            -- Count X Offset
            local countXSlider = CreateSlider(parent, "Count X Offset", -20, 20, 1,
                function() return db.countTextXOffset end,
                function(value)
                    db.countTextXOffset = value
                    UpdateBar()
                end,
                "Horizontal offset for count text")
            countXSlider:SetPoint("TOPLEFT", 10, yOffset)
            yOffset = yOffset - 50

            -- Count Y Offset
            local countYSlider = CreateSlider(parent, "Count Y Offset", -20, 20, 1,
                function() return db.countTextYOffset end,
                function(value)
                    db.countTextYOffset = value
                    UpdateBar()
                end,
                "Vertical offset for count text")
            countYSlider:SetPoint("TOPLEFT", 10, yOffset)
            yOffset = yOffset - 50
        end
    end

    -- Set scroll child height based on content
    local contentHeight = math.abs(yOffset) + 50
    parent:SetHeight(contentHeight)
end

local function CreatePetBarPanel(parent)
    local yOffset = -10
    local db = E.db.actionbar.barPet

    -- Main Header
    CreateSectionHeader(parent, "Pet Bar Settings", yOffset)
    yOffset = yOffset - 30

    -- Enable Pet Bar
    local enableCB = CreateCheckbox(parent, "Enable Pet Bar", "Enable or disable the pet action bar",
        function() return db.enabled end,
        function(value)
            db.enabled = value
            if E.modules.ActionBars then E.modules.ActionBars:UpdatePetBar() end
        end)
    enableCB:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 40

    -- Layout Section
    CreateSectionHeader(parent, "Layout", yOffset)
    yOffset = yOffset - 40

    local buttonsSlider = CreateSlider(parent, "Number of Buttons", 1, 10, 1,
        function() return db.buttons end,
        function(value)
            db.buttons = value
            if E.modules.ActionBars then E.modules.ActionBars:UpdatePetBar() end
        end,
        "Number of pet action buttons")
    buttonsSlider:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 50

    local rowSlider = CreateSlider(parent, "Buttons Per Row", 1, 10, 1,
        function() return db.buttonsPerRow end,
        function(value)
            db.buttonsPerRow = value
            if E.modules.ActionBars then E.modules.ActionBars:UpdatePetBar() end
        end)
    rowSlider:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 50

    local sizeSlider = CreateSlider(parent, "Button Size", 20, 60, 1,
        function() return db.buttonSize end,
        function(value)
            db.buttonSize = value
            db.buttonHeight = value
            if E.modules.ActionBars then E.modules.ActionBars:UpdatePetBar() end
        end)
    sizeSlider:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 50

    local spacingSlider = CreateSlider(parent, "Button Spacing", 0, 10, 1,
        function() return db.buttonSpacing end,
        function(value)
            db.buttonSpacing = value
            if E.modules.ActionBars then E.modules.ActionBars:UpdatePetBar() end
        end)
    spacingSlider:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 50

    -- Appearance Section
    CreateSectionHeader(parent, "Appearance", yOffset)
    yOffset = yOffset - 30

    local backdropCB = CreateCheckbox(parent, "Show Backdrop", "Show background panel",
        function() return db.backdrop end,
        function(value)
            db.backdrop = value
            if E.modules.ActionBars then E.modules.ActionBars:UpdatePetBar() end
        end)
    backdropCB:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 30

    local alphaSlider = CreateSlider(parent, "Alpha", 0, 1, 0.05,
        function() return db.alpha end,
        function(value)
            db.alpha = value
            if E.modules.ActionBars then E.modules.ActionBars:UpdatePetBar() end
        end)
    alphaSlider:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 50

    local mouseoverCB = CreateCheckbox(parent, "Mouseover", "Only show at full alpha when moused over",
        function() return db.mouseover end,
        function(value)
            db.mouseover = value
            if E.modules.ActionBars then E.modules.ActionBars:UpdatePetBar() end
        end)
    mouseoverCB:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 40

    -- Positioning Section
    CreateSectionHeader(parent, "Positioning", yOffset)
    yOffset = yOffset - 40

    local pointDD = CreateDropdown(parent, "Anchor Point",
        {"CENTER", "TOP", "BOTTOM", "LEFT", "RIGHT", "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT"},
        function() return db.point end,
        function(value)
            db.point = value
            if E.modules.ActionBars then E.modules.ActionBars:UpdatePetBar() end
        end)
    pointDD:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 50

    local xSlider = CreateSlider(parent, "X Offset", -500, 500, 1,
        function() return db.xOffset end,
        function(value)
            db.xOffset = value
            if E.modules.ActionBars then E.modules.ActionBars:UpdatePetBar() end
        end)
    xSlider:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 50

    local ySlider = CreateSlider(parent, "Y Offset", -500, 500, 1,
        function() return db.yOffset end,
        function(value)
            db.yOffset = value
            if E.modules.ActionBars then E.modules.ActionBars:UpdatePetBar() end
        end)
    ySlider:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 50

    -- Set scroll child height based on content
    local contentHeight = math.abs(yOffset) + 50
    parent:SetHeight(contentHeight)
end

local function CreateStanceBarPanel(parent)
    local yOffset = -10
    local db = E.db.actionbar.barStance

    CreateSectionHeader(parent, "Stance Bar Settings", yOffset)
    yOffset = yOffset - 30

    local enableCB = CreateCheckbox(parent, "Enable Stance Bar", "Enable or disable the stance/form bar",
        function() return db.enabled end,
        function(value)
            db.enabled = value
            if E.modules.ActionBars then E.modules.ActionBars:UpdateStanceBar() end
        end)
    enableCB:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 40

    CreateSectionHeader(parent, "Layout", yOffset)
    yOffset = yOffset - 40

    local sizeSlider = CreateSlider(parent, "Button Size", 20, 60, 1,
        function() return db.buttonSize end,
        function(value)
            db.buttonSize = value
            db.buttonHeight = value
            if E.modules.ActionBars then E.modules.ActionBars:UpdateStanceBar() end
        end)
    sizeSlider:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 50

    local spacingSlider = CreateSlider(parent, "Button Spacing", 0, 10, 1,
        function() return db.buttonSpacing end,
        function(value)
            db.buttonSpacing = value
            if E.modules.ActionBars then E.modules.ActionBars:UpdateStanceBar() end
        end)
    spacingSlider:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 50

    CreateSectionHeader(parent, "Appearance", yOffset)
    yOffset = yOffset - 30

    local styleDD = CreateDropdown(parent, "Inactive Style", {"darkenInactive", "none"},
        function() return db.style end,
        function(value)
            db.style = value
            if E.modules.ActionBars then E.modules.ActionBars:UpdateStanceBar() end
        end,
        "How to display inactive stances")
    styleDD:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 50

    local backdropCB = CreateCheckbox(parent, "Show Backdrop", "Show background panel",
        function() return db.backdrop end,
        function(value)
            db.backdrop = value
            if E.modules.ActionBars then E.modules.ActionBars:UpdateStanceBar() end
        end)
    backdropCB:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 30

    local alphaSlider = CreateSlider(parent, "Alpha", 0, 1, 0.05,
        function() return db.alpha end,
        function(value)
            db.alpha = value
            if E.modules.ActionBars then E.modules.ActionBars:UpdateStanceBar() end
        end)
    alphaSlider:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 50

    local mouseoverCB = CreateCheckbox(parent, "Mouseover", "Only show at full alpha when moused over",
        function() return db.mouseover end,
        function(value)
            db.mouseover = value
            if E.modules.ActionBars then E.modules.ActionBars:UpdateStanceBar() end
        end)
    mouseoverCB:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 40

    CreateSectionHeader(parent, "Positioning", yOffset)
    yOffset = yOffset - 40

    local pointDD = CreateDropdown(parent, "Anchor Point",
        {"CENTER", "TOP", "BOTTOM", "LEFT", "RIGHT", "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT"},
        function() return db.point end,
        function(value)
            db.point = value
            if E.modules.ActionBars then E.modules.ActionBars:UpdateStanceBar() end
        end)
    pointDD:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 50

    local xSlider = CreateSlider(parent, "X Offset", -500, 500, 1,
        function() return db.xOffset end,
        function(value)
            db.xOffset = value
            if E.modules.ActionBars then E.modules.ActionBars:UpdateStanceBar() end
        end)
    xSlider:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 50

    local ySlider = CreateSlider(parent, "Y Offset", -500, 500, 1,
        function() return db.yOffset end,
        function(value)
            db.yOffset = value
            if E.modules.ActionBars then E.modules.ActionBars:UpdateStanceBar() end
        end)
    ySlider:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 50

    -- Set scroll child height based on content
    local contentHeight = math.abs(yOffset) + 50
    parent:SetHeight(contentHeight)
end

local function CreateMicroBarPanel(parent)
    local yOffset = -10
    local db = E.db.actionbar.microbar

    CreateSectionHeader(parent, "Micro Menu Bar Settings", yOffset)
    yOffset = yOffset - 30

    local enableCB = CreateCheckbox(parent, "Enable Micro Bar", "Enable or disable the micro menu bar",
        function() return db.enabled end,
        function(value)
            db.enabled = value
            if E.modules.ActionBars then E.modules.ActionBars:UpdateMicroBar() end
        end)
    enableCB:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 40

    CreateSectionHeader(parent, "Layout", yOffset)
    yOffset = yOffset - 40

    local sizeSlider = CreateSlider(parent, "Button Size", 15, 40, 1,
        function() return db.buttonSize end,
        function(value)
            db.buttonSize = value
            db.buttonHeight = value
            if E.modules.ActionBars then E.modules.ActionBars:UpdateMicroBar() end
        end)
    sizeSlider:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 50

    local spacingSlider = CreateSlider(parent, "Button Spacing", 0, 10, 1,
        function() return db.buttonSpacing end,
        function(value)
            db.buttonSpacing = value
            if E.modules.ActionBars then E.modules.ActionBars:UpdateMicroBar() end
        end)
    spacingSlider:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 50

    CreateSectionHeader(parent, "Appearance", yOffset)
    yOffset = yOffset - 30

    local iconsCB = CreateCheckbox(parent, "Use Icons", "Use icons instead of text for micro buttons",
        function() return db.useIcons end,
        function(value)
            db.useIcons = value
            if E.modules.ActionBars then E.modules.ActionBars:UpdateMicroBar() end
        end)
    iconsCB:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 30

    local backdropCB = CreateCheckbox(parent, "Show Backdrop", "Show background panel",
        function() return db.backdrop end,
        function(value)
            db.backdrop = value
            if E.modules.ActionBars then E.modules.ActionBars:UpdateMicroBar() end
        end)
    backdropCB:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 30

    local alphaSlider = CreateSlider(parent, "Alpha", 0, 1, 0.05,
        function() return db.alpha end,
        function(value)
            db.alpha = value
            if E.modules.ActionBars then E.modules.ActionBars:UpdateMicroBar() end
        end)
    alphaSlider:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 50

    local mouseoverCB = CreateCheckbox(parent, "Mouseover", "Only show at full alpha when moused over",
        function() return db.mouseover end,
        function(value)
            db.mouseover = value
            if E.modules.ActionBars then E.modules.ActionBars:UpdateMicroBar() end
        end)
    mouseoverCB:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 30

    if db.mouseoverAlpha then
        local mouseAlphaSlider = CreateSlider(parent, "Mouseover Alpha", 0, 1, 0.05,
            function() return db.mouseoverAlpha end,
            function(value)
                db.mouseoverAlpha = value
                if E.modules.ActionBars then E.modules.ActionBars:UpdateMicroBar() end
            end)
        mouseAlphaSlider:SetPoint("TOPLEFT", 10, yOffset)
        yOffset = yOffset - 50
    end

    CreateSectionHeader(parent, "Positioning", yOffset)
    yOffset = yOffset - 40

    local pointDD = CreateDropdown(parent, "Anchor Point",
        {"CENTER", "TOP", "BOTTOM", "LEFT", "RIGHT", "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT"},
        function() return db.point end,
        function(value)
            db.point = value
            if E.modules.ActionBars then E.modules.ActionBars:UpdateMicroBar() end
        end)
    pointDD:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 50

    local xSlider = CreateSlider(parent, "X Offset", -500, 500, 1,
        function() return db.xOffset end,
        function(value)
            db.xOffset = value
            if E.modules.ActionBars then E.modules.ActionBars:UpdateMicroBar() end
        end)
    xSlider:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 50

    local ySlider = CreateSlider(parent, "Y Offset", -500, 500, 1,
        function() return db.yOffset end,
        function(value)
            db.yOffset = value
            if E.modules.ActionBars then E.modules.ActionBars:UpdateMicroBar() end
        end)
    ySlider:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 50

    -- Set scroll child height based on content
    local contentHeight = math.abs(yOffset) + 50
    parent:SetHeight(contentHeight)
end

local function CreateExtraButtonsPanel(parent)
    local yOffset = -10

    CreateSectionHeader(parent, "Extra Action Buttons", yOffset)
    yOffset = yOffset - 30

    local note = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    note:SetPoint("TOPLEFT", 10, yOffset)
    note:SetText("Configure special action buttons that appear during quests and encounters.")
    yOffset = yOffset - 40

    -- Extra Action Button
    CreateSectionHeader(parent, "Extra Action Button", yOffset)
    yOffset = yOffset - 30

    local db1 = E.db.actionbar.extraActionButton

    local enable1CB = CreateCheckbox(parent, "Enable Extra Action Button", "Show the extra action button",
        function() return db1.enabled end,
        function(value)
            db1.enabled = value
            if E.modules.ActionBars then E.modules.ActionBars:UpdateExtraButtons() end
        end)
    enable1CB:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 30

    local size1Slider = CreateSlider(parent, "Button Size", 30, 80, 1,
        function() return db1.buttonSize end,
        function(value)
            db1.buttonSize = value
            if E.modules.ActionBars then E.modules.ActionBars:UpdateExtraButtons() end
        end)
    size1Slider:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 50

    local alpha1Slider = CreateSlider(parent, "Alpha", 0, 1, 0.05,
        function() return db1.alpha end,
        function(value)
            db1.alpha = value
            if E.modules.ActionBars then E.modules.ActionBars:UpdateExtraButtons() end
        end)
    alpha1Slider:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 60

    -- Zone Action Button
    CreateSectionHeader(parent, "Zone Action Button", yOffset)
    yOffset = yOffset - 30

    local db2 = E.db.actionbar.zoneActionButton

    local enable2CB = CreateCheckbox(parent, "Enable Zone Action Button", "Show the zone action button",
        function() return db2.enabled end,
        function(value)
            db2.enabled = value
            if E.modules.ActionBars then E.modules.ActionBars:UpdateExtraButtons() end
        end)
    enable2CB:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 30

    local size2Slider = CreateSlider(parent, "Button Size", 30, 80, 1,
        function() return db2.buttonSize end,
        function(value)
            db2.buttonSize = value
            if E.modules.ActionBars then E.modules.ActionBars:UpdateExtraButtons() end
        end)
    size2Slider:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 50

    local alpha2Slider = CreateSlider(parent, "Alpha", 0, 1, 0.05,
        function() return db2.alpha end,
        function(value)
            db2.alpha = value
            if E.modules.ActionBars then E.modules.ActionBars:UpdateExtraButtons() end
        end)
    alpha2Slider:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 60

    -- Vehicle Exit Button
    CreateSectionHeader(parent, "Vehicle Exit Button", yOffset)
    yOffset = yOffset - 30

    local db3 = E.db.actionbar.vehicleExitButton

    local enable3CB = CreateCheckbox(parent, "Enable Vehicle Exit Button", "Show the vehicle exit button",
        function() return db3.enabled end,
        function(value)
            db3.enabled = value
            if E.modules.ActionBars then E.modules.ActionBars:UpdateExtraButtons() end
        end)
    enable3CB:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 30

    local size3Slider = CreateSlider(parent, "Button Size", 20, 60, 1,
        function() return db3.buttonSize end,
        function(value)
            db3.buttonSize = value
            if E.modules.ActionBars then E.modules.ActionBars:UpdateExtraButtons() end
        end)
    size3Slider:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 50

    local alpha3Slider = CreateSlider(parent, "Alpha", 0, 1, 0.05,
        function() return db3.alpha end,
        function(value)
            db3.alpha = value
            if E.modules.ActionBars then E.modules.ActionBars:UpdateExtraButtons() end
        end)
    alpha3Slider:SetPoint("TOPLEFT", 10, yOffset)

    yOffset = yOffset - 60

    local posNote = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    posNote:SetPoint("TOPLEFT", 10, yOffset)
    posNote:SetText("|cff808080Positioning settings available in Profile.lua|r")
    yOffset = yOffset - 30

    -- Set scroll child height based on content
    local contentHeight = math.abs(yOffset) + 50
    parent:SetHeight(contentHeight)
end

-----------------------------------
-- MAIN FRAME CREATION
-----------------------------------

function ConfigGUI:CreateFrame()
    if configFrame then
        return configFrame
    end

    -- Main frame
    local frame = CreateFrame("Frame", "TotalUIConfigFrame", UIParent, "BackdropTemplate")
    frame:SetSize(1100, 700)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")

    -- Backdrop
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })

    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetClampedToScreen(true)

    -- Title bar
    local titleBg = frame:CreateTexture(nil, "ARTWORK")
    titleBg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    titleBg:SetSize(400, 64)
    titleBg:SetPoint("TOP", 0, 12)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", titleBg, "TOP", 0, -14)
    title:SetText("TotalUI Configuration")

    -- Close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function() frame:Hide() end)

    -- Make closeable with ESC
    table.insert(UISpecialFrames, "TotalUIConfigFrame")

    -----------------------------------
    -- LEFT NAVIGATION
    -----------------------------------

    local navPanel = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    navPanel:SetSize(180, 600)
    navPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -60)
    navPanel:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    navPanel:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
    navPanel:SetBackdropBorderColor(0, 0, 0, 1)

    frame.navButtons = {}
    local yPos = -5

    for _, cat in ipairs(categories) do
        local btn = CreateFrame("Button", nil, navPanel)
        btn:SetSize(170, 35)
        btn:SetPoint("TOPLEFT", navPanel, "TOPLEFT", 5, yPos)

        -- Button background
        btn:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
        btn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
        btn:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")

        -- Button text
        local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        btnText:SetPoint("LEFT", btn, "LEFT", 10, 6)
        btnText:SetJustifyH("LEFT")
        btnText:SetText(cat.name)

        if cat.disabled then
            btnText:SetTextColor(0.5, 0.5, 0.5)
            btn:Disable()
        else
            btn:SetScript("OnClick", function()
                self:ShowCategory(cat.id)
            end)
        end

        frame.navButtons[cat.id] = btn
        yPos = yPos - 40
    end

    -----------------------------------
    -- CONTENT AREA
    -----------------------------------

    local contentPanel = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    contentPanel:SetSize(885, 600)
    contentPanel:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -15, -60)
    contentPanel:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    contentPanel:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    contentPanel:SetBackdropBorderColor(0, 0, 0, 1)

    frame.contentPanel = contentPanel

    -----------------------------------
    -- SECONDARY NAVIGATION PANEL (for nested bars)
    -----------------------------------

    local secondaryNav = CreateFrame("Frame", nil, contentPanel, "BackdropTemplate")
    secondaryNav:SetSize(150, 545)
    secondaryNav:SetPoint("TOPLEFT", contentPanel, "TOPLEFT", 5, -40)
    secondaryNav:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    secondaryNav:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
    secondaryNav:SetBackdropBorderColor(0, 0, 0, 1)
    secondaryNav:Hide()  -- Hidden by default

    frame.secondaryNav = secondaryNav
    frame.secondaryNavButtons = {}

    -----------------------------------
    -- TABS CONTAINER
    -----------------------------------

    local tabContainer = CreateFrame("Frame", nil, contentPanel)
    tabContainer:SetSize(885, 35)
    tabContainer:SetPoint("TOPLEFT", contentPanel, "TOPLEFT", 0, 0)

    frame.tabContainer = tabContainer
    frame.tabs = {}

    -----------------------------------
    -- SCROLL FRAME FOR SETTINGS
    -----------------------------------

    local scrollFrame = CreateFrame("ScrollFrame", nil, contentPanel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(855, 545)
    scrollFrame:SetPoint("TOPLEFT", tabContainer, "BOTTOMLEFT", 5, -5)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(855, 1200)
    scrollFrame:SetScrollChild(scrollChild)

    frame.scrollFrame = scrollFrame
    frame.scrollChild = scrollChild

    configFrame = frame

    -- Show initial category
    self:ShowCategory("ActionBars")

    return frame
end

-----------------------------------
-- CATEGORY MANAGEMENT
-----------------------------------

function ConfigGUI:ShowCategory(categoryID)
    currentCategory = categoryID

    -- Update nav button highlights
    for id, btn in pairs(configFrame.navButtons) do
        if id == categoryID then
            btn:LockHighlight()
        else
            btn:UnlockHighlight()
        end
    end

    -- Clear existing tabs
    for _, tab in pairs(configFrame.tabs) do
        tab:Hide()
    end
    configFrame.tabs = {}

    -- Show appropriate tabs
    if categoryID == "ActionBars" then
        self:CreateActionBarsTabs()
        self:ShowTab("Global")
    elseif categoryID == "General" then
        self:ShowGeneralPanel()
    end
end

-----------------------------------
-- SECONDARY NAVIGATION
-----------------------------------

function ConfigGUI:PopulateSecondaryNav(barsList)
    -- Clear existing buttons
    for _, btn in pairs(configFrame.secondaryNavButtons) do
        btn:Hide()
        btn:SetParent(nil)
    end
    configFrame.secondaryNavButtons = {}

    local yPos = -5
    for _, barName in ipairs(barsList) do
        local btn = CreateFrame("Button", nil, configFrame.secondaryNav)
        btn:SetSize(140, 30)
        btn:SetPoint("TOPLEFT", configFrame.secondaryNav, "TOPLEFT", 5, yPos)

        -- Button background
        btn:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
        btn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
        btn:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")

        -- Button text
        local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        btnText:SetPoint("LEFT", btn, "LEFT", 10, 6)
        btnText:SetJustifyH("LEFT")
        btnText:SetText(barName)

        btn:SetScript("OnClick", function()
            self:ShowBar(barName)
        end)

        configFrame.secondaryNavButtons[barName] = btn
        yPos = yPos - 35
    end
end

function ConfigGUI:ShowBar(barName)
    currentBar = barName

    -- Update secondary nav button highlights
    for name, btn in pairs(configFrame.secondaryNavButtons) do
        if name == barName then
            btn:LockHighlight()
        else
            btn:UnlockHighlight()
        end
    end

    -- Clear scroll child (both frames and regions like FontStrings)
    for _, child in pairs({configFrame.scrollChild:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end

    for _, region in pairs({configFrame.scrollChild:GetRegions()}) do
        if region:GetObjectType() == "FontString" or region:GetObjectType() == "Texture" then
            region:Hide()
            region:SetText("")
        end
    end

    -- Adjust scroll child width to match scroll frame
    configFrame.scrollChild:SetSize(685, 1200)

    -- Create appropriate panel based on bar name
    if barName:match("^Bar %d+$") then
        local barID = tonumber(barName:match("%d+"))
        CreateBarPanel(configFrame.scrollChild, barID)
    elseif barName == "Pet Bar" then
        CreatePetBarPanel(configFrame.scrollChild)
    elseif barName == "Stance Bar" then
        CreateStanceBarPanel(configFrame.scrollChild)
    elseif barName == "Micro Bar" then
        CreateMicroBarPanel(configFrame.scrollChild)
    elseif barName == "Extra Buttons" then
        CreateExtraButtonsPanel(configFrame.scrollChild)
    end
end

function ConfigGUI:CreateActionBarsTabs()
    local xPos = 5

    for i, tabName in ipairs(actionBarTabs) do
        local tab = CreateFrame("Button", nil, configFrame.tabContainer)

        -- Create text first to measure width
        local tabText = tab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        tabText:SetText(tabName)
        tabText:SetJustifyV("MIDDLE")

        -- Calculate tab width based on text width + padding
        local textWidth = tabText:GetStringWidth()
        local tabWidth = textWidth + 30  -- Add 30px padding (15px each side)

        tab:SetSize(tabWidth, 30)
        tab:SetPoint("TOPLEFT", configFrame.tabContainer, "TOPLEFT", xPos, -2)

        tab:SetNormalTexture("Interface\\ChatFrame\\ChatFrameTab")
        tab:SetHighlightTexture("Interface\\ChatFrame\\ChatFrameTab-Highlight")

        tabText:SetPoint("CENTER", tab, "CENTER", 0, -5)

        tab:SetScript("OnClick", function()
            self:ShowTab(tabName)
        end)

        configFrame.tabs[tabName] = tab
        xPos = xPos + tabWidth + 5  -- 5px spacing between tabs

        if xPos > 850 then break end -- Don't overflow tabs
    end
end

function ConfigGUI:ShowTab(tabName)
    currentTab = tabName

    -- Update tab highlights and visual indicators
    for name, tab in pairs(configFrame.tabs) do
        if name == tabName then
            tab:LockHighlight()
            -- Add glow effect for active tab
            if not tab.glow then
                tab.glow = tab:CreateTexture(nil, "BACKGROUND")
                -- Only cover the visible button area (not the full tab frame)
                tab.glow:SetSize(80, 20)
                tab.glow:SetPoint("CENTER", tab, "CENTER", 0, -5)
                tab.glow:SetColorTexture(1, 1, 1, 0.3)
            end
            tab.glow:Show()
        else
            tab:UnlockHighlight()
            if tab.glow then
                tab.glow:Hide()
            end
        end
    end

    -- Clear scroll child (both frames and regions like FontStrings)
    for _, child in pairs({configFrame.scrollChild:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end

    -- Also clear all regions (FontStrings, Textures, etc.)
    for _, region in pairs({configFrame.scrollChild:GetRegions()}) do
        if region:GetObjectType() == "FontString" or region:GetObjectType() == "Texture" then
            region:Hide()
            region:SetText("")  -- Clear text if it's a FontString
        end
    end

    -- Handle the new 3-tab structure
    if tabName == "Global" then
        -- Hide secondary nav
        configFrame.secondaryNav:Hide()
        -- Adjust scroll frame to use full width
        configFrame.scrollFrame:SetSize(855, 545)
        configFrame.scrollFrame:SetPoint("TOPLEFT", configFrame.tabContainer, "BOTTOMLEFT", 5, -5)
        -- Adjust scroll child width to match scroll frame
        configFrame.scrollChild:SetSize(855, 1200)
        -- Show global settings
        CreateGlobalActionBarsPanel(configFrame.scrollChild)
    elseif tabName == "ActionBars 1-15" then
        -- Show secondary nav
        configFrame.secondaryNav:Show()
        -- Adjust scroll frame to account for secondary nav
        configFrame.scrollFrame:SetSize(685, 545)
        configFrame.scrollFrame:SetPoint("TOPLEFT", configFrame.tabContainer, "BOTTOMLEFT", 165, -5)
        -- Populate secondary nav with regular bars
        self:PopulateSecondaryNav(regularBarsList)
        -- Default to Bar 1
        self:ShowBar("Bar 1")
    elseif tabName == "Special Action Bars" then
        -- Show secondary nav
        configFrame.secondaryNav:Show()
        -- Adjust scroll frame to account for secondary nav
        configFrame.scrollFrame:SetSize(685, 545)
        configFrame.scrollFrame:SetPoint("TOPLEFT", configFrame.tabContainer, "BOTTOMLEFT", 165, -5)
        -- Populate secondary nav with special bars
        self:PopulateSecondaryNav(specialBarsList)
        -- Default to first special bar (Pet Bar)
        self:ShowBar("Pet Bar")
    end
end

function ConfigGUI:ShowGeneralPanel()
    -- Clear scroll child (both frames and regions like FontStrings)
    for _, child in pairs({configFrame.scrollChild:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end

    -- Also clear all regions (FontStrings, Textures, etc.)
    for _, region in pairs({configFrame.scrollChild:GetRegions()}) do
        if region:GetObjectType() == "FontString" or region:GetObjectType() == "Texture" then
            region:Hide()
            region:SetText("")  -- Clear text if it's a FontString
        end
    end

    local text = configFrame.scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    text:SetPoint("TOPLEFT", 10, -10)
    text:SetText("General settings coming in future phases...")
end

-----------------------------------
-- SHOW/HIDE
-----------------------------------

function ConfigGUI:Show()
    local frame = self:CreateFrame()
    frame:Show()
end

function ConfigGUI:Hide()
    if configFrame then
        configFrame:Hide()
    end
end

function ConfigGUI:Toggle()
    local frame = self:CreateFrame()
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end

-- Export to namespace
ns.ConfigGUI = ConfigGUI

return ConfigGUI
