
local repo = "https://raw.githubusercontent.com/DasVelocity/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "VelocityLib.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
local Options = Library.Options
local Toggles = Library.Toggles
Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

local function checkExecutor()
    local blacklistedExecutors = {
        ["JJSploit"] = true,
        ["Luna"] = true,
        ["Zorara"] = true,
        ["Argon"] = true,
    }
    local executorName = "Unknown"
    local isBlacklisted = false
    if identifyexecutor then
        executorName = identifyexecutor() or "Unknown"
        if blacklistedExecutors[executorName] then
            isBlacklisted = true
        end
    elseif getexecutorname then
        executorName = getexecutorname() or "Unknown"
        if blacklistedExecutors[executorName] then
            isBlacklisted = true
        end
    else
        local testEnv = getfenv and getfenv() or {}
        if not testEnv.hookmetamethod or not testEnv.getrawmetatable then
            executorName = "Low UNC Executor"
            isBlacklisted = true
        end
    end
    if isBlacklisted then
        local msg = executorName .. " is not supported. Use a stronger executor. if you are broke use valex or volcano"
        pcall(function()
            game.Players.LocalPlayer:Kick(msg)
        end)
        error("Blacklisted executor detected: " .. executorName)
    end
end

local esc = string.char(27)
local function has_rconsole()
    return type(rconsolecreate) == "function" or type(rconsoleprint) == "function"
end

local function try_rconsole_setup()
    if type(rconsolecreate) == "function" then
        pcall(function()
            rconsolecreate()
            if type(rconsolename) == "function" then
                pcall(function() rconsolename("Velocity X Console") end)
            end
            if type(rconsoleclear) == "function" then
                pcall(function() rconsoleclear() end)
            end
        end)
    end
end

local function print_colored(text, color)
    if type(rconsoleprint) == "function" then
        local ok = pcall(function()
            if color == "green" then
                rconsoleprint(esc .. "[32m" .. text .. esc .. "[0m\n")
            elseif color == "red" then
                rconsoleprint(esc .. "[31m" .. text .. esc .. "[0m\n")
            elseif color == "yellow" then
                rconsoleprint(esc .. "[33m" .. text .. esc .. "[0m\n")
            else
                rconsoleprint(text .. "\n")
            end
        end)
        if ok then return end
        pcall(function() rconsoleprint(text .. "\n") end)
        return
    end
    if color == "red" then
        warn("[ERROR] " .. text)
    elseif color == "yellow" then
        warn("[WARN] " .. text)
    else
        print(text)
    end
end

local ascii = [[
____   ____     .__                .__  __           ____  ___
\   \ /   /____ |  |   ____   ____ |__|/  |_ ___.__. \   \/  /
 \   Y   // __ \|  |  /  _ \_/ ___\|  \   __<   |  |  \     / 
  \     /\  ___/|  |_(  <_> )  \___|  ||  |  \___  |  /     \ 
   \___/  \___  >____/\____/ \___  >__||__|  / ____| /___/\  \
              \/                 \/          \/            \_/
]]

local function status_print(name, ok)
    local tag = ok and "[OK]" or "[FAILED]"
    local color = ok and "green" or "red"
    print_colored(string.format("%-40s %s", name, tag), color)
end

local checks = {
    { name = "Executor detection", fn = function()
        local ok = false
        local name = "Unknown"
        if identifyexecutor then
            name = identifyexecutor() or "Unknown"
            ok = true
        elseif getexecutorname then
            name = getexecutorname() or "Unknown"
            ok = true
        else
            ok = false
        end
        return ok, ("Executor: %s"):format(name)
    end},
    { name = "rconsole available", fn = function() return (type(rconsoleprint) == "function" or type(rconsolecreate) == "function"), "" end},
    { name = "HTTP (game:HttpGet) available", fn = function()
        local ok = pcall(function() game:HttpGet("https://example.com") end)
        return ok, ""
    end},
    { name = "VelocityLib loaded", fn = function() return type(Library) == "table", "" end},
    { name = "ThemeManager loaded", fn = function() return type(ThemeManager) == "table", "" end},
    { name = "SaveManager loaded", fn = function() return type(SaveManager) == "table", "" end},
    { name = "Options table present", fn = function() return type(Options) == "table", "" end},
    { name = "Toggles table present", fn = function() return type(Toggles) == "table", "" end},
    { name = "HttpService available", fn = function() local ok = pcall(function() game:GetService("HttpService") end) return ok, "" end},
    { name = "RunService available", fn = function() local ok = pcall(function() game:GetService("RunService") end) return ok, "" end},
    { name = "Player instance", fn = function() return (game.Players and game.Players.LocalPlayer ~= nil), "" end},
    { name = "Repo reachable (quick check)", fn = function()
        local s = pcall(function() game:HttpGet(repo .. "VelocityLib.lua") end)
        return s, ""
    end},
    { name = "Filesystem API (write) available", fn = function()
        return type(writefile) == "function" or type(isfolder) == "function", ""
    end},
}

checkExecutor()
try_rconsole_setup()
print_colored(ascii, "green")

for i, chk in ipairs(checks) do
    local ok, msg = false, ""
    local succeeded, res1, res2 = pcall(function()
        local a,b = chk.fn()
        return a,b
    end)
    if succeeded then
        ok = res1
        msg = res2 or ""
    else
        ok = false
        msg = "check crashed"
    end
    if msg ~= "" then
        print_colored(string.format("%-40s %s", chk.name .. " (" .. tostring(msg) .. ")", ok and "[OK]" or "[FAILED]"), ok and "green" or "red")
    else
        status_print(chk.name, ok)
    end
    pcall(function() wait(0.08) end)
end

print_colored("Script loading...", "yellow")
pcall(function() wait(0.6) end)
print_colored("Script Loaded", "green")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameData = ReplicatedStorage:WaitForChild("GameData")
local currentFloor = GameData:WaitForChild("Floor").Value
wait(0.1)

local Window = Library:CreateWindow({
    Title = "Velocity X",
    Footer = "v2.0 | Velocity X | Floor: " .. currentFloor,
    Icon = 136131547315751,
    NotifySide = "Right",
    ShowCustomCursor = true,
})


local Tabs = {
Home = Window:AddTab("Home", "house"),
Player = Window:AddTab("Player", "user"),
Misc = Window:AddTab("Misc", "box"),
Visuals = Window:AddTab("Visuals", "eye"),
Entities = Window:AddTab("Entities", "shield"),
}


local HomeGroup = Tabs.Home:AddLeftGroupbox("Welcome")

local avatarImage = Instance.new("ImageLabel")
avatarImage.Name = "AvatarThumbnail"
avatarImage.Size = UDim2.new(0, 220, 0, 220)
avatarImage.Position = UDim2.new(0.5, -90, 0, 10)
avatarImage.Image = "rbxassetid://0" 
avatarImage.BackgroundTransparency = 1
avatarImage.BorderSizePixel = 0
avatarImage.ScaleType = Enum.ScaleType.Fit


if HomeGroup.Container then
    avatarImage.Parent = HomeGroup.Container
elseif HomeGroup.Frame then
    avatarImage.Parent = HomeGroup.Frame
else
    avatarImage.Parent = HomeGroup 
end

spawn(function()
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    
    if not player then
        repeat 
            task.wait(0.1) 
            player = Players.LocalPlayer
        until player
    end
    
    task.wait(1)
    
    local success, thumbnail = pcall(function()
        return Players:GetUserThumbnailAsync(
            player.UserId, 
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size180x180
        )
    end)
    
    if success and thumbnail then
        print("Successfully loaded avatar thumbnail")
        avatarImage.Image = thumbnail
    else
        warn("Failed to load avatar thumbnail: " .. tostring(thumbnail))
        
        local alternatives = {
            Enum.ThumbnailType.AvatarThumbnail,
            Enum.ThumbnailType.AvatarBust,
            Enum.ThumbnailType.Avatar
        }
        
        for i, thumbnailType in ipairs(alternatives) do
            local altSuccess, altThumbnail = pcall(function()
                return Players:GetUserThumbnailAsync(
                    player.UserId, 
                    thumbnailType,
                    Enum.ThumbnailSize.Size180x180
                )
            end)
            
            if altSuccess and altThumbnail then
                print("Loaded alternative thumbnail type: " .. tostring(thumbnailType))
                avatarImage.Image = altThumbnail
                break
            else
                warn("Alternative " .. i .. " failed: " .. tostring(altThumbnail))
            end
        end
    end
end)

HomeGroup:AddLabel((function() local h=os.date("*t").hour return (h<12 and h>=5 and "Good morning" or h<17 and "Good afternoon" or h<21 and "Good evening" or "Good night") end)() .. ", " .. game.Players.LocalPlayer.Name)


HomeGroup:AddDivider()


HomeGroup:AddButton("Join Discord", function()
    setclipboard("https://discord.gg/9UuswyPTDE")
    Library:Notify("Discord link copied to clipboard!")
end)
HomeGroup:AddButton("Website", function()
    setclipboard("https://getvelocityx.netlify.app/")
    Library:Notify("website link copied to clipboard!")
end)

local ChangelogsGroup = Tabs.Home:AddRightGroupbox("Changelogs")

ChangelogsGroup:AddLabel('<font color="rgb(76, 0, 255)">Release v2.0</font>')
ChangelogsGroup:AddDivider()
ChangelogsGroup:AddLabel('<font color="rgb(0,255,0)">(+) Added Godmode</font>')
ChangelogsGroup:AddLabel('<font color="rgb(0,255,0)">(+) Ladder anti cheat bypass</font>')
ChangelogsGroup:AddLabel('<font color="rgb(255,165,0)">(=) Fixed Halt</font>')
ChangelogsGroup:AddLabel('<font color="rgb(255,0,0)">(-) Removed Christmas Stuff</font>')




local StatusGroup = Tabs.Home:AddRightGroupbox("Status")

local HttpService = game:GetService("HttpService")
local fileName = "velocityx_executions.json"
local count = 0

if isfile(fileName) then
    local success, data = pcall(function()
        return HttpService:JSONDecode(readfile(fileName))
    end)
    if success and data.count then
        count = data.count
    end
end

count = count + 1

pcall(function()
    writefile(fileName, HttpService:JSONEncode({count = count}))
end)

local ExecutionLabel = StatusGroup:AddLabel('<font color="rgb(0,255,255)">Total Executions: ' .. count .. '</font>')




local LocalPlayer = game.Players.LocalPlayer
local Rooms = workspace.CurrentRooms
local Unloaded = false
local ClonedCollision
local OldAccel = LocalPlayer.Character.HumanoidRootPart.CustomPhysicalProperties
local AntiConnections = {}
local oldBrightness = game.Lighting.Brightness
local oldClockTime = game.Lighting.ClockTime
local oldFogEnd = game.Lighting.FogEnd
local oldGlobalShadows = game.Lighting.GlobalShadows
local oldAmbient = game.Lighting.Ambient











local GodmodeStuff = Tabs.Player:AddLeftGroupbox('<font color="#8000FF">G</font><font color="#9A00FF">o</font><font color="#B200FF">d</font><font color="#C500FF">m</font><font color="#B200FF">o</font><font color="#9A00FF">d</font><font color="#8000FF">e</font>')





--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local lp = Players.LocalPlayer
local Toggles = Library.Toggles
local Options = Library.Options

--// Variables
local AutoMode = "Toggle"
local PreviousMode = "Toggle"
local AutoDistance = 166
local ActiveEntities = {}

--// Core Godmode logic
local function setGodmode(state)
    local char = lp.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local collision = char:FindFirstChild("Collision")
    if not (hum and collision) then return end

    if state then
        hum.HipHeight = 0.09
        collision.Size = Vector3.new(1, 3, 3)
        if collision:FindFirstChild("CollisionCrouch") then
            collision.CollisionCrouch.Size = Vector3.new(1, 3, 3)
        end
    else
        hum.HipHeight = 2.4
        collision.Size = Vector3.new(5.5, 3, 3)
        if collision:FindFirstChild("CollisionCrouch") then
            collision.CollisionCrouch.Size = Vector3.new(5.5, 3, 3)
        end
    end
end

local function safeDisableGod()
    if not lp.Character then return end
    local hum = lp.Character:FindFirstChildOfClass("Humanoid")
    local collision = lp.Character:FindFirstChild("Collision")
    if not (hum and collision) then
        setGodmode(false)
        return
    end

    local wasNoclip = Toggles.Noclip and Toggles.Noclip.Value
    local shouldShim = AutoMode ~= "Never" and not wasNoclip

    if shouldShim and Toggles.Noclip then
        Toggles.Noclip:SetValue(true)
    end

    setGodmode(false)

    if shouldShim and Toggles.Noclip then
        task.delay(0.2, function()
            if Toggles.Noclip and Toggles.Noclip.Value then
                Toggles.Noclip:SetValue(false)
            end
        end)
    end
end

GodmodeStuff:AddDropdown("GodmodeMode", {
    Text = "Godmode Mode",
    Default = "Toggle",
    Values = {"Toggle", "Automatic", "Hold", "Always"},
    Callback = function(mode)
        if PreviousMode == "Always" and mode ~= "Always" then
            if Toggles.PositionSpoof and Toggles.PositionSpoof.Value then
                Toggles.PositionSpoof:SetValue(false)
                setGodmode(false)
                if Toggles.Noclip and not Toggles.Noclip.Value then
                    Toggles.Noclip:SetValue(true)
                    task.delay(0.2, function()
                        if Toggles.Noclip and Toggles.Noclip.Value then
                            Toggles.Noclip:SetValue(false)
                        end
                    end)
                end
            end
        end

        AutoMode = mode
        PreviousMode = mode

        if Options.PositionSpoofKey then
            Options.PositionSpoofKey.Text = "Position Spoof (" .. mode .. ")"
        end

        if mode == "Always" then
            Toggles.PositionSpoof:SetValue(true)
        elseif mode == "Never" then
            Toggles.PositionSpoof:SetValue(false)
        end
    end
})

GodmodeStuff:AddToggle("PositionSpoof", {
    Text = "Godmode Toggle",
    Default = false,
    Callback = function(v)
        if v then
            setGodmode(true)
            
            for i = 1, 1 do
                Library:Notify({
    Title = '<font color="#FF4040">I</font><font color="#FF5050">M</font><font color="#FF6060">P</font><font color="#FF7070">O</font><font color="#FF8080">R</font><font color="#FF9090">T</font><font color="#FFA0A0">A</font><font color="#FFB0B0">N</font><font color="#FFA0A0">T</font><font color="#FF9090">:</font><font color="#FF8080"> </font><font color="#FF7070">C</font><font color="#FF6060">R</font><font color="#FF5050">O</font><font color="#FF4040">U</font><font color="#FF5050">C</font><font color="#FF6060">H</font><font color="#FF7070"> </font><font color="#FF8080">W</font><font color="#FF9090">H</font><font color="#FFA0A0">E</font><font color="#FFB0B0">N</font><font color="#FFA0A0"> </font><font color="#FF9090">A</font><font color="#FF8080">N</font><font color="#FF7070"> </font><font color="#FF6060">E</font><font color="#FF5050">N</font><font color="#FF4040">T</font><font color="#FF5050">I</font><font color="#FF6060">T</font><font color="#FF7070">Y</font><font color="#FF8080"> </font><font color="#FF9090">I</font><font color="#FFA0A0">S</font><font color="#FFB0B0"> </font><font color="#FFA0A0">C</font><font color="#FF9090">O</font><font color="#FF8080">M</font><font color="#FF7070">I</font><font color="#FF6060">N</font><font color="#FF5050">G</font><font color="#FF4040">!</font><font color="#FF5050">!</font><font color="#FF6060">!</font>',
    Description = "",
    Duration = 10,
    Color = Color3.fromRGB(255, 64, 64)
})
            end
        else
            safeDisableGod()
        end
    end
}):AddKeyPicker("PositionSpoofKey", {
    Default = "K",
    Mode = "Toggle",
    Text = "Position Spoof (Toggle)",
    NoUI = false,
    SyncToggleState = true,
})

--// Entity Detection
local EntList = {"a60", "ambushmoving", "backdoorrush", "rushmoving", "mandrake"}
local function IsValidEntity(entity)
    return table.find(EntList, entity.Name:lower()) ~= nil
end

workspace.DescendantAdded:Connect(function(entity)
    if not IsValidEntity(entity) then return end
    local part = entity:FindFirstChildWhichIsA("BasePart")
    if part then ActiveEntities[entity] = part end
end)

--// Mode Logic
RunService.RenderStepped:Connect(function()
    if getgenv().Library.Unloaded then return end

    local root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    if AutoMode == "Never" then
        if Toggles.PositionSpoof.Value then
            Toggles.PositionSpoof:SetValue(false)
        end

    elseif AutoMode == "Always" then
        if not Toggles.PositionSpoof.Value then
            Toggles.PositionSpoof:SetValue(true)
        end

    elseif AutoMode == "Automatic" then
        local shouldEnable = false
        for entity, part in pairs(ActiveEntities) do
            if entity.Parent == nil then
                ActiveEntities[entity] = nil
            elseif part then
                local dist = (root.Position - part.Position).Magnitude
                if dist < AutoDistance then
                    shouldEnable = true
                    break
                end
            end
        end
        if shouldEnable then
            if not Toggles.PositionSpoof.Value then
                Toggles.PositionSpoof:SetValue(true)
            end
        else
            if Toggles.PositionSpoof.Value then
                Toggles.PositionSpoof:SetValue(false)
                safeDisableGod()
            end
        end

    elseif AutoMode == "Hold" then
        local keyCode = Options.PositionSpoofKey and Options.PositionSpoofKey.Value
        if keyCode and UserInputService:IsKeyDown(keyCode) then
            if not Toggles.PositionSpoof.Value then
                Toggles.PositionSpoof:SetValue(true)
            end
        else
            if Toggles.PositionSpoof.Value then
                Toggles.PositionSpoof:SetValue(false)
                safeDisableGod()
            end
        end

    elseif AutoMode == "Toggle" then
        -- Manual toggle only
    end
end)

--// Keep reapplied
task.spawn(function()
    while true do
        task.wait(0.1)
        if getgenv().Library.Unloaded then break end
        if Toggles.PositionSpoof and Toggles.PositionSpoof.Value then
            setGodmode(true)
        end
    end
end)





local MovementGroup = Tabs.Player:AddLeftGroupbox("Walkspeed")









local LocalPlayer = game.Players.LocalPlayer
local Unloaded = false
local ClonedCollision
local OldAccel = PhysicalProperties.new(0.01, 0.7, 0, 1, 1)

-- Clone CollisionPart if available
if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("CollisionPart") then
    ClonedCollision = LocalPlayer.Character.CollisionPart:Clone()
    ClonedCollision.Name = "_CollisionClone"
    ClonedCollision.Massless = true
    ClonedCollision.Parent = LocalPlayer.Character
    ClonedCollision.CanCollide = false
    ClonedCollision.CanQuery = false
    ClonedCollision.CustomPhysicalProperties = OldAccel
end

-- Handle collision tricks for speed
task.spawn(function()
    while task.wait(0.23) and not Unloaded do
        if Toggles.WalkspeedModifier.Value and Options.WalkspeedAmount.Value > 21 and ClonedCollision then
            ClonedCollision.Massless = false
            task.wait(0.23)
            if LocalPlayer.Character 
            and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") 
            and LocalPlayer.Character.HumanoidRootPart.Anchored then
                ClonedCollision.Massless = true
                task.wait(1)
            end
            ClonedCollision.Massless = true
        end
    end
end)

-- Speed bypass replacement (no getsenv/hookfunction)
local BypassLabel = MovementGroup:AddLabel('<font color="rgb(255,0,0)">Speed Bypass: Inactive</font>')

local function updateBypassLabel()
    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        local realSpeed = humanoid.WalkSpeed
        local active = realSpeed > 21
        local color = active and "0,255,0" or "255,0,0"
        local status = active and "Active" or "Inactive"
        BypassLabel:SetText('<font color="rgb(' .. color .. ')">Speed Bypass: ' .. status .. '</font>')
    end
end

task.spawn(function()
    while task.wait(0.1) and not Unloaded do
        local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            if Toggles.WalkspeedModifier.Value then
                humanoid.WalkSpeed = Options.WalkspeedAmount.Value
            end
            updateBypassLabel()
        end
    end
end)

MovementGroup:AddDivider()

local function bindHumanoid(humanoid)
    humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(updateBypassLabel)
end

MovementGroup:AddToggle("WalkspeedModifier", {
    Text = "Custom Walk Speed",
    Default = false,
    Tooltip = "Changes your walking speed to the set value.",
    Callback = function(Value)
        updateBypassLabel()
    end
})

MovementGroup:AddToggle("NoAcceleration", {
    Text = "Instant Acceleration",
    Default = false,
    Tooltip = "Removes slow-down when changing direction.",
    Callback = function(Value)
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CustomPhysicalProperties = Value and PhysicalProperties.new(100, 0, 0, 0, 0) or OldAccel
        end
    end
})

MovementGroup:AddSlider("WalkspeedAmount", {
    Text = "Walk Speed Value",
    Default = 21,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Compact = true,
    Tooltip = "Sets how fast you walk.",
    Callback = function(Value)
        updateBypassLabel()
    end
})

LocalPlayer.CharacterAdded:Connect(function(character)
    local humanoid = character:WaitForChild("Humanoid")
    bindHumanoid(humanoid)
    updateBypassLabel()
end)

if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
    bindHumanoid(LocalPlayer.Character.Humanoid)
end

updateBypassLabel()







local MovementGroupZ = Tabs.Player:AddLeftGroupbox("Movement")

MovementGroupZ:AddToggle("AlwaysJump", { Text = "Always Can Jump", Default = false, Tooltip = "Lets you jump anytime.", Callback = function(Value)
    LocalPlayer.Character:SetAttribute("CanJump", Value or CanJump)
end })


local isFlying = false
local flyConnections = {}
local keys = {W = false, A = false, S = false, D = false, Space = false, Shift = false}
local FlySpeed = 50 

local function startFly()
    local player = game.Players.LocalPlayer
    local character = player.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local bv = Instance.new("BodyVelocity")
    bv.Name = "FlyVelocity"
    bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)  
    bv.Velocity = Vector3.new(0, 0, 0)
    bv.Parent = hrp

    local bg = Instance.new("BodyGyro")
    bg.Name = "FlyGyro"
    bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    bg.P = 20000 
    bg.D = 1000  
    bg.Parent = hrp

    humanoid.AutoRotate = false
    humanoid.PlatformStand = true
    humanoid:ChangeState(Enum.HumanoidStateType.Physics)

    local inputBegan = game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.W then keys.W = true
        elseif input.KeyCode == Enum.KeyCode.A then keys.A = true
        elseif input.KeyCode == Enum.KeyCode.S then keys.S = true
        elseif input.KeyCode == Enum.KeyCode.D then keys.D = true
        elseif input.KeyCode == Enum.KeyCode.Space then keys.Space = true
        elseif input.KeyCode == Enum.KeyCode.LeftShift then keys.Shift = true end
    end)
    table.insert(flyConnections, inputBegan)

    local inputEnded = game:GetService("UserInputService").InputEnded:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.W then keys.W = false
        elseif input.KeyCode == Enum.KeyCode.A then keys.A = false
        elseif input.KeyCode == Enum.KeyCode.S then keys.S = false
        elseif input.KeyCode == Enum.KeyCode.D then keys.D = false
        elseif input.KeyCode == Enum.KeyCode.Space then keys.Space = false
        elseif input.KeyCode == Enum.KeyCode.LeftShift then keys.Shift = false end
    end)
    table.insert(flyConnections, inputEnded)

    local renderConnection = game:GetService("RunService").RenderStepped:Connect(function()
        local cam = workspace.CurrentCamera
        if not cam or not hrp or not hrp:FindFirstChild("FlyVelocity") or not humanoid or humanoid.Health <= 0 then
            stopFly()
            return
        end

        local move = Vector3.new(0, 0, 0)
        if keys.W then move = move + cam.CFrame.LookVector end
        if keys.S then move = move - cam.CFrame.LookVector end
        if keys.A then move = move - cam.CFrame.RightVector end
        if keys.D then move = move + cam.CFrame.RightVector end
        if keys.Space then move = move + Vector3.new(0, 1, 0) end
        if keys.Shift then move = move - Vector3.new(0, 1, 0) end

        local direction = (move.Magnitude > 0) and (move.Unit * FlySpeed) or Vector3.new(0, 0, 0)
        bv.Velocity = direction

        bg.CFrame = cam.CFrame
    end)
    table.insert(flyConnections, renderConnection)
end

local function stopFly()
    local player = game.Players.LocalPlayer
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local hrp = character and character:FindFirstChild("HumanoidRootPart")

    if hrp then
        local flyVelocity = hrp:FindFirstChild("FlyVelocity")
        if flyVelocity then flyVelocity:Destroy() end
        local flyGyro = hrp:FindFirstChild("FlyGyro")
        if flyGyro then flyGyro:Destroy() end
    end

    if humanoid then
        humanoid.AutoRotate = true
        humanoid.PlatformStand = false
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end

    for _, conn in ipairs(flyConnections) do
        conn:Disconnect()
    end
    flyConnections = {}

    keys = {W = false, A = false, S = false, D = false, Space = false, Shift = false}
end

MovementGroupZ:AddToggle("Fly", {
    Text = "Fly",
    Default = false,
    Callback = function(Value)
        isFlying = Value
        if Value then
            startFly()
        else
            stopFly()
        end
    end
}):AddKeyPicker("FlyKeybind", {
    Default = "F",
    SyncToggleState = true, 
    Mode = "Toggle", 
    Text = "Fly Toggle", 
    NoUI = false, 

    Callback = function(Value)
    end,
})














local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local lp = Players.LocalPlayer
local noclipConnection
local originalGroups = {}

local function enableNoclip()
    if noclipConnection then return end
    noclipConnection = RunService.Stepped:Connect(function()
        if lp.Character then
            for _, part in pairs(lp.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                    if not originalGroups[part] then
                        originalGroups[part] = part.CollisionGroup
                    end
                    part.CollisionGroup = "Default"
                end
            end
        end
    end)
end

local function disableNoclip()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end

    local char = lp.Character
    if not char then return end

    local collision = char:FindFirstChild("Collision")
    local crouch = collision and collision:FindFirstChild("CollisionCrouch")

    if collision and crouch then
        local crouching = (collision.CollisionGroup == "PlayerCrouching")
        collision.CanCollide = not crouching
        crouch.CanCollide = crouching
    end
end

MovementGroupZ:AddToggle("Noclip", {
    Text = "Noclip",
    Default = false,
    Tooltip = "you know what it does",
    Callback = function(Value)
        if Value then
            enableNoclip()
        else
            disableNoclip()
        end
    end,
}):AddKeyPicker("NoclipKeybind", {
    Default = "N",
    SyncToggleState = true,
    Mode = "Toggle",
    Text = "Noclip Toggle",
    NoUI = false,
    Callback = function(Value)
    end,
})


















game.Players.LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    if isFlying then
        newCharacter:WaitForChild("HumanoidRootPart")
        newCharacter:WaitForChild("Humanoid")
        startFly()
    end
end)

game.Players.LocalPlayer.CharacterRemoving:Connect(function()
    if isFlying then
        stopFly()
    end
end)






local RunService = game:GetService("RunService")

MovementGroupZ:AddToggle("LadderSpeedBoost", {
    Text = "Faster Ladder Climb",
    Default = false,
    Callback = function(on)
        if on then
            AntiConnections.LadderBoost = RunService.Heartbeat:Connect(function()
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hum and hrp and hum:GetState() == Enum.HumanoidStateType.Climbing then
                    hrp.Velocity = Vector3.new(hrp.Velocity.X, Options.LadderSpeedBoostAmount.Value, hrp.Velocity.Z)
                end
            end)
        else
            if AntiConnections.LadderBoost then
                AntiConnections.LadderBoost:Disconnect()
                AntiConnections.LadderBoost = nil
            end
        end
    end
})


MovementGroupZ:AddSlider("LadderSpeedBoostAmount", {
    Text = "Ladder Climb Speed",
    Default = 20,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Compact = true,
    Tooltip = "Boost for climbing ladders. Higher values might be unstable."
})


local FlySpeed = 50

MovementGroupZ:AddSlider("Fly Speed", {
    Text = "Fly Speed",
    Default = FlySpeed,
    Min = 0,
    Max = 150,
    Rounding = 0,
    Compact = true,
    Tooltip = "Change fly speed",
    Callback = function(Value)
        FlySpeed = Value
    end
})









local VisualEffects = Tabs.Player:AddRightGroupbox("Visual Effects")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera


VisualEffects:AddToggle("NoLookBob", {
    Text = "No Head Bobbing",
    Default = false,
    Tooltip = "Removes head bobbing when walking.",
    Callback = function(Value)
        require(LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game).spring.Speed = Value and 9e9 or 8
    end
})


local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local fullbrightEnabled = false
local ambienceColor = Color3.new(1, 1, 1)

VisualEffects:AddToggle("Ambience", {
    Text = "Fullbright",
    Default = false,
    Tooltip = "Changes the map's color tint.",
    Callback = function(Value)
        fullbrightEnabled = Value
        Lighting.GlobalShadows = not Value
        Lighting.OutdoorAmbient = Value and ambienceColor or Color3.new(0, 0, 0)
    end
}):AddColorPicker("AmbienceColor", {
    Default = Color3.new(1, 1, 1),
    Title = "Color Tint",
    Callback = function(Value)
        ambienceColor = Value
        if fullbrightEnabled then
            Lighting.OutdoorAmbient = Value
        end
    end
})

coroutine.wrap(function()
    while true do
        if fullbrightEnabled then
            Lighting.GlobalShadows = false
            Lighting.OutdoorAmbient = ambienceColor
        end
        wait(1)
    end
end)()


VisualEffects:AddToggle("NoFog", {
    Text = "Remove Fog",
    Default = false,
    Tooltip = "Clears any fog in the map.",
    Callback = function(on)
        if on then
            -- destroy the Fog atmosphere if it exists
            local fog = Lighting:FindFirstChild("Fog")
            if fog and fog:IsA("Atmosphere") then
                fog:Destroy()
            end
            Lighting.FogEnd = 9999
        else
            -- optional: recreate default fog
            local fog = Instance.new("Atmosphere")
            fog.Name = "Fog"
            fog.Density = 0.3
            fog.Parent = Lighting
            Lighting.FogEnd = 500
        end
    end
})


VisualEffects:AddButton("NoLag", {
    Text = "No Lag",
    Func = function()
        local isToggled = not (game.Lighting:FindFirstChild("_OriginalLightingData") or workspace:FindFirstChild("_OriginalData", true))
        
        if isToggled then
            local lightingData = game.Lighting:FindFirstChild("_OriginalLightingData")
            if not lightingData then
                lightingData = Instance.new("Folder")
                lightingData.Name = "_OriginalLightingData"
                local gs = Instance.new("BoolValue")
                gs.Name = "GlobalShadows"
                gs.Value = game.Lighting.GlobalShadows
                gs.Parent = lightingData
                local fe = Instance.new("NumberValue")
                fe.Name = "FogEnd"
                fe.Value = game.Lighting.FogEnd
                fe.Parent = lightingData
                local ql = Instance.new("StringValue")
                ql.Name = "QualityLevel"
                ql.Value = tostring(settings().Rendering.QualityLevel)
                ql.Parent = lightingData
                lightingData.Parent = game.Lighting
            end

            game.Lighting.GlobalShadows = false
            game.Lighting.FogEnd = 9e9
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01

            local function applyPoopGraphics(obj)
                if obj:IsA("BasePart") then
                    if not obj:FindFirstChild("_OriginalData") then
                        local folder = Instance.new("Folder")
                        folder.Name = "_OriginalData"
                        local mat = Instance.new("StringValue")
                        mat.Name = "Material"
                        mat.Value = tostring(obj.Material)
                        mat.Parent = folder
                        local variant = Instance.new("StringValue")
                        variant.Name = "MaterialVariant"
                        variant.Value = obj.MaterialVariant
                        variant.Parent = folder
                        local textures = Instance.new("Folder")
                        textures.Name = "Textures"
                        textures.Parent = folder
                        for _, child in ipairs(obj:GetChildren()) do
                            if child:IsA("Texture") or child:IsA("Decal") then
                                local copy = child:Clone()
                                copy.Parent = textures
                                child:Destroy()
                            end
                        end
                        folder.Parent = obj
                    end
                    obj.Material = Enum.Material.SmoothPlastic
                    obj.MaterialVariant = ""
                end
            end

            for _, obj in ipairs(workspace:GetDescendants()) do
                applyPoopGraphics(obj)
            end

            if not workspace:FindFirstChild("_NoLagConnection") then
                local conn = workspace.DescendantAdded:Connect(applyPoopGraphics)
                conn.Name = "_NoLagConnection" -- tag it so we can disconnect later
                local connHolder = Instance.new("ObjectValue")
                connHolder.Name = "_NoLagConnection"
                connHolder.Value = conn
                connHolder.Parent = workspace
            end

        else
            local lightingData = game.Lighting:FindFirstChild("_OriginalLightingData")
            if lightingData then
                local gs = lightingData:FindFirstChild("GlobalShadows")
                if gs then game.Lighting.GlobalShadows = gs.Value end
                local fe = lightingData:FindFirstChild("FogEnd")
                if fe then game.Lighting.FogEnd = fe.Value end
                local ql = lightingData:FindFirstChild("QualityLevel")
                if ql then settings().Rendering.QualityLevel = Enum.QualityLevel[ql.Value] end
                lightingData:Destroy()
            end

            local connHolder = workspace:FindFirstChild("_NoLagConnection")
            if connHolder and connHolder.Value then
                connHolder.Value:Disconnect()
                connHolder:Destroy()
            end

            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") then
                    local data = obj:FindFirstChild("_OriginalData")
                    if data then
                        local mat = data:FindFirstChild("Material")
                        if mat then obj.Material = Enum.Material[mat.Value] end
                        local variant = data:FindFirstChild("MaterialVariant")
                        if variant then obj.MaterialVariant = variant.Value end
                        local textures = data:FindFirstChild("Textures")
                        if textures then
                            for _, saved in ipairs(textures:GetChildren()) do
                                local restored = saved:Clone()
                                restored.Parent = obj
                            end
                        end
                        data:Destroy()
                    end
                end
            end
        end
    end
})




VisualEffects:AddDivider()

VisualEffects:AddToggle("Thirdperson", {
    Text = "Third Person View",
    Default = false,
    Tooltip = "Shows your character from behind.",
    Callback = function(Value)
        if Value then
            AntiConnections["Thirdperson"] = RunService.RenderStepped:Connect(function()
                local Cam = workspace.CurrentCamera
                Cam.CFrame = Cam.CFrame * CFrame.new(Options.ThirdpersonOffset.Value, Options.ThirdpersonOffsetUp.Value, 3.5 * (Options.ThirdpersonDistance.Value / 7.5))
                
                local character = game.Players.LocalPlayer.Character
                if character then
                    local head = character:FindFirstChild("Head")
                    if head then
                        head.LocalTransparencyModifier = 0
                    end
                    for _, accessory in pairs(character:GetChildren()) do
                        if accessory:IsA("Accessory") then
                            local handle = accessory:FindFirstChild("Handle")
                            if handle then
                                handle.LocalTransparencyModifier = 0
                            end
                        end
                    end
                end
            end)
        else
            if AntiConnections["Thirdperson"] then AntiConnections["Thirdperson"]:Disconnect() end
        end
    end
}):AddKeyPicker("ThirdpersonKey", { 
    Default = "V", 
    SyncToggleState = true, -- Change this to true for automatic sync
    Mode = "Toggle", 
    Text = "Third Person", 
    NoUI = false,
    
    Callback = function(Value)
        -- This will automatically work with SyncToggleState = true
        -- No additional code needed
    end
})

VisualEffects:AddSlider("ThirdpersonDistance", {
    Text = "Third Person Distance",
    Default = 19,
    Min = 5,
    Max = 30,
    Rounding = 0,
    Compact = true,
    Tooltip = "How far the camera is in third person."
})
VisualEffects:AddSlider("ThirdpersonOffset", {
    Text = "Third Person Side Offset",
    Default = 0,
    Min = -5,
    Max = 5,
    Rounding = 1,
    Compact = true,
    Tooltip = "Left/right camera shift in third person."
})
VisualEffects:AddSlider("ThirdpersonOffsetUp", {
    Text = "Third Person Height Offset",
    Default = 0,
    Min = -5,
    Max = 5,
    Rounding = 1,
    Compact = true,
    Tooltip = "Up/down camera shift in third person."
})



VisualEffects:AddSlider("FOV", {
    Text = "Field of View",
    Default = 70,
    Min = 0,
    Max = 120,
    Rounding = 1,
    Compact = true,
    Tooltip = "Changes camera field of view smoothly every frame.",
    Callback = function(TargetFOV)
        TargetFOV = math.clamp(TargetFOV, 0, 120)
        local CurrentFOV = Camera.FieldOfView or 70
        local Speed = 10  -- Higher = faster transitions

        -- Disconnect previous connection if it exists
        if _G.FOVConnection then _G.FOVConnection:Disconnect() end

        -- Update FOV every frame smoothly
        _G.FOVConnection = RunService.RenderStepped:Connect(function(dt)
            CurrentFOV = CurrentFOV + (TargetFOV - CurrentFOV) * math.clamp(Speed * dt, 0, 1)
            Camera.FieldOfView = CurrentFOV
        end)
    end
})

local AutomationGroup = Tabs.Player:AddRightGroupbox("Automation")

local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

local AntiAFKConnection

AutomationGroup:AddToggle("AntiAFK", {
    Text = "Anti AFK",
    Default = false,
    Callback = function(Value)
        if Value then
            -- Connect when toggle is on
            AntiAFKConnection = LocalPlayer.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        else
            -- Disconnect when toggle is off
            if AntiAFKConnection then
                AntiAFKConnection:Disconnect()
                AntiAFKConnection = nil
            end
        end
    end
})



local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local dummy = Instance.new("Part")
dummy.Name = "CameraDummy"
dummy.Anchored = true
dummy.Transparency = 1
dummy.Size = Vector3.new(1, 1, 1)
dummy.Parent = workspace

local originalSubject = nil

AutomationGroup:AddToggle("AntiCheatManipulation", {
    Text = "Anti-Cheat Manipulation",
    Default = false,
}):AddKeyPicker("AntiCheatManipulation_K", {
    Default = "T",
    SyncToggleState = false,
    Mode = "Hold",
    Text = "Anti-Cheat Manipulation",
    NoUI = false,
})

RunService.Heartbeat:Connect(function()
    local isActive = Toggles.AntiCheatManipulation.Value and Options.AntiCheatManipulation_K:GetState()
    
    if isActive then
        if LocalPlayer.Character then
            if Camera.CameraSubject ~= dummy then
                originalSubject = Camera.CameraSubject
                Camera.CameraSubject = dummy
            end
            dummy.CFrame = LocalPlayer.Character:GetPivot()
            LocalPlayer.Character:PivotTo(dummy.CFrame * CFrame.new(0, 0, 1000))
        end
    else
        if Camera.CameraSubject == dummy then
            Camera.CameraSubject = originalSubject
        end
    end
end)

local Script = {}
Script.Functions = {}
Script.Temp = {}
Script.PromptTable = {}
Script.PromptTable.GamePrompts = {}
shared.Connections = {}














local Breaker = nil

AutomationGroup:AddToggle("AutoBreakerSolver", {
    Text = "Solve Breaker Minigame",
    Default = false,
    Callback = function(Value)
        for _, v in ipairs(workspace.CurrentRooms:GetDescendants()) do
            if v.Name == "ElevatorBreaker" then
                Breaker = v
            end
        end
        while task.wait() do
            if not Toggles.AutoBreakerSolver.Value then break end
            if Breaker then
                for _, v in ipairs(Breaker:GetChildren()) do
                    if v.Name == "BreakerSwitch" then
                        if v:GetAttribute("ID") == tonumber(Breaker:WaitForChild("SurfaceGui").Frame.Code.Text) then
                            if Breaker:WaitForChild("SurfaceGui").Frame.Code.Frame.BackgroundTransparency == 0 then
                                v:SetAttribute("Enabled", true)
                                if not v:WaitForChild("Sound").Playing then
                                    v:WaitForChild("Sound", 1e1).Playing = true
                                end
                                v.Material = Enum.Material.Neon
                                v:WaitForChild("Light", 1e1).Attachment.Spark:Emit(1)
                                v:WaitForChild("PrismaticConstraint").TargetPosition = -0.2
                            else
                                v:SetAttribute("Enabled", false)
                                if not v:WaitForChild("Sound").Playing then
                                    v:WaitForChild("Sound", 1e1).Playing = true
                                end
                                v:WaitForChild("PrismaticConstraint").TargetPosition = 0.2
                                v.Material = Enum.Material.Glass
                            end
                        end
                    end
                end
            end
        end
    end
})













local function HasItem(itemName)
    return LocalPlayer.Character:FindFirstChild(itemName) or LocalPlayer.Backpack:FindFirstChild(itemName)
end

local function extractPadlockCode()
    local Paper = HasItem("LibraryHintPaper")
    
    if not Paper then
        for _, Player in Players:GetPlayers() do
            if Player ~= LocalPlayer and (Player.Character:FindFirstChild("LibraryHintPaper") or Player.Backpack:FindFirstChild("LibraryHintPaper")) then
                Paper = Player.Character:FindFirstChild("LibraryHintPaper") or Player.Backpack:FindFirstChild("LibraryHintPaper")
                break
            end
        end
    end
    
    if not Paper then
        return nil, "No LibraryHintPaper found"
    end
    
    if not Paper:FindFirstChild("UI") then
        return nil, "LibraryHintPaper has no UI"
    end
    
    local Code = ""
    local symbolsFound = 0
    
    for _, x in pairs(Paper.UI:GetChildren()) do
        if tonumber(x.Name) then
            symbolsFound = symbolsFound + 1
            for _, y in pairs(LocalPlayer.PlayerGui.PermUI.Hints:GetChildren()) do
                if y.Name == "Icon" then
                    if y.ImageRectOffset == x.ImageRectOffset then
                        Code = Code .. y.TextLabel.Text
                    end
                end
            end
        end
    end
    
    if #Code == 5 then
        return Code, "success"
    elseif symbolsFound > 0 then
        return nil, "Missing books - only found " .. symbolsFound .. " out of 5 symbols"
    else
        return nil, "No symbols found on the paper"
    end
end

AutomationGroup:AddButton("solvecode", {
    Text = "Solve Library Code",
    Tooltip = "solves the library code",
    Func = function()
        local code, status = extractPadlockCode()
        
        if code then
            Library:Notify("Library Code: " .. code, 3)
            print("[Library Solver] The padlock code is: " .. code)
        else
            Library:Notify(status or "Unable to find code", 2)
        end
    end
})




local originalRanges = {} 
local rangeConnections = {}

local function updateProximityPromptRanges(multiplier)
    local function modifyPrompt(prompt)
        if not originalRanges[prompt] then
            originalRanges[prompt] = prompt.MaxActivationDistance
        end
        prompt.MaxActivationDistance = originalRanges[prompt] * multiplier
    end
    
    for _, descendant in pairs(workspace:GetDescendants()) do
        if descendant:IsA("ProximityPrompt") then
            modifyPrompt(descendant)
        end
    end
    
    for _, player in pairs(game.Players:GetPlayers()) do
        if player.PlayerGui then
            for _, descendant in pairs(player.PlayerGui:GetDescendants()) do
                if descendant:IsA("ProximityPrompt") then
                    modifyPrompt(descendant)
                end
            end
        end
    end
end

-- Function to setup connections for new proximity prompts
local function setupRangeConnections(multiplier)
    -- Clear existing connections
    for _, connection in pairs(rangeConnections) do
        connection:Disconnect()
    end
    rangeConnections = {}
    
    -- Connect to workspace descendants
    table.insert(rangeConnections, workspace.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("ProximityPrompt") then
            task.wait(0.1) -- Small delay to ensure properties are set
            originalRanges[descendant] = descendant.MaxActivationDistance
            descendant.MaxActivationDistance = originalRanges[descendant] * multiplier
        end
    end))
    
    -- Connect to player GUIs
    for _, player in pairs(game.Players:GetPlayers()) do
        if player.PlayerGui then
            table.insert(rangeConnections, player.PlayerGui.DescendantAdded:Connect(function(descendant)
                if descendant:IsA("ProximityPrompt") then
                    task.wait(0.1)
                    originalRanges[descendant] = descendant.MaxActivationDistance
                    descendant.MaxActivationDistance = originalRanges[descendant] * multiplier
                end
            end))
        end
    end
end

VisualEffects:AddSlider("RangeBoost", {
    Text = "Interaction Boost",
    Default = 1,
    Min = 1,
    Max = 5,
    Rounding = 1,
    Compact = true,
    Callback = function(multiplier)
        if multiplier == 1 then
            -- Reset all proximity prompts to original values
            for prompt, originalRange in pairs(originalRanges) do
                if prompt and prompt.Parent then
                    prompt.MaxActivationDistance = originalRange
                end
            end
            
            -- Clear connections
            for _, connection in pairs(rangeConnections) do
                connection:Disconnect()
            end
            rangeConnections = {}
            
            Library:Notify("Interaction range reset to normal", 2)
        else
            -- Update all proximity prompt ranges
            updateProximityPromptRanges(multiplier)
            
            -- Setup connections for new prompts
            setupRangeConnections(multiplier)
            
            Library:Notify("Interaction range boosted by " .. multiplier .. "x", 2)
        end
    end
})




















































local VisualsGroupZ = Tabs.Visuals:AddRightGroupbox("Entity ESP")

VisualsGroupZ:AddToggle("FigureESP", {
    Text = "Figure ESP",
    Default = false,
    Tooltip = "shows the figure through walls",
    Callback = function(Value)
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")

        local AllowedFigureModels = {
            ["FigureRig"] = true  
        }

        local function addESP(model)
            if not AllowedFigureModels[model.Name] then return end
            if not model.PrimaryPart then return end 

            
            if not model:FindFirstChild("FigureESP_Highlight") then
                local hl = Instance.new("Highlight")
                hl.Name = "FigureESP_Highlight"
                hl.FillColor = Options.FigureESP_Color.Value
                hl.FillTransparency = 0.6
                hl.OutlineTransparency = 0
                hl.Parent = model
                hl.Adornee = model
            end

            
            if not model:FindFirstChild("FigureESP_Billboard") then
                local bb = Instance.new("BillboardGui")
                bb.Name = "FigureESP_Billboard"
                bb.AlwaysOnTop = true
                bb.Size = UDim2.new(0,100,0,30)
                bb.StudsOffset = Vector3.new(0, 3, 0)
                bb.Adornee = model
                bb.Parent = model

                local lbl = Instance.new("TextLabel")
                lbl.Name = "FigureESP_Label"
                lbl.Size = UDim2.new(1,0,1,0)
                lbl.BackgroundTransparency = 1
                lbl.TextColor3 = Color3.new(1,0,0)  
                lbl.TextScaled = true
                lbl.Font = Enum.Font.Gotham
                lbl.Text = "Figure"
                lbl.TextStrokeTransparency = 0
                lbl.TextStrokeColor3 = Color3.new(0,0,0)
                lbl.TextXAlignment = Enum.TextXAlignment.Center
                lbl.TextYAlignment = Enum.TextYAlignment.Center
                lbl.Parent = bb
            end

            
            if not table.find(_G.FigureESP_Objects, model) then
                table.insert(_G.FigureESP_Objects, model)
            end
        end

        if Value then
            _G.FigureESP_Objects = {}

            for _,v in pairs(workspace:GetDescendants()) do
                if v:IsA("Model") then
                    addESP(v)
                end
            end

            if not _G.FigureESP_Add then
                _G.FigureESP_Add = workspace.DescendantAdded:Connect(function(v)
                    if v:IsA("Model") then
                        addESP(v)
                    end
                end)
            end

            if not _G.FigureESP_Update then
                _G.FigureESP_Update = RunService.RenderStepped:Connect(function()
                    local plrRoot = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not plrRoot then return end

                    for i = #_G.FigureESP_Objects, 1, -1 do
                        local model = _G.FigureESP_Objects[i]
                        if model and model.Parent and model:IsA("Model") and AllowedFigureModels[model.Name] and model.PrimaryPart then
                            local hl = model:FindFirstChild("FigureESP_Highlight")
                            local bb = model:FindFirstChild("FigureESP_Billboard")
                            if hl and bb then
                                local dist = (plrRoot.Position - model.PrimaryPart.Position).Magnitude
                                local lbl = bb:FindFirstChild("FigureESP_Label")
                                if lbl then
                                    lbl.Text = "Figure\n"..math.floor(dist).." studs"
                                end
                                hl.FillColor = Options.FigureESP_Color.Value
                            end
                        else
                            table.remove(_G.FigureESP_Objects, i)
                        end
                    end
                end)
            end
        else
            if _G.FigureESP_Add then _G.FigureESP_Add:Disconnect() _G.FigureESP_Add=nil end
            if _G.FigureESP_Update then _G.FigureESP_Update:Disconnect() _G.FigureESP_Update=nil end
            for _, model in pairs(_G.FigureESP_Objects or {}) do
                if model then
                    if model:FindFirstChild("FigureESP_Highlight") then model.FigureESP_Highlight:Destroy() end
                    if model:FindFirstChild("FigureESP_Billboard") then model.FigureESP_Billboard:Destroy() end
                end
            end
            _G.FigureESP_Objects = nil
        end
    end
}):AddColorPicker("FigureESP_Color", { Default = Color3.fromRGB(255, 255, 255), Title = "Figure Color" })


VisualsGroupZ:AddToggle("AmbushESP", {
    Text = "Ambush ESP",
    Default = false,
    Tooltip = "shows Ambush through walls",
    Callback = function(Value)
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")

        local function addESP(model)
            if model.Name ~= "AmbushMoving" then return end

            local rushPart = model:FindFirstChild("RushNew")
            if rushPart and rushPart:IsA("BasePart") then
                
                local entry = {obj = rushPart}
                if not _G.AmbushESP_Trans[rushPart] then
                    _G.AmbushESP_Trans[rushPart] = rushPart.Transparency
                end
                entry.originalTrans = _G.AmbushESP_Trans[rushPart]

                
                rushPart.Transparency = 0

                
                if not rushPart:FindFirstChild("RushESP_Highlight") then
                    local hl = Instance.new("Highlight")
                    hl.Name = "RushESP_Highlight"
                    hl.FillColor = Color3.fromRGB(255, 255, 255)  
                    hl.FillTransparency = 0.6
                    hl.OutlineTransparency = 0
                    hl.Parent = rushPart
                    hl.Adornee = rushPart
                end

                
                if not rushPart:FindFirstChild("RushESP_Billboard") then
                    local bb = Instance.new("BillboardGui")
                    bb.Name = "RushESP_Billboard"
                    bb.AlwaysOnTop = true
                    bb.Size = UDim2.new(0, 100, 0, 30)
                    bb.StudsOffset = Vector3.new(0, 3, 0)
                    bb.Adornee = rushPart
                    bb.Parent = rushPart

                    local lbl = Instance.new("TextLabel")
                    lbl.Name = "RushESP_Label"
                    lbl.Size = UDim2.new(1, 0, 1, 0)
                    lbl.BackgroundTransparency = 1
                    lbl.TextColor3 = Color3.new(1, 0, 0)  
                    lbl.TextScaled = true
                    lbl.Font = Enum.Font.Gotham
                    lbl.Text = "Ambush"
                    lbl.TextStrokeTransparency = 0
                    lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
                    lbl.TextXAlignment = Enum.TextXAlignment.Center
                    lbl.TextYAlignment = Enum.TextYAlignment.Center
                    lbl.Parent = bb
                end

                
                table.insert(_G.AmbushESP_Objects, entry)
            end
        end

        if Value then
            _G.AmbushESP_Objects = {}
            _G.AmbushESP_Trans = {}

            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("Model") then
                    addESP(v)
                end
            end

            if not _G.AmbushESP_Add then
                _G.AmbushESP_Add = workspace.DescendantAdded:Connect(function(v)
                    if v:IsA("Model") then
                        addESP(v)
                    end
                end)
            end

            if not _G.AmbushESP_Update then
                _G.AmbushESP_Update = RunService.RenderStepped:Connect(function()
                    local plrRoot = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not plrRoot then return end

                    for i = #_G.AmbushESP_Objects, 1, -1 do
                        local entry = _G.AmbushESP_Objects[i]
                        local rushPart = entry.obj
                        if rushPart and rushPart.Parent and rushPart:IsA("BasePart") and rushPart.Parent.Name == "AmbushMoving" then
                            local hl = rushPart:FindFirstChild("RushESP_Highlight")
                            local bb = rushPart:FindFirstChild("RushESP_Billboard")
                            if hl and bb then
                                local dist = (plrRoot.Position - rushPart.Position).Magnitude
                                local lbl = bb:FindFirstChild("RushESP_Label")
                                if lbl then
                                    lbl.Text = "Ambush\n" .. math.floor(dist) .. " studs"
                                end
                                hl.FillColor = Color3.fromRGB(255, 255, 0)  
                            end
                        else
                            table.remove(_G.AmbushESP_Objects, i)
                        end
                    end
                end)
            end
        else
            if _G.AmbushESP_Add then _G.AmbushESP_Add:Disconnect() _G.AmbushESP_Add=nil end
            if _G.AmbushESP_Update then _G.AmbushESP_Update:Disconnect() _G.AmbushESP_Update=nil end
            for _, entry in pairs(_G.AmbushESP_Objects or {}) do
                local rushPart = entry.obj
                if rushPart then
                    rushPart.Transparency = entry.originalTrans
                    if rushPart:FindFirstChild("RushESP_Highlight") then
                        rushPart.RushESP_Highlight:Destroy()
                    end
                    if rushPart:FindFirstChild("RushESP_Billboard") then
                        rushPart.RushESP_Billboard:Destroy()
                    end
                end
            end
            _G.AmbushESP_Objects = nil
            _G.AmbushESP_Trans = nil
        end
    end
}):AddColorPicker("RushESP_Color", { Default = Color3.fromRGB(255, 255, 255), Title = "Rush Color" })


VisualsGroupZ:AddToggle("RushESP", { Text = "Rush ESP", Default = false, Tooltip = "shows Rush through walls", Callback = function(Value) local Players = game:GetService("Players") local RunService = game:GetService("RunService") local function addESP(model) if model.Name ~= "RushMoving" then return end local rushPart = model:FindFirstChild("RushNew") if rushPart and rushPart:IsA("BasePart") then local entry = {obj = rushPart} if not _G.RushESP_Trans[rushPart] then _G.RushESP_Trans[rushPart] = rushPart.Transparency end entry.originalTrans = _G.RushESP_Trans[rushPart] rushPart.Transparency = 0 if not rushPart:FindFirstChild("RushESP_Highlight") then local hl = Instance.new("Highlight") hl.Name = "RushESP_Highlight" hl.FillColor = Color3.fromRGB(255, 0, 0) hl.FillTransparency = 0.6 hl.OutlineTransparency = 0 hl.Parent = rushPart hl.Adornee = rushPart end if not rushPart:FindFirstChild("RushESP_Billboard") then local bb = Instance.new("BillboardGui") bb.Name = "RushESP_Billboard" bb.AlwaysOnTop = true bb.Size = UDim2.new(0, 100, 0, 30) bb.StudsOffset = Vector3.new(0, 3, 0) bb.Adornee = rushPart bb.Parent = rushPart local lbl = Instance.new("TextLabel") lbl.Name = "RushESP_Label" lbl.Size = UDim2.new(1, 0, 1, 0) lbl.BackgroundTransparency = 1 lbl.TextColor3 = Color3.new(1, 0, 0) lbl.TextScaled = true lbl.Font = Enum.Font.Gotham lbl.Text = "Rush" lbl.TextStrokeTransparency = 0 lbl.TextStrokeColor3 = Color3.new(0, 0, 0) lbl.TextXAlignment = Enum.TextXAlignment.Center lbl.TextYAlignment = Enum.TextYAlignment.Center lbl.Parent = bb end table.insert(_G.RushESP_Objects, entry) end end if Value then _G.RushESP_Objects = {} _G.RushESP_Trans = {} for _, v in pairs(workspace:GetDescendants()) do if v:IsA("Model") then addESP(v) end end if not _G.RushESP_Add then _G.RushESP_Add = workspace.DescendantAdded:Connect(function(v) if v:IsA("Model") then addESP(v) end end) end if not _G.RushESP_Update then _G.RushESP_Update = RunService.RenderStepped:Connect(function() local plrRoot = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") if not plrRoot then return end for i = #_G.RushESP_Objects, 1, -1 do local entry = _G.RushESP_Objects[i] local rushPart = entry.obj if rushPart and rushPart.Parent and rushPart:IsA("BasePart") and rushPart.Parent.Name == "RushMoving" then local hl = rushPart:FindFirstChild("RushESP_Highlight") local bb = rushPart:FindFirstChild("RushESP_Billboard") if hl and bb then local dist = (plrRoot.Position - rushPart.Position).Magnitude local lbl = bb:FindFirstChild("RushESP_Label") if lbl then lbl.Text = "Rush\n" .. math.floor(dist) .. " studs" end hl.FillColor = Color3.fromRGB(255, 0, 0) end else table.remove(_G.RushESP_Objects, i) end end end) end else if _G.RushESP_Add then _G.RushESP_Add:Disconnect() _G.RushESP_Add=nil end if _G.RushESP_Update then _G.RushESP_Update:Disconnect() _G.RushESP_Update=nil end for _, entry in pairs(_G.RushESP_Objects or {}) do local rushPart = entry.obj if rushPart then rushPart.Transparency = entry.originalTrans if rushPart:FindFirstChild("RushESP_Highlight") then rushPart.RushESP_Highlight:Destroy() end if rushPart:FindFirstChild("RushESP_Billboard") then rushPart.RushESP_Billboard:Destroy() end end end _G.RushESP_Objects = nil _G.RushESP_Trans = nil end end }):AddColorPicker("RushESP_Color", { Default = Color3.fromRGB(255, 255, 255), Title = "Rush Color" })

VisualsGroupZ:AddToggle("SnareESP", { 
    Text = "Snare ESP",
    Default = false,
    Tooltip = "Shows Snare through walls",
    Callback = function(Value)
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")

        local function addESP(model)
            if model.Name ~= "Snare" then return end
            if not model.PrimaryPart then return end  

            
            if not model:FindFirstChild("SnareESP_Highlight") then
                local hl = Instance.new("Highlight")
                hl.Name = "SnareESP_Highlight"
                hl.FillColor = Options.SnareESP_Color.Value  
                hl.FillTransparency = 0.6
                hl.OutlineTransparency = 0
                hl.Parent = model
                hl.Adornee = model
            end

            
            if not model:FindFirstChild("SnareESP_Billboard") then
                local bb = Instance.new("BillboardGui")
                bb.Name = "SnareESP_Billboard"
                bb.AlwaysOnTop = true
                bb.Size = UDim2.new(0, 100, 0, 30)
                bb.StudsOffset = Vector3.new(0, 3, 0)
                bb.Adornee = model
                bb.Parent = model

                local lbl = Instance.new("TextLabel")
                lbl.Name = "SnareESP_Label"
                lbl.Size = UDim2.new(1, 0, 1, 0)
                lbl.BackgroundTransparency = 1
                lbl.TextColor3 = Options.SnareESP_Color.Value  
                lbl.TextScaled = true
                lbl.Font = Enum.Font.Gotham
                lbl.Text = "Snare"
                lbl.TextStrokeTransparency = 0
                lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
                lbl.TextXAlignment = Enum.TextXAlignment.Center
                lbl.TextYAlignment = Enum.TextYAlignment.Center
                lbl.Parent = bb
            end

            
            if not table.find(_G.SnareESP_Objects, model) then
                table.insert(_G.SnareESP_Objects, model)
            end
        end

        if Value then
            _G.SnareESP_Objects = {}

            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("Model") then
                    addESP(v)
                end
            end

            if not _G.SnareESP_Add then
                _G.SnareESP_Add = workspace.DescendantAdded:Connect(function(v)
                    if v:IsA("Model") then
                        addESP(v)
                    end
                end)
            end

            if not _G.SnareESP_Update then
                _G.SnareESP_Update = RunService.RenderStepped:Connect(function()
                    local plrRoot = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not plrRoot then return end

                    for i = #_G.SnareESP_Objects, 1, -1 do
                        local model = _G.SnareESP_Objects[i]
                        if model and model.Parent and model.Name == "Snare" and model.PrimaryPart then
                            local hl = model:FindFirstChild("SnareESP_Highlight")
                            local bb = model:FindFirstChild("SnareESP_Billboard")
                            if hl and bb then
                                local dist = (plrRoot.Position - model.PrimaryPart.Position).Magnitude
                                local lbl = bb:FindFirstChild("SnareESP_Label")
                                if lbl then
                                    lbl.Text = "Snare\n" .. math.floor(dist) .. " studs"
                                end
                                hl.FillColor = Options.SnareESP_Color.Value  
                            end
                        else
                            table.remove(_G.SnareESP_Objects, i)
                        end
                    end
                end)
            end
        else
            if _G.SnareESP_Add then _G.SnareESP_Add:Disconnect() _G.SnareESP_Add = nil end
            if _G.SnareESP_Update then _G.SnareESP_Update:Disconnect() _G.SnareESP_Update = nil end
            for _, model in pairs(_G.SnareESP_Objects or {}) do
                if model then
                    if model:FindFirstChild("SnareESP_Highlight") then
                        model.SnareESP_Highlight:Destroy()
                    end
                    if model:FindFirstChild("SnareESP_Billboard") then
                        model.SnareESP_Billboard:Destroy()
                    end
                end
            end
            _G.SnareESP_Objects = nil
        end
    end
}):AddColorPicker("SnareESP_Color", { Default = Color3.fromRGB(255, 255, 255), Title = "Snare Color" })

VisualsGroupZ:AddDivider()

VisualsGroupZ:AddToggle("GiggleESP", {
    Text = "Giggle ESP",
    Default = false,
    Tooltip = "Shows Giggle through walls",
    Callback = function(Value)
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")

        local function addESP(model)
            if model.Name ~= "GiggleCeiling" then return end

            
            if not model:FindFirstChild("GiggleESP_Highlight") then
                local hl = Instance.new("Highlight")
                hl.Name = "GiggleESP_Highlight"
                hl.FillColor = Color3.fromRGB(255, 255, 0)  
                hl.FillTransparency = 0.6
                hl.OutlineTransparency = 0
                hl.Parent = model
                hl.Adornee = model
            end

            
            if not model:FindFirstChild("GiggleESP_Billboard") then
                local bb = Instance.new("BillboardGui")
                bb.Name = "GiggleESP_Billboard"
                bb.AlwaysOnTop = true
                bb.Size = UDim2.new(0, 100, 0, 30)
                bb.StudsOffset = Vector3.new(0, 3, 0)
                bb.Adornee = model
                bb.Parent = model

                local lbl = Instance.new("TextLabel")
                lbl.Name = "GiggleESP_Label"
                lbl.Size = UDim2.new(1, 0, 1, 0)
                lbl.BackgroundTransparency = 1
                lbl.TextColor3 = Color3.new(1, 1, 0)  
                lbl.TextScaled = true
                lbl.Font = Enum.Font.Gotham
                lbl.Text = "Giggle"
                lbl.TextStrokeTransparency = 0
                lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
                lbl.TextXAlignment = Enum.TextXAlignment.Center
                lbl.TextYAlignment = Enum.TextYAlignment.Center
                lbl.Parent = bb
            end

            
            if not table.find(_G.GiggleESP_Objects, model) then
                table.insert(_G.GiggleESP_Objects, model)
            end
        end

        if Value then
            _G.GiggleESP_Objects = {}

            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("Model") then
                    addESP(v)
                end
            end

            if not _G.GiggleESP_Add then
                _G.GiggleESP_Add = workspace.DescendantAdded:Connect(function(v)
                    if v:IsA("Model") then
                        addESP(v)
                    end
                end)
            end

            if not _G.GiggleESP_Update then
                _G.GiggleESP_Update = RunService.RenderStepped:Connect(function()
                    local plrRoot = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not plrRoot then return end

                    for i = #_G.GiggleESP_Objects, 1, -1 do
                        local model = _G.GiggleESP_Objects[i]
                        if model and model.Parent and model.Name == "Giggle" and model.PrimaryPart then
                            local hl = model:FindFirstChild("GiggleESP_Highlight")
                            local bb = model:FindFirstChild("GiggleESP_Billboard")
                            if hl and bb then
                                local dist = (plrRoot.Position - model.PrimaryPart.Position).Magnitude
                                local lbl = bb:FindFirstChild("GiggleESP_Label")
                                if lbl then
                                    lbl.Text = "Giggle\n" .. math.floor(dist) .. " studs"
                                end
                                hl.FillColor = Color3.fromRGB(255, 255, 0)  
                            end
                        else
                            table.remove(_G.GiggleESP_Objects, i)
                        end
                    end
                end)
            end
        else
            if _G.GiggleESP_Add then _G.GiggleESP_Add:Disconnect() _G.GiggleESP_Add=nil end
            if _G.GiggleESP_Update then _G.GiggleESP_Update:Disconnect() _G.GiggleESP_Update=nil end
            for _, model in pairs(_G.GiggleESP_Objects or {}) do
                if model then
                    if model:FindFirstChild("GiggleESP_Highlight") then
                        model.GiggleESP_Highlight:Destroy()
                    end
                    if model:FindFirstChild("GiggleESP_Billboard") then
                        model.GiggleESP_Billboard:Destroy()
                    end
                end
            end
            _G.GiggleESP_Objects = nil
        end
    end
}):AddColorPicker("GiggleESP_Color", { Default = Color3.fromRGB(255, 255, 255), Title = "Giggle Color" })

VisualsGroupZ:AddToggle("GuidingLightESP", {
    Text = "Guiding Light ESP",
    Default = false,
    Tooltip = "Shows Guiding Light through walls",
    Callback = function(Value)
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")

        local function addESP(obj)
            if not obj:IsA("BasePart") or obj.Name ~= "HelpfulLight" then return end

            obj.Transparency = 0
            obj.Material = Enum.Material.Plastic

            if not obj:FindFirstChild("GuidingLightESP_Highlight") then
                local hl = Instance.new("Highlight")
                hl.Name = "GuidingLightESP_Highlight"
                hl.FillColor = Color3.fromRGB(0, 0, 255)
                hl.FillTransparency = 0.6
                hl.OutlineTransparency = 0
                hl.Parent = obj
                hl.Adornee = obj
            end

            if not obj:FindFirstChild("GuidingLightESP_Billboard") then
                local bb = Instance.new("BillboardGui")
                bb.Name = "GuidingLightESP_Billboard"
                bb.AlwaysOnTop = true
                bb.Size = UDim2.new(0, 100, 0, 30)
                bb.StudsOffset = Vector3.new(0, 0, 0)
                bb.Adornee = obj
                bb.Parent = obj

                local lbl = Instance.new("TextLabel")
                lbl.Name = "GuidingLightESP_Label"
                lbl.Size = UDim2.new(1, 0, 1, 0)
                lbl.BackgroundTransparency = 1
                lbl.TextColor3 = Color3.new(0, 0, 1)
                lbl.TextScaled = true
                lbl.Font = Enum.Font.Gotham
                lbl.Text = "Guiding Light"
                lbl.TextStrokeTransparency = 0
                lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
                lbl.TextXAlignment = Enum.TextXAlignment.Center
                lbl.TextYAlignment = Enum.TextYAlignment.Center
                lbl.Parent = bb
            end

            if not table.find(_G.GuidingLightESP_Objects, obj) then
                table.insert(_G.GuidingLightESP_Objects, obj)
            end
        end

        if Value then
            _G.GuidingLightESP_Objects = {}

            for _, v in pairs(workspace:GetDescendants()) do
                addESP(v)
            end

            if not _G.GuidingLightESP_Add then
                _G.GuidingLightESP_Add = workspace.DescendantAdded:Connect(function(v)
                    addESP(v)
                end)
            end

            if not _G.GuidingLightESP_Update then
                _G.GuidingLightESP_Update = RunService.RenderStepped:Connect(function()
                    local plrRoot = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not plrRoot then return end

                    for i = #_G.GuidingLightESP_Objects, 1, -1 do
                        local obj = _G.GuidingLightESP_Objects[i]
                        if obj and obj.Parent and obj.Name == "HelpfulLight" then
                            local hl = obj:FindFirstChild("GuidingLightESP_Highlight")
                            local bb = obj:FindFirstChild("GuidingLightESP_Billboard")
                            if hl and bb then
                                local dist = (plrRoot.Position - obj.Position).Magnitude
                                local lbl = bb:FindFirstChild("GuidingLightESP_Label")
                                if lbl then
                                    lbl.Text = "Guiding Light\n" .. math.floor(dist) .. " studs"
                                end
                                hl.FillColor = Color3.fromRGB(0, 0, 255)
                            end
                        else
                            table.remove(_G.GuidingLightESP_Objects, i)
                        end
                    end
                end)
            end
        else
            if _G.GuidingLightESP_Add then _G.GuidingLightESP_Add:Disconnect() _G.GuidingLightESP_Add=nil end
            if _G.GuidingLightESP_Update then _G.GuidingLightESP_Update:Disconnect() _G.GuidingLightESP_Update=nil end
            for _, obj in pairs(_G.GuidingLightESP_Objects or {}) do
                if obj then
                    if obj:FindFirstChild("GuidingLightESP_Highlight") then
                        obj.GuidingLightESP_Highlight:Destroy()
                    end
                    if obj:FindFirstChild("GuidingLightESP_Billboard") then
                        obj.GuidingLightESP_Billboard:Destroy()
                    end
                end
            end
            _G.GuidingLightESP_Objects = nil
        end
    end
}):AddColorPicker("GuidingLightESP_Color", { Default = Color3.fromRGB(255, 255, 255), Title = "Guiding Light Color" })



VisualsGroupZ:AddDivider()



VisualsGroupZ:AddToggle("EyestalkESP", {
    Text = "Eyestalk ESP",
    Default = false,
    Tooltip = "shows Eyestalk through walls",
    Callback = function(Value)
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")

        local function addESP(model)
            if model.Name ~= "EyestalkMoving" then return end

            local entry = {obj = model}
            if not _G.EyestalkESP_Trans[model] then
                _G.EyestalkESP_Trans[model] = {}
                for _, part in ipairs(model:GetDescendants()) do
                    if part:IsA("BasePart") then
                        _G.EyestalkESP_Trans[model][part] = part.Transparency
                        part.Transparency = 0
                    end
                end
            end
            entry.originalTrans = _G.EyestalkESP_Trans[model]

            -- Highlight entire model
            if not model:FindFirstChild("EyestalkESP_Highlight") then
                local hl = Instance.new("Highlight")
                hl.Name = "EyestalkESP_Highlight"
                hl.FillColor = Color3.fromRGB(255, 0, 0)  
                hl.FillTransparency = 0.6
                hl.OutlineTransparency = 0
                hl.Parent = model
                hl.Adornee = model
            end

            -- Billboard above model
            if not model:FindFirstChild("EyestalkESP_Billboard") then
                local bb = Instance.new("BillboardGui")
                bb.Name = "EyestalkESP_Billboard"
                bb.AlwaysOnTop = true
                bb.Size = UDim2.new(0, 100, 0, 30)
                bb.StudsOffset = Vector3.new(0, 5, 0)
                bb.Adornee = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
                bb.Parent = model

                local lbl = Instance.new("TextLabel")
                lbl.Name = "EyestalkESP_Label"
                lbl.Size = UDim2.new(1, 0, 1, 0)
                lbl.BackgroundTransparency = 1
                lbl.TextColor3 = Color3.new(1, 0, 0)  
                lbl.TextScaled = true
                lbl.Font = Enum.Font.Gotham
                lbl.Text = "Eyestalk"
                lbl.TextStrokeTransparency = 0
                lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
                lbl.TextXAlignment = Enum.TextXAlignment.Center
                lbl.TextYAlignment = Enum.TextYAlignment.Center
                lbl.Parent = bb
            end

            table.insert(_G.EyestalkESP_Objects, entry)
        end

        if Value then
            _G.EyestalkESP_Objects = {}
            _G.EyestalkESP_Trans = {}

            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("Model") then
                    addESP(v)
                end
            end

            if not _G.EyestalkESP_Add then
                _G.EyestalkESP_Add = workspace.DescendantAdded:Connect(function(v)
                    if v:IsA("Model") then
                        addESP(v)
                    end
                end)
            end

            if not _G.EyestalkESP_Update then
                _G.EyestalkESP_Update = RunService.RenderStepped:Connect(function()
                    local plrRoot = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not plrRoot then return end

                    for i = #_G.EyestalkESP_Objects, 1, -1 do
                        local entry = _G.EyestalkESP_Objects[i]
                        local model = entry.obj
                        if model and model.Parent and model:IsA("Model") and model.Name == "EyestalkMoving" then
                            local hl = model:FindFirstChild("EyestalkESP_Highlight")
                            local bb = model:FindFirstChild("EyestalkESP_Billboard")
                            if hl and bb then
                                local adornee = bb.Adornee
                                if adornee then
                                    local dist = (plrRoot.Position - adornee.Position).Magnitude
                                    local lbl = bb:FindFirstChild("EyestalkESP_Label")
                                    if lbl then
                                        lbl.Text = "Eyestalk\n" .. math.floor(dist) .. " studs"
                                    end
                                    hl.FillColor = Color3.fromRGB(255, 0, 0)  
                                end
                            end
                        else
                            table.remove(_G.EyestalkESP_Objects, i)
                        end
                    end
                end)
            end
        else
            if _G.EyestalkESP_Add then _G.EyestalkESP_Add:Disconnect() _G.EyestalkESP_Add=nil end
            if _G.EyestalkESP_Update then _G.EyestalkESP_Update:Disconnect() _G.EyestalkESP_Update=nil end
            for _, entry in pairs(_G.EyestalkESP_Objects or {}) do
                local model = entry.obj
                if model then
                    for part, trans in pairs(entry.originalTrans or {}) do
                        if part and part.Parent then
                            part.Transparency = trans
                        end
                    end
                    if model:FindFirstChild("EyestalkESP_Highlight") then
                        model.EyestalkESP_Highlight:Destroy()
                    end
                    if model:FindFirstChild("EyestalkESP_Billboard") then
                        model.EyestalkESP_Billboard:Destroy()
                    end
                end
            end
            _G.EyestalkESP_Objects = nil
            _G.EyestalkESP_Trans = nil
        end
    end
}):AddColorPicker("EyestalkESP_Color", { Default = Color3.fromRGB(255, 255, 255), Title = "Eyestalk Color" })



VisualsGroupZ:AddToggle("MandrakeESP", { 
    Text = "Mandrake ESP",
    Default = false,
    Tooltip = "Shows Mandrake through walls",
    Callback = function(Value)
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")

        local function addESP(model)
            if model.Name ~= "Mandrake" then return end
            if not model.PrimaryPart then return end  

            
            if not model:FindFirstChild("MandrakeESP_Highlight") then
                local hl = Instance.new("Highlight")
                hl.Name = "MandrakeESP_Highlight"
                hl.FillColor = Options.MandrakeESP_Color.Value  
                hl.FillTransparency = 0.6
                hl.OutlineTransparency = 0
                hl.Parent = model
                hl.Adornee = model
            end

            
            if not model:FindFirstChild("MandrakeESP_Billboard") then
                local bb = Instance.new("BillboardGui")
                bb.Name = "MandrakeESP_Billboard"
                bb.AlwaysOnTop = true
                bb.Size = UDim2.new(0, 100, 0, 30)
                bb.StudsOffset = Vector3.new(0, 3, 0)
                bb.Adornee = model
                bb.Parent = model

                local lbl = Instance.new("TextLabel")
                lbl.Name = "MandrakeESP_Label"
                lbl.Size = UDim2.new(1, 0, 1, 0)
                lbl.BackgroundTransparency = 1
                lbl.TextColor3 = Options.MandrakeESP_Color.Value  
                lbl.TextScaled = true
                lbl.Font = Enum.Font.Gotham
                lbl.Text = "Mandrake"
                lbl.TextStrokeTransparency = 0
                lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
                lbl.TextXAlignment = Enum.TextXAlignment.Center
                lbl.TextYAlignment = Enum.TextYAlignment.Center
                lbl.Parent = bb
            end

            
            if not table.find(_G.MandrakeESP_Objects, model) then
                table.insert(_G.MandrakeESP_Objects, model)
            end
        end

        if Value then
            _G.MandrakeESP_Objects = {}

            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("Model") then
                    addESP(v)
                end
            end

            if not _G.MandrakeESP_Add then
                _G.MandrakeESP_Add = workspace.DescendantAdded:Connect(function(v)
                    if v:IsA("Model") then
                        addESP(v)
                    end
                end)
            end

            if not _G.MandrakeESP_Update then
                _G.MandrakeESP_Update = RunService.RenderStepped:Connect(function()
                    local plrRoot = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not plrRoot then return end

                    for i = #_G.MandrakeESP_Objects, 1, -1 do
                        local model = _G.MandrakeESP_Objects[i]
                        if model and model.Parent and model.Name == "Mandrake" and model.PrimaryPart then
                            local hl = model:FindFirstChild("MandrakeESP_Highlight")
                            local bb = model:FindFirstChild("MandrakeESP_Billboard")
                            if hl and bb then
                                local dist = (plrRoot.Position - model.PrimaryPart.Position).Magnitude
                                local lbl = bb:FindFirstChild("MandrakeESP_Label")
                                if lbl then
                                    lbl.Text = "Mandrake\n" .. math.floor(dist) .. " studs"
                                end
                                hl.FillColor = Options.MandrakeESP_Color.Value  
                            end
                        else
                            table.remove(_G.MandrakeESP_Objects, i)
                        end
                    end
                end)
            end
        else
            if _G.MandrakeESP_Add then _G.MandrakeESP_Add:Disconnect() _G.MandrakeESP_Add = nil end
            if _G.MandrakeESP_Update then _G.MandrakeESP_Update:Disconnect() _G.MandrakeESP_Update = nil end
            for _, model in pairs(_G.MandrakeESP_Objects or {}) do
                if model then
                    if model:FindFirstChild("MandrakeESP_Highlight") then
                        model.MandrakeESP_Highlight:Destroy()
                    end
                    if model:FindFirstChild("MandrakeESP_Billboard") then
                        model.MandrakeESP_Billboard:Destroy()
                    end
                end
            end
            _G.MandrakeESP_Objects = nil
        end
    end
}):AddColorPicker("MandrakeESP_Color", { Default = Color3.fromRGB(255, 255, 255), Title = "Mandrake Color" })

VisualsGroupZ:AddToggle("GroundskeeperESP", {
    Text = "Groundskeeper ESP",
    Default = false,
    Tooltip = "Shows Groundskeeper through walls",
    Callback = function(Value)
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")

        local function addESP(model)
            if model.Name ~= "Groundskeeper" then return end

            
            if not model:FindFirstChild("GroundskeeperESP_Highlight") then
                local hl = Instance.new("Highlight")
                hl.Name = "GroundskeeperESP_Highlight"
                hl.FillColor = Color3.fromRGB(0, 255, 0)  
                hl.FillTransparency = 0.6
                hl.OutlineTransparency = 0
                hl.Parent = model
                hl.Adornee = model
            end

            
            if not model:FindFirstChild("GroundskeeperESP_Billboard") then
                local bb = Instance.new("BillboardGui")
                bb.Name = "GroundskeeperESP_Billboard"
                bb.AlwaysOnTop = true
                bb.Size = UDim2.new(0, 100, 0, 30)
                bb.StudsOffset = Vector3.new(0, 3, 0)
                bb.Adornee = model
                bb.Parent = model

                local lbl = Instance.new("TextLabel")
                lbl.Name = "GroundskeeperESP_Label"
                lbl.Size = UDim2.new(1, 0, 1, 0)
                lbl.BackgroundTransparency = 1
                lbl.TextColor3 = Color3.new(0, 1, 0)  
                lbl.TextScaled = true
                lbl.Font = Enum.Font.Gotham
                lbl.Text = "Groundskeeper"
                lbl.TextStrokeTransparency = 0
                lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
                lbl.TextXAlignment = Enum.TextXAlignment.Center
                lbl.TextYAlignment = Enum.TextYAlignment.Center
                lbl.Parent = bb
            end

            
            if not table.find(_G.GroundskeeperESP_Objects, model) then
                table.insert(_G.GroundskeeperESP_Objects, model)
            end
        end

        if Value then
            _G.GroundskeeperESP_Objects = {}

            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("Model") then
                    addESP(v)
                end
            end

            if not _G.GroundskeeperESP_Add then
                _G.GroundskeeperESP_Add = workspace.DescendantAdded:Connect(function(v)
                    if v:IsA("Model") then
                        addESP(v)
                    end
                end)
            end

            if not _G.GroundskeeperESP_Update then
                _G.GroundskeeperESP_Update = RunService.RenderStepped:Connect(function()
                    local plrRoot = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not plrRoot then return end

                    for i = #_G.GroundskeeperESP_Objects, 1, -1 do
                        local model = _G.GroundskeeperESP_Objects[i]
                        if model and model.Parent and model.Name == "Groundskeeper" and model.PrimaryPart then
                            local hl = model:FindFirstChild("GroundskeeperESP_Highlight")
                            local bb = model:FindFirstChild("GroundskeeperESP_Billboard")
                            if hl and bb then
                                local dist = (plrRoot.Position - model.PrimaryPart.Position).Magnitude
                                local lbl = bb:FindFirstChild("GroundskeeperESP_Label")
                                if lbl then
                                    lbl.Text = "Groundskeeper\n" .. math.floor(dist) .. " studs"
                                end
                                hl.FillColor = Color3.fromRGB(0, 255, 0)  
                            end
                        else
                            table.remove(_G.GroundskeeperESP_Objects, i)
                        end
                    end
                end)
            end
        else
            if _G.GroundskeeperESP_Add then _G.GroundskeeperESP_Add:Disconnect() _G.GroundskeeperESP_Add=nil end
            if _G.GroundskeeperESP_Update then _G.GroundskeeperESP_Update:Disconnect() _G.GroundskeeperESP_Update=nil end
            for _, model in pairs(_G.GroundskeeperESP_Objects or {}) do
                if model then
                    if model:FindFirstChild("GroundskeeperESP_Highlight") then
                        model.GroundskeeperESP_Highlight:Destroy()
                    end
                    if model:FindFirstChild("GroundskeeperESP_Billboard") then
                        model.GroundskeeperESP_Billboard:Destroy()
                    end
                end
            end
            _G.GroundskeeperESP_Objects = nil
        end
    end
}):AddColorPicker("GroundskeeperESP_Color", { Default = Color3.fromRGB(255, 255, 255), Title = "Groundskeeper Color" })

VisualsGroupZ:AddDivider()

VisualsGroupZ:AddToggle("BlitzESP", {
    Text = "Blitz ESP",
    Default = false,
    Tooltip = "shows Blitz through walls",
    Callback = function(Value)
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")

        local function addESP(model)
            if model.Name ~= "BackdoorRush" then return end 

            local blitzPart = model:FindFirstChild("Main")  
            if blitzPart and blitzPart:IsA("BasePart") then
                
                local entry = {obj = blitzPart}
                if not _G.BlitzESP_Trans[blitzPart] then
                    _G.BlitzESP_Trans[blitzPart] = blitzPart.Transparency
                end
                entry.originalTrans = _G.BlitzESP_Trans[blitzPart]

                blitzPart.Transparency = 0

                if not blitzPart:FindFirstChild("BlitzESP_Highlight") then
                    local hl = Instance.new("Highlight")
                    hl.Name = "BlitzESP_Highlight"
                    hl.FillColor = Color3.fromRGB(255, 0, 0)
                    hl.FillTransparency = 0.6
                    hl.OutlineTransparency = 0
                    hl.Parent = blitzPart
                    hl.Adornee = blitzPart
                end

                if not blitzPart:FindFirstChild("BlitzESP_Billboard") then
                    local bb = Instance.new("BillboardGui")
                    bb.Name = "BlitzESP_Billboard"
                    bb.AlwaysOnTop = true
                    bb.Size = UDim2.new(0, 100, 0, 30)
                    bb.StudsOffset = Vector3.new(0, 3, 0)
                    bb.Adornee = blitzPart
                    bb.Parent = blitzPart

                    local lbl = Instance.new("TextLabel")
                    lbl.Name = "BlitzESP_Label"
                    lbl.Size = UDim2.new(1, 0, 1, 0)
                    lbl.BackgroundTransparency = 1
                    lbl.TextColor3 = Color3.new(1, 0, 0)
                    lbl.TextScaled = true
                    lbl.Font = Enum.Font.Gotham
                    lbl.Text = "Blitz"
                    lbl.TextStrokeTransparency = 0
                    lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
                    lbl.TextXAlignment = Enum.TextXAlignment.Center
                    lbl.TextYAlignment = Enum.TextYAlignment.Center
                    lbl.Parent = bb
                end

                table.insert(_G.BlitzESP_Objects, entry)
            end
        end

        if Value then
            _G.BlitzESP_Objects = {}
            _G.BlitzESP_Trans = {}

            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("Model") then
                    addESP(v)
                end
            end

            if not _G.BlitzESP_Add then
                _G.BlitzESP_Add = workspace.DescendantAdded:Connect(function(v)
                    if v:IsA("Model") then
                        addESP(v)
                    end
                end)
            end

            if not _G.BlitzESP_Update then
                _G.BlitzESP_Update = RunService.RenderStepped:Connect(function()
                    local plrRoot = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not plrRoot then return end

                    for i = #_G.BlitzESP_Objects, 1, -1 do
                        local entry = _G.BlitzESP_Objects[i]
                        local blitzPart = entry.obj
                        if blitzPart and blitzPart.Parent and blitzPart:IsA("BasePart") and blitzPart.Parent.Name == "BackdoorRush" then
                            local hl = blitzPart:FindFirstChild("BlitzESP_Highlight")
                            local bb = blitzPart:FindFirstChild("BlitzESP_Billboard")
                            if hl and bb then
                                local dist = (plrRoot.Position - blitzPart.Position).Magnitude
                                local lbl = bb:FindFirstChild("BlitzESP_Label")
                                if lbl then
                                    lbl.Text = "Blitz\n" .. math.floor(dist) .. " studs"
                                end
                                hl.FillColor = Color3.fromRGB(255, 0, 0)
                            end
                        else
                            table.remove(_G.BlitzESP_Objects, i)
                        end
                    end
                end)
            end
        else
            if _G.BlitzESP_Add then _G.BlitzESP_Add:Disconnect() _G.BlitzESP_Add = nil end
            if _G.BlitzESP_Update then _G.BlitzESP_Update:Disconnect() _G.BlitzESP_Update = nil end
            for _, entry in pairs(_G.BlitzESP_Objects or {}) do
                local blitzPart = entry.obj
                if blitzPart then
                    blitzPart.Transparency = entry.originalTrans
                    if blitzPart:FindFirstChild("BlitzESP_Highlight") then
                        blitzPart.BlitzESP_Highlight:Destroy()
                    end
                    if blitzPart:FindFirstChild("BlitzESP_Billboard") then
                        blitzPart.BlitzESP_Billboard:Destroy()
                    end
                end
            end
            _G.BlitzESP_Objects = nil
            _G.BlitzESP_Trans = nil
        end
    end
}):AddColorPicker("BlitzESP_Color", { Default = Color3.fromRGB(255, 255, 255), Title = "Blitz Color" })



























local VisualsGroup = Tabs.Visuals:AddLeftGroupbox("Object ESP")

VisualsGroup:AddToggle("DoorESP", {
    Text = "Door ESP",
    Default = false,
    Tooltip = "shows doors through walls",
    Callback = function(Value)
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")

        
        local AllowedDoorModels = {
            ["Door"] = true
        }

        local function addESP(model)
            if not AllowedDoorModels[model.Name] then return end 

            local mesh = model:FindFirstChild("Door")
            if mesh and mesh:IsA("BasePart") then
                
                if not mesh:FindFirstChild("DoorESP_Highlight") then
                    local hl = Instance.new("Highlight")
                    hl.Name = "DoorESP_Highlight"
                    hl.FillColor = Options.DoorESP_Color.Value
                    hl.FillTransparency = 0.6
                    hl.OutlineTransparency = 0
                    hl.Parent = mesh
                end

                
                if not mesh:FindFirstChild("DoorESP_Billboard") then
                    local bb = Instance.new("BillboardGui")
                    bb.Name = "DoorESP_Billboard"
                    bb.AlwaysOnTop = true
                    bb.Size = UDim2.new(0,100,0,30)
                    bb.StudsOffset = Vector3.new(0, 0, 0)
                    bb.Parent = mesh

                    local lbl = Instance.new("TextLabel")
                    lbl.Name = "DoorESP_Label"
                    lbl.Size = UDim2.new(1,0,1,0)
                    lbl.Position = UDim2.new(0,0,0,0)
                    lbl.BackgroundTransparency = 1
                    lbl.TextColor3 = Color3.new(1,1,1)
                    lbl.TextScaled = true
                    lbl.Font = Enum.Font.Gotham
                    lbl.Text = "Door"
                    lbl.TextStrokeTransparency = 0
                    lbl.TextStrokeColor3 = Color3.new(0,0,0)
                    lbl.TextXAlignment = Enum.TextXAlignment.Center
                    lbl.TextYAlignment = Enum.TextYAlignment.Center
                    lbl.Parent = bb
                end

                
                if not table.find(_G.DoorESP_Objects, mesh) then
                    table.insert(_G.DoorESP_Objects, mesh)
                end
            end
        end

        if Value then
            _G.DoorESP_Objects = {}

            for _,v in pairs(workspace:GetDescendants()) do
                if v:IsA("Model") then
                    addESP(v)
                end
            end

            if not _G.DoorESP_Add then
                _G.DoorESP_Add = workspace.DescendantAdded:Connect(function(v)
                    if v:IsA("Model") then
                        addESP(v)
                    end
                end)
            end

            if not _G.DoorESP_Update then
                _G.DoorESP_Update = RunService.RenderStepped:Connect(function()
                    local plrRoot = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not plrRoot then return end

                    for i = #_G.DoorESP_Objects, 1, -1 do
                        local mesh = _G.DoorESP_Objects[i]
                        if mesh and mesh.Parent and mesh:IsA("BasePart") and mesh.Name == "Door" and AllowedDoorModels[mesh.Parent.Name] then
                            local bb = mesh:FindFirstChild("DoorESP_Billboard")
                            local hl = mesh:FindFirstChild("DoorESP_Highlight")
                            if bb and hl then
                                local dist = (plrRoot.Position - mesh.Position).Magnitude
                                local lbl = bb:FindFirstChild("DoorESP_Label")
                                if lbl then
                                    lbl.Text = "Door\n"..math.floor(dist).." studs"
                                end
                                hl.FillColor = Options.DoorESP_Color.Value
                            end
                        else
                            table.remove(_G.DoorESP_Objects, i)
                        end
                    end
                end)
            end
        else
            if _G.DoorESP_Add then _G.DoorESP_Add:Disconnect() _G.DoorESP_Add=nil end
            if _G.DoorESP_Update then _G.DoorESP_Update:Disconnect() _G.DoorESP_Update=nil end
            for _, mesh in pairs(_G.DoorESP_Objects or {}) do
                if mesh then
                    if mesh:FindFirstChild("DoorESP_Highlight") then
                        mesh.DoorESP_Highlight:Destroy()
                    end
                    if mesh:FindFirstChild("DoorESP_Billboard") then
                        mesh.DoorESP_Billboard:Destroy()
                    end
                end
            end
            _G.DoorESP_Objects = nil
        end
    end
}):AddColorPicker("DoorESP_Color", { Default = Color3.fromRGB(0,255,0), Title = "Door Color" })


VisualsGroup:AddToggle("CoinESP", {
    Text = "Coin ESP",
    Default = false,
    Tooltip = "shows coins through walls",
    Callback = function(Value)
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")

        local AllowedCoinModels = { ["GoldPile"] = true }

        local function addESP(model)
            if not AllowedCoinModels[model.Name] then return end
            if not model.PrimaryPart then return end 

            
            if not model:FindFirstChild("CoinESP_Highlight") then
                local hl = Instance.new("Highlight")
                hl.Name = "CoinESP_Highlight"
                hl.FillColor = Options.CoinESP_Color.Value
                hl.FillTransparency = 0.6
                hl.OutlineTransparency = 0
                hl.Parent = model
                hl.Adornee = model 
            end

            
            if not model:FindFirstChild("CoinESP_Billboard") then
                local bb = Instance.new("BillboardGui")
                bb.Name = "CoinESP_Billboard"
                bb.AlwaysOnTop = true
                bb.Size = UDim2.new(0,100,0,30)
                bb.StudsOffset = Vector3.new(0, 0.5, 0)
                bb.Adornee = model
                bb.Parent = model

                local lbl = Instance.new("TextLabel")
                lbl.Name = "CoinESP_Label"
                lbl.Size = UDim2.new(1,0,1,0)
                lbl.Position = UDim2.new(0,0,0,0)
                lbl.BackgroundTransparency = 1
                lbl.TextColor3 = Color3.new(1,1,0)
                lbl.TextScaled = true
                lbl.Font = Enum.Font.Gotham
                lbl.Text = "Gold"
                lbl.TextStrokeTransparency = 0
                lbl.TextStrokeColor3 = Color3.new(0,0,0)
                lbl.TextXAlignment = Enum.TextXAlignment.Center
                lbl.TextYAlignment = Enum.TextYAlignment.Center
                lbl.Parent = bb
            end

            
            if not table.find(_G.CoinESP_Objects, model) then
                table.insert(_G.CoinESP_Objects, model)
            end
        end

        if Value then
            _G.CoinESP_Objects = {}

            for _,v in pairs(workspace:GetDescendants()) do
                if v:IsA("Model") then
                    addESP(v)
                end
            end

            if not _G.CoinESP_Add then
                _G.CoinESP_Add = workspace.DescendantAdded:Connect(function(v)
                    if v:IsA("Model") then
                        addESP(v)
                    end
                end)
            end

            if not _G.CoinESP_Update then
                _G.CoinESP_Update = RunService.RenderStepped:Connect(function()
                    local plrRoot = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not plrRoot then return end

                    for i = #_G.CoinESP_Objects, 1, -1 do
                        local model = _G.CoinESP_Objects[i]
                        if model and model.Parent and model:IsA("Model") and AllowedCoinModels[model.Name] and model.PrimaryPart then
                            local hl = model:FindFirstChild("CoinESP_Highlight")
                            local bb = model:FindFirstChild("CoinESP_Billboard")
                            if hl and bb then
                                local dist = (plrRoot.Position - model.PrimaryPart.Position).Magnitude
                                local lbl = bb:FindFirstChild("CoinESP_Label")
                                if lbl then
                                    lbl.Text = "Gold\n"..math.floor(dist).." studs"
                                end
                                hl.FillColor = Options.CoinESP_Color.Value
                            end
                        else
                            table.remove(_G.CoinESP_Objects, i)
                        end
                    end
                end)
            end
        else
            if _G.CoinESP_Add then _G.CoinESP_Add:Disconnect() _G.CoinESP_Add=nil end
            if _G.CoinESP_Update then _G.CoinESP_Update:Disconnect() _G.CoinESP_Update=nil end
            for _, model in pairs(_G.CoinESP_Objects or {}) do
                if model then
                    if model:FindFirstChild("CoinESP_Highlight") then model.CoinESP_Highlight:Destroy() end
                    if model:FindFirstChild("CoinESP_Billboard") then model.CoinESP_Billboard:Destroy() end
                end
            end
            _G.CoinESP_Objects = nil
        end
    end
}):AddColorPicker("CoinESP_Color", { Default = Color3.fromRGB(255,255,0), Title = "Coin Color" })


VisualsGroup:AddToggle("KeyESP", {
    Text = "Key ESP",
    Default = false,
    Tooltip = "shows keys through walls",
    Callback = function(Value)
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")

        local AllowedKeyModels = { ["KeyObtain"] = true }

        local function addESP(model)
            if not AllowedKeyModels[model.Name] then return end
            if not model.PrimaryPart then return end 

            
            if not model:FindFirstChild("KeyESP_Highlight") then
                local hl = Instance.new("Highlight")
                hl.Name = "KeyESP_Highlight"
                hl.FillColor = Options.KeyESP_Color.Value
                hl.FillTransparency = 0.6
                hl.OutlineTransparency = 0
                hl.Parent = model
                hl.Adornee = model 
            end

            
            if not model:FindFirstChild("KeyESP_Billboard") then
                local bb = Instance.new("BillboardGui")
                bb.Name = "KeyESP_Billboard"
                bb.AlwaysOnTop = true
                bb.Size = UDim2.new(0,100,0,30)
                bb.StudsOffset = Vector3.new(0, 1, 0)
                bb.Adornee = model
                bb.Parent = model

                local lbl = Instance.new("TextLabel")
                lbl.Name = "KeyESP_Label"
                lbl.Size = UDim2.new(1,0,1,0)
                lbl.Position = UDim2.new(0,0,0,0)
                lbl.BackgroundTransparency = 1
                lbl.TextColor3 = Color3.new(0,1,1)
                lbl.TextScaled = true
                lbl.Font = Enum.Font.Gotham
                lbl.Text = "Key"
                lbl.TextStrokeTransparency = 0
                lbl.TextStrokeColor3 = Color3.new(0,0,0)
                lbl.TextXAlignment = Enum.TextXAlignment.Center
                lbl.TextYAlignment = Enum.TextYAlignment.Center
                lbl.Parent = bb
            end

            
            if not table.find(_G.KeyESP_Objects, model) then
                table.insert(_G.KeyESP_Objects, model)
            end
        end

        if Value then
            _G.KeyESP_Objects = {}

            for _,v in pairs(workspace:GetDescendants()) do
                if v:IsA("Model") then
                    addESP(v)
                end
            end

            if not _G.KeyESP_Add then
                _G.KeyESP_Add = workspace.DescendantAdded:Connect(function(v)
                    if v:IsA("Model") then
                        addESP(v)
                    end
                end)
            end

            if not _G.KeyESP_Update then
                _G.KeyESP_Update = RunService.RenderStepped:Connect(function()
                    local plrRoot = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not plrRoot then return end

                    for i = #_G.KeyESP_Objects, 1, -1 do
                        local model = _G.KeyESP_Objects[i]
                        if model and model.Parent and model:IsA("Model") and AllowedKeyModels[model.Name] and model.PrimaryPart then
                            local hl = model:FindFirstChild("KeyESP_Highlight")
                            local bb = model:FindFirstChild("KeyESP_Billboard")
                            if hl and bb then
                                local dist = (plrRoot.Position - model.PrimaryPart.Position).Magnitude
                                local lbl = bb:FindFirstChild("KeyESP_Label")
                                if lbl then
                                    lbl.Text = "Key\n"..math.floor(dist).." studs"
                                end
                                hl.FillColor = Options.KeyESP_Color.Value
                            end
                        else
                            table.remove(_G.KeyESP_Objects, i)
                        end
                    end
                end)
            end
        else
            if _G.KeyESP_Add then _G.KeyESP_Add:Disconnect() _G.KeyESP_Add=nil end
            if _G.KeyESP_Update then _G.KeyESP_Update:Disconnect() _G.KeyESP_Update=nil end
            for _, model in pairs(_G.KeyESP_Objects or {}) do
                if model then
                    if model:FindFirstChild("KeyESP_Highlight") then model.KeyESP_Highlight:Destroy() end
                    if model:FindFirstChild("KeyESP_Billboard") then model.KeyESP_Billboard:Destroy() end
                end
            end
            _G.KeyESP_Objects = nil
        end
    end
}):AddColorPicker("KeyESP_Color", { Default = Color3.fromRGB(0,255,255), Title = "Key Color" })


VisualsGroup:AddToggle("FuseESP", {
    Text = "Fuse ESP",
    Default = false,
    Tooltip = "shows fuses through walls",
    Callback = function(Value)
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")

        local AllowedFuseModels = { ["FuseObtain"] = true }

        local function addESP(model)
            if not AllowedFuseModels[model.Name] then return end
            if not model.PrimaryPart then return end 

            
            if not model:FindFirstChild("FuseESP_Highlight") then
                local hl = Instance.new("Highlight")
                hl.Name = "FuseESP_Highlight"
                hl.FillColor = Options.FuseESP_Color.Value
                hl.FillTransparency = 0.6
                hl.OutlineTransparency = 0
                hl.Parent = model
                hl.Adornee = model 
            end

            
            if not model:FindFirstChild("FuseESP_Billboard") then
                local bb = Instance.new("BillboardGui")
                bb.Name = "FuseESP_Billboard"
                bb.AlwaysOnTop = true
                bb.Size = UDim2.new(0,100,0,30)
                bb.StudsOffset = Vector3.new(0, 1, 0)
                bb.Adornee = model
                bb.Parent = model

                local lbl = Instance.new("TextLabel")
                lbl.Name = "FuseESP_Label"
                lbl.Size = UDim2.new(1,0,1,0)
                lbl.Position = UDim2.new(0,0,0,0)
                lbl.BackgroundTransparency = 1
                lbl.TextColor3 = Color3.new(0,1,1)
                lbl.TextScaled = true
                lbl.Font = Enum.Font.Gotham
                lbl.Text = "Fuse"
                lbl.TextStrokeTransparency = 0
                lbl.TextStrokeColor3 = Color3.new(0,0,0)
                lbl.TextXAlignment = Enum.TextXAlignment.Center
                lbl.TextYAlignment = Enum.TextYAlignment.Center
                lbl.Parent = bb
            end

            
            if not table.find(_G.FuseESP_Objects, model) then
                table.insert(_G.FuseESP_Objects, model)
            end
        end

        if Value then
            _G.FuseESP_Objects = {}

            for _,v in pairs(workspace:GetDescendants()) do
                if v:IsA("Model") then
                    addESP(v)
                end
            end

            if not _G.FuseESP_Add then
                _G.FuseESP_Add = workspace.DescendantAdded:Connect(function(v)
                    if v:IsA("Model") then
                        addESP(v)
                    end
                end)
            end

            if not _G.FuseESP_Update then
                _G.FuseESP_Update = RunService.RenderStepped:Connect(function()
                    local plrRoot = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not plrRoot then return end

                    for i = #_G.FuseESP_Objects, 1, -1 do
                        local model = _G.FuseESP_Objects[i]
                        if model and model.Parent and model:IsA("Model") and AllowedFuseModels[model.Name] and model.PrimaryPart then
                            local hl = model:FindFirstChild("FuseESP_Highlight")
                            local bb = model:FindFirstChild("FuseESP_Billboard")
                            if hl and bb then
                                local dist = (plrRoot.Position - model.PrimaryPart.Position).Magnitude
                                local lbl = bb:FindFirstChild("FuseESP_Label")
                                if lbl then
                                    lbl.Text = "Fuse\n"..math.floor(dist).." studs"
                                end
                                hl.FillColor = Options.FuseESP_Color.Value
                            end
                        else
                            table.remove(_G.FuseESP_Objects, i)
                        end
                    end
                end)
            end
        else
            if _G.FuseESP_Add then _G.FuseESP_Add:Disconnect() _G.FuseESP_Add=nil end
            if _G.FuseESP_Update then _G.FuseESP_Update:Disconnect() _G.FuseESP_Update=nil end
            for _, model in pairs(_G.FuseESP_Objects or {}) do
                if model then
                    if model:FindFirstChild("FuseESP_Highlight") then model.FuseESP_Highlight:Destroy() end
                    if model:FindFirstChild("FuseESP_Billboard") then model.FuseESP_Billboard:Destroy() end
                end
            end
            _G.FuseESP_Objects = nil
        end
    end
}):AddColorPicker("FuseESP_Color", { Default = Color3.fromRGB(0,255,255), Title = "Fuse Color" })




VisualsGroup:AddToggle("MinesGenerator", {
    Text = "Mines Generator",
    Default = false,
    Tooltip = "shows mines generators through walls",
    Callback = function(Value)
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")

        local AllowedMinesModels = { ["MinesGenerator"] = true }

        local function addESP(model)
            if not AllowedMinesModels[model.Name] then return end
            if not model.PrimaryPart then return end 

            
            if not model:FindFirstChild("MinesGenerator_Highlight") then
                local hl = Instance.new("Highlight")
                hl.Name = "MinesGenerator_Highlight"
                hl.FillColor = Options.MinesGenerator_Color.Value
                hl.FillTransparency = 0.6
                hl.OutlineTransparency = 0
                hl.Parent = model
                hl.Adornee = model 
            end

            
            if not model:FindFirstChild("MinesGenerator_Billboard") then
                local bb = Instance.new("BillboardGui")
                bb.Name = "MinesGenerator_Billboard"
                bb.AlwaysOnTop = true
                bb.Size = UDim2.new(0,100,0,30)
                bb.StudsOffset = Vector3.new(0, 1, 0)
                bb.Adornee = model
                bb.Parent = model

                local lbl = Instance.new("TextLabel")
                lbl.Name = "MinesGenerator_Label"
                lbl.Size = UDim2.new(1,0,1,0)
                lbl.Position = UDim2.new(0,0,0,0)
                lbl.BackgroundTransparency = 1
                lbl.TextColor3 = Color3.new(0,1,1)
                lbl.TextScaled = true
                lbl.Font = Enum.Font.Gotham
                lbl.Text = "Mines Generator"
                lbl.TextStrokeTransparency = 0
                lbl.TextStrokeColor3 = Color3.new(0,0,0)
                lbl.TextXAlignment = Enum.TextXAlignment.Center
                lbl.TextYAlignment = Enum.TextYAlignment.Center
                lbl.Parent = bb
            end

            
            if not table.find(_G.MinesGenerator_Objects, model) then
                table.insert(_G.MinesGenerator_Objects, model)
            end
        end

        if Value then
            _G.MinesGenerator_Objects = {}

            for _,v in pairs(workspace:GetDescendants()) do
                if v:IsA("Model") then
                    addESP(v)
                end
            end

            if not _G.MinesGenerator_Add then
                _G.MinesGenerator_Add = workspace.DescendantAdded:Connect(function(v)
                    if v:IsA("Model") then
                        addESP(v)
                    end
                end)
            end

            if not _G.MinesGenerator_Update then
                _G.MinesGenerator_Update = RunService.RenderStepped:Connect(function()
                    local plrRoot = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not plrRoot then return end

                    for i = #_G.MinesGenerator_Objects, 1, -1 do
                        local model = _G.MinesGenerator_Objects[i]
                        if model and model.Parent and model:IsA("Model") and AllowedMinesModels[model.Name] and model.PrimaryPart then
                            local hl = model:FindFirstChild("MinesGenerator_Highlight")
                            local bb = model:FindFirstChild("MinesGenerator_Billboard")
                            if hl and bb then
                                local dist = (plrRoot.Position - model.PrimaryPart.Position).Magnitude
                                local lbl = bb:FindFirstChild("MinesGenerator_Label")
                                if lbl then
                                    lbl.Text = "Mines Generator\n"..math.floor(dist).." studs"
                                end
                                hl.FillColor = Options.MinesGenerator_Color.Value
                            end
                        else
                            table.remove(_G.MinesGenerator_Objects, i)
                        end
                    end
                end)
            end
        else
            if _G.MinesGenerator_Add then _G.MinesGenerator_Add:Disconnect() _G.MinesGenerator_Add=nil end
            if _G.MinesGenerator_Update then _G.MinesGenerator_Update:Disconnect() _G.MinesGenerator_Update=nil end
            for _, model in pairs(_G.MinesGenerator_Objects or {}) do
                if model then
                    if model:FindFirstChild("MinesGenerator_Highlight") then model.MinesGenerator_Highlight:Destroy() end
                    if model:FindFirstChild("MinesGenerator_Billboard") then model.MinesGenerator_Billboard:Destroy() end
                end
            end
            _G.MinesGenerator_Objects = nil
        end
    end
}):AddColorPicker("MinesGenerator_Color", { Default = Color3.fromRGB(0,255,255), Title = "Mines Generator Color" })



VisualsGroup:AddToggle("LeverESP", {
    Text = "Lever ESP",
    Default = false,
    Tooltip = "lever ESP + improved obstacle-aware path (no walls, low-lag)",
    Callback = function(Value)
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local PathfindingService = game:GetService("PathfindingService")
        local LocalPlayer = Players.LocalPlayer

        local AllowedLeverModels = { ["LeverForGate"] = true }

        
        local GAP = 2.2                    
        local UPDATE_INTERVAL = 0.18       
        local MAX_PATH_DISTANCE = 450
        local SMOOTHNESS = 18              
        local MAX_PARTS = 60               
        local FALLBACK_SAMPLE_RADIUS = 5   
        local FALLBACK_ANGLE_STEP = 30     
        local FALLBACK_MAX_EXPAND = 3      
        local LINECAST_OVERHEAD = 2        
        local MAX_WAYPOINTS = 60           
        

        
        _G.LeverESP_Objects = _G.LeverESP_Objects or {}
        _G.LeverESP_PathParts = _G.LeverESP_PathParts or {}
        local targetPositions = {}
        local lastPlrPos = nil
        local currentTargetModel = nil
        local lastCompute = 0
        local baseY = nil
        local computing = false

        
        local function newRaycastParams()
            local p = RaycastParams.new()
            p.FilterType = Enum.RaycastFilterType.Blacklist
            p.FilterDescendantsInstances = { LocalPlayer.Character }
            return p
        end

        local function raycastDownOnce(pos)
            local origin = pos + Vector3.new(0, 8, 0)
            local dir = Vector3.new(0, -60, 0)
            local params = newRaycastParams()
            local res = workspace:Raycast(origin, dir, params)
            return res and res.Position or nil
        end

        
        local function lineClear(a, b)
            local dir = b - a
            local dist = dir.Magnitude
            if dist <= 0.01 then return true end
            dir = dir.Unit
            local origin = a + Vector3.new(0, LINECAST_OVERHEAD, 0)
            local params = newRaycastParams()
            local res = workspace:Raycast(origin, dir * (dist + 1), params)
            if not res then return true end
            
            if (res.Position - b).Magnitude <= 1.6 then
                if res.Normal:Dot(Vector3.new(0,1,0)) > 0.5 then return true end
            end
            return false
        end

        
        local function compactWaypoints(wps)
            local pts = {}
            for i, w in ipairs(wps) do
                table.insert(pts, w.Position)
            end
            
            local res = {}
            for i = 1, #pts do
                if i == 1 or (pts[i] - pts[#res]).Magnitude > 0.8 then
                    table.insert(res, pts[i])
                end
            end
            
            local out = {}
            for i = 1, #res do
                if i >= 3 then
                    local a = res[i-2]; local b = res[i-1]; local c = res[i]
                    local ab = (b - a).Unit
                    local bc = (c - b).Unit
                    if ab:Dot(bc) > 0.985 then
                        
                        out[#out] = nil
                        table.insert(out, c)
                    else
                        table.insert(out, c)
                    end
                else
                    table.insert(out, res[i])
                end
            end
            return out
        end

        
        local function positionsFromWaypointsPoints(pts)
            local positions = {}
            for idx = 1, #pts - 1 do
                local a = pts[idx]
                local b = pts[idx + 1]
                local seg = b - a
                local dist = seg.Magnitude
                local steps = math.max(1, math.ceil(dist / GAP))
                for s = 1, steps do
                    local t = s / steps
                    local pos = a:Lerp(b, t)
                    table.insert(positions, pos)
                    if #positions >= MAX_PARTS then break end
                end
                if #positions >= MAX_PARTS then break end
            end
            
            if #pts >= 1 and #positions < MAX_PARTS then
                table.insert(positions, pts[#pts])
            end
            return positions
        end

        
        local function tryPathfinding(startPos, targetPos)
            local ok, path = pcall(function()
                local p = PathfindingService:CreatePath({
                    AgentRadius = 2,
                    AgentHeight = 5,
                    AgentCanJump = true,
                    AgentJumpHeight = 7,
                    AgentMaxSlope = 45,
                })
                p:ComputeAsync(startPos, targetPos)
                return p
            end)
            if not ok or not path or path.Status ~= Enum.PathStatus.Success then
                return nil
            end
            local wps = path:GetWaypoints()
            if #wps == 0 then return nil end
            
            if #wps > MAX_WAYPOINTS then
                local step = math.ceil(#wps / MAX_WAYPOINTS)
                local reduced = {}
                for i = 1, #wps, step do table.insert(reduced, wps[i]) end
                wps = reduced
            end
            local compacted = compactWaypoints(wps)
            
            local snapped = {}
            for i = 1, #compacted do
                local pos = compacted[i]
                local ground = raycastDownOnce(pos)
                if not ground then
                    
                    return nil
                end
                table.insert(snapped, ground + Vector3.new(0, 0.12, 0))
            end
            
            local dense = positionsFromWaypointsPoints(snapped)
            return dense
        end

        
        local function createFallbackPath(startPos, targetPos)
            local positions = {}
            local totalDist = (targetPos - startPos).Magnitude
            local steps = math.max(1, math.ceil(totalDist / GAP))
            local prev = startPos
            for i = 1, steps do
                
                if i % 8 == 0 then task.wait() end

                local alpha = i / steps
                local candidate = startPos:Lerp(targetPos, alpha)

                
                local ground = raycastDownOnce(candidate)
                if ground and lineClear(prev, ground + Vector3.new(0,0.12,0)) then
                    local place = ground + Vector3.new(0, 0.12, 0)
                    table.insert(positions, place)
                    prev = place
                else
                    
                    local found = nil
                    local radius = FALLBACK_SAMPLE_RADIUS
                    for expand = 1, FALLBACK_MAX_EXPAND do
                        for deg = 0, 360 - FALLBACK_ANGLE_STEP, FALLBACK_ANGLE_STEP do
                            local rad = math.rad(deg)
                            local offs = Vector3.new(math.cos(rad) * radius, 0, math.sin(rad) * radius)
                            local cand2 = candidate + offs
                            local ground2 = raycastDownOnce(cand2)
                            if ground2 then
                                local place2 = ground2 + Vector3.new(0, 0.12, 0)
                                if lineClear(prev, place2) then
                                    found = place2
                                    break
                                end
                            end
                        end
                        if found then break end
                        radius = radius * 1.8
                        
                        task.wait(0)
                    end
                    if found then
                        table.insert(positions, found)
                        prev = found
                    else
                        
                    end
                end
                if #positions >= MAX_PARTS then break end
            end

            
            local targetGround = raycastDownOnce(targetPos)
            if targetGround and ( #positions == 0 or lineClear((#positions>0 and positions[#positions] or startPos), targetGround + Vector3.new(0,0.12,0)) ) then
                table.insert(positions, targetGround + Vector3.new(0, 0.12, 0))
            end

            
            if #positions > MAX_PARTS then
                local out = {}
                local step = math.ceil(#positions / MAX_PARTS)
                for i = 1, #positions, step do table.insert(out, positions[i]) end
                positions = out
            end
            return positions
        end

        
        local function createPathToAsync(targetPos)
            if computing then return end
            computing = true
            task.spawn(function()
                local ok, dense = pcall(function()
                    local plrRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not plrRoot then return {} end
                    local startPos = plrRoot.Position

                    
                    local groundUnderPlayer = raycastDownOnce(startPos)
                    if groundUnderPlayer then baseY = groundUnderPlayer.Y + 0.12 else baseY = startPos.Y end

                    
                    local pf = tryPathfinding(startPos, targetPos)
                    if pf and #pf > 0 then
                        return pf
                    end

                    
                    local fb = createFallbackPath(startPos, targetPos)
                    return fb or {}
                end)

                
                if ok and dense then
                    
                    for i = 1, #dense do
                        dense[i] = Vector3.new(dense[i].X, baseY or dense[i].Y, dense[i].Z)
                    end

                    
                    if #dense > MAX_PARTS then
                        local out = {}
                        local step = math.ceil(#dense / MAX_PARTS)
                        for i = 1, #dense, step do table.insert(out, dense[i]) end
                        dense = out
                    end

                    
                    targetPositions = dense
                    
                    for i = 1, #targetPositions do
                        if not _G.LeverESP_PathParts[i] or not _G.LeverESP_PathParts[i].Instance or not _G.LeverESP_PathParts[i].Instance.Parent then
                            local p = Instance.new("Part")
                            p.Name = "LeverESP_PathPart"
                            p.Size = Vector3.new(2.4, 0.26, 2.4)
                            p.Anchored = true
                            p.CanCollide = false
                            p.TopSurface = Enum.SurfaceType.Smooth
                            p.BottomSurface = Enum.SurfaceType.Smooth
                            p.Material = Enum.Material.Neon
                            p.Transparency = 0.18
                            if Options and Options.LeverESP_Color then
                                p.Color = Options.LeverESP_Color.Value
                            else
                                p.Color = Color3.fromRGB(255,165,0)
                            end
                            local mesh = Instance.new("CylinderMesh", p)
                            mesh.Scale = Vector3.new(1,1,1)
                            p.Parent = workspace
                            _G.LeverESP_PathParts[i] = { Instance = p }
                            
                            p.Position = targetPositions[1] or p.Position
                        end
                    end
                    
                    for i = #_G.LeverESP_PathParts, #targetPositions + 1, -1 do
                        local ent = _G.LeverESP_PathParts[i]
                        if ent and ent.Instance and ent.Instance.Parent then
                            pcall(function() ent.Instance:Destroy() end)
                        end
                        table.remove(_G.LeverESP_PathParts, i)
                    end
                end

                computing = false
            end)
        end

        
        local function findClosestLever(plrPos)
            local closest = nil
            local best = math.huge
            for _, model in pairs(_G.LeverESP_Objects or {}) do
                if model and model.Parent and model:IsA("Model") and AllowedLeverModels[model.Name] and model.PrimaryPart then
                    local d = (plrPos - model.PrimaryPart.Position).Magnitude
                    if d < best then
                        best = d
                        closest = model
                    end
                end
            end
            return closest, best
        end

        
        local function addESP(model)
            if not AllowedLeverModels[model.Name] then return end
            if not model.PrimaryPart then return end

            if not model:FindFirstChild("LeverESP_Highlight") then
                local hl = Instance.new("Highlight")
                hl.Name = "LeverESP_Highlight"
                hl.FillColor = Options.LeverESP_Color.Value
                hl.FillTransparency = 0.6
                hl.OutlineTransparency = 0
                hl.Parent = model
                hl.Adornee = model
            end

            if not model:FindFirstChild("LeverESP_Billboard") then
                local bb = Instance.new("BillboardGui")
                bb.Name = "LeverESP_Billboard"
                bb.AlwaysOnTop = true
                bb.Size = UDim2.new(0,100,0,30)
                bb.StudsOffset = Vector3.new(0, 3, 0)
                bb.Adornee = model
                bb.Parent = model

                local lbl = Instance.new("TextLabel")
                lbl.Name = "LeverESP_Label"
                lbl.Size = UDim2.new(1,0,1,0)
                lbl.BackgroundTransparency = 1
                lbl.TextColor3 = Color3.new(1,0.5,0)
                lbl.TextScaled = true
                lbl.Font = Enum.Font.Gotham
                lbl.Text = "Lever"
                lbl.TextStrokeTransparency = 0
                lbl.TextStrokeColor3 = Color3.new(0,0,0)
                lbl.TextXAlignment = Enum.TextXAlignment.Center
                lbl.TextYAlignment = Enum.TextYAlignment.Center
                lbl.Parent = bb
            end

            if not table.find(_G.LeverESP_Objects, model) then
                table.insert(_G.LeverESP_Objects, model)
            end
        end

        
        if Value then
            _G.LeverESP_Objects = {}

            for _,v in pairs(workspace:GetDescendants()) do
                if v:IsA("Model") then addESP(v) end
            end

            if not _G.LeverESP_Add then
                _G.LeverESP_Add = workspace.DescendantAdded:Connect(function(v)
                    if v:IsA("Model") then addESP(v) end
                end)
            end

            if not _G.LeverESP_Update then
                local acc = 0
                _G.LeverESP_Update = RunService.Heartbeat:Connect(function(dt)
                    acc = acc + dt
                    local plrRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not plrRoot then return end

                    
                    for i = #_G.LeverESP_Objects, 1, -1 do
                        local model = _G.LeverESP_Objects[i]
                        if model and model.Parent and model:IsA("Model") and AllowedLeverModels[model.Name] and model.PrimaryPart then
                            local hl = model:FindFirstChild("LeverESP_Highlight")
                            local bb = model:FindFirstChild("LeverESP_Billboard")
                            if hl and bb then
                                local dist = (plrRoot.Position - model.PrimaryPart.Position).Magnitude
                                local lbl = bb:FindFirstChild("LeverESP_Label")
                                if lbl then lbl.Text = "Lever\n"..math.floor(dist).." studs" end
                                hl.FillColor = Options.LeverESP_Color.Value
                            end
                        else
                            table.remove(_G.LeverESP_Objects, i)
                        end
                    end

                    
                    if #targetPositions > 0 and #_G.LeverESP_PathParts > 0 then
                        for i = 1, math.min(#targetPositions, #_G.LeverESP_PathParts) do
                            local ent = _G.LeverESP_PathParts[i]
                            if ent and ent.Instance and ent.Instance.Parent then
                                local p = ent.Instance
                                local tpos = targetPositions[i]
                                if tpos then
                                    local alpha = math.clamp(SMOOTHNESS * dt, 0, 1)
                                    p.Position = p.Position:Lerp(tpos, alpha)
                                end
                            end
                        end
                    end

                    
                    if #_G.LeverESP_PathParts > 0 then
                        for i = #_G.LeverESP_PathParts, 1, -1 do
                            local ent = _G.LeverESP_PathParts[i]
                            if ent and ent.Instance and ent.Instance.Parent then
                                local dist = (plrRoot.Position - ent.Instance.Position).Magnitude
                                if dist < (GAP * 0.95) then
                                    pcall(function() ent.Instance:Destroy() end)
                                    table.remove(_G.LeverESP_PathParts, i)
                                    table.remove(targetPositions, i)
                                end
                            else
                                table.remove(_G.LeverESP_PathParts, i)
                                table.remove(targetPositions, i)
                            end
                        end
                    end

                    
                    if acc >= UPDATE_INTERVAL then
                        acc = 0
                        local now = tick()
                        local plrPos = plrRoot.Position
                        local recompute = false
                        if not lastPlrPos or (plrPos - lastPlrPos).Magnitude > 0.9 then
                            recompute = true
                            lastPlrPos = plrPos
                        end
                        local closest, bestDist = findClosestLever(plrPos)
                        if closest ~= currentTargetModel then
                            currentTargetModel = closest
                            recompute = true
                        end
                        if recompute and (not computing) and currentTargetModel and currentTargetModel.PrimaryPart and bestDist < MAX_PATH_DISTANCE then
                            createPathToAsync(currentTargetModel.PrimaryPart.Position)
                        elseif not currentTargetModel or bestDist >= MAX_PATH_DISTANCE then
                            
                            targetPositions = {}
                            for i = #_G.LeverESP_PathParts, 1, -1 do
                                local ent = _G.LeverESP_PathParts[i]
                                if ent and ent.Instance and ent.Instance.Parent then
                                    pcall(function() ent.Instance:Destroy() end)
                                end
                                table.remove(_G.LeverESP_PathParts, i)
                            end
                        end
                    end
                end)
            end
        else
            
            if _G.LeverESP_Add then _G.LeverESP_Add:Disconnect() _G.LeverESP_Add = nil end
            if _G.LeverESP_Update then _G.LeverESP_Update:Disconnect() _G.LeverESP_Update = nil end

            for _, model in pairs(_G.LeverESP_Objects or {}) do
                if model then
                    if model:FindFirstChild("LeverESP_Highlight") then model.LeverESP_Highlight:Destroy() end
                    if model:FindFirstChild("LeverESP_Billboard") then model.LeverESP_Billboard:Destroy() end
                end
            end
            _G.LeverESP_Objects = nil

            
            if _G.LeverESP_PathParts then
                for _, ent in pairs(_G.LeverESP_PathParts) do
                    if ent and ent.Instance and ent.Instance.Parent then
                        pcall(function() ent.Instance:Destroy() end)
                    end
                end
            end
            _G.LeverESP_PathParts = nil
            targetPositions = {}
            currentTargetModel = nil
            baseY = nil
            computing = false
        end
    end
}):AddColorPicker("LeverESP_Color", { Default = Color3.fromRGB(255,165,0), Title = "Lever Color" })


VisualsGroup:AddToggle("ItemESP", {
    Text = "Item ESP",
    Default = false,
    Tooltip = "highlights all interactable items",
    Callback = function(Value)
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")

        local AllowedItemModels = {
            ["AlarmClock"] = true,
            ["Aloe"] = true,
            ["BandagePack"] = true,
            ["Battery"] = true,
            ["TimerLever"] = true,
            ["OuterPart"] = true,
            ["BatteryPack"] = true,
            ["Candle"] = true,
            ["LiveBreakerPolePickup"] = true,
            ["Compass"] = true,
            ["Crucifix"] = true,
            ["ElectricalRoomKey"] = true,
            ["Flashlight"] = true,
            ["Glowstick"] = true,
            ["HolyHandGrenade"] = true,
            ["Lantern"] = true,
            ["LaserPointer"] = true,
            ["Lighter"] = true,
            ["Lockpick"] = true,
            ["LotusFlower"] = true,
            ["LotusPetalPickup"] = true,
            ["Multitool"] = true,
            ["NVCS3000"] = true,
            ["OutdoorsKey"] = true,
            ["Shears"] = true,
            ["SkeletonKey"] = true,
            ["Smoothie"] = true,
            ["SolutionPaper"] = true,
            ["Spotlight"] = true,
            ["StarlightVial"] = true,
            ["StarlightJug"] = true,
            ["StarlightBottle"] = true,
            ["Vitamins"] = true
        }

        local function addESP(model)
            if not AllowedItemModels[model.Name] then return end
            if not model.PrimaryPart then return end

            
            if not model:FindFirstChild("ItemESP_Highlight") then
                local hl = Instance.new("Highlight")
                hl.Name = "ItemESP_Highlight"
                hl.FillColor = Options.ItemESP_Color.Value
                hl.FillTransparency = 0.6
                hl.OutlineTransparency = 0
                hl.Parent = model
                hl.Adornee = model
            end

            
            if not model:FindFirstChild("ItemESP_Billboard") then
                local bb = Instance.new("BillboardGui")
                bb.Name = "ItemESP_Billboard"
                bb.AlwaysOnTop = true
                bb.Size = UDim2.new(0,100,0,30)
                bb.StudsOffset = Vector3.new(0, 3, 0)
                bb.Adornee = model
                bb.Parent = model

                local lbl = Instance.new("TextLabel")
                lbl.Name = "ItemESP_Label"
                lbl.Size = UDim2.new(1,0,1,0)
                lbl.BackgroundTransparency = 1
                lbl.TextColor3 = Color3.new(1,1,0)
                lbl.TextScaled = true
                lbl.Font = Enum.Font.Gotham
                lbl.Text = model.Name
                lbl.TextStrokeTransparency = 0
                lbl.TextStrokeColor3 = Color3.new(0,0,0)
                lbl.TextXAlignment = Enum.TextXAlignment.Center
                lbl.TextYAlignment = Enum.TextYAlignment.Center
                lbl.Parent = bb
            end

            
            if not table.find(_G.ItemESP_Objects, model) then
                table.insert(_G.ItemESP_Objects, model)
            end
        end

        if Value then
            _G.ItemESP_Objects = {}

            for _,v in pairs(workspace:GetDescendants()) do
                if v:IsA("Model") then
                    addESP(v)
                end
            end

            if not _G.ItemESP_Add then
                _G.ItemESP_Add = workspace.DescendantAdded:Connect(function(v)
                    if v:IsA("Model") then
                        addESP(v)
                    end
                end)
            end

            if not _G.ItemESP_Update then
                _G.ItemESP_Update = RunService.RenderStepped:Connect(function()
                    local plrRoot = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not plrRoot then return end

                    for i = #_G.ItemESP_Objects, 1, -1 do
                        local model = _G.ItemESP_Objects[i]
                        if model and model.Parent and model:IsA("Model") and AllowedItemModels[model.Name] and model.PrimaryPart then
                            local hl = model:FindFirstChild("ItemESP_Highlight")
                            local bb = model:FindFirstChild("ItemESP_Billboard")
                            if hl and bb then
                                local dist = (plrRoot.Position - model.PrimaryPart.Position).Magnitude
                                local lbl = bb:FindFirstChild("ItemESP_Label")
                                if lbl then
                                    lbl.Text = model.Name.."\n"..math.floor(dist).." studs"
                                end
                                hl.FillColor = Options.ItemESP_Color.Value
                            end
                        else
                            table.remove(_G.ItemESP_Objects, i)
                        end
                    end
                end)
            end
        else
            if _G.ItemESP_Add then _G.ItemESP_Add:Disconnect() _G.ItemESP_Add=nil end
            if _G.ItemESP_Update then _G.ItemESP_Update:Disconnect() _G.ItemESP_Update=nil end
            for _, model in pairs(_G.ItemESP_Objects or {}) do
                if model then
                    if model:FindFirstChild("ItemESP_Highlight") then model.ItemESP_Highlight:Destroy() end
                    if model:FindFirstChild("ItemESP_Billboard") then model.ItemESP_Billboard:Destroy() end
                end
            end
            _G.ItemESP_Objects = nil
        end
    end
}):AddColorPicker("ItemESP_Color", { Default = Color3.fromRGB(255,255,0), Title = "Item Color" })

VisualsGroup:AddToggle("ClosetESP", {
    Text = "Closet ESP",
    Default = false,
    Tooltip = "shows closets through walls",
    Callback = function(Value)
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")

        local AllowedClosetModels = { ["Wardrobe"] = true, ["Toolshed"] = true, ["Locker_Large"] = true,  ["Backdoor_Wardrobe"] = true }

        local function addESP(model)
            if not AllowedClosetModels[model.Name] then return end
            if not model.PrimaryPart then return end 

            
            if not model:FindFirstChild("ClosetESP_Highlight") then
                local hl = Instance.new("Highlight")
                hl.Name = "ClosetESP_Highlight"
                hl.FillColor = Options.ClosetESP_Color.Value
                hl.FillTransparency = 0.6
                hl.OutlineTransparency = 0
                hl.Parent = model
                hl.Adornee = model
            end

            if not model:FindFirstChild("ClosetESP_Billboard") then
                local bb = Instance.new("BillboardGui")
                bb.Name = "ClosetESP_Billboard"
                bb.AlwaysOnTop = true
                bb.Size = UDim2.new(0,100,0,30)
                bb.StudsOffset = Vector3.new(0, 3, 0)
                bb.Adornee = model
                bb.Parent = model

                local lbl = Instance.new("TextLabel")
                lbl.Name = "ClosetESP_Label"
                lbl.Size = UDim2.new(1,0,1,0)
                lbl.BackgroundTransparency = 1
                lbl.TextColor3 = Color3.new(1,0,1)
                lbl.TextScaled = true
                lbl.Font = Enum.Font.Gotham
                lbl.Text = model.Name
                lbl.TextStrokeTransparency = 0
                lbl.TextStrokeColor3 = Color3.new(0,0,0)
                lbl.TextXAlignment = Enum.TextXAlignment.Center
                lbl.TextYAlignment = Enum.TextYAlignment.Center
                lbl.Parent = bb
            end

            
            if not table.find(_G.ClosetESP_Objects, model) then
                table.insert(_G.ClosetESP_Objects, model)
            end
        end

        if Value then
            _G.ClosetESP_Objects = {}

            for _,v in pairs(workspace:GetDescendants()) do
                if v:IsA("Model") then
                    addESP(v)
                end
            end

            if not _G.ClosetESP_Add then
                _G.ClosetESP_Add = workspace.DescendantAdded:Connect(function(v)
                    if v:IsA("Model") then
                        addESP(v)
                    end
                end)
            end

            if not _G.ClosetESP_Update then
                _G.ClosetESP_Update = RunService.RenderStepped:Connect(function()
                    local plrRoot = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not plrRoot then return end

                    for i = #_G.ClosetESP_Objects, 1, -1 do
                        local model = _G.ClosetESP_Objects[i]
                        if model and model.Parent and model:IsA("Model") and AllowedClosetModels[model.Name] and model.PrimaryPart then
                            local hl = model:FindFirstChild("ClosetESP_Highlight")
                            local bb = model:FindFirstChild("ClosetESP_Billboard")
                            if hl and bb then
                                local dist = (plrRoot.Position - model.PrimaryPart.Position).Magnitude
                                local lbl = bb:FindFirstChild("ClosetESP_Label")
                                if lbl then
                                    lbl.Text = model.Name.."\n"..math.floor(dist).." studs"
                                end
                                hl.FillColor = Options.ClosetESP_Color.Value
                            end
                        else
                            table.remove(_G.ClosetESP_Objects, i)
                        end
                    end
                end)
            end
        else
            if _G.ClosetESP_Add then _G.ClosetESP_Add:Disconnect() _G.ClosetESP_Add=nil end
            if _G.ClosetESP_Update then _G.ClosetESP_Update:Disconnect() _G.ClosetESP_Update=nil end
            for _, model in pairs(_G.ClosetESP_Objects or {}) do
                if model then
                    if model:FindFirstChild("ClosetESP_Highlight") then model.ClosetESP_Highlight:Destroy() end
                    if model:FindFirstChild("ClosetESP_Billboard") then model.ClosetESP_Billboard:Destroy() end
                end
            end
            _G.ClosetESP_Objects = nil
        end
    end
}):AddColorPicker("ClosetESP_Color", { Default = Color3.fromRGB(255,0,255), Title = "Closet Color" })


VisualsGroup:AddToggle("AnchorESP", {
    Text = "Anchor ESP",
    Default = false,
    Tooltip = "shows anchors through walls",
    Callback = function(Value)
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")

        local AllowedAnchorModels = { ["MinesAnchor"] = true }

        local function addESP(model)
            if not AllowedAnchorModels[model.Name] then return end
            if not model.PrimaryPart then return end 

            
            if not model:FindFirstChild("AnchorESP_Highlight") then
                local hl = Instance.new("Highlight")
                hl.Name = "AnchorESP_Highlight"
                hl.FillColor = Options.AnchorESP_Color.Value
                hl.FillTransparency = 0.6
                hl.OutlineTransparency = 0
                hl.Parent = model
                hl.Adornee = model
            end

            
            if not model:FindFirstChild("AnchorESP_Billboard") then
                local bb = Instance.new("BillboardGui")
                bb.Name = "AnchorESP_Billboard"
                bb.AlwaysOnTop = true
                bb.Size = UDim2.new(0,100,0,30)
                bb.StudsOffset = Vector3.new(0, 3, 0)
                bb.Adornee = model
                bb.Parent = model

                local lbl = Instance.new("TextLabel")
                lbl.Name = "AnchorESP_Label"
                lbl.Size = UDim2.new(1,0,1,0)
                lbl.BackgroundTransparency = 1
                lbl.TextColor3 = Color3.new(1,0,1)
                lbl.TextScaled = true
                lbl.Font = Enum.Font.Gotham
                lbl.Text = model.Name
                lbl.TextStrokeTransparency = 0
                lbl.TextStrokeColor3 = Color3.new(0,0,0)
                lbl.TextXAlignment = Enum.TextXAlignment.Center
                lbl.TextYAlignment = Enum.TextYAlignment.Center
                lbl.Parent = bb
            end

            
            if not table.find(_G.AnchorESP_Objects, model) then
                table.insert(_G.AnchorESP_Objects, model)
            end
        end

        if Value then
            _G.AnchorESP_Objects = {}

            for _,v in pairs(workspace:GetDescendants()) do
                if v:IsA("Model") then
                    addESP(v)
                end
            end

            if not _G.AnchorESP_Add then
                _G.AnchorESP_Add = workspace.DescendantAdded:Connect(function(v)
                    if v:IsA("Model") then
                        addESP(v)
                    end
                end)
            end

            if not _G.AnchorESP_Update then
                _G.AnchorESP_Update = RunService.RenderStepped:Connect(function()
                    local plrRoot = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not plrRoot then return end

                    for i = #_G.AnchorESP_Objects, 1, -1 do
                        local model = _G.AnchorESP_Objects[i]
                        if model and model.Parent and model:IsA("Model") and AllowedAnchorModels[model.Name] and model.PrimaryPart then
                            local hl = model:FindFirstChild("AnchorESP_Highlight")
                            local bb = model:FindFirstChild("AnchorESP_Billboard")
                            if hl and bb then
                                local dist = (plrRoot.Position - model.PrimaryPart.Position).Magnitude
                                local lbl = bb:FindFirstChild("AnchorESP_Label")
                                if lbl then
                                    lbl.Text = model.Name.."\n"..math.floor(dist).." studs"
                                end
                                hl.FillColor = Options.AnchorESP_Color.Value
                            end
                        else
                            table.remove(_G.AnchorESP_Objects, i)
                        end
                    end
                end)
            end
        else
            if _G.AnchorESP_Add then _G.AnchorESP_Add:Disconnect() _G.AnchorESP_Add=nil end
            if _G.AnchorESP_Update then _G.AnchorESP_Update:Disconnect() _G.AnchorESP_Update=nil end
            for _, model in pairs(_G.AnchorESP_Objects or {}) do
                if model then
                    if model:FindFirstChild("AnchorESP_Highlight") then model.AnchorESP_Highlight:Destroy() end
                    if model:FindFirstChild("AnchorESP_Billboard") then model.AnchorESP_Billboard:Destroy() end
                end
            end
            _G.AnchorESP_Objects = nil
        end
    end
}):AddColorPicker("AnchorESP_Color", { Default = Color3.fromRGB(255,0,255), Title = "Anchor Color" })





























VisualsGroup:AddToggle("LibraryBookESP", {
    Text = "Library Book ESP",
    Default = false,
    Tooltip = "shows library books through walls",
    Callback = function(Value)
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")

        local AllowedLibraryBookModels = { ["LiveHintBook"] = true }

        local function addESP(model)
            if not AllowedLibraryBookModels[model.Name] then return end
            if not model.PrimaryPart then return end 

            
            if not model:FindFirstChild("LibraryBookESP_Highlight") then
                local hl = Instance.new("Highlight")
                hl.Name = "LibraryBookESP_Highlight"
                hl.FillColor = Options.LibraryBookESP_Color.Value
                hl.FillTransparency = 0.6
                hl.OutlineTransparency = 0
                hl.Parent = model
                hl.Adornee = model
            end

            
            if not model:FindFirstChild("LibraryBookESP_Billboard") then
                local bb = Instance.new("BillboardGui")
                bb.Name = "LibraryBookESP_Billboard"
                bb.AlwaysOnTop = true
                bb.Size = UDim2.new(0,100,0,30)
                bb.StudsOffset = Vector3.new(0, 3, 0)
                bb.Adornee = model
                bb.Parent = model

                local lbl = Instance.new("TextLabel")
                lbl.Name = "LibraryBookESP_Label"
                lbl.Size = UDim2.new(1,0,1,0)
                lbl.BackgroundTransparency = 1
                lbl.TextColor3 = Color3.new(0,1,1)
                lbl.TextScaled = true
                lbl.Font = Enum.Font.Gotham
                lbl.Text = "Library Book"
                lbl.TextStrokeTransparency = 0
                lbl.TextStrokeColor3 = Color3.new(0,0,0)
                lbl.TextXAlignment = Enum.TextXAlignment.Center
                lbl.TextYAlignment = Enum.TextYAlignment.Center
                lbl.Parent = bb
            end

            
            if not table.find(_G.LibraryBookESP_Objects, model) then
                table.insert(_G.LibraryBookESP_Objects, model)
            end
        end

        if Value then
            _G.LibraryBookESP_Objects = {}

            for _,v in pairs(workspace:GetDescendants()) do
                if v:IsA("Model") then
                    addESP(v)
                end
            end

            if not _G.LibraryBookESP_Add then
                _G.LibraryBookESP_Add = workspace.DescendantAdded:Connect(function(v)
                    if v:IsA("Model") then
                        addESP(v)
                    end
                end)
            end

            if not _G.LibraryBookESP_Update then
                _G.LibraryBookESP_Update = RunService.RenderStepped:Connect(function()
                    local plrRoot = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not plrRoot then return end

                    for i = #_G.LibraryBookESP_Objects, 1, -1 do
                        local model = _G.LibraryBookESP_Objects[i]
                        if model and model.Parent and model:IsA("Model") and AllowedLibraryBookModels[model.Name] and model.PrimaryPart then
                            local hl = model:FindFirstChild("LibraryBookESP_Highlight")
                            local bb = model:FindFirstChild("LibraryBookESP_Billboard")
                            if hl and bb then
                                local dist = (plrRoot.Position - model.PrimaryPart.Position).Magnitude
                                local lbl = bb:FindFirstChild("LibraryBookESP_Label")
                                if lbl then
                                    lbl.Text = "Library Book\n"..math.floor(dist).." studs"
                                end
                                hl.FillColor = Options.LibraryBookESP_Color.Value
                            end
                        else
                            table.remove(_G.LibraryBookESP_Objects, i)
                        end
                    end
                end)
            end
        else
            if _G.LibraryBookESP_Add then _G.LibraryBookESP_Add:Disconnect() _G.LibraryBookESP_Add=nil end
            if _G.LibraryBookESP_Update then _G.LibraryBookESP_Update:Disconnect() _G.LibraryBookESP_Update=nil end
            for _, model in pairs(_G.LibraryBookESP_Objects or {}) do
                if model then
                    if model:FindFirstChild("LibraryBookESP_Highlight") then model.LibraryBookESP_Highlight:Destroy() end
                    if model:FindFirstChild("LibraryBookESP_Billboard") then model.LibraryBookESP_Billboard:Destroy() end
                end
            end
            _G.LibraryBookESP_Objects = nil
        end
    end
}):AddColorPicker("LibraryBookESP_Color", { Default = Color3.fromRGB(0,255,255), Title = "Library Book Color" })











VisualsGroup:AddToggle("VineCutterESP", {
    Text = "Vine Cutter ESP",
    Default = false,
    Tooltip = "Shows Vine Cutter through walls",
    Callback = function(Value)
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")

        local function addESP(model)
            if model.Name ~= "VineGuillotine" then return end

            -- highlight entire VineGuillotine model
            if not model:FindFirstChild("VineCutterESP_Highlight") then
                local hl = Instance.new("Highlight")
                hl.Name = "VineCutterESP_Highlight"
                hl.FillColor = Color3.fromRGB(0, 255, 0) -- green for vine cutters
                hl.FillTransparency = 0.6
                hl.OutlineTransparency = 0
                hl.Parent = model
                hl.Adornee = model
            end

            if not model:FindFirstChild("VineCutterESP_Billboard") then
                local bb = Instance.new("BillboardGui")
                bb.Name = "VineCutterESP_Billboard"
                bb.AlwaysOnTop = true
                bb.Size = UDim2.new(0, 120, 0, 30)
                bb.StudsOffset = Vector3.new(0, 5, 0)
                bb.Adornee = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
                bb.Parent = model

                local lbl = Instance.new("TextLabel")
                lbl.Name = "VineCutterESP_Label"
                lbl.Size = UDim2.new(1, 0, 1, 0)
                lbl.BackgroundTransparency = 1
                lbl.TextColor3 = Color3.new(0, 1, 0) -- green text
                lbl.TextScaled = true
                lbl.Font = Enum.Font.Gotham
                lbl.Text = "Vine Cutter"
                lbl.TextStrokeTransparency = 0
                lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
                lbl.TextXAlignment = Enum.TextXAlignment.Center
                lbl.TextYAlignment = Enum.TextYAlignment.Center
                lbl.Parent = bb
            end

            table.insert(_G.VineCutterESP_Objects, model)
        end

        if Value then
            _G.VineCutterESP_Objects = {}

            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("Model") then
                    addESP(v)
                end
            end

            if not _G.VineCutterESP_Add then
                _G.VineCutterESP_Add = workspace.DescendantAdded:Connect(function(v)
                    if v:IsA("Model") then
                        addESP(v)
                    end
                end)
            end

            if not _G.VineCutterESP_Update then
                _G.VineCutterESP_Update = RunService.RenderStepped:Connect(function()
                    local plrRoot = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not plrRoot then return end

                    for i = #_G.VineCutterESP_Objects, 1, -1 do
                        local model = _G.VineCutterESP_Objects[i]
                        if model and model.Parent and model:IsA("Model") and model.Name == "VineGuillotine" then
                            local bb = model:FindFirstChild("VineCutterESP_Billboard")
                            if bb then
                                local adornee = bb.Adornee
                                if adornee and adornee:IsA("BasePart") then
                                    local dist = (plrRoot.Position - adornee.Position).Magnitude
                                    local lbl = bb:FindFirstChild("VineCutterESP_Label")
                                    if lbl then
                                        lbl.Text = "Vine Cutter\n" .. math.floor(dist) .. " studs"
                                    end
                                end
                            end
                        else
                            table.remove(_G.VineCutterESP_Objects, i)
                        end
                    end
                end)
            end
        else
            if _G.VineCutterESP_Add then _G.VineCutterESP_Add:Disconnect() _G.VineCutterESP_Add=nil end
            if _G.VineCutterESP_Update then _G.VineCutterESP_Update:Disconnect() _G.VineCutterESP_Update=nil end
            for _, model in pairs(_G.VineCutterESP_Objects or {}) do
                if model then
                    if model:FindFirstChild("VineCutterESP_Highlight") then
                        model.VineCutterESP_Highlight:Destroy()
                    end
                    if model:FindFirstChild("VineCutterESP_Billboard") then
                        model.VineCutterESP_Billboard:Destroy()
                    end
                end
            end
            _G.VineCutterESP_Objects = nil
        end
    end
}):AddColorPicker("VineCutterESP_Color", { Default = Color3.fromRGB(0, 255, 0), Title = "Vine Cutter Color" })




VisualsGroup:AddToggle("ChestESP", {
    Text = "Chest ESP",
    Default = false,
    Tooltip = "Shows chests through walls",
    Callback = function(Value)
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")

        local function addESP(model)
            if model.Name ~= "ChestBox" and model.Name ~= "ChestBoxLocked" then return end

            local chestPart = model:FindFirstChildWhichIsA("BasePart") -- highlights the main part of the model
            if chestPart then
                local entry = {obj = chestPart}
                if not _G.ChestESP_Trans[chestPart] then
                    _G.ChestESP_Trans[chestPart] = chestPart.Transparency
                end
                entry.originalTrans = _G.ChestESP_Trans[chestPart]

                chestPart.Transparency = 0

                if not chestPart:FindFirstChild("ChestESP_Highlight") then
                    local hl = Instance.new("Highlight")
                    hl.Name = "ChestESP_Highlight"
                    hl.FillColor = Color3.fromRGB(0, 255, 0) -- green by default
                    hl.FillTransparency = 0.6
                    hl.OutlineTransparency = 0
                    hl.Parent = chestPart
                    hl.Adornee = chestPart
                end

                if not chestPart:FindFirstChild("ChestESP_Billboard") then
                    local bb = Instance.new("BillboardGui")
                    bb.Name = "ChestESP_Billboard"
                    bb.AlwaysOnTop = true
                    bb.Size = UDim2.new(0, 100, 0, 30)
                    bb.StudsOffset = Vector3.new(0, 3, 0)
                    bb.Adornee = chestPart
                    bb.Parent = chestPart

                    local lbl = Instance.new("TextLabel")
                    lbl.Name = "ChestESP_Label"
                    lbl.Size = UDim2.new(1, 0, 1, 0)
                    lbl.BackgroundTransparency = 1
                    lbl.TextColor3 = Color3.new(0, 1, 0)
                    lbl.TextScaled = true
                    lbl.Font = Enum.Font.Gotham
                    lbl.Text = model.Name
                    lbl.TextStrokeTransparency = 0
                    lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
                    lbl.TextXAlignment = Enum.TextXAlignment.Center
                    lbl.TextYAlignment = Enum.TextYAlignment.Center
                    lbl.Parent = bb
                end

                table.insert(_G.ChestESP_Objects, entry)
            end
        end

        if Value then
            _G.ChestESP_Objects = {}
            _G.ChestESP_Trans = {}

            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("Model") then
                    addESP(v)
                end
            end

            if not _G.ChestESP_Add then
                _G.ChestESP_Add = workspace.DescendantAdded:Connect(function(v)
                    if v:IsA("Model") then
                        addESP(v)
                    end
                end)
            end

            if not _G.ChestESP_Update then
                _G.ChestESP_Update = RunService.RenderStepped:Connect(function()
                    local plrRoot = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not plrRoot then return end

                    for i = #_G.ChestESP_Objects, 1, -1 do
                        local entry = _G.ChestESP_Objects[i]
                        local chestPart = entry.obj
                        if chestPart and chestPart.Parent and chestPart:IsA("BasePart") and (chestPart.Parent.Name == "ChestBox" or chestPart.Parent.Name == "ChestBoxLocked") then
                            local hl = chestPart:FindFirstChild("ChestESP_Highlight")
                            local bb = chestPart:FindFirstChild("ChestESP_Billboard")
                            if hl and bb then
                                local dist = (plrRoot.Position - chestPart.Position).Magnitude
                                local lbl = bb:FindFirstChild("ChestESP_Label")
                                if lbl then
                                    lbl.Text = chestPart.Parent.Name .. "\n" .. math.floor(dist) .. " studs"
                                end
                                hl.FillColor = Color3.fromRGB(0, 255, 0)
                            end
                        else
                            table.remove(_G.ChestESP_Objects, i)
                        end
                    end
                end)
            end
        else
            if _G.ChestESP_Add then _G.ChestESP_Add:Disconnect() _G.ChestESP_Add=nil end
            if _G.ChestESP_Update then _G.ChestESP_Update:Disconnect() _G.ChestESP_Update=nil end
            for _, entry in pairs(_G.ChestESP_Objects or {}) do
                local chestPart = entry.obj
                if chestPart then
                    chestPart.Transparency = entry.originalTrans
                    if chestPart:FindFirstChild("ChestESP_Highlight") then
                        chestPart.ChestESP_Highlight:Destroy()
                    end
                    if chestPart:FindFirstChild("ChestESP_Billboard") then
                        chestPart.ChestESP_Billboard:Destroy()
                    end
                end
            end
            _G.ChestESP_Objects = nil
            _G.ChestESP_Trans = nil
        end
    end
}):AddColorPicker("ChestESP_Color", { Default = Color3.fromRGB(0, 255, 0), Title = "Chest Color" })







local VisualsTab = Tabs.Visuals:AddRightTabbox("Interactable ESP")

-- Entities Tab: Notify and Anti
local NotifyGroup = Tabs.Entities:AddLeftGroupbox("Entity Notifications")
local EntityNotifications = {
    ["Screech"] = {Description = "Screech has spawned", Color = Color3.fromRGB(255, 255, 0)},
    ["Halt"] = {Description = "Halt is here", Color = Color3.fromRGB(0, 255, 255)},
    ["FigureRig"] = {Description = "Figure detected", Color = Color3.fromRGB(255, 0, 0)},
    ["Eyes"] = {Description = "Eyes spawned", Color = Color3.fromRGB(127, 30, 220)},
    ["SeekMoving"] = {Description = "Seek spawned", Color = Color3.fromRGB(255, 100, 100)},
    ["RushMoving"] = {Description = "Rush is coming", Color = Color3.fromRGB(0, 255, 0)},
    ["AmbushMoving"] = {Description = "Ambush is approaching", Color = Color3.fromRGB(80, 255, 110)},
    ["A60"] = {Description = "A-60 is rushing", Color = Color3.fromRGB(200, 50, 50)},
    ["A120"] = {Description = "A-120 is near", Color = Color3.fromRGB(55, 55, 55)},
    ["GiggleCeiling"] = {Description = "Giggle is on the ceiling", Color = Color3.fromRGB(200, 200, 200)},
    ["GrumbleRig"] = {Description = "Grumble is patrolling", Color = Color3.fromRGB(150, 150, 150)},
    ["GloombatSwarm"] = {Description = "Gloombat Swarm incoming", Color = Color3.fromRGB(100, 100, 100)},
    ["Dread"] = {Description = "Dread is active", Color = Color3.fromRGB(80, 80, 80)},
    ["BackdoorLookman"] = {Description = "Lookman is watching", Color = Color3.fromRGB(110, 15, 15)},
    ["Snare"] = {Description = "Snare trap spawned", Color = Color3.fromRGB(100, 100, 100)},
    ["WorldLotus"] = {Description = "World Lotus detected", Color = Color3.fromRGB(200, 230, 50)},
    ["Bramble"] = {Description = "Bramble is growing", Color = Color3.fromRGB(50, 150, 30)},
    ["Caws"] = {Description = "Caws are flying", Color = Color3.fromRGB(30, 30, 30)},
    ["Eyestalk"] = {Description = "Eyestalk is watching", Color = Color3.fromRGB(150, 80, 200)},
    ["Grampy"] = {Description = "Grampy is here", Color = Color3.fromRGB(180, 180, 180)},
    ["Groundskeeper"] = {Description = "Groundskeeper is near", Color = Color3.fromRGB(100, 150, 50)},
    ["Mandrake"] = {Description = "Mandrake is screaming", Color = Color3.fromRGB(130, 80, 30)},
    ["Monument"] = {Description = "Monument activated", Color = Color3.fromRGB(150, 150, 150)},
    ["Surge"] = {Description = "Surge is charging", Color = Color3.fromRGB(230, 130, 30)},
    ["BackdoorRush"] = {Description = "BLITZ IS COMING BRO", Color = Color3.fromRGB(230, 130, 30)},
}
local entityList = {
    "Screech", "Halt", "FigureRig", "Eyes", "SeekMoving", "RushMoving", "AmbushMoving",
    "A60", "A120", "GiggleCeiling", "GrumbleRig", "GloombatSwarm", "Dread",
    "BackdoorLookman", "Snare", "WorldLotus", "Bramble", "Caws", "Eyestalk",
    "Grampy", "Groundskeeper", "Mandrake", "Monument", "Surge", "LiveEntityBramble", "BackdoorRush"
}

NotifyGroup:AddDropdown("NotifyEntitiesDropdown", {
    Text = "Notify on Entity Spawn",
    Default = {},
    Multi = true,
    Values = entityList,
    Callback = function(selectedEntities)
        if AntiConnections["NotifyEntities"] then
            AntiConnections["NotifyEntities"]:Disconnect()
            AntiConnections["NotifyEntitiesRooms"]:Disconnect()
        end

        if next(selectedEntities) then
            AntiConnections["NotifyEntities"] = workspace.ChildAdded:Connect(function(child)
                if child:IsA("Model") and EntityNotifications[child.Name] and selectedEntities[child.Name] then
                    Library:Notify(EntityNotifications[child.Name].Description, 5)
                end
            end)

            AntiConnections["NotifyEntitiesRooms"] = Rooms.DescendantAdded:Connect(function(desc)
                if desc:IsA("Model") and EntityNotifications[desc.Name] and selectedEntities[desc.Name] then
                    Library:Notify(EntityNotifications[desc.Name].Description, 5)
                end
            end)
        end
    end
})
local AntiGroup = Tabs.Entities:AddRightGroupbox("Avoid Entities")
AntiConnections = AntiConnections or {}

AntiGroup:AddToggle("AntiScreech", {
    Text = "Avoid Screech",
    Default = false,
    Callback = function(on)
        if on then
            for _,inst in ipairs(workspace:GetDescendants()) do
                if inst.Name == "Screech" then pcall(function() inst:Destroy() end) end
            end
            AntiConnections.Screech = workspace.DescendantAdded:Connect(function(inst)
                if inst.Name == "Screech" then
                    task.defer(function() if inst and inst.Parent then pcall(function() inst:Destroy() end) end end)
                end
            end)
        else
            if AntiConnections.Screech then AntiConnections.Screech:Disconnect(); AntiConnections.Screech = nil end
        end
    end
})

local connection


AntiGroup:AddToggle("NoHasteEffects", {
    Text = "Avoid Haste Screen Effects",
    Default = false,
    Tooltip = "Removes red edges when Haste appears.",
    Callback = function(Value)
        if game.ReplicatedStorage.FloorReplicated.ClientRemote:FindFirstChild("Haste") then
            local HasteChanged = game.ReplicatedStorage.FloorReplicated.ClientRemote.Haste.Ambience:GetPropertyChangedSignal("Playing"):Connect(function()
                if Value then
                    game.ReplicatedStorage.FloorReplicated.ClientRemote.Haste.Ambience.Playing = false
                end
            end)
            table.insert(Connections, HasteChanged)
        end
        for _, v in workspace.CurrentCamera:GetChildren() do
            if v.Name == "LiveSanity" and workspace:FindFirstChild("EntityModel") then
                v.Enabled = not Value
            end
        end
    end
})

AntiGroup:AddToggle("NoHidingVignette", {
    Text = "Avoid Hiding Edges",
    Default = false,
    Tooltip = "Removes dark edges when hiding.",
    Callback = function(Value)
        LocalPlayer.PlayerGui.MainUI.MainFrame.HideVignette.Image = Value and "rbxassetid://0" or "rbxassetid://6100076320"
    end
})

local isCrouching = false

AntiGroup:AddToggle("CrouchSpoof", {
    Text = "Avoid Figure",
    Default = false,
    Tooltip = "Makes the game think you're crouching",
    Callback = function(Value)
        isCrouching = Value
        
        if Value then
            task.spawn(function()
                while isCrouching do
                    ReplicatedStorage.RemotesFolder.Crouch:FireServer(true)
                    task.wait(0.1)
                end
            end)
        else
            ReplicatedStorage.RemotesFolder.Crouch:FireServer(false)
        end
    end
})

local A90Hook

AntiGroup:AddToggle("AvoidA90", {
    Text = "Avoid A-90",
    Default = false,
    Tooltip = "Removes A90",
    Callback = function(Value)
        local A90 = Modules:FindFirstChild("A90") or Modules:FindFirstChild("velocitywashere")
        if A90 then
            A90.Name = Value and "velocitywashere" or "A90"
        end
    end
})



AntiGroup:AddToggle("NoVoidEffect", {
    Text = "Avoid Void Effect",
    Default = false,
    Tooltip = "Removes void falling effect.",
    Callback = function(Value)
        if not Script.EntityModules then return end

        local module = Script.EntityModules:FindFirstChild("Void") or Script.EntityModules:FindFirstChild("_VELOCITYVOID!")
        if module then
            module.Name = Value and "_Void" or "Void"
        end
    end
})

AntiGroup:AddToggle("NoSurge", {
    Text = "Avoid Surge",
    Default = false,
    Tooltip = "Credits to jack for the line",
    Callback = function(Value)
        if Value then
            local surgeClient = game.ReplicatedStorage:WaitForChild("FloorReplicated"):WaitForChild("ClientRemote"):FindFirstChild("SurgeClient")
            if surgeClient then
                surgeClient:Destroy()
            end
        end
    end
})


local ReplicatedStorage = game:GetService("ReplicatedStorage")

AntiGroup:AddToggle("AntiHalt", {
    Text = "Avoid Halt",
    Default = false,
    Callback = function(Value)
        local Halt = ClientModules.EntityModules:FindFirstChild("Shade") or
                     ClientModules.EntityModules:FindFirstChild("velocityxhalt")
        if Halt then
            Halt.Name = Value and "velocityxhalt" or "Shade"
        end
    end
})









local RunService = game:GetService("RunService")

AntiGroup:AddToggle("AntiLookman", {
    Text = "Avoid Lookman",
    Default = false,
    Callback = function(Value)
        if Value then
            if alive then
                if Workspace:FindFirstChild("BackdoorLookman") then
                    RemoteFolder.MotorReplication:FireServer(-890)
                end
            end
        end
    end
})

AntiGroup:AddToggle("AntiSnare", {
    Text = "Avoid Snare",
    Default = false,
    Callback = function(Value)
        local function updateSnareHitboxes()
            for _, v in game:GetService("Workspace").CurrentRooms:GetDescendants() do
                if v.Name == "Snare" and v:FindFirstChild("Hitbox") then
                    v.Hitbox.CanTouch = not Value
                end
            end
        end

        updateSnareHitboxes()

        if Value then
            if not _G.AntiSnare_Update then
                _G.AntiSnare_Update = game:GetService("RunService").Heartbeat:Connect(function()
                    updateSnareHitboxes()
                end)
            end

            if not _G.AntiSnare_Added then
                _G.AntiSnare_Added = game:GetService("Workspace").CurrentRooms.DescendantAdded:Connect(function(v)
                    if v.Name == "Snare" and v:FindFirstChild("Hitbox") then
                        v.Hitbox.CanTouch = not Value
                    end
                end)
            end
        else
            if _G.AntiSnare_Update then
                _G.AntiSnare_Update:Disconnect()
                _G.AntiSnare_Update = nil
            end
            if _G.AntiSnare_Added then
                _G.AntiSnare_Added:Disconnect()
                _G.AntiSnare_Added = nil
            end

            updateSnareHitboxes()
        end
    end
})

AntiGroup:AddToggle("AntiSeekArmsChandelier", {
    Text = "Avoid Seek Arms & Chandeliers",
    Default = false,
    Callback = function(Value)
        if Value then
            AntiConnections["SeekArmsChandelier"] = Rooms.DescendantAdded:Connect(function(desc)
                if desc.Name == "Seek_Arm" then
                    desc:WaitForChild("AnimatorPart", 9e9)
                    desc.AnimatorPart.CanTouch = false
                    desc.AnimatorPart.Transparency = 1
                    for _, part in desc:GetDescendants() do
                        if part:IsA("BasePart") then
                            part.Transparency = 1
                        end
                    end
                elseif desc.Name == "ChandelierObstruction" then
                    desc:WaitForChild("HurtPart", 9e9)
                    desc.HurtPart.CanTouch = false
                    desc.HurtPart.Transparency = 1
                    for _, part in desc:GetDescendants() do
                        if part:IsA("BasePart") then
                            part.Transparency = 1
                        end
                    end
                end
            end)
            for _, v in Rooms:GetDescendants() do
                if v.Name == "Seek_Arm" and v:IsA("Model") then
                    v:WaitForChild("AnimatorPart", 9e9)
                    v.AnimatorPart.CanTouch = false
                    v.AnimatorPart.Transparency = 1
                    for _, part in v:GetDescendants() do
                        if part:IsA("BasePart") then
                            part.Transparency = 1
                        end
                    end
                elseif v.Name == "ChandelierObstruction" and v:IsA("Model") then
                    v:WaitForChild("HurtPart", 9e9)
                    v.HurtPart.CanTouch = false
                    v.HurtPart.Transparency = 1
                    for _, part in v:GetDescendants() do
                        if part:IsA("BasePart") then
                            part.Transparency = 1
                        end
                    end
                end
            end
        else
            if AntiConnections["SeekArmsChandelier"] then AntiConnections["SeekArmsChandelier"]:Disconnect() end
            for _, v in Rooms:GetDescendants() do
                if v.Name == "Seek_Arm" and v:IsA("Model") then
                    v:WaitForChild("AnimatorPart", 9e9)
                    v.AnimatorPart.CanTouch = true
                    v.AnimatorPart.Transparency = 0
                    for _, part in v:GetDescendants() do
                        if part:IsA("BasePart") then
                            part.Transparency = 0
                        end
                    end
                elseif v.Name == "ChandelierObstruction" and v:IsA("Model") then
                    v:WaitForChild("HurtPart", 9e9)
                    v.HurtPart.CanTouch = true
                    v.HurtPart.Transparency = 0
                    for _, part in v:GetDescendants() do
                        if part:IsA("BasePart") then
                            part.Transparency = 0
                        end
                    end
                end
            end
        end
    end
})


AntiGroup:AddToggle("AntiDupe", {
    Text = "Avoid Dupe",
    Default = false,
    Callback = function(Value)
        for _, v in ipairs(workspace.CurrentRooms:GetDescendants()) do
            if v.Name == "DoorFake" then
                v:WaitForChild("Hidden").CanTouch = not Value
                local lock = v:FindFirstChild("Lock")
                if lock then
                    local prompt = lock:FindFirstChildOfClass("ProximityPrompt")
                    if prompt then
                        prompt.ClickablePrompt = not Value
                    end
                end
            end
        end
    end
})


AntiGroup:AddToggle("AntiVacuum", {
    Text = "Avoid Vacuum",
    Default = false,
    Callback = function(Value)
        for _, v in ipairs(workspace.CurrentRooms:GetDescendants()) do
            if v.Name == "SideroomSpace" then
                for _, part in ipairs(v:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.CanTouch = not Value
                        part.CanCollide = Value
                    end
                end
            end
        end
    end
})


AntiGroup:AddToggle("AntiMandrake", {
    Text = "Avoid Mandrake",
    Default = false,
    Callback = function(Value)
        local Workspace = game:GetService("Workspace")
        local CurrentRooms = Workspace:WaitForChild("CurrentRooms")

        local function destroyMandrake(obj)
            if obj.Name == "MandrakeHole" or obj.Name == "MandrakeLive" then
                obj:Destroy()
            end
        end

        if Value then
            for _, v in ipairs(CurrentRooms:GetDescendants()) do
                destroyMandrake(v)
            end

            local function periodicCheckForMandrakes()
                while Value do
                    for _, v in ipairs(CurrentRooms:GetDescendants()) do
                        destroyMandrake(v)
                    end
                    task.wait(5)  
                end
            end

            task.spawn(periodicCheckForMandrakes)
        else
            shared.Connect:DisconnectAll()
        end
    end
})




AntiGroup:AddToggle("AntiEyes", {
    Text = "Avoid Eyes",
    Default = false,
    Tooltip = "Automatically looks down when Eyes spawns to prevent damage.",
    Callback = function(Value)
        if Value then
            Connections.AntiEyes = game:GetService("RunService").RenderStepped:Connect(function()
                if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
                if not LocalPlayer.Character:GetAttribute("Hiding") then
                    for _, v in pairs(workspace:GetChildren()) do
                        if v.Name == "Eyes" and v:FindFirstChild("Core") and v.Core:FindFirstChild("Ambience") and v.Core.Ambience.Playing then
                            game.ReplicatedStorage.RemotesFolder.MotorReplication:FireServer(-650)
                            break
                        end
                    end
                end
            end)
        else
            if Connections.AntiEyes then
                Connections.AntiEyes:Disconnect()
                Connections.AntiEyes = nil
            end
        end
    end
})

local MissingFeaturesGroup = Tabs.Misc:AddRightGroupbox("MSHAX Features")

MissingFeaturesGroup:AddToggle('DeleteSeek', {
    Text = "Delete Seek (FE)",
    Default = false
})
task.spawn(function()
    while task.wait(0.09) do
        if Toggles.DeleteSeek.Value then
            local SeekCollision = workspace:FindFirstChild("TriggerEventCollision",true)
            local Trigger = workspace:FindFirstChild("TriggerSeek",true)
            if Trigger then Trigger:Destroy() end
            if SeekCollision then SeekCollision:ClearAllChildren() end
        end
    end
end)

MissingFeaturesGroup:AddToggle('AntiBanana', {
    Text = "Anti-Banana",
    Default = false,
    Callback = function(Value)
        for _, v in ipairs(workspace:GetChildren()) do
            if v.Name == "BananaPeel" then
                v.CanTouch = not Value
            end
        end
    end
})

MissingFeaturesGroup:AddToggle('AntiJeff', {
    Text = "Anti-Jeff",
    Default = false,
    Callback = function(Value)
        for _, v in ipairs(workspace:GetChildren()) do
            if v.Name == "JeffTheKiller" then
                for _, part in ipairs(v:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.CanTouch = not Value
                    end
                end
            end
        end
    end
})

workspace.ChildAdded:Connect(function(v)
    if v.Name == "BananaPeel" then
        v.CanTouch = not Toggles.AntiBanana.Value
    end
    if v.Name == "JeffTheKiller" then
        for _, part in ipairs(v:GetChildren()) do
            if part:IsA("BasePart") then
                part.CanTouch = not Toggles.AntiJeff.Value
            end
        end
    end
end)

MissingFeaturesGroup:AddToggle('AutoRooms', {
    Text = "Auto Rooms",
    Default = false
})

local mt = getrawmetatable(game)
setreadonly(mt, false)
local old = mt.__index
mt.__index = newcclosure(function(t,k)
    if k == "MoveDirection" and t:IsA("Humanoid") and t.Parent == LocalPlayer.Character and Toggles.AutoRooms.Value and not LocalPlayer.Character:GetAttribute("Hiding") then
        return Vector3.new(-2,0,0)
    end
    return old(t,k)
end)
setreadonly(mt, true)

Toggles.AutoRooms:OnChanged(function(Value)
    if not Value then
        LocalPlayer.Character.Humanoid:MoveTo(LocalPlayer.Character.HumanoidRootPart.Position)
    end
end)

MissingFeaturesGroup:AddToggle('InfiniteJump', {
    Text = "Infinite Jump",
    Default = false
})

local JumpConnection
if LocalPlayer.PlayerGui.MainUI.MainFrame.MobileButtons:FindFirstChild("JumpButton") then
    JumpConnection = LocalPlayer.PlayerGui.MainUI.MainFrame.MobileButtons.JumpButton.MouseButton1Click:Connect(function()
        task.wait(0.1)
        if Toggles.InfiniteJump.Value then
            if LocalPlayer.Character then
                LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)
end

MissingFeaturesGroup:AddToggle('InstantPrompt', {
    Text = "Instant Interacts",
    Default = false,
    Callback = function(Value)
        if Value then
            for _, v in ipairs(workspace.CurrentRooms:GetDescendants()) do
                if v:IsA("ProximityPrompt") then
                    v:SetAttribute("Hold", v.HoldDuration)
                    v.HoldDuration = 0
                end
            end
        else
            for _, v in ipairs(workspace.CurrentRooms:GetDescendants()) do
                if v:IsA("ProximityPrompt") then
                    v.HoldDuration = v:GetAttribute("Hold") or 0.7
                end
            end
        end
    end
})

MissingFeaturesGroup:AddToggle('PromptClip', {
    Text = "Prompt Clip",
    Default = false,
    Callback = function(Value)
        if Value then
            for _, v in ipairs(workspace.CurrentRooms:GetDescendants()) do
                if v:IsA("ProximityPrompt") then
                    v.RequiresLineOfSight = false
                end
            end
        else
            for _, v in ipairs(workspace.CurrentRooms:GetDescendants()) do
                if v:IsA("ProximityPrompt") then
                    v.RequiresLineOfSight = true
                end
            end
        end
    end
})

MissingFeaturesGroup:AddToggle('AntiAfk', {
    Text = "Disable AFK",
    Default = false
})
LocalPlayer.Idled:Connect(function()
    if Toggles.AntiAfk.Value then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

MissingFeaturesGroup:AddToggle('AntiLag', {
    Text = "Anti Lag",
    Default = false,
    Callback = function(Value)
        if Value then
            for _, v in ipairs(workspace.CurrentRooms:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.Material = Enum.Material.Plastic
                end
                if v.Name == "LightFixture" or v.Name == "Carpet" or v.Name == "CarpetLight" then
                    v:Destroy()
                end
            end
        end
    end
})

MissingFeaturesGroup:AddToggle('PromptReach', {
    Text = "Prompt Reach",
    Default = false,
    Callback = function(Value)
        if Value then
            for _, v in ipairs(workspace.CurrentRooms:GetDescendants()) do
                if v:IsA("ProximityPrompt") then
                    v:SetAttribute("Distance", v.MaxActivationDistance)
                    v.MaxActivationDistance = v.MaxActivationDistance * 2
                end
            end
        else
            for _, v in ipairs(workspace.CurrentRooms:GetDescendants()) do
                if v:IsA("ProximityPrompt") then
                    v.MaxActivationDistance = v:GetAttribute("Distance") or 7
                end
            end
        end
    end
})

MissingFeaturesGroup:AddToggle('DoorReach', {
    Text = "Door Reach",
    Default = false
})
MissingFeaturesGroup:AddSlider("DoorReachRange", {
    Text = "Door Reach Range",
    Default = 20,
    Min = 15,
    Max = 30,
    Rounding = 1,
    Compact = true,
    Callback = function(Value)
        -- Implementation for door reach range
    end
})

MissingFeaturesGroup:AddToggle('NoCutscenes', {
    Text = "No Cutscenes",
    Default = false
})

MissingFeaturesGroup:AddToggle('TransparencyCloset', {
    Text = "Transparency Closet",
    Default = false
})
MissingFeaturesGroup:AddSlider("TransparencySlider", {
    Text = "Transparency Slider",
    Default = 0.5,
    Min = 0.1,
    Max = 1,
    Rounding = 1,
    Compact = true,
    Callback = function(Value)
        -- Implementation for transparency
    end
})

MissingFeaturesGroup:AddToggle('TransparencyCart', {
    Text = "Transparency Cart",
    Default = false
})
MissingFeaturesGroup:AddSlider("CartTransparencySlider", {
    Text = "Transparency Slider",
    Default = 0.5,
    Min = 0.1,
    Max = 1,
    Rounding = 1,
    Compact = true,
    Callback = function(Value)
        -- Implementation for cart transparency
    end
})

MissingFeaturesGroup:AddToggle('Fullbright', {
    Text = "Fullbright",
    Default = false
})

MissingFeaturesGroup:AddToggle('NoCameraShake', {
    Text = "No Camera Shake",
    Default = false
})

MissingFeaturesGroup:AddToggle('ThirdPerson', {
    Text = "Third Person",
    Default = false
})
MissingFeaturesGroup:AddSlider("X", {
    Text = "X",
    Default = 2,
    Min = -10,
    Max = 10,
    Rounding = 0,
    Compact = true
})
MissingFeaturesGroup:AddSlider("Y", {
    Text = "Y",
    Default = 0,
    Min = -10,
    Max = 10,
    Rounding = 0,
    Compact = true
})
MissingFeaturesGroup:AddSlider("Z", {
    Text = "Z",
    Default = 6,
    Min = -10,
    Max = 10,
    Rounding = 0,
    Compact = true
})

MissingFeaturesGroup:AddToggle('SpectateEntity', {
    Text = "Spectate Entity",
    Default = false
})


local BringGroup = Tabs.Misc:AddRightGroupbox("General")

local EntityDistances = {
    ["RushMoving"] = 50,
    ["BackdoorRush"] = 50,
    ["AmbushMoving"] = 100,
    ["A60"] = 100,
    ["A120"] = 35
}

local Rooms = workspace.CurrentRooms
local LocalPlayer = game.Players.LocalPlayer

local function GetHiding()
    local Closest
    local Prompt

    local currRoom = Rooms and Rooms[LocalPlayer:GetAttribute("CurrentRoom")]
    if not currRoom then return nil end
    local char = LocalPlayer.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Collision") or char.PrimaryPart
    if not hrp then return nil end

    local function distFromPlayer(model)
        if not model then return math.huge end
        local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
        if not part then return math.huge end
        return (part.Position - hrp.Position).Magnitude
    end

    local assets = currRoom:FindFirstChild("Assets")
    if assets then
        for _, v in pairs(assets:GetChildren()) do
            if v:IsA("Model") then
                if (v.Name == "Locker_Large" or v.Name == "Wardrobe" or v.Name == "Toolshed" or v.Name == "Bed" or v.Name == "Rooms_Locker" or v.Name == "Rooms_Locker_Fridge" or v.Name == "Backdoor_Wardrobe") and v:FindFirstChild("HidePrompt") and v:FindFirstChild("HiddenPlayer") then
                    if not v.HiddenPlayer.Value and not v:FindFirstChild("HideEntityOnSpot", true) then
                        if Closest then
                            if distFromPlayer(v) < distFromPlayer(Closest) then
                                Closest = v
                                Prompt = v.HidePrompt
                            end
                        else
                            Closest = v
                            Prompt = v.HidePrompt
                        end
                    end
                elseif v.Name == "Double_Bed" then
                    for _, x in pairs(v:GetChildren()) do
                        if x.Name == "DoubleBed" and x:FindFirstChild("HidePrompt") and x:FindFirstChild("HiddenPlayer") then
                            if not x.HiddenPlayer.Value and not x:FindFirstChild("HideEntityOnSpot", true) then
                                if Closest then
                                    if distFromPlayer(x) < distFromPlayer(Closest) then
                                        Closest = x
                                        Prompt = x.HidePrompt
                                    end
                                else
                                    Closest = x
                                    Prompt = x.HidePrompt
                                end
                            end
                        end
                    end
                elseif v.Name == "Dumpster" then
                    for _, x in pairs(v:GetChildren()) do
                        if x:FindFirstChild("HidePrompt") and x:FindFirstChild("HiddenPlayer") then
                            local dumpsterBaseHasSpot = v:FindFirstChild("DumpsterBase") and v.DumpsterBase:FindFirstChild("HideEntityOnSpot")
                            if not x.HiddenPlayer.Value and not dumpsterBaseHasSpot then
                                if Closest then
                                    if distFromPlayer(x) < distFromPlayer(Closest) then
                                        Closest = x
                                        Prompt = x.HidePrompt
                                    end
                                else
                                    Closest = x
                                    Prompt = x.HidePrompt
                                end
                            end
                        end
                    end
                end
            elseif v:IsA("Folder") then
                if v.Name == "Blockage" then
                    for _, x in pairs(v:GetChildren()) do
                        if x:IsA("Model") and x.Name == "Wardrobe" and x:FindFirstChild("HiddenPlayer") and x:FindFirstChild("HidePrompt") then
                            if not x.HiddenPlayer.Value then
                                if Closest then
                                    if distFromPlayer(x) < distFromPlayer(Closest) then
                                        Closest = x
                                        Prompt = x.HidePrompt
                                    end
                                else
                                    Closest = x
                                    Prompt = x.HidePrompt
                                end
                            end
                        end
                    end
                elseif v.Name == "Vents" then
                    for _, x in pairs(v:GetChildren()) do
                        if x.Name == "CircularVent" and x:FindFirstChild("Grate") and x.Grate:FindFirstChild("HidePrompt") and x:FindFirstChild("HiddenPlayer") then
                            if not x.HiddenPlayer.Value and not v:FindFirstChild("HideEntityOnSpot", true) then
                                if Closest then
                                    if distFromPlayer(x) < distFromPlayer(Closest) then
                                        Closest = x
                                        Prompt = x.Grate.HidePrompt
                                    end
                                else
                                    Closest = x
                                    Prompt = x.Grate.HidePrompt
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    for _, v in pairs(currRoom:GetChildren()) do
        if v:IsA("Model") then
            if v.Name == "CircularVent" and v:FindFirstChild("Grate") and v.Grate:FindFirstChild("HidePrompt") and v:FindFirstChild("HiddenPlayer") then
                if not v.HiddenPlayer.Value and not v:FindFirstChild("HideEntityOnSpot", true) then
                    if Closest then
                        if distFromPlayer(v) < distFromPlayer(Closest) then
                            Closest = v
                            Prompt = v.Grate.HidePrompt
                        end
                    else
                        Closest = v
                        Prompt = v.Grate.HidePrompt
                    end
                end
            end
        end
    end

    return Prompt
end

BringGroup:AddToggle("AutoHide", {
    Text = "Auto Hide V2",
    Default = false,
    Tooltip = "hides for you, couldnt you guess it",
    Callback = function(Value)
    end
})

BringGroup:AddSlider("PredictionTime", {
    Text = "Prediction Time",
    Default = 1.5,
    Min = 0.1,
    Max = 1.5,
    Rounding = 2,
    Compact = true,
    Suffix = "s",
    Callback = function(Value)
    end
})

BringGroup:AddSlider("DistanceMultiplier", {
    Text = "Distance Multiplier",
    Default = 1,
    Min = 1,
    Max = 1.5,
    Rounding = 1,
    Compact = true,
    Suffix = "x",
    Callback = function(Value)
    end
})

task.spawn(function()
    local Connections = {}
    table.insert(Connections, workspace.ChildAdded:Connect(function(v)
        if v:IsA("Model") and EntityDistances[v.Name] then
            task.wait(1)
            local Part = v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart", true)
            if not Part then return end
            v:SetAttribute("_Prediction", Part.Position)

            while task.wait() and v.Parent do
                task.spawn(function()
                    local LastPosition = Part.Position
                    task.wait(1 / 3)
                    if Part and Part.Parent then
                        v:SetAttribute("_Prediction", Part.Position - LastPosition)
                    end
                end)

                if Toggles and Toggles.AutoHide and Toggles.AutoHide.Value then
                    local IncludeList = {}
                    for _, Room in pairs(Rooms:GetChildren()) do
                        if Room:FindFirstChild("Assets") then
                            table.insert(IncludeList, Room.Assets)
                        end
                        if Room:FindFirstChild("Parts") then
                            table.insert(IncludeList, Room.Parts)
                        end
                    end

                    local RaycastParams = RaycastParams.new()
                    RaycastParams.FilterDescendantsInstances = IncludeList
                    RaycastParams.FilterType = Enum.RaycastFilterType.Include

                    local Count = {0.2, 0.4, 0.6, 0.8, 1}

                    for i = 1, #Count do
                        local Number = (Options and Options.PredictionTime and Options.PredictionTime.Value) or 0.5
                        Number = Number * Count[i]
                        local predAttr = v:GetAttribute("_Prediction")
                        local Prediction = (predAttr and predAttr * 3) or Vector3.new(0,0,0)
                        Prediction = Prediction * Number

                        local char = LocalPlayer.Character
                        if not char then break end
                        local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Collision") or char.PrimaryPart
                        if not hrp then break end

                        if not char:GetAttribute("Hiding") and Vector3.new(Prediction.X, 0, Prediction.Z).Magnitude > 1 then
                            local PredictionPosition = Part.Position + Prediction
                            local Raycast
                            if Toggles.GA_AutoHide_VisCheck and Toggles.GA_AutoHide_VisCheck.Value then
                                Raycast = workspace:Raycast(hrp.Position, PredictionPosition - hrp.Position, RaycastParams)
                            end

                            local distMultiplier = (Options and Options.DistanceMultiplier and Options.DistanceMultiplier.Value) or 1
                            if (not Raycast) and (PredictionPosition - hrp.Position).Magnitude <= (EntityDistances[v.Name] * distMultiplier) then
                                local Prompt = GetHiding()
                                if Prompt then
                                    pcall(function() fireproximityprompt(Prompt) end)
                                end
                            end
                        end
                    end
                end
            end
        end
    end))
end)

BringGroup:AddDivider()


local doorReachLoop 

BringGroup:AddToggle("DoorReach", {
    Text = "Door Reach",
    Default = false,
    Tooltip = "increases door reach opening",
    Callback = function(Value)
        if Value then
            doorReachLoop = task.spawn(function()
                while Toggles.DoorReach.Value do
                    for _, obj in pairs(workspace:GetDescendants()) do
                        if obj:IsA("Model") and obj.Name == "Door" then
                            local clientOpen = obj:FindFirstChild("ClientOpen")
                            if clientOpen and clientOpen:IsA("RemoteEvent") then
                                clientOpen:FireServer()
                            end
                        end
                    end
                    task.wait(0.5) 
                end
            end)
        else
            doorReachLoop = nil
        end
    end
})




BringGroup:AddToggle("InfItems", {
    Text = "Infinite Items",
    Default = false,
    Callback = function(Value)
        local InfiniteValue = Value
        local InfStore = {}

        local function cleanupEnableReal()
            for _, v in ipairs(Workspace.CurrentRooms:GetDescendants()) do
                if v.Name == "FakePrompt" and v.Parent then
                    v:Destroy()
                end
                if v:IsA("ProximityPrompt") and v.Name ~= "FakePrompt" then
                    pcall(function()
                        v.Enabled = true
                        v.ClickablePrompt = true
                        if v:GetAttribute("HasFake") == true then
                            v:SetAttribute("HasFake", nil)
                        end
                    end)
                end
            end
        end

        local function scanPrompts(validParents, validNames)
            local t = {}
            for _, v in ipairs(Workspace.CurrentRooms:GetDescendants()) do
                if v:IsA("ProximityPrompt") and (validParents[v.Parent.Name] or validNames[v.Name]) then
                    table.insert(t, v)
                end
            end
            return t
        end

        local LockpickParents = { ChestBoxLocked = true, Locker_Small_Locked = true, Toolbox_Locked = true }
        local LockpickNames = { UnlockPrompt = true, ThingToEnable = true, LockPrompt = true, SkullPrompt = true, FusesPrompt = true }

        if not InfiniteValue then
            cleanupEnableReal()
            InfStore = {}
            return
        end

        InfStore = scanPrompts(LockpickParents, LockpickNames)
    end
})






BringGroup:AddToggle("InstantInteract", {
    Text = "Instant Interact",
    Default = false,
    Tooltip = "removes the little waittimes of proxim prompts",
    Callback = function(Value)
        if Value then
            getgenv().InstantInteract = hookmetamethod(game, "__namecall", function(self, ...)
                local method = getnamecallmethod()
                local args = {...}
                
                if method == "FireServer" and self.Name == "ProximityPromptService" then
                    if args[1] and typeof(args[1]) == "Instance" and args[1]:IsA("ProximityPrompt") then
                        args[1].HoldDuration = 0
                        args[1].RequiresLineOfSight = false
                    end
                elseif method == "InvokeServer" and tostring(self):find("ProximityPrompt") then
                    return getgenv().InstantInteract(self, ...)
                end
                
                return getgenv().InstantInteract(self, ...)
            end)
            
            for _, prompt in pairs(workspace:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") then
                    prompt.HoldDuration = 0
                    prompt.RequiresLineOfSight = false
                end
            end
            
            getgenv().ProximityConnection = workspace.DescendantAdded:Connect(function(descendant)
                if descendant:IsA("ProximityPrompt") then
                    wait() 
                    descendant.HoldDuration = 0
                    descendant.RequiresLineOfSight = false
                end
            end)
            
        else
            if getgenv().InstantInteract then
                hookmetamethod(game, "__namecall", getgenv().InstantInteract)
                getgenv().InstantInteract = nil
            end
            
            if getgenv().ProximityConnection then
                getgenv().ProximityConnection:Disconnect()
                getgenv().ProximityConnection = nil
            end
            
            for _, prompt in pairs(workspace:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") then
                    prompt.HoldDuration = prompt:GetAttribute("OriginalHoldDuration") or 1
                    prompt.RequiresLineOfSight = prompt:GetAttribute("OriginalLineOfSight") or true
                end
            end
        end
    end
})

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local excludedModels = {
    Wardrobe = true,
    Toolshed = true,
    Bed = true,
    Rooms_Locker = true,
    Rooms_Locker_Fridge = true,
    Backdoor_Wardrobe = true,
    Double_Bed = true,
    Dumpster = true,
    LiveHintBook = true,
    Padlock = true,
    BreakerBox = true,
    Painting_Tall = true,
    Painting_Big = true,
    Painting_VeryBig = true,
}

local function isInExcludedModel(inst)
    local parent = inst and inst.Parent
    while parent do
        if excludedModels[parent.Name] then
            return true
        end
        parent = parent.Parent
    end
    return false
end

local function getPromptPosition(prompt)
    local parent = prompt.Parent
    if not parent then return Vector3.new() end
    if parent:IsA("Attachment") and parent.WorldPosition then
        return parent.WorldPosition
    elseif parent:IsA("BasePart") then
        return parent.Position
    elseif parent:IsA("Model") then
        if parent.PrimaryPart then return parent.PrimaryPart.Position end
        for _,v in ipairs(parent:GetDescendants()) do
            if v:IsA("BasePart") then return v.Position end
        end
    end
    return parent.Position or Vector3.new()
end

local conn
local lastTriggered = {}


local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local AutoInteractDistance = 10

function HasItem(ItemName)
    local Item = LocalPlayer.Backpack:FindFirstChild(ItemName) or LocalPlayer.Character:FindFirstChild(ItemName)
    return Item
end

function FindAllByName(parent, targetName, results)
    results = results or {}
    
    for _, child in parent:GetChildren() do
        if child.Name == targetName then
            table.insert(results, child)
        end
        if child:IsA("Folder") or child:IsA("Model") then
            FindAllByName(child, targetName, results)
        end
    end
    
    return results
end

function InteractWithDrawers()
    local drawers = FindAllByName(workspace, "DrawerContainer")
    
    for _, drawer in drawers do
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Collision") then
            local prompt = nil

            if drawer:FindFirstChild("Knobs") and drawer.Knobs:FindFirstChild("ActivateEventPrompt") then
                prompt = drawer.Knobs.ActivateEventPrompt
                if (drawer.Knobs.Position - LocalPlayer.Character.Collision.Position).Magnitude < AutoInteractDistance then
                    if not prompt:GetAttribute("Interactions") then
                        fireproximityprompt(prompt)
                    end
                end
            elseif drawer:FindFirstChild("Knob") and drawer.Knob:FindFirstChild("ActivateEventPrompt") then
                prompt = drawer.Knob.ActivateEventPrompt
                if (drawer.Knob.Position - LocalPlayer.Character.Collision.Position).Magnitude < AutoInteractDistance then
                    if not prompt:GetAttribute("Interactions") then
                        fireproximityprompt(prompt)
                    end
                end
            elseif drawer:FindFirstChild("Metal") and drawer.Metal:FindFirstChild("ActivateEventPrompt") then
                prompt = drawer.Metal.ActivateEventPrompt
                if (drawer.Metal.Position - LocalPlayer.Character.Collision.Position).Magnitude < AutoInteractDistance then
                    if not prompt:GetAttribute("Interactions") then
                        fireproximityprompt(prompt)
                    end
                end
            end

            if prompt and prompt:GetAttribute("Interactions") then
                FindLoot(drawer)
            end
        end
    end
end


function InteractWithGoldPiles()
    local goldPiles = FindAllByName(workspace, "GoldPile")
    
    for _, goldPile in ipairs(goldPiles) do
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Collision") then
            if goldPile:FindFirstChild("Hitbox") and goldPile:FindFirstChild("LootPrompt") then
                if (goldPile.Hitbox.Position - LocalPlayer.Character.Collision.Position).Magnitude < AutoInteractDistance then
                    fireproximityprompt(goldPile.LootPrompt)
                end
            end
        end
    end
end


function FindLoot(Origin)
    local Glowsticks = HasItem("Glowsticks")
    local BandagePack = HasItem("BandagePack")
    local BatteryPack = HasItem("BatteryPack")

    for _, Loot in Origin:GetChildren() do
        if Loot.Name == "Glowsticks" and not (Options.GA_AutoInteract_Options and Options.GA_AutoInteract_Options.Value["Ignore Light Sources"]) then
            if not (Glowsticks and Glowsticks:GetAttribute("Durability") >= Glowsticks:GetAttribute("DurabilityMax")) then
                if Loot:FindFirstChild("Main") and Loot:FindFirstChild("ModulePrompt") then
                    if (Loot.Main.Position - LocalPlayer.Character.Collision.Position).Magnitude < AutoInteractDistance then
                        fireproximityprompt(Loot.ModulePrompt)
                    end
                end
            end

        elseif Loot.Name == "GoldPile" then
            if Loot:FindFirstChild("Hitbox") and Loot:FindFirstChild("LootPrompt") then
                if (Loot.Hitbox.Position - LocalPlayer.Character.Collision.Position).Magnitude < AutoInteractDistance then
                    fireproximityprompt(Loot.LootPrompt)
                end
            end

        elseif Loot.Name == "Bandage" then
            if (LocalPlayer.Character.Humanoid.Health < 100 or (BandagePack and BandagePack:GetAttribute("Durability") < BandagePack:GetAttribute("DurabilityMax"))) then
                if Loot:FindFirstChild("Main") and Loot:FindFirstChild("ModulePrompt") then
                    if (Loot.Main.Position - LocalPlayer.Character.Collision.Position).Magnitude < AutoInteractDistance then
                        fireproximityprompt(Loot.ModulePrompt)
                    end
                end
            end

        elseif Loot.Name == "StarJug" or Loot.Name == "Lockpick" or Loot.Name == "StarVial" or Loot.Name == "SkeletonKey" or Loot.Name == "Crucifix" or Loot.Name == "CrucifixWall" or Loot.Name == "Flashlight" or Loot.Name == "Candle" or Loot.Name == "Straplight" or Loot.Name == "Vitamins" or Loot.Name == "Lighter" or Loot.Name == "Shears" or Loot.Name == "BatteryPack" or Loot.Name == "BandagePack" or Loot.Name == "LaserPointer" or Loot.Name == "Bulklight" then
            if Loot:FindFirstChild("Main") and Loot:FindFirstChild("ModulePrompt") then
                if (Loot.Main.Position - LocalPlayer.Character.Collision.Position).Magnitude < AutoInteractDistance then
                    fireproximityprompt(Loot.ModulePrompt)
                end
            end
        end
    end
end

local AutoInteractConnection

BringGroup:AddToggle("AutoInteract", {
    Text = "Auto Interact",
    Default = false,
    Callback = function(Value)
        if Value then
            AutoInteractConnection = RunService.Heartbeat:Connect(function()
                if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Collision") then
                    return
                end

                local CurrentRoom = workspace.CurrentRooms[LocalPlayer:GetAttribute("CurrentRoom")]
                if not CurrentRoom then return end

                local Targets = {}

                for _, v in CurrentRoom:GetChildren() do
                    if v:IsA("Folder") then
                        if v.Name == "Assets" then
                            table.insert(Targets, v)

                            if v:FindFirstChild("Blockage") then
                                table.insert(Targets, v.Blockage)
                            end
                            if v:FindFirstChild("Decor") and v.Decor:FindFirstChild("Folder") then
                                table.insert(Targets, v.Decor.Folder)
                            end

                            for _, Assets in v:GetChildren() do
                                if Assets.Name == "StandardDecor" and v:IsA("Folder") then
                                    table.insert(Targets, Assets)
                                end
                            end
                        end

                    elseif v:IsA("Model") then
                        if v.Name == "Sideroom" and v:FindFirstChild("Assets") then 
                            table.insert(Targets, v.Assets)
                        
                        elseif v.Name == "Door" and v:FindFirstChild("Lock") then
                            local Item = HasItem("Key") or LocalPlayer.Character:FindFirstChild("KeyBackdoor")
                            if Item then
                                if (v.Lock.Position - LocalPlayer.Character.Collision.Position).Magnitude < AutoInteractDistance then
                                    fireproximityprompt(v.Lock.UnlockPrompt)
                                end
                            end
                        end
                    end
                end

                for _, Assets in Targets do
                    for _, Root in Assets:GetChildren() do
                        if Root.Name == "Locker_Small" then
                            if Root.Door.ActivateEventPrompt:GetAttribute("Interactions") then
                                FindLoot(Root)
                            else
                                if (Root.Door.Position - LocalPlayer.Character.Collision.Position).Magnitude < AutoInteractDistance then
                                    fireproximityprompt(Root.Door.ActivateEventPrompt)
                                end
                            end

                        elseif Root.Name == "Toolbox" or Root.Name == "ChestBox" or Root.Name == "Toolshed_Small" then
                            if Root.ActivateEventPrompt:GetAttribute("Interactions") then
                                FindLoot(Root)
                            else
                                if (Root.Main.Position - LocalPlayer.Character.Collision.Position).Magnitude < AutoInteractDistance then
                                    fireproximityprompt(Root.ActivateEventPrompt)
                                end
                            end

                        elseif Root.Name == "RoomsLootItem" or Root.Name == "CrucifixOnTheWall" then
                            FindLoot(Root)
                        end
                    end
                end

                InteractWithDrawers()
                InteractWithGoldPiles()
            end)
        else
            -- Disable auto interact
            if AutoInteractConnection then
                AutoInteractConnection:Disconnect()
                AutoInteractConnection = nil
            end
        end
    end
})
BringGroup:AddSlider("AutoInteractDistance", {
    Text = "Auto Interact Distance",
    Default = 10,
    Min = 5,
    Max = 100,
    Rounding = 1,
    Compact = true,
    Suffix = " studs",
    Callback = function(Value)
        AutoInteractDistance = Value
    end
})


























BringGroup:AddButton({
	Text = "Revive",
	Func = function()
		game.ReplicatedStorage.RemotesFolder.Revive:FireServer()
	end,
})

BringGroup:AddButton({
    Text = "Reset Character",
    Func = function()
        local player = game.Players.LocalPlayer
        if player and player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.Health = 0
        end
    end
})

BringGroup:AddButton({
	Text = "Lobby",
	Func = function()
		game.ReplicatedStorage.RemotesFolder.Lobby:FireServer()
	end,
})

BringGroup:AddButton({
	Text = "Play Again",
	Func = function()
		game.ReplicatedStorage.RemotesFolder.PlayAgain:FireServer()
	end,
})

BringGroup:AddButton("bringitems",{
    Text = "Bring Dropped Items",
    Tooltip = "Bring all items found in the dropped folder",
    Func = function()
        local Players = game:GetService('Players')
        local player = Players.LocalPlayer
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:WaitForChild('HumanoidRootPart')

        local drops = workspace:FindFirstChild('Drops')
        if drops then
            for _, drop in pairs(drops:GetChildren()) do
                if drop:IsA('BasePart') then
                    drop.CFrame = hrp.CFrame + Vector3.new(0, 3, 0)
                elseif drop:IsA('Model') then
                    local main = drop.PrimaryPart or drop:FindFirstChildWhichIsA('BasePart')
                    if main then
                        drop:SetPrimaryPartCFrame(hrp.CFrame + Vector3.new(0, 3, 0))
                    end
                end
            end
        else
            warn('drops folder not found')
        end
    end
})

local WALL_DISTANCE = 7
local WALL_SIZE = Vector3.new(12, 12, 12)
local WALL_COLOR = Color3.fromRGB(0, 0, 0)
local WALL_TRANSPARENCY = 1

local function createWallInFrontOfDoor()
    local currentRooms = workspace:FindFirstChild("CurrentRooms")
    if not currentRooms then return end
    local room0 = currentRooms:FindFirstChild("0")
    if not room0 then return end
    local door = room0:FindFirstChild("Door")
    if not door then return end

    local doorCFrame
    if door:IsA("Model") then
        if door.PrimaryPart then
            doorCFrame = door.PrimaryPart.CFrame
        else
            local firstPart = door:FindFirstChildOfClass("Part") or door:FindFirstChildOfClass("MeshPart")
            if firstPart then doorCFrame = firstPart.CFrame else return end
        end
    elseif door:IsA("BasePart") then
        doorCFrame = door.CFrame
    else
        return
    end

    local wallCFrame = doorCFrame * CFrame.new(0, 0, -WALL_DISTANCE) * CFrame.Angles(0, math.rad(90), 0)

    local wall = Instance.new("Part")
    wall.Name = "SpawnedWall"
    wall.Size = WALL_SIZE
    wall.CFrame = wallCFrame
    wall.Color = WALL_COLOR
    wall.Transparency = WALL_TRANSPARENCY
    wall.Material = Enum.Material.Plastic
    wall.TopSurface = Enum.SurfaceType.Smooth
    wall.BottomSurface = Enum.SurfaceType.Smooth
    wall.CanCollide = false
    wall.Anchored = true
    wall.Parent = room0
    return wall
end

local isActive = false
local connection
local screenGui
local runServiceConnection

BringGroup:AddButton("speedrun", { 
    Text = "spreedrun timer", 
    Default = false, 
    Func = function()
        if isActive then
            Library:Notify("already enabled bro", 2)
            return
        end
        isActive = true
        local success, wall = pcall(createWallInFrontOfDoor)
        if not success or not wall then
            isActive = false
            return
        end
        local hasTriggered = false
        connection = wall.Touched:Connect(function()
            if hasTriggered then return end
            hasTriggered = true
            local player = game.Players.LocalPlayer
            if not player then return end
            local playerGui = player:WaitForChild("PlayerGui", 5)
            if not playerGui then return end
            screenGui = Instance.new("ScreenGui", playerGui)
            local textButton = Instance.new("TextButton", screenGui)
            textButton.Size = UDim2.new(0.2, 0, 0.05, 0)
            textButton.Position = UDim2.new(0.4, 0, 0.02, 0)
            textButton.Text = "00:00:00.000"
            textButton.TextSize = 14
            textButton.BackgroundTransparency = 0.5
            textButton.BackgroundColor3 = Color3.new(0, 0, 0)
            textButton.TextColor3 = Color3.new(1, 1, 1)
            local startTime = tick()
            runServiceConnection = game:GetService("RunService").Heartbeat:Connect(function()
                if not textButton or not textButton.Parent then
                    runServiceConnection:Disconnect()
                    return
                end
                local elapsed = tick() - startTime
                local hours = math.floor(elapsed / 3600)
                elapsed = elapsed % 3600
                local minutes = math.floor(elapsed / 60)
                local seconds = math.floor(elapsed % 60)
                local milliseconds = math.floor((elapsed % 1) * 1000)
                textButton.Text = string.format("%02d:%02d:%02d.%03d", hours, minutes, seconds, milliseconds)
            end)
            if connection then
                connection:Disconnect()
                connection = nil
            end
            if wall then
                wall:Destroy()
            end
        end)
    end
})



local RandomStuff = Tabs.Misc:AddLeftGroupbox("The Hotel")
RandomStuff:AddToggle("SilentJammin", { Text = "Mute Jeff's Shop Music", Default = false, Tooltip = "Silences the music in Jeff's shop.", Callback = function(Value)
    LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game.Health.Jam.Playing = not Value
    game.SoundService.Main.Jamming.Enabled = not Value
end })


RandomStuff:AddDivider()

local TheMinesGroup = Tabs.Misc:AddLeftGroupbox("The Mines")

TheMinesGroup:AddToggle("SilentJammin", { Text = "Mute Jeff's Shop Music", Default = false, Tooltip = "Silences the music in Jeff's shop.", Callback = function(Value)
    LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game.Health.Jam.Playing = not Value
    game.SoundService.Main.Jamming.Enabled = not Value
end })

local anchorConnection = nil
local AnchorIdentify = {
    ["I"] = 1,
    ["II"] = 2,
    ["III"] = 3,
    ["IV"] = 4,
    ["V"] = 5,
    ["VI"] = 6,
    ["VII"] = 7,
    ["VIII"] = 8,
    ["IX"] = 9,
    ["X"] = 10
} 

local function SolveAnchor(code, offset)
    return code
end

TheMinesGroup:AddToggle("solveanchor", {
    Text = "Solve Anchor Code",
    Default = false,
    Tooltip = "Shows anchor codes without auto-solving",
    Callback = function(Value)
        if Value then
            Library:Notify("Anchor Code Solver enabled", 2)
            
            -- Find the current room (you may need to adjust 'v' to your room variable)
            local currentRoom = workspace.CurrentRooms -- Adjust this path as needed
            
            anchorConnection = task.spawn(function()
                while Value and not Library.Unloaded and task.wait(1) do
                    local Anchors = {}
                    
                    -- Scan for anchors in current room
                    for _, room in pairs(currentRoom:GetChildren()) do
                        for _, Anchor in pairs(room:GetChildren()) do
                            if Anchor.Name == "MinesAnchor" and not Anchor:GetAttribute("Activated") then
                                if AnchorIdentify[Anchor.Sign.TextLabel.Text] then
                                    Anchors[AnchorIdentify[Anchor.Sign.TextLabel.Text]] = Anchor
                                end
                            end
                        end
                    end
                    
                    if next(Anchors) then
                        local AnchorsIndex = {}
                        for Index in pairs(Anchors) do
                            table.insert(AnchorsIndex, Index)
                        end
                        
                        local NumberIndex = math.min(unpack(AnchorsIndex))
                        local NextAnchor = Anchors[NumberIndex]
                        
                        if NumberIndex > 1 then
                            -- Get code and solve it
                            local success, Code = pcall(function()
                                return LocalPlayer.PlayerGui.MainUI.MainFrame.AnchorHintFrame.Code.Text
                            end)
                            
                            if success and Code then
                                local Offset = tonumber(NextAnchor.Note.SurfaceGui.TextLabel.Text)
                                local Solved = SolveAnchor(Code, Offset)
                                
                                Library:Notify("Anchor " .. NextAnchor.Sign.TextLabel.Text .. " Code: " .. Solved, 3)
                                print("[Anchor Solver] Anchor " .. NextAnchor.Sign.TextLabel.Text .. " code: " .. Solved)
                            end
                        else
                            -- First anchor - just use the hint code directly
                            local success, Code = pcall(function()
                                return LocalPlayer.PlayerGui.MainUI.MainFrame.AnchorHintFrame.Code.Text
                            end)
                            
                            if success and Code then
                                Library:Notify("Anchor " .. NextAnchor.Sign.TextLabel.Text .. " Code: " .. Code, 3)
                                print("[Anchor Solver] Anchor " .. NextAnchor.Sign.TextLabel.Text .. " code: " .. Code)
                            end
                        end
                        
                        -- Wait a bit before checking again to avoid spam
                        task.wait(5)
                    end
                end
            end)
        else
            Library:Notify("Anchor Code Solver disabled", 2)   
            
            -- Stop the connection
            if anchorConnection then
                task.cancel(anchorConnection)
                anchorConnection = nil
            end
        end
    end
})


TheMinesGroup:AddToggle("AntiCheatBypass", {
    Text = "Anti Cheat Bypass",
    Default = false,
    Callback = function(Value)
        if Value then
            local progressPart = Instance.new("Part", workspace)
            progressPart.Anchored = true
            progressPart.CanCollide = false
            progressPart.Name = "vx_acbypass"
            progressPart.Transparency = 1

            Library:Notify("find a ladder and go on it", 7)

            for _, v in pairs(workspace.CurrentRooms:GetDescendants()) do
                if v:IsA("Model") and v.Name == "Ladder" then
                    if not v:FindFirstChild("VelocityX_Highlight") then
                        local hl = Instance.new("Highlight")
                        hl.Name = "VelocityX_Highlight"
                        hl.FillColor = Color3.fromRGB(255, 255, 255)
                        hl.FillTransparency = 0.6
                        hl.OutlineTransparency = 0
                        hl.Adornee = v
                        hl.Parent = v
                    end

                    if not v:FindFirstChild("VelocityX_Billboard") then
                        local bb = Instance.new("BillboardGui")
                        bb.Name = "VelocityX_Billboard"
                        bb.AlwaysOnTop = true
                        bb.Size = UDim2.new(0, 100, 0, 30)
                        bb.StudsOffset = Vector3.new(0, 3, 0)
                        bb.Adornee = v
                        bb.Parent = v

                        local lbl = Instance.new("TextLabel")
                        lbl.Size = UDim2.new(1, 0, 1, 0)
                        lbl.BackgroundTransparency = 1
                        lbl.TextColor3 = Color3.new(1, 0, 0)
                        lbl.TextScaled = true
                        lbl.Font = Enum.Font.Gotham
                        lbl.Text = "Ladder"
                        lbl.TextStrokeTransparency = 0
                        lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
                        lbl.Parent = bb
                    end
                end
            end

            if Script.IsMines and shared.Character then
                shared.Connections["AnticheatBypassTheMines"] =
                    shared.Character:GetAttributeChangedSignal("Climbing"):Connect(function()
                        if not Toggles.AntiCheatBypass or not Toggles.AntiCheatBypass.Value then return end
                        if not shared.Character:GetAttribute("Climbing") then return end

                        task.wait(1)
                        shared.Character:SetAttribute("Climbing", false)

                        Script.Bypassed = true

                        Options.WalkSpeed:SetMax(75)
                        Options.FlySpeed:SetMax(75)

                        Library:Notify("Bypassed the anticheat successfully, it will be gowne when a cutscene gets played", 7)

                        if workspace:FindFirstChild("vx_acbypass") then
                            workspace:FindFirstChild("vx_acbypass"):Destroy()
                        end
                    end)
            end

            if shared.Humanoid then
                shared.Humanoid.MaxSlopeAngle = Options.MaxSlopeAngle.Value
            end
        else
            if workspace:FindFirstChild("vx_acbypass") then
                workspace:FindFirstChild("vx_acbypass"):Destroy()
            end

            for _, v in pairs(workspace.CurrentRooms:GetDescendants()) do
                if v:IsA("Model") and v.Name == "Ladder" then
                    if v:FindFirstChild("VelocityX_Highlight") then v.VelocityX_Highlight:Destroy() end
                    if v:FindFirstChild("VelocityX_Billboard") then v.VelocityX_Billboard:Destroy() end
                end
            end

            if Script.Bypassed and not Script.FakeRevive.Enabled then
                Script.RemotesFolder.ClimbLadder:FireServer()
                Script.Bypassed = false

                Options.WalkSpeed:SetMax(Toggles.SpeedBypass.Value and 75 or (Toggles.EnableJump.Value and 18 or 22))
                Options.FlySpeed:SetMax(Toggles.SpeedBypass.Value and 75 or 22)
            end
        end
    end
})



local HotelMinus = Tabs.Misc:AddRightGroupbox("Hotel -")


HotelMinus:AddToggle("InfRevives", {
    Text = "Infinite Revives",
    Default = false,
    Callback = function(enabled)
        if shared.InfRevivesConnection then
            shared.InfRevivesConnection:Disconnect()
            shared.InfRevivesConnection = nil
        end

        if enabled then
            local Players = game:GetService("Players")
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local player = Players.LocalPlayer
            local bricks = ReplicatedStorage:WaitForChild("Bricks")
            local revive = bricks:WaitForChild("Revive") -- RemoteEvent

            shared.InfRevivesConnection = player:GetAttributeChangedSignal("Alive"):Connect(function()
                if not player:GetAttribute("Alive") then
                    revive:FireServer()
                end
            end)
        end
    end
})



HotelMinus:AddToggle("NoHalt", {
    Text = "No Halt",
    Default = false,
    Callback = function(enabled)
        if enabled then
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local shadeModule = ReplicatedStorage:WaitForChild("ClientModules")
                                             :WaitForChild("EntityModules")
                                             :FindFirstChild("Shade")
            if shadeModule then
                shadeModule.Name = "velocityshade"
            end
        end
    end
})

HotelMinus:AddToggle("NoSeek", {
    Text = "No Seek",
    Default = false,
    Callback = function(enabled)
        if enabled then
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local shadeModule = ReplicatedStorage:WaitForChild("ClientModules")
                                             :WaitForChild("EntityModules")
                                             :FindFirstChild("Seek")
            if shadeModule then
                shadeModule.Name = "velocityseek"
            end
        end
    end
})

HotelMinus:AddDivider()

HotelMinus:AddToggle("Godmode", {
    Text = "Godmode",
    Default = false,
    Callback = function(enabled)
        if enabled and shared.Humanoid and Script.Collision then
            if not AntiGroup.Toggles.CrouchSpoof.Value then
                AntiGroup.Toggles.CrouchSpoof:SetValue(true)
                Library:Notify("Avoid Figure has been automatically enabled for Godmode.", 3)
            end
            shared.Humanoid.HipHeight = 3.01
            task.wait()
            Script.Collision.Position = Script.Collision.Position - Vector3.new(0, 8, 0)
            task.wait()
            shared.Humanoid.HipHeight = 3
            task.spawn(function()
                repeat task.wait() until not HotelMinus.Toggles.Godmode.Value
                shared.Humanoid.HipHeight = 3.01
                task.wait()
                Script.Collision.Position = Script.Collision.Position + Vector3.new(0, 8, 0)
                task.wait()
                shared.Humanoid.HipHeight = 3
            end)
        end
    end
})





local AprilFools2023 = Tabs.Misc:AddLeftGroupbox("April Fools 2023")



local BackDoorStuff = Tabs.Misc:AddLeftGroupbox("Backdoors")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local FloorReplicated = ReplicatedStorage:FindFirstChild("FloorReplicated")
local timerValue = FloorReplicated and FloorReplicated:FindFirstChild("DigitalTimer")

BackDoorStuff:AddToggle("HasteTimer", { 
    Text = "Haste Timer", 
    Default = false, 
    Callback = function(value) 
        if value then
            local playerGui = player:WaitForChild("PlayerGui")
            local screenGui = playerGui:FindFirstChild("HasteTimerGui")
            if not screenGui then
                screenGui = Instance.new("ScreenGui")
                screenGui.Name = "HasteTimerGui"
                screenGui.Parent = playerGui
            end

            local textButton = screenGui:FindFirstChild("TimerButton")
            if not textButton then
                textButton = Instance.new("TextButton")
                textButton.Name = "TimerButton"
                textButton.Size = UDim2.new(0.2, 0, 0.05, 0)
                textButton.Position = UDim2.new(0.4, 0, 0.9, 0) 
                textButton.Text = "00:00:00.000"
                textButton.TextSize = 14
                textButton.BackgroundTransparency = 0.5
                textButton.BackgroundColor3 = Color3.new(0, 0, 0)
                textButton.TextColor3 = Color3.new(1, 1, 1)
                textButton.Parent = screenGui
            end

            local function updateTimer()
                local total = timerValue.Value
                local hours = math.floor(total / 3600)
                local minutes = math.floor((total % 3600) / 60)
                local seconds = total % 60
                textButton.Text = string.format("%02d:%02d:%02d", hours, minutes, seconds)
            end

            updateTimer()

            if not textButton:FindFirstChild("Connection") then
                local conn = timerValue.Changed:Connect(updateTimer)
                conn.Name = "Connection"
                conn.Parent = textButton 
            end
        else
            local screenGui = player:FindFirstChild("PlayerGui"):FindFirstChild("HasteTimerGui")
            if screenGui then
                local button = screenGui:FindFirstChild("TimerButton")
                if button then
                    local conn = button:FindFirstChild("Connection")
                    if conn then
                        conn:Disconnect()
                    end
                end
                screenGui:Destroy()
            end
        end
    end
})



local OutdoorsStuff = Tabs.Misc:AddLeftGroupbox("Great Outdoors")

OutdoorsStuff:AddToggle("InfiniteOxygen", { 
    Text = "Infinite Oxygen", 
    Default = false, 
    Callback = function(value) 
        if value then
            local Players = game:GetService("Players")
            local RunService = game:GetService("RunService")
            local localPlayer = Players.LocalPlayer
            
            if localPlayer.Character then
                local character = localPlayer.Character
                
                character:SetAttribute("Oxygen", 10000000000)
                
                _G.oxygenConnection = RunService.Heartbeat:Connect(function()
                    if character and character.Parent then
                        local currentOxygen = character:GetAttribute("Oxygen")
                        if currentOxygen and currentOxygen < 10000000000 then
                            character:SetAttribute("Oxygen", 10000000000)
                        end
                    end
                end)
            end
        else
            if _G.oxygenConnection then
                _G.oxygenConnection:Disconnect()
                _G.oxygenConnection = nil
            end
        end
    end
})







CreditsTAB = Window:AddTab("Credits", "database")
local CreditsGroupbox = CreditsTAB:AddLeftGroupbox("Credits")
CreditsGroupbox:AddLabel('Owner: Velocity')
CreditsGroupbox:AddLabel('Developer: Velocity')
CreditsGroupbox:AddLabel('<font color="rgb(194,33,177)">its that shrimple</font>')







UISettings = Window:AddTab("UI Settings", "user-round-cog")

local SettingsLeftGroup = UISettings:AddLeftGroupbox("Menu Settings")

local MenuVisibility = SettingsLeftGroup:AddToggle("MenuVisibility", {
    Text = "Show Menu",
    Default = true,
    Tooltip = "Toggle menu visibility",
    Callback = function(Value)
        Library:Toggle(Value)
        if enableNotifications then
            Library:Notify({
                Title = "Menu Visibility",
                Description = Value and "Menu shown" or "Menu hidden",
                Time = notifyDuration,
                SoundId = notificationSoundId > 0 and notificationSoundId or nil
            })
        end
    end
})

MenuVisibility:AddKeyPicker("MenuToggleKey", {
    Default = "End",
    SyncToggleState = true,
    Mode = "Toggle",
    Text = "Menu Toggle",
    NoUI = false
})

SettingsLeftGroup:AddDivider()

SettingsLeftGroup:AddButton({
    Text = "Unload Menu",
    Func = function()
        if enableNotifications then
            Library:Notify({
                Title = "Menu Unload",
                Description = "Unloading menu...",
                Time = notifyDuration,
                SoundId = notificationSoundId > 0 and notificationSoundId or nil
            })
        end
        task.wait(0.3)
        Library:Unload()
    end,
    DoubleClick = true,
    Tooltip = "Unload the menu"
})

local AppearanceGroup = UISettings:AddLeftGroupbox("Appearance")

AppearanceGroup:AddToggle("ShowKeybinds", {
    Text = "Show Keybinds Frame",
    Default = true,
    Tooltip = "Toggle keybinds list visibility",
    Callback = function(Value)
        Library.KeybindFrame.Visible = Value
        if enableNotifications then
            Library:Notify({
                Title = "Keybinds Frame",
                Description = "Keybinds frame " .. (Value and "shown" or "hidden"),
                Time = notifyDuration,
                SoundId = notificationSoundId > 0 and notificationSoundId or nil
            })
        end
    end
})

SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetFolder("VelocityX")
SaveManager:BuildConfigSection(UISettings)

ThemeManager:SetLibrary(Library)
ThemeManager:SetFolder("VelocityX")
ThemeManager:ApplyToTab(UISettings)

local NotificationGroup = UISettings:AddRightGroupbox("Notifications")

local notifyDuration = 3
local enableNotifications = true
local notificationSoundId = 0

local soundPresets = {
    {Name = "None", Id = 0},
    {Name = "Default Notification", Id = 3023237993},
    {Name = "Android Ding", Id = 6205430632},
    {Name = "Error Buzz", Id = 5188022160},
    {Name = "Alert Alarm", Id = 1616678030}
}

NotificationGroup:AddToggle("EnableNotifications", {
    Text = "Enable Notifications",
    Default = true,
    Tooltip = "Toggle whether notifications are shown for actions",
    Callback = function(Value)
        enableNotifications = Value
    end
})

NotificationGroup:AddSlider("NotifyDuration", {
    Text = "Notification Duration (s)",
    Default = 3,
    Min = 1,
    Max = 10,
    Rounding = 0,
    Compact = true,
    Callback = function(Value)
        notifyDuration = Value
        if enableNotifications then
            Library:Notify({
                Title = "Notification Settings",
                Description = "Notification duration set to " .. Value .. " seconds",
                Time = Value,
                SoundId = notificationSoundId > 0 and notificationSoundId or nil
            })
        end
    end
})

local soundInput = NotificationGroup:AddInput("NotificationSoundId", {
    Text = "Notification Sound ID",
    Default = "0",
    Numeric = true,
    Finished = true,
    Tooltip = "Roblox sound ID for all notifications (0 for none)",
    Callback = function(Value)
        notificationSoundId = tonumber(Value) or 0
    end
})

NotificationGroup:AddDropdown("SoundPreset", {
    Text = "Sound Preset",
    Default = "None",
    Values = {"None", "Default Notification", "Android Ding", "Error Buzz", "Alert Alarm"},
    Callback = function(Value)
        for _, preset in ipairs(soundPresets) do
            if preset.Name == Value then
                notificationSoundId = preset.Id
                soundInput:SetValue(tostring(preset.Id))
                break
            end
        end
    end
})

NotificationGroup:AddButton({
    Text = "Test Notification",
    Func = function()
        Library:Notify({
            Title = "Test Notification",
            Description = "This is a test notification!",
            Time = notifyDuration,
            SoundId = notificationSoundId > 0 and notificationSoundId or nil
        })
    end
})

Library:SetWatermarkVisibility(true)

local FrameTimer = tick()
local FrameCounter = 0
local FPS = 60

local WatermarkConnection = game:GetService("RunService").RenderStepped:Connect(function()
    FrameCounter = FrameCounter + 1
    if tick() - FrameTimer >= 1 then
        FPS = FrameCounter
        FrameTimer = tick()
        FrameCounter = 0
    end
    Library:SetWatermark(("Velocity X | %s FPS | By Velocity | %s ping | v2.0 "):format(
        math.floor(FPS),
        math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
    ))
end)
