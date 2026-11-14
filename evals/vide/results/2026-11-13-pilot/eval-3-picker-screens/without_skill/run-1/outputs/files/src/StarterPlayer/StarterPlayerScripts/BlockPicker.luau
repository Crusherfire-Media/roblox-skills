--[[
	The block picker: one tile per block type plus a title naming the selected block. Sizes are in
	design units (see UI/Responsive); put it inside a UI/Screen so it's scaled for the device.

	It switches layout live as the device changes:
	- "Column", for keyboard and mouse or gamepad with room to spare: a column down the left side,
	  each tile with the block's name beside it and, with a keyboard, its number key.
	- "Bar", for touch or a compact screen: a row of tiles along the top centre, with the title
	  underneath. That keeps it clear of the thumbstick (bottom left) and jump button (bottom
	  right), and makes the tiles finger-sized.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
local Responsive = require(script.Parent.UI.Responsive)
local Vide = require(ReplicatedStorage.Packages.Vide)

local create = Vide.create
local derive = Vide.derive

type BlockType = BlockTypes.BlockType
type Layout = "Column" | "Bar"

local TILE_SIZE = 40
local TILE_GAP = 6
local TILE_RADIUS = 6
local NAME_WIDTH = 96
local NAME_TEXT_SIZE = 16
local HINT_SIZE = 16
local HINT_TEXT_SIZE = 12
local COLUMN_TITLE_HEIGHT = 30
local BAR_TITLE_HEIGHT = 22
local TITLE_MAX_TEXT_SIZE = 24
local PANEL_PADDING = 10
local PANEL_RADIUS = 10
local SCREEN_MARGIN = 20
local PANEL_COLOR = Color3.fromRGB(28, 28, 34)
local SELECTED_COLOR = Color3.fromRGB(255, 200, 60)
local IDLE_STROKE_COLOR = Color3.fromRGB(70, 70, 80)
local TEXT_COLOR = Color3.fromRGB(240, 240, 240)
local HINT_COLOR = Color3.fromRGB(0, 0, 0)

local COLUMN_WIDTH = TILE_SIZE + TILE_GAP + NAME_WIDTH
local BAR_WIDTH = #BlockTypes.List * TILE_SIZE + (#BlockTypes.List - 1) * TILE_GAP

type TileProps = {
	BlockType: BlockType,
	LayoutOrder: number,
	Hotkey: string?,
	Layout: () -> Layout,
	ShowHotkey: () -> boolean,
	IsSelected: () -> boolean,
	Select: () -> (),
}

local function tile(props: TileProps): TextButton
	return create("TextButton")({
		Name = props.BlockType.Name,
		LayoutOrder = props.LayoutOrder,
		Size = function()
			local width = if props.Layout() == "Column" then COLUMN_WIDTH else TILE_SIZE
			return UDim2.fromOffset(width, TILE_SIZE)
		end,
		BackgroundTransparency = 1,
		Text = "",

		Activated = props.Select,

		create("Frame")({
			Name = "Swatch",
			Size = UDim2.fromOffset(TILE_SIZE, TILE_SIZE),
			BackgroundColor3 = props.BlockType.Color,

			create("UICorner")({ CornerRadius = UDim.new(0, TILE_RADIUS) }),
			create("UIStroke")({
				Color = function()
					return if props.IsSelected() then SELECTED_COLOR else IDLE_STROKE_COLOR
				end,
				Thickness = function()
					return if props.IsSelected() then 3 else 1
				end,
			}),

			create("TextLabel")({
				Name = "Hotkey",
				Visible = function()
					return props.Hotkey ~= nil and props.ShowHotkey()
				end,
				Position = UDim2.fromOffset(2, 2),
				Size = UDim2.fromOffset(HINT_SIZE, HINT_SIZE),
				BackgroundColor3 = HINT_COLOR,
				BackgroundTransparency = 0.45,
				Font = Enum.Font.GothamBold,
				TextSize = HINT_TEXT_SIZE,
				TextColor3 = TEXT_COLOR,
				Text = props.Hotkey or "",

				create("UICorner")({ CornerRadius = UDim.new(0, 4) }),
			}),
		}),

		create("TextLabel")({
			Name = "BlockName",
			Visible = function()
				return props.Layout() == "Column"
			end,
			Position = UDim2.fromOffset(TILE_SIZE + TILE_GAP, 0),
			Size = UDim2.fromOffset(NAME_WIDTH, TILE_SIZE),
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
	-- Key labels by block index, shown on the tiles while the player uses a keyboard.
	Hotkeys: { string }?,
}

local function blockPicker(props: BlockPickerProps): Frame
	local layout = derive(function(): Layout
		if Responsive.inputKind() == "Touch" or Responsive.sizeClass() == "Compact" then
			return "Bar"
		end
		return "Column"
	end)
	local isColumn = derive(function()
		return layout() == "Column"
	end)
	local showHotkeys = derive(function()
		return Responsive.inputKind() == "KeyboardMouse"
	end)

	local tiles = {}
	for index, blockType in BlockTypes.List do
		tiles[index] = tile({
			BlockType = blockType,
			LayoutOrder = index,
			Hotkey = if props.Hotkeys then props.Hotkeys[index] else nil,
			Layout = layout,
			ShowHotkey = showHotkeys,
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
			return if isColumn() then Vector2.new(0, 0.5) else Vector2.new(0.5, 0)
		end,
		Position = function()
			return if isColumn()
				then UDim2.new(0, SCREEN_MARGIN, 0.5, 0)
				else UDim2.new(0.5, 0, 0, SCREEN_MARGIN)
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
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, TILE_GAP),
		}),

		create("TextLabel")({
			Name = "Title",
			-- Above the tiles in a column, below them in a bar.
			LayoutOrder = function()
				return if isColumn() then 1 else 3
			end,
			Size = function()
				return if isColumn()
					then UDim2.fromOffset(COLUMN_WIDTH, COLUMN_TITLE_HEIGHT)
					else UDim2.fromOffset(BAR_WIDTH, BAR_TITLE_HEIGHT)
			end,
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextScaled = true,
			TextColor3 = TEXT_COLOR,
			TextXAlignment = function()
				return if isColumn() then Enum.TextXAlignment.Left else Enum.TextXAlignment.Center
			end,
			Text = function()
				return BlockTypes.ByName[props.Selected()].DisplayName
			end,

			create("UITextSizeConstraint")({ MaxTextSize = TITLE_MAX_TEXT_SIZE }),
		}),

		create("Frame")({
			Name = "Tiles",
			LayoutOrder = 2,
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,

			create("UIListLayout")({
				FillDirection = function()
					return if isColumn()
						then Enum.FillDirection.Vertical
						else Enum.FillDirection.Horizontal
				end,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, TILE_GAP),
			}),

			tiles,
		}),
	})
end

return blockPicker
