--[[
	The block picker: a column of tiles down the left side of the screen, one per block type, each
	with the block's name beside it, under a title naming the selected block.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
local Vide = require(ReplicatedStorage.Packages.Vide)

local create = Vide.create

type BlockType = BlockTypes.BlockType

local TILE_SIZE = 40
local TILE_GAP = 6
local TILE_RADIUS = 6
local NAME_WIDTH = 96
local TITLE_HEIGHT = 30
local TITLE_MAX_TEXT_SIZE = 24
local PANEL_PADDING = 10
local PANEL_RADIUS = 10
local PANEL_COLOR = Color3.fromRGB(28, 28, 34)
local SELECTED_COLOR = Color3.fromRGB(255, 200, 60)
local IDLE_STROKE_COLOR = Color3.fromRGB(70, 70, 80)
local TEXT_COLOR = Color3.fromRGB(240, 240, 240)

type TileProps = {
	BlockType: BlockType,
	LayoutOrder: number,
	IsSelected: () -> boolean,
	Select: () -> (),
}

local function tile(props: TileProps): TextButton
	return create("TextButton")({
		Name = props.BlockType.Name,
		LayoutOrder = props.LayoutOrder,
		Size = UDim2.fromOffset(TILE_SIZE + TILE_GAP + NAME_WIDTH, TILE_SIZE),
		BackgroundTransparency = 1,

		Activated = props.Select,

		create("Frame")({
			Name = "Swatch",
			Size = UDim2.fromOffset(TILE_SIZE, TILE_SIZE),
			BackgroundColor3 = props.BlockType.Color,

			create("UICorner")({ CornerRadius = UDim.new(0, TILE_RADIUS) }),
			create("UIStroke")({
				Color = function()
					return if props.IsSelected() then SELECTED_COLOR else IDLE_STROKE_COLOR
				end,
				Thickness = function()
					return if props.IsSelected() then 3 else 1
				end,
			}),
		}),

		create("TextLabel")({
			Name = "BlockName",
			Position = UDim2.fromOffset(TILE_SIZE + TILE_GAP, 0),
			Size = UDim2.fromOffset(NAME_WIDTH, TILE_SIZE),
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			TextSize = 16,
			TextColor3 = TEXT_COLOR,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = props.BlockType.DisplayName,
		}),
	})
end

export type BlockPickerProps = {
	Selected: () -> string,
	Select: (name: string) -> (),
}

local function blockPicker(props: BlockPickerProps): Frame
	local tiles = {}
	for index, blockType in BlockTypes.List do
		tiles[index] = tile({
			BlockType = blockType,
			LayoutOrder = index + 1,
			IsSelected = function()
				return props.Selected() == blockType.Name
			end,
			Select = function()
				props.Select(blockType.Name)
			end,
		})
	end

	return create("Frame")({
		Name = "BlockPicker",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 20, 0.5, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
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
			Padding = UDim.new(0, TILE_GAP),
		}),

		create("TextLabel")({
			Name = "Title",
			LayoutOrder = 1,
			Size = UDim2.fromOffset(TILE_SIZE + TILE_GAP + NAME_WIDTH, TITLE_HEIGHT),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextScaled = true,
			TextColor3 = TEXT_COLOR,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = function()
				return BlockTypes.ByName[props.Selected()].DisplayName
			end,

			create("UITextSizeConstraint")({ MaxTextSize = TITLE_MAX_TEXT_SIZE }),
		}),

		tiles,
	})
end

return blockPicker
