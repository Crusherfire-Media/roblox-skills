--[[
	A row of block type slots with the selected block's name above it. Pressing a slot calls
	OnSelect; the highlight follows Selected, so it stays right however the selection changes.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
local Vide = require(ReplicatedStorage.Packages.Vide)

local create = Vide.create
local derive = Vide.derive
local read = Vide.read

type BlockType = BlockTypes.BlockType

export type HotbarProps = {
	BlockTypes: { BlockType },
	Selected: () -> string,
	OnSelect: (name: string) -> (),
	IsCompact: (boolean | () -> boolean)?,
	ShowKeyHints: (boolean | () -> boolean)?,
}

type Metrics = {
	SlotSize: number,
	Gap: number,
	BarPadding: number,
	NameTextSize: number,
}

local REGULAR: Metrics = table.freeze({
	SlotSize = 64,
	Gap = 8,
	BarPadding = 8,
	NameTextSize = 20,
})
-- Narrow enough to fit between the thumbstick region and the jump button on a 667 wide phone.
local COMPACT: Metrics = table.freeze({
	SlotSize = 52,
	Gap = 6,
	BarPadding = 6,
	NameTextSize = 18,
})

local BAR_RADIUS = 12
local SLOT_RADIUS = 10
local SWATCH_INSET = 6
local SELECTED_STROKE = 3
local NAME_GAP = 4
local KEY_HINT_TEXT_SIZE = 14

local BAR_COLOR = Color3.fromRGB(20, 20, 24)
local BAR_TRANSPARENCY = 0.35
local SLOT_COLOR = Color3.fromRGB(45, 45, 52)
local SELECTED_SLOT_COLOR = Color3.fromRGB(90, 90, 100)
local HIGHLIGHT_COLOR = Color3.fromRGB(255, 255, 255)
local TEXT_COLOR = Color3.fromRGB(255, 255, 255)
local TEXT_OUTLINE_COLOR = Color3.fromRGB(0, 0, 0)
local FONT = Enum.Font.BuilderSansBold

local Hotbar = {}

local function metricsFor(isCompact: boolean): Metrics
	return if isCompact then COMPACT else REGULAR
end

local function barWidth(metrics: Metrics, slotCount: number): number
	return slotCount * metrics.SlotSize + (slotCount - 1) * metrics.Gap + 2 * metrics.BarPadding
end

--[[
	The hotbar's full size in UI units, for placing it without reading AbsoluteSize back.
]]
function Hotbar.size(isCompact: boolean, slotCount: number): Vector2
	local metrics = metricsFor(isCompact)
	local barHeight = metrics.SlotSize + 2 * metrics.BarPadding
	return Vector2.new(barWidth(metrics, slotCount), metrics.NameTextSize + NAME_GAP + barHeight)
end

local function slot(
	blockType: BlockType,
	index: number,
	metrics: () -> Metrics,
	props: HotbarProps
): TextButton
	local function isSelected(): boolean
		return props.Selected() == blockType.Name
	end

	return create("TextButton")({
		Name = blockType.Name,
		LayoutOrder = index,
		Text = "",
		Size = function()
			local size = metrics().SlotSize
			return UDim2.fromOffset(size, size)
		end,
		BackgroundColor3 = function()
			return if isSelected() then SELECTED_SLOT_COLOR else SLOT_COLOR
		end,

		Activated = function()
			props.OnSelect(blockType.Name)
		end,

		create("UICorner")({ CornerRadius = UDim.new(0, SLOT_RADIUS) }),
		create("UIStroke")({
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = HIGHLIGHT_COLOR,
			Thickness = SELECTED_STROKE,
			Enabled = isSelected,
		}),

		create("Frame")({
			Name = "Swatch",
			Position = UDim2.fromOffset(SWATCH_INSET, SWATCH_INSET),
			Size = UDim2.new(1, -2 * SWATCH_INSET, 1, -2 * SWATCH_INSET),
			BackgroundColor3 = blockType.Color,
			BackgroundTransparency = blockType.Transparency,

			create("UICorner")({ CornerRadius = UDim.new(0, SLOT_RADIUS - SWATCH_INSET) }),
		}),

		create("TextLabel")({
			Name = "KeyHint",
			Position = UDim2.fromOffset(SWATCH_INSET, SWATCH_INSET),
			Size = UDim2.fromOffset(KEY_HINT_TEXT_SIZE, KEY_HINT_TEXT_SIZE),
			BackgroundTransparency = 1,
			Text = tostring(index),
			TextSize = KEY_HINT_TEXT_SIZE,
			Font = FONT,
			TextColor3 = TEXT_COLOR,
			TextStrokeColor3 = TEXT_OUTLINE_COLOR,
			TextStrokeTransparency = 0.3,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			Visible = function()
				return read(props.ShowKeyHints) == true
			end,
		}),
	})
end

function Hotbar.new(props: HotbarProps): Frame
	-- Derived so bindings rerun when the variant flips, not on every pixel of a resize.
	local metrics = derive(function(): Metrics
		return metricsFor(read(props.IsCompact) == true)
	end)

	local selectedDisplayName = derive(function(): string
		local name = props.Selected()
		for _, blockType in props.BlockTypes do
			if blockType.Name == name then
				return blockType.DisplayName
			end
		end
		return name
	end)

	local slots = {}
	for index, blockType in props.BlockTypes do
		table.insert(slots, slot(blockType, index, metrics, props))
	end

	return create("Frame")({
		Name = "Hotbar",
		BackgroundTransparency = 1,
		Size = function()
			local size = Hotbar.size(read(props.IsCompact) == true, #props.BlockTypes)
			return UDim2.fromOffset(size.X, size.Y)
		end,

		create("UIListLayout")({
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, NAME_GAP),
		}),

		create("TextLabel")({
			Name = "SelectedName",
			LayoutOrder = 1,
			Size = function()
				return UDim2.new(1, 0, 0, metrics().NameTextSize)
			end,
			BackgroundTransparency = 1,
			Text = selectedDisplayName,
			TextSize = function()
				return metrics().NameTextSize
			end,
			Font = FONT,
			TextColor3 = TEXT_COLOR,
			TextStrokeColor3 = TEXT_OUTLINE_COLOR,
			TextStrokeTransparency = 0.3,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}),

		create("Frame")({
			Name = "Bar",
			LayoutOrder = 2,
			Size = function()
				local current = metrics()
				return UDim2.new(1, 0, 0, current.SlotSize + 2 * current.BarPadding)
			end,
			BackgroundColor3 = BAR_COLOR,
			BackgroundTransparency = BAR_TRANSPARENCY,

			create("UICorner")({ CornerRadius = UDim.new(0, BAR_RADIUS) }),
			create("UIPadding")({
				PaddingLeft = function()
					return UDim.new(0, metrics().BarPadding)
				end,
				PaddingRight = function()
					return UDim.new(0, metrics().BarPadding)
				end,
				PaddingTop = function()
					return UDim.new(0, metrics().BarPadding)
				end,
				PaddingBottom = function()
					return UDim.new(0, metrics().BarPadding)
				end,
			}),
			create("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = function()
					return UDim.new(0, metrics().Gap)
				end,
			}),

			slots,
		}),
	})
end

return Hotbar
