-- main.lua
-- GUI only - all logic is in core.lua and modules.lua
local TweenService = game:GetService("TweenService")
local player = _G.player

-- =====================
-- GUI HELPERS
-- =====================
local function makeSection(parent, yPos, height, title)
    local box = Instance.new("Frame", parent)
    box.Size = UDim2.new(1,-16,0,height); box.Position = UDim2.new(0,8,0,yPos)
    box.BackgroundColor3 = Color3.fromRGB(18,12,32); box.BorderSizePixel = 0; box.ZIndex = 6
    Instance.new("UICorner", box).CornerRadius = UDim.new(0,8)
    Instance.new("UIStroke", box).Color = Color3.fromRGB(80,40,160)
    if title then
        local lbl = Instance.new("TextLabel", box)
        lbl.Size = UDim2.new(1,-10,0,18); lbl.Position = UDim2.new(0,8,0,4)
        lbl.BackgroundTransparency = 1; lbl.Text = title
        lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 11
        lbl.TextColor3 = Color3.fromRGB(140,100,255)
        lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 7
    end
    return box
end

local function makeDivider(parent, yPos)
    local d = Instance.new("Frame", parent)
    d.Size = UDim2.new(1,-16,0,1); d.Position = UDim2.new(0,8,0,yPos)
    d.BackgroundColor3 = Color3.fromRGB(40,30,70); d.BorderSizePixel = 0; d.ZIndex = 6
end

local function makeBtn(parent, size, pos, text, color)
    local btn = Instance.new("TextButton", parent)
    btn.Size = size; btn.Position = pos
    btn.BackgroundColor3 = color or Color3.fromRGB(30,80,180)
    btn.BorderSizePixel = 0; btn.Text = text
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 11
    btn.TextColor3 = Color3.fromRGB(255,255,255); btn.ZIndex = 7
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    return btn
end

-- =====================
-- BUILD GUI
-- =====================
local screenGui = Instance.new("ScreenGui")
screenGui.ResetOnSpawn = false; screenGui.DisplayOrder = 999
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; screenGui.IgnoreGuiInset = true
Instance.new("StringValue", screenGui).Name = "NPCTeleportPanel"
_G.secureGui(screenGui)

-- Toggle button
local toggleBtn = Instance.new("ImageButton")
toggleBtn.Size = UDim2.new(0,44,0,44); toggleBtn.Position = UDim2.new(0,12,0.5,-22)
toggleBtn.BackgroundColor3 = Color3.fromRGB(20,20,28); toggleBtn.BorderSizePixel = 0
toggleBtn.ZIndex = 10; toggleBtn.Parent = screenGui
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0,10)
local s1 = Instance.new("UIStroke", toggleBtn); s1.Color = Color3.fromRGB(120,80,220); s1.Thickness = 1.5
local tLbl = Instance.new("TextLabel", toggleBtn)
tLbl.Size = UDim2.new(1,0,1,0); tLbl.BackgroundTransparency = 1; tLbl.Text = "NPC"
tLbl.TextScaled = true; tLbl.Font = Enum.Font.GothamBold
tLbl.TextColor3 = Color3.fromRGB(255,255,255); tLbl.ZIndex = 11

-- Main panel
local panel = Instance.new("Frame")
panel.Size = UDim2.new(0,280,0,760); panel.Position = UDim2.new(0,64,0.5,-380)
panel.BackgroundColor3 = Color3.fromRGB(14,14,20); panel.BorderSizePixel = 0
panel.Visible = false; panel.ZIndex = 5; panel.Parent = screenGui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0,12)
local ps = Instance.new("UIStroke", panel); ps.Color = Color3.fromRGB(100,60,200); ps.Thickness = 1.5

-- Title
local titleBar = Instance.new("Frame", panel)
titleBar.Size = UDim2.new(1,0,0,38); titleBar.BackgroundColor3 = Color3.fromRGB(22,22,34)
titleBar.BorderSizePixel = 0; titleBar.ZIndex = 6
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0,12)
local tTitle = Instance.new("TextLabel", titleBar)
tTitle.Size = UDim2.new(1,-10,1,0); tTitle.Position = UDim2.new(0,10,0,0)
tTitle.BackgroundTransparency = 1; tTitle.Text = "NPC TELEPORT + AUTOFARM"
tTitle.Font = Enum.Font.GothamBold; tTitle.TextSize = 12
tTitle.TextColor3 = Color3.fromRGB(180,140,255); tTitle.TextXAlignment = Enum.TextXAlignment.Left; tTitle.ZIndex = 7

-- Autofarm (y=44 h=130)
local farmBox = makeSection(panel, 44, 130, "⚙  DOCKS DELIVERY AUTOFARM")
local statusLbl = Instance.new("TextLabel", farmBox)
statusLbl.Size = UDim2.new(1,-10,0,16); statusLbl.Position = UDim2.new(0,8,0,26)
statusLbl.BackgroundTransparency = 1; statusLbl.Text = "◈ Idle"
statusLbl.Font = Enum.Font.Gotham; statusLbl.TextSize = 11
statusLbl.TextColor3 = Color3.fromRGB(160,160,190); statusLbl.TextXAlignment = Enum.TextXAlignment.Left; statusLbl.ZIndex = 7
_G.farmStatusLabel = statusLbl
local infoLbl = Instance.new("TextLabel", farmBox)
infoLbl.Size = UDim2.new(1,-10,0,24); infoLbl.Position = UDim2.new(0,8,0,44)
infoLbl.BackgroundTransparency = 1; infoLbl.Text = "NPC → Show jobs → Docks → Pirate → Pickup → Turn in"
infoLbl.Font = Enum.Font.Gotham; infoLbl.TextSize = 9; infoLbl.TextColor3 = Color3.fromRGB(100,100,130)
infoLbl.TextWrapped = true; infoLbl.TextXAlignment = Enum.TextXAlignment.Left; infoLbl.ZIndex = 7
local farmBtn = makeBtn(farmBox, UDim2.new(1,-16,0,28), UDim2.new(0,8,0,96), "▶  START AUTOFARM", Color3.fromRGB(30,180,80))
farmBtn.TextSize = 12
farmBtn.MouseButton1Click:Connect(function()
    if not _G.farmRunning then
        _G.farmRunning = true; farmBtn.Text = "⏹  STOP AUTOFARM"
        farmBtn.BackgroundColor3 = Color3.fromRGB(200,40,40)
        coroutine.wrap(_G.runDocksDeliveryFarm)()
    else
        _G.farmRunning = false; farmBtn.Text = "▶  START AUTOFARM"
        farmBtn.BackgroundColor3 = Color3.fromRGB(30,180,80)
    end
end)

makeDivider(panel, 182)

-- Auto Parry (y=190 h=56)
local parryBox = makeSection(panel, 190, 56, "⚡  AUTO PARRY")
local parryStatusLbl = Instance.new("TextLabel", parryBox)
parryStatusLbl.Size = UDim2.new(1,-88,0,16); parryStatusLbl.Position = UDim2.new(0,8,0,24)
parryStatusLbl.BackgroundTransparency = 1; parryStatusLbl.Text = "OFF"
parryStatusLbl.Font = Enum.Font.Gotham; parryStatusLbl.TextSize = 10
parryStatusLbl.TextColor3 = Color3.fromRGB(160,160,190); parryStatusLbl.TextXAlignment = Enum.TextXAlignment.Left; parryStatusLbl.ZIndex = 7
_G.autoParryLabel = parryStatusLbl
local parryBtn = makeBtn(parryBox, UDim2.new(0,72,0,24), UDim2.new(1,-80,0,20), "ENABLE")
parryBtn.MouseButton1Click:Connect(function()
    if not _G.isAutoParryActive() then
        _G.startAutoParry(); parryBtn.Text = "DISABLE"; parryBtn.BackgroundColor3 = Color3.fromRGB(200,140,0)
    else
        _G.stopAutoParry(); parryBtn.Text = "ENABLE"; parryBtn.BackgroundColor3 = Color3.fromRGB(30,80,180)
    end
end)

makeDivider(panel, 254)

-- Server Hopper (y=262 h=100)
local serverBox = makeSection(panel, 262, 100, "🌐  SERVER HOPPER")
local serverStatusLbl = Instance.new("TextLabel", serverBox)
serverStatusLbl.Size = UDim2.new(1,-10,0,28); serverStatusLbl.Position = UDim2.new(0,8,0,22)
serverStatusLbl.BackgroundTransparency = 1; serverStatusLbl.Text = "Reads live server list — skips Permadeath"
serverStatusLbl.Font = Enum.Font.Gotham; serverStatusLbl.TextSize = 10
serverStatusLbl.TextColor3 = Color3.fromRGB(130,130,160); serverStatusLbl.TextWrapped = true
serverStatusLbl.TextXAlignment = Enum.TextXAlignment.Left; serverStatusLbl.ZIndex = 7
_G.serverHopLabel = serverStatusLbl
local soloBtn = makeBtn(serverBox, UDim2.new(0.5,-6,0,28), UDim2.new(0,4,0,64), "🔒 JOIN SOLO", Color3.fromRGB(20,120,60))
soloBtn.MouseButton1Click:Connect(function() serverStatusLbl.Text = "Scanning..."; _G.hopToLowServer(1) end)
local lowBtn = makeBtn(serverBox, UDim2.new(0.5,-6,0,28), UDim2.new(0.5,2,0,64), "👥 LOW POP (≤4)", Color3.fromRGB(60,80,160))
lowBtn.MouseButton1Click:Connect(function() serverStatusLbl.Text = "Scanning..."; _G.hopToLowServer(4) end)

makeDivider(panel, 370)

-- Movement (y=378 h=60)
local movBox = makeSection(panel, 378, 60, "✈  MOVEMENT  |  Shift=fast  Ctrl=down")
local flyBtn = makeBtn(movBox, UDim2.new(0.5,-6,0,28), UDim2.new(0,4,0,24), "✈ FLY: OFF", Color3.fromRGB(30,80,180))
local noclipBtn = makeBtn(movBox, UDim2.new(0.5,-6,0,28), UDim2.new(0.5,2,0,24), "👻 NOCLIP: OFF", Color3.fromRGB(100,40,160))
flyBtn.MouseButton1Click:Connect(function()
    if not _G.isFlyActive() then
        _G.startFly(); flyBtn.Text = "✈ FLY: ON"; flyBtn.BackgroundColor3 = Color3.fromRGB(30,200,100)
    else
        _G.stopFly(); flyBtn.Text = "✈ FLY: OFF"; flyBtn.BackgroundColor3 = Color3.fromRGB(30,80,180)
    end
end)
noclipBtn.MouseButton1Click:Connect(function()
    if not _G.isNoclipActive() then
        _G.startNoclip(); noclipBtn.Text = "👻 NOCLIP: ON"; noclipBtn.BackgroundColor3 = Color3.fromRGB(180,60,255)
    else
        _G.stopNoclip(); noclipBtn.Text = "👻 NOCLIP: OFF"; noclipBtn.BackgroundColor3 = Color3.fromRGB(100,40,160)
    end
end)

makeDivider(panel, 446)

-- NPC Teleport
local npcLbl = Instance.new("TextLabel", panel)
npcLbl.Size = UDim2.new(1,-16,0,16); npcLbl.Position = UDim2.new(0,8,0,452)
npcLbl.BackgroundTransparency = 1; npcLbl.Text = "🧭  NPC TELEPORT"
npcLbl.Font = Enum.Font.GothamBold; npcLbl.TextSize = 11
npcLbl.TextColor3 = Color3.fromRGB(140,100,255); npcLbl.TextXAlignment = Enum.TextXAlignment.Left; npcLbl.ZIndex = 6

local searchBox = Instance.new("TextBox", panel)
searchBox.Size = UDim2.new(1,-16,0,28); searchBox.Position = UDim2.new(0,8,0,472)
searchBox.BackgroundColor3 = Color3.fromRGB(25,25,36); searchBox.BorderSizePixel = 0
searchBox.PlaceholderText = "Search NPC..."; searchBox.Text = ""
searchBox.Font = Enum.Font.Gotham; searchBox.TextSize = 12
searchBox.TextColor3 = Color3.fromRGB(220,220,230); searchBox.PlaceholderColor3 = Color3.fromRGB(100,100,120); searchBox.ZIndex = 6
Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0,8)

local scrollFrame = Instance.new("ScrollingFrame", panel)
scrollFrame.Size = UDim2.new(1,-16,1,-512); scrollFrame.Position = UDim2.new(0,8,0,508)
scrollFrame.BackgroundTransparency = 1; scrollFrame.BorderSizePixel = 0; scrollFrame.ScrollBarThickness = 3
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(120,80,220); scrollFrame.ZIndex = 6
local ll = Instance.new("UIListLayout", scrollFrame)
ll.SortOrder = Enum.SortOrder.LayoutOrder; ll.Padding = UDim.new(0,4)

local function getNPCs()
    local npcs, seen = {}, {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            if hrp and not seen[obj] then seen[obj] = true; table.insert(npcs, {name=obj.Name, hrp=hrp}) end
        end
    end
    table.sort(npcs, function(a,b) return a.name < b.name end)
    return npcs
end

local allButtons = {}
local function buildList(filter)
    for _, b in ipairs(allButtons) do b:Destroy() end; allButtons = {}
    local npcs = getNPCs(); local count = 0
    for _, npc in ipairs(npcs) do
        local skip = filter and filter ~= "" and not string.find(string.lower(npc.name), string.lower(filter), 1, true)
        if not skip then
            local btn = Instance.new("TextButton", scrollFrame)
            btn.Size = UDim2.new(1,0,0,32); btn.BackgroundColor3 = Color3.fromRGB(22,22,34)
            btn.BorderSizePixel = 0; btn.Text = npc.name; btn.Font = Enum.Font.Gotham; btn.TextSize = 12
            btn.TextColor3 = Color3.fromRGB(210,210,225); btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.ZIndex = 7; btn.LayoutOrder = count
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
            Instance.new("UIPadding", btn).PaddingLeft = UDim.new(0,10)
            table.insert(allButtons, btn); count = count + 1
            btn.MouseEnter:Connect(function()
                TweenService:Create(btn,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(40,30,60)}):Play()
            end)
            btn.MouseLeave:Connect(function()
                TweenService:Create(btn,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(22,22,34)}):Play()
            end)
            local hrp = npc.hrp
            btn.MouseButton1Click:Connect(function() _G.teleportTo(hrp.CFrame * CFrame.new(0,0,-3.5)) end)
        end
    end
    scrollFrame.CanvasSize = UDim2.new(0,0,0,count*36)
end

buildList("")
searchBox:GetPropertyChangedSignal("Text"):Connect(function() buildList(searchBox.Text) end)

local panelOpen = false
toggleBtn.MouseButton1Click:Connect(function()
    panelOpen = not panelOpen
    if panelOpen then
        panel.Visible = true; buildList(searchBox.Text); panel.Size = UDim2.new(0,0,0,760)
        TweenService:Create(panel,TweenInfo.new(0.18,Enum.EasingStyle.Quad),{Size=UDim2.new(0,280,0,760)}):Play()
    else
        local tw = TweenService:Create(panel,TweenInfo.new(0.15,Enum.EasingStyle.Quad),{Size=UDim2.new(0,0,0,760)})
        tw:Play(); tw.Completed:Connect(function() panel.Visible = false end)
    end
end)

print("[main] loaded")
