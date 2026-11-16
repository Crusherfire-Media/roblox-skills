--[[
	The block picker shown in build mode: a row of tiles along the bottom of the screen, one per
	block type. It slides up from below the screen while Present is true and back down when it
	turns false. One yellow highlight glides to the selected tile, and tiles sink while pressed.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
local Vide = require(ReplicatedStorage.Packages.Vide)

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

local SLIDE_PERIOD = 0.35
local GLIDE_PERIOD = 0.25
local PRESS_PERIOD = 0.2
local PRESS_DAMPING = 0.45
local PRESSED_SCALE = 0.88
-- Keyboard and gamepad activations have no press to hold, so they get a push instead.
local ACTIVATE_IMPULSE = -2

local PANEL_HEIGHT = TILE_SIZE + PANEL_PADDING * 2
-- Far enough below the bottom edge that no part of the panel shows.
local HIDDEN_OFFSET = PANEL_HEIGHT + 8

local indexByName: { [string]: number? } = {}
for index, blockType in BlockTypes.List do
	indexByName[blockType.Name] = index
end

type TileProps = {
	BlockType: BlockType,
	LayoutOrder: number,
	Select: () -> (),
}

local function isPointerInput(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

local function tile(props: TileProps): Frame
	local isPressed = source(false)
	local scale, scaleControl = spring(function()
		return if isPressed() then PRESSED_SCALE else 1
	end, PRESS_PERIOD, PRESS_DAMPING)

	-- The button shrinks inside a fixed slot so the row's layout never shifts.
	return create("Frame")({
		Name = props.BlockType.Name,
		LayoutOrder = props.LayoutOrder,
		Size = UDim2.fromOffset(TILE_SIZE, TILE_SIZE),
		BackgroundTransparency = 1,

		create("TextButton")({
			Name = "Button",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = function()
				return UDim2.fromScale(scale(), scale())
			end,
			BackgroundColor3 = props.BlockType.Color,

			InputBegan = function(input: InputObject)
				if isPointerInput(input) then
					isPressed(true)
				end
			end,
			InputEnded = function(input: InputObject)
				if isPointerInput(input) then
					isPressed(false)
				end
			end,
			MouseLeave = function()
				isPressed(false)
			end,
			Activated = function()
				if not isPressed() then
					scaleControl({ impulse = ACTIVATE_IMPULSE })
				end
				props.Select()
			end,

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

type HighlightProps = {
	Selected: () -> string,
}

local function highlight(props: HighlightProps): Frame
	local position = spring(function()
		local index = indexByName[props.Selected()] or 1
		return UDim2.fromOffset((index - 1) * (TILE_SIZE + TILE_GAP), 0)
	end, GLIDE_PERIOD)

	return create("Frame")({
		Name = "Highlight",
		Position = position,
		Size = UDim2.fromOffset(TILE_SIZE, TILE_SIZE),
		BackgroundTransparency = 1,
		ZIndex = 2,
		Interactable = false,

		create("UICorner")({ CornerRadius = UDim.new(0, TILE_RADIUS) }),
		create("UIStroke")({
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			BorderStrokePosition = Enum.BorderStrokePosition.Inner,
			Color = SELECTED_COLOR,
			Thickness = HIGHLIGHT_THICKNESS,
		}),
	})
end

export type BlockPickerProps = {
	Selected: () -> string,
	Select: (name: string) -> (),
	-- False slides the picker below the screen. Leave it out to show the picker in place.
	Present: (() -> boolean)?,
}

local function blockPicker(props: BlockPickerProps): Frame
	local tiles = {}
	for index, blockType in BlockTypes.List do
		tiles[index] = tile({
			BlockType = blockType,
			LayoutOrder = index,
			Select = function()
				props.Select(blockType.Name)
			end,
		})
	end

	local present = props.Present
	local function isShown(): boolean
		return if present then present() else true
	end

	local slideOffset = spring(function()
		return if isShown() then -BOTTOM_MARGIN else HIDDEN_OFFSET
	end, SLIDE_PERIOD)

	local count = #BlockTypes.List

	return create("Frame")({
		Name = "BlockPicker",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = function()
			return UDim2.new(0.5, 0, 1, slideOffset())
		end,
		Size = UDim2.fromOffset(
			count * TILE_SIZE + (count - 1) * TILE_GAP + PANEL_PADDING * 2,
			PANEL_HEIGHT
		),
		BackgroundColor3 = PANEL_COLOR,
		BackgroundTransparency = 0.2,
		-- A picker on its way out takes no more clicks.
		Interactable = isShown,

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

		highlight({ Selected = props.Selected }),
	})
end

return blockPicker
