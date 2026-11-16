--[[
	The block picker shown in build mode: a row of tiles along the bottom of the screen, one per
	block type. It slides up from the bottom edge when opened and back down when closed, a yellow
	highlight glides to the selected tile, and tiles sink while pressed.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
local Vide = require(ReplicatedStorage.Packages.Vide)

local create = Vide.create
local derive = Vide.derive
local show = Vide.show
local source = Vide.source
local spring = Vide.spring

type BlockType = BlockTypes.BlockType

local TILE_SIZE = 64
local TILE_GAP = 8
local TILE_RADIUS = 8
local PANEL_PADDING = 8
local PANEL_RADIUS = TILE_RADIUS + PANEL_PADDING
local BOTTOM_MARGIN = 24
local PANEL_COLOR = Color3.fromRGB(28, 28, 34)
local SELECTED_COLOR = Color3.fromRGB(255, 200, 60)
local IDLE_STROKE_COLOR = Color3.fromRGB(70, 70, 80)
local HIGHLIGHT_THICKNESS = 3

local SLIDE_PERIOD = 0.3
-- Must outlast the slide off screen, or the panel vanishes while still visible.
local SLIDE_OUT_SECONDS = 0.4
local GLIDE_PERIOD = 0.25
local PRESSED_SCALE = 0.88
local PRESS_PERIOD = 0.25
-- Below 1 so a released tile springs back with a small bounce.
local PRESS_DAMPING = 0.5

local PRESS_INPUT_TYPES = {
	Enum.UserInputType.MouseButton1,
	Enum.UserInputType.Touch,
}
local PRESS_KEY_CODES = {
	Enum.KeyCode.ButtonA,
	Enum.KeyCode.Return,
}

local TILE_COUNT = #BlockTypes.List
local PANEL_WIDTH = TILE_COUNT * TILE_SIZE + (TILE_COUNT - 1) * TILE_GAP + PANEL_PADDING * 2
local PANEL_HEIGHT = TILE_SIZE + PANEL_PADDING * 2
local SHOWN_POSITION = UDim2.new(0.5, 0, 1, -BOTTOM_MARGIN)
-- The extra margin keeps the spring's slow last pixels below the screen edge.
local HIDDEN_POSITION = UDim2.new(0.5, 0, 1, PANEL_HEIGHT + BOTTOM_MARGIN)

local function isPressInput(input: InputObject): boolean
	return table.find(PRESS_INPUT_TYPES, input.UserInputType) ~= nil
		or table.find(PRESS_KEY_CODES, input.KeyCode) ~= nil
end

local function tilePosition(index: number): UDim2
	return UDim2.fromOffset((index - 1) * (TILE_SIZE + TILE_GAP), 0)
end

type TileProps = {
	BlockType: BlockType,
	LayoutOrder: number,
	Select: () -> (),
}

-- The slot holds the tile's place in the row while the button inside shrinks
-- around its center.
local function tile(props: TileProps): Frame
	local isPressed = source(false)

	local scale = spring(function()
		return if isPressed() then PRESSED_SCALE else 1
	end, PRESS_PERIOD, PRESS_DAMPING)

	return create("Frame")({
		Name = props.BlockType.Name,
		LayoutOrder = props.LayoutOrder,
		Size = UDim2.fromOffset(TILE_SIZE, TILE_SIZE),
		BackgroundTransparency = 1,

		create("TextButton")({
			Name = "Button",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = function()
				return UDim2.fromScale(scale(), scale())
			end,
			BackgroundColor3 = props.BlockType.Color,

			Activated = props.Select,
			InputBegan = function(input: InputObject)
				if isPressInput(input) then
					isPressed(true)
				end
			end,
			InputEnded = function(input: InputObject)
				if isPressInput(input) then
					isPressed(false)
				end
			end,
			MouseLeave = function()
				isPressed(false)
			end,

			create("UICorner")({ CornerRadius = UDim.new(0, TILE_RADIUS) }),
			create("UIStroke")({
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				BorderStrokePosition = Enum.BorderStrokePosition.Inner,
				Color = IDLE_STROKE_COLOR,
				Thickness = 1,
			}),
		}),
	})
end

type PanelProps = {
	IsOpen: () -> boolean,
	Selected: () -> string,
	Select: (name: string) -> (),
}

local function panel(props: PanelProps): Frame
	local tiles = {}
	local indexByName: { [string]: number? } = {}
	for index, blockType in BlockTypes.List do
		indexByName[blockType.Name] = index
		tiles[index] = tile({
			BlockType = blockType,
			LayoutOrder = index,
			Select = function()
				props.Select(blockType.Name)
			end,
		})
	end

	local selectedIndex = derive(function()
		return indexByName[props.Selected()] or 1
	end)

	local position = spring(function()
		return if props.IsOpen() then SHOWN_POSITION else HIDDEN_POSITION
	end, SLIDE_PERIOD)

	local highlightPosition = spring(function()
		return tilePosition(selectedIndex())
	end, GLIDE_PERIOD)

	return create("Frame")({
		Name = "BlockPicker",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = position,
		Size = UDim2.fromOffset(PANEL_WIDTH, PANEL_HEIGHT),
		BackgroundColor3 = PANEL_COLOR,
		BackgroundTransparency = 0.2,
		Interactable = props.IsOpen,

		create("UICorner")({ CornerRadius = UDim.new(0, PANEL_RADIUS) }),
		create("UIPadding")({
			PaddingLeft = UDim.new(0, PANEL_PADDING),
			PaddingRight = UDim.new(0, PANEL_PADDING),
			PaddingTop = UDim.new(0, PANEL_PADDING),
			PaddingBottom = UDim.new(0, PANEL_PADDING),
		}),

		create("Frame")({
			Name = "Tiles",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,

			create("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, TILE_GAP),
			}),

			tiles,
		}),

		-- Kept out of the Tiles frame so the list layout does not pin it in place.
		create("Frame")({
			Name = "Highlight",
			Position = highlightPosition,
			Size = UDim2.fromOffset(TILE_SIZE, TILE_SIZE),
			BackgroundTransparency = 1,
			ZIndex = 2,

			create("UICorner")({ CornerRadius = UDim.new(0, TILE_RADIUS) }),
			create("UIStroke")({
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				BorderStrokePosition = Enum.BorderStrokePosition.Inner,
				Color = SELECTED_COLOR,
				Thickness = HIGHLIGHT_THICKNESS,
			}),
		}),
	})
end

export type BlockPickerProps = {
	IsOpen: () -> boolean,
	Selected: () -> string,
	Select: (name: string) -> (),
}

--[[
	Returns a children source to pass as a child. The panel stays until it has slid off
	screen after IsOpen turns false; reopening it mid-slide reverses the same panel.
]]
local function blockPicker(props: BlockPickerProps): () -> any
	return show(props.IsOpen, function(_, present)
		return panel({
			IsOpen = present,
			Selected = props.Selected,
			Select = props.Select,
		}),
			SLIDE_OUT_SECONDS
	end)
end

return blockPicker
