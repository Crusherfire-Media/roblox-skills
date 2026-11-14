--[[
	One hotbar tile: a block type's color swatch with its name under it and a stock count in the
	corner. The selected tile has an outline, and a locked tile is dimmed with a lock mark.
	Every prop is a source, so the tile follows changes live.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.Vide)

local create = Vide.create

local NAME_HEIGHT = 18
local COUNT_SIZE = Vector2.new(30, 18)
local TEXT_COLOR = Color3.fromRGB(240, 240, 240)
local COUNT_BACKGROUND = Color3.fromRGB(20, 20, 24)
local IDLE_STROKE_COLOR = Color3.fromRGB(70, 70, 80)
local LOCKED_TRANSPARENCY = 0.6

export type BlockTileProps = {
	Name: () -> string,
	Color: () -> Color3,
	Count: () -> number,
	ShowName: () -> boolean,
	ShowCount: () -> boolean,
	IsSelected: () -> boolean,
	IsLocked: () -> boolean,
	-- Edge length of the swatch, in pixels.
	Size: () -> number,
	CornerRadius: () -> number,
	HighlightColor: () -> Color3,
	HighlightThickness: () -> number,
	Select: () -> (),
}

local function blockTile(props: BlockTileProps): TextButton
	return create("TextButton")({
		Name = "BlockTile",
		Size = function()
			return UDim2.fromOffset(props.Size(), props.Size() + NAME_HEIGHT)
		end,
		BackgroundTransparency = 1,
		Text = "",

		Activated = function()
			if not props.IsLocked() then
				props.Select()
			end
		end,

		create("Frame")({
			Name = "Swatch",
			Size = function()
				return UDim2.fromOffset(props.Size(), props.Size())
			end,
			BackgroundColor3 = props.Color,
			BackgroundTransparency = function()
				return if props.IsLocked() then LOCKED_TRANSPARENCY else 0
			end,

			create("UICorner")({
				CornerRadius = function()
					return UDim.new(0, props.CornerRadius())
				end,
			}),
			create("UIStroke")({
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				BorderStrokePosition = Enum.BorderStrokePosition.Inner,
				Color = function()
					return if props.IsSelected() then props.HighlightColor() else IDLE_STROKE_COLOR
				end,
				Thickness = function()
					return if props.IsSelected() then props.HighlightThickness() else 1
				end,
			}),
			create("TextLabel")({
				Name = "Count",
				AnchorPoint = Vector2.new(1, 1),
				Position = UDim2.new(1, -4, 1, -4),
				Size = UDim2.fromOffset(COUNT_SIZE.X, COUNT_SIZE.Y),
				BackgroundColor3 = COUNT_BACKGROUND,
				BackgroundTransparency = 0.3,
				Font = Enum.Font.GothamBold,
				TextSize = 12,
				TextColor3 = TEXT_COLOR,
				Visible = props.ShowCount,
				Text = function()
					return tostring(props.Count())
				end,

				create("UICorner")({ CornerRadius = UDim.new(0, 4) }),
			}),
			create("TextLabel")({
				Name = "Lock",
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				TextSize = 24,
				TextColor3 = TEXT_COLOR,
				Visible = props.IsLocked,
				Text = "X",
			}),
		}),
		create("TextLabel")({
			Name = "BlockName",
			Position = function()
				return UDim2.fromOffset(0, props.Size())
			end,
			Size = function()
				return UDim2.fromOffset(props.Size(), NAME_HEIGHT)
			end,
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			TextSize = 14,
			TextColor3 = TEXT_COLOR,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Visible = props.ShowName,
			Text = props.Name,
		}),
	})
end

return blockTile
