--[[
	The block picker: one tile per block type under a title naming the selected block. The
	"Column" layout stacks the tiles with each block's name beside it, for a mouse and keyboard.
	The "Row" layout lines the tiles up side by side, for a strip between the touch controls, and
	wraps onto more rows when the strip is too narrow for thumb-sized tiles.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
local Vide = require(ReplicatedStorage.Packages.Vide)

local create = Vide.create
local derive = Vide.derive
local read = Vide.read

type BlockType = BlockTypes.BlockType

export type Layout = "Column" | "Row"

type Metrics = {
	TileSize: number,
	TileGap: number,
	PanelPadding: number,
	ShowsNames: boolean,
	NameWidth: number,
	NameTextSize: number,
	TitleHeight: number,
	TitleTextSize: number,
}

type Grid = {
	TileSize: number,
	Columns: number,
}

local COLUMN: Metrics = table.freeze({
	TileSize = 44,
	TileGap = 6,
	PanelPadding = 10,
	ShowsNames = true,
	NameWidth = 96,
	NameTextSize = 16,
	TitleHeight = 28,
	TitleTextSize = 22,
})

local ROW: Metrics = table.freeze({
	TileSize = 56,
	TileGap = 8,
	PanelPadding = 8,
	ShowsNames = false,
	NameWidth = 0,
	NameTextSize = 16,
	TitleHeight = 24,
	TitleTextSize = 18,
})

-- Smallest tile a thumb can reliably hit.
local MINIMUM_TILE_SIZE = 44
local TILE_RADIUS = 6
local PANEL_RADIUS = 10
local PANEL_COLOR = Color3.fromRGB(28, 28, 34)
local SELECTED_COLOR = Color3.fromRGB(255, 200, 60)
local IDLE_STROKE_COLOR = Color3.fromRGB(70, 70, 80)
local TEXT_COLOR = Color3.fromRGB(240, 240, 240)
local SELECTED_STROKE_THICKNESS = 3
local IDLE_STROKE_THICKNESS = 1

local TILE_COUNT = #BlockTypes.List

type TileProps = {
	BlockType: BlockType,
	LayoutOrder: number,
	Metrics: () -> Metrics,
	TileSize: () -> number,
	IsSelected: () -> boolean,
	Select: () -> (),
}

local function tile(props: TileProps): TextButton
	return create("TextButton")({
		Name = props.BlockType.Name,
		LayoutOrder = props.LayoutOrder,
		BackgroundTransparency = 1,

		Activated = props.Select,

		create("Frame")({
			Name = "Swatch",
			Size = function()
				local size = props.TileSize()
				return UDim2.fromOffset(size, size)
			end,
			BackgroundColor3 = props.BlockType.Color,

			create("UICorner")({ CornerRadius = UDim.new(0, TILE_RADIUS) }),
			create("UIStroke")({
				Color = function()
					return if props.IsSelected() then SELECTED_COLOR else IDLE_STROKE_COLOR
				end,
				Thickness = function()
					return if props.IsSelected()
						then SELECTED_STROKE_THICKNESS
						else IDLE_STROKE_THICKNESS
				end,
			}),
		}),

		create("TextLabel")({
			Name = "BlockName",
			Visible = function()
				return props.Metrics().ShowsNames
			end,
			Position = function()
				return UDim2.fromOffset(props.TileSize() + props.Metrics().TileGap, 0)
			end,
			Size = function()
				return UDim2.fromOffset(props.Metrics().NameWidth, props.TileSize())
			end,
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			TextSize = function()
				return props.Metrics().NameTextSize
			end,
			TextColor3 = TEXT_COLOR,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = props.BlockType.DisplayName,
		}),
	})
end

export type BlockPickerProps = {
	Selected: () -> string,
	Select: (name: string) -> (),
	Layout: Layout | () -> Layout,
	-- Widest the panel may be, in UI units. The row layout shrinks its tiles to
	-- fit, down to the smallest a thumb can hit, then wraps.
	MaxWidth: (number | () -> number)?,
	AnchorPoint: (Vector2 | () -> Vector2)?,
	Position: (UDim2 | () -> UDim2)?,
}

local function blockPicker(props: BlockPickerProps): Frame
	-- Derived, so bindings rerun when the layout flips, not on every pixel of a
	-- window resize.
	local metrics = derive(function(): Metrics
		return if read(props.Layout) == "Row" then ROW else COLUMN
	end)

	local function computeGrid(): Grid
		local current = metrics()
		if current.ShowsNames then
			return { TileSize = current.TileSize, Columns = 1 }
		end

		local maxWidth = read(props.MaxWidth)
		if not maxWidth then
			return { TileSize = current.TileSize, Columns = TILE_COUNT }
		end

		local room = maxWidth - current.PanelPadding * 2
		local gap = current.TileGap
		local size = math.floor((room - gap * (TILE_COUNT - 1)) / TILE_COUNT)
		size = math.clamp(size, MINIMUM_TILE_SIZE, current.TileSize)
		local columns = math.clamp(math.floor((room + gap) / (size + gap)), 1, TILE_COUNT)
		return { TileSize = size, Columns = columns }
	end

	-- Split into numbers so a resize that changes neither leaves bindings alone.
	local tileSize = derive(function(): number
		return computeGrid().TileSize
	end)
	local columns = derive(function(): number
		return computeGrid().Columns
	end)

	local function cellWidth(): number
		local current = metrics()
		local nameRoom = if current.ShowsNames then current.TileGap + current.NameWidth else 0
		return tileSize() + nameRoom
	end

	local function contentWidth(): number
		local count = columns()
		return cellWidth() * count + metrics().TileGap * (count - 1)
	end

	local tiles = {}
	for index, blockType in BlockTypes.List do
		tiles[index] = tile({
			BlockType = blockType,
			LayoutOrder = index,
			Metrics = metrics,
			TileSize = tileSize,
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
		AnchorPoint = props.AnchorPoint,
		Position = props.Position,
		Size = UDim2.new(),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = PANEL_COLOR,
		BackgroundTransparency = 0.2,
		-- Sinks presses that miss a tile, so a tap in a gap or on the title does
		-- not place a block in the world behind the panel.
		Active = true,

		create("UICorner")({ CornerRadius = UDim.new(0, PANEL_RADIUS) }),
		create("UIPadding")({
			PaddingLeft = function()
				return UDim.new(0, metrics().PanelPadding)
			end,
			PaddingRight = function()
				return UDim.new(0, metrics().PanelPadding)
			end,
			PaddingTop = function()
				return UDim.new(0, metrics().PanelPadding)
			end,
			PaddingBottom = function()
				return UDim.new(0, metrics().PanelPadding)
			end,
		}),
		create("UIListLayout")({
			FillDirection = Enum.FillDirection.Vertical,
			Padding = function()
				return UDim.new(0, metrics().TileGap)
			end,
		}),

		create("TextLabel")({
			Name = "Title",
			LayoutOrder = 1,
			Size = function()
				return UDim2.fromOffset(contentWidth(), metrics().TitleHeight)
			end,
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextSize = function()
				return metrics().TitleTextSize
			end,
			TextColor3 = TEXT_COLOR,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = function()
				return BlockTypes.ByName[props.Selected()].DisplayName
			end,
		}),

		create("Frame")({
			Name = "Tiles",
			LayoutOrder = 2,
			-- AutomaticSize grows from Size, and the default 100 by 100 would pad a
			-- row of smaller tiles.
			Size = UDim2.new(),
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,

			create("UIGridLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				FillDirectionMaxCells = columns,
				CellSize = function()
					return UDim2.fromOffset(cellWidth(), tileSize())
				end,
				CellPadding = function()
					local gap = metrics().TileGap
					return UDim2.fromOffset(gap, gap)
				end,
			}),

			tiles,
		}),
	})
end

return blockPicker
