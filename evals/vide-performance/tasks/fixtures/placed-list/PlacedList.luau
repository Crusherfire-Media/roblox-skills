--[[
	The placed blocks panel: a scrolling list of every block the player has placed this session,
	newest at the top. Each row shows the block's color, its type, where it is, and how long ago it
	was placed.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
local Vide = require(ReplicatedStorage.Packages.Vide)

local cleanup = Vide.cleanup
local create = Vide.create
local indexes = Vide.indexes
local source = Vide.source

export type PlacedBlock = {
	Id: number,
	BlockTypeName: string,
	Position: Vector3,
	-- os.clock() when the block was placed.
	PlacedAt: number,
}

local PANEL_SIZE = Vector2.new(360, 420)
local PANEL_MARGIN = 16
local PANEL_PADDING = 10
local HEADER_HEIGHT = 28
local ROW_HEIGHT = 44
local ROW_GAP = 4
local SWATCH_SIZE = 28
local PANEL_COLOR = Color3.fromRGB(28, 28, 34)
local ROW_COLOR = Color3.fromRGB(44, 44, 52)
local TEXT_COLOR = Color3.fromRGB(240, 240, 240)
local MUTED_TEXT_COLOR = Color3.fromRGB(180, 180, 190)

local function formatAge(seconds: number): string
	if seconds < 60 then
		return `{math.floor(seconds)} s ago`
	end
	return `{math.floor(seconds / 60)} min ago`
end

local function row(entry: () -> PlacedBlock, index: number): Frame
	local now = source(os.clock())
	cleanup(RunService.Heartbeat:Connect(function()
		now(os.clock())
	end))

	local function blockType(): BlockTypes.BlockType
		return BlockTypes.ByName[entry().BlockTypeName]
	end

	return create("Frame")({
		Name = `Row{entry().Id}`,
		-- Newest first: a higher index is a later placement.
		LayoutOrder = -index,
		Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
		BackgroundColor3 = ROW_COLOR,

		create("UICorner")({ CornerRadius = UDim.new(0, 6) }),
		create("Frame")({
			Name = "Swatch",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 8, 0.5, 0),
			Size = UDim2.fromOffset(SWATCH_SIZE, SWATCH_SIZE),
			BackgroundColor3 = function()
				return blockType().Color
			end,

			create("UICorner")({ CornerRadius = UDim.new(0, 4) }),
		}),
		create("TextLabel")({
			Name = "BlockName",
			Position = UDim2.fromOffset(SWATCH_SIZE + 16, 4),
			Size = UDim2.new(1, -(SWATCH_SIZE + 100), 0, 20),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextSize = 16,
			TextColor3 = TEXT_COLOR,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = function()
				return blockType().DisplayName
			end,
		}),
		create("TextLabel")({
			Name = "Position",
			Position = UDim2.fromOffset(SWATCH_SIZE + 16, 24),
			Size = UDim2.new(1, -(SWATCH_SIZE + 100), 0, 16),
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			TextSize = 13,
			TextColor3 = MUTED_TEXT_COLOR,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = function()
				local position = entry().Position
				return `{position.X}, {position.Y}, {position.Z}`
			end,
		}),
		create("TextLabel")({
			Name = "Age",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.fromOffset(76, 20),
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			TextSize = 13,
			TextColor3 = MUTED_TEXT_COLOR,
			TextXAlignment = Enum.TextXAlignment.Right,
			Text = function()
				return formatAge(now() - entry().PlacedAt)
			end,
		}),
	})
end

export type PlacedListProps = {
	Placed: () -> { PlacedBlock },
	IsOpen: () -> boolean,
}

local function placedList(props: PlacedListProps): Frame
	return create("Frame")({
		Name = "PlacedList",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -PANEL_MARGIN, 0.5, 0),
		Size = UDim2.fromOffset(PANEL_SIZE.X, PANEL_SIZE.Y),
		BackgroundColor3 = PANEL_COLOR,
		BackgroundTransparency = 0.1,
		Visible = props.IsOpen,

		create("UICorner")({ CornerRadius = UDim.new(0, 10) }),
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
			TextSize = 20,
			TextColor3 = TEXT_COLOR,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = function()
				return `Placed blocks ({#props.Placed()})`
			end,
		}),
		create("ScrollingFrame")({
			Name = "Rows",
			Position = UDim2.fromOffset(0, HEADER_HEIGHT + PANEL_PADDING),
			Size = UDim2.new(1, 0, 1, -(HEADER_HEIGHT + PANEL_PADDING)),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 6,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(),

			create("UIListLayout")({
				FillDirection = Enum.FillDirection.Vertical,
				Padding = UDim.new(0, ROW_GAP),
			}),

			indexes(props.Placed, row),
		}),
	})
end

return placedList
