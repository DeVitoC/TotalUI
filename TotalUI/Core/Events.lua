--[[
    TotalUI - Events
    Event handling system and callback management.
--]]

local AddonName, ns = ...
local E = ns.public

-- Callback system
E.callbacks = {
    events = {}
}

function E.callbacks:Fire(event, ...)
    if not self.events[event] then return end

    for _, callback in ipairs(self.events[event]) do
        callback(...)
    end
end

function E.callbacks:Register(event, callback)
    if not self.events[event] then
        self.events[event] = {}
    end

    table.insert(self.events[event], callback)
end

function E.callbacks:Unregister(event, callback)
    if not self.events[event] then return end

    for i, cb in ipairs(self.events[event]) do
        if cb == callback then
            table.remove(self.events[event], i)
            return
        end
    end
end

-- Bucket events to reduce spam
E.Buckets = {}

function E:RegisterBucketEvent(event, interval, func)
    if not self.Buckets[event] then
        self.Buckets[event] = {
            interval = interval,
            lastUpdate = 0,
            callbacks = {}
        }

        self.eventFrame:RegisterEvent(event)

        -- Hook the event handler
        self.eventFrame:HookScript("OnEvent", function(frame, triggeredEvent, ...)
            if triggeredEvent ~= event then return end

            local bucket = self.Buckets[event]
            local now = GetTime()

            if now - bucket.lastUpdate >= bucket.interval then
                for _, callback in ipairs(bucket.callbacks) do
                    callback(...)
                end
                bucket.lastUpdate = now
            end
        end)
    end

    table.insert(self.Buckets[event].callbacks, func)
end

function E:UnregisterBucketEvent(event, func)
    if not self.Buckets[event] then return end

    for i, callback in ipairs(self.Buckets[event].callbacks) do
        if callback == func then
            table.remove(self.Buckets[event].callbacks, i)
            break
        end
    end

    -- If no more callbacks, unregister the event
    if #self.Buckets[event].callbacks == 0 then
        self.eventFrame:UnregisterEvent(event)
        self.Buckets[event] = nil
    end
end

-- Combat state tracking
E.inCombat = false

E.eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
E.eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

E.eventFrame:HookScript("OnEvent", function(frame, event, ...)
    if event == "PLAYER_REGEN_DISABLED" then
        E.inCombat = true
        E.callbacks:Fire("EnterCombat")
    elseif event == "PLAYER_REGEN_ENABLED" then
        E.inCombat = false
        E.callbacks:Fire("LeaveCombat")

        -- Fire any queued updates that require out of combat
        if E.combatQueue then
            for _, func in ipairs(E.combatQueue) do
                func()
            end
            E.combatQueue = {}
        end
    end
end)

-- Queue functions to run after leaving combat
E.combatQueue = {}

function E:QueueAfterCombat(func)
    if not self.inCombat then
        func()
    else
        table.insert(self.combatQueue, func)
    end
end

-- Loading state tracking
E.isLoaded = false

E.eventFrame:HookScript("OnEvent", function(frame, event, ...)
    if event == "PLAYER_LOGIN" then
        E.isLoaded = true
        E.callbacks:Fire("AddonLoaded")
    end
end)

-- Screen resolution change tracking
E.eventFrame:RegisterEvent("UI_SCALE_CHANGED")
E.eventFrame:RegisterEvent("DISPLAY_SIZE_CHANGED")

E.eventFrame:HookScript("OnEvent", function(frame, event, ...)
    if event == "UI_SCALE_CHANGED" or event == "DISPLAY_SIZE_CHANGED" then
        E.callbacks:Fire("ResolutionChanged")
    end
end)

-- Zone change tracking
E.eventFrame:RegisterEvent("ZONE_CHANGED")
E.eventFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
E.eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

E.eventFrame:HookScript("OnEvent", function(frame, event, ...)
    if event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" or event == "ZONE_CHANGED_NEW_AREA" then
        E.callbacks:Fire("ZoneChanged")
    end
end)
