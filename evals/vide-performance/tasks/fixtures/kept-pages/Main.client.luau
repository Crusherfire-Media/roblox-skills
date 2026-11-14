local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local BlockPlacer = require(script.Parent.BlockPlacer)
local BuildMenu = require(script.Parent.BuildMenu)
local Vide = require(ReplicatedStorage.Packages.Vide)

local create = Vide.create
local mount = Vide.mount
local show = Vide.show
local source = Vide.source

local MENU_BUTTON_SIZE = Vector2.new(120, 48)
local MENU_BUTTON_MARGIN = 16
local BUTTON_COLOR = Color3.fromRGB(28, 28, 34)
local TEXT_COLOR = Color3.fromRGB(240, 240, 240)

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local isMenuOpen = source(false)
local tab = source("Blocks" :: BuildMenu.Tab)
local tint = source(Color3.new(1, 1, 1))

local function menuButton()
	return create("TextButton")({
		Name = "MenuButton",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -MENU_BUTTON_MARGIN, 0, MENU_BUTTON_MARGIN),
		Size = UDim2.fromOffset(MENU_BUTTON_SIZE.X, MENU_BUTTON_SIZE.Y),
		BackgroundColor3 = BUTTON_COLOR,
		Font = Enum.Font.GothamBold,
		TextSize = 20,
		TextColor3 = TEXT_COLOR,
		Text = "Menu",

		Activated = function()
			isMenuOpen(not isMenuOpen())
		end,

		create("UICorner")({ CornerRadius = UDim.new(0, 8) }),
	})
end

local function app()
	return create("ScreenGui")({
		Name = "BuildMenuGui",

		menuButton(),

		show(isMenuOpen, function(_, present: () -> boolean)
			return BuildMenu.component({
				Tab = tab,
				SelectTab = tab,
				Tint = tint,
				SelectTint = tint,
				Present = present,
			}),
				BuildMenu.SlideSeconds
		end),
	})
end

mount(app, playerGui)

-- M opens and closes the build menu too.
UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
	if gameProcessedEvent or input.KeyCode ~= Enum.KeyCode.M then
		return
	end
	isMenuOpen(not isMenuOpen())
end)

BlockPlacer.start()
