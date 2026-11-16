--!strict
--@author: Crusherfire
--@date: 2026-11-13
--[[@description:
	A row of block slots: each shows its block's color and name, the selected
	one is outlined, and clicking or tapping a slot selects it. The caller
	owns the selection and passes it in, so the row stays a plain view.
]]

const Vide = require("@game/ReplicatedStorage/Packages/Vide")

const create = Vide.create
const derive = Vide.derive
const read = Vide.read

const BlockTypes = require("@game/ReplicatedStorage/Shared/BlockTypes")

type BlockType = BlockTypes.BlockType

export type HotbarProps = {
	BlockTypes: { BlockType },
	SelectedName: () -> string,
	Select: (name: string) -> (),
	-- The touch-sized variant, for phones and small windows.
	IsCompact: (boolean | () -> boolean)?,
	-- Number labels for the keys 1 to 5, for players on keyboard and mouse.
	ShowsKeyHints: (boolean | () -> boolean)?,
	AnchorPoint: (Vector2 | () -> Vector2)?,
	Position: (UDim2 | () -> UDim2)?,
}

type Metrics = {
	SlotSize: number,
	Gap: number,
	CornerRadius: number,
	SwatchSize: number,
	SwatchTop: number,
	NameTop: number,
	NameHeight: number,
	NameTextSize: number,
}

type SlotProps = {
	BlockType: BlockType,
	Index: number,
	IsSelected: () -> boolean,
	Metrics: () -> Metrics,
	ShowsKeyHints: (boolean | () -> boolean)?,
	Select: (name: string) -> (),
}

-- Slots stay above 44 so a thumb can hit them. Each column sums to SlotSize:
-- SwatchTop + SwatchSize + gap + NameHeight + bottom margin.
const REGULAR: Metrics = table.freeze({
	SlotSize = 72,
	Gap = 8,
	CornerRadius = 10,
	SwatchSize = 40,
	SwatchTop = 8,
	NameTop = 50,
	NameHeight = 18,
	NameTextSize = 16,
})
const COMPACT: Metrics = table.freeze({
	SlotSize = 56,
	Gap = 6,
	CornerRadius = 8,
	SwatchSize = 30,
	SwatchTop = 6,
	NameTop = 37,
	NameHeight = 16,
	NameTextSize = 14,
})

const BAR_COLOR = Color3.fromRGB(20, 20, 24)
const BAR_TRANSPARENCY = 0.35
const SLOT_COLOR = Color3.fromRGB(40, 40, 46)
const SELECTED_SLOT_COLOR = Color3.fromRGB(78, 78, 88)
const SELECTED_STROKE_COLOR = Color3.fromRGB(255, 255, 255)
-- Below Gap, so the outline never reaches a neighbor or the bar's edge.
const SELECTED_STROKE_THICKNESS = 3
const SWATCH_CORNER_RADIUS = 6
const SWATCH_EDGE_COLOR = Color3.fromRGB(0, 0, 0)
const SWATCH_EDGE_TRANSPARENCY = 0.6
-- A see-through block drawn at full transparency vanishes into the dark slot.
const SWATCH_TRANSPARENCY_FACTOR = 0.5
const NAME_COLOR = Color3.fromRGB(255, 255, 255)
const KEY_HINT_COLOR = Color3.fromRGB(190, 190, 200)
const KEY_HINT_TEXT_SIZE = 12
-- Stays left of the smallest swatch's edge in both variants.
const KEY_HINT_POSITION = UDim2.fromOffset(3, 2)
const KEY_HINT_SIZE = UDim2.fromOffset(9, 14)
const FONT = Enum.Font.BuilderSansBold

local function slot(props: SlotProps): TextButton
	const blockType = props.BlockType
	const metrics = props.Metrics

	return create("TextButton")({
		Name = blockType.Name,
		LayoutOrder = props.Index,
		Size = function()
			const size = metrics().SlotSize
			return UDim2.fromOffset(size, size)
		end,
		BackgroundColor3 = function()
			return if props.IsSelected() then SELECTED_SLOT_COLOR else SLOT_COLOR
		end,

		Activated = function()
			props.Select(blockType.Name)
		end,

		create("UICorner")({
			CornerRadius = function()
				return UDim.new(0, metrics().CornerRadius)
			end,
		}),

		-- Border mode, since a stroke on a TextButton outlines its text by default.
		create("UIStroke")({
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = SELECTED_STROKE_COLOR,
			Thickness = SELECTED_STROKE_THICKNESS,
			Transparency = function()
				return if props.IsSelected() then 0 else 1
			end,
		}),

		create("Frame")({
			Name = "Swatch",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = function()
				return UDim2.new(0.5, 0, 0, metrics().SwatchTop)
			end,
			Size = function()
				const size = metrics().SwatchSize
				return UDim2.fromOffset(size, size)
			end,
			BackgroundColor3 = blockType.Color,
			BackgroundTransparency = blockType.Transparency * SWATCH_TRANSPARENCY_FACTOR,

			create("UICorner")({ CornerRadius = UDim.new(0, SWATCH_CORNER_RADIUS) }),
			create("UIStroke")({
				Color = SWATCH_EDGE_COLOR,
				Transparency = SWATCH_EDGE_TRANSPARENCY,
			}),
		}),

		create("TextLabel")({
			Name = "BlockName",
			BackgroundTransparency = 1,
			Position = function()
				return UDim2.fromOffset(2, metrics().NameTop)
			end,
			Size = function()
				return UDim2.new(1, -4, 0, metrics().NameHeight)
			end,
			Font = FONT,
			Text = blockType.DisplayName,
			TextColor3 = NAME_COLOR,
			TextSize = function()
				return metrics().NameTextSize
			end,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}),

		create("TextLabel")({
			Name = "KeyHint",
			BackgroundTransparency = 1,
			Position = KEY_HINT_POSITION,
			Size = KEY_HINT_SIZE,
			Font = FONT,
			Text = tostring(props.Index),
			TextColor3 = KEY_HINT_COLOR,
			TextSize = KEY_HINT_TEXT_SIZE,
			TextXAlignment = Enum.TextXAlignment.Left,
			Visible = props.ShowsKeyHints or false,
		}),
	})
end

local function hotbar(props: HotbarProps): Frame
	const metrics = derive(function(): Metrics
		return if read(props.IsCompact) then COMPACT else REGULAR
	end)

	const slots = {}
	for index, blockType in props.BlockTypes do
		const isSelected = derive(function()
			return props.SelectedName() == blockType.Name
		end)
		table.insert(
			slots,
			slot({
				BlockType = blockType,
				Index = index,
				IsSelected = isSelected,
				Metrics = metrics,
				ShowsKeyHints = props.ShowsKeyHints,
				Select = props.Select,
			})
		)
	end

	local function padding(): UDim
		return UDim.new(0, metrics().Gap)
	end

	return create("Frame")({
		Name = "Hotbar",
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		Position = props.Position or UDim2.new(),
		-- A Frame starts at 100 by 100, and AutomaticSize only grows.
		Size = UDim2.new(),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = BAR_COLOR,
		BackgroundTransparency = BAR_TRANSPARENCY,
		-- Sinks presses in the gaps between slots, so they never place a block.
		Active = true,

		create("UICorner")({
			CornerRadius = function()
				return UDim.new(0, metrics().CornerRadius + metrics().Gap)
			end,
		}),
		create("UIPadding")({
			PaddingTop = padding,
			PaddingBottom = padding,
			PaddingLeft = padding,
			PaddingRight = padding,
		}),
		create("UIListLayout")({
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = padding,
		}),

		slots,
	})
end

return hotbar
