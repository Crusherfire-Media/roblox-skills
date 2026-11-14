--[[
	The block picker shown in build mode: a row of tiles along the bottom of the screen, one per
	block type. It slides up from the bottom edge while present and back down while leaving, and
	one yellow outline glides to the selected tile.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
local Vide = require(ReplicatedStorage.Packages.Vide)

local changed = Vide.changed
local create = Vide.create
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
local HIGHLIGHT_PERIOD = 0.25
local PRESSED_SCALE = 0.88
local PRESS_PERIOD = 0.25
-- Below 1 so a released tile springs back past full size, like a key bouncing up.
local PRESS_DAMPING = 0.5

type TileProps = {
	BlockType: BlockType,
	LayoutOrder: number,
	IsInteractable: () -> boolean,
	Select: () -> (),
}

local function tile(props: TileProps): Frame
	local guiState = source(Enum.GuiState.Idle)

	local scale = spring(function()
		return if guiState() == Enum.GuiState.Press then PRESSED_SCALE else 1
	end, PRESS_PERIOD, PRESS_DAMPING)

	-- The layout places this slot, so the button inside can scale about its own center.
	return create("Frame")({
		Name = props.BlockType.Name,
		LayoutOrder = props.LayoutOrder,
		Size = UDim2.fromOffset(TILE_SIZE, TILE_SIZE),
		BackgroundTransparency = 1,

		create("TextButton")({
			Name = "Button",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = props.BlockType.Color,
			Interactable = props.IsInteractable,

			Activated = props.Select,

			create("UIScale")({ Scale = scale }),
			create("UICorner")({ CornerRadius = UDim.new(0, TILE_RADIUS) }),
			create("UIStroke")({
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				BorderStrokePosition = Enum.BorderStrokePosition.Inner,
				Color = IDLE_STROKE_COLOR,
				Thickness = 1,
			}),

			changed("GuiState", guiState),
		}),
	})
end

type HighlightProps = {
	SelectedIndex: () -> number,
}

local function highlight(props: HighlightProps): Frame
	local position = spring(function()
		return UDim2.fromOffset((props.SelectedIndex() - 1) * (TILE_SIZE + TILE_GAP), 0)
	end, HIGHLIGHT_PERIOD)

	-- Outside the tile's edge, so a pressed tile sinks inside the outline.
	return create("Frame")({
		Name = "Highlight",
		Position = position,
		Size = UDim2.fromOffset(TILE_SIZE, TILE_SIZE),
		BackgroundTransparency = 1,
		ZIndex = 2,

		create("UICorner")({ CornerRadius = UDim.new(0, TILE_RADIUS) }),
		create("UIStroke")({
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			BorderStrokePosition = Enum.BorderStrokePosition.Outer,
			Color = SELECTED_COLOR,
			Thickness = HIGHLIGHT_THICKNESS,
		}),
	})
end

export type BlockPickerProps = {
	Selected: () -> string,
	Select: (name: string) -> (),
	-- Pass the `present` source of the `show` that builds the picker; false while it leaves.
	Present: (() -> boolean)?,
}

local function blockPicker(props: BlockPickerProps): Frame
	local present = props.Present or function()
		return true
	end

	local indexByName: { [string]: number? } = {}
	local tiles = {}
	for index, blockType in BlockTypes.List do
		indexByName[blockType.Name] = index
		tiles[index] = tile({
			BlockType = blockType,
			LayoutOrder = index,
			IsInteractable = present,
			Select = function()
				props.Select(blockType.Name)
			end,
		})
	end

	local count = #BlockTypes.List
	local panelHeight = TILE_SIZE + PANEL_PADDING * 2

	local position = spring(function()
		return if present()
			then UDim2.new(0.5, 0, 1, -BOTTOM_MARGIN)
			else UDim2.new(0.5, 0, 1, panelHeight)
	end, SLIDE_PERIOD)

	return create("Frame")({
		Name = "BlockPicker",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = position,
		Size = UDim2.fromOffset(
			count * TILE_SIZE + (count - 1) * TILE_GAP + PANEL_PADDING * 2,
			panelHeight
		),
		BackgroundColor3 = PANEL_COLOR,
		BackgroundTransparency = 0.2,

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

		highlight({
			SelectedIndex = function()
				return indexByName[props.Selected()] or 1
			end,
		}),
	})
end

local BlockPicker = {
	new = blockPicker,
	-- Return it from the `show` builder so the picker stays parented until it is off screen.
	ExitSeconds = SLIDE_PERIOD,
}

return table.freeze(BlockPicker)
