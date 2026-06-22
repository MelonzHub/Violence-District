local RS      = game:GetService("ReplicatedStorage")
local UIS     = game:GetService("UserInputService")
local TS      = game:GetService("TweenService")
local Players = game:GetService("Players")
local pGui    = Players.LocalPlayer:WaitForChild("PlayerGui")

local toggleKey = Enum.KeyCode.U

local currentFOV = 90

_G.FOVChangerConnection = _G.FOVChangerConnection or nil
if _G.FOVChangerConnection then
    _G.FOVChangerConnection:Disconnect()
    _G.FOVChangerConnection = nil
end

local camera = workspace.Camera

local function applyFOV(val)
    currentFOV = val
    camera.FieldOfView = val
    if _G.FOVChangerConnection then _G.FOVChangerConnection:Disconnect() end
    _G.FOVChangerConnection = camera:GetPropertyChangedSignal("FieldOfView"):Connect(function()
        if camera.FieldOfView ~= currentFOV then camera.FieldOfView = currentFOV end
    end)
end

local BG     = Color3.fromRGB( 9,  9, 13)
local PANEL  = Color3.fromRGB(18, 18, 26)
local PANEL2 = Color3.fromRGB(26, 26, 36)
local PANEL3 = Color3.fromRGB(38, 38, 52)
local BORDER = Color3.fromRGB(46, 46, 64)
local SEL    = Color3.fromRGB(54, 54, 74)
local TXT    = Color3.fromRGB(222, 222, 238)
local TXT2   = Color3.fromRGB(128, 128, 150)
local TXT3   = Color3.fromRGB(64,  64,  86)
local OK_C   = Color3.fromRGB(140, 210, 140)
local ERR_C  = Color3.fromRGB(210, 100, 100)

local function nav(root, path)
    local c = root
    for p in path:gmatch("([^%.]+)") do c = c and c:FindFirstChild(p) end
    return c
end

local function swapContent(tgt, src)
    local t = nav(RS,tgt); local s = nav(RS,src)
    if not t or not s then warn("[rg] miss:"..tgt.."/"..src); return false end
    for _,c in pairs(t:GetChildren()) do c:Destroy() end
    for _,c in pairs(s:GetChildren()) do c:Clone().Parent = t end
    return true
end

local function swapLegacy(tgtPath, srcPath)
    local t = nav(RS,tgtPath); local s = nav(RS,srcPath)
    if not t or not s then warn("[rg] miss:"..tgtPath.."/"..srcPath); return false end
    for _,key in ipairs({"Visual","Animation"}) do
        local srcC = s:FindFirstChild(key)
        if srcC then
            pcall(function()
                local old = t:FindFirstChild(key)
                if old then old:Destroy() end
                task.wait(0.05); srcC:Clone().Parent = t
            end)
            task.wait(0.05)
        end
    end
    return true
end

local function corner(p,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 6); c.Parent=p end
local function bdr(p,col)  local s=Instance.new("UIStroke");  s.Color=col or BORDER; s.Thickness=1; s.Parent=p end

local function lbl(txt,fs,col,sz,pos,fa,par)
    local l=Instance.new("TextLabel"); l.Text=txt; l.Font=fa or Enum.Font.Gotham
    l.TextSize=fs; l.TextColor3=col; l.BackgroundTransparency=1
    l.Size=sz; l.Position=pos; l.TextXAlignment=Enum.TextXAlignment.Left
    l.ZIndex=3; l.Parent=par; return l
end

local EMOTES = {
    { n="Rockin Stride", src="Items.Emotes.RockinStride",
      tgts={{ n="Kickback",         p="Items.Emotes.Kickback" },
            { n="CasualSurfing",    p="Items.Emotes.CasualSurfing" },
            { n="FrostDrake",       p="Items.Emotes.FrostDrake" },
            { n="DynastyDrumming",  p="Items.Emotes.DynastyDrumming" }} },
    { n="Zombie Stride", src="Items.Emotes.ZombieStride",
      tgts={{ n="ToyTrainRide", p="Items.Emotes.ToyTrainRide" },
            { n="SolarSlayer",  p="Items.Emotes.SolarSlayer" },
            { n="SwagWalk",     p="Items.Emotes.SwagWalk" }} },
    { n="Broom of Doom", src="Items.Emotes.Broom",
      tgts={{ n="BoldMarch", p="Items.Emotes.BoldMarch" },
            { n="SwagWalk",  p="Items.Emotes.SwagWalk" }} },
    { n="Werewolf Howl", src="Items.Emotes.WerewolfHowl",
      tgts={{ n="Stride",    p="Items.Emotes.Stride" },
            { n="BoldMarch", p="Items.Emotes.BoldMarch" },
            { n="Kickback",  p="Items.Emotes.Kickback" }} },
    { n="RockinStride (LEGACY)", src="Items.Emotes.RockinStride", legacy=true,
      tgts={{ n="SnowmobileCruise", p="Items.Emotes.SnowmobileCruise" },
            { n="Tank",            p="Items.Emotes.Tank" },
            { n="Rocket",          p="Items.Emotes.Rocket" }} },
    { n="BroomOfDoom (LEGACY)", src="Items.Emotes.Broom", legacy=true,
      tgts={{ n="SnowmobileCruise", p="Items.Emotes.SnowmobileCruise" },
            { n="HarpRecital",     p="Items.Emotes.HarpRecital" },
            { n="AngelicWings",    p="Items.Emotes.AngelicWings" }} },
    { n="WerewolfHowl (LEGACY)", src="Items.Emotes.WerewolfHowl", legacy=true,
      tgts={{ n="SwagWalk",         p="Items.Emotes.SwagWalk" },
            { n="SnowmobileCruise", p="Items.Emotes.SnowmobileCruise" },
            { n="BoldMarch",        p="Items.Emotes.BoldMarch" }} },
}

local BASES = {
    { n="BlueAbduction",  p="Items.Cosmetics.BlueAbduction" },
    { n="GreenAbduction", p="Items.Cosmetics.GreenAbduction" },
    { n="PureLove",       p="Items.Cosmetics.PureLove" },
    { n="RedAbduction",   p="Items.Cosmetics.RedAbduction" },
}

local EFFS = {
    { n="Adoration",          p="Items.Cosmetics.Adoration" },
    { n="AlphaTester",        p="Items.Cosmetics.AlphaTester" },
    { n="AngelicRedemption",  p="Items.Cosmetics.AngelicRedemption" },
    { n="AnimalAura",         p="Items.Cosmetics.AnimalAura" },
    { n="AuroranStag",        p="Items.Cosmetics.AuroranStag" },
    { n="BeeShield",          p="Items.Cosmetics.BeeShield" },
    { n="BionicRejuvination", p="Items.Cosmetics.BionicRejuvination" },
    { n="BloodMoon",          p="Items.Cosmetics.BloodMoon" },
    { n="BluefirePortal",     p="Items.Cosmetics.BluefirePortal" },
    { n="ChaoticRadiance",    p="Items.Cosmetics.ChaoticRadiance" },
    { n="CirclingBeams",      p="Items.Cosmetics.CirclingBeams" },
    { n="CursedEye",          p="Items.Cosmetics.CursedEye" },
    { n="DarkTendrils",       p="Items.Cosmetics.DarkTendrils" },
    { n="DoggoAura",          p="Items.Cosmetics.DoggoAura" },
    { n="EclipseCrown",       p="Items.Cosmetics.EclipseCrown" },
    { n="EclipseNova",        p="Items.Cosmetics.EclipseNova" },
    { n="Euphoria",           p="Items.Cosmetics.Euphoria" },
    { n="FrigidPerception",   p="Items.Cosmetics.FrigidPerception" },
    { n="FrostFlame",         p="Items.Cosmetics.FrostFlame" },
    { n="GildedStag",         p="Items.Cosmetics.GildedStag" },
    { n="GlacialOutburst",    p="Items.Cosmetics.GlacialOutburst" },
    { n="GlowingHaze",        p="Items.Cosmetics.GlowingHaze" },
    { n="HallowedSpecters",   p="Items.Cosmetics.HallowedSpecters" },
    { n="HellfirePortal",     p="Items.Cosmetics.HellfirePortal" },
    { n="KoiPond",            p="Items.Cosmetics.KoiPond" },
    { n="MidasTouch",         p="Items.Cosmetics.MidasTouch" },
    { n="OminousDemise",      p="Items.Cosmetics.OminousDemise" },
    { n="OozingMoney",        p="Items.Cosmetics.OozingMoney" },
    { n="ShimmeringCoronet",  p="Items.Cosmetics.ShimmeringCoronet" },
    { n="SpawnHalo",          p="Items.Cosmetics.SpawnHalo" },
    { n="Technotic",          p="Items.Cosmetics.Technotic" },
    { n="ToxicInferno",       p="Items.Cosmetics.ToxicInferno" },
    { n="VerdantStag",        p="Items.Cosmetics.VerdantStag" },
    { n="WinterChains",       p="Items.Cosmetics.WinterChains" },
}

local snapRoot = Instance.new("Folder"); snapRoot.Name="__rg_snap5"; snapRoot.Parent=RS
local eSnaps={}; local lSnaps={}; local bSnaps={}

local seen={}
for _,g in ipairs(EMOTES) do
    for _,t in ipairs(g.tgts) do
        if not seen[t.p] then seen[t.p]=true
            local inst=nav(RS,t.p)
            if inst then
                if g.legacy then
                    local f=Instance.new("Folder"); f.Name="l-"..t.p:gsub("%.","-"); f.Parent=snapRoot
                    for _,key in ipairs({"Visual","Animation"}) do
                        local c=inst:FindFirstChild(key); if c then c:Clone().Parent=f end
                    end; lSnaps[t.p]=f
                else
                    local f=Instance.new("Folder"); f.Name=t.p:gsub("%.","-"); f.Parent=snapRoot
                    for _,c in pairs(inst:GetChildren()) do c:Clone().Parent=f end; eSnaps[t.p]=f
                end
            end
        end
    end
end

for _,b in ipairs(BASES) do
    local inst=nav(RS,b.p)
    if inst then
        local f=Instance.new("Folder"); f.Name="b-"..b.n; f.Parent=snapRoot
        for _,c in pairs(inst:GetChildren()) do c:Clone().Parent=f end; bSnaps[b.p]=f
    end
end

local function resetEmotes()
    local ok=true
    for path,snap in pairs(eSnaps) do
        local i=nav(RS,path)
        if i then for _,c in pairs(i:GetChildren()) do c:Destroy() end
               for _,c in pairs(snap:GetChildren()) do c:Clone().Parent=i end
        else ok=false end
    end
    for path,snap in pairs(lSnaps) do
        local i=nav(RS,path)
        if i then
            for _,key in ipairs({"Visual","Animation"}) do
                local old=i:FindFirstChild(key)
                if old then pcall(function() old:Destroy() end) end; task.wait(0.02)
                local s=snap:FindFirstChild(key)
                if s then pcall(function() s:Clone().Parent=i end) end; task.wait(0.02)
            end
        else ok=false end
    end
    return ok
end

local function resetBase(p)
    local inst=nav(RS,p); local snap=bSnaps[p]
    if inst and snap then
        for _,c in pairs(inst:GetChildren()) do c:Destroy() end
        for _,c in pairs(snap:GetChildren()) do c:Clone().Parent=inst end
        return true
    end; return false
end

local W        = 280
local HDR_H    = 48
local TAB_H    = 26
local CONT_Y   = HDR_H + 7 + TAB_H + 8   -- 89
local CONT_H   = 270
local STATUS_H = 20
local MAIN_H   = CONT_Y + CONT_H + 8 + STATUS_H + 8  -- 395  (full main view)

local SET_H    = HDR_H + 1 + 8 + 70 + 10 + 110 + 10  -- 257

local sg = Instance.new("ScreenGui")
sg.Name="rgCosmic"; sg.ResetOnSpawn=false
sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
sg.DisplayOrder=999   -- above Tab / ESC menus
sg.Parent=pGui

local mf = Instance.new("Frame")
mf.Name="M"
mf.Size=UDim2.new(0,W,0,MAIN_H)
mf.Position=UDim2.new(0,-W-10, 0.5, -MAIN_H/2)
mf.BackgroundColor3=BG; mf.BorderSizePixel=0
mf.ClipsDescendants=true; mf.Parent=sg
corner(mf,10); bdr(mf,BORDER)

local starBg=Instance.new("Frame")
starBg.Size=UDim2.new(1,0,1,0); starBg.BackgroundTransparency=1
starBg.BorderSizePixel=0; starBg.ZIndex=1; starBg.Parent=mf

math.randomseed(os.clock()*997)
local function rnd(a,b) return a+math.random()*(b-a) end

local function animStar(s)
    while s and s.Parent do
        local dur=rnd(9,22)
        TS:Create(s,TweenInfo.new(dur,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{
            Position=UDim2.new(0,math.random(1,W-3),0,math.random(1,MAIN_H-3)),
            BackgroundTransparency=rnd(0.05,0.72),
        }):Play(); task.wait(dur)
    end
end

for i=1,32 do
    local sz=math.random(1,2)
    local s=Instance.new("Frame"); s.Size=UDim2.new(0,sz,0,sz)
    s.Position=UDim2.new(0,math.random(1,W-3),0,math.random(1,MAIN_H-3))
    local br=math.random(195,255)
    s.BackgroundColor3=Color3.fromRGB(br,br,math.min(255,br+20))
    s.BackgroundTransparency=rnd(0.1,0.65); s.BorderSizePixel=0; s.ZIndex=1; s.Parent=starBg
    corner(s,2); task.spawn(animStar,s)
end

local hdr=Instance.new("Frame")
hdr.Size=UDim2.new(1,0,0,HDR_H); hdr.BackgroundTransparency=1; hdr.ZIndex=2; hdr.Parent=mf

lbl("EVADE  Changer",14,TXT,UDim2.new(1,-66,0,20),UDim2.new(0,14,0,6),Enum.Font.GothamBold,hdr)
lbl("by @rgplugg",  10,TXT,UDim2.new(1,-66,0,16),UDim2.new(0,14,0,28),nil,hdr)

local closeBtn=Instance.new("TextButton")
closeBtn.Size=UDim2.new(0,24,0,24); closeBtn.Position=UDim2.new(1,-31,0,12)
closeBtn.Text="x"; closeBtn.Font=Enum.Font.GothamBold; closeBtn.TextSize=11
closeBtn.TextColor3=TXT2; closeBtn.BackgroundColor3=PANEL2; closeBtn.BorderSizePixel=0
closeBtn.AutoButtonColor=false; closeBtn.ZIndex=3; closeBtn.Parent=hdr; corner(closeBtn,5)
closeBtn.MouseButton1Click:Connect(function()
    if _G.FOVChangerConnection then _G.FOVChangerConnection:Disconnect() end
    snapRoot:Destroy(); sg:Destroy()
end)

local gearBtn=Instance.new("TextButton")
gearBtn.Size=UDim2.new(0,24,0,24); gearBtn.Position=UDim2.new(1,-59,0,12)
gearBtn.Text="⚙"; gearBtn.Font=Enum.Font.GothamBold; gearBtn.TextSize=13
gearBtn.TextColor3=TXT2; gearBtn.BackgroundColor3=PANEL2; gearBtn.BorderSizePixel=0
gearBtn.AutoButtonColor=false; gearBtn.ZIndex=3; gearBtn.Parent=hdr; corner(gearBtn,5)
gearBtn.MouseEnter:Connect(function() TS:Create(gearBtn,TweenInfo.new(0.1),{TextColor3=TXT,BackgroundColor3=PANEL3}):Play() end)
gearBtn.MouseLeave:Connect(function() TS:Create(gearBtn,TweenInfo.new(0.1),{TextColor3=TXT2,BackgroundColor3=PANEL2}):Play() end)

local function sep(y,par)
    par = par or mf
    local f=Instance.new("Frame"); f.Size=UDim2.new(1,-20,0,1); f.Position=UDim2.new(0,10,0,y)
    f.BackgroundColor3=BORDER; f.BorderSizePixel=0; f.ZIndex=2; f.Parent=par; return f
end
sep(HDR_H)

local mainPage=Instance.new("Frame")
mainPage.Name="MainPage"
mainPage.Size=UDim2.new(1,0,1,-HDR_H-1)
mainPage.Position=UDim2.new(0,0,0,HDR_H+1)
mainPage.BackgroundTransparency=1; mainPage.BorderSizePixel=0
mainPage.ZIndex=2; mainPage.Visible=true; mainPage.Parent=mf

local tabLocalY = 6
local tabRow=Instance.new("Frame")
tabRow.Size=UDim2.new(1,-20,0,TAB_H); tabRow.Position=UDim2.new(0,10,0,tabLocalY)
tabRow.BackgroundColor3=PANEL; tabRow.BorderSizePixel=0; tabRow.ZIndex=2; tabRow.Parent=mainPage
corner(tabRow,6); bdr(tabRow)

local function makeTabBtn(text,xScale,xOff)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(0.5,-3,1,-4); b.Position=UDim2.new(xScale,xOff,0,2)
    b.Text=text; b.Font=Enum.Font.GothamBold; b.TextSize=10
    b.TextColor3=TXT2; b.BackgroundColor3=PANEL; b.BorderSizePixel=0
    b.AutoButtonColor=false; b.ZIndex=3; b.Parent=tabRow; corner(b,5); return b
end
local tabE=makeTabBtn("EMOTES",  0,  2)
local tabF=makeTabBtn("EFFECTS",0.5, 1)
tabE.TextColor3=TXT; tabE.BackgroundColor3=PANEL2

sep(tabLocalY+TAB_H+4, mainPage)

local statusLocalY = (CONT_Y - HDR_H - 1) + CONT_H + 8
local statusLbl=Instance.new("TextLabel")
statusLbl.Text=""; statusLbl.Font=Enum.Font.Gotham; statusLbl.TextSize=10
statusLbl.TextColor3=TXT2; statusLbl.BackgroundTransparency=1
statusLbl.Size=UDim2.new(1,-20,0,STATUS_H); statusLbl.Position=UDim2.new(0,10,0,statusLocalY)
statusLbl.TextXAlignment=Enum.TextXAlignment.Left; statusLbl.ZIndex=3; statusLbl.Parent=mainPage

local function flash(msg,ok)
    statusLbl.TextColor3=ok and OK_C or ERR_C; statusLbl.Text=msg
    task.delay(3,function() if statusLbl and statusLbl.Parent then statusLbl.Text="" end end)
end

local CONT_LOCAL_Y = CONT_Y - HDR_H - 1  -- content y inside mainPage

local function makeDropdown(parent,x,y,w,label,options,placeholder,onSelect)
    local TRIG_H=26; local ITEM_H=25; local PAD_X=10
    local wrapper=Instance.new("Frame")
    wrapper.Size=UDim2.new(0,w,0,TRIG_H+#options*ITEM_H+4); wrapper.Position=UDim2.new(0,x,0,y)
    wrapper.BackgroundTransparency=1; wrapper.ZIndex=8; wrapper.ClipsDescendants=false
    wrapper.BorderSizePixel=0; wrapper.Parent=parent

    local lbAbove=Instance.new("TextLabel"); lbAbove.Text=label; lbAbove.Font=Enum.Font.GothamBold; lbAbove.TextSize=9
    lbAbove.TextColor3=TXT3; lbAbove.BackgroundTransparency=1
    lbAbove.Size=UDim2.new(1,0,0,12); lbAbove.Position=UDim2.new(0,0,0,-14)
    lbAbove.TextXAlignment=Enum.TextXAlignment.Left; lbAbove.ZIndex=3; lbAbove.Parent=wrapper

    local trig=Instance.new("Frame"); trig.Size=UDim2.new(1,0,0,TRIG_H)
    trig.BackgroundColor3=PANEL2; trig.BackgroundTransparency=0.45; trig.BorderSizePixel=0; trig.ZIndex=3; trig.Parent=wrapper
    corner(trig); bdr(trig)

    local selLbl=Instance.new("TextLabel"); selLbl.Text=placeholder; selLbl.Font=Enum.Font.Gotham; selLbl.TextSize=11
    selLbl.TextColor3=TXT2; selLbl.BackgroundTransparency=1
    selLbl.Size=UDim2.new(1,-26,1,0); selLbl.Position=UDim2.new(0,PAD_X,0,0)
    selLbl.TextXAlignment=Enum.TextXAlignment.Left; selLbl.ZIndex=4; selLbl.Parent=trig

    local chev=Instance.new("TextLabel"); chev.Text="v"; chev.Font=Enum.Font.GothamBold; chev.TextSize=9
    chev.TextColor3=TXT3; chev.BackgroundTransparency=1
    chev.Size=UDim2.new(0,20,1,0); chev.Position=UDim2.new(1,-22,0,0)
    chev.TextXAlignment=Enum.TextXAlignment.Center; chev.ZIndex=4; chev.Parent=trig

    local hit=Instance.new("TextButton"); hit.Size=UDim2.new(1,0,1,0); hit.BackgroundTransparency=1; hit.Text=""
    hit.ZIndex=5; hit.Parent=trig

    local listF=Instance.new("Frame")
    listF.Size=UDim2.new(1,0,0,#options*ITEM_H+4); listF.Position=UDim2.new(0,0,0,TRIG_H+2)
    listF.BackgroundColor3=PANEL3; listF.BorderSizePixel=0; listF.ZIndex=10
    listF.Visible=false; listF.Parent=wrapper; corner(listF); bdr(listF)

    for i,opt in ipairs(options) do
        local itemBtn=Instance.new("TextButton")
        itemBtn.Size=UDim2.new(1,-4,0,ITEM_H); itemBtn.Position=UDim2.new(0,2,0,(i-1)*ITEM_H+2)
        itemBtn.Text=opt.n; itemBtn.Font=Enum.Font.Gotham; itemBtn.TextSize=11
        itemBtn.TextColor3=TXT; itemBtn.BackgroundTransparency=1; itemBtn.BorderSizePixel=0
        itemBtn.AutoButtonColor=false; itemBtn.ZIndex=11; itemBtn.Parent=listF; corner(itemBtn,4)
        itemBtn.MouseEnter:Connect(function() TS:Create(itemBtn,TweenInfo.new(0.08),{BackgroundTransparency=0,BackgroundColor3=SEL}):Play() end)
        itemBtn.MouseLeave:Connect(function() TS:Create(itemBtn,TweenInfo.new(0.08),{BackgroundTransparency=1}):Play() end)
        itemBtn.MouseButton1Click:Connect(function()
            selLbl.Text=opt.n; selLbl.TextColor3=TXT; listF.Visible=false; chev.Text="v"; onSelect(opt,i)
        end)
    end

    local isOpen=false
    hit.MouseButton1Click:Connect(function() isOpen=not isOpen; listF.Visible=isOpen; chev.Text=isOpen and "^" or "v" end)
    return wrapper, selLbl
end

local emCont=Instance.new("Frame")
emCont.Size=UDim2.new(1,0,0,CONT_H); emCont.Position=UDim2.new(0,0,0,CONT_LOCAL_Y)
emCont.BackgroundTransparency=1; emCont.BorderSizePixel=0; emCont.ClipsDescendants=false
emCont.ZIndex=2; emCont.Visible=true; emCont.Parent=mainPage

local emDropW=W-20
local emCard=Instance.new("Frame")
emCard.Size=UDim2.new(1,-20,0,105); emCard.Position=UDim2.new(0,10,0,76)
emCard.BackgroundColor3=PANEL; emCard.BorderSizePixel=0; emCard.ZIndex=2
emCard.Visible=false; emCard.Parent=emCont; corner(emCard); bdr(emCard)

local emCardTitle=Instance.new("TextLabel"); emCardTitle.Text=""; emCardTitle.Font=Enum.Font.GothamBold; emCardTitle.TextSize=11
emCardTitle.TextColor3=TXT; emCardTitle.BackgroundTransparency=1
emCardTitle.Size=UDim2.new(1,-90,0,18); emCardTitle.Position=UDim2.new(0,10,0,8)
emCardTitle.TextXAlignment=Enum.TextXAlignment.Left; emCardTitle.ZIndex=3; emCardTitle.Parent=emCard

local emApplyBtn=Instance.new("TextButton"); emApplyBtn.Size=UDim2.new(0,60,0,22); emApplyBtn.Position=UDim2.new(1,-68,0,8)
emApplyBtn.Text="APPLY"; emApplyBtn.Font=Enum.Font.GothamBold; emApplyBtn.TextSize=10
emApplyBtn.TextColor3=TXT; emApplyBtn.BackgroundColor3=PANEL3; emApplyBtn.BorderSizePixel=0
emApplyBtn.AutoButtonColor=false; emApplyBtn.ZIndex=3; emApplyBtn.Parent=emCard; corner(emApplyBtn); bdr(emApplyBtn)

local emTgtLabel=Instance.new("TextLabel"); emTgtLabel.Text="Replace:"; emTgtLabel.Font=Enum.Font.Gotham; emTgtLabel.TextSize=9
emTgtLabel.TextColor3=TXT3; emTgtLabel.BackgroundTransparency=1
emTgtLabel.Size=UDim2.new(1,-16,0,14); emTgtLabel.Position=UDim2.new(0,10,0,38)
emTgtLabel.TextXAlignment=Enum.TextXAlignment.Left; emTgtLabel.ZIndex=3; emTgtLabel.Parent=emCard

local emTgtRow=Instance.new("Frame"); emTgtRow.Size=UDim2.new(1,-16,0,28); emTgtRow.Position=UDim2.new(0,8,0,54)
emTgtRow.BackgroundTransparency=1; emTgtRow.BorderSizePixel=0; emTgtRow.ZIndex=3; emTgtRow.Parent=emCard

local emResetBtn=Instance.new("TextButton"); emResetBtn.Size=UDim2.new(1,-20,0,26); emResetBtn.Position=UDim2.new(0,10,0,188)
emResetBtn.Text="RESET ALL EMOTES"; emResetBtn.Font=Enum.Font.GothamBold; emResetBtn.TextSize=10
emResetBtn.TextColor3=TXT2; emResetBtn.BackgroundColor3=PANEL2; emResetBtn.BorderSizePixel=0
emResetBtn.AutoButtonColor=false; emResetBtn.ZIndex=2; emResetBtn.Parent=emCont; corner(emResetBtn); bdr(emResetBtn)
emResetBtn.MouseEnter:Connect(function() TS:Create(emResetBtn,TweenInfo.new(0.1),{BackgroundColor3=PANEL3}):Play() end)
emResetBtn.MouseLeave:Connect(function() TS:Create(emResetBtn,TweenInfo.new(0.1),{BackgroundColor3=PANEL2}):Play() end)
emResetBtn.MouseButton1Click:Connect(function()
    emResetBtn.Text="Restoring..."
    local ok=resetEmotes()
    emResetBtn.Text=ok and "RESTORED" or "FAILED"; emResetBtn.TextColor3=ok and OK_C or ERR_C
    flash(ok and "All emotes restored!" or "Some restores failed.",ok)
    task.delay(2,function() if emResetBtn and emResetBtn.Parent then emResetBtn.Text="RESET ALL EMOTES"; emResetBtn.TextColor3=TXT2 end end)
end)

local curGroup=nil; local curTgtIdx=1; local tgtBtns={}
local function rebuildTargetRow(group)
    for _,b in ipairs(tgtBtns) do b:Destroy() end; tgtBtns={}; curTgtIdx=1
    local n=#group.tgts
    local btnW=math.floor((emTgtRow.AbsoluteSize.X>0 and emTgtRow.AbsoluteSize.X or (emDropW-16))/n)-3
    for i,tgt in ipairs(group.tgts) do
        local b=Instance.new("TextButton"); b.Size=UDim2.new(0,btnW,1,0); b.Position=UDim2.new(0,(i-1)*(btnW+3),0,0)
        b.Text=tgt.n; b.Font=Enum.Font.Gotham; b.TextSize=10
        b.TextColor3=i==1 and TXT or TXT2; b.BackgroundColor3=i==1 and SEL or PANEL2
        b.BorderSizePixel=0; b.AutoButtonColor=false; b.ZIndex=4; b.Parent=emTgtRow; corner(b,5)
        if i==1 then bdr(b,Color3.fromRGB(80,80,105)) end; tgtBtns[i]=b
        b.MouseButton1Click:Connect(function()
            curTgtIdx=i
            for k,tb in ipairs(tgtBtns) do
                local s=tb:FindFirstChildOfClass("UIStroke")
                tb.TextColor3=k==i and TXT or TXT2; tb.BackgroundColor3=k==i and SEL or PANEL2
                if s then s:Destroy() end
                if k==i then bdr(tb,Color3.fromRGB(80,80,105)) end
            end
        end)
    end
end

makeDropdown(emCont,10,18,emDropW,"SELECT EMOTE",EMOTES,"-- choose emote --",
    function(opt) curGroup=opt; emCardTitle.Text=opt.n; rebuildTargetRow(opt); emCard.Visible=true end)

emApplyBtn.MouseButton1Click:Connect(function()
    if not curGroup then flash("Select an emote first!",false); return end
    emApplyBtn.Text="..."
    local tgt=curGroup.tgts[curTgtIdx]; local ok
    if curGroup.legacy then
        task.spawn(function()
            ok=swapLegacy(tgt.p,curGroup.src)
            emApplyBtn.Text=ok and "DONE" or "FAIL"; emApplyBtn.TextColor3=ok and OK_C or ERR_C
            flash(ok and (tgt.n.." -> "..curGroup.n) or ("Failed: "..tgt.n),ok)
            task.delay(1.8,function() if emApplyBtn and emApplyBtn.Parent then emApplyBtn.Text="APPLY"; emApplyBtn.TextColor3=TXT end end)
        end)
    else
        ok=swapContent(tgt.p,curGroup.src)
        emApplyBtn.Text=ok and "DONE" or "FAIL"; emApplyBtn.TextColor3=ok and OK_C or ERR_C
        flash(ok and (tgt.n.." -> "..curGroup.n) or ("Failed: "..tgt.n),ok)
        task.delay(1.8,function() if emApplyBtn and emApplyBtn.Parent then emApplyBtn.Text="APPLY"; emApplyBtn.TextColor3=TXT end end)
    end
end)
emApplyBtn.MouseEnter:Connect(function() TS:Create(emApplyBtn,TweenInfo.new(0.1),{BackgroundColor3=SEL}):Play() end)
emApplyBtn.MouseLeave:Connect(function() TS:Create(emApplyBtn,TweenInfo.new(0.1),{BackgroundColor3=PANEL3}):Play() end)

local efCont=Instance.new("Frame")
efCont.Size=UDim2.new(1,0,0,CONT_H); efCont.Position=UDim2.new(0,0,0,CONT_LOCAL_Y)
efCont.BackgroundTransparency=1; efCont.BorderSizePixel=0; efCont.ClipsDescendants=false
efCont.ZIndex=2; efCont.Visible=false; efCont.Parent=mainPage

local curBase=nil
makeDropdown(efCont,10,18,W-20,"SELECT BASE COSMETIC",BASES,"-- choose base --",
    function(opt) curBase=opt end)

local effListLbl=lbl("SELECT EFFECT",9,TXT3,UDim2.new(1,-20,0,12),UDim2.new(0,10,0,80),Enum.Font.GothamBold,efCont)
effListLbl.ZIndex=3

local EFF_ITEM_H=26; local EFF_LIST_H=150
local scrollF=Instance.new("ScrollingFrame")
scrollF.Size=UDim2.new(1,-20,0,EFF_LIST_H); scrollF.Position=UDim2.new(0,10,0,94)
scrollF.CanvasSize=UDim2.new(0,0,0,#EFFS*EFF_ITEM_H+4)
scrollF.ScrollBarThickness=4; scrollF.ScrollBarImageColor3=BORDER
scrollF.BackgroundColor3=PANEL; scrollF.BorderSizePixel=0; scrollF.ZIndex=2
scrollF.Parent=efCont; corner(scrollF); bdr(scrollF)

local activeEffBtn=nil
for i,eff in ipairs(EFFS) do
    local row=Instance.new("Frame"); row.Size=UDim2.new(1,-4,0,EFF_ITEM_H-2); row.Position=UDim2.new(0,2,0,(i-1)*EFF_ITEM_H+2)
    row.BackgroundTransparency=1; row.BorderSizePixel=0; row.ZIndex=3; row.Parent=scrollF; corner(row,4)
    local effLbl=Instance.new("TextLabel"); effLbl.Text=eff.n; effLbl.Font=Enum.Font.Gotham; effLbl.TextSize=11
    effLbl.TextColor3=TXT; effLbl.BackgroundTransparency=1; effLbl.Size=UDim2.new(1,-68,1,0); effLbl.Position=UDim2.new(0,8,0,0)
    effLbl.TextXAlignment=Enum.TextXAlignment.Left; effLbl.ZIndex=4; effLbl.Parent=row
    local effApply=Instance.new("TextButton"); effApply.Size=UDim2.new(0,54,0,18); effApply.Position=UDim2.new(1,-58,0.5,-9)
    effApply.Text="APPLY"; effApply.Font=Enum.Font.GothamBold; effApply.TextSize=9
    effApply.TextColor3=TXT2; effApply.BackgroundColor3=PANEL2; effApply.BorderSizePixel=0
    effApply.AutoButtonColor=false; effApply.ZIndex=4; effApply.Parent=row; corner(effApply,4); bdr(effApply)
    effApply.MouseEnter:Connect(function() TS:Create(effApply,TweenInfo.new(0.08),{BackgroundColor3=SEL}):Play() end)
    effApply.MouseLeave:Connect(function()
        if effApply~=(activeEffBtn and activeEffBtn:FindFirstChildOfClass("TextButton")) then
            TS:Create(effApply,TweenInfo.new(0.08),{BackgroundColor3=PANEL2}):Play() end end)
    effApply.MouseButton1Click:Connect(function()
        if not curBase then flash("Select a base cosmetic first!",false); return end
        effApply.Text="..."; resetBase(curBase.p); local ok=swapContent(curBase.p,eff.p)
        if activeEffBtn and activeEffBtn~=row then
            activeEffBtn.BackgroundTransparency=1
            local pa=activeEffBtn:FindFirstChildOfClass("TextButton")
            if pa then pa.TextColor3=TXT2; pa.BackgroundColor3=PANEL2 end end
        if ok then activeEffBtn=row; row.BackgroundTransparency=0; row.BackgroundColor3=SEL
            effApply.Text="ON"; effApply.TextColor3=OK_C; effApply.BackgroundColor3=PANEL3; flash(curBase.n.." -> "..eff.n,true)
        else effApply.Text="FAIL"; effApply.TextColor3=ERR_C; flash("Failed: "..eff.n,false)
            task.delay(1.5,function() if effApply and effApply.Parent then effApply.Text="APPLY"; effApply.TextColor3=TXT2 end end) end
    end)
end

local efResetBtn=Instance.new("TextButton"); efResetBtn.Size=UDim2.new(1,-20,0,26); efResetBtn.Position=UDim2.new(0,10,0,252)
efResetBtn.Text="RESET EFFECT"; efResetBtn.Font=Enum.Font.GothamBold; efResetBtn.TextSize=10
efResetBtn.TextColor3=TXT2; efResetBtn.BackgroundColor3=PANEL2; efResetBtn.BorderSizePixel=0
efResetBtn.AutoButtonColor=false; efResetBtn.ZIndex=2; efResetBtn.Parent=efCont; corner(efResetBtn); bdr(efResetBtn)
efResetBtn.MouseEnter:Connect(function() TS:Create(efResetBtn,TweenInfo.new(0.1),{BackgroundColor3=PANEL3}):Play() end)
efResetBtn.MouseLeave:Connect(function() TS:Create(efResetBtn,TweenInfo.new(0.1),{BackgroundColor3=PANEL2}):Play() end)
efResetBtn.MouseButton1Click:Connect(function()
    if not curBase then flash("Select a base first.",false); return end
    efResetBtn.Text="Restoring..."
    local ok=resetBase(curBase.p)
    if ok and activeEffBtn then
        activeEffBtn.BackgroundTransparency=1
        local ap=activeEffBtn:FindFirstChildOfClass("TextButton")
        if ap then ap.Text="APPLY"; ap.TextColor3=TXT2; ap.BackgroundColor3=PANEL2 end; activeEffBtn=nil end
    efResetBtn.Text=ok and "RESTORED" or "FAILED"; efResetBtn.TextColor3=ok and OK_C or ERR_C
    flash(ok and (curBase.n.." restored!") or "Reset failed.",ok)
    task.delay(2,function() if efResetBtn and efResetBtn.Parent then efResetBtn.Text="RESET EFFECT"; efResetBtn.TextColor3=TXT2 end end)
end)

local function switchTab(toEffects)
    emCont.Visible=not toEffects; efCont.Visible=toEffects
    tabE.TextColor3=toEffects and TXT2 or TXT;  tabE.BackgroundColor3=toEffects and PANEL  or PANEL2
    tabF.TextColor3=toEffects and TXT  or TXT2; tabF.BackgroundColor3=toEffects and PANEL2 or PANEL
end
tabE.MouseButton1Click:Connect(function() switchTab(false) end)
tabF.MouseButton1Click:Connect(function() switchTab(true) end)

local settingsPage=Instance.new("Frame")
settingsPage.Name="SettingsPage"
settingsPage.Size=UDim2.new(1,0,1,-HDR_H-1)
settingsPage.Position=UDim2.new(0,0,0,HDR_H+1)
settingsPage.BackgroundTransparency=1; settingsPage.BorderSizePixel=0
settingsPage.ZIndex=2; settingsPage.Visible=false; settingsPage.Parent=mf

local kyCard=Instance.new("Frame")
kyCard.Size=UDim2.new(1,-20,0,70); kyCard.Position=UDim2.new(0,10,0,8)
kyCard.BackgroundColor3=PANEL; kyCard.BorderSizePixel=0; kyCard.ZIndex=2
kyCard.Parent=settingsPage; corner(kyCard); bdr(kyCard)

lbl("TOGGLE KEY",9,TXT3,UDim2.new(1,-16,0,14),UDim2.new(0,10,0,6),Enum.Font.GothamBold,kyCard)

local kyRow2=Instance.new("Frame"); kyRow2.Size=UDim2.new(1,-16,0,26); kyRow2.Position=UDim2.new(0,8,0,24)
kyRow2.BackgroundColor3=PANEL2; kyRow2.BorderSizePixel=0; kyRow2.ZIndex=3; kyRow2.Parent=kyCard
corner(kyRow2,5); bdr(kyRow2)

local listeningForKey=false

local keyBtn=Instance.new("TextButton"); keyBtn.Size=UDim2.new(0,52,0,18); keyBtn.Position=UDim2.new(0,6,0.5,-9)
keyBtn.Text=toggleKey.Name; keyBtn.Font=Enum.Font.GothamBold; keyBtn.TextSize=10
keyBtn.TextColor3=TXT; keyBtn.BackgroundColor3=PANEL3; keyBtn.BorderSizePixel=0
keyBtn.AutoButtonColor=false; keyBtn.ZIndex=4; keyBtn.Parent=kyRow2; corner(keyBtn,4); bdr(keyBtn)

local kyHint=lbl("click to rebind",8,TXT3,UDim2.new(1,-70,1,0),UDim2.new(0,64,0,0),nil,kyRow2)
kyHint.ZIndex=4

lbl("Key to show / hide this menu.",8,TXT3,UDim2.new(1,-16,0,14),UDim2.new(0,10,0,52),nil,kyCard).ZIndex=3

keyBtn.MouseButton1Click:Connect(function()
    if listeningForKey then return end
    listeningForKey=true; keyBtn.Text="..."; keyBtn.TextColor3=Color3.fromRGB(200,195,100); kyHint.Text="press any key"
    local conn; conn=UIS.InputBegan:Connect(function(inp,gpe)
        if gpe then return end
        if inp.UserInputType==Enum.UserInputType.Keyboard then
            toggleKey=inp.KeyCode; keyBtn.Text=inp.KeyCode.Name; keyBtn.TextColor3=TXT
            kyHint.Text="click to rebind"; conn:Disconnect()
            task.defer(function() listeningForKey=false end)
        end
    end)
end)

local fovCard=Instance.new("Frame")
fovCard.Size=UDim2.new(1,-20,0,110); fovCard.Position=UDim2.new(0,10,0,88)
fovCard.BackgroundColor3=PANEL; fovCard.BorderSizePixel=0; fovCard.ZIndex=2
fovCard.Parent=settingsPage; corner(fovCard); bdr(fovCard)

lbl("FIELD OF VIEW",9,TXT3,UDim2.new(1,-16,0,14),UDim2.new(0,10,0,8),Enum.Font.GothamBold,fovCard)
lbl("Введите значение от 1 до 270:",8,TXT3,UDim2.new(1,-16,0,14),UDim2.new(0,10,0,22),nil,fovCard).ZIndex=3

local fovBox=Instance.new("TextBox"); fovBox.Size=UDim2.new(0,130,0,26); fovBox.Position=UDim2.new(0.5,-65,0,40)
fovBox.Text=tostring(currentFOV); fovBox.PlaceholderText="90"
fovBox.Font=Enum.Font.GothamBold; fovBox.TextSize=14; fovBox.TextXAlignment=Enum.TextXAlignment.Center
fovBox.TextColor3=TXT; fovBox.BackgroundColor3=PANEL2; fovBox.BorderSizePixel=0
fovBox.ClearTextOnFocus=false; fovBox.ZIndex=3; fovBox.Parent=fovCard
corner(fovBox,5); bdr(fovBox,BORDER)

local fovApplyBtn=Instance.new("TextButton"); fovApplyBtn.Size=UDim2.new(0,90,0,22); fovApplyBtn.Position=UDim2.new(0.5,-45,0,74)
fovApplyBtn.Text="APPLY"; fovApplyBtn.Font=Enum.Font.GothamBold; fovApplyBtn.TextSize=10
fovApplyBtn.TextColor3=TXT2; fovApplyBtn.BackgroundColor3=PANEL2; fovApplyBtn.BorderSizePixel=0
fovApplyBtn.AutoButtonColor=false; fovApplyBtn.ZIndex=3; fovApplyBtn.Parent=fovCard
corner(fovApplyBtn,5); bdr(fovApplyBtn,BORDER)

fovApplyBtn.MouseEnter:Connect(function() TS:Create(fovApplyBtn,TweenInfo.new(0.1),{BackgroundColor3=PANEL3,TextColor3=TXT}):Play() end)
fovApplyBtn.MouseLeave:Connect(function() TS:Create(fovApplyBtn,TweenInfo.new(0.1),{BackgroundColor3=PANEL2,TextColor3=TXT2}):Play() end)

local fovStatus=Instance.new("TextLabel"); fovStatus.Text=""; fovStatus.Font=Enum.Font.Gotham; fovStatus.TextSize=9
fovStatus.TextColor3=OK_C; fovStatus.BackgroundTransparency=1; fovStatus.TextXAlignment=Enum.TextXAlignment.Center
fovStatus.Size=UDim2.new(1,-16,0,14); fovStatus.Position=UDim2.new(0,8,0,94)
fovStatus.ZIndex=3; fovStatus.Parent=fovCard

local function setMsg(msg,ok)
    fovStatus.TextColor3=ok and OK_C or ERR_C; fovStatus.Text=msg
    task.delay(2.5,function() if fovStatus and fovStatus.Parent then fovStatus.Text="" end end)
end

fovApplyBtn.MouseButton1Click:Connect(function()
    local raw=fovBox.Text:match("^%s*(%d+)%s*$"); local val=raw and tonumber(raw)
    if not val or val<1 or val>270 then setMsg("Введите число от 1 до 270",false); return end
    applyFOV(val); fovBox.Text=tostring(val); setMsg("FOV → "..val,true)
end)

fovBox.FocusLost:Connect(function(enter) if enter then fovApplyBtn.MouseButton1Click:Fire() end end)

local onSettingsScreen = false

gearBtn.MouseButton1Click:Connect(function()
    onSettingsScreen = not onSettingsScreen
    if onSettingsScreen then
        gearBtn.Text = "←"; gearBtn.TextSize = 16
        mainPage.Visible = false
        settingsPage.Visible = true
    else
        gearBtn.Text = "⚙"; gearBtn.TextSize = 13
        settingsPage.Visible = false
        mainPage.Visible = true
    end
end)

local drag,dStart,dPos=false,nil,nil
hdr.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true; dStart=i.Position; dPos=mf.Position end
end)
UIS.InputChanged:Connect(function(i)
    if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
        local d=i.Position-dStart
        mf.Position=UDim2.new(dPos.X.Scale,dPos.X.Offset+d.X,dPos.Y.Scale,dPos.Y.Offset+d.Y)
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
end)

local menuVis=true
UIS.InputBegan:Connect(function(inp,gpe)
    if gpe then return end
    if listeningForKey then return end
    if inp.UserInputType==Enum.UserInputType.Keyboard and inp.KeyCode==toggleKey then
        menuVis=not menuVis; mf.Visible=menuVis
    end
end)

TS:Create(mf, TweenInfo.new(0.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out), {
    Position=UDim2.new(0,20,0.5,-MAIN_H/2)
}):Play()

print("[rg] EVADE Changer loaded | "..toggleKey.Name.." to toggle | FOV: "..currentFOV)
