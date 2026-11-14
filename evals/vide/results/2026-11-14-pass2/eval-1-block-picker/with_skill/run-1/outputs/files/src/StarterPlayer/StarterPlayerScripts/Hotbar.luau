--!strict
--[[
	A row of block slots for the bottom of the screen. The selected slot is
	highlighted, and a click or tap on a slot calls Select with its name.
]]

const Vide = require("@game/ReplicatedStorage/Packages/Vide")

const create = Vide.create
const read = Vide.read

const SLOT_SIZE = 64
const SLOT_GAP = 8
const SLOT_RADIUS = 8
const BOTTOM_MARGIN = 16
const SWATCH_SIZE = 28
const SWATCH_TOP = 8
const SWATCH_RADIUS = 4
const LABEL_HEIGHT = 18
const LABEL_BOTTOM = 6
const LABEL_TEXT_SIZE = 14
const KEY_HINT_SIZE = Vector2.new(12, 14)
const KEY_HINT_POSITION = UDim2.fromOffset(5, 3)
const KEY_HINT_TEXT_SIZE = 13
const SELECTED_STROKE = 3

const FONT = Enum.Font.BuilderSansBold
const TEXT_COLOR = Color3.fromRGB(255, 255, 255)
const SLOT_COLOR = Color3.fromRGB(30, 30, 36)
const SELECTED_SLOT_COLOR = Color3.fromRGB(70, 70, 82)
const SLOT_TRANSPARENCY = 0.35
const SELECTED_SLOT_TRANSPARENCY = 0.1
const SWATCH_OUTLINE_COLOR = Color3.fromRGB(0, 0, 0)
const SWATCH_OUTLINE_TRANSPARENCY = 0.5
const KEY_HINT_TRANSPARENCY = 0.3

const BlockTypes = require("@game/ReplicatedStorage/Shared/BlockTypes")

type BlockType = BlockTypes.BlockType

export type HotbarProps = {
	BlockTypes: { BlockType },
	Selected: string | () -> string,
	-- Number key hints, for players with a keyboard.
	ShowKeyHints: boolean | () -> boolean,
	Select: (name: string) -> (),
}

type SlotProps = {
	BlockType: BlockType,
	KeyNumber: number,
	IsSelected: () -> boolean,
	ShowKeyHints: boolean | () -> boolean,
	Select: (name: string) -> (),
}

local function slot(props: SlotProps): TextButton
	const data = props.BlockType

	return create("TextButton")({
		Name = data.Name,
		LayoutOrder = props.KeyNumber,
		Size = UDim2.fromOffset(SLOT_SIZE, SLOT_SIZE),
		Text = "",
		BackgroundColor3 = function()
			return if props.IsSelected() then SELECTED_SLOT_COLOR else SLOT_COLOR
		end,
		BackgroundTransparency = function()
			return if props.IsSelected() then SELECTED_SLOT_TRANSPARENCY else SLOT_TRANSPARENCY
		end,
		Activated = function()
			props.Select(data.Name)
		end,

		create("UICorner")({ CornerRadius = UDim.new(0, SLOT_RADIUS) }),
		create("UIStroke")({
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = TEXT_COLOR,
			Thickness = SELECTED_STROKE,
			Enabled = props.IsSelected,
		}),

		create("Frame")({
			Name = "Swatch",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, SWATCH_TOP),
			Size = UDim2.fromOffset(SWATCH_SIZE, SWATCH_SIZE),
			BackgroundColor3 = data.Color,
			BackgroundTransparency = data.Transparency,

			create("UICorner")({ CornerRadius = UDim.new(0, SWATCH_RADIUS) }),
			create("UIStroke")({
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = SWATCH_OUTLINE_COLOR,
				Transparency = SWATCH_OUTLINE_TRANSPARENCY,
			}),
		}),

		create("TextLabel")({
			Name = "Label",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -LABEL_BOTTOM),
			Size = UDim2.new(1, -SLOT_GAP, 0, LABEL_HEIGHT),
			BackgroundTransparency = 1,
			Font = FONT,
			Text = data.DisplayName,
			TextColor3 = TEXT_COLOR,
			TextSize = LABEL_TEXT_SIZE,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}),

		create("TextLabel")({
			Name = "KeyHint",
			Position = KEY_HINT_POSITION,
			Size = UDim2.fromOffset(KEY_HINT_SIZE.X, KEY_HINT_SIZE.Y),
			BackgroundTransparency = 1,
			Font = FONT,
			Text = tostring(props.KeyNumber),
			TextColor3 = TEXT_COLOR,
			TextSize = KEY_HINT_TEXT_SIZE,
			TextTransparency = KEY_HINT_TRANSPARENCY,
			TextXAlignment = Enum.TextXAlignment.Left,
			Visible = props.ShowKeyHints,
		}),
	})
end

local function hotbar(props: HotbarProps): Frame
	const slots = {}
	for index, data in props.BlockTypes do
		table.insert(
			slots,
			slot({
				BlockType = data,
				KeyNumber = index,
				IsSelected = function()
					return read(props.Selected) == data.Name
				end,
				ShowKeyHints = props.ShowKeyHints,
				Select = props.Select,
			})
		)
	end

	return create("Frame")({
		Name = "Hotbar",
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

return hotbar
