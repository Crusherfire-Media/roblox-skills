--[[
	The hotbar: one slot per block type along the bottom of the screen, each showing the block's
	color and its number key, under the name of the selected block. Clicking or tapping a slot
	selects that block.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
local Vide = require(ReplicatedStorage.Packages.Vide)

local create = Vide.create

type BlockType = BlockTypes.BlockType

local SLOT_SIZE = 56
local SLOT_GAP = 6
local SWATCH_SIZE = 40
local KEY_LABELS = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "0" }
local BAR_COLOR = Color3.fromRGB(30, 30, 36)
local SLOT_COLOR = Color3.fromRGB(50, 50, 58)
local SELECTED_COLOR = Color3.fromRGB(255, 200, 60)
local TEXT_COLOR = Color3.fromRGB(240, 240, 240)

type SlotProps = {
	BlockType: BlockType,
	Index: number,
	IsSelected: () -> boolean,
	Select: () -> (),
}

local function slot(props: SlotProps): TextButton
	return create("TextButton")({
		Name = props.BlockType.Name,
		LayoutOrder = props.Index,
		Size = UDim2.fromOffset(SLOT_SIZE, SLOT_SIZE),
		BackgroundColor3 = SLOT_COLOR,

		Activated = props.Select,

		create("UICorner")({ CornerRadius = UDim.new(0, 6) }),
		create("UIStroke")({
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = SELECTED_COLOR,
			Thickness = 2,
			Enabled = props.IsSelected,
		}),

		create("Frame")({
			Name = "Swatch",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(SWATCH_SIZE, SWATCH_SIZE),
			BackgroundColor3 = props.BlockType.Color,

			create("UICorner")({ CornerRadius = UDim.new(0, 4) }),
		}),

		create("TextLabel")({
			Name = "Key",
			Position = UDim2.fromOffset(4, 2),
			Size = UDim2.fromOffset(14, 14),
			BackgroundTransparency = 1,
			FontFace = Font.fromName("BuilderSans", Enum.FontWeight.Bold),
			TextSize = 14,
			TextColor3 = TEXT_COLOR,
			Text = KEY_LABELS[props.Index],
		}),
	})
end

export type HotbarProps = {
	Selected: () -> string,
	Select: (name: string) -> (),
}

local function hotbar(props: HotbarProps): Frame
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
		})
	end

	return create("Frame")({
		Name = "Hotbar",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -16),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,

		create("UIListLayout")({
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, 8),
		}),

		create("TextLabel")({
			Name = "SelectedName",
			LayoutOrder = 1,
			Size = UDim2.fromOffset(240, 28),
			BackgroundTransparency = 1,
			FontFace = Font.fromName("BuilderSans", Enum.FontWeight.Bold),
			TextSize = 22,
			TextColor3 = TEXT_COLOR,
			Text = function()
				return BlockTypes.ByName[props.Selected()].DisplayName
			end,
		}),

		create("Frame")({
			Name = "Bar",
			LayoutOrder = 2,
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundColor3 = BAR_COLOR,

			create("UICorner")({ CornerRadius = UDim.new(0, 8) }),
			create("UIPadding")({
				PaddingLeft = UDim.new(0, 8),
				PaddingRight = UDim.new(0, 8),
				PaddingTop = UDim.new(0, 8),
				PaddingBottom = UDim.new(0, 8),
			}),
			create("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, SLOT_GAP),
			}),

			slots,
		}),
	})
end

return hotbar
