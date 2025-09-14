-- VelocityESP (extended) - Player Drawing ESP + Object ESP (Highlight + Billboard look)
-- Extended features:
--  * Friendly Start options (Tracers boolean, preset color names, easy toggles)
--  * AddObjectESP(object, options) -> Highlight + Billboard (matches Ambush look)
--  * AddObjectsByName(name, options) -> scans workspace and auto-adds matches
--  * Auto-add on workspace descendant added (optional)
--  * Proper cleanup / restore transparencies

local VelocityESP = {}
VelocityESP.__index = VelocityESP

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Global config
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
local ObjectESP = {} -- object -> { highlight = Instance, billboard = Instance, entry = {...} }
local ObjectAddConnection -- for workspace.DescendantAdded when using AddObjectsByName auto-add
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

-- 50 preset colors (name -> Color3)
local PresetColors = {
    red = Color3.fromRGB(255, 0, 0),
    green = Color3.fromRGB(0, 255, 0),
    blue = Color3.fromRGB(0, 128, 255),
    yellow = Color3.fromRGB(255, 255, 0),
    orange = Color3.fromRGB(255, 165, 0),
    purple = Color3.fromRGB(160, 32, 240),
    violet = Color3.fromRGB(138, 43, 226),
    pink = Color3.fromRGB(255, 105, 180),
    cyan = Color3.fromRGB(0, 255, 255),
    teal = Color3.fromRGB(0, 128, 128),
    lime = Color3.fromRGB(50, 205, 50),
    magenta = Color3.fromRGB(255, 0, 255),
    maroon = Color3.fromRGB(128, 0, 0),
    navy = Color3.fromRGB(0, 0, 128),
    olive = Color3.fromRGB(128, 128, 0),
    silver = Color3.fromRGB(192, 192, 192),
    gray = Color3.fromRGB(128, 128, 128),
    black = Color3.fromRGB(0, 0, 0),
    white = Color3.fromRGB(255, 255, 255),
    brown = Color3.fromRGB(165, 42, 42),
    gold = Color3.fromRGB(255, 215, 0),
    peach = Color3.fromRGB(255, 218, 185),
    coral = Color3.fromRGB(255, 127, 80),
    indigo = Color3.fromRGB(75, 0, 130),
    crimson = Color3.fromRGB(220, 20, 60),
    salmon = Color3.fromRGB(250, 128, 114),
    emerald = Color3.fromRGB(80, 200, 120),
    azure = Color3.fromRGB(0, 127, 255),
    lavender = Color3.fromRGB(181, 126, 220),
    beige = Color3.fromRGB(245, 245, 220),
    mint = Color3.fromRGB(189, 252, 201),
    ruby = Color3.fromRGB(224, 17, 95),
    amber = Color3.fromRGB(255, 191, 0),
    sienna = Color3.fromRGB(160, 82, 45),
    khaki = Color3.fromRGB(195, 176, 145),
    plum = Color3.fromRGB(142, 69, 133),
    orchid = Color3.fromRGB(218, 112, 214),
    tan = Color3.fromRGB(210, 180, 140),
    turquoise = Color3.fromRGB(64, 224, 208),
    chocolate = Color3.fromRGB(123, 63, 0),
    steel = Color3.fromRGB(70, 130, 180),
    slate = Color3.fromRGB(112, 128, 144),
    periwinkle = Color3.fromRGB(204, 204, 255),
    cobalt = Color3.fromRGB(0, 71, 171),
    chartreuse = Color3.fromRGB(127, 255, 0),
    fuchsia = Color3.fromRGB(255, 0, 255),
    lilac = Color3.fromRGB(200, 162, 200),
    blush = Color3.fromRGB(222, 93, 131),
    seafoam = Color3.fromRGB(159, 226, 191)
}

-- resolves a color option: accepts Color3, or string preset (case-insensitive)
local function ResolveColor(value)
    if typeof(value) == "Color3" then return value end
    if type(value) == "string" then
        local key = string.lower(value)
        return PresetColors[key] or GlobalConfig.DefaultColor
    end
    return GlobalConfig.DefaultColor
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
    return Vector2.new(screenPos.X, screenPos.Y), onScreen, screenPos.Z
end

-- Create drawing objects for player (same as your original, but uses ResolveColor)
local function CreateESPObjectsForPlayer(playerOrObject, options)
    options = options or {}
    local types = options.Types or {"Box", "Tracer", "Text", "Distance", "Health"}
    -- If friendly toggles provided, convert those to Types
    if options.ShowBoxes == true or options.ShowTexts == true or options.ShowDistances == true or options.ShowHealth == true then
        local t = {}
        if options.ShowBoxes then table.insert(t, "Box") end
        if options.Tracers ~= false and options.Tracers ~= nil then table.insert(t, "Tracer") end
        if options.ShowTexts then table.insert(t, "Text") end
        if options.ShowDistances then table.insert(t, "Distance") end
        if options.ShowHealth then table.insert(t, "Health") end
        if #t > 0 then types = t end
    end

    local color = ResolveColor(options.Color or options.DefaultColor or GlobalConfig.DefaultColor)
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
        ESPObjects[player].Options = options
        return
    end

    local entry = {
        DrawObjects = CreateESPObjectsForPlayer(player, options),
        Connections = {},
        Options = options
    }
    ESPObjects[player] = entry

    table.insert(entry.Connections, player.AncestryChanged:Connect(function()
        if not player:IsDescendantOf(game) then
            VelocityESP:Remove(player)
        end
    end))

    table.insert(entry.Connections, player.CharacterAdded:Connect(function()
        task.wait(0.05)
    end))
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

-- OBJECT ESP: creates a Highlight + Billboard (Ambush look)
-- object may be a BasePart or a Model (Model must have a PrimaryPart or will choose first BasePart)
function VelocityESP:AddObjectESP(object, options)
    if not object then return end
    options = options or {}

    -- Find the target part to adorn
    local targetPart
    if object:IsA("BasePart") then
        targetPart = object
    elseif object:IsA("Model") then
        targetPart = object.PrimaryPart
        if not targetPart then
            -- fallback to first BasePart
            for _, v in ipairs(object:GetDescendants()) do
                if v:IsA("BasePart") then
                    targetPart = v
                    break
                end
            end
        end
    else
        return
    end
    if not targetPart then return end

    -- if already added, ignore
    if ObjectESP[targetPart] then return end

    local resolvedColor = ResolveColor(options.Color or options.DefaultColor or GlobalConfig.DefaultColor)
    local originalTrans = targetPart.Transparency

    -- optionally override transparency to 0 so highlight visible (default as your sample)
    if options.ForceOpaque then
        pcall(function() targetPart.Transparency = 0 end)
    end

    -- create highlight
    local hl = targetPart:FindFirstChild(options.HighlightName or "VelocityESP_Highlight")
    if not hl then
        hl = Instance.new("Highlight")
        hl.Name = options.HighlightName or "VelocityESP_Highlight"
        hl.Adornee = targetPart
        hl.Parent = targetPart -- keep it attached to the part for auto-cleanup
    end
    hl.FillColor = resolvedColor
    hl.FillTransparency = options.FillTransparency or 0.6
    hl.OutlineTransparency = options.OutlineTransparency or 0 -- matched to your sample

    -- create billboard
    local bb = targetPart:FindFirstChild(options.BillboardName or "VelocityESP_Billboard")
    if not bb then
        bb = Instance.new("BillboardGui")
        bb.Name = options.BillboardName or "VelocityESP_Billboard"
        bb.Adornee = targetPart
        bb.AlwaysOnTop = true
        bb.Size = options.BillboardSize or UDim2.new(0, 100, 0, 30)
        bb.StudsOffset = options.StudsOffset or Vector3.new(0, 3, 0)
        bb.Parent = targetPart
        local label = Instance.new("TextLabel")
        label.Name = options.LabelName or "VelocityESP_Label"
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = options.LabelColor or resolvedColor
        label.TextScaled = true
        label.Font = options.LabelFont or Enum.Font.Gotham
        label.Text = options.LabelText or (targetPart.Name)
        label.TextStrokeTransparency = options.LabelStrokeTransparency or 0
        label.TextStrokeColor3 = options.LabelStrokeColor3 or Color3.new(0, 0, 0)
        label.TextXAlignment = Enum.TextXAlignment.Center
        label.TextYAlignment = Enum.TextYAlignment.Center
        label.Parent = bb
    else
        local label = bb:FindFirstChild(options.LabelName or "VelocityESP_Label")
        if label then
            label.TextColor3 = options.LabelColor or resolvedColor
            label.Font = options.LabelFont or Enum.Font.Gotham
            label.Text = options.LabelText or (targetPart.Name)
        end
    end

    -- store entry
    local entry = {
        obj = targetPart,
        model = object,
        highlight = hl,
        billboard = bb,
        originalTrans = originalTrans,
        options = options
    }
    ObjectESP[targetPart] = entry
end

-- Remove object esp, restore transparency and destroy gui/highlight
function VelocityESP:RemoveObjectESP(object)
    if not object then return end
    local targetPart = object
    if object:IsA("Model") then
        targetPart = object.PrimaryPart
        if not targetPart then
            for _, v in ipairs(object:GetDescendants()) do
                if v:IsA("BasePart") then
                    targetPart = v
                    break
                end
            end
        end
    end
    if not targetPart then return end
    local entry = ObjectESP[targetPart]
    if not entry then return end

    -- restore transparency
    if entry.originalTrans and targetPart and targetPart:IsA("BasePart") then
        pcall(function() targetPart.Transparency = entry.originalTrans end)
    end

    -- destroy highlight & billboard
    if entry.highlight and entry.highlight.Parent then
        pcall(function() entry.highlight:Destroy() end)
    end
    if entry.billboard and entry.billboard.Parent then
        pcall(function() entry.billboard:Destroy() end)
    end

    ObjectESP[targetPart] = nil
end

-- Add all matches in workspace by name (exact match). options: autoAdd boolean to listen for DescendantAdded.
function VelocityESP:AddObjectsByName(name, options)
    options = options or {}
    local found = {}
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Model") or v:IsA("BasePart") then
            if v.Name == name then
                -- add either the Model (preferred) or BasePart
                if v:IsA("Model") then
                    VelocityESP:AddObjectESP(v, options)
                    table.insert(found, v)
                elseif v:IsA("BasePart") then
                    VelocityESP:AddObjectESP(v, options)
                    table.insert(found, v)
                end
            end
        end
    end

    -- if auto-add true, listen for future matches
    if options.AutoAdd and not ObjectAddConnection then
        ObjectAddConnection = Workspace.DescendantAdded:Connect(function(v)
            if not v then return end
            if (v:IsA("Model") or v:IsA("BasePart")) and v.Name == name then
                VelocityESP:AddObjectESP(v, options)
            end
        end)
    end

    return found
end

-- Main render loop for player drawing objects and updating object ESP label/distance and colors
function VelocityESP:Render()
    if DrawingAvailable then
        for player, entry in pairs(ESPObjects) do
            local options = entry.Options or {}
            if not IsValidTarget(player) then
                for _, d in ipairs(entry.DrawObjects) do if d.Obj then d.Obj.Visible = false end end
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

    -- Update object ESP (Highlight color and label distance)
    local plrRoot = LocalPlayer and LocalPlayer.Character and GetRoot(LocalPlayer.Character)
    for part, entry in pairs(ObjectESP) do
        local valid = part and part.Parent and part:IsA("BasePart")
        if not valid then
            -- try to re-resolve from model
            if entry.model and entry.model.Parent then
                local resolved = entry.model.PrimaryPart
                if resolved and resolved:IsA("BasePart") then
                    ObjectESP[resolved] = entry
                    ObjectESP[part] = nil
                    part = resolved
                    entry.obj = resolved
                else
                    -- remove stale
                    VelocityESP:RemoveObjectESP(entry.model)
                end
            else
                VelocityESP:RemoveObjectESP(part)
            end
        else
            -- update label text with distance
            local bb = entry.billboard
            local hl = entry.highlight
            if bb and bb.Parent then
                local label = bb:FindFirstChild(entry.options.LabelName or "VelocityESP_Label")
                if label then
                    local d = 0
                    if plrRoot then
                        d = math.floor((plrRoot.Position - part.Position).Magnitude)
                    else
                        d = 0
                    end
                    label.Text = (entry.options.LabelPrefix or "") .. (entry.options.LabelText or part.Name) .. "\n" .. tostring(d) .. " studs"
                    label.TextColor3 = entry.options.LabelColor or (ResolveColor(entry.options.Color) or hl and hl.FillColor or GlobalConfig.DefaultColor)
                end
            end
            -- update highlight color if needed (supports dynamic color override)
            if hl and hl.Parent and entry.options.Color then
                hl.FillColor = ResolveColor(entry.options.Color)
            end
        end
    end
end

function VelocityESP:UpdateConfig(options)
    for k, v in pairs(options or {}) do
        if k == "TeamCheck" then GlobalConfig.TeamCheck = v end
        if k == "DefaultColor" or k == "Color" then GlobalConfig.DefaultColor = ResolveColor(v) end
        if k == "Thickness" then GlobalConfig.Thickness = v end
        if k == "Transparency" then GlobalConfig.Transparency = v end
        if k == "TracerFrom" then GlobalConfig.TracerFrom = v end
        if k == "IgnoreCharacter" then GlobalConfig.IgnoreCharacter = v end
    end
end

function VelocityESP:AddPlayerESP(player, options)
    options = options or {}
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

-- Friendly Start: accepts simpler boolean flags and color names
-- Options (friendly):
--  Tracers = true/false
--  ShowBoxes = true/false
--  ShowTexts = true/false
--  ShowDistances = true/false
--  ShowHealth = true/false
--  Color = "red" or Color3
--  Thickness, Transparency, Size
--  AutoAddNew (players)
--  ObjectESP = { Enabled = true/false, TargetNames = {"AmbushMoving"}, AutoAdd = true, Color = "yellow", ForceOpaque = true }
function VelocityESP:Start(options)
    if IsRunning then return end
    IsRunning = true

    options = options or {}
    -- convert friendly Tracers flag -> Types handling is in CreateESPObjectsForPlayer
    self:UpdateConfig(options)
    self:AddAllPlayersESP(options)

    -- object auto add if requested
    if options.ObjectESP and options.ObjectESP.Enabled then
        local objCfg = options.ObjectESP
        if objCfg.TargetNames and type(objCfg.TargetNames) == "table" then
            for _, name in ipairs(objCfg.TargetNames) do
                self:AddObjectsByName(name, { AutoAdd = objCfg.AutoAdd, Color = objCfg.Color, ForceOpaque = objCfg.ForceOpaque, LabelPrefix = objCfg.LabelPrefix })
            end
        end
    end

    -- hook PlayerAdded / PlayerRemoving
    table.insert(Connections, Players.PlayerAdded:Connect(function(player)
        self:Add(player, options)
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
            -- ignore render errors
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
    -- clear all player ESP objects
    for player, _ in pairs(ESPObjects) do
        self:Remove(player)
    end
    -- clear object ESPs
    for part, entry in pairs(ObjectESP) do
        if entry and entry.obj then
            self:RemoveObjectESP(entry.obj)
        end
    end
    ObjectESP = {}
    -- disconnect object add listener
    if ObjectAddConnection then
        pcall(function() ObjectAddConnection:Disconnect() end)
        ObjectAddConnection = nil
    end
end

function VelocityESP:Destroy()
    self:Stop()
    if GlobalConfig.StorageFolder then
        pcall(function() GlobalConfig.StorageFolder:Destroy() end)
    end
    ESPObjects = {}
    ObjectESP = {}
end

-- expose module & convenience aliases
getgenv().Velocity_ESP = VelocityESP
VelocityESP.Presets = PresetColors
VelocityESP.ResolveColor = ResolveColor
VelocityESP.AddObjectESP = VelocityESP.AddObjectESP
VelocityESP.RemoveObjectESP = VelocityESP.RemoveObjectESP
VelocityESP.AddObjectsByName = VelocityESP.AddObjectsByName

return VelocityESP
