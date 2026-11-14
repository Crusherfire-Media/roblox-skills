local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local BlockPicker = require(script.Parent.BlockPicker)
local BlockPlacer = require(script.Parent.BlockPlacer)
local Vide = require(ReplicatedStorage.Packages.Vide)

Vide.strict = RunService:IsStudio()

local create = Vide.create
local mount = Vide.mount
local source = Vide.source

-- The UI is authored for a screen 1080 pixels tall and grows on larger screens.
local REFERENCE_SHORT_SIDE = 1080
local MAXIMUM_SCALE = 3
local BUILD_BUTTON_SIZE = Vector2.new(120, 48)
local BUILD_BUTTON_MARGIN = 16
local BUTTON_COLOR = Color3.fromRGB(28, 28, 34)
local BUTTON_ACTIVE_COLOR = Color3.fromRGB(255, 200, 60)
local TEXT_COLOR = Color3.fromRGB(240, 240, 240)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local selected = source(BlockPlacer.getBlockType())
BlockPlacer.BlockTypeChanged:Connect(function(name: string)
	selected(name)
end)

local isBuildMode = source(false)

local function setBuildMode(enabled: boolean)
	BlockPlacer.setEnabled(enabled)
	isBuildMode(enabled)
end

local viewportSize = source(Vector2.new(1920, 1080))

local function refreshViewport()
	local camera = Workspace.CurrentCamera
	if camera and camera.ViewportSize.X > 1 and camera.ViewportSize.Y > 1 then
		viewportSize(camera.ViewportSize)
	end
end

local cameraConnection: RBXScriptConnection? = nil

local function watchCamera()
	if cameraConnection then
		cameraConnection:Disconnect()
	end
	local camera = Workspace.CurrentCamera
	if camera then
		cameraConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(refreshViewport)
	end
	refreshViewport()
end

watchCamera()
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)

local function uiScale(): number
	local size = viewportSize()
	return math.clamp(math.min(size.X, size.Y) / REFERENCE_SHORT_SIDE, 1, MAXIMUM_SCALE)
end

local function buildButton()
	return create("TextButton")({
		Name = "BuildButton",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -BUILD_BUTTON_MARGIN, 0, BUILD_BUTTON_MARGIN),
		Size = UDim2.fromOffset(BUILD_BUTTON_SIZE.X, BUILD_BUTTON_SIZE.Y),
		BackgroundColor3 = function()
			return if isBuildMode() then BUTTON_ACTIVE_COLOR else BUTTON_COLOR
		end,
		Font = Enum.Font.GothamBold,
		TextSize = 20,
		TextColor3 = function()
			return if isBuildMode() then BUTTON_COLOR else TEXT_COLOR
		end,
		Text = "Build",

		Activated = function()
			setBuildMode(not isBuildMode())
		end,

		create("UICorner")({ CornerRadius = UDim.new(0, 8) }),
	})
end

local function app()
	return create("ScreenGui")({
		Name = "BuildGui",

		create("UIScale")({ Scale = uiScale }),
		buildButton(),

		BlockPicker({
			IsOpen = isBuildMode,
			Selected = selected,
			Select = BlockPlacer.setBlockType,
		}),
	})
end

mount(app, playerGui)

-- B toggles build mode too: the picker shows and clicks place blocks only while it is on.
UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
	if gameProcessedEvent or input.KeyCode ~= Enum.KeyCode.B then
		return
	end
	setBuildMode(not isBuildMode())
end)

BlockPlacer.setEnabled(false)
BlockPlacer.start()
