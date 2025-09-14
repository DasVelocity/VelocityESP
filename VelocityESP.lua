local VelocityESP = {}
VelocityESP.__index = VelocityESP

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

getgenv().VelocityESP_GlobalConfig = getgenv().VelocityESP_GlobalConfig or {
    IgnoreCharacter = false,
    DefaultColor = Color3.fromRGB(255, 255, 255),
    TeamCheck = true,
    Thickness = 1,
    Transparency = 1,
    TracerFrom = "Bottom",
    StorageFolder = Instance.new("Folder")
}
local GlobalConfig = getgenv().VelocityESP_GlobalConfig

GlobalConfig.StorageFolder.Name = "VelocityESP_Storage"
GlobalConfig.StorageFolder.Parent = Camera

local ESPObjects = {}
local Connections = {}
local IsRunning = false

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
    local cf, size = model:GetBoundingBox()
    local minVec = cf.Position - size / 2
    local maxVec = cf.Position + size / 2
    return minVec, maxVec
end

function VelocityESP:Add(target, options)
    if not IsValidTarget(target) then return end
    
    options = options or {}
    local espTypes = options.Types or {"Box", "Tracer", "Text", "Distance", "Health"}
    local color = options.Color or GlobalConfig.DefaultColor
    local thickness = options.Thickness or GlobalConfig.Thickness
    local transparency = options.Transparency or GlobalConfig.Transparency
    
    ESPObjects[target] = ESPObjects[target] or {}
    
    for _, espType in ipairs(espTypes) do
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
            drawingObj.Font = 2
            drawingObj.Outline = true
        elseif espType == "Health" then
            drawingObj = Drawing.new("Line")
            drawingObj.Thickness = 3
        else
            continue
        end
        
        drawingObj.Color = color
        drawingObj.Thickness = thickness
        drawingObj.Transparency = transparency
        drawingObj.Visible = false
        
        table.insert(ESPObjects[target], {Obj = drawingObj, Type = espType, Options = options})
    end
end

function VelocityESP:Remove(target)
    if ESPObjects[target] then
        for _, esp in ipairs(ESPObjects[target]) do
            if esp.Obj then esp.Obj:Remove() end
        end
        ESPObjects[target] = nil
    end
end

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
                local _, maxVec = GetBoundingBox(character)
                local corners = {
                    WorldToScreen(character:GetBoundingBox().Position - character:GetBoundingBox().Size / 2),
                    WorldToScreen(Vector3.new(maxVec.X, minVec.Y, minVec.Z)), -- Simplified; use proper corners if needed
                    WorldToScreen(maxVec),
                    WorldToScreen(Vector3.new(minVec.X, maxVec.Y, minVec.Z))
                }
                obj.PointA = Vector2.new(headScreen.X - width, headScreen.Y)
                obj.PointB = Vector2.new(headScreen.X + width, headScreen.Y)
                obj.PointC = Vector2.new(footScreen.X + width, footScreen.Y)
                obj.PointD = Vector2.new(footScreen.X - width, footScreen.Y)
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
                obj.Position = headScreen + Vector2.new(0, - (obj.TextBounds and obj.TextBounds.Y or 13) / 2 - 5)
            elseif esp.Type == "Distance" then
                obj.Text = math.floor(dist) .. " studs"
                obj.Position = footScreen + Vector2.new(0, 10)
            elseif esp.Type == "Health" then
                local humanoid = character:FindFirstChild("Humanoid")
                if humanoid then
                    local healthPercent = humanoid.Health / humanoid.MaxHealth
                    local barHeight = height * healthPercent
                    obj.From = footScreen + Vector2.new(-width - 6, 0)
                    obj.To = footScreen + Vector2.new(-width - 6, -barHeight)
                    obj.Color = Color3.fromHSV((1 - healthPercent) / 3, 1, 1)  -- Red to green
                end
            end
        end
    end
end

function VelocityESP:UpdateConfig(options)
    for key, value in pairs(options or {}) do
        if key == "TeamCheck" then GlobalConfig.TeamCheck = value end
        if key == "DefaultColor" then GlobalConfig.DefaultColor = value end
        if key == "Thickness" then GlobalConfig.Thickness = value end
        if key == "Transparency" then GlobalConfig.Transparency = value end
        if key == "TracerFrom" then GlobalConfig.TracerFrom = value end
        if key == "IgnoreCharacter" then GlobalConfig.IgnoreCharacter = value end
    end
end

function VelocityESP:AddPlayerESP(player, options)
    self:UpdateConfig(options)
    if player then
        self:Add(player, options)
    else
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                self:Add(p, options)
            end
        end
    end
end

function VelocityESP:AddAllPlayersESP(options)
    self:AddPlayerESP(nil, options)
end

function VelocityESP:Start(options)
    if IsRunning then return end
    IsRunning = true
    self:AddAllPlayersESP(options or {})
    
    table.insert(Connections, Players.PlayerAdded:Connect(function(player)
        if options and options.AutoAddNew then
            self:Add(player, options)
        end
    end))
    
    table.insert(Connections, Players.PlayerRemoving:Connect(function(player)
        self:Remove(player)
    end))
    
    table.insert(Connections, RunService.RenderStepped:Connect(function()
        pcall(self.Render, self)
    end))
end

function VelocityESP:Stop()
    if not IsRunning then return end
    IsRunning = false
    for _, conn in ipairs(Connections) do
        conn:Disconnect()
    end
    Connections = {}
    for target in pairs(ESPObjects) do
        self:Remove(target)
    end
end

function VelocityESP:Destroy()
    self:Stop()
    if GlobalConfig.StorageFolder then
        GlobalConfig.StorageFolder:Destroy()
    end
    ESPObjects = {}
end

getgenv().Velocity_ESP = VelocityESP
return VelocityESP
