--!strict
--@author: Crusherfire
--@date: 11/13/2026
--[[@description:
	A row of block slots: each shows the block's color and name, the selected
	slot is outlined, and clicking or tapping a slot asks to select it.
]]

const Vide = require("@game/ReplicatedStorage/Packages/Vide")

const create = Vide.create

const BlockTypes = require("@game/ReplicatedStorage/Shared/BlockTypes")

export type HotbarProps = {
	BlockTypes: { BlockTypes.BlockType },
	SelectedName: () -> string,
	ShowKeyHints: boolean | () -> boolean,
	Select: (name: string) -> (),
	AnchorPoint: Vector2?,
	Position: UDim2?,
}

-- 64 keeps every slot well over the 44 a thumb needs.
const SLOT_SIZE = 64
const SLOT_GAP = 8
const SLOT_RADIUS = 10
const SWATCH_INSET = 6
const SWATCH_RADIUS = SLOT_RADIUS - SWATCH_INSET
const SWATCH_HEIGHT = 34
const NAME_TOP = SWATCH_INSET + SWATCH_HEIGHT + 2
const NAME_HEIGHT = 18
const NAME_TEXT_SIZE = 14
const KEY_HINT_SIZE = 14
const KEY_HINT_TEXT_SIZE = 13
-- Outer padding is wider than the stroke, so the outline is never cut off.
const BAR_PADDING = 8
const BAR_RADIUS = SLOT_RADIUS + BAR_PADDING
const SELECTED_STROKE = 3

const BAR_COLOR = Color3.fromRGB(0, 0, 0)
const BAR_TRANSPARENCY = 0.4
const SLOT_COLOR = Color3.fromRGB(35, 35, 40)
const SELECTED_SLOT_COLOR = Color3.fromRGB(75, 75, 85)
const TEXT_COLOR = Color3.fromRGB(255, 255, 255)
const FONT = Enum.Font.BuilderSansBold

local function slot(props: {
	BlockType: BlockTypes.BlockType,
	KeyNumber: number,
	IsSelected: () -> boolean,
	ShowKeyHints: boolean | () -> boolean,
	Select: (name: string) -> (),
}): TextButton
	const blockType = props.BlockType

	return create("TextButton")({
		Name = blockType.Name,
		LayoutOrder = props.KeyNumber,
		Size = UDim2.fromOffset(SLOT_SIZE, SLOT_SIZE),
		BackgroundColor3 = function()
			return if props.IsSelected() then SELECTED_SLOT_COLOR else SLOT_COLOR
		end,
		Text = "",
		Activated = function()
			props.Select(blockType.Name)
		end,

		create("UICorner")({ CornerRadius = UDim.new(0, SLOT_RADIUS) }),
		create("UIStroke")({
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = TEXT_COLOR,
			Thickness = SELECTED_STROKE,
			Transparency = function()
				return if props.IsSelected() then 0 else 1
			end,
		}),

		create("Frame")({
			Name = "Swatch",
			Position = UDim2.fromOffset(SWATCH_INSET, SWATCH_INSET),
			Size = UDim2.new(1, -2 * SWATCH_INSET, 0, SWATCH_HEIGHT),
			BackgroundColor3 = blockType.Color,
			BackgroundTransparency = blockType.Transparency,

			create("UICorner")({ CornerRadius = UDim.new(0, SWATCH_RADIUS) }),

			create("TextLabel")({
				Name = "KeyHint",
				Position = UDim2.fromOffset(2, 1),
				Size = UDim2.fromOffset(KEY_HINT_SIZE, KEY_HINT_SIZE),
				BackgroundTransparency = 1,
				Font = FONT,
				Text = tostring(props.KeyNumber),
				TextColor3 = TEXT_COLOR,
				TextSize = KEY_HINT_TEXT_SIZE,
				TextStrokeTransparency = 0.3,
				Visible = props.ShowKeyHints,
			}),
		}),

		create("TextLabel")({
			Name = "BlockName",
			Position = UDim2.fromOffset(0, NAME_TOP),
			Size = UDim2.new(1, 0, 0, NAME_HEIGHT),
			BackgroundTransparency = 1,
			Font = FONT,
			Text = blockType.DisplayName,
			TextColor3 = TEXT_COLOR,
			TextSize = NAME_TEXT_SIZE,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}),
	})
end

local function hotbar(props: HotbarProps): Frame
	const slots = {}
	for index, blockType in props.BlockTypes do
		table.insert(
			slots,
			slot({
				BlockType = blockType,
				KeyNumber = index,
				IsSelected = function()
					return props.SelectedName() == blockType.Name
				end,
				ShowKeyHints = props.ShowKeyHints,
				Select = props.Select,
			})
		)
	end

	return create("Frame")({
		Name = "Hotbar",
		AnchorPoint = props.AnchorPoint,
		Position = props.Position,
		Size = UDim2.new(),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = BAR_COLOR,
		BackgroundTransparency = BAR_TRANSPARENCY,

		create("UICorner")({ CornerRadius = UDim.new(0, BAR_RADIUS) }),
		create("UIPadding")({
			PaddingLeft = UDim.new(0, BAR_PADDING),
			PaddingRight = UDim.new(0, BAR_PADDING),
			PaddingTop = UDim.new(0, BAR_PADDING),
			PaddingBottom = UDim.new(0, BAR_PADDING),
		}),
		create("UIListLayout")({
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, SLOT_GAP),
		}),

		slots,
	})
end

return hotbar
