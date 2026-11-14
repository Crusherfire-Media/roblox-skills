--!strict
--[[
	The block picker: one tile per block type under a title naming the selected
	block. The Column layout lists the tiles down the screen with each block's
	name beside it; the Row layout is a hotbar of larger tiles for thumbs.
	Where the picker sits on screen is up to whoever mounts it.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
local Vide = require(ReplicatedStorage.Packages.Vide)

local create = Vide.create
local derive = Vide.derive
local read = Vide.read

local TILE_GAP = 6
local TILE_RADIUS = 6
local IDLE_STROKE_THICKNESS = 1
local SELECTED_STROKE_THICKNESS = 3
local NAME_WIDTH = 96
local NAME_TEXT_SIZE = 16
local TITLE_HEIGHT = 30
local TITLE_TEXT_SIZE = 24
local PANEL_PADDING = 10
local PANEL_RADIUS = 10
local PANEL_COLOR = Color3.fromRGB(28, 28, 34)
local SELECTED_COLOR = Color3.fromRGB(255, 200, 60)
local IDLE_STROKE_COLOR = Color3.fromRGB(70, 70, 80)
local TEXT_COLOR = Color3.fromRGB(240, 240, 240)

type BlockType = BlockTypes.BlockType

export type Layout = "Column" | "Row"

type Metrics = {
	TileSize: number,
	ShowsNames: boolean,
	FillDirection: Enum.FillDirection,
	TitleAlignment: Enum.TextXAlignment,
}

local COLUMN_METRICS: Metrics = table.freeze({
	TileSize = 40,
	ShowsNames = true,
	FillDirection = Enum.FillDirection.Vertical,
	TitleAlignment = Enum.TextXAlignment.Left,
})
-- No names beside the tiles, so the row fits between the thumbstick and the
-- jump button on a phone.
local ROW_METRICS: Metrics = table.freeze({
	TileSize = 52,
	ShowsNames = false,
	FillDirection = Enum.FillDirection.Horizontal,
	TitleAlignment = Enum.TextXAlignment.Center,
})

local COLUMN_CONTENT_WIDTH = COLUMN_METRICS.TileSize + TILE_GAP + NAME_WIDTH

type TileProps = {
	BlockType: BlockType,
	LayoutOrder: number,
	Metrics: () -> Metrics,
	IsSelected: () -> boolean,
	Select: () -> (),
}

export type BlockPickerProps = {
	Layout: Layout | () -> Layout,
	Selected: () -> string,
	Select: (name: string) -> (),
	-- Defaults to every block type in the game.
	BlockTypes: { BlockType }?,
}

local BlockPicker = {}

local function metricsFor(layout: Layout): Metrics
	return if layout == "Column" then COLUMN_METRICS else ROW_METRICS
end

local function contentWidth(layout: Layout, count: number): number
	if layout == "Column" then
		return COLUMN_CONTENT_WIDTH
	end
	local tileSize = ROW_METRICS.TileSize
	local rowWidth = count * tileSize + math.max(count - 1, 0) * TILE_GAP
	-- The title needs room even when only a tile or two shows.
	return math.max(rowWidth, COLUMN_CONTENT_WIDTH)
end

local function contentHeight(layout: Layout, count: number): number
	if layout == "Column" then
		return TITLE_HEIGHT + count * (TILE_GAP + COLUMN_METRICS.TileSize)
	end
	return TITLE_HEIGHT + TILE_GAP + ROW_METRICS.TileSize
end

local function tile(props: TileProps): TextButton
	return create("TextButton")({
		Name = props.BlockType.Name,
		LayoutOrder = props.LayoutOrder,
		Size = function()
			local metrics = props.Metrics()
			local width = metrics.TileSize
			if metrics.ShowsNames then
				width += TILE_GAP + NAME_WIDTH
			end
			return UDim2.fromOffset(width, metrics.TileSize)
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
				return UDim2.fromOffset(props.Metrics().TileSize + TILE_GAP, 0)
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

--[[
	The picker's size in UI units for the given layout and number of block
	types, before any scale. Use it to place or fit the picker without reading
	its AbsoluteSize.
]]
function BlockPicker.designSize(layout: Layout, count: number): Vector2
	return Vector2.new(
		contentWidth(layout, count) + PANEL_PADDING * 2,
		contentHeight(layout, count) + PANEL_PADDING * 2
	)
end

function BlockPicker.component(props: BlockPickerProps): Frame
	local blockTypes = props.BlockTypes or BlockTypes.List
	local count = #blockTypes

	local byName: { [string]: BlockType? } = {}
	for _, blockType in blockTypes do
		byName[blockType.Name] = blockType
	end

	-- Derived, so bindings rerun when the layout flips, not on every pixel of
	-- a window resize.
	local layout = derive(function(): Layout
		return read(props.Layout)
	end) :: () -> Layout
	local metrics = derive(function(): Metrics
		return metricsFor(layout())
	end)

	local tiles = {}
	for index, blockType in blockTypes do
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

	return create("Frame")({
		Name = "BlockPicker",
		Size = function()
			local size = BlockPicker.designSize(layout(), count)
			return UDim2.fromOffset(size.X, size.Y)
		end,
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
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, TILE_GAP),
		}),

		create("TextLabel")({
			Name = "Title",
			LayoutOrder = 1,
			Size = function()
				return UDim2.fromOffset(contentWidth(layout(), count), TITLE_HEIGHT)
			end,
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextSize = TITLE_TEXT_SIZE,
			TextColor3 = TEXT_COLOR,
			TextXAlignment = function()
				return metrics().TitleAlignment
			end,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = function()
				local blockType = byName[props.Selected()]
				return if blockType then blockType.DisplayName else ""
			end,
		}),

		create("Frame")({
			Name = "Tiles",
			LayoutOrder = 2,
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,

			create("UIListLayout")({
				FillDirection = function()
					return metrics().FillDirection
				end,
				Padding = UDim.new(0, TILE_GAP),
			}),

			tiles,
		}),
	})
end

return BlockPicker
