--[[
    TotalUI - Keybinds Handler
    Manages keybinding functionality for action bars.

    Features:
    - Hover keybind mode (hover over button to bind key)
    - Quick keybind toggle
    - Integration with Blizzard keybind system
    - Visual feedback during binding mode
--]]

local AddonName, ns = ...
local E = ns.public

-- Create Keybinds handler
local Keybinds = {}
Keybinds.__index = Keybinds

-- State variables
local bindingMode = false
local currentButton = nil
local bindingFrame = nil

-----------------------------------
-- CONSTRUCTOR
-----------------------------------

function Keybinds:New(actionBarsModule)
    local handler = setmetatable({}, Keybinds)

    handler.actionBars = actionBarsModule
    handler.boundButtons = {}

    handler:Initialize()

    return handler
end

-----------------------------------
-- INITIALIZATION
-----------------------------------

function Keybinds:Initialize()
    -- Create binding mode UI
    self:CreateBindingModeUI()

    -- Register slash command
    self:RegisterCommands()
end

-----------------------------------
-- BINDING MODE UI
-----------------------------------

function Keybinds:CreateBindingModeUI()
    -- Create a frame to capture key presses during binding mode
    bindingFrame = CreateFrame("Frame", "TotalUI_KeybindFrame", UIParent)
    bindingFrame:SetFrameStrata("DIALOG")
    bindingFrame:SetFrameLevel(100)
    bindingFrame:EnableKeyboard(true)
    bindingFrame:EnableMouseWheel(true)
    bindingFrame:Hide()

    -- Create visual overlay
    bindingFrame.overlay = bindingFrame:CreateTexture(nil, "BACKGROUND")
    bindingFrame.overlay:SetAllPoints(UIParent)
    bindingFrame.overlay:SetColorTexture(0, 0, 0, 0.5)

    -- Create instruction text
    bindingFrame.text = bindingFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    bindingFrame.text:SetPoint("TOP", UIParent, "TOP", 0, -100)
    bindingFrame.text:SetText("|cff1784d1TotalUI Keybind Mode|r\n\nHover over a button and press a key to bind\nPress |cffff0000ESC|r or |cffff0000RIGHT CLICK|r to unbind\nPress |cffff0000ENTER|r to exit")
    bindingFrame.text:SetJustifyH("CENTER")

    -- Current binding display
    bindingFrame.currentBind = bindingFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    bindingFrame.currentBind:SetPoint("TOP", bindingFrame.text, "BOTTOM", 0, -20)
    bindingFrame.currentBind:SetText("")
    bindingFrame.currentBind:SetTextColor(1, 1, 1)

    -- Key capture handlers
    bindingFrame:SetScript("OnKeyDown", function(frame, key)
        self:OnKeyPress(key)
    end)

    bindingFrame:SetScript("OnMouseDown", function(frame, button)
        if button == "RightButton" then
            self:UnbindButton(currentButton)
        else
            self:OnKeyPress(button)
        end
    end)

    bindingFrame:SetScript("OnMouseWheel", function(frame, delta)
        local key = delta > 0 and "MOUSEWHEELUP" or "MOUSEWHEELDOWN"
        self:OnKeyPress(key)
    end)
end

-----------------------------------
-- BINDING MODE CONTROL
-----------------------------------

function Keybinds:ToggleBindingMode()
    if bindingMode then
        self:ExitBindingMode()
    else
        self:EnterBindingMode()
    end
end

function Keybinds:EnterBindingMode()
    if InCombatLockdown() then
        E:Print("Cannot enter keybind mode in combat")
        return
    end

    bindingMode = true
    bindingFrame:Show()

    -- Enable hover on all action buttons
    self:EnableHoverBindings()

    E:Print("Keybind mode enabled. Hover over a button and press a key.")
end

function Keybinds:ExitBindingMode()
    bindingMode = false
    bindingFrame:Hide()
    currentButton = nil

    -- Disable hover on all action buttons
    self:DisableHoverBindings()

    -- Save keybinds
    SaveBindings(GetCurrentBindingSet())

    E:Print("Keybind mode disabled. Keybinds saved.")
end

-----------------------------------
-- HOVER BINDING
-----------------------------------

function Keybinds:EnableHoverBindings()
    -- Enable hover binding for all action bar buttons
    local AB = self.actionBars

    -- Standard bars (1-15)
    for barID, bar in pairs(AB.bars) do
        if bar and bar.buttons then
            for _, button in ipairs(bar.buttons) do
                if button then
                    self:EnableButtonHover(button)
                end
            end
        end
    end

    -- Pet bar
    if AB.petBar and AB.petBar.buttons then
        for _, button in ipairs(AB.petBar.buttons) do
            if button then
                self:EnableButtonHover(button)
            end
        end
    end

    -- Stance bar
    if AB.stanceBar and AB.stanceBar.buttons then
        for _, button in ipairs(AB.stanceBar.buttons) do
            if button then
                self:EnableButtonHover(button)
            end
        end
    end
end

function Keybinds:DisableHoverBindings()
    -- Remove hover scripts from all buttons
    local AB = self.actionBars

    -- Standard bars (1-15)
    for barID, bar in pairs(AB.bars) do
        if bar and bar.buttons then
            for _, button in ipairs(bar.buttons) do
                if button and button._keybindHover then
                    button:SetScript("OnEnter", button._originalOnEnter)
                    button:SetScript("OnLeave", button._originalOnLeave)
                    button._keybindHover = nil
                    button._originalOnEnter = nil
                    button._originalOnLeave = nil

                    -- Remove highlight
                    if button._keybindHighlight then
                        button._keybindHighlight:Hide()
                    end
                end
            end
        end
    end

    -- Pet bar
    if AB.petBar and AB.petBar.buttons then
        for _, button in ipairs(AB.petBar.buttons) do
            if button and button._keybindHover then
                button:SetScript("OnEnter", button._originalOnEnter)
                button:SetScript("OnLeave", button._originalOnLeave)
                button._keybindHover = nil
                button._originalOnEnter = nil
                button._originalOnLeave = nil

                if button._keybindHighlight then
                    button._keybindHighlight:Hide()
                end
            end
        end
    end

    -- Stance bar
    if AB.stanceBar and AB.stanceBar.buttons then
        for _, button in ipairs(AB.stanceBar.buttons) do
            if button and button._keybindHover then
                button:SetScript("OnEnter", button._originalOnEnter)
                button:SetScript("OnLeave", button._originalOnLeave)
                button._keybindHover = nil
                button._originalOnEnter = nil
                button._originalOnLeave = nil

                if button._keybindHighlight then
                    button._keybindHighlight:Hide()
                end
            end
        end
    end
end

function Keybinds:EnableButtonHover(button)
    if not button or button._keybindHover then return end

    -- Store original scripts
    button._originalOnEnter = button:GetScript("OnEnter")
    button._originalOnLeave = button:GetScript("OnLeave")
    button._keybindHover = true

    -- Create hover highlight if it doesn't exist
    if not button._keybindHighlight then
        button._keybindHighlight = button:CreateTexture(nil, "OVERLAY")
        button._keybindHighlight:SetAllPoints()
        button._keybindHighlight:SetColorTexture(0.3, 0.7, 1, 0.3)
        button._keybindHighlight:Hide()
    end

    -- Set hover scripts
    button:SetScript("OnEnter", function(btn)
        currentButton = btn
        button._keybindHighlight:Show()
        self:UpdateBindingDisplay(btn)

        -- Call original OnEnter if it exists
        if button._originalOnEnter then
            button._originalOnEnter(btn)
        end
    end)

    button:SetScript("OnLeave", function(btn)
        if currentButton == btn then
            currentButton = nil
        end
        button._keybindHighlight:Hide()
        self:UpdateBindingDisplay(nil)

        -- Call original OnLeave if it exists
        if button._originalOnLeave then
            button._originalOnLeave(btn)
        end
    end)
end

-----------------------------------
-- KEY BINDING
-----------------------------------

function Keybinds:OnKeyPress(key)
    if not currentButton then return end

    -- Handle ESC to exit
    if key == "ESCAPE" then
        self:ExitBindingMode()
        return
    end

    -- Handle ENTER to exit
    if key == "ENTER" then
        self:ExitBindingMode()
        return
    end

    -- Get button's binding action
    local bindingAction = self:GetButtonBindingAction(currentButton)
    if not bindingAction then
        E:Print("Cannot bind this button type")
        return
    end

    -- Check if key is already bound
    local currentBinding = GetBindingKey(bindingAction)
    if currentBinding then
        -- Unbind existing
        SetBinding(currentBinding, nil)
    end

    -- Normalize key name
    key = self:NormalizeKeyName(key)

    -- Set new binding
    local success = SetBinding(key, bindingAction)
    if success then
        E:Print(string.format("Bound |cffFFD100%s|r to |cff00FF00%s|r", key, currentButton:GetName() or "button"))
        self:UpdateBindingDisplay(currentButton)
    else
        E:Print(string.format("Failed to bind |cffFFD100%s|r", key))
    end
end

function Keybinds:UnbindButton(button)
    if not button then return end

    local bindingAction = self:GetButtonBindingAction(button)
    if not bindingAction then return end

    local key = GetBindingKey(bindingAction)
    if key then
        SetBinding(key, nil)
        E:Print(string.format("Unbound |cffFFD100%s|r from |cff00FF00%s|r", key, button:GetName() or "button"))
        self:UpdateBindingDisplay(button)
    else
        E:Print("Button has no binding to remove")
    end
end

function Keybinds:GetButtonBindingAction(button)
    if not button then return nil end

    -- Try to get the binding from button attributes
    local actionType = button:GetAttribute("type")
    local actionID = button:GetAttribute("action")

    if actionType == "action" and actionID then
        -- Standard action button
        return string.format("ACTIONBUTTON%d", actionID)
    elseif actionType == "pet" and actionID then
        -- Pet action button
        return string.format("BONUSACTIONBUTTON%d", actionID)
    elseif button:GetName() then
        -- Try to derive from button name
        local name = button:GetName()

        -- Match TotalUI_BarXButtonY pattern
        local barNum, btnNum = name:match("TotalUI_Bar(%d+)Button(%d+)")
        if barNum and btnNum then
            barNum = tonumber(barNum)
            btnNum = tonumber(btnNum)
            local actionID = ((barNum - 1) * 12) + btnNum
            return string.format("ACTIONBUTTON%d", actionID)
        end

        -- Match TotalUI_PetBarButtonY pattern
        btnNum = name:match("TotalUI_PetBarButton(%d+)")
        if btnNum then
            return string.format("BONUSACTIONBUTTON%d", tonumber(btnNum))
        end

        -- Match TotalUI_StanceButtonY pattern
        btnNum = name:match("TotalUI_StanceButton(%d+)")
        if btnNum then
            return string.format("SHAPESHIFTBUTTON%d", tonumber(btnNum))
        end
    end

    return nil
end

function Keybinds:NormalizeKeyName(key)
    -- Convert mouse button names
    if key == "LeftButton" then
        return "BUTTON1"
    elseif key == "RightButton" then
        return "BUTTON2"
    elseif key == "MiddleButton" then
        return "BUTTON3"
    elseif key == "Button4" then
        return "BUTTON4"
    elseif key == "Button5" then
        return "BUTTON5"
    end

    return key
end

-----------------------------------
-- DISPLAY UPDATE
-----------------------------------

function Keybinds:UpdateBindingDisplay(button)
    if not bindingFrame or not bindingFrame.currentBind then return end

    if not button then
        bindingFrame.currentBind:SetText("")
        return
    end

    local bindingAction = self:GetButtonBindingAction(button)
    if not bindingAction then
        bindingFrame.currentBind:SetText("Cannot bind this button")
        bindingFrame.currentBind:SetTextColor(1, 0, 0)
        return
    end

    local key = GetBindingKey(bindingAction)
    local buttonName = button:GetName() or "Unknown Button"

    if key then
        bindingFrame.currentBind:SetText(string.format("Current: |cff00FF00%s|r → |cffFFD100%s|r", buttonName, key))
        bindingFrame.currentBind:SetTextColor(1, 1, 1)
    else
        bindingFrame.currentBind:SetText(string.format("Current: |cff00FF00%s|r → |cffFF0000Not Bound|r", buttonName))
        bindingFrame.currentBind:SetTextColor(1, 1, 1)
    end
end

-----------------------------------
-- COMMANDS
-----------------------------------

function Keybinds:RegisterCommands()
    -- This will be called from ActionBars module
    -- /totalui keybind
end

function Keybinds:HandleCommand(args)
    local cmd = args[1]

    if not cmd or cmd == "toggle" then
        self:ToggleBindingMode()
    elseif cmd == "on" then
        if not bindingMode then
            self:EnterBindingMode()
        end
    elseif cmd == "off" then
        if bindingMode then
            self:ExitBindingMode()
        end
    else
        E:Print("Keybind Commands:")
        E:Print("  /totalui keybind - Toggle keybind mode")
        E:Print("  /totalui keybind on - Enable keybind mode")
        E:Print("  /totalui keybind off - Disable keybind mode")
    end
end

-----------------------------------
-- CLEANUP
-----------------------------------

function Keybinds:Destroy()
    -- Exit binding mode if active
    if bindingMode then
        self:ExitBindingMode()
    end

    -- Clean up frame
    if bindingFrame then
        bindingFrame:Hide()
        bindingFrame = nil
    end

    self.boundButtons = {}
end

-- Export handler to namespace
ns.Keybinds = Keybinds
