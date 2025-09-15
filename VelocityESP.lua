--!nocheck
--!nolint UnknownGlobal

local VERSION = "2.0.2";
local debug_print = if getgenv().VelocityESP_DEBUG then (function(...) print("[Velocity ESP]", ...) end) else (function() end);
local debug_warn  = if getgenv().VelocityESP_DEBUG then (function(...) warn("[Velocity ESP]", ...) end) else (function() end);
local debug_error = if getgenv().VelocityESP_DEBUG then (function(...) error("[Velocity ESP] " .. table.concat({ ... }, " ")) end) else (function() end);

if getgenv().VelocityESP then
	debug_warn("Already Loaded.")
	return getgenv().VelocityESP
end

local ColorPresets = {
	red = Color3.new(1, 0, 0),
	orange = Color3.new(1, 0.5, 0),
	yellow = Color3.new(1, 1, 0),
	lime = Color3.new(0.5, 1, 0),
	green = Color3.new(0, 1, 0),
	teal = Color3.new(0, 1, 1),
	cyan = Color3.new(0, 0.75, 1),
	sky = Color3.new(0, 0.5, 1),
	blue = Color3.new(0, 0, 1),
	purple = Color3.new(0.5, 0, 1),
	magenta = Color3.new(1, 0, 1),
	pink = Color3.new(1, 0.5, 0.5),
	brown = Color3.new(0.65, 0.16, 0.16),
	gray = Color3.new(0.5, 0.5, 0.5),
	lightgray = Color3.new(0.75, 0.75, 0.75),
	darkgray = Color3.new(0.25, 0.25, 0.25),
	black = Color3.new(0, 0, 0),
	white = Color3.new(1, 1, 1),
	crimson = Color3.new(0.86, 0.08, 0.24),
	darkred = Color3.new(0.55, 0, 0),
	gold = Color3.new(1, 0.84, 0),
	darkorange = Color3.new(1, 0.55, 0),
	chartreuse = Color3.new(0.5, 1, 0),
	limegreen = Color3.new(0.2, 0.8, 0),
	springgreen = Color3.new(0, 1, 0.5),
	turquoise = Color3.new(0, 0.75, 0.75),
	aqua = Color3.new(0, 1, 1),
	steelblue = Color3.new(0.27, 0.51, 0.71),
	royalblue = Color3.new(0.25, 0.41, 0.88),
	indigo = Color3.new(0.29, 0, 0.51),
	violet = Color3.new(0.93, 0.51, 0.93),
	plum = Color3.new(0.87, 0.63, 0.87),
	olive = Color3.new(0.5, 0.5, 0),
	darkgreen = Color3.new(0, 0.5, 0),
	forestgreen = Color3.new(0.13, 0.55, 0.13),
	navy = Color3.new(0, 0, 0.5),
	midnightblue = Color3.new(0.1, 0.1, 0.44),
	silver = Color3.new(0.75, 0.75, 0.75),
	darksilver = Color3.new(0.66, 0.66, 0.66),
	khaki = Color3.new(0.94, 0.90, 0.55),
	beige = Color3.new(0.96, 0.96, 0.86),
	ivory = Color3.new(1, 1, 0.94),
	cream = Color3.new(1, 0.96, 0.80),
	rose = Color3.new(0.98, 0.80, 0.82),
	salmon = Color3.new(0.98, 0.50, 0.45),
	coral = Color3.new(1, 0.50, 0.31),
	tomato = Color3.new(1, 0.39, 0.12),
}

local function GetColor(input)
	if typeof(input) == "Color3" then
		return input
	elseif typeof(input) == "string" then
		local preset = ColorPresets[string.lower(input)]
		if preset then
			return preset
		end
	end
	return Color3.new(1, 1, 1)
end

export type ESPSettings = {
	Name: string?,

	Model: Instance,
	TextModel: Instance?,

	Show: boolean?,
	MainColor: Color3 | string?,
	MaxViewDistance: number?,

	NameOffset: Vector3?,
	NameSize: number?,

	ShowNameLabel: boolean?,
	ShowHighlight: boolean?,
	ShowBox: boolean?,
	ShowOutlineBox: boolean?,
	ShowSphere: boolean?,
	ShowCylinder: boolean?,

	OutlineThickness: number?,
	OutlineTransparency: number?,

	BoxFillColor: Color3 | string?,

	HighlightFillColor: Color3 | string?,
	HighlightOutlineColor: Color3 | string?,

	HighlightFillTransparency: number?,
	HighlightOutlineTransparency: number?,

	TracerEnabled: boolean?,
	TracerColor: Color3 | string?,
	TracerThickness: number?,
	TracerTransparency: number?,
	TracerFrom: ("Top" | "Bottom" | "Center" | "Mouse")?,

	ArrowEnabled: boolean?,
	ArrowColor: Color3 | string?,
	ArrowDistanceFromCenter: number?,

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
		IgnoreOwnCharacter = false,
		UseRainbowColors = false,

		ShowNameLabels = true,
		ShowOutlines = true,
		ShowDistances = true,
		ShowTracers = true,
		ShowArrows = true,

		TextFont = Enum.Font.RobotoCondensed
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

local function UpdatePlayerVariables(newCharacter, force)
	if force ~= true and Library.GlobalConfig.IgnoreOwnCharacter == true then
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

local AllowedTracerFrom = {
	top = true,
	bottom = true,
	center = true,
	mouse = true,
}

function TracerCreate(tracerSettings, instanceName)
	if Library.Destroyed == true then
		return
	end

	if not tracerSettings.Enabled then
		return
	end
	debug_print("Creating Tracer...")

	tracerSettings.Color = GetColor(tracerSettings.Color)
	tracerSettings.Thickness = typeof(tracerSettings.Thickness) == "number" and tracerSettings.Thickness or 2
	tracerSettings.Transparency = typeof(tracerSettings.Transparency) == "number" and tracerSettings.Transparency or 0
	tracerSettings.From = string.lower(typeof(tracerSettings.From) == "string" and tracerSettings.From or "bottom")
	if AllowedTracerFrom[tracerSettings.From] == nil then
		tracerSettings.From = "bottom"
	end

	local Path2D = InstancesLib.Create("Path2D", {
		Parent = MainGUI,
		Name = if typeof(instanceName) == "string" then instanceName else "Tracer",
		Closed = true,

		Color3 = tracerSettings.Color,
		Thickness = tracerSettings.Thickness,
		Transparency = tracerSettings.Transparency,
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
		Color3 = tracerSettings.Color,
		Thickness = tracerSettings.Thickness,
		Transparency = tracerSettings.Transparency,
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

	debug_print("Tracer created.")
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
	espSettings.MainColor = GetColor(espSettings.MainColor);
	espSettings.MaxViewDistance = if typeof(espSettings.MaxViewDistance) == "number" then espSettings.MaxViewDistance else 5000;

	espSettings.NameOffset = if typeof(espSettings.NameOffset) == "Vector3" then espSettings.NameOffset else Vector3.new();
	espSettings.NameSize = if typeof(espSettings.NameSize) == "number" then espSettings.NameSize else 16;

	espSettings.ShowNameLabel = if typeof(espSettings.ShowNameLabel) == "boolean" then espSettings.ShowNameLabel else true;
	espSettings.ShowHighlight = if typeof(espSettings.ShowHighlight) == "boolean" then espSettings.ShowHighlight else true;
	espSettings.ShowBox = if typeof(espSettings.ShowBox) == "boolean" then espSettings.ShowBox else false;
	espSettings.ShowOutlineBox = if typeof(espSettings.ShowOutlineBox) == "boolean" then espSettings.ShowOutlineBox else false;
	espSettings.ShowSphere = if typeof(espSettings.ShowSphere) == "boolean" then espSettings.ShowSphere else false;
	espSettings.ShowCylinder = if typeof(espSettings.ShowCylinder) == "boolean" then espSettings.ShowCylinder else false;

	espSettings.OutlineThickness = if typeof(espSettings.OutlineThickness) == "number" then espSettings.OutlineThickness else 0.1;
	espSettings.OutlineTransparency = if typeof(espSettings.OutlineTransparency) == "number" then espSettings.OutlineTransparency else 0.65;

	espSettings.BoxFillColor = GetColor(espSettings.BoxFillColor);

	espSettings.HighlightFillColor = GetColor(espSettings.HighlightFillColor);
	espSettings.HighlightOutlineColor = GetColor(espSettings.HighlightOutlineColor);

	espSettings.HighlightFillTransparency = if typeof(espSettings.HighlightFillTransparency) == "number" then espSettings.HighlightFillTransparency else 0.65;
	espSettings.HighlightOutlineTransparency = if typeof(espSettings.HighlightOutlineTransparency) == "number" then espSettings.HighlightOutlineTransparency else 0;

	espSettings.TracerEnabled = if typeof(espSettings.TracerEnabled) == "boolean" then espSettings.TracerEnabled else false;
	espSettings.TracerColor = GetColor(espSettings.TracerColor);
	espSettings.TracerThickness = if typeof(espSettings.TracerThickness) == "number" then espSettings.TracerThickness else 2;
	espSettings.TracerTransparency = if typeof(espSettings.TracerTransparency) == "number" then espSettings.TracerTransparency else 0;
	espSettings.TracerFrom = string.lower(typeof(espSettings.TracerFrom) == "string" and espSettings.TracerFrom or "bottom");

	espSettings.ArrowEnabled = if typeof(espSettings.ArrowEnabled) == "boolean" then espSettings.ArrowEnabled else false;
	espSettings.ArrowColor = GetColor(espSettings.ArrowColor);
	espSettings.ArrowDistanceFromCenter = if typeof(espSettings.ArrowDistanceFromCenter) == "number" then espSettings.ArrowDistanceFromCenter else 300;

	local ESP = {
		Index = RandomString(),
		OriginalSettings = tablefreeze(espSettings),
		CurrentSettings = espSettings,

		Hidden = false,
		Deleted = false,
		Connections = {},
		RenderThread = nil,
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
		Font = Library.GlobalConfig.TextFont,
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

	local Highlighter = nil
	local espTypeUsed = nil
	local isAdornment = false

	if ESP.CurrentSettings.ShowHighlight then
		espTypeUsed = "highlight"
		Highlighter = InstancesLib.Create("Highlight", {
			Parent = ActiveFolder,
			Name = ESP.Index,

			Adornee = ESP.CurrentSettings.Model,

			FillColor = ESP.CurrentSettings.HighlightFillColor or Color3.new(1,1,1),
			OutlineColor = ESP.CurrentSettings.HighlightOutlineColor or Color3.new(1, 1, 1),

			FillTransparency = ESP.CurrentSettings.HighlightFillTransparency or 0.65,
			OutlineTransparency = ESP.CurrentSettings.HighlightOutlineTransparency or 0,
		})
	elseif ESP.CurrentSettings.ShowBox then
		espTypeUsed = "box"
		isAdornment = true
		local _, ModelSize = nil, nil
		if ESP.CurrentSettings.Model:IsA("Model") then
			_, ModelSize = ESP.CurrentSettings.Model:GetBoundingBox()
		else
			if not InstancesLib.TryGetProperty(ESP.CurrentSettings.Model, "Size") then
				local prim = InstancesLib.FindPrimaryPart(ESP.CurrentSettings.Model)
				if not InstancesLib.TryGetProperty(prim, "Size") then
					debug_print("Couldn't get model size, switching to Highlight.", ESP.Index, "-", ESP.CurrentSettings.Name)

					espSettings.ShowHighlight = true
					return Library:Add(espSettings)
				end

				ModelSize = prim.Size
			else
				ModelSize = ESP.CurrentSettings.Model.Size
			end
		end

		Highlighter = InstancesLib.Create("BoxHandleAdornment", {
			Parent = ActiveFolder,
			Name = ESP.Index,

			Adornee = ESP.CurrentSettings.Model,

			AlwaysOnTop = true,
			ZIndex = 10,

			Size = ModelSize,

			Color3 = ESP.CurrentSettings.MainColor or Color3.new(1,1,1),
			Transparency = ESP.CurrentSettings.OutlineTransparency or 0.65,
		})
	elseif ESP.CurrentSettings.ShowOutlineBox then
		espTypeUsed = "outlinebox"
		Highlighter = InstancesLib.Create("SelectionBox", {
			Parent = ActiveFolder,
			Name = ESP.Index,

			Adornee = ESP.CurrentSettings.Model,

			Color3 = ESP.CurrentSettings.MainColor or Color3.new(1,1,1),
			LineThickness = ESP.CurrentSettings.OutlineThickness or 0.1,

			SurfaceColor3 = ESP.CurrentSettings.BoxFillColor or Color3.new(1,1,1),
			SurfaceTransparency = ESP.CurrentSettings.OutlineTransparency or 0.65,
		})
	elseif ESP.CurrentSettings.ShowSphere then
		espTypeUsed = "sphere"
		isAdornment = true
		local _, ModelSize = nil, nil
		if ESP.CurrentSettings.Model:IsA("Model") then
			_, ModelSize = ESP.CurrentSettings.Model:GetBoundingBox()
		else
			if not InstancesLib.TryGetProperty(ESP.CurrentSettings.Model, "Size") then
				local prim = InstancesLib.FindPrimaryPart(ESP.CurrentSettings.Model)
				if not InstancesLib.TryGetProperty(prim, "Size") then
					debug_print("Couldn't get model size, switching to Highlight.", ESP.Index, "-", ESP.CurrentSettings.Name)

					espSettings.ShowHighlight = true
					return Library:Add(espSettings)
				end

				ModelSize = prim.Size
			else
				ModelSize = ESP.CurrentSettings.Model.Size
			end
		end

		Highlighter = InstancesLib.Create("SphereHandleAdornment", {
			Parent = ActiveFolder,
			Name = ESP.Index,

			Adornee = ESP.CurrentSettings.Model,

			AlwaysOnTop = true,
			ZIndex = 10,

			Radius = ModelSize.X * 1.085,
			CFrame = CFrame.new() * CFrame.Angles(math.rad(90), 0, 0),

			Color3 = ESP.CurrentSettings.MainColor or Color3.new(1,1,1),
			Transparency = ESP.CurrentSettings.OutlineTransparency or 0.65,
		})
	elseif ESP.CurrentSettings.ShowCylinder then
		espTypeUsed = "cylinder"
		isAdornment = true
		local _, ModelSize = nil, nil
		if ESP.CurrentSettings.Model:IsA("Model") then
			_, ModelSize = ESP.CurrentSettings.Model:GetBoundingBox()
		else
			if not InstancesLib.TryGetProperty(ESP.CurrentSettings.Model, "Size") then
				local prim = InstancesLib.FindPrimaryPart(ESP.CurrentSettings.Model)
				if not InstancesLib.TryGetProperty(prim, "Size") then
					debug_print("Couldn't get model size, switching to Highlight.", ESP.Index, "-", ESP.CurrentSettings.Name)

					espSettings.ShowHighlight = true
					return Library:Add(espSettings)
				end

				ModelSize = prim.Size
			else
				ModelSize = ESP.CurrentSettings.Model.Size
			end
		end

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
			Transparency = ESP.CurrentSettings.OutlineTransparency or 0.65,
		})
	end

	if not espTypeUsed then
		espSettings.ShowHighlight = true
		return Library:Add(espSettings)
	end

	local Tracer = if ESP.CurrentSettings.TracerEnabled then TracerCreate(ESP.CurrentSettings, ESP.Index) else nil;
	local Arrow = nil;

	if ESP.CurrentSettings.ArrowEnabled then
		debug_print("Creating Arrow...", ESP.Index, "-", ESP.CurrentSettings.Name)
		Arrow = InstancesLib.Create("Frame", {
			Parent = MainGUI,
			Name = ESP.Index,

			Size = UDim2.new(0, 24, 0, 24),
			AnchorPoint = Vector2.new(0.5, 0.5),

			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		});

		local arrowShape = InstancesLib.Create("Frame", {
			Parent = Arrow,
			Size = UDim2.new(0, 24, 0, 24),
			BackgroundColor3 = ESP.CurrentSettings.ArrowColor or Color3.new(1,1,1),
			BorderSizePixel = 0,
		});

		local corner = InstancesLib.Create("UICorner", {
			Parent = arrowShape,
			CornerRadius = UDim.new(0, 0),
		});

		local gradient = InstancesLib.Create("UIGradient", {
			Parent = arrowShape,
			Color = ColorSequence.new{
				ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
				ColorSequenceKeypoint.new(1, Color3.new(0.8,0.8,0.8)),
			},
			Rotation = 45,
		});

		local function drawArrow()
			arrowShape:ClearAllChildren()
			local points = {
				Vector2.new(0, 12),
				Vector2.new(12, 0),
				Vector2.new(24, 12),
				Vector2.new(12, 24),
			}
			local polygon = InstancesLib.Create("ImageLabel", {
				Parent = arrowShape,
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Image = "",
				ScaleType = Enum.ScaleType.Fit,
			})
			polygon.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
			local clip = InstancesLib.Create("Frame", {
				Parent = arrowShape,
				Size = UDim2.new(1, 0, 1, 0),
				ClipsDescendants = true,
				BackgroundTransparency = 1,
			})
			polygon.Parent = clip
		end
		drawArrow()
	end

	function ESP:Destroy()
		if ESP.Deleted == true then
			return;
		end

		debug_print("Deleting ESP...", ESP.Index, "-", ESP.CurrentSettings.Name)
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

	local function Show(forceShow)
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

	local function Hide(forceHide)
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
			(if Library.GlobalConfig.IgnoreOwnCharacter == true then false else not rootPart)
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
			(if Library.GlobalConfig.IgnoreOwnCharacter == true then (camera or rootPart) else rootPart)
		)

		if distanceFromPlayer > ESP.CurrentSettings.MaxViewDistance then
			Hide()
			return
		end

		if Arrow then
			Arrow.Visible = Library.GlobalConfig.ShowArrows == true and ESP.CurrentSettings.ArrowEnabled == true and (isOnScreen ~= true)

			if Arrow.Visible then
				local screenSize = camera.ViewportSize
				local centerPos = Vector2.new(screenSize.X / 2, screenSize.Y / 2)

				local partPos = Vector2.new(screenPos.X, screenPos.Y)

				local IsInverted = screenPos.Z <= 0
				local invert = (IsInverted and -1 or 1)

				local direction = (partPos - centerPos)
				local arctan = math.atan2(direction.Y, direction.X)
				local angle = math.deg(arctan) + 90
				local distance = (ESP.CurrentSettings.ArrowDistanceFromCenter * 0.001) * screenSize.Y

				Arrow.Rotation = angle + 180 * (IsInverted and 0 or 1)
				Arrow.Position = UDim2.new(
					0,
					centerPos.X + (distance * math.cos(arctan) * invert),
					0,
					centerPos.Y + (distance * math.sin(arctan) * invert)
				)
				Arrow:FindFirstChild("Frame").BackgroundColor3 =
					if Library.GlobalConfig.UseRainbowColors then Library.RainbowColor else ESP.CurrentSettings.ArrowColor;
			end
		end

		if isOnScreen == false then
			Hide()
			return
		else Show() end

		if Tracer then
			Tracer.Visible = Library.GlobalConfig.ShowTracers == true and ESP.CurrentSettings.TracerEnabled == true;

			if Tracer.Visible then
				if ESP.CurrentSettings.TracerFrom == "mouse" then
					local mousePos = UserInputService:GetMouseLocation()
					Tracer.From = Vector2.new(mousePos.X, mousePos.Y)
				elseif ESP.CurrentSettings.TracerFrom == "top" then
					Tracer.From = Vector2.new(camera.ViewportSize.X / 2, 0)
				elseif ESP.CurrentSettings.TracerFrom == "center" then
					Tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
				else
					Tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
				end

				Tracer.To = Vector2.new(screenPos.X, screenPos.Y)

				Tracer.Transparency = ESP.CurrentSettings.TracerTransparency
				Tracer.Thickness = ESP.CurrentSettings.TracerThickness
				Tracer.Color3 = Library.GlobalConfig.UseRainbowColors and Library.RainbowColor
					or ESP.CurrentSettings.TracerColor
			end
		end

		if Billboard then
			Billboard.Enabled = Library.GlobalConfig.ShowNameLabels == true and ESP.CurrentSettings.ShowNameLabel == true;

			if Billboard.Enabled then
				if Library.GlobalConfig.ShowDistances then
					BillboardText.Text = string.format(
						'%s\n<font size="%d">[%s]</font>',
						ESP.CurrentSettings.Name,
						ESP.CurrentSettings.NameSize - 3,
						math.floor(distanceFromPlayer)
					)
				else
					BillboardText.Text = ESP.CurrentSettings.Name
				end

				BillboardText.Font = Library.GlobalConfig.TextFont
				BillboardText.TextColor3 =
					if Library.GlobalConfig.UseRainbowColors then Library.RainbowColor else ESP.CurrentSettings.MainColor;
				BillboardText.TextSize = ESP.CurrentSettings.NameSize
			end
		end

		if Highlighter then
			Highlighter.Parent = if Library.GlobalConfig.ShowOutlines == true then ActiveFolder else StorageFolder;
			Highlighter.Adornee = if Library.GlobalConfig.ShowOutlines == true then ESP.CurrentSettings.Model else nil;

			if Highlighter.Adornee then
				if isAdornment then
					Highlighter.Color3 = Library.GlobalConfig.UseRainbowColors and Library.RainbowColor or ESP.CurrentSettings.MainColor
					Highlighter.Transparency = ESP.CurrentSettings.OutlineTransparency

				elseif espTypeUsed == "outlinebox" then
					Highlighter.Color3 = Library.GlobalConfig.UseRainbowColors and Library.RainbowColor or ESP.CurrentSettings.MainColor
					Highlighter.LineThickness = ESP.CurrentSettings.OutlineThickness

					Highlighter.SurfaceColor3 = ESP.CurrentSettings.BoxFillColor
					Highlighter.SurfaceTransparency = ESP.CurrentSettings.OutlineTransparency

				else
					Highlighter.FillColor =
						if Library.GlobalConfig.UseRainbowColors then Library.RainbowColor else ESP.CurrentSettings.HighlightFillColor;
					Highlighter.OutlineColor =
						if Library.GlobalConfig.UseRainbowColors then Library.RainbowColor else ESP.CurrentSettings.HighlightOutlineColor;

					Highlighter.FillTransparency = ESP.CurrentSettings.HighlightFillTransparency
					Highlighter.OutlineTransparency = ESP.CurrentSettings.HighlightOutlineTransparency
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
