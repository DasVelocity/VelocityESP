-- Velocity ESP Library v1.0
-- Inspired by various Roblox ESP implementations
-- Features: Box, Tracer, Name (Text), Health, Distance
-- GlobalConfig: IgnoreCharacter (uses Camera for positioning)
-- Usage: VelocityESP:Add(playerInstance, {Type = "Box", Color = Color3.new(1,0,0), ...})
-- Call VelocityESP:Render() in a loop or RenderStepped

local VelocityESP = {}
VelocityESP.__index = VelocityESP

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Global configuration
getgenv().VelocityESP_GlobalConfig = getgenv().VelocityESP_GlobalConfig or {
    IgnoreCharacter = false,  -- If true, uses Camera instead of Character RootPart for relative positioning
    DefaultColor = Color3.fromRGB(255, 255, 255),
    TeamCheck = true,         -- Don't ESP teammates
    Thickness = 1,
    Transparency = 1,
    TracerFrom = "Bottom",    -- "Bottom", "Top", "Center", or Vector2 screen point
    StorageFolder = Instance.new("Folder")  -- To parent invisible elements and avoid render limits
}
local GlobalConfig = getgenv().VelocityESP_GlobalConfig

GlobalConfig.StorageFolder.Name = "VelocityESP_Storage"
GlobalConfig.StorageFolder.Parent = Camera  -- Parent to Camera to persist

-- Internal storage
local ESPObjects = {}
local Connections = {}

-- Helper functions
local function GetRoot(part)
    return part:FindFirstAncestorOfClass("Model") and part:FindFirstAncestorOfClass("Model"):FindFirstChild("HumanoidRootPart") or part.PrimaryPart
end

local function GetTeam(player)
    return player.Team
end

local function IsValidTarget(target)
    if not target or not target:IsA("Player") then return false end
    if GlobalConfig.TeamCheck and GetTeam(target) == GetTeam(LocalPlayer) then return false end
    local character = target.Character
    if not character or not character:FindFirstChild("Humanoid") or character.Humanoid.Health <= 0 then return false end
    return true
end

local function WorldToScreen(pos)
    local screen, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(screen.X, screen.Y), onScreen, screen.Z
end

local function GetBoundingBox(model)
    local parts = model:GetDescendants()
    local minVec, maxVec = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
    for _, part in ipairs(parts) do
        if part:IsA("BasePart") then
            local cf = part.CFrame
            local size = part.Size / 2
            for i = 1, 8 do
                local corner = cf * Vector3.new(size.X * (i%2==0 and 1 or -1), size.Y * (math.floor(i/2)%2==0 and 1 or -1), size.Z * (math.floor(i/4)%2==0 and 1 or -1))
                minVec = minVec:Min(corner)
                maxVec = maxVec:Max(corner)
            end
        end
    end
    return minVec, maxVec
end

-- Create new ESP for a target
function VelocityESP:Add(target, options)
    if not IsValidTarget(target) then return end
    
    options = options or {}
    local espType = options.Type or "Box"  -- "Box", "Tracer", "Text", "Health", "Distance"
    local color = options.Color or GlobalConfig.DefaultColor
    local thickness = options.Thickness or GlobalConfig.Thickness
    local transparency = options.Transparency or GlobalConfig.Transparency
    
    local drawingObj
    if espType == "Box" then
        drawingObj = Drawing.new("Quad")
        drawingObj.Filled = false
    elseif espType == "Tracer" then
        drawingObj = Drawing.new("Line")
    elseif espType == "Text" or espType == "Distance" then
        drawingObj = Drawing.new("Text")
        drawingObj.Size = options.Size or 13
        drawingObj.Center = true
    elseif espType == "Health" then
        drawingObj = Drawing.new("Line")  -- For health bar
    else
        error("Invalid ESPType: " .. espType)
    end
    
    drawingObj.Color = color
    drawingObj.Thickness = thickness
    drawingObj.Transparency = transparency
    drawingObj.Visible = false
    
    -- Store per target
    ESPObjects[target] = ESPObjects[target] or {}
    table.insert(ESPObjects[target], {Obj = drawingObj, Type = espType, Options = options})
end

-- Remove ESP for a target
function VelocityESP:Remove(target)
    if ESPObjects[target] then
        for _, esp in ipairs(ESPObjects[target]) do
            esp.Obj:Remove()
        end
        ESPObjects[target] = nil
    end
end

-- Render/update all ESP
function VelocityESP:Render()
    for target, esps in pairs(ESPObjects) do
        if not IsValidTarget(target) then
            self:Remove(target)
            continue
        end
        
        local character = target.Character
        local root = GetRoot(character)
        if not root then continue end
        
        local refPos = GlobalConfig.IgnoreCharacter and Camera.CFrame.Position or (LocalPlayer.Character and GetRoot(LocalPlayer.Character).Position) or Camera.CFrame.Position
        local dist = (refPos - root.Position).Magnitude
        
        local headPos = character:FindFirstChild("Head") and character.Head.Position or root.Position + Vector3.new(0, 2, 0)
        local footPos = root.Position - Vector3.new(0, 3, 0)
        
        local headScreen, headOnScreen = WorldToScreen(headPos)
        local footScreen, footOnScreen = WorldToScreen(footPos)
        
        if not headOnScreen or not footOnScreen then
            for _, esp in ipairs(esps) do esp.Obj.Visible = false end
            continue
        end
        
        local height = math.abs(headScreen.Y - footScreen.Y)
        local width = height / 2
        
        for _, esp in ipairs(esps) do
            local obj = esp.Obj
            obj.Visible = true
            
            if esp.Type == "Box" then
                local minVec, maxVec = GetBoundingBox(character)
                local corners = {
                    WorldToScreen(minVec),
                    WorldToScreen(Vector3.new(maxVec.X, minVec.Y, minVec.Z)),
                    WorldToScreen(maxVec),
                    WorldToScreen(Vector3.new(minVec.X, maxVec.Y, minVec.Z))
                }
                obj.PointA = corners[1]
                obj.PointB = corners[2]
                obj.PointC = corners[3]
                obj.PointD = corners[4]
            elseif esp.Type == "Tracer" then
                local from
                if GlobalConfig.TracerFrom == "Bottom" then
                    from = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                elseif GlobalConfig.TracerFrom == "Top" then
                    from = Vector2.new(Camera.ViewportSize.X / 2, 0)
                elseif GlobalConfig.TracerFrom == "Center" then
                    from = Camera.ViewportSize / 2
                else
                    from = GlobalConfig.TracerFrom
                end
                obj.From = from
                obj.To = footScreen
            elseif esp.Type == "Text" then
                obj.Text = target.Name
                obj.Position = headScreen + Vector2.new(0, -obj.TextBounds.Y / 2 - 5)
            elseif esp.Type == "Distance" then
                obj.Text = math.floor(dist) .. " studs"
                obj.Position = footScreen + Vector2.new(0, 10)
            elseif esp.Type == "Health" then
                local humanoid = character.Humanoid
                local healthPercent = humanoid.Health / humanoid.MaxHealth
                obj.From = footScreen + Vector2.new(-width / 2 - 5, 0)
                obj.To = obj.From + Vector2.new(0, -height * healthPercent)
                obj.Color = Color3.fromHSV(healthPercent / 3, 1, 1)  -- Green to red
            end
        end
    end
end

-- Destroy the library
function VelocityESP:Destroy()
    for target in pairs(ESPObjects) do
        self:Remove(target)
    end
    for _, conn in ipairs(Connections) do
        conn:Disconnect()
    end
    GlobalConfig.StorageFolder:Destroy()
    Connections = {}
    ESPObjects = {}
end

-- Auto-add all players and handle joins/leaves
local function SetupAutoESP()
    local function AddPlayer(player)
        if player ~= LocalPlayer then
            -- Example: Add default ESP types
            VelocityESP:Add(player, {Type = "Box"})
            VelocityESP:Add(player, {Type = "Tracer"})
            VelocityESP:Add(player, {Type = "Text"})
            VelocityESP:Add(player, {Type = "Distance"})
            VelocityESP:Add(player, {Type = "Health"})
        end
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        AddPlayer(player)
    end
    
    table.insert(Connections, Players.PlayerAdded:Connect(AddPlayer))
    table.insert(Connections, Players.PlayerRemoving:Connect(function(player)
        VelocityESP:Remove(player)
    end))
    
    -- Render loop
    table.insert(Connections, RunService.RenderStepped:Connect(function()
        pcall(VelocityESP.Render, VelocityESP)  -- Error handling
    end))
end

-- Initialize if desired (call manually if needed)
-- SetupAutoESP()

getgenv().Velocity_ESP = VelocityESP
return VelocityESP
