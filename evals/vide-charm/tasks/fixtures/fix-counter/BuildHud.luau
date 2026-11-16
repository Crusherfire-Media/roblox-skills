--[[
	The build HUD in the top-left corner: how many blocks the player has placed this session, the
	last block type they placed, and a button that clears the count. A short click plays each time
	a block lands.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Charm = require(ReplicatedStorage.Packages.Charm)
local PlacedBlocks = require(script.Parent.PlacedBlocks)
local Vide = require(ReplicatedStorage.Packages.Vide)
local VideCharm = require(ReplicatedStorage.Packages.VideCharm)

local create = Vide.create

local PANEL_SIZE = Vector2.new(220, 104)
local PANEL_MARGIN = 16
local PANEL_PADDING = 10
local PANEL_COLOR = Color3.fromRGB(28, 28, 34)
local TEXT_COLOR = Color3.fromRGB(240, 240, 240)
local MUTED_TEXT_COLOR = Color3.fromRGB(180, 180, 190)
local BUTTON_COLOR = Color3.fromRGB(60, 60, 70)
local CLICK_SOUND_ID = "rbxasset://sounds/electronicpingshort.wav"

local clickSound = Instance.new("Sound")
clickSound.Name = "PlaceClick"
clickSound.SoundId = CLICK_SOUND_ID
clickSound.Volume = 0.5

local function buildHud(): Frame
	local count = VideCharm.useSignalState(PlacedBlocks.getCount)

	Charm.subscribe(PlacedBlocks.getLastPlaced, function(blockTypeName: string?)
		if blockTypeName then
			SoundService:PlayLocalSound(clickSound)
		end
	end)

	return create("Frame")({
		Name = "BuildHud",
		Position = UDim2.fromOffset(PANEL_MARGIN, PANEL_MARGIN),
		Size = UDim2.fromOffset(PANEL_SIZE.X, PANEL_SIZE.Y),
		BackgroundColor3 = PANEL_COLOR,
		BackgroundTransparency = 0.2,

		create("UICorner")({ CornerRadius = UDim.new(0, 8) }),
		create("UIPadding")({
			PaddingLeft = UDim.new(0, PANEL_PADDING),
			PaddingRight = UDim.new(0, PANEL_PADDING),
			PaddingTop = UDim.new(0, PANEL_PADDING),
			PaddingBottom = UDim.new(0, PANEL_PADDING),
		}),
		create("UIListLayout")({
			FillDirection = Enum.FillDirection.Vertical,
			Padding = UDim.new(0, 6),
		}),

		create("TextLabel")({
			Name = "Count",
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, 24),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextSize = 20,
			TextColor3 = TEXT_COLOR,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = function()
				return `Blocks placed: {count()}`
			end,
		}),
		create("TextLabel")({
			Name = "LastPlaced",
			LayoutOrder = 2,
			Size = UDim2.new(1, 0, 0, 18),
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			TextSize = 16,
			TextColor3 = MUTED_TEXT_COLOR,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = function()
				local last = PlacedBlocks.getLastPlaced()
				return `Last: {last or "none"}`
			end,
		}),
		create("TextButton")({
			Name = "Clear",
			LayoutOrder = 3,
			Size = UDim2.fromOffset(80, 28),
			BackgroundColor3 = BUTTON_COLOR,
			Font = Enum.Font.GothamBold,
			TextSize = 16,
			TextColor3 = TEXT_COLOR,
			Text = "Clear",

			Activated = function()
				PlacedBlocks.clear()
			end,

			create("UICorner")({ CornerRadius = UDim.new(0, 6) }),
		}),
	})
end

return buildHud
