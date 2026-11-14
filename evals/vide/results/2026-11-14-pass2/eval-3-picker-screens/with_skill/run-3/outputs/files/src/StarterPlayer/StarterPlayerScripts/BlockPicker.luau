--!strict
--[[
	The block picker, one tile per block type, in two layouts:

	- Column: tiles down the screen with each block's name beside it, under a
	  title naming the selected block. For mouse and keyboard.
	- Row: larger tiles side by side with each name underneath, sized for a
	  thumb. For touch screens and small windows.

	The screen that mounts the picker chooses the layout and where it sits.
]]

local Vide = require("@game/ReplicatedStorage/Packages/Vide")

local BlockTypes = require("@game/ReplicatedStorage/Shared/BlockTypes")

local create = Vide.create
local derive = Vide.derive
local read = Vide.read

local TILE_GAP = 6
local TILE_RADIUS = 6
local TITLE_HEIGHT = 30
local TITLE_TEXT_SIZE = 24
local PANEL_PADDING = 10
local PANEL_RADIUS = 10
local KEY_HINT_SIZE = 16
local KEY_HINT_TEXT_SIZE = 12
-- Keep in sync with NUMBER_KEYS in BlockPlacer.
local KEY_HINT_COUNT = 5
local SELECTED_STROKE = 3
local IDLE_STROKE = 1
local PANEL_COLOR = Color3.fromRGB(28, 28, 34)
local SELECTED_COLOR = Color3.fromRGB(255, 200, 60)
local IDLE_STROKE_COLOR = Color3.fromRGB(70, 70, 80)
local TEXT_COLOR = Color3.fromRGB(240, 240, 240)
local KEY_HINT_COLOR = Color3.fromRGB(20, 20, 24)

type BlockType = BlockTypes.BlockType

export type Layout = "Column" | "Row"

type Metrics = {
	TileSize: Vector2,
	SwatchSize: number,
	SwatchPosition: Vector2,
	NamePosition: Vector2,
	NameSize: Vector2,
	NameTextSize: number,
	NameAlignment: Enum.TextXAlignment,
	FillDirection: Enum.FillDirection,
	HasTitle: boolean,
}

type TileProps = {
	BlockType: BlockType,
	LayoutOrder: number,
	KeyHint: string?,
	Metrics: () -> Metrics,
	ShowKeyHint: () -> boolean,
	IsSelected: () -> boolean,
	Select: () -> (),
}

export type BlockPickerProps = {
	Selected: () -> string,
	Select: (name: string) -> (),
	Layout: Layout | () -> Layout,
	ShowKeyHints: (boolean | () -> boolean)?,
	AnchorPoint: (Vector2 | () -> Vector2)?,
	Position: (UDim2 | () -> UDim2)?,
}

local COLUMN: Metrics = table.freeze({
	TileSize = Vector2.new(44 + TILE_GAP + 96, 44),
	SwatchSize = 44,
	SwatchPosition = Vector2.zero,
	NamePosition = Vector2.new(44 + TILE_GAP, 0),
	NameSize = Vector2.new(96, 44),
	NameTextSize = 18,
	NameAlignment = Enum.TextXAlignment.Left,
	FillDirection = Enum.FillDirection.Vertical,
	HasTitle = true,
})

-- The tile is wider than its swatch so the name fits under it, and the whole
-- tile takes the press.
local ROW: Metrics = table.freeze({
	TileSize = Vector2.new(64, 52 + 4 + 18),
	SwatchSize = 52,
	SwatchPosition = Vector2.new(6, 0),
	NamePosition = Vector2.new(0, 52 + 4),
	NameSize = Vector2.new(64, 18),
	NameTextSize = 16,
	NameAlignment = Enum.TextXAlignment.Center,
	FillDirection = Enum.FillDirection.Horizontal,
	HasTitle = false,
})

local METRICS: { [Layout]: Metrics } = table.freeze({
	Column = COLUMN,
	Row = ROW,
})

local function toOffset(size: Vector2): UDim2
	return UDim2.fromOffset(size.X, size.Y)
end

local function tile(props: TileProps): TextButton
	local metrics = props.Metrics

	return create("TextButton")({
		Name = props.BlockType.Name,
		LayoutOrder = props.LayoutOrder,
		Size = function()
			return toOffset(metrics().TileSize)
		end,
		BackgroundTransparency = 1,

		Activated = props.Select,

		create("Frame")({
			Name = "Swatch",
			Position = function()
				return toOffset(metrics().SwatchPosition)
			end,
			Size = function()
				local size = metrics().SwatchSize
				return UDim2.fromOffset(size, size)
			end,
			BackgroundColor3 = props.BlockType.Color,

			create("UICorner")({ CornerRadius = UDim.new(0, TILE_RADIUS) }),
			create("UIStroke")({
				Color = function()
					return if props.IsSelected() then SELECTED_COLOR else IDLE_STROKE_COLOR
				end,
				Thickness = function()
					return if props.IsSelected() then SELECTED_STROKE else IDLE_STROKE
				end,
			}),

			props.KeyHint and create("TextLabel")({
				Name = "KeyHint",
				Position = UDim2.fromOffset(2, 2),
				Size = UDim2.fromOffset(KEY_HINT_SIZE, KEY_HINT_SIZE),
				BackgroundColor3 = KEY_HINT_COLOR,
				BackgroundTransparency = 0.2,
				Font = Enum.Font.GothamBold,
				TextSize = KEY_HINT_TEXT_SIZE,
				TextColor3 = TEXT_COLOR,
				Text = props.KeyHint,
				Visible = props.ShowKeyHint,

				create("UICorner")({ CornerRadius = UDim.new(0, TILE_RADIUS - 2) }),
			}),
		}),

		create("TextLabel")({
			Name = "BlockName",
			Position = function()
				return toOffset(metrics().NamePosition)
			end,
			Size = function()
				return toOffset(metrics().NameSize)
			end,
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			TextSize = function()
				return metrics().NameTextSize
			end,
			TextColor3 = TEXT_COLOR,
			TextXAlignment = function()
				return metrics().NameAlignment
			end,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = props.BlockType.DisplayName,
		}),
	})
end

local function blockPicker(props: BlockPickerProps): Frame
	-- Derived, so bindings rerun when the layout flips and not on every
	-- pixel of a window resize.
	local metrics = derive(function(): Metrics
		return METRICS[read(props.Layout)]
	end)

	local function showKeyHint(): boolean
		return read(props.ShowKeyHints) == true
	end

	local tiles = {}
	for index, blockType in BlockTypes.List do
		tiles[index] = tile({
			BlockType = blockType,
			LayoutOrder = index + 1,
			KeyHint = if index <= KEY_HINT_COUNT then tostring(index) else nil,
			Metrics = metrics,
			ShowKeyHint = showKeyHint,
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
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		Position = props.Position or UDim2.fromOffset(0, 0),
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
			FillDirection = function()
				return metrics().FillDirection
			end,
			Padding = UDim.new(0, TILE_GAP),
		}),

		create("TextLabel")({
			Name = "Title",
			LayoutOrder = 1,
			Size = function()
				return UDim2.fromOffset(metrics().TileSize.X, TITLE_HEIGHT)
			end,
			Visible = function()
				return metrics().HasTitle
			end,
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextSize = TITLE_TEXT_SIZE,
			TextColor3 = TEXT_COLOR,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = function()
				return BlockTypes.ByName[props.Selected()].DisplayName
			end,
		}),

		tiles,
	})
end

return blockPicker
