--[[
    TotalUI - Public API
    Public API functions for frame creation and manipulation.
--]]

local AddonName, ns = ...
local E = ns.public

-- Frame creation with standard backdrop (uses compatibility layer)
-- Signature matches WoW's CreateFrame: frameType, name, parent, template
function E:CreateFrame(frameType, name, parent, template)
    -- Use compatibility layer for proper backdrop template handling
    if E.Compat and E.Compat.CreateFrame then
        return E.Compat:CreateFrame(frameType, name, parent, template)
    else
        return CreateFrame(frameType, name, parent, template)
    end
end

-- Create a backdrop frame
function E:CreateBackdrop(frame, template)
    if frame.backdrop then return end

    -- Create backdrop frame with proper template
    local backdropTemplate = template or (E.Compat and E.Compat.HasBackdropTemplate and "BackdropTemplate" or nil)
    local backdrop = CreateFrame("Frame", nil, frame, backdropTemplate)

    if not backdrop then
        -- Fallback if template isn't available
        backdrop = CreateFrame("Frame", nil, frame)
    end

    backdrop:SetFrameLevel(math.max(0, frame:GetFrameLevel() - 1))

    -- Set standard backdrop
    local backdropInfo = {
        bgFile = E.Media.Blank,
        edgeFile = E.Media.Blank,
        tile = false,
        tileSize = 0,
        edgeSize = 1,
        insets = {left = 0, right = 0, top = 0, bottom = 0}
    }

    -- Use compatibility layer for setting backdrop
    if E.Compat then
        E.Compat:SetBackdrop(backdrop, backdropInfo)

        -- Get colors from database or use defaults
        local bgColor = E.db and E.db.general and E.db.general.backdropcolor or {r = 0.1, g = 0.1, b = 0.1, a = 1}
        local borderColor = E.db and E.db.general and E.db.general.bordercolor or {r = 0, g = 0, b = 0, a = 1}

        E.Compat:SetBackdropColor(backdrop, bgColor.r, bgColor.g, bgColor.b, bgColor.a or 1)
        E.Compat:SetBackdropBorderColor(backdrop, borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)
    elseif backdrop.SetBackdrop then
        backdrop:SetBackdrop(backdropInfo)
        backdrop:SetBackdropColor(0.1, 0.1, 0.1, 1)
        backdrop:SetBackdropBorderColor(0, 0, 0, 1)
    end

    backdrop:SetAllPoints(frame)
    frame.backdrop = backdrop

    return backdrop
end

-- Create a status bar
function E:CreateStatusBar(parent, texture, name)
    local bar = CreateFrame("StatusBar", name, parent)

    -- Use LibSharedMedia texture if available, otherwise use provided texture or default
    local texturePath = texture
    if not texturePath and E.LSM then
        local defaultTexture = E.db and E.db.general and E.db.general.statusbar or "Blizzard"
        texturePath = E.LSM:Fetch("statusbar", defaultTexture) or E.Media.Blank
    elseif not texturePath then
        texturePath = E.Media.Blank
    end

    bar:SetStatusBarTexture(texturePath)
    bar:GetStatusBarTexture():SetHorizTile(false)
    bar:GetStatusBarTexture():SetVertTile(false)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(1)

    -- Add background
    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetAllPoints()
    bar.bg:SetTexture(texturePath)
    bar.bg:SetAlpha(0.3)

    return bar
end

-- Create a font string with standard settings
function E:CreateFontString(parent, layer, size, outline, font)
    local fs = parent:CreateFontString(nil, layer or "OVERLAY")

    -- Use LibSharedMedia font if available
    local fontPath = font
    if not fontPath and E.LSM then
        local defaultFont = E.db and E.db.general and E.db.general.font or "Friz Quadrata TT"
        fontPath = E.LSM:Fetch("font", defaultFont) or [[Fonts\FRIZQT__.TTF]]
    elseif not fontPath then
        fontPath = [[Fonts\FRIZQT__.TTF]]
    end

    -- Use database settings if available
    local fontSize = size or (E.db and E.db.general and E.db.general.fontSize) or 12
    local fontOutline = outline or (E.db and E.db.general and E.db.general.fontOutline) or "OUTLINE"

    fs:SetFont(fontPath, fontSize, fontOutline)
    fs:SetShadowOffset(1, -1)
    fs:SetShadowColor(0, 0, 0, 1)

    return fs
end

-- Create a button with standard styling
function E:CreateButton(name, parent, template)
    local button = CreateFrame("Button", name, parent, template)

    -- Add standard styling
    E:CreateBackdrop(button)

    return button
end

-- Set template for consistent frame styling
function E:SetTemplate(frame, template, glossTex, ignoreUpdates, forcePixelMode, isUnitFrameElement, isNamePlateElement)
    if frame.template then return end

    local backdropInfo = {
        bgFile = E.Media.Blank,
        edgeFile = E.Media.Blank,
        tile = false,
        tileSize = 0,
        edgeSize = 1,
        insets = {left = 0, right = 0, top = 0, bottom = 0}
    }

    -- Use compatibility layer for backdrop
    if E.Compat then
        E.Compat:SetBackdrop(frame, backdropInfo)

        -- Get colors from database or use defaults
        local bgColor = E.db and E.db.general and E.db.general.backdropcolor or {r = 0.1, g = 0.1, b = 0.1, a = 1}
        local borderColor = E.db and E.db.general and E.db.general.bordercolor or {r = 0, g = 0, b = 0, a = 1}

        E.Compat:SetBackdropColor(frame, bgColor.r, bgColor.g, bgColor.b, bgColor.a or 1)
        E.Compat:SetBackdropBorderColor(frame, borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)
    elseif frame.SetBackdrop then
        frame:SetBackdrop(backdropInfo)
        frame:SetBackdropColor(0.1, 0.1, 0.1, 1)
        frame:SetBackdropBorderColor(0, 0, 0, 1)
    end

    frame.template = template or "Default"
end

-- Kill a frame completely
function E:Kill(frame)
    if not frame then return end

    frame:UnregisterAllEvents()
    frame:SetParent(UIParent)
    frame:Hide()

    if frame.UnregisterAllEvents then
        frame:UnregisterAllEvents()
    end

    if frame.SetScript then
        frame:SetScript("OnUpdate", nil)
        frame:SetScript("OnEvent", nil)
    end
end

-- Temporarily hide a frame
function E:Hide(frame)
    if frame then
        frame:Hide()
    end
end

-- Show a frame
function E:Show(frame)
    if frame then
        frame:Show()
    end
end

-- Toggle a frame
function E:Toggle(frame)
    if not frame then return end

    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end

-- Scale function for proper pixel scaling
function E:Scale(value)
    local mult = 768 / string.match(({GetScreenResolutions()})[GetCurrentResolution()], "%d+x(%d+)")
    return mult * math.floor(value / mult + 0.5)
end

-- Get opposite anchor point
function E:GetOppositeAnchor(anchor)
    local opposites = {
        TOPLEFT = "BOTTOMRIGHT",
        TOPRIGHT = "BOTTOMLEFT",
        BOTTOMLEFT = "TOPRIGHT",
        BOTTOMRIGHT = "TOPLEFT",
        TOP = "BOTTOM",
        BOTTOM = "TOP",
        LEFT = "RIGHT",
        RIGHT = "LEFT",
        CENTER = "CENTER"
    }

    return opposites[anchor] or "CENTER"
end

-- Smooth value update for status bars
function E:SmoothBar(bar)
    if not bar.smoothing then
        bar.smoothing = {}
    end

    bar.smoothing.targetValue = select(2, bar:GetMinMaxValues())

    if not bar.smoothing.ticker then
        bar.smoothing.ticker = C_Timer.NewTicker(0.02, function()
            local current = bar:GetValue()
            local target = bar.smoothing.targetValue
            local delta = target - current

            if math.abs(delta) < 0.01 then
                bar:SetValue(target)
                if bar.smoothing.ticker then
                    bar.smoothing.ticker:Cancel()
                    bar.smoothing.ticker = nil
                end
            else
                bar:SetValue(current + delta * 0.3)
            end
        end)
    end
end

function E:SetSmoothValue(bar, value)
    if not bar or not bar.smoothing then
        if bar then
            bar:SetValue(value)
        end
        return
    end

    bar.smoothing.targetValue = value

    if not bar.smoothing.ticker then
        E:SmoothBar(bar)
    end
end

-- Register a callback for settings changes
E.ConfigCallbacks = {}

function E:RegisterConfigCallback(callback)
    table.insert(E.ConfigCallbacks, callback)
end

function E:FireConfigCallbacks()
    for _, callback in ipairs(E.ConfigCallbacks) do
        callback()
    end
end
