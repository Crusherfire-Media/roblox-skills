--[[
	The block picker: a title over a row of tiles along the bottom of the screen, one per block
	type, optionally with its name under the swatch. The selected tile has a yellow outline, and
	clicking or tapping a tile selects its block type with a click sound.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
local Vide = require(ReplicatedStorage.Packages.Vide)

local create = Vide.create

type BlockType = BlockTypes.BlockType

local TILE_SIZE = 64
local NAME_HEIGHT = 18
local TILE_GAP = 8
local TILE_RADIUS = 8
local PANEL_PADDING = 8
local PANEL_RADIUS = TILE_RADIUS + PANEL_PADDING
local TITLE_HEIGHT = 26
local BOTTOM_MARGIN = 24
local PANEL_COLOR = Color3.fromRGB(28, 28, 34)
local SELECTED_COLOR = Color3.fromRGB(255, 200, 60)
local IDLE_STROKE_COLOR = Color3.fromRGB(70, 70, 80)
local TEXT_COLOR = Color3.fromRGB(240, 240, 240)
local CLICK_SOUND_ID = "rbxasset://sounds/electronicpingshort.wav"

local PLAYER_NAME = Players.LocalPlayer.DisplayName

local tileClick = Instance.new("Sound")
tileClick.Name = "TileClick"
tileClick.SoundId = CLICK_SOUND_ID
tileClick.Volume = 0.4
tileClick.Parent = SoundService

type TileProps = {
	BlockType: BlockType,
	LayoutOrder: number,
	ShowName: boolean,
	IsSelected: () -> boolean,
	Select: () -> (),
}

local function tile(props: TileProps): TextButton
	local nameLabel: TextLabel? = nil
	if props.ShowName then
		nameLabel = create("TextLabel")({
			Name = "BlockName",
			Position = UDim2.fromOffset(0, TILE_SIZE),
			Size = UDim2.fromOffset(TILE_SIZE, NAME_HEIGHT),
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			TextSize = 14,
			TextColor3 = TEXT_COLOR,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = props.BlockType.DisplayName,
		})
	end

	return create("TextButton")({
		Name = props.BlockType.Name,
		LayoutOrder = props.LayoutOrder,
		Size = UDim2.fromOffset(TILE_SIZE, TILE_SIZE + NAME_HEIGHT),
		BackgroundTransparency = 1,
		Text = "",

		Activated = function()
			tileClick:Play()
			props.Select()
		end,

		create("Frame")({
			Name = "Swatch",
			Size = UDim2.fromOffset(TILE_SIZE, TILE_SIZE),
			BackgroundColor3 = props.BlockType.Color,

			create("UICorner")({ CornerRadius = UDim.new(0, TILE_RADIUS) }),
			create("UIStroke")({
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				BorderStrokePosition = Enum.BorderStrokePosition.Inner,
				Color = function()
					return if props.IsSelected() then SELECTED_COLOR else IDLE_STROKE_COLOR
				end,
				Thickness = function()
					return if props.IsSelected() then 3 else 1
				end,
			}),
		}),
		nameLabel,
	})
end

export type BlockPickerProps = {
	ShowNames: boolean,
	Selected: () -> string,
	Select: (name: string) -> (),
}

local function blockPicker(props: BlockPickerProps): Frame
	local tiles = {}
	for index, blockType in BlockTypes.List do
		tiles[index] = tile({
			BlockType = blockType,
			LayoutOrder = index,
			ShowName = props.ShowNames,
			IsSelected = function()
				return props.Selected() == blockType.Name
			end,
			Select = function()
				props.Select(blockType.Name)
			end,
		})
	end

	local count = #BlockTypes.List
	local width = count * TILE_SIZE + (count - 1) * TILE_GAP + PANEL_PADDING * 2

	return create("Frame")({
		Name = "BlockPicker",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -BOTTOM_MARGIN),
		Size = UDim2.fromOffset(width, TITLE_HEIGHT + TILE_SIZE + NAME_HEIGHT + PANEL_PADDING * 3),
		BackgroundColor3 = PANEL_COLOR,
		BackgroundTransparency = 0.2,

		create("UICorner")({ CornerRadius = UDim.new(0, PANEL_RADIUS) }),
		create("UIPadding")({
			PaddingLeft = UDim.new(0, PANEL_PADDING),
			PaddingRight = UDim.new(0, PANEL_PADDING),
			PaddingTop = UDim.new(0, PANEL_PADDING),
			PaddingBottom = UDim.new(0, PANEL_PADDING),
		}),
		create("UIListLayout")({
			FillDirection = Enum.FillDirection.Vertical,
			Padding = UDim.new(0, PANEL_PADDING),
		}),

		create("TextLabel")({
			Name = "Title",
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, TITLE_HEIGHT),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextSize = 20,
			TextColor3 = TEXT_COLOR,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = `{PLAYER_NAME}'s blocks`,
		}),
		create("Frame")({
			Name = "Tiles",
			LayoutOrder = 2,
			Size = UDim2.new(1, 0, 0, TILE_SIZE + NAME_HEIGHT),
			BackgroundTransparency = 1,

			create("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, TILE_GAP),
			}),

			tiles,
		}),
	})
end

return blockPicker
