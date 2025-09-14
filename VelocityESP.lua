-- VelocityESP (fixed rendering + object tracers)
local VelocityESP = {}
VelocityESP.__index = VelocityESP

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

getgenv().VelocityESP_GlobalConfig = getgenv().VelocityESP_GlobalConfig or {
    IgnoreCharacter = false,
    DefaultColor = Color3.fromRGB(255, 0, 0),
    TeamCheck = true,
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

local function safeNewDrawing(typeName)
    local ok, obj = pcall(function()
        return (Drawing and Drawing.new) and Drawing.new(typeName) or nil
    end)
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
    return player and player.Team
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

local function MergePlayerDefaults(options)
    options = options or {}
    local out = {}
    out.ShowBoxes = (options.ShowBoxes ~= nil) and options.ShowBoxes or true
    out.Tracers = (options.Tracers ~= nil) and options.Tracers or ((options.Tracer ~= nil) and true or true)
    out.Tracer = options.Tracer or (options.Tracers and {}) or nil
    out.ShowTexts = (options.ShowTexts ~= nil) and options.ShowTexts or true
    out.ShowHealth = (options.ShowHealth ~= nil) and options.ShowHealth or false
    out.Size = options.Size or 14
    out.LabelColor = options.LabelColor or options.Color or GlobalConfig.DefaultColor
    out.LabelFont = options.LabelFont or Enum.Font.Gotham
    out.LabelStrokeTransparency = options.LabelStrokeTransparency or 0
    out.LabelStrokeColor3 = options.LabelStrokeColor3 or Color3.new(0,0,0)
    out.Color = options.Color or GlobalConfig.DefaultColor
    out.StudsOffset = options.StudsOffset or Vector3.new(0,3,0)
    out.Thickness = options.Thickness or GlobalConfig.Thickness
    out.Transparency = (options.Transparency ~= nil) and options.Transparency or GlobalConfig.Transparency
    out.ShowHighlight = (options.ShowHighlight ~= nil) and options.ShowHighlight or true
    out.FillTransparency = options.FillTransparency or 0.6
    out.OutlineTransparency = options.OutlineTransparency or 0
    out.ShowBillboard = (options.ShowBillboard ~= nil) and options.ShowBillboard or true
    out.DepthMode = options.DepthMode or Enum.HighlightDepthMode.AlwaysOnTop
    out = setmetatable(out, {__index = options})
    return out
end

local function CreateESPObjectsForPlayer(playerOrObject, optionsRaw)
    local options = MergePlayerDefaults(optionsRaw)
    local types = {}
    if options.ShowBoxes then table.insert(types, "Box") end
    if options.Tracers then table.insert(types, "Tracer") end
    if options.ShowTexts then table.insert(types, "Text") end
    if options.ShowHealth then table.insert(types, "Health") end

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
            if obj then obj.Thickness = math.max(2, (options.Thickness or GlobalConfig.Thickness)) end
        end
        if obj then
            obj.Color = color
            obj.Thickness = thickness
            obj.Transparency = transparency
            obj.Visible = false
            table.insert(drawList, {Obj = obj, Type = typ})
        end
    end
    return drawList, options
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

function VelocityESP:Add(player, optionsRaw)
    if not player or not player:IsA("Player") then return end
    optionsRaw = optionsRaw or {}
    if ESPObjects[player] then
        ESPObjects[player].Options = MergePlayerDefaults(optionsRaw)
        return
    end

    local drawList, merged = CreateESPObjectsForPlayer(player, optionsRaw)
    local entry = {
        DrawObjects = drawList,
        Connections = {},
        Options = merged,
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
        local opt = ESPObjects[player] and ESPObjects[player].Options or merged
        local resolvedColor = ResolveColor(opt.Color or GlobalConfig.DefaultColor)
        local character = char
        if not character then return end
        local root = GetRoot(character)
        if not root then return end
        if opt.ShowHighlight then
            local existing = character:FindFirstChild("VelocityESP_PlayerHighlight")
            if existing and existing:IsA("Highlight") then
                existing.Adornee = character
                existing.Parent = GlobalConfig.StorageFolder
                existing.FillColor = resolvedColor
                existing.FillTransparency = opt.FillTransparency or 0.6
                existing.OutlineTransparency = opt.OutlineTransparency or 0
                existing.DepthMode = opt.DepthMode or Enum.HighlightDepthMode.AlwaysOnTop
                ESPObjects[player].Highlight = existing
            else
                local hl = Instance.new("Highlight")
                hl.Name = "VelocityESP_PlayerHighlight"
                hl.Adornee = character
                hl.Parent = GlobalConfig.StorageFolder
                hl.FillColor = resolvedColor
                hl.FillTransparency = opt.FillTransparency or 0.6
                hl.OutlineTransparency = opt.OutlineTransparency or 0
                hl.DepthMode = opt.DepthMode or Enum.HighlightDepthMode.AlwaysOnTop
                ESPObjects[player].Highlight = hl
            end
        end
        if opt.ShowBillboard and root then
            local bb = root:FindFirstChild("VelocityESP_PlayerBillboard")
            if bb and bb:IsA("BillboardGui") then
                bb.Adornee = root
                bb.Parent = root
                bb.AlwaysOnTop = true
                bb.StudsOffset = opt.StudsOffset or Vector3.new(0, 3, 0)
                local label = bb:FindFirstChildWhichIsA("TextLabel")
                if label then
                    label.TextColor3 = ResolveColor(opt.LabelColor or opt.Color or resolvedColor)
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
                label.TextColor3 = ResolveColor(opt.LabelColor or opt.Color or resolvedColor)
                label.TextScaled = true
                label.Font = opt.LabelFont or Enum.Font.Gotham
                label.TextStrokeTransparency = opt.LabelStrokeTransparency or 0
                label.TextStrokeColor3 = opt.LabelStrokeColor3 or Color3.new(0, 0, 0)
                label.Text = player.Name or ""
                label.TextYAlignment = Enum.TextYAlignment.Center
                label.TextXAlignment = Enum.TextXAlignment.Center
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
            if opt.ShowHighlight then
                local existing = char:FindFirstChild("VelocityESP_PlayerHighlight")
                if existing and existing:IsA("Highlight") then
                    existing.Adornee = char
                    existing.Parent = GlobalConfig.StorageFolder
                    existing.FillColor = resolvedColor
                    existing.FillTransparency = opt.FillTransparency or 0.6
                    existing.OutlineTransparency = opt.OutlineTransparency or 0
                    existing.DepthMode = opt.DepthMode or Enum.HighlightDepthMode.AlwaysOnTop
                    entry.Highlight = existing
                else
                    local hl = Instance.new("Highlight")
                    hl.Name = "VelocityESP_PlayerHighlight"
                    hl.Adornee = char
                    hl.Parent = GlobalConfig.StorageFolder
                    hl.FillColor = resolvedColor
                    hl.FillTransparency = opt.FillTransparency or 0.6
                    hl.OutlineTransparency = opt.OutlineTransparency or 0
                    hl.DepthMode = opt.DepthMode or Enum.HighlightDepthMode.AlwaysOnTop
                    entry.Highlight = hl
                end
            end
            if root and opt.ShowBillboard then
                local bb = root:FindFirstChild("VelocityESP_PlayerBillboard")
                if bb and bb:IsA("BillboardGui") then
                    bb.Adornee = root
                    bb.Parent = root
                    bb.AlwaysOnTop = true
                    bb.StudsOffset = opt.StudsOffset or Vector3.new(0, 3, 0)
                    local label = bb:FindFirstChildWhichIsA("TextLabel")
                    if label then
                        label.TextColor3 = ResolveColor(opt.LabelColor or opt.Color or resolvedColor)
                        label.Font = opt.LabelFont or Enum.Font.Gotham
                        label.TextStrokeTransparency = opt.LabelStrokeTransparency or 0
                        label.TextStrokeColor3 = opt.LabelStrokeColor3 or Color3.new(0, 0, 0)
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
                    bb.StudsOffset = opt.StudsOffset or Vector3.new(0, 3, 0)
                    bb.Parent = root
                    local label = Instance.new("TextLabel")
                    label.Name = "VelocityESP_PlayerLabel"
                    label.Size = UDim2.new(1, 0, 1, 0)
                    label.BackgroundTransparency = 1
                    label.TextColor3 = ResolveColor(opt.LabelColor or opt.Color or resolvedColor)
                    label.TextScaled = true
                    label.Font = opt.LabelFont or Enum.Font.Gotham
                    label.TextStrokeTransparency = opt.LabelStrokeTransparency or 0
                    label.TextStrokeColor3 = opt.LabelStrokeColor3 or Color3.new(0, 0, 0)
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

function VelocityESP:Remove(player)
    if not player then
        for p, _ in pairs(ESPObjects) do
            pcall(function()
                local e = ESPObjects[p]
                if e then
                    for _, esp in ipairs(e.DrawObjects or {}) do
                        if esp.Obj and esp.Obj.Remove then
                            pcall(function() esp.Obj:Remove() end)
                        end
                    end
                    if e.Highlight and e.Highlight.Parent then
                        pcall(function() e.Highlight:Destroy() end)
                    end
                    if e.Billboard and e.Billboard.Parent then
                        pcall(function() e.Billboard:Destroy() end)
                    end
                    for _, conn in ipairs(e.Connections or {}) do
                        pcall(function() conn:Disconnect() end)
                    end
                end
            end)
            ESPObjects[p] = nil
        end
        return
    end

    local entry = ESPObjects[player]
    if not entry then return end
    for _, esp in ipairs(entry.DrawObjects or {}) do
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
    for _, conn in ipairs(entry.Connections or {}) do
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
                label.TextColor3 = ResolveColor(options.LabelColor or resolvedColor)
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
            label.TextColor3 = ResolveColor(options.LabelColor or resolvedColor)
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

    local drawObjects = {}
    if safeNewDrawing and options.Tracer and options.Tracer.Enabled then
        local ln = safeNewDrawing("Line")
        if ln then
            ln.Thickness = options.Tracer.Thickness or (options.Thickness or GlobalConfig.Thickness) or 1
            ln.Transparency = options.Tracer.Transparency or 0
            ln.Color = ResolveColor(options.Tracer.Color or options.Color or resolvedColor)
            ln.Visible = false
            table.insert(drawObjects, {Obj = ln, Type = "Tracer"})
        end
    end
    if safeNewDrawing and options.TextLabel and options.TextLabel.Enabled then
        local txt = safeNewDrawing("Text")
        if txt then
            txt.Size = options.TextLabel.Size or 14
            txt.Center = true
            txt.Outline = true
            txt.Font = 2
            txt.Text = options.TextLabel.Text or (targetPart.Name)
            txt.Visible = false
            txt.Transparency = options.TextLabel.Transparency or 0.0
            txt.Color = ResolveColor(options.TextLabel.Color or options.Color or resolvedColor)
            table.insert(drawObjects, {Obj = txt, Type = "ObjectText"})
        end
    end

    local entry = {
        key = key,
        obj = targetPart,
        model = object,
        highlight = hl,
        billboard = bb,
        originalTrans = originalTrans,
        options = options,
        DrawObjects = drawObjects
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
    if entry.DrawObjects then
        for _, d in ipairs(entry.DrawObjects) do
            if d.Obj and d.Obj.Remove then
                pcall(function() d.Obj:Remove() end)
            end
        end
    end
    ObjectESP[foundKey] = nil
end

function VelocityESP:RemoveObjectsByName(name)
    if not name or type(name) ~= "string" then return end
    for key, entry in pairs(ObjectESP) do
        local obj = entry.model or entry.obj
        if obj and obj.Name == name then
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
    for player, entry in pairs(ESPObjects) do
        local options = entry and entry.Options or {}
        if not IsValidTarget(player) then
            for _, d in ipairs(entry.DrawObjects or {}) do
                if d.Obj then pcall(function() d.Obj.Visible = false end) end
            end
            if entry.Billboard and entry.Billboard.Parent then
                local lbl = entry.Billboard:FindFirstChildWhichIsA("TextLabel")
                if lbl then pcall(function() lbl.Text = "" end) end
            end
            if entry.Highlight and entry.Highlight.Parent then
                pcall(function() entry.Highlight.FillTransparency = options.FillTransparency or 0.6 end)
            end
        else
            local character = player.Character
            local root = GetRoot(character)
            if not root then
                for _, d in ipairs(entry.DrawObjects or {}) do
                    if d.Obj then pcall(function() d.Obj.Visible = false end) end
                end
            else
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
                    for _, d in ipairs(entry.DrawObjects or {}) do
                        if d.Obj then pcall(function() d.Obj.Visible = false end) end
                    end
                    if entry.Billboard and entry.Billboard.Parent then
                        local lbl = entry.Billboard:FindFirstChildWhichIsA("TextLabel")
                        if lbl then pcall(function() lbl.Text = "" end) end
                    end
                else
                    local height = math.max(20, math.abs(headScreen.Y - footScreen.Y))
                    local width = height * 0.45
                    local humanoid = character:FindFirstChildOfClass("Humanoid")
                    local hpText = ""
                    if options.ShowHealth and humanoid then
                        hpText = "\n" .. tostring(math.floor(humanoid.Health)) .. " HP"
                    end
                    for _, d in ipairs(entry.DrawObjects or {}) do
                        local obj = d.Obj
                        if not obj then
                        else
                            pcall(function()
                                obj.Visible = true
                                if d.Type == "Box" then
                                    obj.PointA = Vector2.new(headScreen.X - width, headScreen.Y)
                                    obj.PointB = Vector2.new(headScreen.X + width, headScreen.Y)
                                    obj.PointC = Vector2.new(footScreen.X + width, footScreen.Y)
                                    obj.PointD = Vector2.new(footScreen.X - width, footScreen.Y)
                                elseif d.Type == "Tracer" then
                                    local from
                                    local tracerFrom = GlobalConfig.TracerFrom or "Bottom"
                                    if options.Tracer and options.Tracer.From then tracerFrom = options.Tracer.From end
                                    if tracerFrom == "Bottom" then
                                        from = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                                    elseif tracerFrom == "Top" then
                                        from = Vector2.new(Camera.ViewportSize.X / 2, 0)
                                    elseif tracerFrom == "Center" then
                                        from = Camera.ViewportSize / 2
                                    elseif typeof(tracerFrom) == "Vector2" then
                                        from = tracerFrom
                                    elseif tracerFrom == "Mouse" then
                                        local mx, my = UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y
                                        from = Vector2.new(mx, my)
                                    else
                                        from = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                                    end
                                    d.Obj.From = from
                                    d.Obj.To = footScreen
                                    d.Obj.Color = ResolveColor((options.Tracer and options.Tracer.Color) or options.Color or ResolveColor(options.Color))
                                    d.Obj.Thickness = (options.Tracer and options.Tracer.Thickness) or options.Thickness or GlobalConfig.Thickness
                                    d.Obj.Transparency = (options.Tracer and options.Tracer.Transparency) or GlobalConfig.Transparency or 0
                                elseif d.Type == "Text" then
                                    local text = player.Name .. "\n" .. tostring(math.floor(dist)) .. " studs" .. hpText
                                    obj.Text = text
                                    obj.Position = headScreen + Vector2.new(0, -height / 2 - 20)
                                    obj.Size = options.Size or 14
                                    obj.Color = ResolveColor(options.LabelColor or options.Color)
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
                            end)
                        end
                    end
                    if entry.Billboard and entry.Billboard.Parent then
                        local label = entry.Billboard:FindFirstChildWhichIsA("TextLabel")
                        if label then
                            local hpTextLocal = ""
                            if options.ShowHealth and humanoid then hpTextLocal = tostring(math.floor(humanoid.Health)) .. " HP" end
                            pcall(function()
                                label.Text = (player.Name or "") .. "\n" .. tostring(math.floor(dist)) .. " studs" .. (hpTextLocal ~= "" and ("\n" .. hpTextLocal) or "")
                                label.TextColor3 = ResolveColor(options.LabelColor or options.Color or (entry.Highlight and entry.Highlight.FillColor) or GlobalConfig.DefaultColor)
                                label.Visible = true
                            end)
                        end
                    end
                    if entry.Highlight and entry.Highlight.Parent then
                        if options.Color then
                            pcall(function() entry.Highlight.FillColor = ResolveColor(options.Color) end)
                        end
                        pcall(function() entry.Highlight.FillTransparency = options.FillTransparency or 0.6 end)
                        pcall(function() entry.Highlight.DepthMode = options.DepthMode or Enum.HighlightDepthMode.AlwaysOnTop end)
                    end
                end
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
                    pcall(function() VelocityESP:RemoveObjectESP(entry.model) end)
                end
            else
                pcall(function() VelocityESP:RemoveObjectESP(part) end)
            end
        else
            local bb = entry.billboard
            local hl = entry.highlight
            local opts = entry.options or {}
            if bb and bb.Parent then
                local label = bb:FindFirstChild(opts.LabelName or "VelocityESP_Label")
                if label then
                    local d = 0
                    if plrRoot then
                        d = math.floor((plrRoot.Position - part.Position).Magnitude)
                    else
                        d = 0
                    end
                    pcall(function()
                        label.Text = (opts.LabelPrefix or "") .. (opts.LabelText or opts.TextlabelText or part.Name) .. "\n" .. tostring(d) .. " studs"
                        label.TextColor3 = ResolveColor(opts.LabelColor or opts.Color or (hl and hl.FillColor) or GlobalConfig.DefaultColor)
                        label.Visible = true
                    end)
                end
            end
            if hl and hl.Parent and opts.Color then
                pcall(function() hl.FillColor = ResolveColor(opts.Color) end)
            end

            if entry.DrawObjects then
                local screenPos, onScreen = WorldToScreenVec(part.Position)
                for _, d in ipairs(entry.DrawObjects) do
                    if not d or not d.Obj then
                    else
                        pcall(function()
                            if d.Type == "Tracer" then
                                local tracerFrom = (opts.Tracer and opts.Tracer.From) or GlobalConfig.TracerFrom
                                local fromVec
                                if tracerFrom == "Bottom" then
                                    fromVec = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                                elseif tracerFrom == "Top" then
                                    fromVec = Vector2.new(Camera.ViewportSize.X / 2, 0)
                                elseif tracerFrom == "Center" then
                                    fromVec = Camera.ViewportSize / 2
                                elseif typeof(tracerFrom) == "Vector2" then
                                    fromVec = tracerFrom
                                elseif tracerFrom == "Mouse" then
                                    local mx, my = UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y
                                    fromVec = Vector2.new(mx, my)
                                else
                                    fromVec = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                                end
                                d.Obj.From = fromVec
                                d.Obj.To = screenPos
                                d.Obj.Color = ResolveColor((opts.Tracer and opts.Tracer.Color) or opts.Color or (hl and hl.FillColor) or GlobalConfig.DefaultColor)
                                d.Obj.Thickness = (opts.Tracer and opts.Tracer.Thickness) or opts.Thickness or GlobalConfig.Thickness
                                d.Obj.Transparency = (opts.Tracer and opts.Tracer.Transparency) or GlobalConfig.Transparency or 0
                                d.Obj.Visible = onScreen
                            elseif d.Type == "ObjectText" then
                                d.Obj.Text = (opts.LabelPrefix or "") .. (opts.LabelText or opts.TextlabelText or part.Name)
                                d.Obj.Position = screenPos
                                d.Obj.Color = ResolveColor((opts.TextLabel and opts.TextLabel.Color) or opts.Color or (hl and hl.FillColor) or GlobalConfig.DefaultColor)
                                d.Obj.Visible = onScreen
                            end
                        end)
                    end
                end
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
                    Tracer = objCfg.Tracer,
                    TextLabel = objCfg.TextLabel
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
    if options.Tracers == nil then options.Tracers = false end
    if options.ShowHighlight == nil then options.ShowHighlight = true end
    if options.ShowBillboard == nil then options.ShowBillboard = true end

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
    self:Remove()
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

getgenv().Velocity_ESP = VelocityESP
VelocityESP.Presets = PresetColors
VelocityESP.ResolveColor = ResolveColor
VelocityESP.AddObjectESP = VelocityESP.AddObjectESP
VelocityESP.RemoveObjectESP = VelocityESP.RemoveObjectESP
VelocityESP.AddObjectsByName = VelocityESP.AddObjectsByName
VelocityESP.RemoveObjectsByName = VelocityESP.RemoveObjectsByName

return VelocityESP
