--[[
	The build menu: a panel with three tabs. Blocks shows a card per block type, Colors is a
	palette of tints for the next blocks plus a rainbow swatch whose hue keeps cycling, and Shapes
	lists the block shapes. The panel slides up from below the screen when it opens and back down
	when it closes.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
local Vide = require(ReplicatedStorage.Packages.Vide)

local cleanup = Vide.cleanup
local create = Vide.create
local source = Vide.source
local spring = Vide.spring
local switch = Vide.switch

type BlockType = BlockTypes.BlockType

export type Tab = "Blocks" | "Colors" | "Shapes"

local TABS: { Tab } = { "Blocks", "Colors", "Shapes" }
local PANEL_SIZE = Vector2.new(600, 440)
local PANEL_PADDING = 12
local TAB_HEIGHT = 40
local TAB_WIDTH = 120
local SWATCH_SIZE = 36
local SWATCH_GAP = 6
local PALETTE_COLUMNS = 12
local PALETTE_ROWS = 10
local SHAPE_NAMES = { "Cube", "Slab", "Stair", "Wedge", "Corner", "Pillar", "Arch", "Fence" }
local SHAPE_VARIANTS = 8
local SHAPE_CARD_SIZE = Vector2.new(132, 64)
local CARD_GAP = 8
-- How long the slide in or out takes, in seconds.
local SLIDE_SECONDS = 0.3
-- How many hue turns per second the rainbow swatch makes.
local RAINBOW_SPEED = 0.25
local PANEL_COLOR = Color3.fromRGB(28, 28, 34)
local CARD_COLOR = Color3.fromRGB(44, 44, 52)
local SELECTED_COLOR = Color3.fromRGB(255, 200, 60)
local IDLE_STROKE_COLOR = Color3.fromRGB(70, 70, 80)
local TEXT_COLOR = Color3.fromRGB(240, 240, 240)
local MUTED_TEXT_COLOR = Color3.fromRGB(180, 180, 190)

export type BuildMenuProps = {
	Tab: () -> Tab,
	SelectTab: (tab: Tab) -> (),
	Tint: () -> Color3,
	SelectTint: (tint: Color3) -> (),
	-- True while the menu is open; false makes it slide out.
	Present: () -> boolean,
}

local function strokeFor(isSelected: () -> boolean): UIStroke
	return create("UIStroke")({
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		BorderStrokePosition = Enum.BorderStrokePosition.Inner,
		Color = function()
			return if isSelected() then SELECTED_COLOR else IDLE_STROKE_COLOR
		end,
		Thickness = function()
			return if isSelected() then 3 else 1
		end,
	})
end

local function swatch(props: BuildMenuProps, color: Color3, layoutOrder: number): TextButton
	return create("TextButton")({
		Name = `Swatch{layoutOrder}`,
		LayoutOrder = layoutOrder,
		BackgroundColor3 = color,
		Text = "",

		Activated = function()
			props.SelectTint(color)
		end,

		create("UICorner")({ CornerRadius = UDim.new(0, 6) }),
		strokeFor(function()
			return props.Tint() == color
		end),
	})
end

local function rainbowSwatch(props: BuildMenuProps): TextButton
	local hue = source(0)
	cleanup(RunService.Heartbeat:Connect(function(deltaTime: number)
		hue((hue() + deltaTime * RAINBOW_SPEED) % 1)
	end))

	return create("TextButton")({
		Name = "Rainbow",
		LayoutOrder = 0,
		BackgroundColor3 = function()
			return Color3.fromHSV(hue(), 0.8, 1)
		end,
		Text = "",

		Activated = function()
			props.SelectTint(Color3.fromHSV(hue(), 0.8, 1))
		end,

		create("UICorner")({ CornerRadius = UDim.new(0, 6) }),
		create("UIStroke")({ Color = TEXT_COLOR, Thickness = 2 }),
	})
end

local function colorsPage(props: BuildMenuProps): ScrollingFrame
	local swatches = {}
	for row = 1, PALETTE_ROWS do
		for column = 1, PALETTE_COLUMNS do
			local index = (row - 1) * PALETTE_COLUMNS + column
			local color = Color3.fromHSV(
				(column - 1) / PALETTE_COLUMNS,
				0.25 + 0.75 * (row - 1) / PALETTE_ROWS,
				1
			)
			swatches[index] = swatch(props, color, index)
		end
	end

	return create("ScrollingFrame")({
		Name = "Colors",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),

		create("UIGridLayout")({
			CellSize = UDim2.fromOffset(SWATCH_SIZE, SWATCH_SIZE),
			CellPadding = UDim2.fromOffset(SWATCH_GAP, SWATCH_GAP),
		}),

		rainbowSwatch(props),
		swatches,
	})
end

local function blockCard(blockType: BlockType, layoutOrder: number): Frame
	return create("Frame")({
		Name = blockType.Name,
		LayoutOrder = layoutOrder,
		BackgroundColor3 = CARD_COLOR,

		create("UICorner")({ CornerRadius = UDim.new(0, 8) }),
		create("UIPadding")({
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
		}),
		create("Frame")({
			Name = "Swatch",
			Size = UDim2.new(1, 0, 1, -24),
			BackgroundColor3 = blockType.Color,
			BackgroundTransparency = blockType.Transparency,

			create("UICorner")({ CornerRadius = UDim.new(0, 6) }),
		}),
		create("TextLabel")({
			Name = "Label",
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.new(1, 0, 0, 20),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextSize = 16,
			TextColor3 = TEXT_COLOR,
			Text = blockType.DisplayName,
		}),
	})
end

local function blocksPage(): Frame
	local cards = {}
	for index, blockType in BlockTypes.List do
		cards[index] = blockCard(blockType, index)
	end

	return create("Frame")({
		Name = "Blocks",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,

		create("UIGridLayout")({
			CellSize = UDim2.fromOffset(108, 128),
			CellPadding = UDim2.fromOffset(CARD_GAP, CARD_GAP),
		}),

		cards,
	})
end

local function shapeCard(shapeName: string, variant: number, layoutOrder: number): Frame
	return create("Frame")({
		Name = `{shapeName}{variant}`,
		LayoutOrder = layoutOrder,
		BackgroundColor3 = CARD_COLOR,

		create("UICorner")({ CornerRadius = UDim.new(0, 8) }),
		create("UIStroke")({ Color = IDLE_STROKE_COLOR }),
		create("Frame")({
			Name = "Icon",
			Position = UDim2.fromOffset(8, 8),
			Size = UDim2.fromOffset(48, 48),
			BackgroundColor3 = MUTED_TEXT_COLOR,
			Rotation = (variant - 1) * 45,

			create("UICorner")({ CornerRadius = UDim.new(0, 4) }),
		}),
		create("TextLabel")({
			Name = "Label",
			Position = UDim2.fromOffset(64, 8),
			Size = UDim2.new(1, -72, 0, 22),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextSize = 16,
			TextColor3 = TEXT_COLOR,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = shapeName,
		}),
		create("TextLabel")({
			Name = "Variant",
			Position = UDim2.fromOffset(64, 32),
			Size = UDim2.new(1, -72, 0, 18),
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			TextSize = 14,
			TextColor3 = MUTED_TEXT_COLOR,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = `Variant {variant}`,
		}),
	})
end

local function shapesPage(): ScrollingFrame
	local cards = {}
	for shapeIndex, shapeName in SHAPE_NAMES do
		for variant = 1, SHAPE_VARIANTS do
			local index = (shapeIndex - 1) * SHAPE_VARIANTS + variant
			cards[index] = shapeCard(shapeName, variant, index)
		end
	end

	return create("ScrollingFrame")({
		Name = "Shapes",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),

		create("UIGridLayout")({
			CellSize = UDim2.fromOffset(SHAPE_CARD_SIZE.X, SHAPE_CARD_SIZE.Y),
			CellPadding = UDim2.fromOffset(CARD_GAP, CARD_GAP),
		}),

		cards,
	})
end

local function tabButton(props: BuildMenuProps, tab: Tab, layoutOrder: number): TextButton
	return create("TextButton")({
		Name = tab,
		LayoutOrder = layoutOrder,
		Size = UDim2.fromOffset(TAB_WIDTH, TAB_HEIGHT),
		BackgroundColor3 = function()
			return if props.Tab() == tab then SELECTED_COLOR else CARD_COLOR
		end,
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		TextColor3 = function()
			return if props.Tab() == tab then PANEL_COLOR else TEXT_COLOR
		end,
		Text = tab,

		Activated = function()
			props.SelectTab(tab)
		end,

		create("UICorner")({ CornerRadius = UDim.new(0, 8) }),
	})
end

local function buildMenu(props: BuildMenuProps): Frame
	-- 0 is in place; 1 is fully below the screen.
	local slide = spring(function(): number
		return if props.Present() then 0 else 1
	end, SLIDE_SECONDS)

	local tabs = {}
	for index, tab in TABS do
		tabs[index] = tabButton(props, tab, index)
	end

	return create("Frame")({
		Name = "BuildMenu",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = function()
			return UDim2.new(0.5, 0, 0.5 + slide(), slide() * PANEL_SIZE.Y)
		end,
		Size = UDim2.fromOffset(PANEL_SIZE.X, PANEL_SIZE.Y),
		BackgroundColor3 = PANEL_COLOR,
		BackgroundTransparency = 0.1,

		create("UICorner")({ CornerRadius = UDim.new(0, 12) }),
		create("UIPadding")({
			PaddingLeft = UDim.new(0, PANEL_PADDING),
			PaddingRight = UDim.new(0, PANEL_PADDING),
			PaddingTop = UDim.new(0, PANEL_PADDING),
			PaddingBottom = UDim.new(0, PANEL_PADDING),
		}),

		create("Frame")({
			Name = "Tabs",
			Size = UDim2.new(1, 0, 0, TAB_HEIGHT),
			BackgroundTransparency = 1,

			create("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, CARD_GAP),
			}),

			tabs,
		}),
		create("Frame")({
			Name = "Page",
			Position = UDim2.fromOffset(0, TAB_HEIGHT + PANEL_PADDING),
			Size = UDim2.new(1, 0, 1, -(TAB_HEIGHT + PANEL_PADDING)),
			BackgroundTransparency = 1,

			switch(props.Tab)({
				Blocks = blocksPage,
				Colors = function()
					return colorsPage(props)
				end,
				Shapes = shapesPage,
			}),
		}),
	})
end

return {
	SlideSeconds = SLIDE_SECONDS,
	component = buildMenu,
}
