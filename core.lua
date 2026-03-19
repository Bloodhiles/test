-- core.lua
-- Shared state and utilities
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Expose globally
_G.player = player
_G.RS = RS
_G.RunService = RunService
_G.farmRunning = false

-- =====================
-- CLEANUP
-- =====================
local function cleanup()
    local containers = {}
    pcall(function() containers[#containers+1] = gethui and gethui() end)
    pcall(function() containers[#containers+1] = game:GetService("CoreGui") end)
    pcall(function() containers[#containers+1] = player.PlayerGui end)
    for _, c in ipairs(containers) do
        if c then
            for _, ch in ipairs(c:GetChildren()) do
                if ch:IsA("ScreenGui") and ch:FindFirstChild("NPCTeleportPanel") then ch:Destroy() end
            end
        end
    end
end
cleanup()

-- =====================
-- SECURE GUI
-- =====================
_G.secureGui = function(gui)
    local randName = ""
    for i = 1, 20 do randName = randName .. string.char(math.random(65, 122)) end
    gui.Name = randName
    if gethui then gui.Parent = gethui()
    elseif syn and syn.protect_gui then syn.protect_gui(gui); gui.Parent = game:GetService("CoreGui")
    elseif protect_gui then protect_gui(gui); gui.Parent = game:GetService("CoreGui")
    elseif protectgui then protectgui(gui); gui.Parent = game:GetService("CoreGui")
    else
        local ok, cg = pcall(function() return game:GetService("CoreGui") end)
        if ok then gui.Parent = cg else gui.Parent = player:WaitForChild("PlayerGui") end
    end
end

-- =====================
-- TELEPORT
-- =====================
local function trySetHidden(inst, prop, val)
    return pcall(function() sethiddenproperty(inst, prop, val) end)
end
local function forceCFrame(hrp, cf)
    local n = 0; local c
    c = RunService.Heartbeat:Connect(function()
        n = n + 1; hrp.CFrame = cf
        if n >= 4 then c:Disconnect() end
    end)
end
local function nudgeTeleport(hrp, cf, steps)
    steps = steps or 6; local start = hrp.CFrame; local n = 0; local c
    c = RunService.Heartbeat:Connect(function()
        n = n + 1; hrp.CFrame = start:Lerp(cf, n/steps)
        if n >= steps then c:Disconnect(); hrp.CFrame = cf end
    end)
end
_G.teleportTo = function(cf)
    local char = player.Character; if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local ok = pcall(function() hrp.CFrame = cf end)
    if not ok then
        if not trySetHidden(hrp, "CFrame", cf) then nudgeTeleport(hrp, cf) end
    else forceCFrame(hrp, cf) end
end

-- =====================
-- UTILITIES
-- =====================
_G.waitSec = function(s)
    local t = tick()
    repeat task.wait(0.05) until tick()-t >= s or not _G.farmRunning
end

_G.firePrompt = function(prompt)
    if not prompt then return end
    local ok = pcall(function() fireproximityprompt(prompt) end)
    if not ok then
        local remote = prompt.Parent:FindFirstChild("TalkToNPC")
            or (prompt.Parent.Parent and prompt.Parent.Parent:FindFirstChild("TalkToNPC"))
        if remote then pcall(function() remote:FireServer() end) end
    end
end

_G.setStatus = function(msg)
    if _G.farmStatusLabel then _G.farmStatusLabel.Text = "◈ " .. msg end
end

-- Positions
_G.OFFICE_CONTRACTOR_POS = Vector3.new(439.25, -7.5, 430.5)
_G.DOCKS_CENTER = Vector3.new(-867, -10, 877)
_G.DOCKS_CARGO_POSITIONS = {
    Vector3.new(-1229.76, -10, 860.9), Vector3.new(-1250.96, -10, 860.9),
    Vector3.new(-1250.96, -10, 897.9), Vector3.new(-1229.76, -10, 885.7),
    Vector3.new(-1212.26, -10, 868.0), Vector3.new(-1212.26, -10, 901.4),
}

print("[core] loaded")
