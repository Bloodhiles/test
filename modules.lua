-- modules.lua
-- Auto parry, fly, noclip, server hopper, dialogue, farm logic
local player = _G.player
local RS = _G.RS
local RunService = _G.RunService
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

-- =====================
-- AUTO PARRY
-- =====================
local autoParryActive = false
local autoParryConn = nil
_G.autoParryLabel = nil

local function canParry()
    local char = player.Character; if not char then return false end
    -- FIX: Use GetAttribute and check truthiness properly.
    -- ParryCD is a number/timestamp when on cooldown, nil or 0 when ready.
    local pcd = char:GetAttribute("ParryCD")
    if pcd and pcd ~= false and pcd ~= 0 then return false end
    -- FIX: FindFirstChild returns the object, not a bool. Check Value property.
    local function boolBlock(name)
        local v = char:FindFirstChild(name)
        if not v then return false end
        if v:IsA("BoolValue") then return v.Value end
        return true -- exists as a non-BoolValue instance = blocked
    end
    if boolBlock("NoParry") then return false end
    if boolBlock("UsingMove") then return false end
    if boolBlock("LightAttack") then return false end
    if boolBlock("HeavyAttack") then return false end
    if boolBlock("Grabbed") then return false end
    if boolBlock("Knocked") then return false end
    if boolBlock("Ragdolled") then return false end
    if char:HasTag("FragileParry") then return false end
    return true
end

local function doParry(attackType)
    if not canParry() then
        if _G.autoParryLabel then _G.autoParryLabel.Text = "ON — ✗ can't parry" end
        return false
    end
    local ok = pcall(function() RS.Events.ParryActivate:FireServer() end)
    if _G.autoParryLabel then
        _G.autoParryLabel.Text = ok
            and ("ON — ✓ " .. tostring(attackType or "attack"))
            or  "ON — ✗ failed"
    end
    return ok
end

_G.startAutoParry = function()
    if autoParryConn then autoParryConn:Disconnect(); autoParryConn = nil end
    autoParryActive = true
    if _G.autoParryLabel then _G.autoParryLabel.Text = "ON — waiting..." end
    -- FIX: attacker arg is a STRING (attacker name), NOT a Model instance.
    -- The old code called attacker:FindFirstChild() on a string, which errored
    -- silently every time and swallowed the entire parry attempt.
    -- Also skip Unblockable attacks — they can't be parried.
    autoParryConn = RS.Events.PerilousAttack.OnClientEvent:Connect(function(attackerName, attackType)
        if not autoParryActive then return end
        if tostring(attackType) == "Unblockable" then
            if _G.autoParryLabel then _G.autoParryLabel.Text = "ON — skip Unblockable" end
            return
        end
        task.delay(math.random(50, 120) / 1000, function()
            if not autoParryActive then return end
            doParry(attackType)
        end)
    end)
end

_G.stopAutoParry = function()
    autoParryActive = false
    if autoParryConn then autoParryConn:Disconnect(); autoParryConn = nil end
    if _G.autoParryLabel then _G.autoParryLabel.Text = "OFF" end
end

_G.isAutoParryActive = function() return autoParryActive end

player.CharacterAdded:Connect(function()
    if autoParryActive then
        if autoParryConn then autoParryConn:Disconnect(); autoParryConn = nil end
        task.wait(1); _G.startAutoParry()
    end
end)

-- =====================
-- FLY
-- =====================
local flyActive = false; local flyConn = nil; local flyBV = nil; local flyBG = nil
local FLY_SPEED = 60

_G.startFly = function()
    local char = player.Character; if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    flyActive = true; hum.PlatformStand = true
    flyBV = Instance.new("BodyVelocity"); flyBV.Name = "FlyVelocity"
    flyBV.Velocity = Vector3.new(0,0,0); flyBV.MaxForce = Vector3.new(1e5,1e5,1e5); flyBV.Parent = hrp
    flyBG = Instance.new("BodyGyro"); flyBG.Name = "FlyGyro"
    flyBG.MaxTorque = Vector3.new(1e5,1e5,1e5); flyBG.D = 100
    flyBG.CFrame = hrp.CFrame; flyBG.Parent = hrp
    local camera = workspace.CurrentCamera
    flyConn = RunService.Heartbeat:Connect(function()
        if not flyActive then return end
        local c2 = player.Character; if not c2 then return end
        local h2 = c2:FindFirstChild("HumanoidRootPart"); if not h2 or h2 ~= hrp then return end
        local move = Vector3.new(0,0,0)
        local cf = camera.CFrame
        local flat = Vector3.new(cf.LookVector.X,0,cf.LookVector.Z).Unit
        local right = Vector3.new(cf.RightVector.X,0,cf.RightVector.Z).Unit
        if UIS:IsKeyDown(Enum.KeyCode.W) then move = move + flat end
        if UIS:IsKeyDown(Enum.KeyCode.S) then move = move - flat end
        if UIS:IsKeyDown(Enum.KeyCode.D) then move = move + right end
        if UIS:IsKeyDown(Enum.KeyCode.A) then move = move - right end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then move = move * 2.5 end
        flyBV.Velocity = move.Magnitude > 0 and move.Unit * FLY_SPEED or Vector3.new(0,0,0)
        flyBG.CFrame = CFrame.new(h2.Position, h2.Position + flat)
    end)
end

_G.stopFly = function()
    flyActive = false
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if flyBV then flyBV:Destroy(); flyBV = nil end
    if flyBG then flyBG:Destroy(); flyBG = nil end
    local char = player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end
end

_G.isFlyActive = function() return flyActive end

-- =====================
-- NOCLIP
-- =====================
local noclipActive = false; local noclipConn = nil

_G.startNoclip = function()
    noclipActive = true
    noclipConn = RunService.Heartbeat:Connect(function()
        if not noclipActive then return end
        local char = player.Character; if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
        end
    end)
end

_G.stopNoclip = function()
    noclipActive = false
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    local char = player.Character
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = true end
        end
    end
end

_G.isNoclipActive = function() return noclipActive end

player.CharacterAdded:Connect(function()
    flyActive = false; noclipActive = false
    flyBV = nil; flyBG = nil; flyConn = nil; noclipConn = nil
end)

-- =====================
-- SERVER HOPPER
-- =====================
_G.serverHopLabel = nil

_G.hopToLowServer = function(maxPlayers)
    maxPlayers = maxPlayers or 3
    local servers = RS:FindFirstChild("Servers"); if not servers then return end
    local list = {}
    for _, folder in ipairs(servers:GetChildren()) do
        local players = folder:GetAttribute("ServerPlayers")
        local jobID = folder:GetAttribute("JobID")
        local name = folder:GetAttribute("ServerName")
        local max = folder:GetAttribute("ServerPlayersMax")
        local perm = folder:GetAttribute("Permadeath")
        if players ~= nil and jobID and not perm then
            table.insert(list, {players=players, max=max or 18, jobID=jobID, name=name or "?"})
        end
    end
    table.sort(list, function(a,b) return a.players < b.players end)
    if #list == 0 then
        if _G.serverHopLabel then _G.serverHopLabel.Text = "No servers found" end; return
    end
    local currentJobId = game.JobId
    for _, s in ipairs(list) do
        if s.players <= maxPlayers and s.jobID ~= currentJobId then
            if _G.serverHopLabel then _G.serverHopLabel.Text = string.format("Joining: %s (%d players)", s.name, s.players) end
            pcall(function() RS.Events.JoinServer:FireServer(s.jobID) end); return
        end
    end
    local best = list[1]
    if best and best.jobID ~= currentJobId then
        if _G.serverHopLabel then _G.serverHopLabel.Text = string.format("Best: %s (%d/%d)", best.name, best.players, best.max) end
        pcall(function() RS.Events.JoinServer:FireServer(best.jobID) end)
    else
        if _G.serverHopLabel then _G.serverHopLabel.Text = "Already in lowest server" end
    end
end

-- =====================
-- DIALOGUE
--
-- CONFIRMED structure (from live dump):
--   Options (Frame) > Scroll (ScrollingFrame) > "Option" (Frame) > OptionButton (TextButton) + OptionText (TextLabel)
--
-- CONFIRMED: OptionButton has Click:1 Down:1 Activated:1 connections.
-- OptionText holds the visible text — OptionButton.Text is empty.
--
-- FIX: Removed GuiService navigation (it interferes with the Handler).
--      Fire MouseButton1Click directly via firesignal.
--      Sort frames by AbsolutePosition.Y (already correct).
-- =====================
local talkRemote = RS.Events.Talk
local lastTalkText = ""
local lastTalkTime = 0

talkRemote.OnClientEvent:Connect(function(_, text)
    lastTalkText = text or ""
    lastTalkTime = tick()
end)

local function getTextAnimDuration(text)
    local t = 0
    for i = 1, #text do
        local c = text:sub(i,i)
        if c == "." or c == "?" or c == "!" then t = t + 0.1
        elseif c ~= " " then t = t + 0.015 end
    end
    return t + 0.2
end

_G.waitForTalk = function(containsText, timeoutSecs)
    lastTalkText = ""; lastTalkTime = 0
    local deadline = tick() + (timeoutSecs or 8)
    while tick() < deadline and _G.farmRunning do
        if lastTalkText:lower():find(containsText:lower(), 1, true) then
            local elapsed = tick() - lastTalkTime
            local remaining = getTextAnimDuration(lastTalkText) - elapsed
            if remaining > 0 then task.wait(remaining) end
            return true
        end
        task.wait(0.05)
    end
    return false
end

-- Wait for Options panel to have buttons
local function waitForOptions(timeoutSecs)
    local pgui = player.PlayerGui
    local deadline = tick() + (timeoutSecs or 8)
    while tick() < deadline and _G.farmRunning do
        local dlg = pgui:FindFirstChild("Dialogue")
        if dlg and dlg.Enabled then
            local scroll
            pcall(function() scroll = dlg.MainFrame.Options.Scroll end)
            if scroll then
                -- FIX: Check AbsoluteSize of Options, not Scroll CanvasSize (canvas stays 0,0)
                local optionsVisible = false
                pcall(function() optionsVisible = dlg.MainFrame.Options.AbsoluteSize.Y > 10 end)
                if optionsVisible then
                    local count = 0
                    for _, c in ipairs(scroll:GetChildren()) do
                        if not c:IsA("UIListLayout") then count += 1 end
                    end
                    if count > 0 then return scroll end
                end
            end
        end
        task.wait(0.05)
    end
    return nil
end

-- Sort Option frames by Y, return their OptionButton children in order
local function getSortedOptionButtons(scroll)
    local frames = {}
    for _, item in ipairs(scroll:GetChildren()) do
        if not item:IsA("UIListLayout") then
            table.insert(frames, item)
        end
    end
    table.sort(frames, function(a, b)
        return a.AbsolutePosition.Y < b.AbsolutePosition.Y
    end)
    local buttons = {}
    for _, frame in ipairs(frames) do
        local btn = frame:FindFirstChild("OptionButton")
        if btn and btn:IsA("TextButton") then
            table.insert(buttons, btn)
        else
            local any = frame:FindFirstChildOfClass("TextButton")
            if any then table.insert(buttons, any) end
        end
    end
    return buttons
end

-- FIX: Removed GuiService navigation entirely — it was interfering with the game's Handler.
-- Simply firesignal MouseButton1Click directly. That connection is confirmed to exist (1 conn).
local function fireButtonSignals(btn)
    -- Try MouseButton1Click first (confirmed 1 connection)
    local fired = false
    pcall(function()
        local conns = getconnections(btn.MouseButton1Click)
        if #conns > 0 then
            firesignal(btn.MouseButton1Click)
            fired = true
        end
    end)
    if fired then return true end
    -- Fallback: MouseButton1Down, then Activated
    pcall(function() firesignal(btn.MouseButton1Down) end)
    pcall(function() firesignal(btn.Activated) end)
    return false
end

-- navDialogue(0) = 1st option, navDialogue(1) = 2nd option, etc.
_G.navDialogue = function(buttonIndex, timeoutSecs)
    local scroll = waitForOptions(timeoutSecs or 8)
    if not scroll then
        _G.setStatus("navDialogue: options timed out")
        return false
    end

    local buttons = getSortedOptionButtons(scroll)
    if #buttons == 0 then
        _G.setStatus("navDialogue: no OptionButtons found")
        return false
    end

    local idx = (buttonIndex or 0) + 1  -- 0-based to 1-based
    if idx > #buttons then
        _G.setStatus("navDialogue: index " .. tostring(buttonIndex) .. " OOB (" .. #buttons .. " buttons)")
        return false
    end

    local target = buttons[idx]

    -- FIX: Removed GuiService navigation — no more SelectedObject, no more GuiNavigationEnabled.
    -- Just fire the button directly.
    fireButtonSignals(target)
    task.wait(0.2)

    return true
end

-- =====================
-- FARM HELPERS
-- =====================
_G.findDocksNPC = function()
    local folders = {workspace}
    local alive = workspace:FindFirstChild("Alive"); if alive then table.insert(folders, alive) end
    local npcsF = workspace:FindFirstChild("NPCS"); if npcsF then table.insert(folders, npcsF) end
    for _, folder in ipairs(folders) do
        for _, obj in ipairs(folder:GetChildren()) do
            if obj:IsA("Model") and obj.Name == "Twinhook Pirate" then
                local hrp = obj:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local pos = hrp.Position
                    if pos.X < -800 and pos.Z > 800 and pos.Z < 1000 then
                        local prompt = obj:FindFirstChild("InteractPrompt", true)
                        if prompt then return obj, prompt, pos end
                    end
                end
            end
        end
    end
    return nil, nil, nil
end

_G.findShipmentPrompt = function()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local ok, pos = pcall(function() return obj.Parent.Position end)
            if ok and pos.X < -800 and pos.X > -1400 and pos.Z > 700 and pos.Z < 1100 then
                local parent = obj.Parent
                if not parent:FindFirstChildOfClass("Humanoid") and
                   not (parent.Parent and parent.Parent:FindFirstChildOfClass("Humanoid")) then
                    return obj, pos
                end
            end
        end
    end
    return nil, nil
end

-- =====================
-- FARM LOOP
-- navDialogue(0) = "Show me the available jobs."  (1st button)
-- navDialogue(?) = Docks Delivery — UPDATE index once confirmed in-game
-- navDialogue(2) = "I'm here to turn this in."   (3rd button)
-- =====================
_G.runDocksDeliveryFarm = function()
    local teleportTo = _G.teleportTo
    local firePrompt = _G.firePrompt
    local waitSec = _G.waitSec
    local setStatus = _G.setStatus
    local waitForTalk = _G.waitForTalk
    local navDialogue = _G.navDialogue
    local findDocksNPC = _G.findDocksNPC
    local findShipment = _G.findShipmentPrompt

    while _G.farmRunning do

        setStatus("Going to Office Contractor...")
        teleportTo(CFrame.new(_G.OFFICE_CONTRACTOR_POS + Vector3.new(0,0,3)))
        waitSec(1.5); if not _G.farmRunning then break end

        setStatus("Talking to Office Contractor...")
        local npc = workspace.NPCS:FindFirstChild("Office Contractor")
        if not npc then setStatus("NPC not found!"); waitSec(3); break end
        local prompt = npc:FindFirstChild("InteractPrompt", true)
        if prompt then firePrompt(prompt) end

        setStatus("Waiting for greeting...")
        local gotGreeting = waitForTalk("jobs here", 6)
        if not gotGreeting then setStatus("No greeting, retrying..."); waitSec(2) end
        if not _G.farmRunning then break end

        setStatus("Clicking 'Show me the available jobs.'...")
        navDialogue(0, 6)
        if not _G.farmRunning then break end

        setStatus("Waiting for jobs list...")
        local gotJobs = waitForTalk("jobs currently available", 7)
        if gotJobs then
            setStatus("Clicking Docks Delivery...")
            navDialogue(0, 6)  -- <-- UPDATE THIS INDEX once confirmed in-game
        else
            setStatus("Jobs list not received, restarting...")
            waitSec(3)
        end
        if not _G.farmRunning then break end

        setStatus("Waiting for contract...")
        local contractConfirmed = false
        local contractConn = RS.Events.CreateContract.OnClientEvent:Connect(function(name)
            if tostring(name):lower():find("docks", 1, true) then contractConfirmed = true end
        end)
        local t = tick()
        while tick()-t < 5 and not contractConfirmed and _G.farmRunning do task.wait(0.1) end
        contractConn:Disconnect()
        setStatus(contractConfirmed and "DocksDelivery confirmed ✓" or "Unconfirmed, continuing...")
        waitSec(1); if not _G.farmRunning then break end

        setStatus("Going to docks...")
        teleportTo(CFrame.new(_G.DOCKS_CENTER))
        waitSec(1.5); if not _G.farmRunning then break end

        setStatus("Waiting for Twinhook Pirate...")
        local docksNPC, docksPrompt, docksPos = findDocksNPC()
        local dAttempts = 0
        while not docksNPC and dAttempts < 12 and _G.farmRunning do
            task.wait(1); docksNPC, docksPrompt, docksPos = findDocksNPC(); dAttempts += 1
        end

        if docksNPC and docksPrompt and docksPos then
            setStatus("Talking to Twinhook Pirate...")
            teleportTo(CFrame.new(docksPos + Vector3.new(0,0,3)))
            waitSec(0.8); firePrompt(docksPrompt)
            local gotPirate = waitForTalk("shipment", 5)
            if gotPirate then navDialogue(0, 3) end
            waitSec(1)
        else
            setStatus("Pirate not found, continuing...")
        end
        if not _G.farmRunning then break end

        setStatus("Looking for shipment...")
        local shipPrompt, shipPos = findShipment()
        local sAttempts = 0
        while not shipPrompt and sAttempts < 8 and _G.farmRunning do
            teleportTo(CFrame.new(_G.DOCKS_CARGO_POSITIONS[(sAttempts % #_G.DOCKS_CARGO_POSITIONS)+1]))
            waitSec(0.8); shipPrompt, shipPos = findShipment(); sAttempts += 1
        end

        if shipPrompt and shipPos then
            setStatus("Picking up shipment...")
            teleportTo(CFrame.new(shipPos + Vector3.new(0,0,2)))
            waitSec(0.8); firePrompt(shipPrompt); waitSec(1.5)
        else
            setStatus("Shipment not found, restarting..."); waitSec(3)
        end
        if not _G.farmRunning then break end

        setStatus("Returning to turn in...")
        teleportTo(CFrame.new(_G.OFFICE_CONTRACTOR_POS + Vector3.new(0,0,3)))
        waitSec(1.5); if not _G.farmRunning then break end

        local turnInDone = false
        local turnInAttempts = 0
        while not turnInDone and turnInAttempts < 3 and _G.farmRunning do
            turnInAttempts += 1
            setStatus("Talking to turn in (attempt " .. turnInAttempts .. ")...")
            if prompt then firePrompt(prompt) end

            local gotGreeting2 = waitForTalk("jobs here", 6)
            if gotGreeting2 then
                setStatus("Clicking 'I'm here to turn this in.'...")
                navDialogue(2, 6)
            end

            local deadline = tick() + 4
            while tick() < deadline and _G.farmRunning do
                local pgui = player.PlayerGui
                local stats = pgui:FindFirstChild("Stats")
                local found = false
                if stats then
                    local active = stats:FindFirstChild("ContractsActive")
                    if active then
                        for _, child in ipairs(active:GetChildren()) do
                            local ok, ct = pcall(function() return child.ContractName.Text end)
                            if ok and ct and ct:lower():find("docks", 1, true) then found = true; break end
                        end
                    end
                end
                if not found then turnInDone = true; break end
                task.wait(0.2)
            end

            if not turnInDone and turnInAttempts < 3 then
                setStatus("Turn-in not confirmed, retrying..."); waitSec(1)
            end
        end

        setStatus(turnInDone and "Contract complete ✓" or "Turn-in failed, restarting loop...")
        if not _G.farmRunning then break end
        setStatus("Cooldown..."); waitSec(3)
    end

    setStatus("Stopped")
end

print("[modules] loaded")
