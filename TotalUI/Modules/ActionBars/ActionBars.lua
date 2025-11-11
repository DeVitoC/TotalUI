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
    E:Print(string.format("ActionBars: Using %s", LTAB.VERSION_STRING))

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

    -- Create pet bar
    self:CreatePetBar()

    -- Create stance bar
    self:CreateStanceBar()

    -- Create micro bar
    self:CreateMicroBar()

    -- Create extra action buttons
    self:CreateExtraButtons()

    -- Initialize keybind handler
    self:InitializeKeybinds()

    -- Initialize cooldown handler
    self:InitializeCooldown()
end

function AB:CreateBar(barID)
    local db = E.db.actionbar["bar" .. barID]

    if not db then
        E:Print(string.format("ActionBars: No configuration for bar%d", barID))
        return
    end

    if not db.enabled then
        return
    end

    -- Create the bar using ActionBar class
    local bar = ActionBar:New(barID, UIParent)

    if bar then
        self.bars[barID] = bar
        E:Print(string.format("Created Bar %d", barID))
    else
        E:Print(string.format("Failed to create Bar %d", barID))
    end
end

function AB:CreatePetBar()
    local db = E.db.actionbar.barPet

    if not db then
        E:Print("ActionBars: No configuration for pet bar")
        return
    end

    if not db.enabled then
        return
    end

    -- Check if PetBar class loaded
    if not PetBar then
        E:Print("ActionBars: Failed to load PetBar class")
        return
    end

    -- Create the pet bar using PetBar class
    local petBar = PetBar:New(UIParent)

    if petBar then
        self.petBar = petBar
        E:Print("Created Pet Bar")
    else
        E:Print("Failed to create Pet Bar")
    end
end

function AB:CreateStanceBar()
    local db = E.db.actionbar.barStance

    if not db then
        E:Print("ActionBars: No configuration for stance bar")
        return
    end

    if not db.enabled then
        return
    end

    -- Check if StanceBar class loaded
    if not StanceBar then
        E:Print("ActionBars: Failed to load StanceBar class")
        return
    end

    -- Create the stance bar using StanceBar class
    local stanceBar = StanceBar:New(UIParent)

    if stanceBar then
        self.stanceBar = stanceBar
        E:Print("Created Stance Bar")
    else
        E:Print("Failed to create Stance Bar")
    end
end

function AB:CreateMicroBar()
    local db = E.db.actionbar.microbar

    if not db then
        E:Print("ActionBars: No configuration for micro bar")
        return
    end

    if not db.enabled then
        return
    end

    -- Check if MicroBar class loaded
    if not MicroBar then
        E:Print("ActionBars: Failed to load MicroBar class")
        return
    end

    -- Create the micro bar using MicroBar class
    local microBar = MicroBar:New(UIParent)

    if microBar then
        self.microBar = microBar
        E:Print("Created Micro Bar")
    else
        E:Print("Failed to create Micro Bar")
    end
end

function AB:CreateExtraButtons()
    -- Check if ExtraButtons class loaded
    if not ExtraButtons then
        E:Print("ActionBars: Failed to load ExtraButtons class")
        return
    end

    -- Create the extra buttons handler
    local extraButtons = ExtraButtons:New()

    if extraButtons then
        self.extraButtons = extraButtons
        E:Print("Created Extra Action Buttons")
    else
        E:Print("Failed to create Extra Action Buttons")
    end
end

function AB:InitializeKeybinds()
    -- Check if Keybinds handler loaded
    if not Keybinds then
        E:Print("ActionBars: Failed to load Keybinds handler")
        return
    end

    -- Create the keybinds handler (pass reference to this module)
    local keybinds = Keybinds:New(self)

    if keybinds then
        self.keybinds = keybinds
        E:Print("Keybinds system initialized")
    else
        E:Print("Failed to initialize keybinds")
    end
end

function AB:InitializeCooldown()
    -- Check if Cooldown handler loaded
    if not Cooldown then
        E:Print("ActionBars: Failed to load Cooldown handler")
        return
    end

    -- Create the cooldown handler
    local cooldown = Cooldown:New()

    if cooldown then
        self.cooldown = cooldown
        E:Print("Cooldown system initialized")
    else
        E:Print("Failed to initialize cooldown")
    end
end

-----------------------------------
-- BLIZZARD UI HANDLING
-----------------------------------

function AB:HideBlizzard()
    -- Hide the main action bar background art and frames
    -- These create the gray background that shows behind our bars

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
            frame:SetParent(E.HiddenFrame)
            frame:UnregisterAllEvents()
            frame:Hide()

            -- Prevent showing
            if frame.Show then
                frame.Show = function() end
            end
        end
    end

    -- Additional cleanup for action buttons
    for i = 1, 12 do
        local button = _G["ActionButton" .. i]
        if button then
            button:Hide()
            button:UnregisterAllEvents()
            button:SetParent(E.HiddenFrame)
        end

        local multiButton = _G["MultiBarBottomLeftButton" .. i]
        if multiButton then
            multiButton:Hide()
            multiButton:UnregisterAllEvents()
            multiButton:SetParent(E.HiddenFrame)
        end

        multiButton = _G["MultiBarBottomRightButton" .. i]
        if multiButton then
            multiButton:Hide()
            multiButton:UnregisterAllEvents()
            multiButton:SetParent(E.HiddenFrame)
        end

        multiButton = _G["MultiBarRightButton" .. i]
        if multiButton then
            multiButton:Hide()
            multiButton:UnregisterAllEvents()
            multiButton:SetParent(E.HiddenFrame)
        end

        multiButton = _G["MultiBarLeftButton" .. i]
        if multiButton then
            multiButton:Hide()
            multiButton:UnregisterAllEvents()
            multiButton:SetParent(E.HiddenFrame)
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
