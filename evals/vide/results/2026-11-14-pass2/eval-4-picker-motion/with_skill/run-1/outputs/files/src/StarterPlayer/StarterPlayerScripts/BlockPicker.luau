--[[
	The block picker shown in build mode: a row of tiles along the bottom of the screen, one per
	block type. It slides up from below the screen while Present is true and back down when it
	turns false. One yellow highlight glides to the selected tile, and tiles sink when pressed.
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

local SHOWN_POSITION = UDim2.new(0.5, 0, 1, -BOTTOM_MARGIN)
local HIDDEN_POSITION = UDim2.new(0.5, 0, 1, PANEL_HEIGHT + BOTTOM_MARGIN)
local SLIDE_PERIOD = 0.3
-- A critically damped spring is within a pixel of its target after about one period.
local EXIT_DURATION = SLIDE_PERIOD * 1.2
local HIGHLIGHT_PERIOD = 0.25
local PRESSED_SCALE = 0.88
local PRESS_PERIOD = 0.25
-- Below 1 so a released tile springs back with a small bounce.
local PRESS_DAMPING = 0.45

type TileProps = {
	BlockType: BlockType,
	LayoutOrder: number,
	Interactable: () -> boolean,
	Select: () -> (),
}

local function tile(props: TileProps): TextButton
	local guiState = source(Enum.GuiState.Idle)

	local scale = spring(function()
		return if guiState() == Enum.GuiState.Press then PRESSED_SCALE else 1
	end, PRESS_PERIOD, PRESS_DAMPING)

	return create("TextButton")({
		Name = props.BlockType.Name,
		LayoutOrder = props.LayoutOrder,
		Size = UDim2.fromOffset(TILE_SIZE, TILE_SIZE),
		BackgroundColor3 = props.BlockType.Color,
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
	})
end

local function indexOf(name: string): number
	for index, blockType in BlockTypes.List do
		if blockType.Name == name then
			return index
		end
	end
	return 1
end

export type BlockPickerProps = {
	Selected: () -> string,
	Select: (name: string) -> (),
	-- The present source from show(); the picker sits below the screen while it is false.
	Present: () -> boolean,
}

local function blockPicker(props: BlockPickerProps): Frame
	local tiles = {}
	for index, blockType in BlockTypes.List do
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

	local position = spring(function()
		return if props.Present() then SHOWN_POSITION else HIDDEN_POSITION
	end, SLIDE_PERIOD)

	local highlightPosition = spring(function()
		local index = indexOf(props.Selected())
		return UDim2.fromOffset((index - 1) * (TILE_SIZE + TILE_GAP), 0)
	end, HIGHLIGHT_PERIOD)

	return create("Frame")({
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

		-- Its own frame, or the list layout would also place the highlight.
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
				Thickness = 3,
			}),
		}),
	})
end

return {
	new = blockPicker,
	ExitDuration = EXIT_DURATION,
}
