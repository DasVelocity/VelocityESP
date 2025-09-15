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

						 Created by [Anonymous]
				Contributors: [Anonymous Contributors]
--]]

local VERSION = "2.0.2";
local debug_print = if getgenv().ESP_DEBUG then (function(...) print("[ESP Library]", ...) end) else (function() end);
local debug_warn  = if getgenv().ESP_DEBUG then (function(...) warn("[ESP Library]", ...) end) else (function() end);
local debug_error = if getgenv().ESP_DEBUG then (function(...) error("[ESP Library] " .. table.concat({ ... }, " ")) end) else (function() end);

if getgenv().ESP then
	debug_warn("Already Loaded.")
	return getgenv().ESP
end

export type TracerESPSettings = {
	Enabled: boolean,
	Color: Color3?,
	Thickness: number?,
	Transparency: number?,
	From: ("Top" | "Bottom" | "Center" | "Mouse")?,
}

export type ArrowESPSettings = {
	Enabled: boolean,
	Color: Color3?,
	CenterOffset: number?,
}

export type ESPSettings = {
	Name: string?,
	Model: Instance,
	TextModel: Instance?,
	Visible: boolean?,
	Color: Color3?,
	MaxDistance: number?,
	StudsOffset: Vector3?,
	TextSize: number?,
	ESPType: ("Text" | "SphereAdornment" | "CylinderAdornment" | "Adornment" | "SelectionBox" | "Highlight")?,
	Thickness: number?,
	Transparency: number?,
	SurfaceColor: Color3?,
	FillColor: Color3?,
	OutlineColor: Color3?,
	FillTransparency: number?,
	OutlineTransparency: number?,
	Tracer: TracerESPSettings?,
	Arrow: ArrowESPSettings?,
	OnDestroy: BindableEvent?,
	OnDestroyFunc: (() -> nil)?,
}

--// Executor Variables \\--
local cloneref = getgenv().cloneref or function(inst) return inst; end
local getui;

--// Services \\--
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local CoreGui = cloneref(game:GetService("CoreGui"))

-- // Variables // --
local tablefreeze = function<T>(provided_table: T): T
	local proxy = {}
	local data = table.clone(provided_table)
	local mt = {
		__index = function(table, key)
			return data[key]
		end,
		__newindex = function(table, key, value)
			-- nope --
		end
	}
	return setmetatable(proxy, mt) :: typeof(provided_table)
end

--// Functions \\--
local function GetPivot(Instance: Bone | Attachment | CFrame | PVInstance)
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

local function RandomString(length: number?)
	length = tonumber(length) or math.random(10, 20)
	local array = {}
	for i = 1, length do
		array[i] = string.char(math.random(32, 126))
	end
	return table.concat(array)
end

-- // Instances // --
local InstancesLib = {
	Create = function(instanceType, properties)
		assert(typeof(instanceType) == "string", "Argument #1 must be a string.")
		assert(typeof(properties) == "table", "Argument #2 must be a table.")
		local instance = Instance.new(instanceType)
		for name, val in pairs(properties) do
			if name == "Parent" then
				continue
			end
			instance[name] = val
		end
		if properties["Parent"] ~= nil then
			instance["Parent"] = properties["Parent"]
		end
		return instance
	end,
	TryGetProperty = function(instance, propertyName)
		assert(typeof(instance) == "Instance", "Argument #1 must be an Instance.")
		assert(typeof(propertyName) == "string", "Argument #2 must be a string.")
		local success, property = pcall(function()
			return instance[propertyName]
		end)
		return if success then property else nil;
	end,
	FindPrimaryPart = function(instance)
		if typeof(instance) ~= "Instance" then
			return nil
		end
		return (instance:IsA("Model") and instance.PrimaryPart or nil)
			or instance:FindFirstChildWhichIsA("BasePart")
			or instance:FindFirstChildWhichIsA("UnionOperation")
			or instance;
	end,
	DistanceFrom = function(inst, from)
		if not (inst and from) then
			return 9e9;
		end
		local position = if typeof(inst) == "Instance" then GetPivot(inst).Position else inst;
		local fromPosition = if typeof(from) == "Instance" then GetPivot(from).Position else from;
		return (fromPosition - position).Magnitude;
	end
}

--// HiddenUI test \\--
do
	local testGui = Instance.new("ScreenGui")
	local successful = pcall(function()
		testGui.Parent = CoreGui;
	end)
	if not successful then
		debug_warn("CoreGUI is not accessible!")
		getui = function() return Players.LocalPlayer.PlayerGui; end;
	else
		getui = function() return CoreGui end;
	end
	testGui:Destroy()
end

--// GUI \\--
local ActiveFolder = InstancesLib.Create("Folder", {
	Parent = getui(),
	Name = RandomString()
})

local StorageFolder = InstancesLib.Create("Folder", {
	Parent = if typeof(game) == "userdata" then Players.Parent else game,
	Name = RandomString()
})

local MainGUI = InstancesLib.Create("ScreenGui", {
	Parent = getui(),
	Name = RandomString(),
	IgnoreGuiInset = true,
	ResetOnSpawn = false,
	ClipToDeviceSafeArea = false,
	DisplayOrder = 999_999
})

local BillboardGUI = InstancesLib.Create("ScreenGui", {
	Parent = getui(),
	Name = RandomString(),
	IgnoreGuiInset = true,
	ResetOnSpawn = false,
	ClipToDeviceSafeArea = false,
	DisplayOrder = 999_999
})

-- // Library // --
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
		Billboards = true,
		Highlighters = true,
		Distance = true,
		Tracers = true,
		Arrows = true,
		Font = Enum.Font.Gotham
	},
	RainbowHueSetup = 0,
	RainbowHue = 0,
	RainbowStep = 0,
	RainbowColor = Color3.new()
}

-- // Player Variables // --
local character: Model
local rootPart: Part?
local camera: Camera = workspace.CurrentCamera

local function worldToViewport(...)
	camera = (camera or workspace.CurrentCamera);
	if camera == nil then
		return Vector2.new(0, 0), false
	end
	return camera:WorldToViewportPoint(...)
end

local function UpdatePlayerVariables(newCharacter: any, force: boolean?)
	if force ~= true and Library.GlobalConfig.IgnoreCharacter == true then
		debug_warn("UpdatePlayerVariables: IgnoreCharacter enabled.")
		return
	end
	debug_print("Updating Player Variables...")
	character = newCharacter or Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait();
	rootPart =
		character:WaitForChild("HumanoidRootPart", 2.5)
		or character:WaitForChild("UpperTorso", 2.5)
		or character:WaitForChild("Torso", 2.5)
		or character.PrimaryPart
		or character:WaitForChild("Head", 2.5);
end
task.spawn(UpdatePlayerVariables, nil, true);

--// Library Functions \\--
function Library:Clear()
	if Library.Destroyed == true then
		return
	end
	for _, ESP in pairs(Library.ESP) do
		if not ESP then continue end
		ESP:Destroy()
	end
end

function Library:Destroy()
	if Library.Destroyed == true then
		return
	end
	Library.Destroyed = true;
	Library:Clear();
	ActiveFolder:Destroy();
	StorageFolder:Destroy();
	MainGUI:Destroy();
	BillboardGUI:Destroy();
	for _, connection in Library.Connections do
		if not connection.Connected then
			continue
		end
		connection:Disconnect()
	end
	table.clear(Library.Connections)
	getgenv().ESP = nil;
	debug_print("Unloaded!")
end

--// Type Checks \\--
local AllowedTracerFrom = {
	top = true,
	bottom = true,
	center = true,
	mouse = true,
}

local AllowedESPType = {
	text = true,
	sphereadornment = true,
	cylinderadornment = true,
	adornment = true,
	selectionbox = true,
	highlight = true,
}

--// ESP Instances \\--
function TracerCreate(espSettings: TracerESPSettings, instanceName: string?)
	if Library.Destroyed == true then
		debug_warn("Library is destroyed, please reload it.")
		return
	end
	if not espSettings then
		espSettings = {}
	end
	if espSettings.Enabled ~= true then
		debug_warn("Tracer is not enabled.")
		return
	end
	debug_print("Creating Tracer...")
	espSettings.Color = typeof(espSettings.Color) == "Color3" and espSettings.Color or Color3.new()
	espSettings.Thickness = typeof(espSettings.Thickness) == "number" and espSettings.Thickness or 2
	espSettings.Transparency = typeof(espSettings.Transparency) == "number" and espSettings.Transparency or 0
	espSettings.From = string.lower(typeof(espSettings.From) == "string" and espSettings.From or "bottom")
	if AllowedTracerFrom[espSettings.From] == nil then
		espSettings.From = "bottom"
	end
	local Path2D = InstancesLib.Create("Path2D", {
		Parent = MainGUI,
		Name = if typeof(instanceName) == "string" then instanceName else "Tracer",
		Closed = true,
		Color3 = espSettings.Color,
		Thickness = espSettings.Thickness,
		Transparency = espSettings.Transparency,
	})
	local function UpdateTracer(from: Vector2, to: Vector2)
		Path2D:SetControlPoints({
			Path2DControlPoint.new(UDim2.fromOffset(from.X, from.Y)),
			Path2DControlPoint.new(UDim2.fromOffset(to.X, to.Y))
		})
	end
	local data = {
		From = typeof(espSettings.From) ~= "Vector2" and UDim2.fromOffset(0, 0) or UDim2.fromOffset(espSettings.From.X, espSettings.From.Y),
		To = typeof(espSettings.To) ~= "Vector2" and UDim2.fromOffset(0, 0) or UDim2.fromOffset(espSettings.To.X, espSettings.To.Y),
		Visible = true,
		Color3 = espSettings.Color,
		Thickness = espSettings.Thickness,
		Transparency = espSettings.Transparency,
	}
	UpdateTracer(data.From, data.To);
	local proxy = {}
	local Tracer = {
		__newindex = function(table, key, value)
			if not Path2D then
				return
			end
			if key == "From" then
				assert(typeof(value) == "Vector2", tostring(key) .. "; expected Vector2, got " .. typeof(value))
				UpdateTracer(value, data.To)
			elseif key == "To" then
				assert(typeof(value) == "Vector2", tostring(key) .. "; expected Vector2, got " .. typeof(value))
				UpdateTracer(data.From, value)
			elseif key == "Transparency" or key == "Thickness" then
				assert(typeof(value) == "number", tostring(key) .. "; expected number, got " .. typeof(value))
				Path2D[key] = value
			elseif key == "Color3" then
				assert(typeof(value) == "Color3", tostring(key) .. "; expected Color3, got " .. typeof(value))
				Path2D.Color3 = value
			elseif key == "Visible" then
				assert(typeof(value) == "boolean", tostring(key) .. "; expected boolean, got " .. typeof(value))
				Path2D.Parent = if value then MainGUI else StorageFolder;
			end
			data[key] = value
		end,
		__index = function(table, key)
			if not Path2D then
				return nil
			end
			if key == "Destroy" or key == "Delete" then
				return function()
					Path2D:SetControlPoints({ });
					Path2D:Destroy();
					Path2D = nil;
				end
			end
			return data[key]
		end,
	}
	debug_print("Tracer created.")
	return setmetatable(proxy, Tracer) :: typeof(data)
end

function Library:Add(espSettings: ESPSettings)
	if Library.Destroyed == true then
		debug_warn("Library is destroyed, please reload it.")
		return
	end
	assert(typeof(espSettings) == "table", "espSettings; expected table, got " .. typeof(espSettings))
	assert(typeof(espSettings.Model) == "Instance", "espSettings.Model; expected Instance, got " .. typeof(espSettings.Model))
	if not espSettings.ESPType then
		espSettings.ESPType = "Highlight"
	end
	assert(typeof(espSettings.ESPType) == "string", "espSettings.ESPType; expected string, got " .. typeof(espSettings.ESPType))
	espSettings.ESPType = string.lower(espSettings.ESPType)
	assert(AllowedESPType[espSettings.ESPType] == true, "espSettings.ESPType; invalid ESPType")
	espSettings.Name = if typeof(espSettings.Name) == "string" then espSettings.Name else espSettings.Model.Name;
	espSettings.TextModel = if typeof(espSettings.TextModel) == "Instance" then espSettings.TextModel else espSettings.Model;
	espSettings.Visible = if typeof(espSettings.Visible) == "boolean" then espSettings.Visible else true;
	espSettings.Color = if typeof(espSettings.Color) == "Color3" then espSettings.Color else Color3.new();
	espSettings.MaxDistance = if typeof(espSettings.MaxDistance) == "number" then espSettings.MaxDistance else 5000;
	espSettings.StudsOffset = if typeof(espSettings.StudsOffset) == "Vector3" then espSettings.StudsOffset else Vector3.new();
	espSettings.TextSize = if typeof(espSettings.TextSize) == "number" then espSettings.TextSize else 16;
	espSettings.Thickness = if typeof(espSettings.Thickness) == "number" then espSettings.Thickness else 0.1;
	espSettings.Transparency = if typeof(espSettings.Transparency) == "number" then espSettings.Transparency else 0.65;
	espSettings.SurfaceColor = if typeof(espSettings.SurfaceColor) == "Color3" then espSettings.SurfaceColor else Color3.new();
	espSettings.FillColor = if typeof(espSettings.FillColor) == "Color3" then espSettings.FillColor else Color3.new();
	espSettings.OutlineColor = if typeof(espSettings.OutlineColor) == "Color3" then espSettings.OutlineColor else Color3.new(1, 1, 1);
	espSettings.FillTransparency = if typeof(espSettings.FillTransparency) == "number" then espSettings.FillTransparency else 0.65;
	espSettings.OutlineTransparency = if typeof(espSettings.OutlineTransparency) == "number" then espSettings.OutlineTransparency else 0;
	espSettings.Tracer = if typeof(espSettings.Tracer) == "table" then espSettings.Tracer else { Enabled = false };
	espSettings.Arrow = if typeof(espSettings.Arrow) == "table" then espSettings.Arrow else { Enabled = false };
	local ESP = {
		Index = RandomString(),
		OriginalSettings = tablefreeze(espSettings),
		CurrentSettings = espSettings,
		Hidden = false,
		Deleted = false,
		Connections = {} :: { RBXScriptConnection },
		RenderThread = nil :: thread?
	}
	debug_print("Creating ESP...", ESP.Index, "-", ESP.CurrentSettings.Name)
	local Billboard = InstancesLib.Create("BillboardGui", {
		Parent = BillboardGUI,
		Name = ESP.Index,
		Enabled = true,
		ResetOnSpawn = false,
		AlwaysOnTop = true,
		Size = UDim2.new(0, 100, 0, 30),
		Adornee = ESP.CurrentSettings.TextModel or ESP.CurrentSettings.Model,
		StudsOffset = ESP.CurrentSettings.StudsOffset or Vector3.new(0, 3, 0),
	})
	local BillboardText = InstancesLib.Create("TextLabel", {
		Parent = Billboard,
		Name = "ESP_Label",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		TextColor3 = Color3.new(1, 0, 0),
		TextScaled = true,
		Font = Enum.Font.Gotham,
		Text = ESP.CurrentSettings.Name,
		TextStrokeTransparency = 0,
		TextStrokeColor3 = Color3.new(0, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
	})
	local Highlighter, IsAdornment = nil, not not string.match(string.lower(ESP.OriginalSettings.ESPType), "adornment")
	debug_print("Creating Highlighter...", ESP.OriginalSettings.ESPType, IsAdornment)
	if IsAdornment then
		local _, ModelSize = nil, nil
		if ESP.CurrentSettings.Model:IsA("Model") then
			_, ModelSize = ESP.CurrentSettings.Model:GetBoundingBox()
		else
			if not InstancesLib.TryGetProperty(ESP.CurrentSettings.Model, "Size") then
				local prim = InstancesLib.FindPrimaryPart(ESP.CurrentSettings.Model)
				if not InstancesLib.TryGetProperty(prim, "Size") then
					debug_print("Couldn't get model size, switching to Highlight.", ESP.Index, "-", ESP.CurrentSettings.Name)
					espSettings.ESPType = "Highlight"
					return Library:Add(espSettings)
				end
				ModelSize = prim.Size
			else
				ModelSize = ESP.CurrentSettings.Model.Size
			end
		end
		if ESP.OriginalSettings.ESPType == "sphereadornment" then
			Highlighter = InstancesLib.Create("SphereHandleAdornment", {
				Parent = ActiveFolder,
				Name = ESP.Index,
				Adornee = ESP.CurrentSettings.Model,
				AlwaysOnTop = true,
				ZIndex = 10,
				Radius = ModelSize.X * 1.085,
				CFrame = CFrame.new() * CFrame.Angles(math.rad(90), 0, 0),
				Color3 = ESP.CurrentSettings.Color or Color3.new(),
				Transparency = ESP.CurrentSettings.Transparency or 0.65,
			})
		elseif ESP.OriginalSettings.ESPType == "cylinderadornment" then
			Highlighter = InstancesLib.Create("CylinderHandleAdornment", {
				Parent = ActiveFolder,
				Name = ESP.Index,
				Adornee = ESP.CurrentSettings.Model,
				AlwaysOnTop = true,
				ZIndex = 10,
				Height = ModelSize.Y * 2,
				Radius = ModelSize.X * 1.085,
				CFrame = CFrame.new() * CFrame.Angles(math.rad(90), 0, 0),
				Color3 = ESP.CurrentSettings.Color or Color3.new(),
				Transparency = ESP.CurrentSettings.Transparency or 0.65,
			})
		else
			Highlighter = InstancesLib.Create("BoxHandleAdornment", {
				Parent = ActiveFolder,
				Name = ESP.Index,
				Adornee = ESP.CurrentSettings.Model,
				AlwaysOnTop = true,
				ZIndex = 10,
				Size = ModelSize,
				Color3 = ESP.CurrentSettings.Color or Color3.new(),
				Transparency = ESP.CurrentSettings.Transparency or 0.65,
			})
		end
	elseif ESP.OriginalSettings.ESPType == "selectionbox" then
		Highlighter = InstancesLib.Create("SelectionBox", {
			Parent = ActiveFolder,
			Name = ESP.Index,
			Adornee = ESP.CurrentSettings.Model,
			Color3 = ESP.CurrentSettings.Color or Color3.new(),
			LineThickness = ESP.CurrentSettings.Thickness or 0.1,
			SurfaceColor3 = ESP.CurrentSettings.SurfaceColor or Color3.new(),
			SurfaceTransparency = ESP.CurrentSettings.Transparency or 0.65,
		})
	elseif ESP.OriginalSettings.ESPType == "highlight" then
		Highlighter = InstancesLib.Create("Highlight", {
			Parent = ActiveFolder,
			Name = ESP.Index,
			Adornee = ESP.CurrentSettings.Model,
			FillColor = ESP.CurrentSettings.FillColor or Color3.fromRGB(255, 255, 0),
			OutlineColor = Color3.new(1, 1, 1),
			FillTransparency = ESP.CurrentSettings.FillTransparency or 0.6,
			OutlineTransparency = ESP.CurrentSettings.OutlineTransparency or 0,
		})
	end
	local Tracer = if typeof(ESP.OriginalSettings.Tracer) == "table" then TracerCreate(ESP.CurrentSettings.Tracer, ESP.Index) else nil;
	local Arrow = nil;
	if typeof(ESP.OriginalSettings.Arrow) == "table" then
		debug_print("Creating Arrow...", ESP.Index, "-", ESP.CurrentSettings.Name)
		Arrow = InstancesLib.Create("Frame", {
			Parent = MainGUI,
			Name = ESP.Index,
			Size = UDim2.new(0, 40, 0, 40),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		})
		local Triangle = InstancesLib.Create("ImageLabel", {
			Parent = Arrow,
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Image = "rbxassetid://0", -- No image, using UICorner and UIStroke for shape
			ImageTransparency = 1,
		})
		local Corner = InstancesLib.Create("UICorner", {
			Parent = Triangle,
			CornerRadius = UDim.new(0, 8),
		})
		local Stroke = InstancesLib.Create("UIStroke", {
			Parent = Triangle,
			Color = ESP.CurrentSettings.Arrow.Color or Color3.fromRGB(255, 255, 0),
			Thickness = 2,
			Transparency = 0,
		})
		local Points = {
			Vector2.new(0, -20), -- Top
			Vector2.new(-20, 20), -- Bottom left
			Vector2.new(20, 20), -- Bottom right
		}
		local function UpdateTriangle()
			Triangle.Position = UDim2.new(0.5, 0, 0.5, 0)
			Triangle.Size = UDim2.new(0, 40, 0, 40)
		end
		UpdateTriangle()
		ESP.CurrentSettings.Arrow.CenterOffset = if typeof(ESP.CurrentSettings.Arrow.CenterOffset) == "number" then ESP.CurrentSettings.Arrow.CenterOffset else 300;
	end
	function ESP:Destroy()
		if ESP.Deleted == true then
			debug_warn("ESP Instance is already deleted.")
			return;
		end
		debug_print("Deleting ESP...", ESP.Index, "-", ESP.CurrentSettings.Name)
		ESP.Deleted = true
		if ESP.RenderThread then
			debug_print("Stopping render coroutine", ESP.Index, "-", ESP.CurrentSettings.Name)
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
			if not connection.Connected then
				continue
			end
			connection:Disconnect()
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
	local function Show(forceShow: boolean?)
		if not (ESP and ESP.Deleted ~= true) then return end
		if forceShow ~= true and not ESP.Hidden then
			return
		end
		ESP.Hidden = false;
		Billboard.Enabled = true;
		if Highlighter then
			Highlighter.Adornee = ESP.CurrentSettings.Model;
			Highlighter.Parent = ActiveFolder;
		end
		if Tracer then
			Tracer.Visible = true;
		end
		if Arrow then
			Arrow.Visible = true;
		end
	end
	local function Hide(forceHide: boolean?)
		if not (ESP and ESP.Deleted ~= true) then return end
		if forceHide ~= true and ESP.Hidden then
			return
		end
		ESP.Hidden = true
		Billboard.Enabled = false;
		if Highlighter then
			Highlighter.Adornee = nil;
			Highlighter.Parent = StorageFolder;
		end
		if Tracer then
			Tracer.Visible = false;
		end
		if Arrow then
			Arrow.Visible = false;
		end
	end
	function ESP:Show(force: boolean?)
		ESP.CurrentSettings.Visible = true
		Show(force);
	end
	function ESP:Hide(force: boolean?)
		if not (ESP and ESP.CurrentSettings and ESP.Deleted ~= true) then return end
		ESP.CurrentSettings.Visible = false
		Hide(force);
	end
	function ESP:ToggleVisibility(force: boolean?)
		ESP.CurrentSettings.Visible = not ESP.CurrentSettings.Visible
		if ESP.CurrentSettings.Visible then
			Show(force);
		else
			Hide(force);
		end
	end
	function ESP:Render()
		if not (ESP and ESP.CurrentSettings and ESP.Deleted ~= true) then return end
		if
			ESP.CurrentSettings.Visible == false or
			not camera or
			(if Library.GlobalConfig.IgnoreCharacter == true then false else not rootPart)
		then
			Hide()
			return
		end
		if not ESP.CurrentSettings.ModelRoot then
			ESP.CurrentSettings.ModelRoot = InstancesLib.FindPrimaryPart(ESP.CurrentSettings.Model)
		end
		local screenPos, isOnScreen = worldToViewport(
			GetPivot(ESP.CurrentSettings.ModelRoot or ESP.CurrentSettings.Model).Position
		)
		local distanceFromPlayer = InstancesLib.DistanceFrom(
			(ESP.CurrentSettings.ModelRoot or ESP.CurrentSettings.Model),
			(if Library.GlobalConfig.IgnoreCharacter == true then (camera or rootPart) else rootPart)
		)
		if distanceFromPlayer > ESP.CurrentSettings.MaxDistance then
			Hide()
			return
		end
		if Arrow then
			Arrow.Visible = Library.GlobalConfig.Arrows == true and ESP.CurrentSettings.Arrow.Enabled == true and (isOnScreen ~= true)
			if Arrow.Visible then
				local screenSize = camera.ViewportSize
				local centerPos = Vector2.new(screenSize.X / 2, screenSize.Y / 2)
				local partPos = Vector2.new(screenPos.X, screenPos.Y)
				local IsInverted = screenPos.Z <= 0
				local invert = (IsInverted and -1 or 1)
				local direction = (partPos - centerPos)
				local arctan = math.atan2(direction.Y, direction.X)
				local angle = math.deg(arctan) + 90
				local distance = (ESP.CurrentSettings.Arrow.CenterOffset * 0.001) * screenSize.Y
				Arrow.Rotation = angle + 180 * (IsInverted and 0 or 1)
				Arrow.Position = UDim2.new(
					0,
					centerPos.X + (distance * math.cos(arctan) * invert),
					0,
					centerPos.Y + (distance * math.sin(arctan) * invert)
				)
				if Arrow:FindFirstChild("ImageLabel") then
					Arrow.ImageLabel.ImageColor3 =
						if Library.GlobalConfig.Rainbow then Library.RainbowColor else ESP.CurrentSettings.Arrow.Color;
				end
			end
		end
		if isOnScreen == false then
			Hide()
			return
		else Show() end
		if Tracer then
			Tracer.Visible = Library.GlobalConfig.Tracers == true and ESP.CurrentSettings.Tracer.Enabled == true;
			if Tracer.Visible then
				if ESP.CurrentSettings.Tracer.From == "mouse" then
					local mousePos = UserInputService:GetMouseLocation()
					Tracer.From = Vector2.new(mousePos.X, mousePos.Y)
				elseif ESP.CurrentSettings.Tracer.From == "top" then
					Tracer.From = Vector2.new(camera.ViewportSize.X / 2, 0)
				elseif ESP.CurrentSettings.Tracer.From == "center" then
					Tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
				else
					Tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
				end
				Tracer.To = Vector2.new(screenPos.X, screenPos.Y)
				Tracer.Transparency = ESP.CurrentSettings.Tracer.Transparency
				Tracer.Thickness = ESP.CurrentSettings.Tracer.Thickness
				Tracer.Color3 = Library.GlobalConfig.Rainbow and Library.RainbowColor
					or ESP.CurrentSettings.Tracer.Color
			end
		end
		if Billboard then
			Billboard.Enabled = Library.GlobalConfig.Billboards == true;
			if Billboard.Enabled then
				if Library.GlobalConfig.Distance then
					BillboardText.Text = string.format(
						'%s\n<font size="%d">[%s studs]</font>',
						ESP.CurrentSettings.Name,
						ESP.CurrentSettings.TextSize - 3,
						math.floor(distanceFromPlayer)
					)
				else
					BillboardText.Text = ESP.CurrentSettings.Name
				end
				BillboardText.Font = Library.GlobalConfig.Font
				BillboardText.TextColor3 =
					if Library.GlobalConfig.Rainbow then Library.RainbowColor else ESP.CurrentSettings.Color;
				BillboardText.TextSize = ESP.CurrentSettings.TextSize
			end
		end
		if Highlighter then
			Highlighter.Parent = if Library.GlobalConfig.Highlighters == true then ActiveFolder else StorageFolder;
			Highlighter.Adornee = if Library.GlobalConfig.Highlighters == true then ESP.CurrentSettings.Model else nil;
			if Highlighter.Adornee then
				if IsAdornment then
					Highlighter.Color3 = Library.GlobalConfig.Rainbow and Library.RainbowColor or ESP.CurrentSettings.Color
					Highlighter.Transparency = ESP.CurrentSettings.Transparency
				elseif ESP.OriginalSettings.ESPType == "selectionbox" then
					Highlighter.Color3 = Library.GlobalConfig.Rainbow and Library.RainbowColor or ESP.CurrentSettings.Color
					Highlighter.LineThickness = ESP.CurrentSettings.Thickness
					Highlighter.SurfaceColor3 = ESP.CurrentSettings.SurfaceColor
					Highlighter.SurfaceTransparency = ESP.CurrentSettings.Transparency
				else
					Highlighter.FillColor =
						if Library.GlobalConfig.Rainbow then Library.RainbowColor else ESP.CurrentSettings.FillColor;
					Highlighter.OutlineColor =
						if Library.GlobalConfig.Rainbow then Library.RainbowColor else ESP.CurrentSettings.OutlineColor;
					Highlighter.FillTransparency = ESP.CurrentSettings.FillTransparency
					Highlighter.OutlineTransparency = ESP.CurrentSettings.OutlineTransparency
				end
			end
		end
	end
	if not ESP.OriginalSettings.Visible then
		Hide()
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

table.insert(Library.Connections, workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	camera = workspace.CurrentCamera;
end))
table.insert(Library.Connections, Players.LocalPlayer.CharacterAdded:Connect(UpdatePlayerVariables))
table.insert(Library.Connections, RunService.RenderStepped:Connect(function(Delta)
	Library.RainbowStep = Library.RainbowStep + Delta
	if Library.RainbowStep >= (1 / 60) then
		Library.RainbowStep = 0
		Library.RainbowHueSetup = Library.RainbowHueSetup + (1 / 400)
		if Library.RainbowHueSetup > 1 then
			Library.RainbowHueSetup = 0
		end
		Library.RainbowHue = Library.RainbowHueSetup
		Library.RainbowColor = Color3.fromHSV(Library.RainbowHue, 0.8, 1)
	end
end))
table.insert(Library.Connections, RunService.RenderStepped:Connect(function()
	for Index, ESP in Library.ESP do
		if not (ESP and ESP.CurrentSettings and ESP.Deleted ~= true) then
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

debug_print("Loaded! (" .. tostring(VERSION) ..")")
getgenv().ESP = Library
return Library

-- Ambush ESP Implementation
local VisualsGroup = {
	AddToggle = function(name, settings)
		return {
			Name = name,
			Text = settings.Text,
			Default = settings.Default,
			Tooltip = settings.Tooltip,
			Callback = settings.Callback
		}
	}
}

VisualsGroup:AddToggle("AmbushESP", {
	Text = "Ambush ESP",
	Default = false,
	Tooltip = "Shows Ambush through walls",
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
					hl.FillColor = Color3.fromRGB(255, 255, 0)
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
})
