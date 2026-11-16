--[[
	The block picker shown in build mode: a row of tiles along the bottom of the screen, one per
	block type. It slides up when opened and back down before it is removed when closed. A yellow
	ring glides to the selected tile, and tiles squash when pressed.

	Note on springs: Vide's spring only settles exactly onto a target that isn't 0 (its tolerance
	scales with the target), so every animated value here has a non-zero resting value.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
local Vide = require(ReplicatedStorage.Packages.Vide)

local create = Vide.create
local derive = Vide.derive
local show = Vide.show
local source = Vide.source
local spring = Vide.spring

type BlockType = BlockTypes.BlockType

local TILE_SIZE = 64
local TILE_GAP = 8
local TILE_RADIUS = 8
local TILE_STRIDE = TILE_SIZE + TILE_GAP
local PANEL_PADDING = 8
local PANEL_RADIUS = TILE_RADIUS + PANEL_PADDING
local BOTTOM_MARGIN = 24
local PANEL_COLOR = Color3.fromRGB(28, 28, 34)
local SELECTED_COLOR = Color3.fromRGB(255, 200, 60)
local IDLE_STROKE_COLOR = Color3.fromRGB(70, 70, 80)

-- The selection ring sits slightly outside the tile so a squashed tile still reads as selected.
local RING_OUTSET = 4
local RING_THICKNESS = 3

-- Panel slide: vertical offset of the panel's bottom edge from the bottom of the screen.
local SHOWN_OFFSET = -BOTTOM_MARGIN
local SLIDE_PERIOD = 0.4
local SLIDE_DAMPING = 0.8

local GLIDE_PERIOD = 0.25
local GLIDE_DAMPING = 0.75

local PRESSED_SCALE = 0.88
local PRESS_PERIOD = 0.2
local PRESS_DAMPING = 0.45

local function isPressInput(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

type TileProps = {
	BlockType: BlockType,
	LayoutOrder: number,
	Select: () -> (),
}

local function tile(props: TileProps): Frame
	local isPressed = source(false)
	local scale = spring(function()
		return if isPressed() then PRESSED_SCALE else 1
	end, PRESS_PERIOD, PRESS_DAMPING)

	-- The layout positions the slot; the button inside scales around its centre.
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

			Activated = props.Select,
			InputBegan = function(input: InputObject)
				if isPressInput(input) then
					isPressed(true)
				end
			end,
			InputEnded = function(input: InputObject)
				if isPressInput(input) then
					isPressed(false)
				end
			end,
			MouseLeave = function()
				isPressed(false)
			end,

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

local function selectionRing(selectedIndex: () -> number): Frame
	-- Always positive (PANEL_PADDING > RING_OUTSET), so the spring settles exactly.
	local x = spring(function()
		return PANEL_PADDING - RING_OUTSET + (selectedIndex() - 1) * TILE_STRIDE
	end, GLIDE_PERIOD, GLIDE_DAMPING)

	return create("Frame")({
		Name = "SelectionRing",
		Position = function()
			return UDim2.fromOffset(x(), PANEL_PADDING - RING_OUTSET)
		end,
		Size = UDim2.fromOffset(TILE_SIZE + RING_OUTSET * 2, TILE_SIZE + RING_OUTSET * 2),
		BackgroundTransparency = 1,
		Active = false,
		ZIndex = 2,

		create("UICorner")({ CornerRadius = UDim.new(0, TILE_RADIUS + RING_OUTSET) }),
		create("UIStroke")({
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			BorderStrokePosition = Enum.BorderStrokePosition.Inner,
			Color = SELECTED_COLOR,
			Thickness = RING_THICKNESS,
		}),
	})
end

export type BlockPickerProps = {
	Open: () -> boolean,
	Selected: () -> string,
	Select: (name: string) -> (),
}

local function blockPicker(props: BlockPickerProps)
	local count = #BlockTypes.List
	local panelSize = Vector2.new(
		count * TILE_SIZE + (count - 1) * TILE_GAP + PANEL_PADDING * 2,
		TILE_SIZE + PANEL_PADDING * 2
	)
	-- Fully below the screen edge, with a little room for the spring to overshoot.
	local hiddenOffset = panelSize.Y + PANEL_PADDING

	-- This spring lives outside the shown panel so it keeps its state across open/close toggles:
	-- reopening mid-slide just retargets it instead of remounting the panel.
	local offset = spring(function()
		return if props.Open() then SHOWN_OFFSET else hiddenOffset
	end, SLIDE_PERIOD, SLIDE_DAMPING)

	-- Stay mounted while open or while still sliding out; the spring snaps exactly to
	-- hiddenOffset once it settles, which is what removes the panel.
	local isMounted = derive(function()
		return props.Open() or offset() ~= hiddenOffset
	end)

	return show(isMounted, function()
		local selectedIndex = derive(function()
			local name = props.Selected()
			for index, blockType in BlockTypes.List do
				if blockType.Name == name then
					return index
				end
			end
			return 1
		end)

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

		return create("Frame")({
			Name = "BlockPicker",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = function()
				return UDim2.new(0.5, 0, 1, offset())
			end,
			Size = UDim2.fromOffset(panelSize.X, panelSize.Y),
			BackgroundColor3 = PANEL_COLOR,
			BackgroundTransparency = 0.2,
			-- Ignore presses while sliding away.
			Interactable = props.Open,

			create("UICorner")({ CornerRadius = UDim.new(0, PANEL_RADIUS) }),

			create("Frame")({
				Name = "Tiles",
				Position = UDim2.fromOffset(PANEL_PADDING, PANEL_PADDING),
				Size = UDim2.new(1, -PANEL_PADDING * 2, 1, -PANEL_PADDING * 2),
				BackgroundTransparency = 1,

				create("UIListLayout")({
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, TILE_GAP),
				}),

				tiles,
			}),

			selectionRing(selectedIndex),
		})
	end)
end

return blockPicker
