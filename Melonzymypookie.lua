
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService       = game:GetService("GuiService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CONFIG = {
    ToggleWidth  = 140,
    ToggleHeight = 45,

    BackgroundColor        = Color3.fromRGB(25, 25, 25),
    BackgroundTransparency = 0.35,

    StrokeColor          = Color3.fromRGB(120, 120, 120),
    StrokeTransparency   = 0.5,
    StrokeThickness      = 1.2,

    TextColor        = Color3.fromRGB(255, 255, 255),
    TextTransparency = 0.1,
    Font             = Enum.Font.GothamMedium,
    TextSize         = 15,

    OnColor              = Color3.fromRGB(0, 180, 255),
    OnTransparency       = 0.25,
    OnStroke             = Color3.fromRGB(100, 210, 255),
    OnStrokeTransparency = 0.15,
    OnTextColor          = Color3.fromRGB(255, 255, 255),
    OnGlowColor          = Color3.fromRGB(0, 180, 255),

    OffColor              = Color3.fromRGB(25, 25, 25),
    OffTransparency       = 0.35,
    OffStroke             = Color3.fromRGB(120, 120, 120),
    OffStrokeTransparency = 0.5,
    OffTextColor          = Color3.fromRGB(200, 200, 200),

    CornerRadius = 10,

    LongPressDuration = 0.6,

    SpeedMultiplier  = 1.15,
    DefaultWalkSpeed = 0,

    TweenDuration = 0.25,
}

local currentKeybind = Enum.KeyCode.E
local isRebinding    = false
local eHeld          = false
local rHeld          = false

local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "SpeedBoostUI"
screenGui.ResetOnSpawn   = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.Parent         = playerGui

local notifContainer = Instance.new("Frame")
notifContainer.Name                   = "NotifContainer"
notifContainer.Size                   = UDim2.new(0, 260, 0, 200)
notifContainer.Position               = UDim2.new(1, -276, 1, -220)
notifContainer.BackgroundTransparency = 1
notifContainer.BorderSizePixel        = 0
notifContainer.ZIndex                 = 50
notifContainer.Parent                 = screenGui

local notifLayout = Instance.new("UIListLayout")
notifLayout.SortOrder         = Enum.SortOrder.LayoutOrder
notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
notifLayout.Padding           = UDim.new(0, 6)
notifLayout.Parent            = notifContainer

local notifCount = 0

local function notify(title, body, color)
    notifCount += 1
    color = color or Color3.fromRGB(0, 180, 255)

    local card = Instance.new("Frame")
    card.Name                   = "Notif_" .. notifCount
    card.Size                   = UDim2.new(1, 0, 0, 54)
    card.BackgroundColor3       = Color3.fromRGB(18, 18, 22)
    card.BackgroundTransparency = 0.1
    card.BorderSizePixel        = 0
    card.ClipsDescendants       = true
    card.LayoutOrder            = notifCount
    card.ZIndex                 = 51
    card.Parent                 = notifContainer

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 8)
    cardCorner.Parent = card

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color        = color
    cardStroke.Thickness    = 1
    cardStroke.Transparency = 0.4
    cardStroke.Parent       = card

    local accent = Instance.new("Frame")
    accent.Size             = UDim2.new(0, 3, 1, 0)
    accent.BackgroundColor3 = color
    accent.BorderSizePixel  = 0
    accent.ZIndex           = 52
    accent.Parent           = card

    local accentCorner = Instance.new("UICorner")
    accentCorner.CornerRadius = UDim.new(0, 4)
    accentCorner.Parent = accent

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size                   = UDim2.new(1, -16, 0, 20)
    titleLbl.Position               = UDim2.new(0, 12, 0, 7)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text                   = title
    titleLbl.TextColor3             = Color3.fromRGB(255, 255, 255)
    titleLbl.Font                   = Enum.Font.GothamBold
    titleLbl.TextSize               = 12
    titleLbl.TextXAlignment         = Enum.TextXAlignment.Left
    titleLbl.ZIndex                 = 52
    titleLbl.Parent                 = card

    local bodyLbl = Instance.new("TextLabel")
    bodyLbl.Size                    = UDim2.new(1, -16, 0, 18)
    bodyLbl.Position                = UDim2.new(0, 12, 0, 28)
    bodyLbl.BackgroundTransparency  = 1
    bodyLbl.Text                    = body
    bodyLbl.TextColor3              = Color3.fromRGB(180, 180, 195)
    bodyLbl.Font                    = Enum.Font.Gotham
    bodyLbl.TextSize                = 11
    bodyLbl.TextXAlignment          = Enum.TextXAlignment.Left
    bodyLbl.ZIndex                  = 52
    bodyLbl.Parent                  = card

    card.Position = UDim2.new(1, 10, 0, 0)
    TweenService:Create(card,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Position = UDim2.new(0, 0, 0, 0) }
    ):Play()

    task.delay(3.5, function()
        if not card.Parent then return end
        TweenService:Create(card,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { Position = UDim2.new(1, 10, 0, 0), BackgroundTransparency = 1 }
        ):Play()
        task.wait(0.35)
        if card.Parent then card:Destroy() end
    end)
end

local vp = workspace.CurrentCamera.ViewportSize

local toggleFrame = Instance.new("Frame")
toggleFrame.Name                   = "SpeedBoostToggle"
toggleFrame.Size                   = UDim2.new(0, CONFIG.ToggleWidth, 0, CONFIG.ToggleHeight)
toggleFrame.Position               = UDim2.new(
    0, math.floor(vp.X * 0.85 - CONFIG.ToggleWidth / 2),
    0, math.floor(vp.Y * 0.15)
)
toggleFrame.BackgroundColor3       = CONFIG.OffColor
toggleFrame.BackgroundTransparency = CONFIG.OffTransparency
toggleFrame.BorderSizePixel        = 0
toggleFrame.Active                 = true
toggleFrame.ZIndex                 = 5
toggleFrame.Parent                 = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, CONFIG.CornerRadius)
uiCorner.Parent = toggleFrame

local stroke = Instance.new("UIStroke")
stroke.Color        = CONFIG.OffStroke
stroke.Transparency = CONFIG.OffStrokeTransparency
stroke.Thickness    = CONFIG.StrokeThickness
stroke.Parent       = toggleFrame

local altGlow = Instance.new("UIStroke")
altGlow.Name         = "AltGlow"
altGlow.Color        = CONFIG.OnGlowColor
altGlow.Transparency = 1
altGlow.Thickness    = 5
altGlow.Parent       = toggleFrame

local textLabel = Instance.new("TextLabel")
textLabel.Name                   = "ToggleText"
textLabel.Size                   = UDim2.new(1, -8, 1, 0)
textLabel.Position               = UDim2.new(0, 8, 0, 0)
textLabel.BackgroundTransparency = 1
textLabel.Text                   = "Speed Boost"
textLabel.TextColor3             = CONFIG.OffTextColor
textLabel.Font                   = CONFIG.Font
textLabel.TextSize               = CONFIG.TextSize
textLabel.TextTransparency       = CONFIG.TextTransparency
textLabel.TextXAlignment         = Enum.TextXAlignment.Center
textLabel.ZIndex                 = 6
textLabel.Parent                 = toggleFrame

local hintLabel = Instance.new("TextLabel")
hintLabel.Name                   = "HintLabel"
hintLabel.Size                   = UDim2.new(1, 0, 0, 14)
hintLabel.Position               = UDim2.new(0, 0, 1, 5)
hintLabel.BackgroundTransparency = 1
hintLabel.TextColor3             = Color3.fromRGB(155, 155, 155)
hintLabel.Font                   = Enum.Font.Gotham
hintLabel.TextSize               = 10
hintLabel.TextTransparency       = 0.2
hintLabel.ZIndex                 = 6
hintLabel.Parent                 = toggleFrame

local statusDot = Instance.new("Frame")
statusDot.Name             = "StatusDot"
statusDot.Size             = UDim2.new(0, 6, 0, 6)
statusDot.Position         = UDim2.new(0, 10, 0.5, -3)
statusDot.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
statusDot.BorderSizePixel  = 0
statusDot.ZIndex           = 6
statusDot.Parent           = toggleFrame

local dotCorner = Instance.new("UICorner")
dotCorner.CornerRadius = UDim.new(1, 0)
dotCorner.Parent = statusDot

local isSpeedBoostOn = false
local isLocked       = false
local isDragging     = false
local mouseIsDown    = false

local mouseDownPos = Vector2.new()

local dragOffsetX = 0
local dragOffsetY = 0

local longPressThread    = nil
local longPressStartTime = 0
local isLongPressing     = false

local pulseTween      = nil
local glowTween       = nil
local bgTween         = nil
local dotColorTween   = nil

local function getKeybindName(keyCode)
    return keyCode.Name
end

local function updateHint()
    hintLabel.Text = string.format("[%s] Toggle  [E+R] Rebind", getKeybindName(currentKeybind))
end

local function stopAllEffects()

    if pulseTween    then pulseTween:Cancel();    pulseTween    = nil end
    if glowTween     then glowTween:Cancel();     glowTween     = nil end
    if bgTween       then bgTween:Cancel();       bgTween       = nil end
    if dotColorTween then dotColorTween:Cancel(); dotColorTween = nil end

    statusDot.Size = UDim2.new(0, 6, 0, 6)
end

local function tweenToggle(state)
    local ti     = TweenInfo.new(CONFIG.TweenDuration, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
    local tiSlow = TweenInfo.new(0.4,                  Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    stopAllEffects()

    if state then

        TweenService:Create(toggleFrame, tiSlow, {
            BackgroundColor3       = CONFIG.OnColor,
            BackgroundTransparency = CONFIG.OnTransparency,
        }):Play()
        TweenService:Create(stroke, tiSlow, {
            Color        = CONFIG.OnStroke,
            Transparency = CONFIG.OnStrokeTransparency,
        }):Play()
        TweenService:Create(textLabel, ti, { TextColor3 = CONFIG.OnTextColor }):Play()

        TweenService:Create(altGlow, ti, { Transparency = 0.6 }):Play()

        TweenService:Create(statusDot, tiSlow, {
            BackgroundColor3 = Color3.fromRGB(0, 255, 120),
            Size             = UDim2.new(0, 9, 0, 9),
        }):Play()

        task.delay(0.45, function()
            if not isSpeedBoostOn then return end

            local pulseInfo = TweenInfo.new(
                0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true
            )
            pulseTween = TweenService:Create(statusDot, pulseInfo, {
                Size = UDim2.new(0, 13, 0, 13),
            })
            pulseTween:Play()

            local colorInfo = TweenInfo.new(
                1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true
            )
            dotColorTween = TweenService:Create(statusDot, colorInfo, {
                BackgroundColor3 = Color3.fromRGB(0, 200, 255),
            })
            dotColorTween:Play()

            local glowInfo = TweenInfo.new(
                1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true
            )
            glowTween = TweenService:Create(altGlow, glowInfo, {
                Transparency = 0.85,
                Thickness    = 7,
            })
            glowTween:Play()

            local bgInfo = TweenInfo.new(
                1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true
            )
            bgTween = TweenService:Create(toggleFrame, bgInfo, {
                BackgroundTransparency = CONFIG.OnTransparency + 0.12,
            })
            bgTween:Play()
        end)

    else

        TweenService:Create(toggleFrame, tiSlow, {
            BackgroundColor3       = CONFIG.OffColor,
            BackgroundTransparency = CONFIG.OffTransparency,
        }):Play()
        TweenService:Create(stroke, tiSlow, {
            Color        = CONFIG.OffStroke,
            Transparency = CONFIG.OffStrokeTransparency,
        }):Play()
        TweenService:Create(textLabel, ti, { TextColor3 = CONFIG.OffTextColor }):Play()

        TweenService:Create(altGlow, tiSlow, {
            Transparency = 1,
            Thickness    = 5,
        }):Play()

        TweenService:Create(statusDot, tiSlow, {
            BackgroundColor3 = Color3.fromRGB(120, 120, 120),
            Size             = UDim2.new(0, 6, 0, 6),
        }):Play()
    end
end

local function getHumanoid()
    local character = player.Character
    if not character then return nil end
    return character:FindFirstChildOfClass("Humanoid")
end

local function applySpeedBoost(enabled)
    local humanoid = getHumanoid()
    if not humanoid then return end

    if enabled then
        if CONFIG.DefaultWalkSpeed == 0 then
            CONFIG.DefaultWalkSpeed = humanoid.WalkSpeed
        end
        humanoid.WalkSpeed = CONFIG.DefaultWalkSpeed * CONFIG.SpeedMultiplier
    else
        if CONFIG.DefaultWalkSpeed ~= 0 then
            humanoid.WalkSpeed = CONFIG.DefaultWalkSpeed
        end
    end
end

local function doToggle()
    isSpeedBoostOn = not isSpeedBoostOn
    tweenToggle(isSpeedBoostOn)
    applySpeedBoost(isSpeedBoostOn)
end

local function showLockFeedback(locked)
    local feedback = Instance.new("TextLabel")
    feedback.Size                   = UDim2.new(1, 0, 0, 20)
    feedback.Position               = UDim2.new(0, 0, 0, -26)
    feedback.BackgroundTransparency = 1
    feedback.Text                   = locked and "Locked" or "Unlocked"
    feedback.TextColor3             = locked
        and Color3.fromRGB(255, 100, 100)
        or  Color3.fromRGB(100, 255, 150)
    feedback.Font                   = Enum.Font.GothamMedium
    feedback.TextSize               = 11
    feedback.TextTransparency       = 1
    feedback.ZIndex                 = 8
    feedback.Parent                 = toggleFrame

    local ti = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(feedback, ti, { TextTransparency = 0 }):Play()
    task.delay(1.3, function()
        TweenService:Create(feedback, ti, { TextTransparency = 1 }):Play()
        task.wait(0.3)
        if feedback.Parent then feedback:Destroy() end
    end)
end

local function cancelLongPress()
    isLongPressing = false
    if longPressThread then
        task.cancel(longPressThread)
        longPressThread = nil
    end
end

local function startLongPress()
    isLongPressing     = true
    longPressStartTime = tick()

    longPressThread = task.delay(CONFIG.LongPressDuration, function()
        if not isLongPressing then return end
        isLongPressing = false

        isLocked = not isLocked
        showLockFeedback(isLocked)

        local basePos   = toggleFrame.Position
        local shakeInfo = TweenInfo.new(0.05, Enum.EasingStyle.Linear)
        for i = 1, 4 do
            local ox = (i % 2 == 0) and 3 or -3
            TweenService:Create(toggleFrame, shakeInfo, {
                Position = UDim2.new(0, basePos.X.Offset + ox, 0, basePos.Y.Offset)
            }):Play()
            task.wait(0.055)
        end
        TweenService:Create(toggleFrame, shakeInfo, { Position = basePos }):Play()
    end)
end

local function startDrag(inputPos)
    if isLocked then return end
    isDragging  = true

    dragOffsetX = inputPos.X - toggleFrame.Position.X.Offset
    dragOffsetY = inputPos.Y - toggleFrame.Position.Y.Offset
end

local function updateDrag(inputPos)
    if not isDragging then return end

    local newX = inputPos.X - dragOffsetX
    local newY = inputPos.Y - dragOffsetY

    local vpSize = workspace.CurrentCamera.ViewportSize
    local size   = toggleFrame.AbsoluteSize
    newX = math.clamp(newX, 0, vpSize.X - size.X)
    newY = math.clamp(newY, 0, vpSize.Y - size.Y)

    toggleFrame.Position = UDim2.new(0, newX, 0, newY)
end

local function endDrag()
    isDragging = false
end

toggleFrame.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
    and input.UserInputType ~= Enum.UserInputType.Touch then return end

    mouseIsDown  = true
    mouseDownPos = Vector2.new(input.Position.X, input.Position.Y)
    startLongPress()
end)

toggleFrame.InputChanged:Connect(function(input)
    if not mouseIsDown then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement
    and input.UserInputType ~= Enum.UserInputType.Touch then return end

    local moved = (Vector2.new(input.Position.X, input.Position.Y) - mouseDownPos).Magnitude

    if isLongPressing and moved > 12 then
        cancelLongPress()
        startDrag(input.Position)
    end

    updateDrag(input.Position)
end)

toggleFrame.InputEnded:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
    and input.UserInputType ~= Enum.UserInputType.Touch then return end

    mouseIsDown = false

    if isLongPressing then
        local duration = tick() - longPressStartTime
        cancelLongPress()
        if duration < CONFIG.LongPressDuration and not isDragging then
            doToggle()
        end
    end

    endDrag()
end)

UserInputService.InputChanged:Connect(function(input)
    if not isDragging then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement
    and input.UserInputType ~= Enum.UserInputType.Touch then return end
    updateDrag(input.Position)
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
    and input.UserInputType ~= Enum.UserInputType.Touch then return end
    if not mouseIsDown and not isDragging then return end
    mouseIsDown = false
    cancelLongPress()
    endDrag()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

    if input.KeyCode == Enum.KeyCode.E then eHeld = true end
    if input.KeyCode == Enum.KeyCode.R then rHeld = true end

    if isRebinding then
        if input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.R then return end
        currentKeybind = input.KeyCode
        isRebinding    = false
        updateHint()
        notify(
            "Keybind Updated",
            string.format("Toggle key set to [%s]", getKeybindName(currentKeybind)),
            Color3.fromRGB(100, 220, 120)
        )
        return
    end

    if eHeld and rHeld and not isRebinding then
        isRebinding = true
        notify(
            "Rebind Mode",
            "Press any key to set as new toggle keybind",
            Color3.fromRGB(255, 200, 60)
        )
        return
    end

    if input.KeyCode == currentKeybind then
        doToggle()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if input.KeyCode == Enum.KeyCode.E then eHeld = false end
    if input.KeyCode == Enum.KeyCode.R then rHeld = false end
end)

player.CharacterAdded:Connect(function()
    CONFIG.DefaultWalkSpeed = 0
    task.wait(0.5)
    if isSpeedBoostOn then
        applySpeedBoost(true)
    end
end)

updateHint()

toggleFrame.Size                   = UDim2.new(0, 0, 0, 0)
toggleFrame.BackgroundTransparency = 1
textLabel.TextTransparency         = 1

TweenService:Create(toggleFrame,
    TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size                   = UDim2.new(0, CONFIG.ToggleWidth, 0, CONFIG.ToggleHeight),
        BackgroundTransparency = CONFIG.OffTransparency,
    }
):Play()

TweenService:Create(textLabel,
    TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.2), {
        TextTransparency = CONFIG.TextTransparency,
    }
):Play()

task.delay(0.7, function()
    notify(
        "Speed Boost Ready",
        string.format("[%s] Toggle | [E+R] Rebind | Hold to Lock", getKeybindName(currentKeybind)),
        Color3.fromRGB(0, 180, 255)
    )
end)

print("Speed Boost UI loaded — keybind: " .. getKeybindName(currentKeybind) .. " | multiplier: x" .. CONFIG.SpeedMultiplier)
