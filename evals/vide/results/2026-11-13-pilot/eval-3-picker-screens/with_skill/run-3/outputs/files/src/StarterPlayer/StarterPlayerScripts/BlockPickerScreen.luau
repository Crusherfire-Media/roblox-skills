--[[
	Places the block picker for the screen the player has, and moves it live when that changes.
	With a mouse and keyboard it is a column at the left edge. With touch controls up, or on a
	phone-sized window, it is a row along the bottom, between the thumbstick region and the jump
	button.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BlockPicker = require(script.Parent.BlockPicker)
local GameScreenGui = require(script.Parent.GameScreenGui)
local Screen = require(script.Parent.Screen)
local Vide = require(ReplicatedStorage.Packages.Vide)

local derive = Vide.derive

local COLUMN_ANCHOR = Vector2.new(0, 0.5)
local COLUMN_POSITION = UDim2.new(0, 20, 0.5, 0)
local ROW_ANCHOR = Vector2.new(0.5, 1)
local ROW_BOTTOM_MARGIN = 12

export type BlockPickerScreenProps = {
	Selected: () -> string,
	Select: (name: string) -> (),
}

local function blockPickerScreen(props: BlockPickerScreenProps): ScreenGui
	local layout = derive(function(): BlockPicker.Layout
		return if Screen.isTouchLayout() then "Row" else "Column"
	end)

	return GameScreenGui({
		Name = "BlockPickerGui",
		Children = {
			BlockPicker({
				Selected = props.Selected,
				Select = props.Select,
				Layout = layout,
				MaxWidth = function()
					local band = Screen.bottomBand()
					return band.Right - band.Left
				end,
				AnchorPoint = function()
					return if layout() == "Row" then ROW_ANCHOR else COLUMN_ANCHOR
				end,
				Position = function()
					if layout() == "Column" then
						return COLUMN_POSITION
					end
					local band = Screen.bottomBand()
					local centerX = math.round((band.Left + band.Right) / 2)
					return UDim2.new(0, centerX, 1, -ROW_BOTTOM_MARGIN)
				end,
			}),
		},
	})
end

return blockPickerScreen
