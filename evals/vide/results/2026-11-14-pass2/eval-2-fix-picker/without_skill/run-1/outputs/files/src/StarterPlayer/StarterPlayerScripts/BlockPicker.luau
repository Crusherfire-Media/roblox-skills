--[[
	The block picker shown in build mode: a row of tiles, one per block type, under a label naming
	the selected block. Q and E step through the block types, and hovering a tile shows an info
	card above it.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
local Vide = require(ReplicatedStorage.Packages.Vide)

local cleanup = Vide.cleanup
local create = Vide.create
local show = Vide.show
local source = Vide.source

type BlockType = BlockTypes.BlockType

local TILE_SIZE = 64
local TILE_GAP = 8
local TILE_RADIUS = 8
local CARD_SIZE = Vector2.new(150, 56)
local CARD_RADIUS = 6
local LABEL_HEIGHT = 28
local SELECTED_COLOR = Color3.fromRGB(255, 200, 60)
local IDLE_COLOR = Color3.fromRGB(40, 40, 46)
local TEXT_COLOR = Color3.fromRGB(240, 240, 240)
local MUTED_TEXT_COLOR = Color3.fromRGB(180, 180, 190)

type InfoCardProps = {
	BlockType: BlockType,
	IsSelected: () -> boolean,
}

local function infoCard(props: InfoCardProps): Frame
	return create("Frame")({
		Name = "InfoCard",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 0, -TILE_GAP),
		Size = UDim2.fromOffset(CARD_SIZE.X, CARD_SIZE.Y),
		BackgroundColor3 = IDLE_COLOR,
		ZIndex = 2,

		create("UICorner")({ CornerRadius = UDim.new(0, CARD_RADIUS) }),
		create("UIPadding")({
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
			PaddingTop = UDim.new(0, 6),
			PaddingBottom = UDim.new(0, 6),
		}),
		create("UIListLayout")({ FillDirection = Enum.FillDirection.Vertical }),

		create("TextLabel")({
			Name = "Title",
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, 22),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextSize = 18,
			TextColor3 = TEXT_COLOR,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = props.BlockType.DisplayName,
			ZIndex = 2,
		}),
		create("TextLabel")({
			Name = "Hint",
			LayoutOrder = 2,
			Size = UDim2.new(1, 0, 0, 18),
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			TextSize = 14,
			TextColor3 = MUTED_TEXT_COLOR,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = function()
				return if props.IsSelected() then "Selected" else "Click to select"
			end,
			ZIndex = 2,
		}),
	})
end

type TileProps = {
	BlockType: BlockType,
	LayoutOrder: number,
	Selected: () -> string,
	Select: (name: string) -> (),
}

local function tile(props: TileProps): TextButton
	local isHovered = source(false)
	local function isSelected(): boolean
		return props.Selected() == props.BlockType.Name
	end

	return create("TextButton")({
		Name = props.BlockType.Name,
		LayoutOrder = props.LayoutOrder,
		Size = UDim2.fromOffset(TILE_SIZE, TILE_SIZE),
		BackgroundColor3 = props.BlockType.Color,

		MouseEnter = function()
			isHovered(true)
		end,
		MouseLeave = function()
			isHovered(false)
		end,
		Activated = function()
			props.Select(props.BlockType.Name)
		end,

		create("UICorner")({ CornerRadius = UDim.new(0, TILE_RADIUS) }),
		create("UIStroke")({
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = function()
				return if isSelected() then SELECTED_COLOR else IDLE_COLOR
			end,
			Thickness = function()
				return if isSelected() then 3 else 1
			end,
		}),

		-- show() builds the card in its own stable scope, so the card can have reactive properties.
		show(isHovered, function()
			return infoCard({
				BlockType = props.BlockType,
				IsSelected = isSelected,
			})
		end),
	})
end

export type BlockPickerProps = {
	Selected: () -> string,
	Select: (name: string) -> (),
}

local function blockPicker(props: BlockPickerProps): Frame
	local function selectedDisplayName(): string
		return BlockTypes.ByName[props.Selected()].DisplayName
	end

	local function step(direction: number)
		local current = 1
		for index, blockType in BlockTypes.List do
			if blockType.Name == props.Selected() then
				current = index
			end
		end
		local nextIndex = (current - 1 + direction) % #BlockTypes.List + 1
		props.Select(BlockTypes.List[nextIndex].Name)
	end

	-- Disconnected when the picker's scope is destroyed, so Q and E only work while it is shown.
	local connection = UserInputService.InputBegan:Connect(
		function(input: InputObject, gameProcessedEvent: boolean)
			if gameProcessedEvent then
				return
			end
			if input.KeyCode == Enum.KeyCode.Q then
				step(-1)
			elseif input.KeyCode == Enum.KeyCode.E then
				step(1)
			end
		end
	)
	cleanup(connection)

	local tiles = {}
	for index, blockType in BlockTypes.List do
		tiles[index] = tile({
			BlockType = blockType,
			LayoutOrder = index,
			Selected = props.Selected,
			Select = props.Select,
		})
	end

	return create("Frame")({
		Name = "BlockPicker",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -24),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,

		create("UIListLayout")({
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, TILE_GAP),
		}),

		create("TextLabel")({
			Name = "SelectedName",
			LayoutOrder = 1,
			Size = UDim2.fromOffset(TILE_SIZE * 5 + TILE_GAP * 4, LABEL_HEIGHT),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextSize = 22,
			TextColor3 = TEXT_COLOR,
			TextStrokeTransparency = 0.5,
			Text = selectedDisplayName,
		}),

		create("Frame")({
			Name = "Tiles",
			LayoutOrder = 2,
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,

			create("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, TILE_GAP),
			}),

			tiles,
		}),
	})
end

return blockPicker
