local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local BlockPicker = require(script.Parent.BlockPicker)
local BlockPlacer = require(script.Parent.BlockPlacer)
local SoundIds = require(ReplicatedStorage.Shared.SoundIds)
local UiSounds = require(script.Parent.UiSounds)
local Vide = require(ReplicatedStorage.Packages.Vide)

local create = Vide.create
local mount = Vide.mount
local show = Vide.show
local source = Vide.source

local BUILD_BUTTON_SIZE = Vector2.new(120, 48)
local BUILD_BUTTON_MARGIN = 16
local BUTTON_COLOR = Color3.fromRGB(28, 28, 34)
local BUTTON_ACTIVE_COLOR = Color3.fromRGB(255, 200, 60)
local TEXT_COLOR = Color3.fromRGB(240, 240, 240)

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local selected = source(BlockPlacer.getBlockType())
BlockPlacer.BlockTypeChanged:Connect(function(name: string)
	selected(name)
end)

local isBuildMode = source(false)

local function setBuildMode(enabled: boolean)
	BlockPlacer.setEnabled(enabled)
	isBuildMode(enabled)
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
			UiSounds.play(SoundIds.Click)
			setBuildMode(not isBuildMode())
		end,

		create("UICorner")({ CornerRadius = UDim.new(0, 8) }),
	})
end

local function app()
	return create("ScreenGui")({
		Name = "BuildGui",

		buildButton(),

		show(isBuildMode, function()
			return BlockPicker({
				Selected = selected,
				Select = BlockPlacer.setBlockType,
			})
		end),
	})
end

mount(app, playerGui)

-- B toggles build mode too.
UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
	if gameProcessedEvent or input.KeyCode ~= Enum.KeyCode.B then
		return
	end
	setBuildMode(not isBuildMode())
end)

-- Tried to warm the UI sounds up front; clicks still play late.
task.spawn(function()
	ContentProvider:PreloadAsync({ SoundIds.Click, SoundIds.PickerOpen, SoundIds.PickerClose })
end)

BlockPlacer.setEnabled(false)
BlockPlacer.start()
