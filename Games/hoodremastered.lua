-- Load Void UI Library
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/weakhoes/Roblox-UI-Libs/refs/heads/main/Void%20Lib/Void%20Lib%20Source.lua"))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

-- Create watermark and main window
local watermark = library:Watermark("Silent.cc | 0 fps | v1.4 | ultimate pro sex edition")

local main = library:Load{
	Name = "Silent.cc",
	SizeX = 600,
	SizeY = 650,
	Theme = "Midnight",
	Extension = "json",
	Folder = "Silent"
}

local function ensureFoldersExist()
	pcall(function()
		if not isfolder("Silent_Configs") then
			makefolder("Silent_Configs")
		end
	end)
end

-- Silent Aim Variables
local silentAimEnabled = false
local silentAimTargetPart = "Head"
local silentAimFOV = 100
local silentAimShowFOV = true
local silentAimFOVCircle = Drawing.new("Circle")
silentAimFOVCircle.Radius = silentAimFOV
silentAimFOVCircle.Thickness = 2
silentAimFOVCircle.Transparency = 1
silentAimFOVCircle.Color = Color3.fromRGB(255, 0, 0)
silentAimFOVCircle.Filled = false
silentAimFOVCircle.Visible = silentAimShowFOV

local function getSilentAimTarget()
	local closest, distance = nil, math.huge
	local mousePos = UserInputService:GetMouseLocation()

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local character = player.Character
			local targetPart = character:FindFirstChild(silentAimTargetPart) or character:FindFirstChild("HumanoidRootPart")

			if targetPart then
				local pos, visible = Camera:WorldToViewportPoint(targetPart.Position)
				if visible and pos.Z > 0 then
					local dist = (mousePos - Vector2.new(pos.X, pos.Y)).Magnitude
					if dist < silentAimFOV and dist < distance then
						closest = targetPart
						distance = dist
					end
				end
			end
		end
	end
	return closest
end

local mt = getrawmetatable(game)
setreadonly(mt, false)
local oldNamecall = mt.__namecall
local spoofedMousePos = nil

mt.__namecall = newcclosure(function(self, ...)
	local method = getnamecallmethod()
	local args = {...}
	if silentAimEnabled and tostring(method) == "FireServer" and tostring(self) == "MainEvent" then
		if args[1] == "UpdateMousePos" and spoofedMousePos then
			args[2] = spoofedMousePos
			return oldNamecall(self, unpack(args))
		end
	end

	return oldNamecall(self, ...)
end)

setreadonly(mt, true)

RunService.RenderStepped:Connect(function()
	if silentAimEnabled then
		local target = getSilentAimTarget()
		if target then
			spoofedMousePos = target.Position
		else
			spoofedMousePos = nil
		end
	else
		spoofedMousePos = nil
	end
end)

RunService.RenderStepped:Connect(function()
	local mousePos = UserInputService:GetMouseLocation()
	silentAimFOVCircle.Position = mousePos
	silentAimFOVCircle.Visible = silentAimShowFOV and silentAimEnabled
end)

-- Anti-Lock Variables
local antiLockEnabled = false
local antiLockConnection = nil
local originalCFrame = nil
local amplitude = 5
local frequency = 20

local function enableAntiLock()
	if antiLockConnection then return end

	antiLockConnection = RunService.RenderStepped:Connect(function()
		local char = LocalPlayer.Character
		if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then return end
		local hrp = char.HumanoidRootPart
		local humanoid = char.Humanoid

		local offset = math.sin(tick() * frequency) * amplitude

		hrp.Velocity = Vector3.new(hrp.Velocity.X, offset, hrp.Velocity.Z)

		humanoid:Move(humanoid.MoveDirection, false)
	end)
end

local function disableAntiLock()
	if antiLockConnection then
		antiLockConnection:Disconnect()
		antiLockConnection = nil
	end

	local char = LocalPlayer.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		char.HumanoidRootPart.Velocity = Vector3.zero
	end
end

-- ESP Variables
local boxes = {}
local espEnabled = false
local gradientEnabled = false
local gradientDirection = "Vertical"
local colorTop = Color3.fromRGB(255, 255, 255)
local colorBottom = Color3.fromRGB(0, 0, 0)
local defaultColor = Color3.fromRGB(255, 255, 255)

local MIN_WIDTH = 20
local MAX_WIDTH = 120
local MIN_HEIGHT = 35
local MAX_HEIGHT = 180
local SEGMENTS = 15

-- Aimbot Variables
local aimbotEnabled = false
local showFOV = true
local fovColor = Color3.fromRGB(255, 255, 255)
local fovSize = 100
local aimbotKey = Enum.KeyCode.E
local notify = true
local smoothing = 5
local targetPart = "Head"
local prediction = 0.165
local autoPrediction = true
local wallcheckEnabled = true

local fovCircle = Drawing.new("Circle")
fovCircle.Radius = fovSize
fovCircle.Thickness = 2
fovCircle.Transparency = 1
fovCircle.Color = fovColor
fovCircle.Filled = false
fovCircle.Visible = showFOV

local closestTarget = nil
local aiming = false

-- Helper Functions
local function interpolateColor(color1, color2, t)
	return Color3.new(
		color1.R + (color2.R - color1.R) * t,
		color1.G + (color2.G - color1.G) * t,
		color1.B + (color2.B - color1.B) * t
	)
end

local function hasWallBetween(origin, target)
	if not wallcheckEnabled then return false end
	
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.FilterDescendantsInstances = {LocalPlayer.Character, target.Parent}
	
	local result = Workspace:Raycast(origin, (target.Position - origin), params)
	
	return result ~= nil
end

-- ESP Functions
local function createEsp(player)
	if player == LocalPlayer then return end
	if boxes[player] then return end

	local lines = {}
	for i = 1, SEGMENTS * 4 do
		local line = Drawing.new("Line")
		line.Thickness = 1
		line.Visible = false
		table.insert(lines, line)
	end

	boxes[player] = lines

	player.CharacterAdded:Connect(function()
	end)
end

local function delBoxes()
	for _, lines in pairs(boxes) do
		for _, line in pairs(lines) do
			line:Remove()
		end
	end
	table.clear(boxes)
end

local function updateBoxes()
	if not espEnabled then return end

	for player, lines in pairs(boxes) do
		local character = player.Character
		if character and character:FindFirstChild("HumanoidRootPart") then
			local hrp = character.HumanoidRootPart
			local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)

			if onScreen then
				local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
				local scale = math.max(1 / (distance / 100), 0.3)
				
				local width = math.clamp(60 * scale, MIN_WIDTH, MAX_WIDTH)
				local height = math.clamp(90 * scale, MIN_HEIGHT, MAX_HEIGHT)
				
				local topLeft = Vector2.new(pos.X - width/2, pos.Y - height/2)
				local topRight = Vector2.new(pos.X + width/2, pos.Y - height/2)
				local bottomLeft = Vector2.new(pos.X - width/2, pos.Y + height/2)
				local bottomRight = Vector2.new(pos.X + width/2, pos.Y + height/2)

				local segmentIndex = 1

				local function drawSegment(p1, p2, axis)
					for i = 0, SEGMENTS - 1 do
						local t1 = i / SEGMENTS
						local t2 = (i + 1) / SEGMENTS
						local start = p1:Lerp(p2, t1)
						local finish = p1:Lerp(p2, t2)
						
						local rel = 0
						if axis == "Vertical" then
							rel = (start.Y - topLeft.Y) / height
						else
							rel = (start.X - topLeft.X) / width
						end

						local color = defaultColor
						if gradientEnabled then
							color = interpolateColor(colorTop, colorBottom, rel)
						end

						local line = lines[segmentIndex]
						if line then
							segmentIndex = segmentIndex + 1
							line.From = start
							line.To = finish
							line.Color = color
							line.Visible = true
						end
					end
				end

				drawSegment(topLeft, topRight, gradientDirection)
				drawSegment(topRight, bottomRight, gradientDirection)
				drawSegment(bottomRight, bottomLeft, gradientDirection)
				drawSegment(bottomLeft, topLeft, gradientDirection)

				for i = segmentIndex, #lines do
					lines[i].Visible = false
				end
			else
				for _, line in pairs(lines) do
					line.Visible = false
				end
			end
		else
			for _, line in pairs(lines) do
				line.Visible = false
			end
		end
	end
end

-- Aimbot Functions
local function getClosestPlayer()
	local closest, distance = nil, math.huge
	local mousePos = UserInputService:GetMouseLocation()
	
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local character = player.Character
			local targetBodyPart = character:FindFirstChild(targetPart) or character:FindFirstChild("HumanoidRootPart")
			
			if targetBodyPart then
				local pos, visible = Camera:WorldToViewportPoint(targetBodyPart.Position)
				if visible and pos.Z > 0 then
					local dist = (mousePos - Vector2.new(pos.X, pos.Y)).Magnitude
					if dist < fovSize and dist < distance then
						if not hasWallBetween(Camera.CFrame.Position, targetBodyPart) then
							closest = player
							distance = dist
						end
					end
				end
			end
		end
	end
	return closest
end

local function smoothAim(targetPosition)
	if not targetPosition then return end

	local currentCFrame = Camera.CFrame
	local targetCFrame = CFrame.lookAt(currentCFrame.Position, targetPosition)
	local lerpedCFrame = currentCFrame:Lerp(targetCFrame, 1 / smoothing)
	Camera.CFrame = lerpedCFrame
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	local isBindedKey = false

	if typeof(aimbotKey) == "EnumItem" then
		if aimbotKey.EnumType == Enum.KeyCode then
			isBindedKey = input.KeyCode == aimbotKey
		elseif aimbotKey.EnumType == Enum.UserInputType then
			isBindedKey = input.UserInputType == aimbotKey
		end
	end

	if isBindedKey and aimbotEnabled then
		aiming = true
		closestTarget = getClosestPlayer()

		if notify and closestTarget then
			pcall(function()
				game.StarterGui:SetCore("SendNotification", {
					Title = "Silent.cc",
					Text = "Aimbotting on: " .. closestTarget.Name,
					Duration = 1
				})
			end)
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	local isBindedKey = false

	if typeof(aimbotKey) == "EnumItem" then
		if aimbotKey.EnumType == Enum.KeyCode then
			isBindedKey = input.KeyCode == aimbotKey
		elseif aimbotKey.EnumType == Enum.UserInputType then
			isBindedKey = input.UserInputType == aimbotKey
		end
	end

	if isBindedKey then
		aiming = false
		closestTarget = nil
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == aimbotKey then
		aiming = false
		closestTarget = nil
	end
end)

-- Main loop
RunService.RenderStepped:Connect(function()
	-- Update fov
	local mousePos = UserInputService:GetMouseLocation()
	fovCircle.Position = mousePos
	fovCircle.Color = fovColor
	fovCircle.Visible = showFOV and aimbotEnabled
	fovCircle.Radius = fovSize
	
	-- Update ESP
	updateBoxes()
	
	-- Update Aimbot
	if aiming and closestTarget and closestTarget.Character then
		local character = closestTarget.Character
		local targetBodyPart = character:FindFirstChild(targetPart) or character:FindFirstChild("HumanoidRootPart")

		if targetBodyPart then			
			local mouse2Held = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
			local isMouse2Bind = aimbotKey == Enum.UserInputType.MouseButton2

			if autoPrediction then
				local pingStat = LocalPlayer:FindFirstChild("NetworkStats")
				if pingStat and pingStat:FindFirstChild("Data Ping") then
					local rawPing = tonumber(pingStat["Data Ping"].Value:match("%d+")) or 100
					prediction = math.clamp(rawPing / 1000, 0.05, 0.3)
				end
			end

			if not (isMouse2Bind and mouse2Held and UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter) then
				local predictedPos = targetBodyPart.Position + targetBodyPart.Velocity * prediction
				smoothAim(predictedPos)
			end
		else
			closestTarget = getClosestPlayer()
		end
	end
end)

local rageTab = main:Tab("Rage")
local visualTab = main:Tab("Visual")
local MiscTab = main:Tab("Misc")
local configs = main:Tab("Configuration")

local aimbotSection = rageTab:Section{
	Name = "Aimbot",
	Side = "Left"
}

local AntiLockSection = rageTab:Section{
	Name = "Anti Lock",
	Side = "Right"
}

local themes = configs:Section{Name = "Theme", Side = "Left"}
local themepickers = {}

AntiLockSection:Toggle{
	Name = "Anti Lock",
	Flag = "AntiLock",
	Default = false,
	Callback = function(bool)
		antiLockEnabled = bool
		if bool then
			enableAntiLock()
		else
			disableAntiLock()
		end
	end
}

AntiLockSection:Slider{
	Name = "Amplitude",
	Text = "[value]",
	Flag = "Amplitude",
	Default = 5,
	Min = 1,
	Max = 20,
	Float = 1,
	Callback = function(value)
		amplitude = value
	end
}

AntiLockSection:Slider{
	Name = "Frequency",
	Text = "[value]",
	Flag = "Frequency",
	Default = 100,
	Min = 1,
	Max = 50,
	Float = 1,
	Callback = function(value)
		frequency = value
	end
}

local aimbotToggle = aimbotSection:Toggle{
	Name = "Aimbot",
	Flag = "AimbotEnabled",
	Default = false,
	Callback = function(bool)
		aimbotEnabled = bool
	end
}

aimbotSection:Toggle{
	Name = "Show FOV",
	Flag = "ShowFOV",
	Default = true,
	Callback = function(bool)
		showFOV = bool
	end
}

aimbotSection:Toggle{
	Name = "Wall Check",
	Flag = "WallCheck",
	Default = true,
	Callback = function(bool)
		wallcheckEnabled = bool
	end
}

aimbotSection:Toggle{
	Name = "Auto Predict",
	Flag = "AutoPrediction",
	Default = true,
	Callback = function(bool)
		autoPrediction = bool
	end
}

aimbotSection:ColorPicker{
	Name = "FOV Color",
	Flag = "FOVColor", 
	Default = Color3.fromRGB(255, 255, 255),
	Callback = function(color)
		fovColor = color
	end
}

aimbotSection:Slider{
	Name = "FOV Size",
	Text = "[value]",
	Flag = "FOVSize",
	Default = 100,
	Min = 10,
	Max = 300,
	Float = 1,
	Callback = function(value)
		fovSize = value
	end
}

aimbotSection:Slider{
	Name = "Smoothing",
	Text = "[value]",
	Flag = "Smoothing",
	Default = 5,
	Min = 1,
	Max = 20,
	Float = 1,
	Callback = function(value)
		smoothing = value
	end
}

aimbotSection:Slider{
	Name = "Prediction",
	Text = "[value]",
	Flag = "Prediction",
	Default = 0.165,
	Min = 0,
	Max = 0.3,
	Float = 0.001,
	Callback = function(value)
		prediction = value
	end
}

aimbotSection:Dropdown{
	Name = "Target Part",
	Flag = "TargetPart",
	Default = "Head",
	Content = {"Head", "HumanoidRootPart", "UpperTorso"},
	Callback = function(option)
		targetPart = option
	end
}

aimbotSection:Toggle{
	Name = "Aimbot Notify",
	Flag = "AimbotNotify",
	Default = true,
	Callback = function(bool)
		notify = bool
	end
}

local aimbotKeybind = aimbotSection:Keybind{
	Name = "Aimbot Key",
	Flag = "AimbotKey",
	Default = Enum.KeyCode.E,
	Callback = function(key, fromsetting)
		if fromsetting then
			aimbotKey = key
		end
	end
}

local silentAimSection = rageTab:Section{
	Name = "Silent Aim",
	Side = "Right"
}

silentAimSection:Toggle{
	Name = "Silent Aim",
	Flag = "SilentAimEnabled",
	Default = false,
	Callback = function(bool)
		silentAimEnabled = bool
	end
}

silentAimSection:Slider{
	Name = "Silent Aim FOV",
	Text = "[value]",
	Flag = "SilentAimFOV",
	Default = 100,
	Min = 10,
	Max = 300,
	Float = 1,
	Callback = function(value)
		silentAimFOV = value
		silentAimFOVCircle.Radius = value
	end
}

silentAimSection:Toggle{
	Name = "Show FOV",
	Flag = "SilentAimShowFOV",
	Default = true,
	Callback = function(bool)
		silentAimShowFOV = bool
	end
}

silentAimSection:Dropdown{
	Name = "Target Part",
	Flag = "SilentAimTargetPart",
	Default = "Head",
	Content = {"Head", "HumanoidRootPart", "UpperTorso"},
	Callback = function(option)
		silentAimTargetPart = option
	end
}

local espSection = visualTab:Section{
	Name = "ESP",
	Side = "Left"
}

local VisualsSection = visualTab:Section{
	Name = "Visuals",
	Side = "Right"
}

local UiSection = MiscTab:Section{
	Name = "Ui",
	Side = "Left"
}

espSection:Toggle{
	Name = "Square ESP",
	Flag = "SquareESP",
	Default = false,
	Callback = function(bool)
		espEnabled = bool
		
		if bool then
			for _, player in ipairs(Players:GetPlayers()) do
				createEsp(player)
			end
		else
			delBoxes()
		end
	end
}

espSection:Toggle{
	Name = "Gradient ESP",
	Flag = "GradientESP", 
	Default = false,
	Callback = function(bool)
		gradientEnabled = bool
	end
}

espSection:Dropdown{
	Name = "Gradient Direction",
	Flag = "GradientDirection",
	Default = "Vertical",
	Content = {"Vertical", "Horizontal"},
	Callback = function(option)
		gradientDirection = option
	end
}

espSection:ColorPicker{
	Name = "Static Color",
	Flag = "StaticColor",
	Default = Color3.fromRGB(255, 255, 255),
	Callback = function(color)
		defaultColor = color
	end
}

espSection:ColorPicker{
	Name = "Gradient Top Color",
	Flag = "GradientTopColor",
	Default = Color3.fromRGB(255, 255, 255),
	Callback = function(color)
		colorTop = color
	end
}

espSection:ColorPicker{
	Name = "Gradient Bottom Color", 
	Flag = "GradientBottomColor",
	Default = Color3.fromRGB(0, 0, 0),
	Callback = function(color)
		colorBottom = color
	end
}

VisualsSection:Toggle{ 
	Name = "FullBright", 
	Flag = "FBModule", 
	Default = false,
	Callback = function(bool)
		if bool then
			game:GetService("Lighting").Ambient = Color3.new(1, 1, 1)
			game:GetService("Lighting").OutdoorAmbient = Color3.new(1, 1, 1)
			game:GetService("Lighting").Brightness = 2
			print("FullBright enabled")
		else
			game:GetService("Lighting").Ambient = Color3.new(0.5, 0.5, 0.5)
			game:GetService("Lighting").OutdoorAmbient = Color3.new(0.5, 0.5, 0.5)
			game:GetService("Lighting").Brightness = 1
			print("FullBright disabled")
		end
	end
}

local themelist = themes:Dropdown{
	Name = "Theme",
	Default = library.currenttheme,
	Content = library:GetThemes(),
	Flag = "Theme Dropdown",
	Callback = function(option)
		if option then
			library:SetTheme(option)

			for option, picker in next, themepickers do
				picker:Set(library.theme[option])
			end
		end
	end
}

library:ConfigIgnore("Theme Dropdown")

local namebox = themes:Box{
	Name = "Custom Theme Name",
	Placeholder = "Custom Theme",
	Flag = "Custom Theme"
}

library:ConfigIgnore("Custom Theme")

themes:Button{
	Name = "Save Custom Theme",
	Callback = function()
		if library:SaveCustomTheme(library.flags["Custom Theme"]) then
			themelist:Refresh(library:GetThemes())
			themelist:Set(library.flags["Custom Theme"])
			namebox:Set("")
		end
	end
}

local customtheme = configs:Section{Name = "Custom Theme", Side = "Right"}

themepickers["Accent"] = customtheme:ColorPicker{
	Name = "Accent",
	Default = library.theme["Accent"],
	Flag = "Accent",
	Callback = function(color)
		library:ChangeThemeOption("Accent", color)
	end
}

library:ConfigIgnore("Accent")

themepickers["Window Background"] = customtheme:ColorPicker{
	Name = "Window Background",
	Default = library.theme["Window Background"],
	Flag = "Window Background",
	Callback = function(color)
		library:ChangeThemeOption("Window Background", color)
	end
}

library:ConfigIgnore("Window Background")

themepickers["Window Border"] = customtheme:ColorPicker{
	Name = "Window Border",
	Default = library.theme["Window Border"],
	Flag = "Window Border",
	Callback = function(color)
		library:ChangeThemeOption("Window Border", color)
	end
}

library:ConfigIgnore("Window Border")

themepickers["Tab Background"] = customtheme:ColorPicker{
	Name = "Tab Background",
	Default = library.theme["Tab Background"],
	Flag = "Tab Background",
	Callback = function(color)
		library:ChangeThemeOption("Tab Background", color)
	end
}

library:ConfigIgnore("Tab Background")

themepickers["Tab Border"] = customtheme:ColorPicker{
	Name = "Tab Border",
	Default = library.theme["Tab Border"],
	Flag = "Tab Border",
	Callback = function(color)
		library:ChangeThemeOption("Tab Border", color)
	end
}

library:ConfigIgnore("Tab Border")

themepickers["Tab Toggle Background"] = customtheme:ColorPicker{
	Name = "Tab Toggle Background",
	Default = library.theme["Tab Toggle Background"],
	Flag = "Tab Toggle Background",
	Callback = function(color)
		library:ChangeThemeOption("Tab Toggle Background", color)
	end
}

library:ConfigIgnore("Tab Toggle Background")

themepickers["Section Background"] = customtheme:ColorPicker{
	Name = "Section Background",
	Default = library.theme["Section Background"],
	Flag = "Section Background",
	Callback = function(color)
		library:ChangeThemeOption("Section Background", color)
	end
}

library:ConfigIgnore("Section Background")

themepickers["Section Border"] = customtheme:ColorPicker{
	Name = "Section Border",
	Default = library.theme["Section Border"],
	Flag = "Section Border",
	Callback = function(color)
		library:ChangeThemeOption("Section Border", color)
	end
}

library:ConfigIgnore("Section Border")

themepickers["Text"] = customtheme:ColorPicker{
	Name = "Text",
	Default = library.theme["Text"],
	Flag = "Text",
	Callback = function(color)
		library:ChangeThemeOption("Text", color)
	end
}

library:ConfigIgnore("Text")

themepickers["Disabled Text"] = customtheme:ColorPicker{
	Name = "Disabled Text",
	Default = library.theme["Disabled Text"],
	Flag = "Disabled Text",
	Callback = function(color)
		library:ChangeThemeOption("Disabled Text", color)
	end
}

library:ConfigIgnore("Disabled Text")

themepickers["Object Background"] = customtheme:ColorPicker{
	Name = "Object Background",
	Default = library.theme["Object Background"],
	Flag = "Object Background",
	Callback = function(color)
		library:ChangeThemeOption("Object Background", color)
	end
}

library:ConfigIgnore("Object Background")

themepickers["Object Border"] = customtheme:ColorPicker{
	Name = "Object Border",
	Default = library.theme["Object Border"],
	Flag = "Object Border",
	Callback = function(color)
		library:ChangeThemeOption("Object Border", color)
	end
}

library:ConfigIgnore("Object Border")

themepickers["Dropdown Option Background"] = customtheme:ColorPicker{
	Name = "Dropdown Option Background",
	Default = library.theme["Dropdown Option Background"],
	Flag = "Dropdown Option Background",
	Callback = function(color)
		library:ChangeThemeOption("Dropdown Option Background", color)
	end
}

library:ConfigIgnore("Dropdown Option Background")

local configsection = configs:Section{Name = "Configs", Side = "Left"}

local configlist = configsection:Dropdown{
	Name = "Configs",
	Content = library:GetConfigs(), -- GetConfigs(true) if you want universal configs
	Flag = "Config Dropdown"
}

library:ConfigIgnore("Config Dropdown")

local loadconfig = configsection:Button{
	Name = "Load Config",
	Callback = function()
		library:LoadConfig(library.flags["Config Dropdown"]) -- LoadConfig(library.flags["Config Dropdown"], true)  if you want universal configs
	end
}

local delconfig = configsection:Button{
	Name = "Delete Config",
	Callback = function()
		library:DeleteConfig(library.flags["Config Dropdown"]) -- DeleteConfig(library.flags["Config Dropdown"], true)  if you want universal configs
		configlist:Refresh(library:GetConfigs())
	end
}

local configbox = configsection:Box{
	Name = "Config Name",
	Placeholder = "Config Name",
	Flag = "Config Name"
}

library:ConfigIgnore("Config Name")

local save = configsection:Button{
	Name = "Save Config",
	Callback = function()
		library:SaveConfig(library.flags["Config Dropdown"] or library.flags["Config Name"]) -- SaveConfig(library.flags["Config Name"], true) if you want universal configs
		configlist:Refresh(library:GetConfigs())
	end
}

local keybindsection = configs:Section{Name = "UI Toggle Keybind", Side = "Left"}

keybindsection:Keybind{
	Name = "UI Toggle",
	Flag = "UI Toggle",
	Default = Enum.KeyCode.RightShift,
	Blacklist = {Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2, Enum.UserInputType.MouseButton3},
	Callback = function(_, fromsetting)
		if not fromsetting then
			library:Close()
		end
	end
}

-- Initialize ESP for existing players
Players.PlayerAdded:Connect(createEsp)

-- Clean up on player leave
Players.PlayerRemoving:Connect(function(player)
	if boxes[player] then
		for _, line in pairs(boxes[player]) do
			line:Remove()
		end
		boxes[player] = nil
	end
end)

-- Initialize folders
ensureFoldersExist()
