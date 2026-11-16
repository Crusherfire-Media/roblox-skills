--[[
	The block picker: one tile per block type under a title naming the selected block.

	With a keyboard and mouse or a gamepad it is a column down the left side of the screen, with each
	block's name beside its tile. On touch screens the left side belongs to the movement thumbstick
	and the bottom right to the jump button, so it becomes a row of larger, name-less tiles along the
	top centre instead. It switches between the two as soon as the player's input changes.

	Sizes are in design units; the Screen it is mounted in scales them to the display.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
local Responsive = require(script.Parent.UI.Responsive)
local Vide = require(ReplicatedStorage.Packages.Vide)

local create = Vide.create

type BlockType = BlockTypes.BlockType

local TILE_SIZE = 40
local TILE_GAP = 6
-- Comfortably above the minimum tap target so neighbouring tiles are hard to hit by mistake.
local TOUCH_TILE_SIZE = Responsive.MIN_TOUCH_TARGET + 4
local TOUCH_TILE_GAP = 8
local TILE_RADIUS = 6
-- Outline thickness as a fraction of the swatch's size (3 and 1 pixels on a 40-unit tile).
local SELECTED_STROKE = 3 / TILE_SIZE
local IDLE_STROKE = 1 / TILE_SIZE
local NAME_WIDTH = 96
local NAME_TEXT_SIZE = 16
local TITLE_HEIGHT = 26
local TITLE_TEXT_SIZE = 22
local PANEL_PADDING = 10
local PANEL_RADIUS = 10
local SCREEN_MARGIN = 20
local TOUCH_SCREEN_MARGIN = 8
local PANEL_COLOR = Color3.fromRGB(28, 28, 34)
local SELECTED_COLOR = Color3.fromRGB(255, 200, 60)
local IDLE_STROKE_COLOR = Color3.fromRGB(70, 70, 80)
local TEXT_COLOR = Color3.fromRGB(240, 240, 240)

local function tileSize(): number
	return if Responsive.isTouch() then TOUCH_TILE_SIZE else TILE_SIZE
end

local function tileGap(): number
	return if Responsive.isTouch() then TOUCH_TILE_GAP else TILE_GAP
end

local function showsNames(): boolean
	return not Responsive.isTouch()
end

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
		Size = function()
			local size = tileSize()
			local width = if showsNames() then size + tileGap() + NAME_WIDTH else size
			return UDim2.fromOffset(width, size)
		end,
		BackgroundTransparency = 1,

		Activated = props.Select,

		create("Frame")({
			Name = "Swatch",
			Size = function()
				local size = tileSize()
				return UDim2.fromOffset(size, size)
			end,
			BackgroundColor3 = props.BlockType.Color,

			create("UICorner")({ CornerRadius = UDim.new(0, TILE_RADIUS) }),
			create("UIStroke")({
				-- Thickness is a fraction of the swatch, so the outline grows with the tile on
				-- every display instead of staying a fixed number of pixels.
				StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
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
			Visible = showsNames,
			Position = function()
				return UDim2.fromOffset(tileSize() + tileGap(), 0)
			end,
			Size = function()
				return UDim2.fromOffset(NAME_WIDTH, tileSize())
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
}

local function blockPicker(props: BlockPickerProps): Frame
	local tiles = {}
	for index, blockType in BlockTypes.List do
		tiles[index] = tile({
			BlockType = blockType,
			LayoutOrder = index,
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
			return if Responsive.isTouch() then Vector2.new(0.5, 0) else Vector2.new(0, 0.5)
		end,
		Position = function()
			return if Responsive.isTouch()
				then UDim2.new(0.5, 0, 0, TOUCH_SCREEN_MARGIN)
				else UDim2.new(0, SCREEN_MARGIN, 0.5, 0)
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
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = function()
				return UDim.new(0, tileGap())
			end,
		}),

		create("TextLabel")({
			Name = "Title",
			LayoutOrder = 1,
			-- Fills the panel's width, which the tiles decide.
			Size = UDim2.new(1, 0, 0, TITLE_HEIGHT),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextSize = TITLE_TEXT_SIZE,
			TextColor3 = TEXT_COLOR,
			TextXAlignment = function()
				return if Responsive.isTouch()
					then Enum.TextXAlignment.Center
					else Enum.TextXAlignment.Left
			end,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = function()
				return BlockTypes.ByName[props.Selected()].DisplayName
			end,
		}),

		create("Frame")({
			Name = "Tiles",
			LayoutOrder = 2,
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,

			create("UIListLayout")({
				FillDirection = function()
					return if Responsive.isTouch()
						then Enum.FillDirection.Horizontal
						else Enum.FillDirection.Vertical
				end,
				Padding = function()
					return UDim.new(0, tileGap())
				end,
			}),

			tiles,
		}),
	})
end

return blockPicker
