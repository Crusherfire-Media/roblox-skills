local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local BlockCatalog = require(script.Parent.BlockCatalog)
local BlockPlacer = require(script.Parent.BlockPlacer)
local Vide = require(ReplicatedStorage.Packages.Vide)

local create = Vide.create
local mount = Vide.mount
local show = Vide.show
local source = Vide.source

local CATALOG_BUTTON_SIZE = Vector2.new(120, 48)
local CATALOG_BUTTON_MARGIN = 16
local BUTTON_COLOR = Color3.fromRGB(28, 28, 34)
local TEXT_COLOR = Color3.fromRGB(240, 240, 240)

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local isCatalogOpen = source(false)

local function catalogButton()
	return create("TextButton")({
		Name = "CatalogButton",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -CATALOG_BUTTON_MARGIN, 0, CATALOG_BUTTON_MARGIN),
		Size = UDim2.fromOffset(CATALOG_BUTTON_SIZE.X, CATALOG_BUTTON_SIZE.Y),
		BackgroundColor3 = BUTTON_COLOR,
		Font = Enum.Font.GothamBold,
		TextSize = 20,
		TextColor3 = TEXT_COLOR,
		Text = "Catalog",

		Activated = function()
			isCatalogOpen(not isCatalogOpen())
		end,

		create("UICorner")({ CornerRadius = UDim.new(0, 8) }),
	})
end

local function app()
	return create("ScreenGui")({
		Name = "CatalogGui",

		catalogButton(),

		show(isCatalogOpen, function(_, present: () -> boolean)
			return BlockCatalog.component({
				Select = function(blockTypeName: string)
					BlockPlacer.setBlockType(blockTypeName)
					isCatalogOpen(false)
				end,
				Present = present,
			}),
				BlockCatalog.FadeSeconds
		end),
	})
end

mount(app, playerGui)

-- C opens and closes the catalog too.
UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
	if gameProcessedEvent or input.KeyCode ~= Enum.KeyCode.C then
		return
	end
	isCatalogOpen(not isCatalogOpen())
end)

BlockPlacer.start()
