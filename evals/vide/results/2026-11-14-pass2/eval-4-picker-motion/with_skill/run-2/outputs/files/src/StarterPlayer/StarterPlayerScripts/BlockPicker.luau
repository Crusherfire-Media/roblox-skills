--[[
	The block picker shown in build mode: a row of tiles along the bottom of the screen, one per
	block type. It slides up from below the screen when shown and back down when hidden, a yellow
	highlight glides to the selected tile, and tiles sink when pressed.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
local Vide = require(ReplicatedStorage.Packages.Vide)

local cleanup = Vide.cleanup
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

local TILE_COUNT = #BlockTypes.List
local PANEL_WIDTH = TILE_COUNT * TILE_SIZE + (TILE_COUNT - 1) * TILE_GAP + PANEL_PADDING * 2
local PANEL_HEIGHT = TILE_SIZE + PANEL_PADDING * 2

local SHOWN_POSITION = UDim2.new(0.5, 0, 1, -BOTTOM_MARGIN)
-- The extra margin keeps the spring's last few pixels of travel below the screen edge.
local HIDDEN_POSITION = UDim2.new(0.5, 0, 1, PANEL_HEIGHT + BOTTOM_MARGIN)

local SLIDE_PERIOD = 0.4
local HIGHLIGHT_PERIOD = 0.25
local PRESS_PERIOD = 0.2
-- Below 1 so a released tile bounces back.
local PRESS_DAMPING = 0.45
local PRESSED_SCALE = 0.86

local function isPointerPress(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

type TileProps = {
	BlockType: BlockType,
	LayoutOrder: number,
	Select: () -> (),
}

--[[
	Only the face scales, so the button's hit area stays put while the face shrinks under the
	pointer.
]]
local function tile(props: TileProps): TextButton
	local isPressed = source(false)
	local releaseConnection: RBXScriptConnection? = nil

	local function release()
		isPressed(false)
		if releaseConnection then
			releaseConnection:Disconnect()
			releaseConnection = nil
		end
	end

	cleanup(release)

	local faceScale = spring(function()
		return if isPressed() then PRESSED_SCALE else 1
	end, PRESS_PERIOD, PRESS_DAMPING)

	return create("TextButton")({
		Name = props.BlockType.Name,
		LayoutOrder = props.LayoutOrder,
		Size = UDim2.fromOffset(TILE_SIZE, TILE_SIZE),
		BackgroundTransparency = 1,
		Text = "",

		Activated = props.Select,
		InputBegan = function(input: InputObject)
			if not isPointerPress(input) then
				return
			end
			release()
			isPressed(true)
			-- The button gets no InputEnded when the pointer is released off it.
			releaseConnection = input:GetPropertyChangedSignal("UserInputState"):Connect(function()
				if
					input.UserInputState == Enum.UserInputState.End
					or input.UserInputState == Enum.UserInputState.Cancel
				then
					release()
				end
			end)
		end,

		create("Frame")({
			Name = "Face",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = props.BlockType.Color,

			create("UIScale")({ Scale = faceScale }),
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

local function tilePosition(index: number): UDim2
	return UDim2.fromOffset((index - 1) * (TILE_SIZE + TILE_GAP), 0)
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
	-- The `present` source of the show() that builds the picker.
	Present: () -> boolean,
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

	local position = spring(function()
		return if props.Present() then SHOWN_POSITION else HIDDEN_POSITION
	end, SLIDE_PERIOD)

	local highlightPosition = spring(function()
		return tilePosition(indexOf(props.Selected()))
	end, HIGHLIGHT_PERIOD)

	return create("Frame")({
		Name = "BlockPicker",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = position,
		Size = UDim2.fromOffset(PANEL_WIDTH, PANEL_HEIGHT),
		BackgroundColor3 = PANEL_COLOR,
		BackgroundTransparency = 0.2,
		-- Build mode is already off while the picker slides away.
		Interactable = props.Present,

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

		-- Outside the tile row, so the list layout leaves its position to the spring.
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
				Thickness = HIGHLIGHT_THICKNESS,
			}),
		}),
	})
end

return {
	new = blockPicker,
	-- Seconds the picker needs to slide fully off screen once Present turns false.
	ExitDuration = SLIDE_PERIOD,
}
