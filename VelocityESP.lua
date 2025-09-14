-- VelocityESP fixed module
-- Designed for exploit environments that support the Drawing API

local VelocityESP = {}
VelocityESP.__index = VelocityESP

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Global config (use getgenv so user can change at runtime if needed)
getgenv().VelocityESP_GlobalConfig = getgenv().VelocityESP_GlobalConfig or {
    IgnoreCharacter = false,
    DefaultColor = Color3.fromRGB(255, 0, 0),
    TeamCheck = true,
    Thickness = 1,
    Transparency = 1,
    TracerFrom = "Bottom", -- "Bottom", "Top", "Center" or Vector2
    StorageFolder = Instance.new("Folder")
}
local GlobalConfig = getgenv().VelocityESP_GlobalConfig
GlobalConfig.StorageFolder.Name = "VelocityESP_Storage"
GlobalConfig.StorageFolder.Parent = Camera

-- internal state
local ESPObjects = {} -- player -> { DrawObjects = {...}, Connections = {...}, Options = {} }
local Connections = {}
local IsRunning = false

-- feature-detect Drawing
local DrawingAvailable = (type(Drawing) == "table")

local function safeNewDrawing(typeName)
    if not DrawingAvailable then return nil end
    local ok, obj = pcall(function() return Drawing.new(typeName) end)
    if not ok then return nil end
    return obj
end

local function GetRoot(character)
    if not character then return nil end
    local root = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
    return root
end

local function GetTeam(player)
    -- simple wrapper; some games store teams differently
    return player.Team
end

local function IsValidTarget(player)
    if not player or not player:IsA("Player") then return false end
    if player == LocalPlayer then return false end
    if GlobalConfig.TeamCheck and GetTeam(player) == GetTeam(LocalPlayer) then return false end
    local character = player.Character
    if not character then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    return true
end

local function WorldToScreenVec(vector3)
    if not Camera then Camera = Workspace.CurrentCamera end
    local screenPos, onScreen = Camera:WorldToViewportPoint(vector3)
    -- screenPos is a Vector3 where X,Y are screen coords and Z is depth
    return Vector2.new(screenPos.X, screenPos.Y), onScreen, screenPos.Z
end

local function CreateESPObjectsForPlayer(player, options)
    options = options or {}
    local types = options.Types or {"Box", "Tracer", "Text", "Distance", "Health"}
    local color = options.Color or GlobalConfig.DefaultColor
    local thickness = options.Thickness or GlobalConfig.Thickness
    local transparency = options.Transparency or GlobalConfig.Transparency
    
    local drawList = {}
    for _, typ in ipairs(types) do
        local obj
        if typ == "Box" then
            obj = safeNewDrawing("Quad")
            if obj then obj.Filled = false end
        elseif typ == "Tracer" then
            obj = safeNewDrawing("Line")
        elseif typ == "Text" or typ == "Distance" then
            obj = safeNewDrawing("Text")
            if obj then
                obj.Size = options.Size or 14
                obj.Center = true
                obj.Font = 2
                obj.Outline = true
            end
        elseif typ == "Health" then
            obj = safeNewDrawing("Line")
            if obj then obj.Thickness = 3 end
        else
            -- ignore unknown
        end
        if obj then
            obj.Color = color
            obj.Thickness = thickness
            obj.Transparency = transparency
            obj.Visible = false
            table.insert(drawList, {Obj = obj, Type = typ})
        end
    end
    return drawList
end

function VelocityESP:Add(player, options)
    if not player or not player:IsA("Player") then return end
    options = options or {}
    if ESPObjects[player] then
        -- update options
        ESPObjects[player].Options = options
        return
    end

    local entry = {
        DrawObjects = CreateESPObjectsForPlayer(player, options),
        Connections = {},
        Options = options
    }
    ESPObjects[player] = entry

    -- remove when player leaves
    table.insert(entry.Connections, player.AncestryChanged:Connect(function()
        -- if player removed from game
        if not player:IsDescendantOf(game) then
            VelocityESP:Remove(player)
        end
    end))

    -- respawn handling: re-add when character spawns
    table.insert(entry.Connections, player.CharacterAdded:Connect(function()
        -- small delay to let character set up
        task.wait(0.05)
        -- ensure we have draw objects (if new types requested)
        -- we keep draw objects persistent; Render will skip if invalid
    end))

    -- if character exists now and valid, keep it; Render will draw when valid
end

function VelocityESP:Remove(player)
    local entry = ESPObjects[player]
    if not entry then return end
    for _, esp in ipairs(entry.DrawObjects) do
        if esp.Obj and esp.Obj.Remove then
            pcall(function() esp.Obj:Remove() end)
        end
    end
    for _, conn in ipairs(entry.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    ESPObjects[player] = nil
end

function VelocityESP:Render()
    if not DrawingAvailable then return end
    for player, entry in pairs(ESPObjects) do
        local options = entry.Options or {}
        if not IsValidTarget(player) then
            -- hide drawing objects if invalid
            for _, d in ipairs(entry.DrawObjects) do
                if d.Obj then d.Obj.Visible = false end
            end
            continue
        end

        local character = player.Character
        local root = GetRoot(character)
        if not root then
            for _, d in ipairs(entry.DrawObjects) do if d.Obj then d.Obj.Visible = false end end
            continue
        end

        -- reference position for distance calculation
        local refPos
        if GlobalConfig.IgnoreCharacter or not (LocalPlayer and LocalPlayer.Character) then
            refPos = Camera.CFrame.Position
        else
            local localRoot = GetRoot(LocalPlayer.Character)
            refPos = (localRoot and localRoot.Position) or Camera.CFrame.Position
        end

        local dist = (refPos - root.Position).Magnitude

        local head = character:FindFirstChild("Head")
        local headPos = head and head.Position or root.Position + Vector3.new(0, 2, 0)
        local footPos = root.Position - Vector3.new(0, 3, 0)

        local headScreen, headOnScreen = WorldToScreenVec(headPos)
        local footScreen, footOnScreen = WorldToScreenVec(footPos)

        if not headOnScreen and not footOnScreen then
            for _, d in ipairs(entry.DrawObjects) do if d.Obj then d.Obj.Visible = false end end
            continue
        end

        -- simple box math using head/foot projection
        local height = math.max(20, math.abs(headScreen.Y - footScreen.Y))
        local width = height * 0.45

        for _, d in ipairs(entry.DrawObjects) do
            local obj = d.Obj
            if not obj then continue end
            obj.Visible = true
            if d.Type == "Box" then
                -- Quad points: top-left, top-right, bottom-right, bottom-left
                obj.PointA = Vector2.new(headScreen.X - width, headScreen.Y)
                obj.PointB = Vector2.new(headScreen.X + width, headScreen.Y)
                obj.PointC = Vector2.new(footScreen.X + width, footScreen.Y)
                obj.PointD = Vector2.new(footScreen.X - width, footScreen.Y)
            elseif d.Type == "Tracer" then
                local from
                if GlobalConfig.TracerFrom == "Bottom" then
                    from = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                elseif GlobalConfig.TracerFrom == "Top" then
                    from = Vector2.new(Camera.ViewportSize.X / 2, 0)
                elseif GlobalConfig.TracerFrom == "Center" then
                    from = Camera.ViewportSize / 2
                elseif typeof(GlobalConfig.TracerFrom) == "Vector2" then
                    from = GlobalConfig.TracerFrom
                else
                    from = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                end
                obj.From = from
                obj.To = footScreen
            elseif d.Type == "Text" then
                obj.Text = player.Name
                -- constant offset to avoid TextBounds nil issues
                obj.Position = headScreen + Vector2.new(0, -18)
            elseif d.Type == "Distance" then
                obj.Text = tostring(math.floor(dist)) .. " studs"
                obj.Position = footScreen + Vector2.new(0, 12)
            elseif d.Type == "Health" then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    local healthPercent = math.clamp(humanoid.Health / (humanoid.MaxHealth ~= 0 and humanoid.MaxHealth or 100), 0, 1)
                    local barHeight = height * healthPercent
                    obj.From = footScreen + Vector2.new(-width - 8, 0)
                    obj.To = footScreen + Vector2.new(-width - 8, -barHeight)
                    obj.Color = Color3.fromHSV((1 - healthPercent) / 3, 1, 1)
                else
                    obj.Visible = false
                end
            end
        end
    end
end

function VelocityESP:UpdateConfig(options)
    for k, v in pairs(options or {}) do
        if k == "TeamCheck" then GlobalConfig.TeamCheck = v end
        if k == "DefaultColor" or k == "Color" then GlobalConfig.DefaultColor = v end
        if k == "Thickness" then GlobalConfig.Thickness = v end
        if k == "Transparency" then GlobalConfig.Transparency = v end
        if k == "TracerFrom" then GlobalConfig.TracerFrom = v end
        if k == "IgnoreCharacter" then GlobalConfig.IgnoreCharacter = v end
    end
end

function VelocityESP:AddPlayerESP(player, options)
    options = options or {}
    -- apply config overrides but keep defaults
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

    options = options or {}
    self:UpdateConfig(options)
    self:AddAllPlayersESP(options)

    -- hook PlayerAdded
    table.insert(Connections, Players.PlayerAdded:Connect(function(player)
        -- create entry for player
        self:Add(player, options)
        if options and options.AutoAddNew then
            -- when character spawns, ESP will start drawing in Render
        end
    end))

    table.insert(Connections, Players.PlayerRemoving:Connect(function(player)
        self:Remove(player)
    end))

    -- main render loop
    table.insert(Connections, RunService.RenderStepped:Connect(function()
        local ok, err = pcall(function()
            self:Render()
        end)
        if not ok then
            -- silently ignore render errors to avoid breaking loop
            -- warn(err)
        end
    end))
end

function VelocityESP:Stop()
    if not IsRunning then return end
    IsRunning = false
    for _, conn in ipairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    Connections = {}
    -- clear all ESP objects
    for player, _ in pairs(ESPObjects) do
        self:Remove(player)
    end
end

function VelocityESP:Destroy()
    self:Stop()
    if GlobalConfig.StorageFolder then
        pcall(function() GlobalConfig.StorageFolder:Destroy() end)
    end
    ESPObjects = {}
end

-- expose module
getgenv().Velocity_ESP = VelocityESP
return VelocityESP
