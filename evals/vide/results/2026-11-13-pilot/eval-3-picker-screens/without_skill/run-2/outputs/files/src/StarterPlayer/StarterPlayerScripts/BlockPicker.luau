--[[
	The block picker: one tile per block type under a title naming the selected block.

	It has two layouts and switches between them live, using the Responsive value of the Screen it
	is built in:

	- Column: down the left side, with each block's name beside its tile. Used with a keyboard and
	  mouse or a gamepad when the screen is tall enough for it.
	- Bar: a row of larger tiles along the top centre. Used for touch, because the movement
	  thumbstick and jump button live in the bottom corners, and on any screen too small for the
	  column.

	With a keyboard and mouse, each tile shows the number key that selects it.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
local Responsive = require(script.Parent.UI.Responsive)
local Vide = require(ReplicatedStorage.Packages.Vide)

local create = Vide.create
local derive = Vide.derive

type BlockType = BlockTypes.BlockType

-- All sizes are design units (see UI/Responsive.luau).
local TILE_SIZE = 40
local TILE_GAP = 6
-- Touch tiles meet the usual 44 to 48 point minimum for something a thumb has to hit.
local TOUCH_TILE_SIZE = 48
local TOUCH_TILE_GAP = 8
local TILE_RADIUS = 6
local RING_THICKNESS = 1
local SELECTED_RING_THICKNESS = 3
local NAME_WIDTH = 96
local NAME_TEXT_SIZE = 16
local KEY_HINT_TEXT_SIZE = 12
local TITLE_HEIGHT = 30
local TITLE_MAX_TEXT_SIZE = 24
local PANEL_PADDING = 10
local PANEL_RADIUS = 10
local SCREEN_MARGIN = 20
local TOUCH_SCREEN_MARGIN = 8
-- BlockPlacer binds the number keys 1 to this to the first block types.
local HOTKEY_COUNT = 5

local PANEL_COLOR = Color3.fromRGB(28, 28, 34)
local SELECTED_COLOR = Color3.fromRGB(255, 200, 60)
local IDLE_RING_COLOR = Color3.fromRGB(70, 70, 80)
local TEXT_COLOR = Color3.fromRGB(240, 240, 240)
local KEY_HINT_STROKE_COLOR = Color3.fromRGB(0, 0, 0)

type Metrics = {
	IsBar: boolean,
	TileSize: number,
	Gap: number,
	-- Width of the title and of the tiles under it.
	ContentWidth: number,
	Margin: number,
	ShowKeyHints: boolean,
}

local function computeMetrics(
	size: Vector2,
	sizeClass: Responsive.SizeClass,
	input: Responsive.InputKind
): Metrics
	local isTouch = input == "Touch"
	local tileSize = if isTouch then TOUCH_TILE_SIZE else TILE_SIZE
	local gap = if isTouch then TOUCH_TILE_GAP else TILE_GAP
	local count = #BlockTypes.List

	local columnHeight = 2 * PANEL_PADDING + TITLE_HEIGHT + count * (tileSize + gap)
	local columnFits = columnHeight + 2 * SCREEN_MARGIN <= size.Y
	local isBar = isTouch or sizeClass == "Compact" or not columnFits

	return {
		IsBar = isBar,
		TileSize = tileSize,
		Gap = gap,
		ContentWidth = if isBar
			then count * tileSize + (count - 1) * gap
			else tileSize + gap + NAME_WIDTH,
		Margin = if isTouch then TOUCH_SCREEN_MARGIN else SCREEN_MARGIN,
		ShowKeyHints = input == "KeyboardAndMouse",
	}
end

type TileProps = {
	BlockType: BlockType,
	Index: number,
	Metrics: () -> Metrics,
	IsSelected: () -> boolean,
	Select: () -> (),
}

local function tile(props: TileProps): TextButton
	local metrics = props.Metrics

	local ringThickness = function()
		return if props.IsSelected() then SELECTED_RING_THICKNESS else RING_THICKNESS
	end

	return create("TextButton")({
		Name = props.BlockType.Name,
		LayoutOrder = props.Index,
		BackgroundTransparency = 1,
		Size = function()
			local current = metrics()
			local width = if current.IsBar then current.TileSize else current.ContentWidth
			return UDim2.fromOffset(width, current.TileSize)
		end,

		Activated = props.Select,

		-- The swatch's own background is the ring around the block colour, so the ring scales
		-- with the rest of the UI.
		create("Frame")({
			Name = "Swatch",
			Size = function()
				local tileSize = metrics().TileSize
				return UDim2.fromOffset(tileSize, tileSize)
			end,
			BackgroundColor3 = function()
				return if props.IsSelected() then SELECTED_COLOR else IDLE_RING_COLOR
			end,

			create("UICorner")({ CornerRadius = UDim.new(0, TILE_RADIUS) }),
			create("UIPadding")({
				PaddingLeft = function()
					return UDim.new(0, ringThickness())
				end,
				PaddingRight = function()
					return UDim.new(0, ringThickness())
				end,
				PaddingTop = function()
					return UDim.new(0, ringThickness())
				end,
				PaddingBottom = function()
					return UDim.new(0, ringThickness())
				end,
			}),

			create("Frame")({
				Name = "Fill",
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = props.BlockType.Color,

				create("UICorner")({
					CornerRadius = function()
						return UDim.new(0, math.max(0, TILE_RADIUS - ringThickness()))
					end,
				}),

				create("TextLabel")({
					Name = "KeyHint",
					Visible = function()
						return metrics().ShowKeyHints and props.Index <= HOTKEY_COUNT
					end,
					Position = UDim2.fromOffset(3, 1),
					Size = UDim2.fromOffset(KEY_HINT_TEXT_SIZE, KEY_HINT_TEXT_SIZE),
					BackgroundTransparency = 1,
					Font = Enum.Font.GothamBold,
					TextSize = KEY_HINT_TEXT_SIZE,
					TextColor3 = TEXT_COLOR,
					TextStrokeColor3 = KEY_HINT_STROKE_COLOR,
					TextStrokeTransparency = 0.3,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					Text = tostring(props.Index),
				}),
			}),
		}),

		create("TextLabel")({
			Name = "BlockName",
			Visible = function()
				return not metrics().IsBar
			end,
			Position = function()
				local current = metrics()
				return UDim2.fromOffset(current.TileSize + current.Gap, 0)
			end,
			Size = function()
				return UDim2.fromOffset(NAME_WIDTH, metrics().TileSize)
			end,
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			TextSize = NAME_TEXT_SIZE,
			TextColor3 = TEXT_COLOR,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = props.BlockType.DisplayName,
		}),
	})
end

export type BlockPickerProps = {
	Selected: () -> string,
	Select: (name: string) -> (),
}

--[[
	Must be built inside a Screen.
]]
local function blockPicker(props: BlockPickerProps): Frame
	local responsive = Responsive.use()
	local metrics = derive(function()
		return computeMetrics(responsive.Size(), responsive.SizeClass(), responsive.Input())
	end)

	local tiles = {}
	for index, blockType in BlockTypes.List do
		tiles[index] = tile({
			BlockType = blockType,
			Index = index,
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
		AnchorPoint = function()
			return if metrics().IsBar then Vector2.new(0.5, 0) else Vector2.new(0, 0.5)
		end,
		Position = function()
			local current = metrics()
			return if current.IsBar
				then UDim2.new(0.5, 0, 0, current.Margin)
				else UDim2.new(0, current.Margin, 0.5, 0)
		end,
		Size = UDim2.new(),
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
			Padding = function()
				return UDim.new(0, metrics().Gap)
			end,
		}),

		create("TextLabel")({
			Name = "Title",
			LayoutOrder = 1,
			Size = function()
				return UDim2.fromOffset(metrics().ContentWidth, TITLE_HEIGHT)
			end,
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextScaled = true,
			TextColor3 = TEXT_COLOR,
			TextXAlignment = function()
				return if metrics().IsBar
					then Enum.TextXAlignment.Center
					else Enum.TextXAlignment.Left
			end,
			Text = function()
				return BlockTypes.ByName[props.Selected()].DisplayName
			end,

			create("UITextSizeConstraint")({ MaxTextSize = TITLE_MAX_TEXT_SIZE }),
		}),

		create("Frame")({
			Name = "Tiles",
			LayoutOrder = 2,
			Size = UDim2.new(),
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,

			create("UIListLayout")({
				FillDirection = function()
					return if metrics().IsBar
						then Enum.FillDirection.Horizontal
						else Enum.FillDirection.Vertical
				end,
				Padding = function()
					return UDim.new(0, metrics().Gap)
				end,
			}),

			tiles,
		}),
	})
end

return blockPicker
