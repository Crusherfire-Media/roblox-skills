--!strict
--[[
	A row of block slots, one per block type, with the selected one
	highlighted. Pressing a slot calls Select with that block type's name.
]]

local Vide = require("@game/ReplicatedStorage/Packages/Vide")

local create = Vide.create
local source = Vide.source

-- 64 keeps every slot well over the 44 a thumb needs.
local SLOT_SIZE = 64
-- Wider than both selected strokes together, so neighbors never touch.
local SLOT_GAP = 8
local SLOT_CORNER = UDim.new(0, 10)
local SLOT_TRANSPARENCY = 0.25
local BOTTOM_MARGIN = 16

local SWATCH_SIZE = 32
local SWATCH_TOP = 6
local SWATCH_CORNER = UDim.new(0, 6)

local LABEL_HEIGHT = 16
local LABEL_BOTTOM = 5
local LABEL_TEXT_SIZE = 13
local KEY_HINT_TEXT_SIZE = 12
local KEY_HINT_POSITION = UDim2.fromOffset(5, 3)
local KEY_HINT_SIZE = UDim2.fromOffset(10, 14)

local SELECTED_STROKE_THICKNESS = 3
local IDLE_STROKE_THICKNESS = 1

local IDLE_COLOR = Color3.fromRGB(28, 30, 36)
local HOVER_COLOR = Color3.fromRGB(48, 52, 62)
local SELECTED_COLOR = Color3.fromRGB(70, 76, 92)
local IDLE_STROKE_COLOR = Color3.fromRGB(90, 96, 110)
local SELECTED_STROKE_COLOR = Color3.fromRGB(255, 255, 255)
local TEXT_COLOR = Color3.fromRGB(255, 255, 255)
local KEY_HINT_COLOR = Color3.fromRGB(190, 196, 210)
local FONT = Enum.Font.BuilderSansBold

local BlockTypes = require("@game/ReplicatedStorage/Shared/BlockTypes")

type BlockType = BlockTypes.BlockType

type SlotProps = {
	BlockType: BlockType,
	KeyHint: string,
	LayoutOrder: number,
	IsSelected: () -> boolean,
	ShowKeyHint: boolean | () -> boolean,
	Select: () -> (),
}

export type BlockHotbarProps = {
	BlockTypes: { BlockType },
	Selected: () -> string,
	Select: (name: string) -> (),
	-- Number key hints, which mean nothing to a player on touch.
	ShowKeyHints: boolean | () -> boolean,
}

local function slot(props: SlotProps): TextButton
	local blockType = props.BlockType
	local isHovered = source(false)

	return create("TextButton")({
		Name = blockType.Name,
		LayoutOrder = props.LayoutOrder,
		Size = UDim2.fromOffset(SLOT_SIZE, SLOT_SIZE),
		BackgroundColor3 = function()
			if props.IsSelected() then
				return SELECTED_COLOR
			end
			return if isHovered() then HOVER_COLOR else IDLE_COLOR
		end,
		BackgroundTransparency = SLOT_TRANSPARENCY,
		Activated = props.Select,
		MouseEnter = function()
			isHovered(true)
		end,
		MouseLeave = function()
			isHovered(false)
		end,

		create("UICorner")({ CornerRadius = SLOT_CORNER }),
		create("UIStroke")({
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = function()
				return if props.IsSelected() then SELECTED_STROKE_COLOR else IDLE_STROKE_COLOR
			end,
			Thickness = function()
				return if props.IsSelected()
					then SELECTED_STROKE_THICKNESS
					else IDLE_STROKE_THICKNESS
			end,
		}),

		create("Frame")({
			Name = "Swatch",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, SWATCH_TOP),
			Size = UDim2.fromOffset(SWATCH_SIZE, SWATCH_SIZE),
			BackgroundColor3 = blockType.Color,
			BackgroundTransparency = blockType.Transparency,

			create("UICorner")({ CornerRadius = SWATCH_CORNER }),
			-- Outlines see-through blocks such as Window, which would otherwise
			-- fade into the slot.
			create("UIStroke")({
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = blockType.Color,
				Thickness = IDLE_STROKE_THICKNESS,
			}),
		}),

		create("TextLabel")({
			Name = "Label",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -LABEL_BOTTOM),
			Size = UDim2.new(1, 0, 0, LABEL_HEIGHT),
			BackgroundTransparency = 1,
			Font = FONT,
			Text = blockType.DisplayName,
			TextColor3 = TEXT_COLOR,
			TextSize = LABEL_TEXT_SIZE,
		}),

		create("TextLabel")({
			Name = "KeyHint",
			Position = KEY_HINT_POSITION,
			Size = KEY_HINT_SIZE,
			BackgroundTransparency = 1,
			Font = FONT,
			Text = props.KeyHint,
			TextColor3 = KEY_HINT_COLOR,
			TextSize = KEY_HINT_TEXT_SIZE,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			Visible = props.ShowKeyHint,
		}),
	})
end

local function BlockHotbar(props: BlockHotbarProps): Frame
	local slots = {}
	for index, blockType in props.BlockTypes do
		slots[index] = slot({
			BlockType = blockType,
			KeyHint = tostring(index),
			LayoutOrder = index,
			IsSelected = function()
				return props.Selected() == blockType.Name
			end,
			ShowKeyHint = props.ShowKeyHints,
			Select = function()
				props.Select(blockType.Name)
			end,
		})
	end

	return create("Frame")({
		Name = "BlockHotbar",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -BOTTOM_MARGIN),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,

		create("UIListLayout")({
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, SLOT_GAP),
		}),
		slots,
	})
end

return BlockHotbar
