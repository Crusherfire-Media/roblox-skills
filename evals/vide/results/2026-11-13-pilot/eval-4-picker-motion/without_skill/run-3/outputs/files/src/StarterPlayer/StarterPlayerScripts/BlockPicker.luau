--[[
	The block picker shown in build mode: a row of tiles along the bottom of the screen, one per
	block type. A single yellow highlight glides to the selected tile.

	The picker slides up from below the screen when it appears and slides back down before it is
	removed. It is meant to be used inside `Vide.show`: it takes the `Present` source that `show`
	passes to its component, and returns the exit delay `show` should wait before destroying it.
	If build mode is turned back on during the slide-out, `show` keeps the same picker and the
	spring simply turns around, so spamming the toggle is safe.
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
local PANEL_HEIGHT = TILE_SIZE + PANEL_PADDING * 2
local BOTTOM_MARGIN = 24
local PANEL_COLOR = Color3.fromRGB(28, 28, 34)
local SELECTED_COLOR = Color3.fromRGB(255, 200, 60)
local IDLE_STROKE_COLOR = Color3.fromRGB(70, 70, 80)
local HIGHLIGHT_THICKNESS = 3

-- The panel is anchored at its bottom centre. Shown, it sits BOTTOM_MARGIN above the screen's
-- bottom edge; hidden, its top edge is a little below the screen.
local SHOWN_POSITION = UDim2.new(0.5, 0, 1, -BOTTOM_MARGIN)
local HIDDEN_POSITION = UDim2.new(0.5, 0, 1, PANEL_HEIGHT + 16)
local SLIDE_PERIOD = 0.35
local SLIDE_DAMPING = 0.75
-- How long `show` keeps the picker after build mode turns off, so the slide-out can finish.
local EXIT_DELAY = 0.4

local HIGHLIGHT_PERIOD = 0.25
local HIGHLIGHT_DAMPING = 0.7

local PRESSED_SCALE = 0.86
local HOVER_SCALE = 1.06
local PRESS_PERIOD = 0.2
local PRESS_DAMPING = 0.45

type TileProps = {
	BlockType: BlockType,
	LayoutOrder: number,
	Interactable: () -> boolean,
	Select: () -> (),
}

-- A tile is a fixed slot in the row holding a button centred inside it, so the button can shrink
-- and grow around its centre without nudging the layout.
local function tile(props: TileProps): Frame
	local guiState = source(Enum.GuiState.Idle)

	local scale = spring(function()
		local state = guiState()
		if state == Enum.GuiState.Press then
			return PRESSED_SCALE
		elseif state == Enum.GuiState.Hover then
			return HOVER_SCALE
		end
		return 1
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
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = props.BlockType.Color,
			Text = "",
			AutoButtonColor = false,
			Interactable = props.Interactable,

			Activated = props.Select,
			changed("GuiState", guiState),

			create("UIScale")({ Scale = scale }),
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

local function tileOffset(index: number): UDim2
	return UDim2.fromOffset((index - 1) * (TILE_SIZE + TILE_GAP), 0)
end

export type BlockPickerProps = {
	Selected: () -> string,
	Select: (name: string) -> (),
	-- From `Vide.show`: true while the picker should be on screen, false while it leaves.
	Present: () -> boolean,
}

local function blockPicker(props: BlockPickerProps): (Frame, number)
	local tiles = {}
	local indexByName: { [string]: number } = {}
	for index, blockType in BlockTypes.List do
		indexByName[blockType.Name] = index
		tiles[index] = tile({
			BlockType = blockType,
			LayoutOrder = index,
			Interactable = props.Present,
			Select = function()
				props.Select(blockType.Name)
			end,
		})
	end

	local count = #BlockTypes.List

	-- `show` creates the picker with Present false and flips it to true right after, so the
	-- spring starts below the screen and slides up.
	local position = spring(function()
		return if props.Present() then SHOWN_POSITION else HIDDEN_POSITION
	end, SLIDE_PERIOD, SLIDE_DAMPING)

	local highlightPosition = spring(function()
		return tileOffset(indexByName[props.Selected()] or 1)
	end, HIGHLIGHT_PERIOD, HIGHLIGHT_DAMPING)

	local panel = create("Frame")({
		Name = "BlockPicker",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = position,
		Size = UDim2.fromOffset(
			count * TILE_SIZE + (count - 1) * TILE_GAP + PANEL_PADDING * 2,
			PANEL_HEIGHT
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
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, TILE_GAP),
			}),

			tiles,
		}),

		-- Drawn over the tiles and kept out of the list layout so it can move freely.
		create("Frame")({
			Name = "Highlight",
			ZIndex = 2,
			Position = highlightPosition,
			Size = UDim2.fromOffset(TILE_SIZE, TILE_SIZE),
			BackgroundTransparency = 1,
			Active = false,

			create("UICorner")({ CornerRadius = UDim.new(0, TILE_RADIUS) }),
			create("UIStroke")({
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				BorderStrokePosition = Enum.BorderStrokePosition.Inner,
				Color = SELECTED_COLOR,
				Thickness = HIGHLIGHT_THICKNESS,
			}),
		}),
	})

	return panel, EXIT_DELAY
end

return blockPicker
