--[[
	The in-game HUD: a hotbar of the ten block types along the bottom with their number keys, the
	build mode hint, the inventory button, and the coin counter. A slot's name shows in a tooltip
	while the mouse is over it.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
local Vide = require(ReplicatedStorage.Packages.Vide)

local create = Vide.create
local show = Vide.show
local source = Vide.source

type BlockType = BlockTypes.BlockType

local SLOT_SIZE = 40
local SLOT_GAP = 4
local KEY_LABELS = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "0" }
local SELECTED_COLOR = Color3.fromRGB(255, 200, 60)
local IDLE_STROKE_COLOR = Color3.fromRGB(20, 20, 24)
local PANEL_COLOR = Color3.fromRGB(28, 28, 34)
local TEXT_COLOR = Color3.fromRGB(240, 240, 240)

export type HudProps = {
	Selected: () -> string,
	Select: (name: string) -> (),
	BuildMode: () -> boolean,
	Coins: () -> number,
	OpenInventory: () -> (),
}

type SlotProps = {
	BlockType: BlockType,
	Index: number,
	IsSelected: () -> boolean,
	Select: () -> (),
	Hovered: Vide.Source<string?>,
}

local function slot(props: SlotProps): TextButton
	return create("TextButton")({
		Name = props.BlockType.Name,
		LayoutOrder = props.Index,
		Size = UDim2.fromOffset(SLOT_SIZE, SLOT_SIZE),
		BackgroundColor3 = props.BlockType.Color,

		MouseEnter = function()
			props.Hovered(props.BlockType.DisplayName)
		end,
		MouseLeave = function()
			if props.Hovered() == props.BlockType.DisplayName then
				props.Hovered(nil)
			end
		end,
		MouseButton1Click = props.Select,

		create("UICorner")({ CornerRadius = UDim.new(0, 4) }),
		create("UIStroke")({
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = function()
				return if props.IsSelected() then SELECTED_COLOR else IDLE_STROKE_COLOR
			end,
			Thickness = function()
				return if props.IsSelected() then 3 else 1
			end,
		}),

		create("TextLabel")({
			Name = "Key",
			Position = UDim2.fromOffset(3, 1),
			Size = UDim2.fromOffset(12, 12),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextSize = 12,
			TextColor3 = TEXT_COLOR,
			TextStrokeTransparency = 0.4,
			Text = KEY_LABELS[props.Index],
		}),
	})
end

local function hud(props: HudProps): { Instance }
	local hovered: Vide.Source<string?> = source(nil :: string?)

	local slots = {}
	for index, blockType in BlockTypes.List do
		slots[index] = slot({
			BlockType = blockType,
			Index = index,
			IsSelected = function()
				return props.Selected() == blockType.Name
			end,
			Select = function()
				props.Select(blockType.Name)
			end,
			Hovered = hovered,
		})
	end

	return {
		create("Frame")({
			Name = "Hotbar",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -16),
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundColor3 = PANEL_COLOR,
			BackgroundTransparency = 0.3,

			create("UICorner")({ CornerRadius = UDim.new(0, 6) }),
			create("UIPadding")({
				PaddingLeft = UDim.new(0, 6),
				PaddingRight = UDim.new(0, 6),
				PaddingTop = UDim.new(0, 6),
				PaddingBottom = UDim.new(0, 6),
			}),
			create("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, SLOT_GAP),
			}),

			slots,
		}),

		show(function()
			return hovered() ~= nil
		end, function()
			return create("TextLabel")({
				Name = "Tooltip",
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, 0, 1, -16 - SLOT_SIZE - 24),
				Size = UDim2.fromOffset(100, 22),
				BackgroundColor3 = PANEL_COLOR,
				Font = Enum.Font.Gotham,
				TextSize = 14,
				TextColor3 = TEXT_COLOR,
				Text = function()
					return hovered() or ""
				end,
			})
		end),

		create("TextLabel")({
			Name = "BuildModeHint",
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 16, 1, -16),
			Size = UDim2.fromOffset(180, 20),
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			TextSize = 14,
			TextColor3 = TEXT_COLOR,
			TextStrokeTransparency = 0.5,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = function()
				return if props.BuildMode() then "[B] Build mode: ON" else "[B] Build mode: OFF"
			end,
		}),

		create("TextButton")({
			Name = "InventoryButton",
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -16, 1, -16),
			Size = UDim2.fromOffset(120, 28),
			BackgroundColor3 = PANEL_COLOR,
			Font = Enum.Font.GothamBold,
			TextSize = 14,
			TextColor3 = TEXT_COLOR,
			Text = "[I] Inventory",

			MouseButton1Click = props.OpenInventory,

			create("UICorner")({ CornerRadius = UDim.new(0, 6) }),
		}),

		create("TextLabel")({
			Name = "Coins",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -16, 0, 12),
			Size = UDim2.fromOffset(140, 20),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextSize = 14,
			TextColor3 = SELECTED_COLOR,
			TextStrokeTransparency = 0.5,
			TextXAlignment = Enum.TextXAlignment.Right,
			Text = function()
				return `Coins: {props.Coins()}`
			end,
		}),
	}
end

return hud
