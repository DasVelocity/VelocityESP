--!nocheck
--!nolint UnknownGlobal
--[[

         ▄▄▄▄███▄▄▄▄      ▄████████         ▄████████    ▄████████    ▄███████▄
        ▄██▀▀▀███▀▀▀██▄   ███    ███        ███    ███   ███    ███   ███    ███
        ███   ███   ███   ███    █▀         ███    █▀    ███    █▀    ███    ███
        ███   ███   ███   ███              ▄███▄▄▄       ███          ███    ███
        ███   ███   ███ ▀███████████      ▀▀███▀▀▀     ▀███████████ ▀█████████▀
        ███   ███   ███          ███        ███    █▄           ███   ███
        ███   ███   ███    ▄█    ███        ███    ███    ▄█    ███   ███
        ▀█   ███   █▀   ▄████████▀         ██████████  ▄████████▀   ▄████▀
                                    v2.0.2

                        Created by Velocity Team (velocityesp.dev)
--]]

--[[
    https://docs.velocityesp.dev/

    VelocityESP:Add({
        Name: string [optional, defaults to Model.Name]
        Model: Instance [required]
        Color: Color3 [optional, defaults to green]
        ShowDistance: boolean [optional, defaults to true]
        Highlight: boolean [optional, defaults to true]
        Tracer: boolean [optional, defaults to true]
        Arrow: boolean [optional, defaults to false]
        OnDestroy: BindableEvent [optional]
        OnDestroyFunc: function [optional]
    })
--]]

local VERSION = "2.0.2"
local debug_print = if getgenv().VelocityESP_DEBUG then (function(...) print("[Velocity ESP]", ...) end) else (function() end)
local debug_warn = if getgenv().VelocityESP_DEBUG then (function(...) warn("[Velocity ESP]", ...) end) else (function() end)
local debug_error = if getgenv().VelocityESP_DEBUG then (function(...) error("[Velocity ESP] " .. table.concat({ ... }, " ")) end) else (function() end)

if getgenv().VelocityESP then
    debug_warn("Already Loaded.")
    return getgenv().VelocityESP
end

export type ESPSettings = {
    Name: string?,
    Model: Instance,
    Color: Color3?,
    ShowDistance: boolean?,
    Highlight: boolean?,
    Tracer: boolean?,
    Arrow: boolean?,
    OnDestroy: BindableEvent?,
    OnDestroyFunc: (() -> nil)?,
}

-- Executor Variables
local cloneref = getgenv().cloneref or function(inst) return inst end

-- Services
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local CoreGui = cloneref(game:GetService("CoreGui"))

-- Utility Functions
local function GetPivot(Instance)
    if Instance.ClassName == "Bone" then
        return Instance.TransformedWorldCFrame
    elseif Instance.ClassName == "Attachment" then
        return Instance.WorldCFrame
    elseif Instance.ClassName == "Camera" then
        return Instance.CFrame
    else
        return Instance:GetPivot()
    end
end

local function RandomString(length)
    length = length or math.random(10, 20)
    local array = {}
    for i = 1, length do
        array[i] = string.char(math.random(32, 126))
    end
    return table.concat(array)
end

-- Instances Utility
local InstancesLib = {
    Create = function(instanceType, properties)
        local instance = Instance.new(instanceType)
        for name, val in pairs(properties) do
            if name == "Parent" then continue end
            instance[name] = val
        end
        if properties["Parent"] then
            instance["Parent"] = properties["Parent"]
        end
        return instance
    end,

    FindPrimaryPart = function(instance)
        if typeof(instance) ~= "Instance" then return nil end
        return (instance:IsA("Model") and instance.PrimaryPart or nil)
            or instance:FindFirstChildWhichIsA("BasePart")
            or instance:FindFirstChildWhichIsA("UnionOperation")
            or instance
    end,

    DistanceFrom = function(inst, from)
        if not (inst and from) then return 9e9 end
        local position = if typeof(inst) == "Instance" then GetPivot(inst).Position else inst
        local fromPosition = if typeof(from) == "Instance" then GetPivot(from).Position else from
        return (fromPosition - position).Magnitude
    end
}

-- CoreGui Access Check
local function getUI()
    local testGui = Instance.new("ScreenGui")
    local success = pcall(function() testGui.Parent = CoreGui end)
    testGui:Destroy()
    return success and CoreGui or Players.LocalPlayer.PlayerGui
end

-- GUI Setup
local ActiveFolder = InstancesLib.Create("Folder", { Parent = getUI(), Name = RandomString() })
local StorageFolder = InstancesLib.Create("Folder", { Parent = game, Name = RandomString() })
local MainGUI = InstancesLib.Create("ScreenGui", {
    Parent = getUI(),
    Name = RandomString(),
    IgnoreGuiInset = true,
    ResetOnSpawn = false,
    ClipToDeviceSafeArea = false,
    DisplayOrder = 999_999
})
local BillboardGUI = InstancesLib.Create("ScreenGui", {
    Parent = getUI(),
    Name = RandomString(),
    IgnoreGuiInset = true,
    ResetOnSpawn = false,
    ClipToDeviceSafeArea = false,
    DisplayOrder = 999_999
})

-- Library
local Library = {
    Destroyed = false,
    ActiveFolder = ActiveFolder,
    StorageFolder = StorageFolder,
    MainGUI = MainGUI,
    BillboardGUI = BillboardGUI,
    ESP = {},
    Connections = {},
    GlobalConfig = {
        IgnoreCharacter = false,
        Rainbow = false,
        Font = Enum.Font.RobotoCondensed
    },
    RainbowHue = 0,
    RainbowStep = 0,
    RainbowColor = Color3.new()
}

-- Player Variables
local character
local rootPart
local camera = workspace.CurrentCamera

local function UpdatePlayerVariables(newCharacter, force)
    if force ~= true and Library.GlobalConfig.IgnoreCharacter then return end
    character = newCharacter or Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
    rootPart = character:WaitForChild("HumanoidRootPart", 2.5)
        or character:WaitForChild("UpperTorso", 2.5)
        or character:WaitForChild("Torso", 2.5)
        or character.PrimaryPart
        or character:WaitForChild("Head", 2.5)
end
task.spawn(UpdatePlayerVariables, nil, true)

local function worldToViewport(...)
    camera = camera or workspace.CurrentCamera
    if not camera then return Vector2.new(0, 0), false end
    return camera:WorldToViewportPoint(...)
end

-- Library Functions
function Library:Clear()
    if Library.Destroyed then return end
    for _, ESP in pairs(Library.ESP) do
        if ESP then ESP:Destroy() end
    end
end

function Library:Destroy()
    if Library.Destroyed then return end
    Library.Destroyed = true
    Library:Clear()
    ActiveFolder:Destroy()
    StorageFolder:Destroy()
    MainGUI:Destroy()
    BillboardGUI:Destroy()
    for _, connection in Library.Connections do
        if connection.Connected then connection:Disconnect() end
    end
    table.clear(Library.Connections)
    getgenv().VelocityESP = nil
    debug_print("Unloaded!")
end

-- Tracer Creation
local function TracerCreate(enabled, color, index)
    if not Library.Destroyed and enabled then
        local Path2D = InstancesLib.Create("Path2D", {
            Parent = MainGUI,
            Name = index or "Tracer",
            Closed = true,
            Color3 = color or Color3.fromRGB(0, 255, 0),
            Thickness = 2,
            Transparency = 0
        })

        local function UpdateTracer(from, to)
            Path2D:SetControlPoints({
                Path2DControlPoint.new(UDim2.fromOffset(from.X, from.Y)),
                Path2DControlPoint.new(UDim2.fromOffset(to.X, to.Y))
            })
        end

        local data = { From = Vector2.new(0, 0), To = Vector2.new(0, 0), Visible = true, Color3 = color, Thickness = 2, Transparency = 0 }
        UpdateTracer(data.From, data.To)

        local proxy = {}
        local Tracer = {
            __newindex = function(_, key, value)
                if not Path2D then return end
                if key == "From" or key == "To" then
                    assert(typeof(value) == "Vector2", tostring(key) .. "; expected Vector2, got " .. typeof(value))
                    UpdateTracer(key == "From" and value or data.From, key == "To" and value or data.To)
                elseif key == "Transparency" or key == "Thickness" then
                    assert(typeof(value) == "number", tostring(key) .. "; expected number, got " .. typeof(value))
                    Path2D[key] = value
                elseif key == "Color3" then
                    assert(typeof(value) == "Color3", tostring(key) .. "; expected Color3, got " .. typeof(value))
                    Path2D.Color3 = value
                elseif key == "Visible" then
                    assert(typeof(value) == "boolean", tostring(key) .. "; expected boolean, got " .. typeof(value))
                    Path2D.Parent = value and MainGUI or StorageFolder
                end
                data[key] = value
            end,

            __index = function(_, key)
                if not Path2D then return nil end
                if key == "Destroy" then
                    return function()
                        Path2D:SetControlPoints({})
                        Path2D:Destroy()
                        Path2D = nil
                    end
                end
                return data[key]
            end
        }
        debug_print("Tracer created.")
        return setmetatable(proxy, Tracer)
    end
end

-- Main ESP Function
function Library:Add(espSettings)
    if Library.Destroyed then
        debug_warn("Library is destroyed, please reload it.")
        return
    end

    assert(typeof(espSettings) == "table", "espSettings; expected table, got " .. typeof(espSettings))
    assert(typeof(espSettings.Model) == "Instance", "espSettings.Model; expected Instance, got " .. typeof(espSettings.Model))

    -- Default Settings
    espSettings.Name = espSettings.Name or espSettings.Model.Name
    espSettings.Color = espSettings.Color or Color3.fromRGB(0, 255, 0)
    espSettings.ShowDistance = espSettings.ShowDistance ~= false
    espSettings.Highlight = espSettings.Highlight ~= false
    espSettings.Tracer = espSettings.Tracer ~= false
    espSettings.Arrow = espSettings.Arrow or false

    local ESP = {
        Index = RandomString(),
        OriginalSettings = espSettings,
        CurrentSettings = espSettings,
        Hidden = false,
        Deleted = false,
        Connections = {},
        RenderThread = nil
    }

    debug_print("Creating ESP...", ESP.Index, "-", ESP.CurrentSettings.Name)

    -- Billboard
    local Billboard = InstancesLib.Create("BillboardGui", {
        Parent = BillboardGUI,
        Name = ESP.Index,
        Enabled = true,
        ResetOnSpawn = false,
        AlwaysOnTop = true,
        Size = UDim2.new(0, 200, 0, 50),
        Adornee = ESP.CurrentSettings.Model,
        StudsOffset = Vector3.new(0, 2, 0)
    })

    local BillboardText = InstancesLib.Create("TextLabel", {
        Parent = Billboard,
        Size = UDim2.new(0, 200, 0, 50),
        Font = Library.GlobalConfig.Font,
        TextWrap = true,
        TextWrapped = true,
        RichText = true,
        TextStrokeTransparency = 0,
        BackgroundTransparency = 1,
        Text = ESP.CurrentSettings.Name,
        TextColor3 = ESP.CurrentSettings.Color,
        TextSize = 18
    })
    InstancesLib.Create("UIStroke", { Parent = BillboardText })

    -- Highlight
    local Highlighter = nil
    if ESP.CurrentSettings.Highlight then
        Highlighter = InstancesLib.Create("Highlight", {
            Parent = ActiveFolder,
            Name = ESP.Index,
            Adornee = ESP.CurrentSettings.Model,
            FillColor = ESP.CurrentSettings.Color,
            OutlineColor = Color3.fromRGB(255, 255, 255),
            FillTransparency = 0.5,
            OutlineTransparency = 0
        })
    end

    -- Tracer and Arrow
    local Tracer = ESP.CurrentSettings.Tracer and TracerCreate(true, ESP.CurrentSettings.Color, ESP.Index)
    local Arrow = nil
    if ESP.CurrentSettings.Arrow then
        Arrow = InstancesLib.Create("ImageLabel", {
            Parent = MainGUI,
            Name = ESP.Index,
            Size = UDim2.new(0, 48, 0, 48),
            SizeConstraint = Enum.SizeConstraint.RelativeYY,
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Image = "http://www.roblox.com/asset/?id=16368985219",
            ImageColor3 = ESP.CurrentSettings.Color
        })
    end

    -- Destroy Handler
    function ESP:Destroy()
        if ESP.Deleted then
            debug_warn("ESP Instance is already deleted.")
            return
        end
        ESP.Deleted = true
        if ESP.RenderThread then
            pcall(coroutine.close, ESP.RenderThread)
        end
        if table.find(Library.ESP, ESP.Index) then
            table.remove(Library.ESP, table.find(Library.ESP, ESP.Index))
        end
        Library.ESP[ESP.Index] = nil
        if Billboard then Billboard:Destroy() end
        if Highlighter then Highlighter:Destroy() end
        if Tracer then Tracer:Destroy() end
        if Arrow then Arrow:Destroy() end
        for _, connection in ESP.Connections do
            if connection.Connected then connection:Disconnect() end
        end
        table.clear(ESP.Connections)
        if ESP.OriginalSettings.OnDestroy then
            pcall(ESP.OriginalSettings.OnDestroy.Fire, ESP.OriginalSettings.OnDestroy)
        end
        if ESP.OriginalSettings.OnDestroyFunc then
            pcall(ESP.OriginalSettings.OnDestroyFunc)
        end
        debug_print("ESP deleted.", ESP.Index, "-", ESP.CurrentSettings.Name)
    end

    -- Visibility Handlers
    local function Show(forceShow)
        if not ESP or ESP.Deleted then return end
        if not forceShow and not ESP.Hidden then return end
        ESP.Hidden = false
        Billboard.Enabled = true
        if Highlighter then
            Highlighter.Adornee = ESP.CurrentSettings.Model
            Highlighter.Parent = ActiveFolder
        end
        if Tracer then Tracer.Visible = true end
        if Arrow then Arrow.Visible = true end
    end

    local function Hide(forceHide)
        if not ESP or ESP.Deleted then return end
        if not forceHide and ESP.Hidden then return end
        ESP.Hidden = true
        Billboard.Enabled = false
        if Highlighter then
            Highlighter.Adornee = nil
            Highlighter.Parent = StorageFolder
        end
        if Tracer then Tracer.Visible = false end
        if Arrow then Arrow.Visible = false end
    end

    function ESP:Show() ESP.CurrentSettings.Visible = true Show() end
    function ESP:Hide() ESP.CurrentSettings.Visible = false Hide() end
    function ESP:ToggleVisibility() ESP.CurrentSettings.Visible = not ESP.CurrentSettings.Visible if ESP.CurrentSettings.Visible then Show() else Hide() end end

    -- Render Loop
    function ESP:Render()
        if not ESP or not ESP.CurrentSettings or ESP.Deleted then return end
        if not ESP.CurrentSettings.Visible or not camera or (not Library.GlobalConfig.IgnoreCharacter and not rootPart) then
            Hide()
            return
        end

        if not ESP.CurrentSettings.ModelRoot then
            ESP.CurrentSettings.ModelRoot = InstancesLib.FindPrimaryPart(ESP.CurrentSettings.Model)
        end

        local screenPos, isOnScreen = worldToViewport(GetPivot(ESP.CurrentSettings.ModelRoot or ESP.CurrentSettings.Model).Position)
        local distanceFromPlayer = InstancesLib.DistanceFrom(
            ESP.CurrentSettings.ModelRoot or ESP.CurrentSettings.Model,
            Library.GlobalConfig.IgnoreCharacter and camera or rootPart
        )

        if distanceFromPlayer > 5000 then
            Hide()
            return
        end

        if Arrow then
            Arrow.Visible = ESP.CurrentSettings.Arrow and (not isOnScreen)
            if Arrow.Visible then
                local screenSize = camera.ViewportSize
                local centerPos = Vector2.new(screenSize.X / 2, screenSize.Y / 2)
                local partPos = Vector2.new(screenPos.X, screenPos.Y)
                local IsInverted = screenPos.Z <= 0
                local invert = IsInverted and -1 or 1
                local direction = partPos - centerPos
                local arctan = math.atan2(direction.Y, direction.X)
                local angle = math.deg(arctan) + 90
                local distance = 0.3 * screenSize.Y
                Arrow.Rotation = angle + 180 * (IsInverted and 0 or 1)
                Arrow.Position = UDim2.new(0, centerPos.X + (distance * math.cos(arctan) * invert), 0, centerPos.Y + (distance * math.sin(arctan) * invert))
                Arrow.ImageColor3 = Library.GlobalConfig.Rainbow and Library.RainbowColor or ESP.CurrentSettings.Color
            end
        end

        if not isOnScreen then
            Hide()
            return
        else
            Show()
        end

        if Tracer and ESP.CurrentSettings.Tracer then
            Tracer.Visible = true
            Tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
            Tracer.To = Vector2.new(screenPos.X, screenPos.Y)
            Tracer.Color3 = Library.GlobalConfig.Rainbow and Library.RainbowColor or ESP.CurrentSettings.Color
        end

        if Billboard then
            Billboard.Enabled = true
            BillboardText.Text = ESP.CurrentSettings.ShowDistance and string.format("%s\n<font size=\"15\">[%d]</font>", ESP.CurrentSettings.Name, math.floor(distanceFromPlayer)) or ESP.CurrentSettings.Name
            BillboardText.TextColor3 = Library.GlobalConfig.Rainbow and Library.RainbowColor or ESP.CurrentSettings.Color
        end

        if Highlighter and ESP.CurrentSettings.Highlight then
            Highlighter.Parent = ActiveFolder
            Highlighter.Adornee = ESP.CurrentSettings.Model
            Highlighter.FillColor = Library.GlobalConfig.Rainbow and Library.RainbowColor or ESP.CurrentSettings.Color
        end
    end

    ESP.RenderThread = coroutine.create(function()
        while true do
            local success, errorMessage = pcall(ESP.Render, ESP)
            if not success then
                task.defer(debug_error, "Failed to render ESP:", errorMessage)
            end
            coroutine.yield()
        end
    end)
    coroutine.resume(ESP.RenderThread)

    Library.ESP[ESP.Index] = ESP
    debug_print("ESP created.", ESP.Index, "-", ESP.CurrentSettings.Name)
    return ESP
end

-- Connections
table.insert(Library.Connections, workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    camera = workspace.CurrentCamera
end))
table.insert(Library.Connections, Players.LocalPlayer.CharacterAdded:Connect(UpdatePlayerVariables))
table.insert(Library.Connections, RunService.RenderStepped:Connect(function(Delta)
    Library.RainbowStep = Library.RainbowStep + Delta
    if Library.RainbowStep >= (1 / 60) then
        Library.RainbowStep = 0
        Library.RainbowHue = (Library.RainbowHue + (1 / 400)) % 1
        Library.RainbowColor = Color3.fromHSV(Library.RainbowHue, 0.8, 1)
    end
end))
table.insert(Library.Connections, RunService.RenderStepped:Connect(function()
    for Index, ESP in Library.ESP do
        if not ESP or not ESP.CurrentSettings or ESP.Deleted then
            if ESP and ESP.RenderThread then
                pcall(coroutine.close, ESP.RenderThread)
            end
            Library.ESP[Index] = nil
            continue
        end
        if not ESP.CurrentSettings.Model or not ESP.CurrentSettings.Model.Parent then
            ESP:Destroy()
            continue
        end
        pcall(coroutine.resume, ESP.RenderThread)
    end
end))

debug_print("Loaded! (" .. VERSION .. ")")
getgenv().VelocityESP = Library
return Library
