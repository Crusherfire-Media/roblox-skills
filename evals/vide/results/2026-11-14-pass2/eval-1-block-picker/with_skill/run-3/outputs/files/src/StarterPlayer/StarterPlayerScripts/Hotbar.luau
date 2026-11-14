--!strict
--[[
	A row of block type slots that shows which one is selected and selects a
	block type when a slot is clicked or tapped.
]]

const Vide = require("@game/ReplicatedStorage/Packages/Vide")

const changed = Vide.changed
const create = Vide.create
const derive = Vide.derive
const read = Vide.read
const source = Vide.source

const SLOT_COLOR = Color3.fromRGB(28, 30, 36)
const SLOT_HOVER_COLOR = Color3.fromRGB(48, 52, 62)
const SLOT_PRESS_COLOR = Color3.fromRGB(20, 21, 26)
const SLOT_SELECTED_COLOR = Color3.fromRGB(70, 76, 92)
const SLOT_TRANSPARENCY = 0.15
const BAR_COLOR = Color3.fromRGB(0, 0, 0)
const BAR_TRANSPARENCY = 0.45
const TEXT_COLOR = Color3.fromRGB(255, 255, 255)
const KEY_TEXT_COLOR = Color3.fromRGB(190, 195, 205)
const STROKE_COLOR = Color3.fromRGB(90, 95, 110)
const SELECTED_STROKE_COLOR = Color3.fromRGB(255, 255, 255)
const STROKE_THICKNESS = 1
const SELECTED_STROKE_THICKNESS = 3
const SWATCH_STROKE_COLOR = Color3.fromRGB(0, 0, 0)
const SWATCH_STROKE_TRANSPARENCY = 0.5
const SWATCH_CORNER_RADIUS = 4
-- Glass at its real transparency vanishes against the dark slot.
const MAXIMUM_SWATCH_TRANSPARENCY = 0.3
const LABEL_INSET = 4

type Metrics = {
	SlotSize: number,
	SwatchSize: number,
	SwatchTop: number,
	CornerRadius: number,
	NameTextSize: number,
	NameBottom: number,
	KeyTextSize: number,
	Gap: number,
	Padding: number,
}

const REGULAR: Metrics = table.freeze({
	SlotSize = 80,
	SwatchSize = 40,
	SwatchTop = 10,
	CornerRadius = 10,
	NameTextSize = 16,
	NameBottom = 6,
	KeyTextSize = 14,
	Gap = 8,
	Padding = 8,
})

const COMPACT: Metrics = table.freeze({
	SlotSize = 64,
	SwatchSize = 32,
	SwatchTop = 8,
	CornerRadius = 8,
	NameTextSize = 14,
	NameBottom = 4,
	KeyTextSize = 12,
	Gap = 6,
	Padding = 6,
})

const BlockTypes = require("@game/ReplicatedStorage/Shared/BlockTypes")

type BlockType = BlockTypes.BlockType

export type HotbarProps = {
	BlockTypes: { BlockType },
	Selected: () -> string,
	Select: (name: string) -> (),
	IsCompact: (boolean | () -> boolean)?,
	ShowKeyHints: (boolean | () -> boolean)?,
	AnchorPoint: (Vector2 | () -> Vector2)?,
	Position: (UDim2 | () -> UDim2)?,
}

type SlotProps = {
	BlockType: BlockType,
	Index: number,
	IsSelected: () -> boolean,
	Select: () -> (),
	Metrics: () -> Metrics,
	ShowKeyHints: (boolean | () -> boolean)?,
}

local function slot(props: SlotProps): TextButton
	const metrics = props.Metrics
	const guiState = source(Enum.GuiState.Idle)

	return create("TextButton")({
		Name = props.BlockType.Name,
		LayoutOrder = props.Index,
		Text = "",
		BackgroundTransparency = SLOT_TRANSPARENCY,
		BackgroundColor3 = function()
			const state = guiState()
			if state == Enum.GuiState.Press then
				return SLOT_PRESS_COLOR
			elseif props.IsSelected() then
				return SLOT_SELECTED_COLOR
			elseif state == Enum.GuiState.Hover then
				return SLOT_HOVER_COLOR
			end
			return SLOT_COLOR
		end,
		Size = function()
			const size = metrics().SlotSize
			return UDim2.fromOffset(size, size)
		end,
		Activated = props.Select,

		changed("GuiState", guiState),

		create("UICorner")({
			CornerRadius = function()
				return UDim.new(0, metrics().CornerRadius)
			end,
		}),

		create("UIStroke")({
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = function()
				return if props.IsSelected() then SELECTED_STROKE_COLOR else STROKE_COLOR
			end,
			Thickness = function()
				return if props.IsSelected() then SELECTED_STROKE_THICKNESS else STROKE_THICKNESS
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
			BackgroundColor3 = props.BlockType.Color,
			BackgroundTransparency = math.min(
				props.BlockType.Transparency,
				MAXIMUM_SWATCH_TRANSPARENCY
			),

			create("UICorner")({ CornerRadius = UDim.new(0, SWATCH_CORNER_RADIUS) }),
			create("UIStroke")({
				Color = SWATCH_STROKE_COLOR,
				Transparency = SWATCH_STROKE_TRANSPARENCY,
			}),
		}),

		create("TextLabel")({
			Name = "BlockName",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = function()
				return UDim2.new(0.5, 0, 1, -metrics().NameBottom)
			end,
			Size = function()
				return UDim2.new(1, -LABEL_INSET * 2, 0, metrics().NameTextSize)
			end,
			BackgroundTransparency = 1,
			Text = props.BlockType.DisplayName,
			TextColor3 = TEXT_COLOR,
			TextSize = function()
				return metrics().NameTextSize
			end,
			Font = Enum.Font.BuilderSansBold,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}),

		create("TextLabel")({
			Name = "KeyHint",
			Position = UDim2.fromOffset(LABEL_INSET, LABEL_INSET / 2),
			Size = function()
				const size = metrics().KeyTextSize
				return UDim2.fromOffset(size, size)
			end,
			BackgroundTransparency = 1,
			Visible = props.ShowKeyHints,
			Text = tostring(props.Index),
			TextColor3 = KEY_TEXT_COLOR,
			TextSize = function()
				return metrics().KeyTextSize
			end,
			Font = Enum.Font.BuilderSansBold,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
	})
end

local function hotbar(props: HotbarProps): Frame
	-- Derived, so bindings rerun when the variant flips and not on every
	-- pixel of a window resize.
	const metrics = derive(function(): Metrics
		return if read(props.IsCompact) then COMPACT else REGULAR
	end)

	local function padding(): UDim
		return UDim.new(0, metrics().Padding)
	end

	const slots = {}
	for index, blockType in props.BlockTypes do
		table.insert(
			slots,
			slot({
				BlockType = blockType,
				Index = index,
				IsSelected = function()
					return props.Selected() == blockType.Name
				end,
				Select = function()
					props.Select(blockType.Name)
				end,
				Metrics = metrics,
				ShowKeyHints = props.ShowKeyHints,
			})
		)
	end

	return create("Frame")({
		Name = "Hotbar",
		AnchorPoint = props.AnchorPoint,
		Position = props.Position,
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = BAR_COLOR,
		BackgroundTransparency = BAR_TRANSPARENCY,

		create("UICorner")({
			CornerRadius = function()
				const current = metrics()
				return UDim.new(0, current.CornerRadius + current.Padding)
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
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = function()
				return UDim.new(0, metrics().Gap)
			end,
		}),

		slots,
	})
end

return hotbar
