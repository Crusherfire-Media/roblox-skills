--[[
	The block catalog: a panel with a card for every block type in every shape. Hovering a card
	sweeps a soft shine across it, clipped to the card's rounded corners, and clicking it picks
	that block type. The whole panel fades in when it opens and out when it closes.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
local Vide = require(ReplicatedStorage.Packages.Vide)

local create = Vide.create
local source = Vide.source
local spring = Vide.spring

type BlockType = BlockTypes.BlockType

local SHAPE_NAMES = { "Cube", "Slab", "Stair", "Wedge", "Corner", "Pillar", "Arch", "Fence" }
local PANEL_SIZE = Vector2.new(640, 480)
local PANEL_PADDING = 12
local HEADER_HEIGHT = 32
local CARD_SIZE = Vector2.new(140, 72)
local CARD_GAP = 8
local CARD_RADIUS = 10
local SWATCH_SIZE = 48
local SHINE_WIDTH = 28
-- How long the panel takes to fade in or out, in seconds.
local FADE_SECONDS = 0.25
-- How long the shine takes to sweep across a card, in seconds.
local SWEEP_SECONDS = 0.45
local PANEL_COLOR = Color3.fromRGB(28, 28, 34)
local CARD_COLOR = Color3.fromRGB(44, 44, 52)
local SHINE_COLOR = Color3.fromRGB(255, 255, 255)
local TEXT_COLOR = Color3.fromRGB(240, 240, 240)
local MUTED_TEXT_COLOR = Color3.fromRGB(180, 180, 190)

export type BlockCatalogProps = {
	Select: (blockTypeName: string) -> (),
	-- True while the catalog is open; false makes it fade out.
	Present: () -> boolean,
}

local function card(
	props: BlockCatalogProps,
	blockType: BlockType,
	shapeName: string,
	layoutOrder: number
)
	local isHovered = source(false)
	-- 0 is no shine; 1 is full strength.
	local shine = spring(function(): number
		return if isHovered() then 1 else 0
	end, SWEEP_SECONDS)
	-- Where the shine stripe is across the card, from -1 (left of it) to 1 (right of it).
	local sweep = spring(function(): number
		return if isHovered() then 1 else -1
	end, SWEEP_SECONDS)

	return create("CanvasGroup")({
		Name = `{blockType.Name}{shapeName}`,
		LayoutOrder = layoutOrder,
		BackgroundColor3 = CARD_COLOR,

		MouseEnter = function()
			isHovered(true)
		end,
		MouseLeave = function()
			isHovered(false)
		end,

		create("UICorner")({ CornerRadius = UDim.new(0, CARD_RADIUS) }),
		create("Frame")({
			Name = "Swatch",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 12, 0.5, 0),
			Size = UDim2.fromOffset(SWATCH_SIZE, SWATCH_SIZE),
			BackgroundColor3 = blockType.Color,

			create("UICorner")({ CornerRadius = UDim.new(0, 6) }),
		}),
		create("TextLabel")({
			Name = "BlockName",
			Position = UDim2.fromOffset(SWATCH_SIZE + 20, 14),
			Size = UDim2.new(1, -(SWATCH_SIZE + 28), 0, 20),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextSize = 16,
			TextColor3 = TEXT_COLOR,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = blockType.DisplayName,
		}),
		create("TextLabel")({
			Name = "Shape",
			Position = UDim2.fromOffset(SWATCH_SIZE + 20, 36),
			Size = UDim2.new(1, -(SWATCH_SIZE + 28), 0, 18),
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			TextSize = 14,
			TextColor3 = MUTED_TEXT_COLOR,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = shapeName,
		}),
		create("TextButton")({
			Name = "Hitbox",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "",
			ZIndex = 3,

			Activated = function()
				props.Select(blockType.Name)
			end,
		}),
		create("Frame")({
			Name = "Shine",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = function()
				return UDim2.fromScale(0.5 + sweep() * 0.75, 0.5)
			end,
			Size = UDim2.new(0, SHINE_WIDTH, 2, 0),
			Rotation = 20,
			BackgroundColor3 = SHINE_COLOR,
			BackgroundTransparency = function()
				return 1 - shine() * 0.5
			end,
			ZIndex = 2,

			create("UIGradient")({
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.5, 0),
					NumberSequenceKeypoint.new(1, 1),
				}),
			}),
		}),
	})
end

local function blockCatalog(props: BlockCatalogProps): CanvasGroup
	-- 0 is hidden; 1 is fully shown.
	local fade = spring(function(): number
		return if props.Present() then 1 else 0
	end, FADE_SECONDS)

	local cards = {}
	for typeIndex, blockType in BlockTypes.List do
		for shapeIndex, shapeName in SHAPE_NAMES do
			local index = (typeIndex - 1) * #SHAPE_NAMES + shapeIndex
			cards[index] = card(props, blockType, shapeName, index)
		end
	end

	return create("CanvasGroup")({
		Name = "BlockCatalog",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(PANEL_SIZE.X, PANEL_SIZE.Y),
		BackgroundColor3 = PANEL_COLOR,
		GroupTransparency = function()
			return 1 - fade()
		end,

		create("UICorner")({ CornerRadius = UDim.new(0, 14) }),
		create("UIPadding")({
			PaddingLeft = UDim.new(0, PANEL_PADDING),
			PaddingRight = UDim.new(0, PANEL_PADDING),
			PaddingTop = UDim.new(0, PANEL_PADDING),
			PaddingBottom = UDim.new(0, PANEL_PADDING),
		}),

		create("TextLabel")({
			Name = "Header",
			Size = UDim2.new(1, 0, 0, HEADER_HEIGHT),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextSize = 22,
			TextColor3 = TEXT_COLOR,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = "Block catalog",
		}),
		create("ScrollingFrame")({
			Name = "Cards",
			Position = UDim2.fromOffset(0, HEADER_HEIGHT + PANEL_PADDING),
			Size = UDim2.new(1, 0, 1, -(HEADER_HEIGHT + PANEL_PADDING)),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 6,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(),

			create("UIGridLayout")({
				CellSize = UDim2.fromOffset(CARD_SIZE.X, CARD_SIZE.Y),
				CellPadding = UDim2.fromOffset(CARD_GAP, CARD_GAP),
			}),

			cards,
		}),
	})
end

return {
	FadeSeconds = FADE_SECONDS,
	component = blockCatalog,
}
