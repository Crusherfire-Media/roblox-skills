--[[
	The build mode HUD: a panel in the top-left corner with the player's name, the selected block
	type, and how many blocks they have placed since build mode opened. While it is open the world
	behind it is blurred and the camera zooms in a little, and a sound plays as it opens.
]]

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local BlockPlacer = require(script.Parent.BlockPlacer)
local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
local Vide = require(ReplicatedStorage.Packages.Vide)

local cleanup = Vide.cleanup
local create = Vide.create
local source = Vide.source

local PANEL_SIZE = Vector2.new(240, 96)
local PANEL_MARGIN = 16
local PANEL_PADDING = 10
local PANEL_COLOR = Color3.fromRGB(28, 28, 34)
local TEXT_COLOR = Color3.fromRGB(240, 240, 240)
local MUTED_TEXT_COLOR = Color3.fromRGB(180, 180, 190)
local SWATCH_SIZE = 16
local BLUR_SIZE = 12
local BUILD_FIELD_OF_VIEW = 60
local OPEN_SOUND_ID = "rbxasset://sounds/electronicpingshort.wav"

local openSound = Instance.new("Sound")
openSound.Name = "BuildModeOpen"
openSound.SoundId = OPEN_SOUND_ID
openSound.Volume = 0.5

local function buildModeHud(): Frame
	local localPlayer = Players.LocalPlayer
	local selected = source(BlockPlacer.getBlockType())
	local placedCount = source(0)

	cleanup(BlockPlacer.BlockTypeChanged:Connect(function(name: string)
		selected(name)
	end))

	local blockPlaced = ReplicatedStorage:WaitForChild("BlockPlaced") :: RemoteEvent
	cleanup(blockPlaced.OnClientEvent:Connect(function()
		placedCount(placedCount() + 1)
	end))

	local blur = Instance.new("BlurEffect")
	blur.Name = "BuildBlur"
	blur.Size = BLUR_SIZE
	blur.Parent = Lighting
	cleanup(blur)

	local camera = Workspace.CurrentCamera
	local previousFieldOfView = camera.FieldOfView
	camera.FieldOfView = BUILD_FIELD_OF_VIEW
	cleanup(function()
		camera.FieldOfView = previousFieldOfView
	end)

	SoundService:PlayLocalSound(openSound)

	local function selectedType(): BlockTypes.BlockType
		return BlockTypes.ByName[selected()]
	end

	return create("Frame")({
		Name = "BuildModeHud",
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
			Name = "PlayerName",
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, 22),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextSize = 18,
			TextColor3 = TEXT_COLOR,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = `{localPlayer.DisplayName} is building`,
		}),
		create("Frame")({
			Name = "Selected",
			LayoutOrder = 2,
			Size = UDim2.new(1, 0, 0, 20),
			BackgroundTransparency = 1,

			create("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 6),
			}),

			create("Frame")({
				Name = "Swatch",
				LayoutOrder = 1,
				Size = UDim2.fromOffset(SWATCH_SIZE, SWATCH_SIZE),
				BackgroundColor3 = function()
					return selectedType().Color
				end,

				create("UICorner")({ CornerRadius = UDim.new(0, 4) }),
			}),
			create("TextLabel")({
				Name = "BlockName",
				LayoutOrder = 2,
				Size = UDim2.new(1, -(SWATCH_SIZE + 6), 1, 0),
				BackgroundTransparency = 1,
				Font = Enum.Font.Gotham,
				TextSize = 16,
				TextColor3 = MUTED_TEXT_COLOR,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = function()
					return selectedType().DisplayName
				end,
			}),
		}),
		create("TextLabel")({
			Name = "PlacedCount",
			LayoutOrder = 3,
			Size = UDim2.new(1, 0, 0, 20),
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			TextSize = 16,
			TextColor3 = MUTED_TEXT_COLOR,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = function()
				return `Placed: {placedCount()}`
			end,
		}),
	})
end

return buildModeHud
