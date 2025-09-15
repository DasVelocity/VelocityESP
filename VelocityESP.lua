--!nocheck
--!nolint UnknownGlobal

local VERSION = "1.0.0";

local PresetColors = {
	["red"] = Color3.new(1, 0, 0),
	["green"] = Color3.new(0, 1, 0),
	["blue"] = Color3.new(0, 0, 1),
	["yellow"] = Color3.new(1, 1, 0),
	["orange"] = Color3.new(1, 0.5, 0),
	["purple"] = Color3.new(0.5, 0, 1),
	["pink"] = Color3.new(1, 0.75, 0.8),
	["brown"] = Color3.new(0.65, 0.16, 0.16),
	["gray"] = Color3.new(0.5, 0.5, 0.5),
	["black"] = Color3.new(0, 0, 0),
	["white"] = Color3.new(1, 1, 1),
	["cyan"] = Color3.new(0, 1, 1),
	["magenta"] = Color3.new(1, 0, 1),
	["lime"] = Color3.new(0.5, 1, 0),
	["navy"] = Color3.new(0, 0, 0.5),
	["teal"] = Color3.new(0, 0.5, 0.5),
	["maroon"] = Color3.new(0.5, 0, 0),
	["olive"] = Color3.new(0.5, 0.5, 0),
	["darkred"] = Color3.new(0.8, 0, 0),
	["lightblue"] = Color3.new(0.5, 0.8, 1),
	["darkgreen"] = Color3.new(0, 0.5, 0),
	["gold"] = Color3.new(1, 0.84, 0),
	["silver"] = Color3.new(0.75, 0.75, 0.75),
	["crimson"] = Color3.new(0.86, 0.08, 0.24),
	["indigo"] = Color3.new(0.29, 0, 0.51),
	["violet"] = Color3.new(0.93, 0.51, 0.93),
	["turquoise"] = Color3.new(0.68, 0.93, 0.93),
	["coral"] = Color3.new(1, 0.5, 0.31),
	["khaki"] = Color3.new(0.94, 0.9, 0.55),
	["plum"] = Color3.new(0.87, 0.63, 0.87),
	["orchid"] = Color3.new(0.85, 0.44, 0.84),
	["salmon"] = Color3.new(0.98, 0.5, 0.45),
	["seagreen"] = Color3.new(0.18, 0.55, 0.34),
	["sienna"] = Color3.new(0.63, 0.32, 0.18),
	["tan"] = Color3.new(0.82, 0.71, 0.55),
	["thistle"] = Color3.new(0.85, 0.75, 0.85),
	["tomato"] = Color3.new(1, 0.39, 0.28),
	["wheat"] = Color3.new(0.96, 0.87, 0.7),
	["aliceblue"] = Color3.new(0.94, 0.97, 1),
	["antiquewhite"] = Color3.new(0.98, 0.92, 0.84),
	["aqua"] = Color3.new(0, 1, 1),
	["aquamarine"] = Color3.new(0.5, 1, 0.83),
	["azure"] = Color3.new(0.94, 1, 1),
	["beige"] = Color3.new(0.96, 0.96, 0.86),
	["bisque"] = Color3.new(1, 0.89, 0.77),
	["blanchedalmond"] = Color3.new(1, 0.92, 0.81),
	["blueviolet"] = Color3.new(0.63, 0.13, 0.94),
	["cadetblue"] = Color3.new(0.37, 0.63, 0.76),
	["chartreuse"] = Color3.new(0.5, 1, 0),
	["chocolate"] = Color3.new(0.82, 0.41, 0.21),
	["cornflowerblue"] = Color3.new(0.39, 0.58, 0.93),
}

local debug_print = if getgenv().GrokESP_DEBUG then (function(...) print("[Grok ESP]", ...) end) else (function() end);
local debug_warn  = if getgenv().GrokESP_DEBUG then (function(...) warn("[Grok ESP]", ...) end) else (function() end);
local debug_error = if getgenv().GrokESP_DEBUG then (function(...) error("[Grok ESP] " .. table.concat({ ... }, " ")) end) else (function() end);

if getgenv().GrokESP then
	debug_warn("Already Loaded.")
	return getgenv().GrokESP
end

local function GetColor(input)
	if typeof(input) == "Color3" then
		return input
	end
	if typeof(input) == "string" then
		local lower = string.lower(input)
		return PresetColors[lower] or Color3.new(1, 1, 1)
	end
	return Color3.new(1, 1, 1)
end

export type TracerSettings = {
	UseLine: boolean,

	LineColor: Color3 | string?,
	LineWidth: number?,
	LineOpacity: number?,
	StartPoint: ("Top" | "Bottom" | "Center" | "Mouse")?,
}

export type ArrowSettings = {
	UseArrow: boolean,

	ArrowColor: Color3 | string?,
	ArrowDistance: number?,
}

export type ESPFeatures = {
	ShowName: boolean?,
	Highlight: boolean?,
	Box: boolean?,
	Outline: boolean?,
	Sphere: boolean?,
	Cylinder: boolean?,
}

export type ESPSettings = {
	Name: string?,

	Model: Instance,
	TextModel: Instance?,

	Show: boolean?,
	MainColor: Color3 | string?,
	ViewDistance: number?,

	TextOffset: Vector3?,
	LabelSize: number?,

	ESPFeatures: ESPFeatures?,
	LineThickness: number?,
	Opacity: number?,

	FillColor: Color3 | string?,
	EdgeColor: Color3 | string?,

	InnerOpacity: number?,
	EdgeOpacity: number?,

	Tracer: TracerSettings?,
	Arrow: ArrowSettings?,

	OnDestroy: BindableEvent?,
	OnDestroyFunc: (() -> nil)?,
}

local cloneref = getgenv().cloneref or function(inst) return inst; end
local getui;

local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local CoreGui = cloneref(game:GetService("CoreGui"))

local tablefreeze = function<T>(provided_table: T): T
	local proxy = {}
	local data = table.clone(provided_table)

	local mt = {
		__index = function(table, key)
			return data[key]
		end,

		__newindex = function(table, key, value)
		end
	}

	return setmetatable(proxy, mt) :: typeof(provided_table)
end

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
	length = tonumber(length) or math.random(10, 20)

	local array = {}
	for i = 1, length do
		array[i] = string.char(math.random(32, 126))
	end

	return table.concat(array)
end

local InstancesLib = {
	Create = function(instanceType, properties)
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

do
	local testGui = Instance.new("ScreenGui")
	local successful = pcall(function()
		testGui.Parent = CoreGui;
	end)

	if not successful then
		getui = function() return Players.LocalPlayer.PlayerGui; end;
	else
		getui = function() return CoreGui end;
	end

	testGui:Destroy()
end

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

local Library = {
	Destroyed = false,

	ActiveFolder = ActiveFolder,
	StorageFolder = StorageFolder,
	MainGUI = MainGUI,
	BillboardGUI = BillboardGUI,
	ESP = {},
	Connections = {},

	GlobalConfig = {
		IgnoreLocalPlayer = false,
		UseRainbow = false,

		ShowLabels = true,
		ShowVisuals = true,
		ShowDistance = true,
		ShowTracers = true,
		ShowArrows = true,

		Font = Enum.Font.RobotoCondensed
	},

	RainbowHueSetup = 0,
	RainbowHue = 0,
	RainbowStep = 0,
	RainbowColor = Color3.new()
}

local character
local rootPart
local camera = workspace.CurrentCamera

local function worldToViewport(...)
	camera = (camera or workspace.CurrentCamera);

	if camera == nil then
		return Vector2.new(0, 0), false
	end

	return camera:WorldToViewportPoint(...)
end

local function UpdatePlayerVariables(newCharacter, force)
	if force ~= true and Library.GlobalConfig.IgnoreLocalPlayer == true then
		return
	end

	character = newCharacter or Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait();
	rootPart =
		character:WaitForChild("HumanoidRootPart", 2.5)
		or character:WaitForChild("UpperTorso", 2.5)
		or character:WaitForChild("Torso", 2.5)
		or character.PrimaryPart
		or character:WaitForChild("Head", 2.5);
end
task.spawn(UpdatePlayerVariables, nil, true);

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

	getgenv().GrokESP = nil;
end

local AllowedStartPoint = {
	top = true,
	bottom = true,
	center = true,
	mouse = true,
}

local defaultFeatures = {ShowName = true, Highlight = true, Box = false, Outline = false, Sphere = false, Cylinder = false}

function CreateTracer(tracerSettings, instanceName)
	if Library.Destroyed == true then
		return
	end

	if not tracerSettings then
		tracerSettings = {}
	end

	if tracerSettings.UseLine ~= true then
		return
	end

	tracerSettings.LineColor = GetColor(tracerSettings.LineColor or Color3.new(1,1,1))
	tracerSettings.LineWidth = typeof(tracerSettings.LineWidth) == "number" and tracerSettings.LineWidth or 2
	tracerSettings.LineOpacity = typeof(tracerSettings.LineOpacity) == "number" and tracerSettings.LineOpacity or 0
	local startPoint = string.lower(typeof(tracerSettings.StartPoint) == "string" and tracerSettings.StartPoint or "bottom")
	if AllowedStartPoint[startPoint] == nil then
		startPoint = "bottom"
	end

	local Path2D = InstancesLib.Create("Path2D", {
		Parent = MainGUI,
		Name = if typeof(instanceName) == "string" then instanceName else "Tracer",
		Closed = true,

		Color3 = tracerSettings.LineColor,
		Thickness = tracerSettings.LineWidth,
		Transparency = tracerSettings.LineOpacity,
	})

	local function UpdateTracer(from, to)
		Path2D:SetControlPoints({
			Path2DControlPoint.new(UDim2.fromOffset(from.X, from.Y)),
			Path2DControlPoint.new(UDim2.fromOffset(to.X, to.Y))
		})
	end

	local data = {
		From = UDim2.fromOffset(0, 0),
		To = UDim2.fromOffset(0, 0),

		Visible = true,
		Color3 = tracerSettings.LineColor,
		Thickness = tracerSettings.LineWidth,
		Transparency = tracerSettings.LineOpacity,
	}
	UpdateTracer(data.From, data.To);

	local proxy = {}
	local Tracer = {
		__newindex = function(table, key, value)
			if not Path2D then
				return
			end

			if key == "From" then
				UpdateTracer(value, data.To)

			elseif key == "To" then
				UpdateTracer(data.From, value)

			elseif key == "Transparency" or key == "Thickness" then
				Path2D[key] = value

			elseif key == "Color3" then
				Path2D.Color3 = value

			elseif key == "Visible" then
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

	return setmetatable(proxy, Tracer) :: typeof(data)
end

function Library:Add(espSettings)
	if Library.Destroyed == true then
		return
	end

	assert(typeof(espSettings) == "table", "espSettings; expected table, got " .. typeof(espSettings))
	assert(
		typeof(espSettings.Model) == "Instance",
		"espSettings.Model; expected Instance, got " .. typeof(espSettings.Model)
	)

	espSettings.Name = if typeof(espSettings.Name) == "string" then espSettings.Name else espSettings.Model.Name;
	espSettings.TextModel = if typeof(espSettings.TextModel) == "Instance" then espSettings.TextModel else espSettings.Model;

	espSettings.Show = if typeof(espSettings.Show) == "boolean" then espSettings.Show else true;
	espSettings.MainColor = GetColor(espSettings.MainColor or Color3.new(1,1,1));
	espSettings.ViewDistance = if typeof(espSettings.ViewDistance) == "number" then espSettings.ViewDistance else 5000;

	espSettings.TextOffset = if typeof(espSettings.TextOffset) == "Vector3" then espSettings.TextOffset else Vector3.new();
	espSettings.LabelSize = if typeof(espSettings.LabelSize) == "number" then espSettings.LabelSize else 16;

	espSettings.LineThickness = if typeof(espSettings.LineThickness) == "number" then espSettings.LineThickness else 0.1;
	espSettings.Opacity = if typeof(espSettings.Opacity) == "number" then espSettings.Opacity else 0.65;

	espSettings.FillColor = GetColor(espSettings.FillColor or espSettings.MainColor);
	espSettings.EdgeColor = GetColor(espSettings.EdgeColor or espSettings.MainColor);

	espSettings.InnerOpacity = if typeof(espSettings.InnerOpacity) == "number" then espSettings.InnerOpacity else espSettings.Opacity;
	espSettings.EdgeOpacity = if typeof(espSettings.EdgeOpacity) == "number" then espSettings.EdgeOpacity else 0;

	espSettings.Tracer = if typeof(espSettings.Tracer) == "table" then espSettings.Tracer else { UseLine = false };
	espSettings.Arrow = if typeof(espSettings.Arrow) == "table" then espSettings.Arrow else { UseArrow = false };

	espSettings.ESPFeatures = espSettings.ESPFeatures or defaultFeatures
	for k, v in pairs(defaultFeatures) do
		if espSettings.ESPFeatures[k] == nil then
			espSettings.ESPFeatures[k] = v
		end
	end

	local ESP = {
		Index = RandomString(),
		OriginalSettings = tablefreeze(espSettings),
		CurrentSettings = espSettings,

		Hidden = false,
		Deleted = false,
		Connections = {},
		RenderThread = nil,
		Highlighters = {},
		Billboard = nil,
		Tracer = nil,
		Arrow = nil,
	}

	local showName = ESP.CurrentSettings.ESPFeatures.ShowName
	local hasVisuals = ESP.CurrentSettings.ESPFeatures.Highlight or ESP.CurrentSettings.ESPFeatures.Box or ESP.CurrentSettings.ESPFeatures.Outline or ESP.CurrentSettings.ESPFeatures.Sphere or ESP.CurrentSettings.ESPFeatures.Cylinder

	local _, ModelSize = pcall(function()
		if ESP.CurrentSettings.Model:IsA("Model") then
			return ESP.CurrentSettings.Model:GetBoundingBox()
		end
	end)
	if not ModelSize and ESP.CurrentSettings.Model:IsA("BasePart") then
		ModelSize = ESP.CurrentSettings.Model.Size
	end
	ModelSize = ModelSize or Vector3.new(4, 6, 2)

	if showName then
		local Billboard = InstancesLib.Create("BillboardGui", {
			Parent = BillboardGUI,
			Name = ESP.Index,

			Enabled = true,
			ResetOnSpawn = false,
			AlwaysOnTop = true,
			Size = UDim2.new(0, 200, 0, 50),

			Adornee = ESP.CurrentSettings.TextModel or ESP.CurrentSettings.Model,
			StudsOffset = ESP.CurrentSettings.TextOffset or Vector3.new(),
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
			TextColor3 = ESP.CurrentSettings.MainColor or Color3.new(1,1,1),
			TextSize = ESP.CurrentSettings.LabelSize or 16,
		})

		InstancesLib.Create("UIStroke", {
			Parent = BillboardText
		})

		ESP.Billboard = Billboard
	end

	local Model = ESP.CurrentSettings.Model

	if ESP.CurrentSettings.ESPFeatures.Highlight then
		local Highlighter = InstancesLib.Create("Highlight", {
			Parent = ActiveFolder,
			Name = ESP.Index .. "_Highlight",

			Adornee = Model,

			FillColor = ESP.CurrentSettings.FillColor,
			OutlineColor = ESP.CurrentSettings.EdgeColor,

			FillTransparency = ESP.CurrentSettings.InnerOpacity,
			OutlineTransparency = ESP.CurrentSettings.EdgeOpacity,
		})
		table.insert(ESP.Highlighters, Highlighter)
	end

	if ESP.CurrentSettings.ESPFeatures.Box then
		local Highlighter = InstancesLib.Create("BoxHandleAdornment", {
			Parent = ActiveFolder,
			Name = ESP.Index .. "_Box",

			Adornee = Model,

			AlwaysOnTop = true,
			ZIndex = 10,

			Size = ModelSize,

			Color3 = ESP.CurrentSettings.MainColor,
			Transparency = ESP.CurrentSettings.Opacity,
		})
		table.insert(ESP.Highlighters, Highlighter)
	end

	if ESP.CurrentSettings.ESPFeatures.Outline then
		local Highlighter = InstancesLib.Create("SelectionBox", {
			Parent = ActiveFolder,
			Name = ESP.Index .. "_Outline",

			Adornee = Model,

			Color3 = ESP.CurrentSettings.MainColor,
			LineThickness = ESP.CurrentSettings.LineThickness,

			SurfaceColor3 = ESP.CurrentSettings.FillColor,
			SurfaceTransparency = ESP.CurrentSettings.InnerOpacity,
		})
		table.insert(ESP.Highlighters, Highlighter)
	end

	if ESP.CurrentSettings.ESPFeatures.Sphere then
		local Highlighter = InstancesLib.Create("SphereHandleAdornment", {
			Parent = ActiveFolder,
			Name = ESP.Index .. "_Sphere",

			Adornee = Model,

			AlwaysOnTop = true,
			ZIndex = 10,

			Radius = ModelSize.X * 1.085,
			CFrame = CFrame.new() * CFrame.Angles(math.rad(90), 0, 0),

			Color3 = ESP.CurrentSettings.MainColor,
			Transparency = ESP.CurrentSettings.Opacity,
		})
		table.insert(ESP.Highlighters, Highlighter)
	end

	if ESP.CurrentSettings.ESPFeatures.Cylinder then
		local Highlighter = InstancesLib.Create("CylinderHandleAdornment", {
			Parent = ActiveFolder,
			Name = ESP.Index .. "_Cylinder",

			Adornee = Model,

			AlwaysOnTop = true,
			ZIndex = 10,

			Height = ModelSize.Y * 2,
			Radius = ModelSize.X * 1.085,
			CFrame = CFrame.new() * CFrame.Angles(math.rad(90), 0, 0),

			Color3 = ESP.CurrentSettings.MainColor,
			Transparency = ESP.CurrentSettings.Opacity,
		})
		table.insert(ESP.Highlighters, Highlighter)
	end

	ESP.Tracer = if typeof(ESP.OriginalSettings.Tracer) == "table" then CreateTracer(ESP.CurrentSettings.Tracer, ESP.Index) else nil;

	if typeof(ESP.OriginalSettings.Arrow) == "table" and ESP.OriginalSettings.Arrow.UseArrow then
		ESP.Arrow = InstancesLib.Create("ImageLabel", {
			Parent = MainGUI,
			Name = ESP.Index,

			Size = UDim2.new(0, 32, 0, 32),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,

			AnchorPoint = Vector2.new(0.5, 0.5),

			BackgroundTransparency = 1,
			BorderSizePixel = 0,

			Image = "http://www.roblox.com/asset/?id=3926305904",
			ImageColor3 = ESP.CurrentSettings.Arrow.ArrowColor or ESP.CurrentSettings.MainColor,
		});

		ESP.CurrentSettings.Arrow.ArrowDistance = if typeof(ESP.CurrentSettings.Arrow.ArrowDistance) == "number" then ESP.CurrentSettings.Arrow.ArrowDistance else 300;
	end

	function ESP:Destroy()
		if ESP.Deleted == true then
			return;
		end

		ESP.Deleted = true

		if ESP.RenderThread then
			pcall(coroutine.close, ESP.RenderThread)
		end

		if table.find(Library.ESP, ESP.Index) then
			table.remove(Library.ESP, table.find(Library.ESP, ESP.Index))
		end

		Library.ESP[ESP.Index] = nil

		if ESP.Billboard then ESP.Billboard:Destroy() end
		for _, hl in ipairs(ESP.Highlighters) do
			if hl then hl:Destroy() end
		end
		if ESP.Tracer then ESP.Tracer:Destroy() end
		if ESP.Arrow then ESP.Arrow:Destroy() end

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
	end

	local function Show(forceShow)
		if not (ESP and ESP.Deleted ~= true) then return end
		if forceShow ~= true and not ESP.Hidden then
			return
		end

		ESP.Hidden = false;

		if ESP.Billboard then
			ESP.Billboard.Enabled = true;
		end

		for _, hl in ipairs(ESP.Highlighters) do
			if hl then
				hl.Adornee = ESP.CurrentSettings.Model;
				hl.Parent = ActiveFolder;
			end
		end

		if ESP.Tracer then
			ESP.Tracer.Visible = true;
		end

		if ESP.Arrow then
			ESP.Arrow.Visible = true;
		end
	end

	local function Hide(forceHide)
		if not (ESP and ESP.Deleted ~= true) then return end
		if forceHide ~= true and ESP.Hidden then
			return
		end

		ESP.Hidden = true

		if ESP.Billboard then
			ESP.Billboard.Enabled = false;
		end

		for _, hl in ipairs(ESP.Highlighters) do
			if hl then
				hl.Adornee = nil;
				hl.Parent = StorageFolder;
			end
		end

		if ESP.Tracer then
			ESP.Tracer.Visible = false;
		end

		if ESP.Arrow then
			ESP.Arrow.Visible = false;
		end
	end

	function ESP:Show(force)
		ESP.CurrentSettings.Show = true
		Show(force);
	end

	function ESP:Hide(force)
		if not (ESP and ESP.CurrentSettings and ESP.Deleted ~= true) then return end

		ESP.CurrentSettings.Show = false
		Hide(force);
	end

	function ESP:ToggleVisibility(force)
		ESP.CurrentSettings.Show = not ESP.CurrentSettings.Show
		if ESP.CurrentSettings.Show then
			Show(force);
		else
			Hide(force);
		end
	end

	function ESP:Render()
		if not (ESP and ESP.CurrentSettings and ESP.Deleted ~= true) then return end
		if
			ESP.CurrentSettings.Show == false or
			not camera or
			(if Library.GlobalConfig.IgnoreLocalPlayer == true then false else not rootPart)
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
			(if Library.GlobalConfig.IgnoreLocalPlayer == true then (camera or rootPart) else rootPart)
		)

		if distanceFromPlayer > ESP.CurrentSettings.ViewDistance then
			Hide()
			return
		end

		if ESP.Arrow then
			ESP.Arrow.Visible = Library.GlobalConfig.ShowArrows == true and ESP.CurrentSettings.Arrow.UseArrow == true and (isOnScreen ~= true);

			if ESP.Arrow.Visible then
				local screenSize = camera.ViewportSize
				local centerPos = Vector2.new(screenSize.X / 2, screenSize.Y / 2)

				local partPos = Vector2.new(screenPos.X, screenPos.Y)

				local IsInverted = screenPos.Z <= 0
				local invert = (IsInverted and -1 or 1)

				local direction = (partPos - centerPos)
				local arctan = math.atan2(direction.Y, direction.X)
				local angle = math.deg(arctan) + 90
				local distance = (ESP.CurrentSettings.Arrow.ArrowDistance * 0.001) * screenSize.Y

				ESP.Arrow.Rotation = angle + 180 * (IsInverted and 0 or 1)
				ESP.Arrow.Position = UDim2.new(
					0,
					centerPos.X + (distance * math.cos(arctan) * invert),
					0,
					centerPos.Y + (distance * math.sin(arctan) * invert)
				)
				ESP.Arrow.ImageColor3 = if Library.GlobalConfig.UseRainbow then Library.RainbowColor else ESP.CurrentSettings.Arrow.ArrowColor;
			end
		end

		if isOnScreen == false then
			Hide()
			return
		else Show() end

		if ESP.Tracer then
			ESP.Tracer.Visible = Library.GlobalConfig.ShowTracers == true and ESP.CurrentSettings.Tracer.UseLine == true;

			if ESP.Tracer.Visible then
				local startPoint = string.lower(ESP.CurrentSettings.Tracer.StartPoint or "bottom")
				local fromPos
				if startPoint == "mouse" then
					local mousePos = UserInputService:GetMouseLocation()
					fromPos = Vector2.new(mousePos.X, mousePos.Y)
				elseif startPoint == "top" then
					fromPos = Vector2.new(camera.ViewportSize.X / 2, 0)
				elseif startPoint == "center" then
					fromPos = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
				else
					fromPos = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
				end

				ESP.Tracer.From = fromPos
				ESP.Tracer.To = Vector2.new(screenPos.X, screenPos.Y)

				ESP.Tracer.Transparency = ESP.CurrentSettings.Tracer.LineOpacity
				ESP.Tracer.Thickness = ESP.CurrentSettings.Tracer.LineWidth
				ESP.Tracer.Color3 = Library.GlobalConfig.UseRainbow and Library.RainbowColor
					or ESP.CurrentSettings.Tracer.LineColor
			end
		end

		if ESP.Billboard then
			ESP.Billboard.Enabled = Library.GlobalConfig.ShowLabels == true;

			if ESP.Billboard.Enabled then
				if Library.GlobalConfig.ShowDistance then
					ESP.Billboard.TextLabel.Text = string.format(
						'%s\n<font size="%d">[%s]</font>',
						ESP.CurrentSettings.Name,
						ESP.CurrentSettings.LabelSize - 3,
						math.floor(distanceFromPlayer)
					)
				else
					ESP.Billboard.TextLabel.Text = ESP.CurrentSettings.Name
				end

				ESP.Billboard.TextLabel.Font = Library.GlobalConfig.Font
				ESP.Billboard.TextLabel.TextColor3 =
					if Library.GlobalConfig.UseRainbow then Library.RainbowColor else ESP.CurrentSettings.MainColor;
				ESP.Billboard.TextLabel.TextSize = ESP.CurrentSettings.LabelSize
			end
		end

		local showVisuals = Library.GlobalConfig.ShowVisuals == true
		for _, hl in ipairs(ESP.Highlighters) do
			if hl then
				hl.Parent = if showVisuals then ActiveFolder else StorageFolder;
				hl.Adornee = if showVisuals then ESP.CurrentSettings.Model else nil;

				if hl.Adornee then
					local rainbow = Library.GlobalConfig.UseRainbow
					if hl:IsA("Highlight") then
						hl.FillColor = rainbow and Library.RainbowColor or ESP.CurrentSettings.FillColor
						hl.OutlineColor = rainbow and Library.RainbowColor or ESP.CurrentSettings.EdgeColor

						hl.FillTransparency = ESP.CurrentSettings.InnerOpacity
						hl.OutlineTransparency = ESP.CurrentSettings.EdgeOpacity
					elseif hl:IsA("SelectionBox") then
						hl.Color3 = rainbow and Library.RainbowColor or ESP.CurrentSettings.MainColor
						hl.SurfaceColor3 = rainbow and Library.RainbowColor or ESP.CurrentSettings.FillColor

						hl.SurfaceTransparency = ESP.CurrentSettings.InnerOpacity
						hl.LineThickness = ESP.CurrentSettings.LineThickness
					else
						hl.Color3 = rainbow and Library.RainbowColor or ESP.CurrentSettings.MainColor

						if hl:IsA("HandleAdornment") then
							hl.Transparency = ESP.CurrentSettings.Opacity
						end
					end
				end
			end
		end
	end

	if not ESP.OriginalSettings.Show then
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

getgenv().GrokESP = Library
return Library
