- ================================
-- VIOLENCE DISTRICT SCRIPT HUB
-- ================================

print("Script loading...")

local WindUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
))()

print("WindUI loaded!")

local ESP = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/MelonzHub/Violence-District/refs/heads/main/esp.lua"
))()

print("ESP loaded!")

-- ================================
-- WINDOW
-- ================================

local Window = WindUI:CreateWindow({
    Title = "Violence District",
    Icon = "sword",
    Author = "Melonz",
    Folder = "VDScript",
    Size = UDim2.fromOffset(580, 460),
    Transparent = true,
    Theme = "Dark",
})

-- ================================
-- TAB: PLAYER
-- ================================

local TabPlayer = Window:Tab({
    Title = "Player",
    Icon = "user",
})

local SecPlayer = TabPlayer:Section({
    Title = "Player Settings",
})

SecPlayer:Toggle({
    Title = "God Mode",
    Description = "HP tidak berkurang",
    Default = false,
    Callback = function(on)
        local char = game.Players.LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                hum.MaxHealth = on and math.huge or 100
                hum.Health = on and math.huge or 100
            end
        end
    end,
})

SecPlayer:Slider({
    Title = "WalkSpeed",
    Default = 16,
    Min = 16,
    Max = 150,
    Rounding = 0,
    Callback = function(val)
        local char = game.Players.LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then hum.WalkSpeed = val end
        end
    end,
})

SecPlayer:Slider({
    Title = "JumpPower",
    Default = 50,
    Min = 50,
    Max = 300,
    Rounding = 0,
    Callback = function(val)
        local char = game.Players.LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then hum.JumpPower = val end
        end
    end,
})

-- ================================
-- TAB: ESP PLAYER
-- ================================

local TabESP = Window:Tab({
    Title = "ESP Player",
    Icon = "eye",
})

local SecSurvivor = TabESP:Section({
    Title = "Survivor",
})

-- Survivor Name
SecSurvivor:Toggle({
    Title = "Survivor Name",
    Description = "Tampilkan nama survivor",
    Default = false,
    Callback = function(on)
        getgenv().ESP_Survivor_Name = on
        ESP.RefreshESP()
    end,
})

-- Survivor Highlight
SecSurvivor:Toggle({
    Title = "Survivor Highlight",
    Description = "Highlight body survivor (hijau)",
    Default = false,
    Callback = function(on)
        getgenv().ESP_Survivor_Highlight = on
        ESP.RefreshESP()
    end,
})

local SecKiller = TabESP:Section({
    Title = "Killer",
})

-- Killer Name
SecKiller:Toggle({
    Title = "Killer Name",
    Description = "Tampilkan nama killer",
    Default = false,
    Callback = function(on)
        getgenv().ESP_Killer_Name = on
        ESP.RefreshESP()
    end,
})

-- Killer Highlight
SecKiller:Toggle({
    Title = "Killer Highlight",
    Description = "Highlight body killer (merah)",
    Default = false,
    Callback = function(on)
        getgenv().ESP_Killer_Highlight = on
        ESP.RefreshESP()
    end,
})

-- ================================
-- TAB: ESP MAP
-- ================================

local TabMap = Window:Tab({
    Title = "ESP Map",
    Icon = "map",
})

local SecMap = TabMap:Section({
    Title = "Objek Map",
})

SecMap:Toggle({
    Title = "Generator ESP",
    Description = "Tampilkan generator + progress %",
    Default = false,
    Callback = function(on)
        getgenv().ESP_Generator = on
        ESP.UpdateMapCache()
    end,
})

SecMap:Toggle({
    Title = "Gate ESP",
    Description = "Tampilkan lokasi pintu keluar",
    Default = false,
    Callback = function(on)
        getgenv().ESP_Gate = on
        ESP.UpdateMapCache()
    end,
})

SecMap:Toggle({
    Title = "Pallet ESP",
    Description = "Tampilkan lokasi pallet",
    Default = false,
    Callback = function(on)
        getgenv().ESP_Pallet = on
        ESP.UpdateMapCache()
    end,
})

SecMap:Toggle({
    Title = "Hook ESP",
    Description = "Tampilkan lokasi hook",
    Default = false,
    Callback = function(on)
        getgenv().ESP_Hook = on
        ESP.UpdateMapCache()
    end,
})

SecMap:Toggle({
    Title = "SCP / Monster ESP",
    Description = "Highlight musuh/monster di map",
    Default = false,
    Callback = function(on)
        getgenv().ESP_SCP = on
        if on then
            ESP.ScanSCP()
        end
    end,
})
