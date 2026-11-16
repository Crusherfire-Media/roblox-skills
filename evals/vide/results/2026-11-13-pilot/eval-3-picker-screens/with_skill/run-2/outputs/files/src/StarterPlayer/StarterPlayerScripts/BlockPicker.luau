--!strict
--@author: Crusherfire
--@date: 2026-11-13
--[[@description:
	The block picker: one tile per block type under a title naming the
	selected block. The Column layout stacks the tiles with each block's name
	beside it, for mouse and keyboard. The Row layout lines up larger tiles
	with no names, sized for thumbs. The screen that mounts it picks the
	layout and places it.
]]

const BlockTypes = require("@game/ReplicatedStorage/Shared/BlockTypes")
const Vide = require("@game/ReplicatedStorage/Packages/Vide")

const create = Vide.create
const derive = Vide.derive
const read = Vide.read

type BlockType = BlockTypes.BlockType

export type Layout = "Column" | "Row"

type Metrics = {
	TileSize: number,
	TileGap: number,
	PanelPadding: number,
	TitleHeight: number,
	TitleTextSize: number,
	ShowsNames: boolean,
	TileDirection: Enum.FillDirection,
}

const COLUMN: Metrics = table.freeze({
	TileSize = 40,
	TileGap = 6,
	PanelPadding = 10,
	TitleHeight = 30,
	TitleTextSize = 22,
	ShowsNames = true,
	TileDirection = Enum.FillDirection.Vertical,
})
-- Tiles stay above 44, the smallest size a thumb hits reliably.
const ROW: Metrics = table.freeze({
	TileSize = 52,
	TileGap = 8,
	PanelPadding = 8,
	TitleHeight = 22,
	TitleTextSize = 18,
	ShowsNames = false,
	TileDirection = Enum.FillDirection.Horizontal,
})

const NAME_WIDTH = 96
const NAME_TEXT_SIZE = 16
const TILE_RADIUS = 6
const PANEL_RADIUS = 10
const SELECTED_STROKE = 3
const IDLE_STROKE = 1
const PANEL_COLOR = Color3.fromRGB(28, 28, 34)
const SELECTED_COLOR = Color3.fromRGB(255, 200, 60)
const IDLE_STROKE_COLOR = Color3.fromRGB(70, 70, 80)
const TEXT_COLOR = Color3.fromRGB(240, 240, 240)

type TileProps = {
	BlockType: BlockType,
	LayoutOrder: number,
	Metrics: () -> Metrics,
	IsSelected: () -> boolean,
	Select: () -> (),
}

local function tileWidth(metrics: Metrics): number
	if metrics.ShowsNames then
		return metrics.TileSize + metrics.TileGap + NAME_WIDTH
	end
	return metrics.TileSize
end

local function tile(props: TileProps): TextButton
	return create("TextButton")({
		Name = props.BlockType.Name,
		LayoutOrder = props.LayoutOrder,
		Size = function()
			local metrics = props.Metrics()
			return UDim2.fromOffset(tileWidth(metrics), metrics.TileSize)
		end,
		BackgroundTransparency = 1,

		Activated = props.Select,

		create("Frame")({
			Name = "Swatch",
			Size = function()
				local tileSize = props.Metrics().TileSize
				return UDim2.fromOffset(tileSize, tileSize)
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
		}),

		create("TextLabel")({
			Name = "BlockName",
			Visible = function()
				return props.Metrics().ShowsNames
			end,
			Position = function()
				local metrics = props.Metrics()
				return UDim2.fromOffset(metrics.TileSize + metrics.TileGap, 0)
			end,
			Size = function()
				return UDim2.fromOffset(NAME_WIDTH, props.Metrics().TileSize)
			end,
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			TextSize = NAME_TEXT_SIZE,
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
	Layout: (Layout | () -> Layout)?,
	AnchorPoint: (Vector2 | () -> Vector2)?,
	Position: (UDim2 | () -> UDim2)?,
}

local function blockPicker(props: BlockPickerProps): Frame
	-- Derived, so bindings rerun when the layout flips, not on every pixel of
	-- a window resize.
	local metrics = derive(function(): Metrics
		return if read(props.Layout) == "Row" then ROW else COLUMN
	end)

	local function contentWidth(): number
		local current = metrics()
		if current.ShowsNames then
			return tileWidth(current)
		end
		local count = #BlockTypes.List
		return count * current.TileSize + (count - 1) * current.TileGap
	end

	local tiles = {}
	for index, blockType in BlockTypes.List do
		tiles[index] = tile({
			BlockType = blockType,
			LayoutOrder = index,
			Metrics = metrics,
			IsSelected = function()
				return props.Selected() == blockType.Name
			end,
			Select = function()
				props.Select(blockType.Name)
			end,
		})
	end

	local function padding(): UDim
		return UDim.new(0, metrics().PanelPadding)
	end

	local function gap(): UDim
		return UDim.new(0, metrics().TileGap)
	end

	return create("Frame")({
		Name = "BlockPicker",
		AnchorPoint = props.AnchorPoint,
		Position = props.Position,
		Size = UDim2.new(),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = PANEL_COLOR,
		BackgroundTransparency = 0.2,

		create("UICorner")({ CornerRadius = UDim.new(0, PANEL_RADIUS) }),
		create("UIPadding")({
			PaddingLeft = padding,
			PaddingRight = padding,
			PaddingTop = padding,
			PaddingBottom = padding,
		}),
		create("UIListLayout")({
			FillDirection = Enum.FillDirection.Vertical,
			Padding = gap,
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
			Size = UDim2.new(),
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,

			create("UIListLayout")({
				FillDirection = function()
					return metrics().TileDirection
				end,
				Padding = gap,
			}),

			tiles,
		}),
	})
end

return blockPicker
