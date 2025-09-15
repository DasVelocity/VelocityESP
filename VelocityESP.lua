local VERSION = "1.0 FunGlow";
local ColorPresets = {
	red = Color3.fromRGB(255, 0, 0),
	green = Color3.fromRGB(0, 255, 0),
	blue = Color3.fromRGB(0, 0, 255),
	yellow = Color3.fromRGB(255, 255, 0),
	cyan = Color3.fromRGB(0, 255, 255),
	magenta = Color3.fromRGB(255, 0, 255),
	white = Color3.fromRGB(255, 255, 255),
	black = Color3.fromRGB(0, 0, 0),
	orange = Color3.fromRGB(255, 165, 0),
	purple = Color3.fromRGB(128, 0, 128),
	pink = Color3.fromRGB(255, 192, 203),
	brown = Color3.fromRGB(165, 42, 42),
	gray = Color3.fromRGB(128, 128, 128),
	lightgray = Color3.fromRGB(211, 211, 211),
	darkgray = Color3.fromRGB(64, 64, 64),
	lime = Color3.fromRGB(50, 205, 50),
	navy = Color3.fromRGB(0, 0, 128),
	gold = Color3.fromRGB(255, 215, 0),
	silver = Color3.fromRGB(192, 192, 192),
	crimson = Color3.fromRGB(220, 20, 60),
	azure = Color3.fromRGB(240, 255, 255),
	beige = Color3.fromRGB(245, 245, 220),
	coral = Color3.fromRGB(255, 127, 80),
	fuchsia = Color3.fromRGB(255, 0, 255),
	indigo = Color3.fromRGB(75, 0, 130),
	lavender = Color3.fromRGB(230, 230, 250),
	maroon = Color3.fromRGB(128, 0, 0),
	olive = Color3.fromRGB(128, 128, 0),
	plum = Color3.fromRGB(221, 160, 221),
	salmon = Color3.fromRGB(250, 128, 114),
	sienna = Color3.fromRGB(160, 82, 45),
	tan = Color3.fromRGB(210, 180, 140),
	teal = Color3.fromRGB(0, 128, 128),
	turquoise = Color3.fromRGB(64, 224, 208),
	violet = Color3.fromRGB(238, 130, 238),
	wheat = Color3.fromRGB(245, 222, 179),
	aliceblue = Color3.fromRGB(240, 248, 255),
	antiquewhite = Color3.fromRGB(250, 235, 215),
	aquamarine = Color3.fromRGB(127, 255, 212),
	bisque = Color3.fromRGB(255, 228, 196),
	blanchedalmond = Color3.fromRGB(255, 235, 205),
	blueviolet = Color3.fromRGB(138, 43, 226),
	cadetblue = Color3.fromRGB(95, 158, 160),
	chartreuse = Color3.fromRGB(127, 255, 0),
	chocolate = Color3.fromRGB(210, 105, 30),
	cornflowerblue = Color3.fromRGB(100, 149, 237),
	darkblue = Color3.fromRGB(0, 0, 139),
	darkgreen = Color3.fromRGB(0, 100, 0),
	darkorange = Color3.fromRGB(255, 140, 0),
	darkred = Color3.fromRGB(139, 0, 0)
};

local function ResolveColor(color)
	if typeof(color) == "string" then
		local preset = ColorPresets[string.lower(color)]
		if preset then return preset end
	end
	return color
end

if getgenv().FunGlow then
	return getgenv().FunGlow
end

export type TargetLineSettings = {
	ShowLine: boolean,

	LineColor: Color3?,
	LineWidth: number?,
	LineOpacity: number?,
	StartPoint: ("Top" | "Bottom" | "Center" | "Mouse")?,
}

export type ScreenArrowSettings = {
	ShowArrow: boolean,

	ArrowColor: Color3?,
	ArrowDist: number?,
}

export type GlowSettings = {
	LabelText: string?,

	TargetModel: Instance,
	TextAnchor: Instance?,

	IsVisible: boolean?,
	MainColor: Color3?,
	MaxViewDist: number?,

	TextOffset: Vector3?,
	TextScale: number?,

	ESPTypes: {
		Text: boolean?,
		Sphere: boolean?,
		Cylinder: boolean?,
		Box: boolean?,
		BoxOutline: boolean?,
		Highlight: boolean?
	}?,
	OutlineWidth: number?,
	FillOpacity: number?,

	BoxFillColor: Color3?,

	InnerColor: Color3?,
	EdgeColor: Color3?,

	InnerOpacity: number?,
	EdgeOpacity: number?,

	TargetLine: TargetLineSettings?,
	ScreenArrow: ScreenArrowSettings?,

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
		IgnoreSelf = false,
		ColorCycle = false,

		ShowNames = true,
		ShowESP = true,
		ShowDist = true,
		ShowLines = true,
		ShowArrows = true,

		TextFont = Enum.Font.RobotoCondensed
	},

	RainbowHueSetup = 0,
	RainbowHue = 0,
	RainbowStep = 0,
	RainbowColor = Color3.new()
}

local character: Model
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
	if force ~= true and Library.GlobalConfig.IgnoreSelf == true then
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

	getgenv().FunGlow = nil;
end

local AllowedStartPoint = {
	top = true,
	bottom = true,
	center = true,
	mouse = true,
}

local AllowedESPType = {
	text = true,
	sphere = true,
	cylinder = true,
	box = true,
	boxoutline = true,
	highlight = true,
}

function TargetLineCreate(lineSettings, instanceName)
	if Library.Destroyed == true then
		return
	end

	if not lineSettings then
		lineSettings = {}
	end

	if lineSettings.ShowLine ~= true then
		return
	end

	lineSettings.LineColor = ResolveColor(lineSettings.LineColor or Color3.new(1,1,1))
	lineSettings.LineWidth = typeof(lineSettings.LineWidth) == "number" and lineSettings.LineWidth or 2
	lineSettings.LineOpacity = typeof(lineSettings.LineOpacity) == "number" and lineSettings.LineOpacity or 0
	lineSettings.StartPoint = string.lower(typeof(lineSettings.StartPoint) == "string" and lineSettings.StartPoint or "bottom")
	if AllowedStartPoint[lineSettings.StartPoint] == nil then
		lineSettings.StartPoint = "bottom"
	end

	local Path2D = InstancesLib.Create("Path2D", {
		Parent = MainGUI,
		Name = if typeof(instanceName) == "string" then instanceName else "TargetLine",
		Closed = true,

		Color3 = lineSettings.LineColor,
		Thickness = lineSettings.LineWidth,
		Transparency = lineSettings.LineOpacity,
	})

	local function UpdateLine(from, to)
		Path2D:SetControlPoints({
			Path2DControlPoint.new(UDim2.fromOffset(from.X, from.Y)),
			Path2DControlPoint.new(UDim2.fromOffset(to.X, to.Y))
		})
	end

	local data = {
		From = UDim2.fromOffset(0, 0),
		To = UDim2.fromOffset(0, 0),

		Visible = true,
		Color3 = lineSettings.LineColor,
		Thickness = lineSettings.LineWidth,
		Transparency = lineSettings.LineOpacity,
	}
	UpdateLine(data.From, data.To);

	local proxy = {}
	local LineMT = {
		__newindex = function(table, key, value)
			if not Path2D then
				return
			end

			if key == "From" then
				UpdateLine(value, data.To)

			elseif key == "To" then
				UpdateLine(data.From, value)

			elseif key == "LineOpacity" or key == "LineWidth" then
				Path2D[key:lower()] = value

			elseif key == "LineColor" then
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

	return setmetatable(proxy, LineMT) :: typeof(data)
end

function Library:Add(glowSettings)
	if Library.Destroyed == true then
		return
	end

	assert(typeof(glowSettings) == "table", "glowSettings; expected table, got " .. typeof(glowSettings))
	assert(
		typeof(glowSettings.TargetModel) == "Instance",
		"glowSettings.TargetModel; expected Instance, got " .. typeof(glowSettings.TargetModel)
	)

	local espTypes = glowSettings.ESPTypes or {Text = false, Sphere = false, Cylinder = false, Box = false, BoxOutline = false, Highlight = true}
	local espType = nil
	for k, v in pairs(espTypes) do
		if v then
			if espType then
				espType = "Highlight"
				break
			end
			espType = k
		end
	end
	if not espType then espType = "Highlight" end

	espType = string.lower(espType)
	if espType == "sphere" then espType = "sphereadornment" end
	if espType == "cylinder" then espType = "cylinderadornment" end
	if espType == "box" then espType = "adornment" end
	if espType == "boxoutline" then espType = "selectionbox" end
	assert(AllowedESPType[espType] == true, "glowSettings.ESPType; invalid ESPType")

	glowSettings.LabelText = if typeof(glowSettings.LabelText) == "string" then glowSettings.LabelText else glowSettings.TargetModel.Name;
	glowSettings.TextAnchor = if typeof(glowSettings.TextAnchor) == "Instance" then glowSettings.TextAnchor else glowSettings.TargetModel;

	glowSettings.IsVisible = if typeof(glowSettings.IsVisible) == "boolean" then glowSettings.IsVisible else true;
	glowSettings.MainColor = ResolveColor(glowSettings.MainColor or Color3.new(1,1,1));
	glowSettings.MaxViewDist = if typeof(glowSettings.MaxViewDist) == "number" then glowSettings.MaxViewDist else 5000;

	glowSettings.TextOffset = if typeof(glowSettings.TextOffset) == "Vector3" then glowSettings.TextOffset else Vector3.new();
	glowSettings.TextScale = if typeof(glowSettings.TextScale) == "number" then glowSettings.TextScale else 16;

	glowSettings.OutlineWidth = if typeof(glowSettings.OutlineWidth) == "number" then glowSettings.OutlineWidth else 0.1;
	glowSettings.FillOpacity = if typeof(glowSettings.FillOpacity) == "number" then glowSettings.FillOpacity else 0.65;

	glowSettings.BoxFillColor = ResolveColor(glowSettings.BoxFillColor or Color3.new(1,1,1));
	glowSettings.InnerColor = ResolveColor(glowSettings.InnerColor or Color3.new(1,1,1));
	glowSettings.EdgeColor = ResolveColor(glowSettings.EdgeColor or Color3.new(1, 1, 1));

	glowSettings.InnerOpacity = if typeof(glowSettings.InnerOpacity) == "number" then glowSettings.InnerOpacity else 0.65;
	glowSettings.EdgeOpacity = if typeof(glowSettings.EdgeOpacity) == "number" then glowSettings.EdgeOpacity else 0;

	glowSettings.TargetLine = if typeof(glowSettings.TargetLine) == "table" then glowSettings.TargetLine else { ShowLine = false };
	glowSettings.ScreenArrow = if typeof(glowSettings.ScreenArrow) == "table" then glowSettings.ScreenArrow else { ShowArrow = false };

	local ESP = {
		Index = RandomString(),
		OriginalSettings = tablefreeze(glowSettings),
		CurrentSettings = glowSettings,

		Hidden = false,
		Deleted = false,
		Connections = {},
		RenderThread = nil
	}

	local Billboard = InstancesLib.Create("BillboardGui", {
		Parent = BillboardGUI,
		Name = ESP.Index,

		Enabled = true,
		ResetOnSpawn = false,
		AlwaysOnTop = true,
		Size = UDim2.new(0, 200, 0, 50),

		Adornee = ESP.CurrentSettings.TextAnchor or ESP.CurrentSettings.TargetModel,
		StudsOffset = ESP.CurrentSettings.TextOffset or Vector3.new(),
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

		Text = ESP.CurrentSettings.LabelText,
		TextColor3 = ESP.CurrentSettings.MainColor or Color3.new(1,1,1),
		TextSize = ESP.CurrentSettings.TextScale or 16,
	})

	InstancesLib.Create("UIStroke", {
		Parent = BillboardText
	})

	local Highlighter, IsAdornment = nil, not not string.match(string.lower(ESP.OriginalSettings.ESPTypes and "highlight" or espType), "adornment") or espType == "text"

	if espType == "text" then
	elseif IsAdornment then
		local _, ModelSize
		if ESP.CurrentSettings.TargetModel:IsA("Model") then
			_, ModelSize = ESP.CurrentSettings.TargetModel:GetBoundingBox()
		else
			if not InstancesLib.TryGetProperty(ESP.CurrentSettings.TargetModel, "Size") then
				local prim = InstancesLib.FindPrimaryPart(ESP.CurrentSettings.TargetModel)
				if not InstancesLib.TryGetProperty(prim, "Size") then

					glowSettings.ESPTypes = {Highlight = true}
					return Library:Add(glowSettings)
				end

				ModelSize = prim.Size
			else
				ModelSize = ESP.CurrentSettings.TargetModel.Size
			end
		end

		if espType == "sphereadornment" then
			Highlighter = InstancesLib.Create("SphereHandleAdornment", {
				Parent = ActiveFolder,
				Name = ESP.Index,

				Adornee = ESP.CurrentSettings.TargetModel,

				AlwaysOnTop = true,
				ZIndex = 10,

				Radius = ModelSize.X * 1.085,
				CFrame = CFrame.new() * CFrame.Angles(math.rad(90), 0, 0),

				Color3 = ESP.CurrentSettings.MainColor or Color3.new(1,1,1),
				Transparency = ESP.CurrentSettings.FillOpacity or 0.65,
			})
		elseif espType == "cylinderadornment" then
			Highlighter = InstancesLib.Create("CylinderHandleAdornment", {
				Parent = ActiveFolder,
				Name = ESP.Index,

				Adornee = ESP.CurrentSettings.TargetModel,

				AlwaysOnTop = true,
				ZIndex = 10,

				Height = ModelSize.Y * 2,
				Radius = ModelSize.X * 1.085,
				CFrame = CFrame.new() * CFrame.Angles(math.rad(90), 0, 0),

				Color3 = ESP.CurrentSettings.MainColor or Color3.new(1,1,1),
				Transparency = ESP.CurrentSettings.FillOpacity or 0.65,
			})
		else
			Highlighter = InstancesLib.Create("BoxHandleAdornment", {
				Parent = ActiveFolder,
				Name = ESP.Index,

				Adornee = ESP.CurrentSettings.TargetModel,

				AlwaysOnTop = true,
				ZIndex = 10,

				Size = ModelSize,

				Color3 = ESP.CurrentSettings.MainColor or Color3.new(1,1,1),
				Transparency = ESP.CurrentSettings.FillOpacity or 0.65,
			})
		end
	elseif espType == "selectionbox" then
		Highlighter = InstancesLib.Create("SelectionBox", {
			Parent = ActiveFolder,
			Name = ESP.Index,

			Adornee = ESP.CurrentSettings.TargetModel,

			Color3 = ESP.CurrentSettings.MainColor or Color3.new(1,1,1),
			LineThickness = ESP.CurrentSettings.OutlineWidth or 0.1,

			SurfaceColor3 = ESP.CurrentSettings.BoxFillColor or Color3.new(1,1,1),
			SurfaceTransparency = ESP.CurrentSettings.FillOpacity or 0.65,
		})
	elseif espType == "highlight" then
		Highlighter = InstancesLib.Create("Highlight", {
			Parent = ActiveFolder,
			Name = ESP.Index,

			Adornee = ESP.CurrentSettings.TargetModel,

			FillColor = ESP.CurrentSettings.InnerColor or Color3.new(1,1,1),
			OutlineColor = ESP.CurrentSettings.EdgeColor or Color3.new(1, 1, 1),

			FillTransparency = ESP.CurrentSettings.InnerOpacity or 0.65,
			OutlineTransparency = ESP.CurrentSettings.EdgeOpacity or 0,
		})
	end

	local TargetLine = if typeof(ESP.OriginalSettings.TargetLine) == "table" then TargetLineCreate(ESP.CurrentSettings.TargetLine, ESP.Index) else nil;
	local Arrow
	if typeof(ESP.OriginalSettings.ScreenArrow) == "table" and ESP.OriginalSettings.ScreenArrow.ShowArrow then
		Arrow = InstancesLib.Create("ImageLabel", {
			Parent = MainGUI,
			Name = ESP.Index,

			Size = UDim2.new(0, 36, 0, 36),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,

			AnchorPoint = Vector2.new(0.5, 0.5),

			BackgroundTransparency = 1,
			BorderSizePixel = 0,

			Image = "http://www.roblox.com/asset/?id=6034616401",
			ImageColor3 = ESP.CurrentSettings.MainColor or Color3.new(1,1,1),
		});

		ESP.CurrentSettings.ScreenArrow.ArrowDist = if typeof(ESP.CurrentSettings.ScreenArrow.ArrowDist) == "number" then ESP.CurrentSettings.ScreenArrow.ArrowDist else 250;
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

		if Billboard then Billboard:Destroy() end
		if Highlighter then Highlighter:Destroy() end
		if TargetLine then TargetLine:Destroy() end
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
	end

	local function Show(forceShow)
		if not (ESP and ESP.Deleted ~= true) then return end
		if forceShow ~= true and not ESP.Hidden then
			return
		end

		ESP.Hidden = false;

		Billboard.Enabled = true;

		if Highlighter then
			Highlighter.Adornee = ESP.CurrentSettings.TargetModel;
			Highlighter.Parent = ActiveFolder;
		end

		if TargetLine then
			TargetLine.Visible = true;
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

		if TargetLine then
			TargetLine.Visible = false;
		end

		if Arrow then
			Arrow.Visible = false;
		end
	end

	function ESP:Show(force)
		ESP.CurrentSettings.IsVisible = true
		Show(force);
	end

	function ESP:Hide(force)
		if not (ESP and ESP.CurrentSettings and ESP.Deleted ~= true) then return end

		ESP.CurrentSettings.IsVisible = false
		Hide(force);
	end

	function ESP:ToggleVisibility(force)
		ESP.CurrentSettings.IsVisible = not ESP.CurrentSettings.IsVisible
		if ESP.CurrentSettings.IsVisible then
			Show(force);
		else
			Hide(force);
		end
	end

	function ESP:Render()
		if not (ESP and ESP.CurrentSettings and ESP.Deleted ~= true) then return end
		if
			ESP.CurrentSettings.IsVisible == false or
			not camera or
			(if Library.GlobalConfig.IgnoreSelf == true then false else not rootPart)
		then
			Hide()
			return
		end

		if not ESP.CurrentSettings.ModelRoot then
			ESP.CurrentSettings.ModelRoot = InstancesLib.FindPrimaryPart(ESP.CurrentSettings.TargetModel)
		end

		local screenPos, isOnScreen = worldToViewport(
			GetPivot(ESP.CurrentSettings.ModelRoot or ESP.CurrentSettings.TargetModel).Position
		)

		local distanceFromPlayer = InstancesLib.DistanceFrom(
			(ESP.CurrentSettings.ModelRoot or ESP.CurrentSettings.TargetModel),
			(if Library.GlobalConfig.IgnoreSelf == true then (camera or rootPart) else rootPart)
		)

		if distanceFromPlayer > ESP.CurrentSettings.MaxViewDist then
			Hide()
			return
		end

		if Arrow then
			Arrow.Visible = Library.GlobalConfig.ShowArrows == true and ESP.CurrentSettings.ScreenArrow.ShowArrow == true and (isOnScreen ~= true)

			if Arrow.Visible then
				local screenSize = camera.ViewportSize
				local centerPos = Vector2.new(screenSize.X / 2, screenSize.Y / 2)

				local partPos = Vector2.new(screenPos.X, screenPos.Y)

				local IsInverted = screenPos.Z <= 0
				local invert = (IsInverted and -1 or 1)

				local direction = (partPos - centerPos)
				local arctan = math.atan2(direction.Y, direction.X)
				local angle = math.deg(arctan) + 90
				local distance = (ESP.CurrentSettings.ScreenArrow.ArrowDist * 0.001) * screenSize.Y

				Arrow.Rotation = angle + 180 * (IsInverted and 0 or 1)
				Arrow.Position = UDim2.new(
					0,
					centerPos.X + (distance * math.cos(arctan) * invert),
					0,
					centerPos.Y + (distance * math.sin(arctan) * invert)
				)
				Arrow.ImageColor3 =
					if Library.GlobalConfig.ColorCycle then Library.RainbowColor else ESP.CurrentSettings.ScreenArrow.ArrowColor or ESP.CurrentSettings.MainColor;
			end
		end

		if isOnScreen == false then
			Hide()
			return
		else Show() end

		if TargetLine then
			TargetLine.Visible = Library.GlobalConfig.ShowLines == true and ESP.CurrentSettings.TargetLine.ShowLine == true;

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

				TargetLine.LineOpacity = ESP.CurrentSettings.TargetLine.LineOpacity
				TargetLine.LineWidth = ESP.CurrentSettings.TargetLine.LineWidth
				TargetLine.LineColor = Library.GlobalConfig.ColorCycle and Library.RainbowColor
					or (ESP.CurrentSettings.TargetLine.LineColor or ESP.CurrentSettings.MainColor)
			end
		end

		if Billboard then
			Billboard.Enabled = Library.GlobalConfig.ShowNames == true;

			if Billboard.Enabled then
				if Library.GlobalConfig.ShowDist then
					BillboardText.Text = string.format(
						'%s\n<font size="%d">[%s]</font>',
						ESP.CurrentSettings.LabelText,
						ESP.CurrentSettings.TextScale - 3,
						math.floor(distanceFromPlayer)
					)
				else
					BillboardText.Text = ESP.CurrentSettings.LabelText
				end

				BillboardText.Font = Library.GlobalConfig.TextFont
				BillboardText.TextColor3 =
					if Library.GlobalConfig.ColorCycle then Library.RainbowColor else ESP.CurrentSettings.MainColor;
				BillboardText.TextSize = ESP.CurrentSettings.TextScale
			end
		end

		if Highlighter then
			Highlighter.Parent = if Library.GlobalConfig.ShowESP == true then ActiveFolder else StorageFolder;
			Highlighter.Adornee = if Library.GlobalConfig.ShowESP == true then ESP.CurrentSettings.TargetModel else nil;

			if Highlighter.Adornee then
				if IsAdornment then
					Highlighter.Color3 = Library.GlobalConfig.ColorCycle and Library.RainbowColor or ESP.CurrentSettings.MainColor
					Highlighter.Transparency = ESP.CurrentSettings.FillOpacity

				elseif espType == "selectionbox" then
					Highlighter.Color3 = Library.GlobalConfig.ColorCycle and Library.RainbowColor or ESP.CurrentSettings.MainColor
					Highlighter.LineThickness = ESP.CurrentSettings.OutlineWidth

					Highlighter.SurfaceColor3 = ESP.CurrentSettings.BoxFillColor
					Highlighter.SurfaceTransparency = ESP.CurrentSettings.FillOpacity

				else
					Highlighter.FillColor =
						if Library.GlobalConfig.ColorCycle then Library.RainbowColor else ESP.CurrentSettings.InnerColor;
					Highlighter.OutlineColor =
						if Library.GlobalConfig.ColorCycle then Library.RainbowColor else ESP.CurrentSettings.EdgeColor;

					Highlighter.FillTransparency = ESP.CurrentSettings.InnerOpacity
					Highlighter.OutlineTransparency = ESP.CurrentSettings.EdgeOpacity
				end
			end
		end
	end

	if not ESP.OriginalSettings.IsVisible then
		Hide()
	end

	ESP.RenderThread = coroutine.create(function()
		while true do
			local success, errorMessage = pcall(ESP.Render, ESP)
			if not success then
				task.defer(function() error("Failed to render Glow: " .. errorMessage) end)
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

		if not ESP.CurrentSettings.TargetModel or not ESP.CurrentSettings.TargetModel.Parent then
			ESP:Destroy()
			continue
		end

		pcall(coroutine.resume, ESP.RenderThread)
	end
end))

getgenv().FunGlow = Library
return Library
