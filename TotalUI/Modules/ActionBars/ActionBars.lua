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

-- Module variables
AB.bars = {}
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
    local LAB = LibStub("LibTotalActionButtons-1.0", true)  -- true = silent fail
    if not LAB then
        E:Print("ActionBars: LibTotalActionButtons not loaded. Action bars will not function.")
        return
    end

    -- Store reference for convenience
    self.LAB = LAB
    E:Print(string.format("ActionBars: Using %s", LAB.VERSION_STRING))

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
    -- For Phase 1A, we'll start with just Bar 1
    -- This will be expanded in Phase 1B
    self:CreateBar(1)

    -- TODO: Phase 1B - Create bars 2-5
    -- TODO: Phase 1C - Create special bars (pet, stance, micro)
    -- TODO: Phase 1D - Create bars 6-15
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
        for i = 1, 5 do
            local db = E.db.actionbar["bar" .. i]
            if db then
                E:Print(string.format("  Bar %d: %s", i, db.enabled and "Enabled" or "Disabled"))
            end
        end
    else
        E:Print("ActionBar Commands:")
        E:Print("  /totalui actionbar toggle <1-15> - Toggle a bar")
        E:Print("  /totalui actionbar status - Show bar status")
    end
end

-- Return module
return AB
