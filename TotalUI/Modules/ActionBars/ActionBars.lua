--[[
    TotalUI - ActionBars Module (Phase 1)
    Complete replacement for Blizzard action bars.
--]]

local AddonName, ns = ...
local E = ns.public

-- Create module
local AB = E:NewModule("ActionBars")

-- Get ActionBar class from namespace (loaded via .toc)
local ActionBar = ns.ActionBar
local PetBar = ns.PetBar
local StanceBar = ns.StanceBar
local MicroBar = ns.MicroBar
local ExtraButtons = ns.ExtraButtons
local Keybinds = ns.Keybinds
local Cooldown = ns.Cooldown

-- Module variables
AB.bars = {}
AB.petBar = nil
AB.stanceBar = nil
AB.microBar = nil
AB.extraButtons = nil
AB.keybinds = nil
AB.cooldown = nil
AB.initialized = false
AB.blizzardState = {} -- Store original Blizzard frame state for restoration

-----------------------------------
-- INITIALIZATION
-----------------------------------

function AB:Initialize()
    -- Check if module is enabled
    if not E.private.actionbars.enable then
        return
    end

    -- Check if ActionBar class loaded
    if not ActionBar then
        E:Print("ActionBars: Failed to load ActionBar class")
        return
    end

    -- Verify LibTotalActionButtons is available via LibStub (Phase 1 Step 1.5)
    local LTAB = LibStub("LibTotalActionButtons-1.0", true)  -- true = silent fail
    if not LTAB then
        E:Print("ActionBars: LibTotalActionButtons not loaded. Action bars will not function.")
        return
    end

    -- Store reference for convenience
    self.LTAB = LTAB

    -- Hide Blizzard action bars
    self:HideBlizzard()

    -- Create action bars
    self:CreateBars()

    -- Register global events
    self:RegisterEvents()

    -- Register config callbacks
    E.callbacks:Register("ConfigChanged", function()
        self:Update()
    end)

    E.callbacks:Register("EnterCombat", function()
        self:OnEnterCombat()
    end)

    E.callbacks:Register("LeaveCombat", function()
        self:OnLeaveCombat()
    end)

    self.initialized = true
    E:Print("ActionBars module loaded")
end

-----------------------------------
-- BAR CREATION
-----------------------------------

function AB:CreateBars()
    -- Create all 15 standard action bars
    for i = 1, 15 do
        self:CreateBar(i)
    end

    -- Pet bar (now has PET button type support)
    self:CreatePetBar()

    -- TODO: Stance bar doesn't use LTAB (uses direct WoW API)
    -- self:CreateStanceBar()

    -- TODO: Micro bar needs testing
    -- self:CreateMicroBar()

    -- TODO: Extra buttons need testing
    -- self:CreateExtraButtons()

    -- TODO: Keybinds need testing
    -- self:InitializeKeybinds()

    -- Initialize cooldown handler
    self:InitializeCooldown()
end

function AB:CreateBar(barID)
    local db = E.db.actionbar["bar" .. barID]

    if not db then
        return
    end

    if not db.enabled then
        return
    end

    -- Create the bar using ActionBar class
    local bar = ActionBar:New(barID, UIParent)

    if bar then
        self.bars[barID] = bar
    end
end

function AB:CreatePetBar()
    local db = E.db.actionbar.barPet

    if not db then
        return
    end

    if not db.enabled then
        return
    end

    -- Check if PetBar class loaded
    if not PetBar then
        return
    end

    -- Create the pet bar using PetBar class
    local petBar = PetBar:New(UIParent)

    if petBar then
        self.petBar = petBar
    end
end

function AB:CreateStanceBar()
    local db = E.db.actionbar.barStance

    if not db then
        return
    end

    if not db.enabled then
        return
    end

    -- Check if StanceBar class loaded
    if not StanceBar then
        return
    end

    -- Create the stance bar using StanceBar class
    local stanceBar = StanceBar:New(UIParent)

    if stanceBar then
        self.stanceBar = stanceBar
    end
end

function AB:CreateMicroBar()
    local db = E.db.actionbar.microbar

    if not db then
        return
    end

    if not db.enabled then
        return
    end

    -- Check if MicroBar class loaded
    if not MicroBar then
        return
    end

    -- Create the micro bar using MicroBar class
    local microBar = MicroBar:New(UIParent)

    if microBar then
        self.microBar = microBar
    end
end

function AB:CreateExtraButtons()
    -- Check if ExtraButtons class loaded
    if not ExtraButtons then
        return
    end

    -- Create the extra buttons handler
    local extraButtons = ExtraButtons:New()

    if extraButtons then
        self.extraButtons = extraButtons
    end
end

function AB:InitializeKeybinds()
    -- Check if Keybinds handler loaded
    if not Keybinds then
        return
    end

    -- Create the keybinds handler (pass reference to this module)
    local keybinds = Keybinds:New(self)

    if keybinds then
        self.keybinds = keybinds
    end
end

function AB:InitializeCooldown()
    -- Check if Cooldown handler loaded
    if not Cooldown then
        return
    end

    -- Create the cooldown handler
    local cooldown = Cooldown:New()

    if cooldown then
        self.cooldown = cooldown
    end
end

-----------------------------------
-- BLIZZARD UI HANDLING
-----------------------------------

function AB:HideBlizzard()
    -- Hide the main action bar background art and frames
    -- Store original state for restoration when module is disabled

    local blizzardFrames = {
        -- Main bar
        MainMenuBar,
        MainMenuBarArtFrame,

        -- Additional bars
        MultiBarBottomLeft,
        MultiBarBottomRight,
        MultiBarRight,
        MultiBarLeft,
        MultiBar5,
        MultiBar6,
        MultiBar7,

        -- Pet bar
        PetActionBarFrame,

        -- Stance bar
        StanceBarFrame,

        -- Possession bar (vehicles, etc.)
        PossessBarFrame,

        -- Override bar
        OverrideActionBar,

        -- Micro menu
        MicroButtonAndBagsBar,

        -- Status bars
        StatusTrackingBarManager,

        -- Experience/reputation bars
        MainMenuBarVehicleLeaveButton,
    }

    -- Hide and disable each frame
    for _, frame in pairs(blizzardFrames) do
        if frame then
            -- Store original state if not already stored
            if not self.blizzardState[frame] then
                self.blizzardState[frame] = {
                    parent = frame:GetParent(),
                    show = frame.Show,
                }
            end

            frame:SetParent(E.HiddenFrame)
            frame:Hide()

            -- Prevent showing
            if frame.Show then
                frame.Show = function() end
            end
        end
    end

    -- Additional cleanup for action buttons
    -- Note: We don't unregister events because Blizzard frames need their events to function
    -- when we restore them. Just hiding and reparenting is sufficient.
    for i = 1, 12 do
        local button = _G["ActionButton" .. i]
        if button then
            if not self.blizzardState[button] then
                self.blizzardState[button] = {
                    parent = button:GetParent(),
                }
            end
            button:SetParent(E.HiddenFrame)
            button:Hide()
        end

        local multiButton = _G["MultiBarBottomLeftButton" .. i]
        if multiButton then
            if not self.blizzardState[multiButton] then
                self.blizzardState[multiButton] = {
                    parent = multiButton:GetParent(),
                }
            end
            multiButton:SetParent(E.HiddenFrame)
            multiButton:Hide()
        end

        multiButton = _G["MultiBarBottomRightButton" .. i]
        if multiButton then
            if not self.blizzardState[multiButton] then
                self.blizzardState[multiButton] = {
                    parent = multiButton:GetParent(),
                }
            end
            multiButton:SetParent(E.HiddenFrame)
            multiButton:Hide()
        end

        multiButton = _G["MultiBarRightButton" .. i]
        if multiButton then
            if not self.blizzardState[multiButton] then
                self.blizzardState[multiButton] = {
                    parent = multiButton:GetParent(),
                }
            end
            multiButton:SetParent(E.HiddenFrame)
            multiButton:Hide()
        end

        multiButton = _G["MultiBarLeftButton" .. i]
        if multiButton then
            if not self.blizzardState[multiButton] then
                self.blizzardState[multiButton] = {
                    parent = multiButton:GetParent(),
                }
            end
            multiButton:SetParent(E.HiddenFrame)
            multiButton:Hide()
        end
    end
end

function AB:ShowBlizzard()
    -- Restore Blizzard's default action bars
    -- Called when ActionBars module is disabled

    -- First, restore all stored frame states
    for frame, state in pairs(self.blizzardState) do
        if frame and state then
            -- Restore parent
            if state.parent then
                frame:SetParent(state.parent)
            end

            -- Restore Show method
            if state.show then
                frame.Show = state.show
            else
                -- If we don't have stored Show method, remove our override
                frame.Show = nil
            end
        end
    end

    -- Force restoration of key frames
    -- MainMenuBar
    if MainMenuBar then
        MainMenuBar:SetParent(UIParent)
        MainMenuBar.Show = nil
        MainMenuBar:SetShown(true)
        MainMenuBar:SetAlpha(1)
    end

    if MainMenuBarArtFrame then
        MainMenuBarArtFrame:SetParent(UIParent)
        MainMenuBarArtFrame.Show = nil
        MainMenuBarArtFrame:SetShown(true)
        MainMenuBarArtFrame:SetAlpha(1)
    end

    -- MultiBar frames
    local multiBarNames = {
        "MultiBarBottomLeft",
        "MultiBarBottomRight",
        "MultiBarRight",
        "MultiBarLeft",
        "MultiBar5",
        "MultiBar6",
        "MultiBar7"
    }

    for _, barName in ipairs(multiBarNames) do
        local bar = _G[barName]
        if bar then
            bar:SetParent(UIParent)
            bar.Show = nil
            bar:SetShown(true)
            bar:SetAlpha(1)
        end
    end

    -- Pet bar
    if PetActionBarFrame then
        PetActionBarFrame:SetParent(UIParent)
        PetActionBarFrame.Show = nil
        PetActionBarFrame:SetShown(true)
        PetActionBarFrame:SetAlpha(1)
    end

    -- Stance bar
    if StanceBarFrame then
        StanceBarFrame:SetParent(UIParent)
        StanceBarFrame.Show = nil
        StanceBarFrame:SetShown(true)
        StanceBarFrame:SetAlpha(1)
    end

    -- Micro menu
    if MicroButtonAndBagsBar then
        MicroButtonAndBagsBar:SetParent(UIParent)
        MicroButtonAndBagsBar.Show = nil
        MicroButtonAndBagsBar:SetShown(true)
        MicroButtonAndBagsBar:SetAlpha(1)
    end

    -- Status tracking
    if StatusTrackingBarManager then
        StatusTrackingBarManager:SetParent(UIParent)
        StatusTrackingBarManager.Show = nil
        StatusTrackingBarManager:SetShown(true)
        StatusTrackingBarManager:SetAlpha(1)
    end

    -- Restore action buttons
    for i = 1, 12 do
        local btn = _G["ActionButton" .. i]
        if btn then
            btn:SetParent(MainMenuBar or UIParent)
            btn:SetShown(true)
        end
    end

    -- Try to refresh Blizzard's UI
    if MainMenuBar then
        if MainMenuBar.UpdateAll then
            MainMenuBar:UpdateAll()
        end
        if MainMenuBar.Layout then
            MainMenuBar:Layout()
        end
    end

    -- Force UI update
    if UIParent_ManageFramePositions then
        UIParent_ManageFramePositions()
    end

    -- If EditMode exists (retail), refresh it
    if EditModeManagerFrame then
        -- Refresh each individual bar system in EditMode
        -- Note: We skip UpdateLayoutInfo() as it can fail if EditMode isn't fully initialized
        local barSystems = {
            "ActionBar",
            "MultiBarBottomLeft",
            "MultiBarBottomRight",
            "MultiBarLeft",
            "MultiBarRight",
            "MultiBar5",
            "MultiBar6",
            "MultiBar7",
            "PetActionBar",
            "StanceBar",
            "MicroMenu"
        }

        for _, systemName in ipairs(barSystems) do
            local system = EditModeManagerFrame.editModeSystemsCache and EditModeManagerFrame.editModeSystemsCache[systemName]
            if system then
                if system.UpdateVisibility then
                    system:UpdateVisibility()
                end
                if system.SetShown then
                    system:SetShown(true)
                end
            end
        end
    end
end

-----------------------------------
-- EVENTS
-----------------------------------

function AB:RegisterEvents()
    -- Check if we have AceEvent (via E)
    if E.RegisterEvent then
        -- Use AceEvent
        E:RegisterEvent("PLAYER_ENTERING_WORLD", function() self:OnPlayerEnter() end)
        E:RegisterEvent("PLAYER_LEVEL_UP", function() self:OnPlayerLevelUp() end)
    else
        -- Fallback to basic frame events
        if not self.eventFrame then
            self.eventFrame = CreateFrame("Frame")
        end

        self.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        self.eventFrame:RegisterEvent("PLAYER_LEVEL_UP")

        self.eventFrame:SetScript("OnEvent", function(_, event, ...)
            if event == "PLAYER_ENTERING_WORLD" then
                self:OnPlayerEnter()
            elseif event == "PLAYER_LEVEL_UP" then
                self:OnPlayerLevelUp()
            end
        end)
    end
end

function AB:OnPlayerEnter()
    -- Update all bars
    self:Update()
end

function AB:OnPlayerLevelUp()
    -- Update all bars (new spells might be available)
    self:Update()
end

function AB:OnEnterCombat()
    -- Combat started
    -- Any combat-specific behavior can go here
end

function AB:OnLeaveCombat()
    -- Combat ended
    -- Process any queued updates
end

-----------------------------------
-- UPDATE
-----------------------------------

function AB:Update()
    if not self.initialized then return end

    -- Check if ActionBars module is enabled
    if not E.db.actionbar.enable then
        -- Hide all TotalUI bars
        for barID, bar in pairs(self.bars) do
            if bar and bar.frame then
                -- CRITICAL: Unregister attribute drivers FIRST to prevent them from showing the frame
                UnregisterAttributeDriver(bar.frame, "state-visibility")
                UnregisterStateDriver(bar.frame, "page")

                bar.frame:Hide()
            end
        end
        if self.petBar and self.petBar.frame then
            self.petBar.frame:Hide()
        end
        if self.stanceBar and self.stanceBar.frame then
            self.stanceBar.frame:Hide()
        end
        if self.microBar and self.microBar.frame then
            self.microBar.frame:Hide()
        end
        if self.extraButtons then
            if self.extraButtons.extraActionButton then
                self.extraButtons.extraActionButton:Hide()
            end
            if self.extraButtons.zoneActionButton then
                self.extraButtons.zoneActionButton:Hide()
            end
            if self.extraButtons.vehicleExitButton then
                self.extraButtons.vehicleExitButton:Hide()
            end
        end

        -- Restore Blizzard's default action bars
        self:ShowBlizzard()

        return
    end

    -- Hide Blizzard bars when TotalUI bars are enabled
    self:HideBlizzard()

    -- Update all created bars
    for barID, bar in pairs(self.bars) do
        if bar and bar.Update then
            bar:Update()
        end
    end

    -- Update pet bar
    if self.petBar and self.petBar.Update then
        self.petBar:Update()
    end

    -- Update stance bar
    if self.stanceBar and self.stanceBar.Update then
        self.stanceBar:Update()
    end

    -- Update micro bar
    if self.microBar and self.microBar.Update then
        self.microBar:Update()
    end

    -- Update extra buttons
    if self.extraButtons and self.extraButtons.Update then
        self.extraButtons:Update()
    end

    -- Update cooldown settings
    if self.cooldown and self.cooldown.Update then
        self.cooldown:Update()
    end
end

function AB:UpdateBar(barID)
    -- Update a specific bar (called from settings UI)
    if not self.initialized then return end

    local bar = self.bars[barID]
    if bar and bar.Update then
        bar:Update()
    end
end

-----------------------------------
-- UTILITY
-----------------------------------

function AB:GetBar(barID)
    return self.bars[barID]
end

function AB:EnableBar(barID)
    if InCombatLockdown() then
        E:Print("Cannot enable bars in combat")
        return
    end

    -- Update database
    local db = E.db.actionbar["bar" .. barID]
    if db then
        db.enabled = true

        -- Create bar if it doesn't exist
        if not self.bars[barID] then
            self:CreateBar(barID)
        else
            self.bars[barID]:Update()
        end
    end
end

function AB:DisableBar(barID)
    if InCombatLockdown() then
        E:Print("Cannot disable bars in combat")
        return
    end

    -- Update database
    local db = E.db.actionbar["bar" .. barID]
    if db then
        db.enabled = false

        -- Hide bar if it exists
        if self.bars[barID] then
            self.bars[barID]:Update()
        end
    end
end

function AB:ToggleBar(barID)
    local db = E.db.actionbar["bar" .. barID]
    if db and db.enabled then
        self:DisableBar(barID)
    else
        self:EnableBar(barID)
    end
end

-----------------------------------
-- COMMAND HANDLERS
-----------------------------------

function AB:HandleCommand(args)
    local cmd = args[1]

    if cmd == "toggle" then
        local barID = tonumber(args[2])
        if barID and barID >= 1 and barID <= 15 then
            self:ToggleBar(barID)
            local db = E.db.actionbar["bar" .. barID]
            if db then
                E:Print(string.format("Bar %d: %s", barID, db.enabled and "Enabled" or "Disabled"))
            end
        else
            E:Print("Usage: /totalui actionbar toggle <1-15>")
        end
    elseif cmd == "status" then
        E:Print("ActionBar Status:")
        for i = 1, 15 do
            local db = E.db.actionbar["bar" .. i]
            if db then
                E:Print(string.format("  Bar %d: %s", i, db.enabled and "Enabled" or "Disabled"))
            end
        end
    elseif cmd == "keybind" or cmd == "kb" then
        -- Handle keybind commands
        if self.keybinds then
            -- Pass remaining args to keybinds handler
            local keybindArgs = {}
            for i = 2, #args do
                table.insert(keybindArgs, args[i])
            end
            self.keybinds:HandleCommand(keybindArgs)
        else
            E:Print("Keybinds system not initialized")
        end
    else
        E:Print("ActionBar Commands:")
        E:Print("  /totalui actionbar toggle <1-15> - Toggle a bar")
        E:Print("  /totalui actionbar status - Show bar status")
        E:Print("  /totalui actionbar keybind - Toggle keybind mode")
    end
end

-- Return module
return AB
