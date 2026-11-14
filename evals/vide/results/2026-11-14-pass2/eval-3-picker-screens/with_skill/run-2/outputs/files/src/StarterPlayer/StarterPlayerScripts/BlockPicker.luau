--!strict
--[[
	The block picker: one tile per block type, with the block's name on each.

	Layouts:
	- Column: tiles down the screen with names beside them, under a title
	  naming the selected block. For mouse and keyboard, and gamepad.
	- Row: tiles across the screen with names below, sized for thumbs. For
	  touch screens with room to spare, such as tablets.
	- CompactRow: a smaller Row for phone-sized screens.

	Where the picker sits is up to the screen that mounts it.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
local Vide = require(ReplicatedStorage.Packages.Vide)

local create = Vide.create
local derive = Vide.derive
local read = Vide.read

local TILE_RADIUS = 6
-- Space between a swatch and its name, beside it or below it.
local NAME_GAP = 6
local TITLE_HEIGHT = 30
local TITLE_TEXT_SIZE = 22
local PANEL_RADIUS = 10
local IDLE_STROKE_THICKNESS = 1
local SELECTED_STROKE_THICKNESS = 3
local PANEL_COLOR = Color3.fromRGB(28, 28, 34)
local SELECTED_COLOR = Color3.fromRGB(255, 200, 60)
local IDLE_STROKE_COLOR = Color3.fromRGB(70, 70, 80)
local TEXT_COLOR = Color3.fromRGB(240, 240, 240)

type BlockType = BlockTypes.BlockType

export type Layout = "Column" | "Row" | "CompactRow"

type Metrics = {
	Direction: Enum.FillDirection,
	IsNameBeside: boolean,
	HasTitle: boolean,
	TileSize: number,
	-- Width of one tile's pressable cell, swatch and name together.
	CellWidth: number,
	Gap: number,
	PanelPadding: number,
	NameTextSize: number,
	-- Only used when the name sits below the swatch.
	NameHeight: number,
}

local METRICS: { [Layout]: Metrics } = {
	Column = {
		Direction = Enum.FillDirection.Vertical,
		IsNameBeside = true,
		HasTitle = true,
		TileSize = 44,
		CellWidth = 146,
		Gap = 6,
		PanelPadding = 10,
		NameTextSize = 18,
		NameHeight = 0,
	},
	Row = {
		Direction = Enum.FillDirection.Horizontal,
		IsNameBeside = false,
		HasTitle = false,
		TileSize = 64,
		CellWidth = 76,
		Gap = 8,
		PanelPadding = 8,
		NameTextSize = 16,
		NameHeight = 20,
	},
	CompactRow = {
		Direction = Enum.FillDirection.Horizontal,
		IsNameBeside = false,
		HasTitle = false,
		TileSize = 48,
		CellWidth = 60,
		Gap = 6,
		PanelPadding = 8,
		NameTextSize = 14,
		NameHeight = 16,
	},
}

type TileProps = {
	BlockType: BlockType,
	LayoutOrder: number,
	Metrics: () -> Metrics,
	IsSelected: () -> boolean,
	Select: () -> (),
}

local function tile(props: TileProps): TextButton
	local metrics = props.Metrics

	return create("TextButton")({
		Name = props.BlockType.Name,
		LayoutOrder = props.LayoutOrder,
		Size = function()
			local current = metrics()
			local height = if current.IsNameBeside
				then current.TileSize
				else current.TileSize + NAME_GAP + current.NameHeight
			return UDim2.fromOffset(current.CellWidth, height)
		end,
		BackgroundTransparency = 1,

		Activated = props.Select,

		create("Frame")({
			Name = "Swatch",
			AnchorPoint = function()
				return if metrics().IsNameBeside then Vector2.zero else Vector2.new(0.5, 0)
			end,
			Position = function()
				return if metrics().IsNameBeside then UDim2.new() else UDim2.fromScale(0.5, 0)
			end,
			Size = function()
				local tileSize = metrics().TileSize
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
			Position = function()
				local current = metrics()
				return if current.IsNameBeside
					then UDim2.fromOffset(current.TileSize + NAME_GAP, 0)
					else UDim2.fromOffset(0, current.TileSize + NAME_GAP)
			end,
			Size = function()
				local current = metrics()
				if current.IsNameBeside then
					local nameWidth = current.CellWidth - current.TileSize - NAME_GAP
					return UDim2.fromOffset(nameWidth, current.TileSize)
				else
					return UDim2.fromOffset(current.CellWidth, current.NameHeight)
				end
			end,
			BackgroundTransparency = 1,
			Font = function()
				return if props.IsSelected() then Enum.Font.GothamBold else Enum.Font.Gotham
			end,
			TextSize = function()
				return metrics().NameTextSize
			end,
			TextColor3 = function()
				return if props.IsSelected() then SELECTED_COLOR else TEXT_COLOR
			end,
			TextXAlignment = function()
				return if metrics().IsNameBeside
					then Enum.TextXAlignment.Left
					else Enum.TextXAlignment.Center
			end,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = props.BlockType.DisplayName,
		}),
	})
end

export type BlockPickerProps = {
	Selected: () -> string,
	Select: (name: string) -> (),
	Layout: Layout | () -> Layout,
	AnchorPoint: (Vector2 | () -> Vector2)?,
	Position: (UDim2 | () -> UDim2)?,
}

local function blockPicker(props: BlockPickerProps): Frame
	-- Derived, so bindings rerun when the layout flips and not on every
	-- pixel of a window resize.
	local metrics = derive(function(): Metrics
		local layout: Layout = read(props.Layout)
		return METRICS[layout]
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

	local function padding()
		return UDim.new(0, metrics().PanelPadding)
	end

	return create("Frame")({
		Name = "BlockPicker",
		AnchorPoint = props.AnchorPoint,
		Position = props.Position,
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
			FillDirection = function()
				return metrics().Direction
			end,
			Padding = function()
				return UDim.new(0, metrics().Gap)
			end,
		}),

		create("TextLabel")({
			Name = "Title",
			LayoutOrder = 1,
			-- A list layout skips hidden children, so the rows lose no space.
			Visible = function()
				return metrics().HasTitle
			end,
			Size = function()
				return UDim2.fromOffset(metrics().CellWidth, TITLE_HEIGHT)
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
