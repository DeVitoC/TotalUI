--[[
    TotalUI_Options - ActionBars Configuration Panel
    Settings interface for Phase 1: ActionBars
--]]

local AddonName, ns = ...
local E = ns.E

-- Create ActionBars options module
local ActionBarsOptions = {}

-----------------------------------
-- SETTINGS CATEGORIES
-----------------------------------

-- Track if settings have been created
local settingsCreated = false

local function CreateActionBarsSettings()
    if settingsCreated then
        print("|cff1784d1TotalUI|r WARNING: CreateActionBarsSettings() called multiple times! Ignoring.")
        return
    end
    settingsCreated = true

    print("|cff1784d1TotalUI|r Creating ActionBars settings category...")

    -- Main ActionBars category
    local category, layout = Settings.RegisterVerticalLayoutCategory("TotalUI ActionBars")

    -- CRITICAL: Register the category with the settings panel
    Settings.RegisterAddOnCategory(category)

    -- Global ActionBars Settings Section
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Global Settings"))

    -- Enable ActionBars
    do
        local name = "Enable ActionBars"
        local tooltip = "Enable TotalUI ActionBars module"
        local defaultValue = true

        local function GetValue()
            return E.db.actionbar.enable
        end

        local function SetValue(value)
            print("SetValue called with value:", value)
            E.db.actionbar.enable = value
            print("Database value is now:", E.db.actionbar.enable)
            if E.modules.ActionBars then
                print("Calling ActionBars:Update()")
                E.modules.ActionBars:Update()
            else
                print("ERROR: E.modules.ActionBars is nil!")
            end
        end

        local setting = Settings.RegisterProxySetting(category, "TOTALUI_ACTIONBARS_ENABLE", Settings.VarType.Boolean, name, defaultValue, GetValue, SetValue)
        Settings.CreateCheckbox(category, setting, tooltip)
    end

    -- Desaturate on Cooldown
    do
        local name = "Desaturate on Cooldown"
        local tooltip = "Desaturate button icons when on cooldown"
        local defaultValue = true

        local function GetValue()
            return E.db.actionbar.desaturateOnCooldown
        end

        local function SetValue(value)
            E.db.actionbar.desaturateOnCooldown = value
            if E.modules.ActionBars and E.modules.ActionBars.cooldown then
                E.modules.ActionBars.cooldown:Update()
            end
        end

        local setting = Settings.RegisterProxySetting(category, "TOTALUI_ACTIONBARS_DESATURATE", Settings.VarType.Boolean, name, defaultValue, GetValue, SetValue)
        Settings.CreateCheckbox(category, setting, tooltip)
    end

    -- Hide Cooldown Bling
    do
        local name = "Hide Cooldown Bling"
        local tooltip = "Hide cooldown bling animation"
        local defaultValue = false

        local function GetValue()
            return E.db.actionbar.hideCooldownBling
        end

        local function SetValue(value)
            E.db.actionbar.hideCooldownBling = value
            if E.modules.ActionBars and E.modules.ActionBars.cooldown then
                E.modules.ActionBars.cooldown:Update()
            end
        end

        local setting = Settings.RegisterProxySetting(category, "TOTALUI_ACTIONBARS_HIDEBLING", Settings.VarType.Boolean, name, defaultValue, GetValue, SetValue)
        Settings.CreateCheckbox(category, setting, tooltip)
    end

    -- Individual Bar Settings (TODO: Fix to use CreateVariable)
    --[[
    for barID = 1, 15 do
        CreateBarSettings(category, layout, barID)
    end

    -- Pet Bar Settings
    CreatePetBarSettings(category, layout)

    -- Stance Bar Settings
    CreateStanceBarSettings(category, layout)

    -- Micro Bar Settings
    CreateMicroBarSettings(category, layout)

    -- Extra Buttons Settings
    CreateExtraButtonsSettings(category, layout)
    ]]

    return category
end

-----------------------------------
-- INDIVIDUAL BAR SETTINGS
-----------------------------------

function CreateBarSettings(parentCategory, layout, barID)
    local barKey = "bar" .. barID
    local db = E.db.actionbar[barKey]

    if not db then return end

    -- Add section header for this bar
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Bar " .. barID))

    -- Enable Bar
    local enableSetting = Settings.RegisterProxySetting(
        parentCategory,
        "TOTALUI_BAR" .. barID .. "_ENABLE",
        Settings.VarType.Boolean,
        "Enable Bar " .. barID,
        db.enabled,
        barID <= 5 -- Default: first 5 bars enabled
    )
    Settings.SetOnValueChangedCallback(enableSetting:GetVariable(), function()
        db.enabled = enableSetting:GetValue()
        E.modules.ActionBars:ToggleBar(barID)
    end)
    Settings.CreateCheckbox(parentCategory, enableSetting, "Enable this action bar")

    -- Button Count Slider
    local buttonsSetting = Settings.RegisterProxySetting(
        parentCategory,
        "TOTALUI_BAR" .. barID .. "_BUTTONS",
        Settings.VarType.Number,
        "Number of Buttons",
        db.buttons,
        12
    )
    Settings.SetOnValueChangedCallback(buttonsSetting:GetVariable(), function()
        db.buttons = buttonsSetting:GetValue()
        E.modules.ActionBars:UpdateBar(barID)
    end)
    local buttonsOptions = Settings.CreateSliderOptions(1, 12, 1)
    buttonsOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
    Settings.CreateSlider(parentCategory, buttonsSetting, buttonsOptions, "Number of buttons to display")

    -- Button Size Slider
    local sizeSetting = Settings.RegisterProxySetting(
        parentCategory,
        "TOTALUI_BAR" .. barID .. "_SIZE",
        Settings.VarType.Number,
        "Button Size",
        db.buttonSize,
        32
    )
    Settings.SetOnValueChangedCallback(sizeSetting:GetVariable(), function()
        db.buttonSize = sizeSetting:GetValue()
        E.modules.ActionBars:UpdateBar(barID)
    end)
    local sizeOptions = Settings.CreateSliderOptions(20, 60, 1)
    sizeOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
    Settings.CreateSlider(parentCategory, sizeSetting, sizeOptions, "Size of each button")

    -- Buttons Per Row Slider
    local rowSetting = Settings.RegisterProxySetting(
        parentCategory,
        "TOTALUI_BAR" .. barID .. "_PERROW",
        Settings.VarType.Number,
        "Buttons Per Row",
        db.buttonsPerRow,
        12
    )
    Settings.SetOnValueChangedCallback(rowSetting:GetVariable(), function()
        db.buttonsPerRow = rowSetting:GetValue()
        E.modules.ActionBars:UpdateBar(barID)
    end)
    local rowOptions = Settings.CreateSliderOptions(1, 12, 1)
    rowOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
    Settings.CreateSlider(parentCategory, rowSetting, rowOptions, "Buttons per row before wrapping")

    -- Mouseover Fade
    local mouseoverSetting = Settings.RegisterProxySetting(
        parentCategory,
        "TOTALUI_BAR" .. barID .. "_MOUSEOVER",
        Settings.VarType.Boolean,
        "Mouseover Fade",
        db.mouseover,
        false
    )
    Settings.SetOnValueChangedCallback(mouseoverSetting:GetVariable(), function()
        db.mouseover = mouseoverSetting:GetValue()
        E.modules.ActionBars:UpdateBar(barID)
    end)
    Settings.CreateCheckbox(parentCategory, mouseoverSetting, "Fade bar until mouse over")

    -- Show Backdrop
    local backdropSetting = Settings.RegisterProxySetting(
        parentCategory,
        "TOTALUI_BAR" .. barID .. "_BACKDROP",
        Settings.VarType.Boolean,
        "Show Backdrop",
        db.backdrop,
        true
    )
    Settings.SetOnValueChangedCallback(backdropSetting:GetVariable(), function()
        db.backdrop = backdropSetting:GetValue()
        E.modules.ActionBars:UpdateBar(barID)
    end)
    Settings.CreateCheckbox(parentCategory, backdropSetting, "Show backdrop behind buttons")

    -- Show Grid
    local gridSetting = Settings.RegisterProxySetting(
        parentCategory,
        "TOTALUI_BAR" .. barID .. "_GRID",
        Settings.VarType.Boolean,
        "Show Empty Button Grid",
        db.showGrid,
        barID == 1 -- Only bar 1 shows grid by default
    )
    Settings.SetOnValueChangedCallback(gridSetting:GetVariable(), function()
        db.showGrid = gridSetting:GetValue()
        E.modules.ActionBars:UpdateBar(barID)
    end)
    Settings.CreateCheckbox(parentCategory, gridSetting, "Show grid for empty buttons")
end

-----------------------------------
-- PET BAR SETTINGS
-----------------------------------

function CreatePetBarSettings(parentCategory, layout)
    local db = E.db.actionbar.barPet
    if not db then return end

    -- Add section header
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Pet Bar"))

    -- Enable
    local enableSetting = Settings.RegisterProxySetting(
        parentCategory,
        "TOTALUI_PETBAR_ENABLE",
        Settings.VarType.Boolean,
        "Enable Pet Bar",
        db.enabled,
        true
    )
    Settings.SetOnValueChangedCallback(enableSetting:GetVariable(), function()
        db.enabled = enableSetting:GetValue()
        if E.modules.ActionBars and E.modules.ActionBars.petBar then
            E.modules.ActionBars.petBar:Update()
        end
    end)
    Settings.CreateCheckbox(parentCategory, enableSetting, "Enable pet action bar")

    -- Button Size
    local sizeSetting = Settings.RegisterProxySetting(
        parentCategory,
        "TOTALUI_PETBAR_SIZE",
        Settings.VarType.Number,
        "Button Size",
        db.buttonSize,
        30
    )
    Settings.SetOnValueChangedCallback(sizeSetting:GetVariable(), function()
        db.buttonSize = sizeSetting:GetValue()
        if E.modules.ActionBars and E.modules.ActionBars.petBar then
            E.modules.ActionBars.petBar:Update()
        end
    end)
    local sizeOptions = Settings.CreateSliderOptions(20, 50, 1)
    sizeOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
    Settings.CreateSlider(parentCategory, sizeSetting, sizeOptions, "Size of pet bar buttons")
end

-----------------------------------
-- STANCE BAR SETTINGS
-----------------------------------

function CreateStanceBarSettings(parentCategory, layout)
    local db = E.db.actionbar.barStance
    if not db then return end

    -- Add section header
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Stance Bar"))

    -- Enable
    local enableSetting = Settings.RegisterProxySetting(
        parentCategory,
        "TOTALUI_STANCEBAR_ENABLE",
        Settings.VarType.Boolean,
        "Enable Stance Bar",
        db.enabled,
        true
    )
    Settings.SetOnValueChangedCallback(enableSetting:GetVariable(), function()
        db.enabled = enableSetting:GetValue()
        if E.modules.ActionBars and E.modules.ActionBars.stanceBar then
            E.modules.ActionBars.stanceBar:Update()
        end
    end)
    Settings.CreateCheckbox(parentCategory, enableSetting, "Enable stance/form bar")

    -- Button Size
    local sizeSetting = Settings.RegisterProxySetting(
        parentCategory,
        "TOTALUI_STANCEBAR_SIZE",
        Settings.VarType.Number,
        "Button Size",
        db.buttonSize,
        30
    )
    Settings.SetOnValueChangedCallback(sizeSetting:GetVariable(), function()
        db.buttonSize = sizeSetting:GetValue()
        if E.modules.ActionBars and E.modules.ActionBars.stanceBar then
            E.modules.ActionBars.stanceBar:Update()
        end
    end)
    local sizeOptions = Settings.CreateSliderOptions(20, 50, 1)
    sizeOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
    Settings.CreateSlider(parentCategory, sizeSetting, sizeOptions, "Size of stance bar buttons")
end

-----------------------------------
-- MICRO BAR SETTINGS
-----------------------------------

function CreateMicroBarSettings(parentCategory, layout)
    local db = E.db.actionbar.microbar
    if not db then return end

    -- Add section header
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Micro Bar"))

    -- Enable
    local enableSetting = Settings.RegisterProxySetting(
        parentCategory,
        "TOTALUI_MICROBAR_ENABLE",
        Settings.VarType.Boolean,
        "Enable Micro Bar",
        db.enabled,
        true
    )
    Settings.SetOnValueChangedCallback(enableSetting:GetVariable(), function()
        db.enabled = enableSetting:GetValue()
        if E.modules.ActionBars and E.modules.ActionBars.microBar then
            E.modules.ActionBars.microBar:Update()
        end
    end)
    Settings.CreateCheckbox(parentCategory, enableSetting, "Enable micro menu bar")

    -- Mouseover
    local mouseoverSetting = Settings.RegisterProxySetting(
        parentCategory,
        "TOTALUI_MICROBAR_MOUSEOVER",
        Settings.VarType.Boolean,
        "Mouseover Fade",
        db.mouseover,
        true
    )
    Settings.SetOnValueChangedCallback(mouseoverSetting:GetVariable(), function()
        db.mouseover = mouseoverSetting:GetValue()
        if E.modules.ActionBars and E.modules.ActionBars.microBar then
            E.modules.ActionBars.microBar:Update()
        end
    end)
    Settings.CreateCheckbox(parentCategory, mouseoverSetting, "Fade micro bar until mouse over")

    -- Button Size
    local sizeSetting = Settings.RegisterProxySetting(
        parentCategory,
        "TOTALUI_MICROBAR_SIZE",
        Settings.VarType.Number,
        "Button Size",
        db.buttonSize,
        20
    )
    Settings.SetOnValueChangedCallback(sizeSetting:GetVariable(), function()
        db.buttonSize = sizeSetting:GetValue()
        if E.modules.ActionBars and E.modules.ActionBars.microBar then
            E.modules.ActionBars.microBar:Update()
        end
    end)
    local sizeOptions = Settings.CreateSliderOptions(15, 30, 1)
    sizeOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
    Settings.CreateSlider(parentCategory, sizeSetting, sizeOptions, "Size of micro bar buttons")
end

-----------------------------------
-- EXTRA BUTTONS SETTINGS
-----------------------------------

function CreateExtraButtonsSettings(parentCategory, layout)
    -- Add section header
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Extra Buttons"))

    -- Extra Action Button
    local extraDB = E.db.actionbar.extraActionButton
    if extraDB then
        local extraEnableSetting = Settings.RegisterProxySetting(
            parentCategory,
            "TOTALUI_EXTRABUTTON_ENABLE",
            Settings.VarType.Boolean,
            "Enable Extra Action Button",
            extraDB.enabled,
            true
        )
        Settings.SetOnValueChangedCallback(extraEnableSetting:GetVariable(), function()
            extraDB.enabled = extraEnableSetting:GetValue()
            if E.modules.ActionBars and E.modules.ActionBars.extraButtons then
                E.modules.ActionBars.extraButtons:Update()
            end
        end)
        Settings.CreateCheckbox(parentCategory, extraEnableSetting, "Enable extra action button")
    end

    -- Zone Action Button
    local zoneDB = E.db.actionbar.zoneActionButton
    if zoneDB then
        local zoneEnableSetting = Settings.RegisterProxySetting(
            parentCategory,
            "TOTALUI_ZONEBUTTON_ENABLE",
            Settings.VarType.Boolean,
            "Enable Zone Action Button",
            zoneDB.enabled,
            true
        )
        Settings.SetOnValueChangedCallback(zoneEnableSetting:GetVariable(), function()
            zoneDB.enabled = zoneEnableSetting:GetValue()
            if E.modules.ActionBars and E.modules.ActionBars.extraButtons then
                E.modules.ActionBars.extraButtons:Update()
            end
        end)
        Settings.CreateCheckbox(parentCategory, zoneEnableSetting, "Enable zone action button")
    end

    -- Vehicle Exit Button
    local vehicleDB = E.db.actionbar.vehicleExitButton
    if vehicleDB then
        local vehicleEnableSetting = Settings.RegisterProxySetting(
            parentCategory,
            "TOTALUI_VEHICLEBUTTON_ENABLE",
            Settings.VarType.Boolean,
            "Enable Vehicle Exit Button",
            vehicleDB.enabled,
            true
        )
        Settings.SetOnValueChangedCallback(vehicleEnableSetting:GetVariable(), function()
            vehicleDB.enabled = vehicleEnableSetting:GetValue()
            if E.modules.ActionBars and E.modules.ActionBars.extraButtons then
                E.modules.ActionBars.extraButtons:Update()
            end
        end)
        Settings.CreateCheckbox(parentCategory, vehicleEnableSetting, "Enable vehicle exit button")
    end
end

-----------------------------------
-- INITIALIZATION
-----------------------------------

function ActionBarsOptions:Initialize()
    -- Prevent multiple initialization
    if self._initialized then
        return
    end

    -- Verify TotalUI is ready (note: lowercase 'modules')
    if not E or not E.modules or not E.modules.ActionBars then
        print("|cff1784d1TotalUI|r ActionBars options ERROR: ActionBars module not found!")
        print("  E exists:", tostring(E ~= nil))
        print("  E.modules exists:", tostring(E and E.modules ~= nil))
        print("  E.modules.ActionBars exists:", tostring(E and E.modules and E.modules.ActionBars ~= nil))
        return
    end

    print("|cff1784d1TotalUI|r ActionBars options creating settings UI...")

    -- Create settings UI with error handling
    local success, category = pcall(CreateActionBarsSettings)
    if not success then
        print("|cff1784d1TotalUI|r ActionBars settings FAILED:", category)
        return
    end

    -- Store category for opening from slash command
    self.category = category
    E.OptionsCategory = category

    self._initialized = true
    print("|cff1784d1TotalUI|r ActionBars settings loaded successfully.")
end

-- Export
ns.ActionBarsOptions = ActionBarsOptions

return ActionBarsOptions
