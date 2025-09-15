local VERSION = "2.0.2";
local debug_print = if getgenv().VelocityESP_DEBUG then (function(...) print("[Velocity ESP]", ...) end) else (function() end);
local debug_warn  = if getgenv().VelocityESP_DEBUG then (function(...) warn("[Velocity ESP]", ...) end) else (function() end);
local debug_error = if getgenv().VelocityESP_DEBUG then (function(...) error("[Velocity ESP] " .. table.concat({ ... }, " ")) end) else (function() end);

if getgenv().VelocityESP then
	debug_warn("Already Loaded.")
	return getgenv().VelocityESP
end

local ColorPresets = {
	white = Color3.new(1,1,1),
	black = Color3.new(0,0,0),
	red = Color3.new(1,0,0),
	green = Color3.new(0,1,0),
	blue = Color3.new(0,0,1),
	yellow = Color3.new(1,1,0),
	cyan = Color3.new(0,1,1),
	magenta = Color3.new(1,0,1),
	orange = Color3.new(1,0.5,0),
	purple = Color3.new(0.5,0,1),
	pink = Color3.new(1,0.5,0.5),
	lime = Color3.new(0.5,1,0),
	teal = Color3.new(0,0.5,0.5),
	navy = Color3.new(0,0,0.5),
	maroon = Color3.new(0.5,0,0),
	olive = Color3.new(0.5,0.5,0),
	gray = Color3.new(0.5,0.5,0.5),
	darkgray = Color3.new(0.3,0.3,0.3),
	lightgray = Color3.new(0.7,0.7,0.7),
	brown = Color3.new(0.6,0.3,0),
	gold = Color3.new(1,0.8,0),
	silver = Color3.new(0.75,0.75,0.75),
	crimson = Color3.new(0.86,0.08,0.24),
	turquoise = Color3.new(0.68,0.93,0.93),
	indigo = Color3.new(0.29,0,0.51),
	violet = Color3.new(0.93,0.51,0.93),
	coral = Color3.new(1,0.5,0.31),
	khaki = Color3.new(0.94,0.90,0.55),
	lavender = Color3.new(0.90,0.90,0.98),
	plum = Color3.new(0.86,0.57,0.98),
	darkred = Color3.new(0.5,0,0),
	lightred = Color3.new(1,0.5,0.5),
	darkgreen = Color3.new(0,0.5,0),
	lightgreen = Color3.new(0.5,1,0.5),
	darkblue = Color3.new(0,0,0.5),
	lightblue = Color3.new(0.5,0.5,1),
	darkyellow = Color3.new(0.5,0.5,0),
	lightyellow = Color3.new(1,1,0.5),
	darkcyan = Color3.new(0,0.5,0.5),
	lightcyan = Color3.new(0.5,1,1),
	darkmagenta = Color3.new(0.5,0,0.5),
	lightmagenta = Color3.new(1,0.5,1),
	darkorange = Color3.new(0.5,0.25,0),
	lightorange = Color3.new(1,0.75,0.5),
	darkpurple = Color3.new(0.25,0,0.5),
	lightpurple = Color3.new(0.75,0.5,1),
	beige = Color3.new(0.96,0.96,0.86),
	azure = Color3.new(0.82,1,1),
	fuchsia = Color3.new(1,0,1),
	springgreen = Color3.new(0,1,0.5),
}

local function GetColorFromPreset(colorInput)
	if typeof(colorInput) == "string" then
		local lowerKey = string.lower(colorInput)
		if ColorPresets[lowerKey] then
			return ColorPresets[lowerKey]
		else
			debug_warn("Unknown color preset: " .. colorInput .. ". Using white.")
			return Color3.new(1,1,1)
		end
	end
	return colorInput
end

export type TargetLineSettings = {
	Active: boolean,

	LineColor: Color3?,
	LineWidth: number?,
	LineFade: number?,
	StartPoint: ("Top" | "Bottom" | "Center" | "Mouse")?,
}

export type ScreenPointerSettings = {
	Active: boolean,

	PointerColor: Color3?,
	EdgeDistance: number?,
}

export type ESPStyleSettings = {
	Text: boolean?,
	Sphere: boolean?,
	Cylinder: boolean?,
	Box: boolean?,
	BoxOutline: boolean?,
	Highlight: boolean?,
}

export type ESPSettings = {
	Name: string?,

	Model: Instance,
	TextModel: Instance?,

	Show: boolean?,
	MainColor: Color3?,
	MaxViewDistance: number?,

	NameOffset: Vector3?,
	NameSize: number?,

	ESPStyles: ESPStyleSettings?,
	OutlineWidth: number?,
	OutlineFade: number?,

	BoxFillColor: Color3?,

	InnerColor: Color3?,
	EdgeColor: Color3?,

	InnerFade: number?,
	EdgeFade: number?,

	TargetLine: TargetLineSettings?,
	ScreenPointer: ScreenPointerSettings?,

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
		IgnoreOwnPlayer = false,
		RainbowMode = false,

		ShowNames = true,
		ShowBoxes = true,
		ShowDist = true,
		ShowLines = true,
		ShowPointers = true,

		FontType = Enum.Font.RobotoCondensed
	},

	RainbowHueSetup = 0,
	RainbowHue = 0,
	RainbowStep = 0,
	RainbowColor = Color3.new()
}

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
	if force ~= true and Library.GlobalConfig.IgnoreOwnPlayer == true then
		debug_warn("UpdatePlayerVariables: IgnoreOwnPlayer enabled.")
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

	getgenv().VelocityESP = nil;
	debug_print("Unloaded!")
end

local AllowedStartPoint = {
	top = true,
	bottom = true,
	center = true,
	mouse = true,
}

local AllowedESPStyle = {
	text = true,
	sphere = true,
	cylinder = true,
	box = true,
	boxoutline = true,
	highlight = true,
}

function TracerCreate(targetLineSettings: TargetLineSettings, instanceName: string?)
	if Library.Destroyed == true then
		debug_warn("Library is destroyed, please reload it.")
		return
	end

	if not targetLineSettings then
		targetLineSettings = {}
	end

	if targetLineSettings.Active ~= true then
		debug_warn("TargetLine is not active.")
		return
	end
	debug_print("Creating TargetLine...")

	targetLineSettings.LineColor = GetColorFromPreset(targetLineSettings.LineColor or Color3.new(1,1,1))
	targetLineSettings.LineWidth = typeof(targetLineSettings.LineWidth) == "number" and targetLineSettings.LineWidth or 2
	targetLineSettings.LineFade = typeof(targetLineSettings.LineFade) == "number" and targetLineSettings.LineFade or 0
	targetLineSettings.StartPoint = string.lower(typeof(targetLineSettings.StartPoint) == "string" and targetLineSettings.StartPoint or "bottom")
	if AllowedStartPoint[targetLineSettings.StartPoint] == nil then
		targetLineSettings.StartPoint = "bottom"
	end

	local Path2D = InstancesLib.Create("Path2D", {
		Parent = MainGUI,
		Name = if typeof(instanceName) == "string" then instanceName else "TargetLine",
		Closed = true,

		Color3 = targetLineSettings.LineColor,
		Thickness = targetLineSettings.LineWidth,
		Transparency = targetLineSettings.LineFade,
	})

	local function UpdateTracer(from: Vector2, to: Vector2)
		Path2D:SetControlPoints({
			Path2DControlPoint.new(UDim2.fromOffset(from.X, from.Y)),
			Path2DControlPoint.new(UDim2.fromOffset(to.X, to.Y))
		})
	end

	local data = {
		From = typeof(targetLineSettings.StartPoint) ~= "Vector2" and UDim2.fromOffset(0, 0) or UDim2.fromOffset(targetLineSettings.StartPoint.X, targetLineSettings.StartPoint.Y),
		To = typeof(targetLineSettings.To) ~= "Vector2" and UDim2.fromOffset(0, 0) or UDim2.fromOffset(targetLineSettings.To.X, targetLineSettings.To.Y),

		Visible = true,
		Color3 = targetLineSettings.LineColor,
		Thickness = targetLineSettings.LineWidth,
		Transparency = targetLineSettings.LineFade,
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

			elseif key == "LineFade" or key == "LineWidth" then
				assert(typeof(value) == "number", tostring(key) .. "; expected number, got " .. typeof(value))
				Path2D[key == "LineFade" and "Transparency" or "Thickness"] = value

			elseif key == "LineColor" then
				assert(typeof(value) == "Color3", tostring(key) .. "; expected Color3, got " .. typeof(value))
				Path2D.Color3 = GetColorFromPreset(value)

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

	debug_print("TargetLine created.")
	return setmetatable(proxy, Tracer) :: typeof(data)
end

local function GetActiveESPStyle(espStyles)
	local activeStyle = nil
	for style, enabled in pairs(espStyles or {}) do
		if enabled then
			if activeStyle then
				debug_warn("Multiple ESP styles enabled. Using first: " .. activeStyle)
			else
				activeStyle = string.lower(style)
			end
		end
	end
	if not activeStyle then
		activeStyle = "highlight"
	end
	return activeStyle
end

function Library:Add(espSettings: ESPSettings)
	if Library.Destroyed == true then
		debug_warn("Library is destroyed, please reload it.")
		return
	end

	assert(typeof(espSettings) == "table", "espSettings; expected table, got " .. typeof(espSettings))
	assert(
		typeof(espSettings.Model) == "Instance",
		"espSettings.Model; expected Instance, got " .. typeof(espSettings.Model)
	)

	espSettings.ESPStyles = espSettings.ESPStyles or { Text = false, Sphere = false, Cylinder = false, Box = false, BoxOutline = false, Highlight = true }
	local espStyle = GetActiveESPStyle(espSettings.ESPStyles)
	assert(
		AllowedESPStyle[espStyle] == true,
		"espSettings.ESPStyles; invalid active ESP style: " .. espStyle
	)

	espSettings.Name = if typeof(espSettings.Name) == "string" then espSettings.Name else espSettings.Model.Name;
	espSettings.TextModel = if typeof(espSettings.TextModel) == "Instance" then espSettings.TextModel else espSettings.Model;

	espSettings.Show = if typeof(espSettings.Show) == "boolean" then espSettings.Show else true;
	espSettings.MainColor = GetColorFromPreset(espSettings.MainColor or Color3.new(1,1,1));
	espSettings.MaxViewDistance = if typeof(espSettings.MaxViewDistance) == "number" then espSettings.MaxViewDistance else 5000;

	espSettings.NameOffset = if typeof(espSettings.NameOffset) == "Vector3" then espSettings.NameOffset else Vector3.new();
	espSettings.NameSize = if typeof(espSettings.NameSize) == "number" then espSettings.NameSize else 16;

	espSettings.OutlineWidth = if typeof(espSettings.OutlineWidth) == "number" then espSettings.OutlineWidth else 0.1;
	espSettings.OutlineFade = if typeof(espSettings.OutlineFade) == "number" then espSettings.OutlineFade else 0.65;

	espSettings.BoxFillColor = GetColorFromPreset(espSettings.BoxFillColor or Color3.new(1,1,1));
	espSettings.InnerColor = GetColorFromPreset(espSettings.InnerColor or Color3.new(1,1,1));
	espSettings.EdgeColor = GetColorFromPreset(espSettings.EdgeColor or Color3.new(1, 1, 1));

	espSettings.InnerFade = if typeof(espSettings.InnerFade) == "number" then espSettings.InnerFade else 0.65;
	espSettings.EdgeFade = if typeof(espSettings.EdgeFade) == "number" then espSettings.EdgeFade else 0;

	espSettings.TargetLine = if typeof(espSettings.TargetLine) == "table" then espSettings.TargetLine else { Active = false };
	espSettings.ScreenPointer = if typeof(espSettings.ScreenPointer) == "table" then espSettings.ScreenPointer else { Active = false };

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
		Size = UDim2.new(0, 200, 0, 50),

		Adornee = ESP.CurrentSettings.TextModel or ESP.CurrentSettings.Model,
		StudsOffset = ESP.CurrentSettings.NameOffset or Vector3.new(),
	})

	local BillboardText = InstancesLib.Create("TextLabel", {
		Parent = Billboard,

		Size = UDim2.new(0, 200, 0, 50),
		Font = Library.GlobalConfig.FontType,
		TextWrap = true,
		TextWrapped = true,
		RichText = true,
		TextStrokeTransparency = 0,
		BackgroundTransparency = 1,

		Text = ESP.CurrentSettings.Name,
		TextColor3 = ESP.CurrentSettings.MainColor or Color3.new(1,1,1),
		TextSize = ESP.CurrentSettings.NameSize or 16,
	})

	InstancesLib.Create("UIStroke", {
		Parent = BillboardText
	})

	local Highlighter, IsAdornment = nil, not not string.match(espStyle, "adornment") or espStyle == "text"
	debug_print("Creating Highlighter...", espStyle, IsAdornment)

	if espStyle == "text" then

	elseif IsAdornment then
		local _, ModelSize = nil, nil
		if ESP.CurrentSettings.Model:IsA("Model") then
			_, ModelSize = ESP.CurrentSettings.Model:GetBoundingBox()
		else
			if not InstancesLib.TryGetProperty(ESP.CurrentSettings.Model, "Size") then
				local prim = InstancesLib.FindPrimaryPart(ESP.CurrentSettings.Model)
				if not InstancesLib.TryGetProperty(prim, "Size") then
					debug_print("Couldn't get model size, switching to Highlight.", ESP.Index, "-", ESP.CurrentSettings.Name)

					espSettings.ESPStyles.Highlight = true
					for k,v in pairs(espSettings.ESPStyles) do if k ~= "Highlight" then v = false end end
					return Library:Add(espSettings)
				end

				ModelSize = prim.Size
			else
				ModelSize = ESP.CurrentSettings.Model.Size
			end
		end

		if espStyle == "sphere" then
			Highlighter = InstancesLib.Create("SphereHandleAdornment", {
				Parent = ActiveFolder,
				Name = ESP.Index,

				Adornee = ESP.CurrentSettings.Model,

				AlwaysOnTop = true,
				ZIndex = 10,

				Radius = ModelSize.X * 1.085,
				CFrame = CFrame.new() * CFrame.Angles(math.rad(90), 0, 0),

				Color3 = ESP.CurrentSettings.MainColor or Color3.new(1,1,1),
				Transparency = ESP.CurrentSettings.OutlineFade or 0.65,
			})
		elseif espStyle == "cylinder" then
			Highlighter = InstancesLib.Create("CylinderHandleAdornment", {
				Parent = ActiveFolder,
				Name = ESP.Index,

				Adornee = ESP.CurrentSettings.Model,

				AlwaysOnTop = true,
				ZIndex = 10,

				Height = ModelSize.Y * 2,
				Radius = ModelSize.X * 1.085,
				CFrame = CFrame.new() * CFrame.Angles(math.rad(90), 0, 0),

				Color3 = ESP.CurrentSettings.MainColor or Color3.new(1,1,1),
				Transparency = ESP.CurrentSettings.OutlineFade or 0.65,
			})
		else
			Highlighter = InstancesLib.Create("BoxHandleAdornment", {
				Parent = ActiveFolder,
				Name = ESP.Index,

				Adornee = ESP.CurrentSettings.Model,

				AlwaysOnTop = true,
				ZIndex = 10,

				Size = ModelSize,

				Color3 = ESP.CurrentSettings.MainColor or Color3.new(1,1,1),
				Transparency = ESP.CurrentSettings.OutlineFade or 0.65,
			})
		end
	elseif espStyle == "boxoutline" then
		Highlighter = InstancesLib.Create("SelectionBox", {
			Parent = ActiveFolder,
			Name = ESP.Index,

			Adornee = ESP.CurrentSettings.Model,

			Color3 = ESP.CurrentSettings.MainColor or Color3.new(1,1,1),
			LineThickness = ESP.CurrentSettings.OutlineWidth or 0.1,

			SurfaceColor3 = ESP.CurrentSettings.BoxFillColor or Color3.new(1,1,1),
			SurfaceTransparency = ESP.CurrentSettings.OutlineFade or 0.65,
		})
	elseif espStyle == "highlight" then
		Highlighter = InstancesLib.Create("Highlight", {
			Parent = ActiveFolder,
			Name = ESP.Index,

			Adornee = ESP.CurrentSettings.Model,

			FillColor = ESP.CurrentSettings.InnerColor or Color3.new(1,1,1),
			OutlineColor = ESP.CurrentSettings.EdgeColor or Color3.new(1, 1, 1),

			FillTransparency = ESP.CurrentSettings.InnerFade or 0.65,
			OutlineTransparency = ESP.CurrentSettings.EdgeFade or 0,
		})
	end

	local TargetLine = if typeof(ESP.OriginalSettings.TargetLine) == "table" then TracerCreate(ESP.CurrentSettings.TargetLine, ESP.Index) else nil;
	local ScreenPointer = nil;

	if typeof(ESP.OriginalSettings.ScreenPointer) == "table" and ESP.OriginalSettings.ScreenPointer.Active then
		debug_print("Creating ScreenPointer...", ESP.Index, "-", ESP.CurrentSettings.Name)
		ScreenPointer = InstancesLib.Create("ImageLabel", {
			Parent = MainGUI,
			Name = ESP.Index,

			Size = UDim2.new(0, 48, 0, 48),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,

			AnchorPoint = Vector2.new(0.5, 0.5),

			BackgroundTransparency = 1,
			BorderSizePixel = 0,

			Image = "rbxassetid://6031097228",
			ImageColor3 = ESP.CurrentSettings.MainColor or Color3.new(1,1,1),
		});

		ESP.CurrentSettings.ScreenPointer.EdgeDistance = if typeof(ESP.CurrentSettings.ScreenPointer.EdgeDistance) == "number" then ESP.CurrentSettings.ScreenPointer.EdgeDistance else 300;
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
		if TargetLine then TargetLine:Destroy() end
		if ScreenPointer then ScreenPointer:Destroy() end

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

		if TargetLine then
			TargetLine.Visible = true;
		end

		if ScreenPointer then
			ScreenPointer.Visible = true;
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

		if TargetLine then
			TargetLine.Visible = false;
		end

		if ScreenPointer then
			ScreenPointer.Visible = false;
		end
	end

	function ESP:Show(force: boolean?)
		ESP.CurrentSettings.Show = true
		Show(force);
	end

	function ESP:Hide(force: boolean?)
		if not (ESP and ESP.CurrentSettings and ESP.Deleted ~= true) then return end

		ESP.CurrentSettings.Show = false
		Hide(force);
	end

	function ESP:ToggleVisibility(force: boolean?)
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
			(if Library.GlobalConfig.IgnoreOwnPlayer == true then false else not rootPart)
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
			(if Library.GlobalConfig.IgnoreOwnPlayer == true then (camera or rootPart) else rootPart)
		)

		if distanceFromPlayer > ESP.CurrentSettings.MaxViewDistance then
			Hide()
			return
		end

		if ScreenPointer then
			ScreenPointer.Visible = Library.GlobalConfig.ShowPointers == true and ESP.CurrentSettings.ScreenPointer.Active == true and (isOnScreen ~= true)

			if ScreenPointer.Visible then
				local screenSize = camera.ViewportSize
				local centerPos = Vector2.new(screenSize.X / 2, screenSize.Y / 2)

				local partPos = Vector2.new(screenPos.X, screenPos.Y)

				local IsInverted = screenPos.Z <= 0
				local invert = (IsInverted and -1 or 1)

				local direction = (partPos - centerPos)
				local arctan = math.atan2(direction.Y, direction.X)
				local angle = math.deg(arctan) + 90
				local distance = (ESP.CurrentSettings.ScreenPointer.EdgeDistance * 0.001) * screenSize.Y

				ScreenPointer.Rotation = angle + 180 * (IsInverted and 0 or 1)
				ScreenPointer.Position = UDim2.new(
					0,
					centerPos.X + (distance * math.cos(arctan) * invert),
					0,
					centerPos.Y + (distance * math.sin(arctan) * invert)
				)
				ScreenPointer.ImageColor3 =
					if Library.GlobalConfig.RainbowMode then Library.RainbowColor else ESP.CurrentSettings.ScreenPointer.PointerColor or ESP.CurrentSettings.MainColor;
			end
		end

		if isOnScreen == false then
			Hide()
			return
		else Show() end

		if TargetLine then
			TargetLine.Visible = Library.GlobalConfig.ShowLines == true and ESP.CurrentSettings.TargetLine.Active == true;

			if TargetLine.Visible then
				if ESP.CurrentSettings.TargetLine.StartPoint == "mouse" then
					local mousePos = UserInputService:GetMouseLocation()
					TargetLine.From = Vector2.new(mousePos.X, mousePos.Y)
				elseif ESP.CurrentSettings.TargetLine.StartPoint == "top" then
					TargetLine.From = Vector2.new(camera.ViewportSize.X / 2, 0)
				elseif ESP.CurrentSettings.TargetLine.StartPoint == "center" then
					TargetLine.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
				else
					TargetLine.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
				end

				TargetLine.To = Vector2.new(screenPos.X, screenPos.Y)

				TargetLine.LineFade = ESP.CurrentSettings.TargetLine.LineFade
				TargetLine.LineWidth = ESP.CurrentSettings.TargetLine.LineWidth
				TargetLine.LineColor = Library.GlobalConfig.RainbowMode and Library.RainbowColor
					or GetColorFromPreset(ESP.CurrentSettings.TargetLine.LineColor)
			end
		end

		if Billboard then
			Billboard.Enabled = Library.GlobalConfig.ShowNames == true;

			if Billboard.Enabled then
				if Library.GlobalConfig.ShowDist then
					BillboardText.Text = string.format(
						'%s\n<font size="%d">[%s]</font>',
						ESP.CurrentSettings.Name,
						ESP.CurrentSettings.NameSize - 3,
						math.floor(distanceFromPlayer)
					)
				else
					BillboardText.Text = ESP.CurrentSettings.Name
				end

				BillboardText.Font = Library.GlobalConfig.FontType
				BillboardText.TextColor3 =
					if Library.GlobalConfig.RainbowMode then Library.RainbowColor else ESP.CurrentSettings.MainColor;
				BillboardText.TextSize = ESP.CurrentSettings.NameSize
			end
		end

		if Highlighter then
			Highlighter.Parent = if Library.GlobalConfig.ShowBoxes == true then ActiveFolder else StorageFolder;
			Highlighter.Adornee = if Library.GlobalConfig.ShowBoxes == true then ESP.CurrentSettings.Model else nil;

			if Highlighter.Adornee then
				if IsAdornment then
					Highlighter.Color3 = Library.GlobalConfig.RainbowMode and Library.RainbowColor or ESP.CurrentSettings.MainColor
					Highlighter.Transparency = ESP.CurrentSettings.OutlineFade

				elseif espStyle == "boxoutline" then
					Highlighter.Color3 = Library.GlobalConfig.RainbowMode and Library.RainbowColor or ESP.CurrentSettings.MainColor
					Highlighter.LineThickness = ESP.CurrentSettings.OutlineWidth

					Highlighter.SurfaceColor3 = ESP.CurrentSettings.BoxFillColor
					Highlighter.SurfaceTransparency = ESP.CurrentSettings.OutlineFade

				else
					Highlighter.FillColor =
						if Library.GlobalConfig.RainbowMode then Library.RainbowColor else ESP.CurrentSettings.InnerColor;
					Highlighter.OutlineColor =
						if Library.GlobalConfig.RainbowMode then Library.RainbowColor else ESP.CurrentSettings.EdgeColor;

					Highlighter.FillTransparency = ESP.CurrentSettings.InnerFade
					Highlighter.OutlineTransparency = ESP.CurrentSettings.EdgeFade
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
getgenv().VelocityESP = Library
return Library
