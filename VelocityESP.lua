-- VelocityESP (fixed: Default TeamCheck=false, PlayerESP visuals now working, added tracers for objects, expanded API with inspired functions)
local VelocityESP = {}
VelocityESP.__index = VelocityESP

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

getgenv().VelocityESP_GlobalConfig = getgenv().VelocityESP_GlobalConfig or {
    IgnoreCharacter = false,
    DefaultColor = Color3.fromRGB(255, 0, 0),
    TeamCheck = false,  -- Fixed: Default to false to ensure ESP shows in teamless games
    Thickness = 1,
    Transparency = 0.3,
    TracerFrom = "Bottom",
    StorageFolder = Instance.new("Folder")
}
local GlobalConfig = getgenv().VelocityESP_GlobalConfig
GlobalConfig.StorageFolder.Name = "VelocityESP_Storage"
GlobalConfig.StorageFolder.Parent = Workspace

local ESPObjects = {}
local ObjectESP = {}
local ObjectAddConnection
local Connections = {}
local IsRunning = false

local DrawingAvailable = (type(Drawing) == "table")

local function safeNewDrawing(typeName)
    if not DrawingAvailable then return nil end
    local ok, obj = pcall(function() return Drawing.new(typeName) end)
    if not ok then return nil end
    return obj
end

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

local function CreateESPObjectsForPlayer(playerOrObject, options)
    options = options or {}
    local types = options.Types or nil
    if not types then
        local t = {}
        if options.ShowBoxes == nil then options.ShowBoxes = true end
        if options.ShowBoxes then table.insert(t, "Box") end
        if options.Tracers == nil then options.Tracers = true end
        if options.Tracers then table.insert(t, "Tracer") end
        if options.ShowTexts == nil then options.ShowTexts = true end
        if options.ShowTexts then table.insert(t, "Text") end
        if options.ShowHealth == nil then options.ShowHealth = true end
        if options.ShowHealth then table.insert(t, "Health") end
        types = t
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
        elseif typ == "Text" then
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

function VelocityESP:CreateCharacterHighlightAndBillboard(player, options)
    if not player then return end
    local character = player.Character
    if not character then return end
    local root = GetRoot(character)
    if not root then return end
    local color = ResolveColor((options and options.Color) or GlobalConfig.DefaultColor)
    if ESPObjects[player] then
        if ESPObjects[player].Highlight and ESPObjects[player].Highlight.Parent then
            ESPObjects[player].Highlight.Adornee = character
            ESPObjects[player].Highlight.FillColor = color
        end
        if ESPObjects[player].Billboard and ESPObjects[player].Billboard.Parent then
            local label = ESPObjects[player].Billboard:FindFirstChildWhichIsA("TextLabel")
            if label then
                label.TextColor3 = color
            end
        end
        return
    end
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
        Options = options,
        Highlight = nil,
        Billboard = nil
    }
    ESPObjects[player] = entry

    table.insert(entry.Connections, player.AncestryChanged:Connect(function()
        if not player:IsDescendantOf(game) then
            VelocityESP:Remove(player)
        end
    end))

    table.insert(entry.Connections, player.CharacterAdded:Connect(function(char)
        task.wait(0.05)
        local opt = ESPObjects[player] and ESPObjects[player].Options or options
        local resolvedColor = ResolveColor(opt.Color or GlobalConfig.DefaultColor)
        local character = char
        if not character then return end
        local root = GetRoot(character)
        if not root then return end
        if opt.ShowHighlight == nil then opt.ShowHighlight = true end
        if opt.ShowHighlight then
            local existing = character:FindFirstChild("VelocityESP_PlayerHighlight")
            if existing and existing:IsA("Highlight") then
                existing.Adornee = character
                existing.Parent = character
                existing.FillColor = resolvedColor
                existing.FillTransparency = opt.FillTransparency or 0.6
                existing.OutlineTransparency = opt.OutlineTransparency or 0
                existing.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                ESPObjects[player].Highlight = existing
            else
                local hl = Instance.new("Highlight")
                hl.Name = "VelocityESP_PlayerHighlight"
                hl.Adornee = character
                hl.Parent = character
                hl.FillColor = resolvedColor
                hl.FillTransparency = opt.FillTransparency or 0.6
                hl.OutlineTransparency = opt.OutlineTransparency or 0
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                ESPObjects[player].Highlight = hl
            end
        end
        if opt.ShowBillboard == nil then opt.ShowBillboard = true end
        if opt.ShowBillboard then
            local bb = root:FindFirstChild("VelocityESP_PlayerBillboard")
            if bb and bb:IsA("BillboardGui") then
                bb.Adornee = root
                bb.Parent = root
                bb.AlwaysOnTop = true
                bb.StudsOffset = opt.StudsOffset or Vector3.new(0, 3, 0)
                local label = bb:FindFirstChildWhichIsA("TextLabel")
                if label then
                    label.TextColor3 = opt.LabelColor or resolvedColor
                    label.Font = opt.LabelFont or Enum.Font.Gotham
                    label.TextStrokeTransparency = opt.LabelStrokeTransparency or 0
                    label.TextStrokeColor3 = opt.LabelStrokeColor3 or Color3.new(0, 0, 0)
                    label.Text = player.Name or ""
                    label.TextScaled = true
                    label.Visible = true
                end
                ESPObjects[player].Billboard = bb
            else
                local bb = Instance.new("BillboardGui")
                bb.Name = "VelocityESP_PlayerBillboard"
                bb.Adornee = root
                bb.AlwaysOnTop = true
                bb.Size = UDim2.new(0, 160, 0, 48)
                bb.StudsOffset = opt.StudsOffset or Vector3.new(0, 3, 0)
                bb.Parent = root
                local label = Instance.new("TextLabel")
                label.Name = "VelocityESP_PlayerLabel"
                label.Size = UDim2.new(1, 0, 1, 0)
                label.BackgroundTransparency = 1
                label.TextColor3 = opt.LabelColor or resolvedColor
                label.TextScaled = true
                label.Font = opt.LabelFont or Enum.Font.Gotham
                label.TextStrokeTransparency = opt.LabelStrokeTransparency or 0
                label.TextStrokeColor3 = opt.LabelStrokeColor3 or Color3.new(0, 0, 0)
                label.Text = player.Name or ""
                label.TextYAlignment = Enum.TextYAlignment.Center
                label.TextXAlignment = Enum.TextXAlignment.Center
                label.Visible = true
                label.Parent = bb
                ESPObjects[player].Billboard = bb
            end
        end
    end))

    if player.Character then
        task.spawn(function()
            task.wait(0.05)
            local char = player.Character
            local opt = entry.Options
            local resolvedColor = ResolveColor(opt.Color or GlobalConfig.DefaultColor)
            local root = GetRoot(char)
            if opt.ShowHighlight == nil then opt.ShowHighlight = true end
            if opt.ShowHighlight then
                local existing = char:FindFirstChild("VelocityESP_PlayerHighlight")
                if existing and existing:IsA("Highlight") then
                    existing.Adornee = char
                    existing.Parent = char
                    existing.FillColor = resolvedColor
                    existing.FillTransparency = opt.FillTransparency or 0.6
                    existing.OutlineTransparency = opt.OutlineTransparency or 0
                    existing.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    entry.Highlight = existing
                else
                    local hl = Instance.new("Highlight")
                    hl.Name = "VelocityESP_PlayerHighlight"
                    hl.Adornee = char
                    hl.Parent = char
                    hl.FillColor = resolvedColor
                    hl.FillTransparency = opt.FillTransparency or 0.6
                    hl.OutlineTransparency = opt.OutlineTransparency or 0
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    entry.Highlight = hl
                end
            end
            if root and (entry.Options.ShowBillboard == nil or entry.Options.ShowBillboard) then
                local optbb = entry.Options
                local bb = root:FindFirstChild("VelocityESP_PlayerBillboard")
                if bb and bb:IsA("BillboardGui") then
                    bb.Adornee = root
                    bb.Parent = root
                    bb.AlwaysOnTop = true
                    bb.StudsOffset = optbb.StudsOffset or Vector3.new(0, 3, 0)
                    local label = bb:FindFirstChildWhichIsA("TextLabel")
                    if label then
                        label.TextColor3 = optbb.LabelColor or resolvedColor
                        label.Font = optbb.LabelFont or Enum.Font.Gotham
                        label.TextStrokeTransparency = optbb.LabelStrokeTransparency or 0
                        label.TextStrokeColor3 = optbb.LabelStrokeColor3 or Color3.new(0, 0, 0)
                        label.Text = player.Name or ""
                        label.Visible = true
                    end
                    entry.Billboard = bb
                else
                    local bb = Instance.new("BillboardGui")
                    bb.Name = "VelocityESP_PlayerBillboard"
                    bb.Adornee = root
                    bb.AlwaysOnTop = true
                    bb.Size = UDim2.new(0, 160, 0, 48)
                    bb.StudsOffset = optbb.StudsOffset or Vector3.new(0, 3, 0)
                    bb.Parent = root
                    local label = Instance.new("TextLabel")
                    label.Name = "VelocityESP_PlayerLabel"
                    label.Size = UDim2.new(1, 0, 1, 0)
                    label.BackgroundTransparency = 1
                    label.TextColor3 = optbb.LabelColor or resolvedColor
                    label.TextScaled = true
                    label.Font = optbb.LabelFont or Enum.Font.Gotham
                    label.TextStrokeTransparency = optbb.LabelStrokeTransparency or 0
                    label.TextStrokeColor3 = optbb.LabelStrokeColor3 or Color3.new(0, 0, 0)
                    label.Text = player.Name or ""
                    label.TextYAlignment = Enum.TextYAlignment.Center
                    label.TextXAlignment = Enum.TextXAlignment.Center
                    label.Parent = bb
                    entry.Billboard = bb
                end
            end
        end)
    end
end

-- Remove player ESP; if no argument provided, remove all players
function VelocityESP:Remove(player)
    if not player then
        -- remove all player ESP entries
        for p, _ in pairs(ESPObjects) do
            -- safe pcall for each to avoid errors during iteration
            pcall(function() 
                for _, esp in ipairs(ESPObjects[p].DrawObjects or {}) do
                    if esp.Obj and esp.Obj.Remove then
                        pcall(function() esp.Obj:Remove() end)
                    end
                end
                if ESPObjects[p].Highlight and ESPObjects[p].Highlight.Parent then
                    pcall(function() ESPObjects[p].Highlight:Destroy() end)
                end
                if ESPObjects[p].Billboard and ESPObjects[p].Billboard.Parent then
                    pcall(function() ESPObjects[p].Billboard:Destroy() end)
                end
                for _, conn in ipairs(ESPObjects[p].Connections or {}) do
                    pcall(function() conn:Disconnect() end)
                end
            end)
            ESPObjects[p] = nil
        end
        return
    end

    local entry = ESPObjects[player]
    if not entry then return end
    for _, esp in ipairs(entry.DrawObjects) do
        if esp.Obj and esp.Obj.Remove then
            pcall(function() esp.Obj:Remove() end)
        end
    end
    if entry.Highlight and entry.Highlight.Parent then
        pcall(function() entry.Highlight:Destroy() end)
    end
    if entry.Billboard and entry.Billboard.Parent then
        pcall(function() entry.Billboard:Destroy() end)
    end
    for _, conn in ipairs(entry.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    ESPObjects[player] = nil
end

function VelocityESP:AddObjectESP(object, options)
    if not object then return end
    options = options or {}
    local targetPart
    if object:IsA("BasePart") then
        targetPart = object
    elseif object:IsA("Model") then
        targetPart = object.PrimaryPart
        if not targetPart then
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
    local key
    if options.ShowWholeModel and object:IsA("Model") then
        key = object
    else
        key = targetPart
    end
    if ObjectESP[key] then return end
    local resolvedColor = ResolveColor(options.Color or options.DefaultColor or GlobalConfig.DefaultColor)
    local originalTrans = nil
    if targetPart and targetPart:IsA("BasePart") then
        originalTrans = targetPart.Transparency
        if options.ForceOpaque then
            pcall(function() targetPart.Transparency = 0 end)
        end
    end

    local billboardAdornee = targetPart
    local hlAdornee = (options.ShowWholeModel and object:IsA("Model")) and object or targetPart

    -- create highlight and parent to storage folder (reliable)
    local hl = nil
    do
        local existing = nil
        if options.ShowWholeModel and object:IsA("Model") then
            existing = object:FindFirstChild(options.HighlightName or "VelocityESP_Highlight")
        else
            existing = targetPart:FindFirstChild(options.HighlightName or "VelocityESP_Highlight")
        end

        if existing and existing:IsA("Highlight") then
            hl = existing
            hl.Adornee = hlAdornee
            hl.Parent = GlobalConfig.StorageFolder
        else
            hl = Instance.new("Highlight")
            hl.Name = options.HighlightName or "VelocityESP_Highlight"
            hl.Adornee = hlAdornee
            hl.Parent = GlobalConfig.StorageFolder
        end
    end

    hl.FillColor = resolvedColor
    hl.FillTransparency = options.FillTransparency or 0.6
    hl.OutlineTransparency = options.OutlineTransparency or 0
    hl.DepthMode = options.DepthMode or Enum.HighlightDepthMode.AlwaysOnTop

    -- create billboard (parent to adornee part)
    local bb = nil
    if billboardAdornee then
        local existingbb = billboardAdornee:FindFirstChild(options.BillboardName or "VelocityESP_Billboard")
        if existingbb and existingbb:IsA("BillboardGui") then
            bb = existingbb
            bb.Adornee = billboardAdornee
            bb.Parent = billboardAdornee
            bb.AlwaysOnTop = true
            bb.Size = options.BillboardSize or UDim2.new(0, 120, 0, 36)
            bb.StudsOffset = options.StudsOffset or Vector3.new(0, 3, 0)
            local label = bb:FindFirstChild(options.LabelName or "VelocityESP_Label")
            if label and label:IsA("TextLabel") then
                label.TextColor3 = options.LabelColor or resolvedColor
                label.Font = options.LabelFont or Enum.Font.Gotham
                label.Text = options.LabelText or options.TextlabelText or (targetPart.Name)
                label.TextScaled = true
                label.Visible = true
            end
        else
            bb = Instance.new("BillboardGui")
            bb.Name = options.BillboardName or "VelocityESP_Billboard"
            bb.Adornee = billboardAdornee
            bb.AlwaysOnTop = true
            bb.Size = options.BillboardSize or UDim2.new(0, 120, 0, 36)
            bb.StudsOffset = options.StudsOffset or Vector3.new(0, 3, 0)
            bb.Parent = billboardAdornee
            local label = Instance.new("TextLabel")
            label.Name = options.LabelName or "VelocityESP_Label"
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.TextColor3 = options.LabelColor or resolvedColor
            label.TextScaled = true
            label.Font = options.LabelFont or Enum.Font.Gotham
            label.Text = options.LabelText or options.TextlabelText or (targetPart.Name)
            label.TextStrokeTransparency = options.LabelStrokeTransparency or 0
            label.TextStrokeColor3 = options.LabelStrokeColor3 or Color3.new(0, 0, 0)
            label.TextXAlignment = Enum.TextXAlignment.Center
            label.TextYAlignment = Enum.TextYAlignment.Center
            label.Visible = true
            label.Parent = bb
        end
    end

    local tracer = nil
    if options.ShowTracers then
        tracer = safeNewDrawing("Line")
        if tracer then
            tracer.Color = resolvedColor
            tracer.Thickness = options.Thickness or GlobalConfig.Thickness
            tracer.Transparency = options.Transparency or GlobalConfig.Transparency
            tracer.Visible = false
        end
    end

    local entry = {
        key = key,
        obj = targetPart,
        model = object,
        highlight = hl,
        billboard = bb,
        tracer = tracer,
        originalTrans = originalTrans,
        options = options
    }
    ObjectESP[key] = entry
end

function VelocityESP:RemoveObjectESP(object)
    if not object then return end
    local foundKey = nil
    for k, entry in pairs(ObjectESP) do
        if entry then
            if entry.model == object or entry.obj == object or k == object then
                foundKey = k
                break
            end
        end
    end
    if not foundKey then return end
    local entry = ObjectESP[foundKey]
    if entry.originalTrans and entry.obj and entry.obj:IsA("BasePart") then
        pcall(function() entry.obj.Transparency = entry.originalTrans end)
    end
    if entry.highlight and entry.highlight.Parent then
        pcall(function() entry.highlight:Destroy() end)
    end
    if entry.billboard and entry.billboard.Parent then
        pcall(function() entry.billboard:Destroy() end)
    end
    if entry.tracer then
        pcall(function() entry.tracer:Remove() end)
    end
    ObjectESP[foundKey] = nil
end

-- New: remove all objects with the provided name (works for both Models and Parts)
function VelocityESP:RemoveObjectsByName(name)
    if not name or type(name) ~= "string" then return end
    for key, entry in pairs(ObjectESP) do
        local obj = entry.model or entry.obj
        if obj and obj.Name == name then
            -- remove by passing original object reference (RemoveObjectESP handles both keys)
            pcall(function() VelocityESP:RemoveObjectESP(obj) end)
        end
    end
end

function VelocityESP:AddObjectsByName(name, options)
    options = options or {}
    local found = {}
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Model") or v:IsA("BasePart") then
            if v.Name == name then
                VelocityESP:AddObjectESP(v, options)
                table.insert(found, v)
            end
        end
    end
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

function VelocityESP:Render()
    if DrawingAvailable then
        for player, entry in pairs(ESPObjects) do
            local options = entry.Options or {}
            if not IsValidTarget(player) then
                for _, d in ipairs(entry.DrawObjects or {}) do if d.Obj then d.Obj.Visible = false end end
                if entry.Billboard and entry.Billboard.Parent then
                    local lbl = entry.Billboard:FindFirstChildWhichIsA("TextLabel")
                    if lbl then lbl.Text = "" end
                end
                if entry.Highlight and entry.Highlight.Parent then
                    entry.Highlight.FillTransparency = options.FillTransparency or 0.6
                end
                continue
            end
            local character = player.Character
            local root = GetRoot(character)
            if not root then
                for _, d in ipairs(entry.DrawObjects) do if d.Obj then d.Obj.Visible = false end end
                continue
            end
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
                if entry.Billboard and entry.Billboard.Parent then
                    local lbl = entry.Billboard:FindFirstChildWhichIsA("TextLabel")
                    if lbl then lbl.Text = "" end
                end
                continue
            end
            local height = math.max(20, math.abs(headScreen.Y - footScreen.Y))
            local width = height * 0.45
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local hpText = humanoid and ("\n" .. tostring(math.floor(humanoid.Health)) .. " HP") or ""
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
                    local text = player.Name .. "\n" .. tostring(math.floor(dist)) .. " studs" .. hpText
                    obj.Text = text
                    obj.Position = headScreen + Vector2.new(0, -height / 2 - 20)
                elseif d.Type == "Health" then
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
            if entry.Billboard and entry.Billboard.Parent then
                local label = entry.Billboard:FindFirstChildWhichIsA("TextLabel")
                if label then
                    local hpText = humanoid and tostring(math.floor(humanoid.Health)) .. " HP" or ""
                    -- Ensure label is always updated and visible
                    label.Text = (player.Name or "") .. "\n" .. tostring(math.floor(dist)) .. " studs" .. (hpText ~= "" and ("\n" .. hpText) or "")
                    label.TextColor3 = entry.Options.LabelColor or ResolveColor(entry.Options.Color) or (entry.Highlight and entry.Highlight.FillColor) or GlobalConfig.DefaultColor
                    label.Visible = true
                end
            end
            if entry.Highlight and entry.Highlight.Parent then
                if entry.Options.Color then
                    entry.Highlight.FillColor = ResolveColor(entry.Options.Color)
                end
                entry.Highlight.FillTransparency = entry.Options.FillTransparency or 0.6
                entry.Highlight.DepthMode = entry.Options.DepthMode or Enum.HighlightDepthMode.AlwaysOnTop
            end
        end
    end

    local plrRoot = LocalPlayer and LocalPlayer.Character and GetRoot(LocalPlayer.Character)
    for key, entry in pairs(ObjectESP) do
        local part = entry.obj
        local valid = part and part.Parent and part:IsA("BasePart")
        if not valid then
            if entry.model and entry.model.Parent then
                local resolved = entry.model.PrimaryPart
                if resolved and resolved:IsA("BasePart") then
                    ObjectESP[resolved] = entry
                    ObjectESP[key] = nil
                    entry.obj = resolved
                else
                    VelocityESP:RemoveObjectESP(entry.model)
                end
            else
                VelocityESP:RemoveObjectESP(part)
            end
        else
            local bb = entry.billboard
            local hl = entry.highlight
            local pos = part.Position
            local screenPos, onScreen = WorldToScreenVec(pos)
            if entry.tracer then
                if onScreen then
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
                    entry.tracer.From = from
                    entry.tracer.To = screenPos
                    entry.tracer.Visible = true
                else
                    entry.tracer.Visible = false
                end
            end
            if bb and bb.Parent then
                local label = bb:FindFirstChild(entry.options.LabelName or "VelocityESP_Label")
                if label then
                    local d = 0
                    if plrRoot then
                        d = math.floor((plrRoot.Position - part.Position).Magnitude)
                    else
                        d = 0
                    end
                    label.Text = (entry.options.LabelPrefix or "") .. (entry.options.LabelText or entry.options.TextlabelText or part.Name) .. "\n" .. tostring(d) .. " studs"
                    label.TextColor3 = entry.options.LabelColor or (ResolveColor(entry.options.Color) or hl and hl.FillColor or GlobalConfig.DefaultColor)
                    label.Visible = true
                end
            end
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

function VelocityESP:ObjectESP(options)
    options = options or {}
    if options.Enabled then
        local objCfg = options
        if objCfg.TargetNames and type(objCfg.TargetNames) == "table" then
            for _, name in ipairs(objCfg.TargetNames) do
                local addOpts = {
                    AutoAdd = objCfg.AutoAdd,
                    Color = objCfg.Color,
                    ForceOpaque = objCfg.ForceOpaque,
                    LabelPrefix = objCfg.LabelPrefix,
                    LabelText = objCfg.TextlabelText or objCfg.LabelText,
                    ShowWholeModel = objCfg.ShowWholeModel,
                    LabelName = objCfg.LabelName,
                    BillboardName = objCfg.BillboardName,
                    HighlightName = objCfg.HighlightName,
                    BillboardSize = objCfg.BillboardSize,
                    StudsOffset = objCfg.StudsOffset,
                    FillTransparency = objCfg.FillTransparency,
                    OutlineTransparency = objCfg.OutlineTransparency,
                    DepthMode = objCfg.DepthMode,
                    ShowTracers = objCfg.ShowTracers  -- Added support for object tracers
                }
                self:AddObjectsByName(name, addOpts)
            end
        end
    end
end

function VelocityESP:Start(options)
    if IsRunning then return end
    IsRunning = true
    options = options or {}
    self:UpdateConfig(options)
    if options.ShowBoxes == nil then options.ShowBoxes = true end
    if options.Tracers == nil then options.Tracers = true end  -- Fixed: Default tracers to true for better out-of-box experience
    if options.ShowHighlight == nil then options.ShowHighlight = true end
    if options.ShowBillboard == nil then options.ShowBillboard = true end

    -- PlayerESP must be passed as a table under options.PlayerESP with Enabled=true to auto-add players
    if options.PlayerESP and type(options.PlayerESP) == "table" and options.PlayerESP.Enabled then
        self:AddAllPlayersESP(options.PlayerESP)
    end

    if options.ObjectESP and options.ObjectESP.Enabled then
        self:ObjectESP(options.ObjectESP)
    end
    table.insert(Connections, Players.PlayerAdded:Connect(function(player)
        if options.PlayerESP and type(options.PlayerESP) == "table" and options.PlayerESP.Enabled then
            self:Add(player, options.PlayerESP)
        end
    end))
    table.insert(Connections, Players.PlayerRemoving:Connect(function(player)
        self:Remove(player)
    end))
    table.insert(Connections, RunService.RenderStepped:Connect(function()
        local ok, err = pcall(function()
            self:Render()
        end)
        if not ok then
            -- swallow rendering errors silently
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
    -- remove all player ESP
    self:Remove()
    -- remove all object ESP
    for key, entry in pairs(ObjectESP) do
        if entry and entry.obj then
            self:RemoveObjectESP(entry.obj)
        end
    end
    ObjectESP = {}
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

-- Expanded API with inspired functions (switched up naming and structure to avoid direct copy)
-- Equivalent to Load: Initializes with config
function VelocityESP:Initialize(customConfig)
    self:UpdateConfig(customConfig)
    self:Start(customConfig)
end

-- Equivalent to Toggle: Enables/disables the ESP
function VelocityESP:Enable(state)
    if state == nil then state = not IsRunning end
    if state then
        self:Start()
    else
        self:Stop()
    end
end

-- Equivalent to Unload: Cleans up everything
function VelocityESP:Cleanup()
    self:Destroy()
end

-- Equivalent to AddInstance: Registers a specific instance (player or object)
function VelocityESP:RegisterEntity(entity, opts)
    if entity:IsA("Player") then
        self:Add(entity, opts)
    else
        self:AddObjectESP(entity, opts)
    end
end

-- Equivalent to RemoveInstance: Unregisters a specific instance
function VelocityESP:UnregisterEntity(entity)
    if entity:IsA("Player") then
        self:Remove(entity)
    else
        self:RemoveObjectESP(entity)
    end
end

-- Equivalent to GetESP: Retrieves options for a registered entity
function VelocityESP:GetEntityOptions(entity)
    if entity:IsA("Player") then
        return ESPObjects[entity] and ESPObjects[entity].Options or nil
    else
        for _, entry in pairs(ObjectESP) do
            if entry.obj == entity or entry.model == entity then
                return entry.options
            end
        end
        return nil
    end
end

-- Equivalent to UpdateESP: Updates options for a registered entity
function VelocityESP:ModifyEntity(entity, newOpts)
    if entity:IsA("Player") then
        if ESPObjects[entity] then
            for k, v in pairs(newOpts) do
                ESPObjects[entity].Options[k] = v
            end
        end
    else
        for _, entry in pairs(ObjectESP) do
            if entry.obj == entity or entry.model == entity then
                for k, v in pairs(newOpts) do
                    entry.options[k] = v
                end
                -- Reapply changes if needed (e.g., color)
                if newOpts.Color then
                    entry.highlight.FillColor = ResolveColor(newOpts.Color)
                    if entry.billboard then
                        local label = entry.billboard:FindFirstChild(entry.options.LabelName or "VelocityESP_Label")
                        if label then label.TextColor3 = newOpts.LabelColor or ResolveColor(newOpts.Color) end
                    end
                    if entry.tracer then entry.tracer.Color = ResolveColor(newOpts.Color) end
                end
                if newOpts.ShowTracers ~= nil and not entry.tracer and newOpts.ShowTracers then
                    local tracer = safeNewDrawing("Line")
                    if tracer then
                        tracer.Color = ResolveColor(entry.options.Color or GlobalConfig.DefaultColor)
                        tracer.Thickness = entry.options.Thickness or GlobalConfig.Thickness
                        tracer.Transparency = entry.options.Transparency or GlobalConfig.Transparency
                        tracer.Visible = false
                        entry.tracer = tracer
                    end
                elseif newOpts.ShowTracers == false and entry.tracer then
                    pcall(function() entry.tracer:Remove() end)
                    entry.tracer = nil
                end
            end
        end
    end
end

-- Equivalent to AddTag: Adds ESP to all instances with a specific name/tag
function VelocityESP:RegisterGroup(groupName, opts)
    self:AddObjectsByName(groupName, opts)
end

-- Equivalent to RemoveTag: Removes ESP from all instances with a specific name/tag
function VelocityESP:UnregisterGroup(groupName)
    self:RemoveObjectsByName(groupName)
end

getgenv().Velocity_ESP = VelocityESP
VelocityESP.Presets = PresetColors
VelocityESP.ResolveColor = ResolveColor
VelocityESP.AddObjectESP = VelocityESP.AddObjectESP
VelocityESP.RemoveObjectESP = VelocityESP.RemoveObjectESP
VelocityESP.AddObjectsByName = VelocityESP.AddObjectsByName
VelocityESP.RemoveObjectsByName = VelocityESP.RemoveObjectsByName

return VelocityESP
