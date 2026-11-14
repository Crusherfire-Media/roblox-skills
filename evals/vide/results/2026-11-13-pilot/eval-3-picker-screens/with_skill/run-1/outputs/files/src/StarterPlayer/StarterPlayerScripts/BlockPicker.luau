--[[
	The block picker: one tile per block type, showing the block's color and name, with the
	selected tile outlined and its name in bold. It has two layouts:

	- Column: down the left edge under a title naming the selected block, for mouse and keyboard.
	- Row: larger tiles across the top-right corner, for touch, clear of the thumbstick region
	  (left 40%, lower two thirds) and the jump button.
]]

const BlockTypes = require("@game/ReplicatedStorage/Shared/BlockTypes")
const Vide = require("@game/ReplicatedStorage/Packages/Vide")

const create = Vide.create
const derive = Vide.derive
const read = Vide.read

type BlockType = BlockTypes.BlockType

export type Layout = "Column" | "Row"

type Metrics = {
	PanelAnchor: Vector2,
	PanelPosition: UDim2,
	FillDirection: Enum.FillDirection,
	TileSize: Vector2,
	SwatchSize: number,
	SwatchPosition: Vector2,
	NameSize: Vector2,
	NamePosition: Vector2,
	NameTextSize: number,
	NameAlignment: Enum.TextXAlignment,
	HasTitle: boolean,
}

const TILE_GAP = 6
const TILE_RADIUS = 6
const TITLE_HEIGHT = 30
const TITLE_TEXT_SIZE = 24
const PANEL_PADDING = 10
const PANEL_RADIUS = 10
const PANEL_COLOR = Color3.fromRGB(28, 28, 34)
const SELECTED_COLOR = Color3.fromRGB(255, 200, 60)
const IDLE_STROKE_COLOR = Color3.fromRGB(70, 70, 80)
const TEXT_COLOR = Color3.fromRGB(240, 240, 240)

const COLUMN_SWATCH = 40
const COLUMN_NAME_WIDTH = 96
const COLUMN_TILE_WIDTH = COLUMN_SWATCH + TILE_GAP + COLUMN_NAME_WIDTH

-- Wide enough for "Window" at the row's text size, and narrow enough that
-- five tiles start right of the thumbstick region on a 667 wide phone.
const ROW_TILE_WIDTH = 68
const ROW_SWATCH = 56
const ROW_NAME_HEIGHT = 18
const ROW_NAME_GAP = 4

const COLUMN: Metrics = table.freeze({
	PanelAnchor = Vector2.new(0, 0.5),
	PanelPosition = UDim2.new(0, 20, 0.5, 0),
	FillDirection = Enum.FillDirection.Vertical,
	TileSize = Vector2.new(COLUMN_TILE_WIDTH, COLUMN_SWATCH),
	SwatchSize = COLUMN_SWATCH,
	SwatchPosition = Vector2.zero,
	NameSize = Vector2.new(COLUMN_NAME_WIDTH, COLUMN_SWATCH),
	NamePosition = Vector2.new(COLUMN_SWATCH + TILE_GAP, 0),
	NameTextSize = 16,
	NameAlignment = Enum.TextXAlignment.Left,
	HasTitle = true,
})

const ROW: Metrics = table.freeze({
	PanelAnchor = Vector2.new(1, 0),
	PanelPosition = UDim2.new(1, -12, 0, 12),
	FillDirection = Enum.FillDirection.Horizontal,
	TileSize = Vector2.new(ROW_TILE_WIDTH, ROW_SWATCH + ROW_NAME_GAP + ROW_NAME_HEIGHT),
	SwatchSize = ROW_SWATCH,
	SwatchPosition = Vector2.new((ROW_TILE_WIDTH - ROW_SWATCH) / 2, 0),
	NameSize = Vector2.new(ROW_TILE_WIDTH, ROW_NAME_HEIGHT),
	NamePosition = Vector2.new(0, ROW_SWATCH + ROW_NAME_GAP),
	NameTextSize = 15,
	NameAlignment = Enum.TextXAlignment.Center,
	HasTitle = false,
})

local function toOffset(vector: Vector2): UDim2
	return UDim2.fromOffset(vector.X, vector.Y)
end

type TileProps = {
	BlockType: BlockType,
	LayoutOrder: number,
	Metrics: () -> Metrics,
	IsSelected: () -> boolean,
	Select: () -> (),
}

local function tile(props: TileProps): TextButton
	return create("TextButton")({
		Name = props.BlockType.Name,
		LayoutOrder = props.LayoutOrder,
		Size = function()
			return toOffset(props.Metrics().TileSize)
		end,
		BackgroundTransparency = 1,

		Activated = props.Select,

		create("Frame")({
			Name = "Swatch",
			Position = function()
				return toOffset(props.Metrics().SwatchPosition)
			end,
			Size = function()
				const size = props.Metrics().SwatchSize
				return UDim2.fromOffset(size, size)
			end,
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
			Position = function()
				return toOffset(props.Metrics().NamePosition)
			end,
			Size = function()
				return toOffset(props.Metrics().NameSize)
			end,
			BackgroundTransparency = 1,
			Font = function()
				return if props.IsSelected() then Enum.Font.GothamBold else Enum.Font.Gotham
			end,
			TextSize = function()
				return props.Metrics().NameTextSize
			end,
			TextColor3 = TEXT_COLOR,
			TextXAlignment = function()
				return props.Metrics().NameAlignment
			end,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = props.BlockType.DisplayName,
		}),
	})
end

export type BlockPickerProps = {
	Layout: Layout | () -> Layout,
	Selected: () -> string,
	Select: (name: string) -> (),
}

local function blockPicker(props: BlockPickerProps): Frame
	-- Derived, so bindings rerun when the layout flips, not on every pixel of
	-- a window resize.
	const metrics = derive(function(): Metrics
		return if read(props.Layout) == "Row" then ROW else COLUMN
	end)

	local tiles = {}
	for index, blockType in BlockTypes.List do
		tiles[index] = tile({
			BlockType = blockType,
			LayoutOrder = index + 1,
			Metrics = metrics,
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
		AnchorPoint = function()
			return metrics().PanelAnchor
		end,
		Position = function()
			return metrics().PanelPosition
		end,
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

		-- In the row each tile names itself, so the title only takes room.
		create("TextLabel")({
			Name = "Title",
			LayoutOrder = 1,
			Visible = function()
				return metrics().HasTitle
			end,
			Size = UDim2.fromOffset(COLUMN_TILE_WIDTH, TITLE_HEIGHT),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			-- A fixed size grows with the root UIScale; a TextScaled cap would not.
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
