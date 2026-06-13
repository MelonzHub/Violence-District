local module = {}

----------------------------------------------------------------
-- SERVICES
----------------------------------------------------------------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

----------------------------------------------------------------
-- SHORTCUTS
----------------------------------------------------------------

local t_insert = table.insert
local t_remove = table.remove
local s_format = string.format
local m_floor = math.floor
local v3 = Vector3.new

----------------------------------------------------------------
-- ESP COLORS
----------------------------------------------------------------

module.ESP_COLORS = {
    Killer = Color3.fromRGB(255, 93, 108),
    Survivor = Color3.fromRGB(0, 255, 34),
    Generator = Color3.fromRGB(200, 100, 0),
    Gate = Color3.fromRGB(255, 255, 255),
    Pallet = Color3.fromRGB(53, 189, 166),
    Hook = Color3.fromRGB(252, 116, 116)
}
module.GEN_COLOR_MID =
    Color3.fromRGB(255,140,0)

module.GEN_COLOR_END =
    Color3.fromRGB(0,255,120)
module.MaskNames = {
    ["Abysswalker"] = "ABYSSWALKER",
    ["Cure"] = "CURE",
    ["Hidden"] = "HIDDEN",
    ["Killer"] = "THE KILLER",
    ["Masked"] = "PALA AYAM",
    ["Stalker"] = "STALKER",
    ["Veil"] = "VEIL",
    ["Slasher"] = "SLASHER",
}

module.MaskColors = {
    ["Abysswalker"] = Color3.fromRGB(110, 20, 255),
    ["Cure"] = Color3.fromRGB(0, 54, 156),
    ["Hidden"] = Color3.fromRGB(170, 170, 170),
    ["Killer"] = Color3.fromRGB(255, 40, 40),
    ["Masked"] = Color3.fromRGB(255, 90, 20),
    ["Stalker"] = Color3.fromRGB(255, 0, 140),
    ["Veil"] = Color3.fromRGB(0, 140, 255),
    ["Slasher"] = Color3.fromRGB(180, 0, 255),
}

----------------------------------------------------------------
-- CACHE
----------------------------------------------------------------

module.CachedMapObjects = {
    Generators = {},
    Pallets = {},
    Hooks = {},
    Gates = {}
}

module.PrevESPState = {
    Generator = false,
    Hook = false,
    Pallet = false,
    Gate = false
}

module.ESP_PlayerCache = {}
module.SCPESPCache = {}
module.SCPConnections = {}
----------------------------------------------------------------
-- FLAGS
----------------------------------------------------------------

getgenv().ESP_Survivor_Name = false
getgenv().ESP_Survivor_Highlight = false
getgenv().ESP_Killer_Name = false
getgenv().ESP_Killer_Highlight = false
getgenv().ESP_Generator = false
getgenv().ESP_Gate = false
getgenv().ESP_Pallet = false
getgenv().ESP_Hook = false
getgenv().ESP_SCP = false

----------------------------------------------------------------
-- UI FOLDER
----------------------------------------------------------------

module.ESP_UI_Folder =
    PlayerGui:FindFirstChild("FORKT_ESP_UI")
    or Instance.new("ScreenGui")

module.ESP_UI_Folder.Name = "FORKT_ESP_UI"
module.ESP_UI_Folder.ResetOnSpawn = false
module.ESP_UI_Folder.IgnoreGuiInset = true
module.ESP_UI_Folder.Parent = PlayerGui

module.ESP_3D_Folder =
    workspace.CurrentCamera:FindFirstChild("FORKT_ESP_3D")
    or Instance.new("Folder")

module.ESP_3D_Folder.Name = "FORKT_ESP_3D"
module.ESP_3D_Folder.Parent = workspace.CurrentCamera

----------------------------------------------------------------
-- UTILITIES
----------------------------------------------------------------

function module.GetGameValue(obj, name)
    if typeof(obj) ~= "Instance" then
        return nil
    end

    local attr = obj:GetAttribute(name)
    if attr ~= nil then
        return attr
    end

    local child = obj:FindFirstChild(name)
    return child and child:IsA("ValueBase") and child.Value or nil
end

----------------------------------------------------------------
-- BILLBOARD
----------------------------------------------------------------

function module.CreateBillboardTag(text, color, size, textSize)

    local billboard = Instance.new("BillboardGui")

    billboard.Name = "TagESP"
    billboard.AlwaysOnTop = true
    billboard.Size = size or UDim2.new(0,150,0,40)
    billboard.LightInfluence = 0

    local label = Instance.new("TextLabel")

    label.Name = "Label"
    label.Size = UDim2.new(1,0,1,0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color
    label.Font = Enum.Font.GothamBold
    label.TextSize = textSize or 12
    label.RichText = true

    local stroke = Instance.new("UIStroke")

    stroke.Thickness = 1.2
    stroke.Color = Color3.new(0,0,0)
    stroke.Transparency = 0.2
    stroke.Parent = label

    label.Parent = billboard

    return billboard
end

----------------------------------------------------------------
-- HIGHLIGHT
----------------------------------------------------------------
function module.ApplyHighlight(object, color)
    local h = object:FindFirstChild("H")

    if not h then
        h = Instance.new("Highlight")
        h.Name = "H"
        h.Adornee = object
        h.FillTransparency = 0.8
        h.OutlineTransparency = 0.5
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = object
    end

    h.FillColor = color
    h.OutlineColor = color
    h.Enabled = true
end

function module.RemoveHighlight(object)
    local h = object and object:FindFirstChild("H")
    if h then
        h:Destroy()
    end
end
----------------------------------------------------------------
-- SCP HELPERS
----------------------------------------------------------------

function module.IsSCP(obj)

    if not obj or not obj:IsA("Model") then
        return false
    end

    local n = obj.Name:lower()

    return n == "scp" or n:match("^scp%d*$")
        or n:find("zombie")
        or n:find("monster")
        or n:find("creature")
end

----------------------------------------------------------------
-- REMOVE SCP ESP
----------------------------------------------------------------

function module.RemoveSCPESP(model)

    local esp =
        module.SCPESPCache[model]

    if esp then

        pcall(function()
            esp:Destroy()
        end)
    end

    module.SCPESPCache[model] = nil

    local conn =
        module.SCPConnections[model]

    if conn then
        conn:Disconnect()
        module.SCPConnections[model] = nil
    end
end

----------------------------------------------------------------
-- GET ADORNEE
----------------------------------------------------------------

function module.GetAdornee(model)

    if model.PrimaryPart then
        return model
    end

    local part =
        model:FindFirstChild(
            "HumanoidRootPart",
            true
        )
        or model:FindFirstChildWhichIsA(
            "BasePart",
            true
        )

    return part and model or nil
end

----------------------------------------------------------------
-- CREATE SCP ESP
----------------------------------------------------------------

function module.CreateSCPESP(model)

    if not getgenv().ESP_SCP
    or module.SCPESPCache[model]
    or not model.Parent then
        return
    end

    local adornee =
        module.GetAdornee(model)

    if not adornee then
        return
    end

    local hl = Instance.new("Highlight")

    hl.Name = "SCPESP"
    hl.Adornee = model

    hl.FillColor =
        Color3.fromRGB(170,0,255)

    hl.OutlineColor =
        Color3.fromRGB(220,170,255)

    hl.FillTransparency = 0.45
    hl.OutlineTransparency = 0

    hl.DepthMode =
        Enum.HighlightDepthMode.AlwaysOnTop

    hl.Parent =
        module.ESP_3D_Folder

    module.SCPESPCache[model] = hl

    module.SCPConnections[model] =
        model.AncestryChanged:Connect(function(_,parent)

            if not parent then
                module.RemoveSCPESP(model)
            end
        end)
end

----------------------------------------------------------------
-- SCAN SCP
----------------------------------------------------------------

function module.ScanSCP()

    local map =
        workspace:FindFirstChild("Map")

    if not map then
        return
    end

    for _,obj in ipairs(
        map:GetDescendants()
    ) do

        if module.IsSCP(obj) then
            module.CreateSCPESP(obj)
        end
    end
end
----------------------------------------------------------------
-- MAP CACHE
----------------------------------------------------------------

function module.UpdateMapCache()

    local map = workspace:FindFirstChild("Map")

    if not map then
        return
    end

    module.CachedMapObjects.Generators = {}
    module.CachedMapObjects.Pallets = {}
    module.CachedMapObjects.Hooks = {}
    module.CachedMapObjects.Gates = {}

    local descendants = map:GetDescendants()

    for i = 1,#descendants do

        local obj = descendants[i]
        local n = obj.Name

        if n == "Generator" then

            t_insert(module.CachedMapObjects.Generators,obj)

        elseif n == "Hook" then

            t_insert(module.CachedMapObjects.Hooks,obj)

        elseif n == "Gate" then

            t_insert(module.CachedMapObjects.Gates,obj)

        elseif n == "Pallet"
        or n == "Palletwrong" then

            t_insert(module.CachedMapObjects.Pallets,obj)
        end

        if i % 500 == 0 then
            task.wait()
        end
    end

    module.PrevESPState.Generator = false
    module.PrevESPState.Hook = false
    module.PrevESPState.Pallet = false
    module.PrevESPState.Gate = false
end

----------------------------------------------------------------
-- PLAYER ESP
----------------------------------------------------------------

function module.RemovePlayerESP(player)

    local char = player.Character

    if char then

        module.RemoveHighlight(char)

        local root =
            char:FindFirstChild("HumanoidRootPart")

        local bg =
            root
            and root:FindFirstChild("TagESP")

        if bg then
            bg:Destroy()
        end
    end
end

function module.CreatePlayerESP(player,isKiller)

    local char = player.Character

    local root =
        char
        and char:FindFirstChild("HumanoidRootPart")

    local hum =
        char
        and char:FindFirstChild("Humanoid")

    if not root
    or not hum
    or hum.Health <= 0 then

        module.RemovePlayerESP(player)

        module.ESP_PlayerCache[player.UserId] = nil

        return
    end

    local myChar =
        LocalPlayer.Character

    local myRoot =
        myChar
        and myChar:FindFirstChild(
            "HumanoidRootPart"
        )

    if not myRoot then
        return
    end

    ------------------------------------------------
    -- DIST
    ------------------------------------------------

    local dist = floor((root.Position - myRoot.Position).Magnitude)

    local color =
        isKiller
        and module.ESP_COLORS.Killer
        or module.ESP_COLORS.Survivor

    local statusText = ""
    local bottomText = ""

    ------------------------------------------------
    -- KILLER STATUS
    ------------------------------------------------

    if isKiller then

        local detectedMask =
            char:GetAttribute("CachedMask")
            or char:GetAttribute("KillerType")
            or char:GetAttribute("SelectedKiller")
            or module.GetGameValue(
                char,
                "SelectedKiller"
            )
            or module.GetGameValue(
                player,
                "SelectedKiller"
            )
            or module.GetGameValue(
                char,
                "Mask"
            )
            or module.GetGameValue(
                player,
                "Mask"
            )
            or char.Name

        if detectedMask then

            char:SetAttribute(
                "CachedMask",
                detectedMask
            )

            statusText =
                module.MaskNames[detectedMask]
                or "KILLER"

            color =
                module.MaskColors[detectedMask]
                or color

        else

            statusText = "KILLER"
        end

    else

        local function IsActive(v)

            return
                v == true
                or (
                    type(v) == "number"
                    and v > 0
                )
        end

        local isHooked =
            IsActive(
                module.GetGameValue(
                    char,
                    "IsHooked"
                )
            )
            or IsActive(
                module.GetGameValue(
                    player,
                    "IsHooked"
                )
            )

        local isCarried =
            IsActive(
                module.GetGameValue(
                    char,
                    "Carried"
                )
            )
            or IsActive(
                module.GetGameValue(
                    char,
                    "IsCarried"
                )
            )
            or IsActive(
                module.GetGameValue(
                    char,
                    "Grabbed"
                )
            )
            or IsActive(
                module.GetGameValue(
                    player,
                    "Carried"
                )
            )

        local isKnocked =
            IsActive(
                module.GetGameValue(
                    char,
                    "Knocked"
                )
            )
            or IsActive(
                module.GetGameValue(
                    char,
                    "IsKnocked"
                )
            )

        if isHooked then

            color =
                Color3.fromRGB(
                    255,
                    75,
                    147
                )

            statusText = "HOOKED"

        elseif isCarried then

            color =
                Color3.fromRGB(
                    200,
                    75,
                    255
                )

            statusText = "CARRIED"

        elseif isKnocked then

            color =
                Color3.fromRGB(
                    255,
                    150,
                    0
                )

            statusText = "KNOCKED"

        elseif hum.Health < hum.MaxHealth then

            color =
                Color3.fromRGB(
                    255,
                    220,
                    50
                )

            statusText = "INJURED"

        else

            statusText = "IDLE"
        end
    end

    ------------------------------------------------
    -- TEXT FORMAT
    ------------------------------------------------

    if isKiller then

        bottomText =
            s_format(
                '<font color="#DDDDDD">%dm</font> | <font color="#%s">[%s]</font>',
                dist,
                color:ToHex(),
                string.upper(statusText)
            )

    else

        if statusText == "IDLE" then

            bottomText =
                s_format(
                    '<font color="#DDDDDD">%dm</font>',
                    dist
                )

        else

            bottomText =
                s_format(
                    '<font color="#DDDDDD">%dm</font> | <font color="#%s">%s</font>',
                    dist,
                    color:ToHex(),
                    statusText
                )
        end
    end

    ------------------------------------------------
    -- CACHE
    ------------------------------------------------

    module.ESP_PlayerCache[player.UserId] = {
        dist = dist,
        status = statusText
    }

    ------------------------------------------------
    -- FINAL TEXT
    ------------------------------------------------

    local finalName =
        s_format(
            "<b>%s</b>\n%s",
            player.Name,
            bottomText
        )

    local showName =
        isKiller
        and getgenv().ESP_Killer_Name
        or (
            not isKiller
            and getgenv().ESP_Survivor_Name
        )

    local showHighlight =
        isKiller
        and getgenv().ESP_Killer_Highlight
        or (
            not isKiller
            and getgenv().ESP_Survivor_Highlight
        )

    ------------------------------------------------
    -- HIGHLIGHT
    ------------------------------------------------

    if showHighlight then
        module.ApplyHighlight(
            char,
            color
        )
    else
        module.RemoveHighlight(char)
    end

    ------------------------------------------------
    -- BILLBOARD
    ------------------------------------------------

    local bg =
        root:FindFirstChild("TagESP")

    if showName then

        if not bg then

            bg = Instance.new("BillboardGui")

            bg.Name = "TagESP"
            bg.Adornee = root
            bg.Parent = root

            bg.AlwaysOnTop = true

            bg.Size =
                UDim2.new(
                    0,
                    150,
                    0,
                    35
                )

            bg.StudsOffset =
                v3(0,4.5,0)

            bg.MaxDistance = 2000
            bg.ResetOnSpawn = false

            local lbl =
                Instance.new("TextLabel")

            lbl.Name = "Label"
            lbl.Parent = bg

            lbl.BackgroundTransparency = 1

            lbl.Size =
                UDim2.new(
                    1,
                    0,
                    1,
                    0
                )

            lbl.Font =
                Enum.Font.GothamBold

            lbl.TextScaled = true
            lbl.RichText = true

            lbl.Text = finalName

            lbl.TextColor3 = color

            lbl.TextYAlignment =
                Enum.TextYAlignment.Bottom

            local constraint =
                Instance.new(
                    "UITextSizeConstraint",
                    lbl
                )

            constraint.MaxTextSize = 7
            constraint.MinTextSize = 5

            local stroke =
                Instance.new(
                    "UIStroke",
                    lbl
                )

            stroke.Thickness = 1.5

            stroke.Color =
                Color3.fromRGB(
                    10,
                    10,
                    10
                )

            stroke.Transparency = 0.3

            stroke.LineJoinMode =
                Enum.LineJoinMode.Round

        else

            local lbl =
                bg:FindFirstChild("Label")

            if lbl
            and lbl.Text ~= finalName then

                lbl.Text = finalName
                lbl.TextColor3 = color
            end
        end

    else

        if bg then
            bg:Destroy()
        end
    end
end
----------------------------------------------------------------
-- REFRESH ESP
----------------------------------------------------------------

function module.RefreshESP()

    if not workspace.CurrentCamera then
        return
    end

    if #Players:GetPlayers() <= 1 then
        return
    end

    ------------------------------------------------
    -- PLAYER ESP
    ------------------------------------------------

    local players =
        Players:GetPlayers()

    for _,p in ipairs(players) do

        if p ~= LocalPlayer then

            local team = p.Team
            local isKiller = false

            if team
            and team.Name then

                isKiller =
                    string.find(
                        string.lower(team.Name),
                        "killer"
                    ) ~= nil
            end

            local shouldESP = false

            if isKiller
            and (
                getgenv().ESP_Killer_Name
                or getgenv().ESP_Killer_Highlight
            ) then

                shouldESP = true

            elseif not isKiller
            and (
                getgenv().ESP_Survivor_Name
                or getgenv().ESP_Survivor_Highlight
            ) then

                shouldESP = true
            end

            if shouldESP then

                module.CreatePlayerESP(
                    p,
                    isKiller
                )

            else

                module.RemovePlayerESP(p)
            end
        end
    end

    ------------------------------------------------
    -- CACHE CHECK
    ------------------------------------------------

    if not module.CachedMapObjects then
        return
    end

    ------------------------------------------------
    -- GENERATOR ESP
    ------------------------------------------------

    if getgenv().ESP_Generator then

        if not module.PrevESPState.Generator then
            module.PrevESPState.Generator = true
        end

        local gens =
            module.CachedMapObjects.Generators

        local newActiveGens = {}

        for i = 1,#gens do

            local obj = gens[i]

            if obj
            and obj.Parent then

                local isFinished =
                    module.updateGeneratorProgress(
                        obj
                    )

                if not isFinished then

                    t_insert(
                        newActiveGens,
                        obj
                    )
                end
            end
        end

        module.CachedMapObjects.Generators =
            newActiveGens

        module.ActiveGenerators = newActiveGens

    elseif module.PrevESPState.Generator then

        local gens =
            module.CachedMapObjects.Generators

        for _,obj in ipairs(gens) do

            if obj
            and obj.Parent then

                module.RemoveHighlight(obj)

                local b =
                    obj:FindFirstChild(
                        "GenBitchHook"
                    )

                if b then
                    b:Destroy()
                end

                if obj:GetAttribute(
                    "LastESPPercent"
                ) then

                    obj:SetAttribute(
                        "LastESPPercent",
                        nil
                    )
                end
            end
        end

        module.PrevESPState.Generator = false
    end

    ------------------------------------------------
    -- PALLET ESP
    ------------------------------------------------

    if getgenv().ESP_Pallet then

        if not module.PrevESPState.Pallet then
            module.PrevESPState.Pallet = true
        end

        local pallets =
            module.CachedMapObjects.Pallets

        local MAX_DISTANCE = 140

        for i = #pallets,1,-1 do

            local pallet =
                pallets[i]

            local isValid =
                pallet
                and pallet.Parent
                and pallet:IsDescendantOf(
                    workspace
                )

            if isValid then

                local targetPart =
                    (
                        pallet:IsA("Model")
                        and pallet.PrimaryPart
                    )
                    or pallet:FindFirstChildWhichIsA(
                        "BasePart",
                        true
                    )
                    or (
                        pallet:IsA("BasePart")
                        and pallet
                    )

                local hasVisibleParts = false

                if targetPart then

                    if pallet:IsA("BasePart") then

                        hasVisibleParts =
                            pallet.Transparency < 1

                    else

                        local parts =
                            pallet:GetDescendants()

                        for j = 1,#parts do

                            local p =
                                parts[j]

                            if p:IsA("BasePart")
                            and p.Transparency < 1 then

                                hasVisibleParts = true
                                break
                            end
                        end
                    end
                end

                local nLower =
                    string.lower(
                        pallet.Name
                    )

                local function IsActive(val)

                    return
                        val == true
                        or (
                            type(val) == "number"
                            and val > 0
                        )
                end

                local isDropped =
                    IsActive(
                        module.GetGameValue(
                            pallet,
                            "Dropped"
                        )
                    )
                    or IsActive(
                        module.GetGameValue(
                            pallet,
                            "IsDropped"
                        )
                    )

                local isBroken =
                    IsActive(
                        module.GetGameValue(
                            pallet,
                            "Broken"
                        )
                    )
                    or IsActive(
                        module.GetGameValue(
                            pallet,
                            "IsBroken"
                        )
                    )
                    or IsActive(
                        module.GetGameValue(
                            pallet,
                            "Destroyed"
                        )
                    )

                local isFake =
                    string.find(
                        nLower,
                        "fake"
                    )
                    or string.find(
                        nLower,
                        "broken"
                    )
                    or string.find(
                        nLower,
                        "destroyed"
                    )

                if isDropped
                or isBroken
                or isFake
                or not hasVisibleParts
                or not targetPart then

                    local tag =
                        pallet:FindFirstChild(
                            "PalletTag"
                        )

                    if tag then
                        tag:Destroy()
                    end

                    if isDropped
                    or isBroken
                    or isFake then

                        t_remove(
                            pallets,
                            i
                        )
                    end

                else

                    local tag =
                        pallet:FindFirstChild(
                            "PalletTag"
                        )

                    if not tag then

                        local b =
                            module.CreateBillboardTag(
                                "<b>[PALLET]</b>",
                                module.ESP_COLORS.Pallet,
                                UDim2.new(
                                    0,
                                    50,
                                    0,
                                    18
                                ),
                                6
                            )

                        b.Name = "PalletTag"

                        b.Parent = pallet

                        b.Adornee =
                            targetPart

                        b.MaxDistance =
                            MAX_DISTANCE

                    else

                        if not tag.Adornee then
                            tag.Adornee =
                                targetPart
                        end

                        local lbl =
                            tag:FindFirstChild(
                                "Label"
                            )

                        if lbl
                        and lbl.TextColor3
                        ~= module.ESP_COLORS.Pallet then

                            lbl.TextColor3 =
                                module.ESP_COLORS.Pallet
                        end
                    end
                end

            else

                if pallet then

                    local tag =
                        pallet:FindFirstChild(
                            "PalletTag"
                        )

                    if tag then
                        tag:Destroy()
                    end
                end

                t_remove(
                    pallets,
                    i
                )
            end
        end

    elseif module.PrevESPState.Pallet then

        for _,pallet in ipairs(
            module.CachedMapObjects.Pallets
        ) do

            if pallet then

                local tag =
                    pallet:FindFirstChild(
                        "PalletTag"
                    )

                if tag then
                    tag:Destroy()
                end
            end
        end

        module.PrevESPState.Pallet = false
    end

    ------------------------------------------------
    -- GATE ESP
    ------------------------------------------------

    if getgenv().ESP_Gate then

        if not module.PrevESPState.Gate then
            module.PrevESPState.Gate = true
        end

        local gates =
            module.CachedMapObjects.Gates

        for i = #gates,1,-1 do

            local gate =
                gates[i]

            if gate
            and gate.Parent then

                module.ApplyHighlight(
                    gate,
                    module.ESP_COLORS.Gate
                )

            else

                t_remove(
                    gates,
                    i
                )
            end
        end

    elseif module.PrevESPState.Gate then

        for _,gate in ipairs(
            module.CachedMapObjects.Gates
        ) do

            if gate
            and gate.Parent then

                module.RemoveHighlight(gate)
            end
        end

        module.PrevESPState.Gate = false
    end

    ------------------------------------------------
    -- HOOK ESP
    ------------------------------------------------

    if getgenv().ESP_Hook then

        if not module.PrevESPState.Hook then
            module.PrevESPState.Hook = true
        end

        local hooks =
            module.CachedMapObjects.Hooks

        for i = #hooks,1,-1 do

            local hook =
                hooks[i]

            if hook
            and hook.Parent then

                local m =
                    hook:FindFirstChild(
                        "Model"
                    )

                if m then

                    for _,p in ipairs(
                        m:GetDescendants()
                    ) do

                        if p:IsA("MeshPart") then

                            module.ApplyHighlight(
                                p,
                                module.ESP_COLORS.Hook
                            )
                        end
                    end

                else

                    module.ApplyHighlight(
                        hook,
                        module.ESP_COLORS.Hook
                    )
                end

            else

                t_remove(
                    hooks,
                    i
                )
            end
        end

    elseif module.PrevESPState.Hook then

        for _,hook in ipairs(
            module.CachedMapObjects.Hooks
        ) do

            if hook
            and hook.Parent then

                local m =
                    hook:FindFirstChild(
                        "Model"
                    )

                if m then

                    for _,p in ipairs(
                        m:GetDescendants()
                    ) do

                        if p:IsA("MeshPart") then
                            module.RemoveHighlight(p)
                        end
                    end

                else

                    module.RemoveHighlight(hook)
                end
            end
        end

        module.PrevESPState.Hook = false
    end
end
----------------------------------------------------------------
-- GENERATOR PROGRESS
----------------------------------------------------------------

function module.updateGeneratorProgress(generator)

    if not generator
    or not generator.Parent then
        return true
    end

    local percent =
        module.GetGameValue(
            generator,
            "RepairProgress"
        )
        or module.GetGameValue(
            generator,
            "Progress"
        )
        or 0

    local billboard =
        generator:FindFirstChild(
            "GenBitchHook"
        )

    ------------------------------------------------
    -- REMOVE IF DONE
    ------------------------------------------------

    if percent >= 100
    or not getgenv().ESP_Generator then

        if billboard then
            billboard:Destroy()
        end

        module.RemoveHighlight(generator)

        generator:SetAttribute(
            "LastESPPercent",
            nil
        )

        return (
            percent >= 100
        )
    end

    ------------------------------------------------
    -- CACHE
    ------------------------------------------------

    local roundedPercent =
        math.floor(percent * 10) / 10

    local lastPercent =
        generator:GetAttribute(
            "LastESPPercent"
        )

    if lastPercent == roundedPercent
    and billboard then
        return false
    end

    generator:SetAttribute(
        "LastESPPercent",
        roundedPercent
    )

    ------------------------------------------------
    -- COLOR TRANSITION
    ------------------------------------------------

    local cp =
        math.clamp(
            percent,
            0,
            100
        )

    local finalColor =
        (
            cp < 50
        )
        and module.ESP_COLORS.Generator:Lerp(
            module.GEN_COLOR_MID,
            cp / 50
        )
        or module.GEN_COLOR_MID:Lerp(
            module.GEN_COLOR_END,
            (cp - 50) / 50
        )

    module.ApplyHighlight(
        generator,
        finalColor
    )

    local percentStr =
        s_format(
            "%.1f%%",
            roundedPercent
        )

    ------------------------------------------------
    -- TARGET PART
    ------------------------------------------------

    local targetPart =
        generator:FindFirstChild(
            "defaultMaterial",
            true
        )
        or (
            generator:IsA("Model")
            and generator.PrimaryPart
        )
        or generator:FindFirstChildWhichIsA(
            "BasePart",
            true
        )

    if not targetPart then
        return false
    end

    ------------------------------------------------
    -- CREATE BILLBOARD
    ------------------------------------------------

    if not billboard then

        billboard =
            Instance.new(
                "BillboardGui"
            )

        billboard.Name =
            "GenBitchHook"

        billboard.Parent =
            generator

        billboard.Adornee =
            targetPart

        billboard.AlwaysOnTop = true
        billboard.LightInfluence = 0
        billboard.ResetOnSpawn = false

        billboard.MaxDistance = 260

        billboard.Size =
            UDim2.new(
                0,
                140,
                0,
                28
            )

        billboard.StudsOffset =
            v3(0,3.1,0)

        local lbl =
            Instance.new(
                "TextLabel"
            )

        lbl.Name = "Label"
        lbl.Parent = billboard

        lbl.BackgroundTransparency = 1

        lbl.Size =
            UDim2.fromScale(1,1)

        lbl.TextScaled = false
        lbl.TextWrapped = false

        lbl.TextXAlignment =
            Enum.TextXAlignment.Center

        lbl.TextYAlignment =
            Enum.TextYAlignment.Center

        lbl.Font =
            Enum.Font.GothamBold

        lbl.TextSize = 8
        lbl.RichText = false

        lbl.Text = percentStr

        lbl.TextColor3 =
            finalColor

        local stroke =
            Instance.new(
                "UIStroke"
            )

        stroke.Parent = lbl

        stroke.ApplyStrokeMode =
            Enum.ApplyStrokeMode.Contextual

        stroke.Thickness = 1.1
        stroke.Transparency = 0.25

        stroke.Color =
            Color3.new(0,0,0)

        local constraint =
            Instance.new(
                "UITextSizeConstraint"
            )

        constraint.Parent = lbl

        constraint.MaxTextSize = 8
        constraint.MinTextSize = 6

    else

        local lbl =
            billboard:FindFirstChild(
                "Label"
            )

        if lbl then

            lbl.Text =
                percentStr

            lbl.TextColor3 =
                finalColor
        end
    end

    return false
end
----------------------------------------------------------------
-- AUTO LOOP
----------------------------------------------------------------

task.spawn(function()

    while task.wait(1) do

        if getgenv().FORKT_RUNNING == false then
            break
        end
        ------------------------------------------------
        -- SCP REFRESH
        ------------------------------------------------
        
        if not getgenv().ESP_SCP then
        
            for model in pairs(
                module.SCPESPCache
            ) do
        
                module.RemoveSCPESP(model)
            end
        
        else
        
            for model,esp in pairs(
                module.SCPESPCache
            ) do
        
                if not model
                or not model.Parent
                or not esp
                or not esp.Parent then
        
                    module.RemoveSCPESP(model)
        
                elseif not esp.Adornee then
        
                    esp.Adornee = model
                end
            end
        
            module.ScanSCP()
        end
        pcall(module.RefreshESP)
    end
end)
----------------------------------------------------------------
-- INITIAL SCAN
----------------------------------------------------------------

module.ScanSCP()

----------------------------------------------------------------
-- REALTIME DETECT
----------------------------------------------------------------

local map =
    workspace:FindFirstChild("Map")

if map then

    map.DescendantAdded:Connect(function(obj)

        if module.IsSCP(obj) then

            task.wait(0.2)

            module.CreateSCPESP(obj)
        end
    end)
end
return module
