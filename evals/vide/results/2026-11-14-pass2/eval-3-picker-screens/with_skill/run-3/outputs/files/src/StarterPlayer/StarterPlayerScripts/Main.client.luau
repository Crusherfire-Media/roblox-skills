local Players = game:GetService("Players")

local Vide = require("@game/ReplicatedStorage/Packages/Vide")

local BlockPicker = require("./BlockPicker")
local BlockPlacer = require("./BlockPlacer")
local GameScreenGui = require("./GameScreenGui")
local Screen = require("./Screen")

local derive = Vide.derive
local mount = Vide.mount
local source = Vide.source

-- The column sits mid-left, out of the way on a desktop. The row sits at the
-- top center, clear of the thumbstick (lower left) and jump button (lower
-- right) on touch screens.
local COLUMN_ANCHOR = Vector2.new(0, 0.5)
local COLUMN_POSITION = UDim2.new(0, 20, 0.5, 0)
local ROW_ANCHOR = Vector2.new(0.5, 0)
local ROW_POSITION = UDim2.new(0.5, 0, 0, 8)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local selected = source(BlockPlacer.getBlockType())
BlockPlacer.BlockTypeChanged:Connect(function(name: string)
	selected(name)
end)

local function app()
	local layout = derive(function(): BlockPicker.Layout
		return if Screen.isTouchLayout() then "Row" else "Column"
	end)

	return GameScreenGui({
		Name = "BlockPickerGui",
		Children = {
			BlockPicker({
				Selected = selected,
				Select = BlockPlacer.setBlockType,
				Layout = layout,
				ShowKeyHints = function()
					return Screen.preferredInput() == Enum.PreferredInput.KeyboardAndMouse
				end,
				AnchorPoint = function()
					return if layout() == "Row" then ROW_ANCHOR else COLUMN_ANCHOR
				end,
				Position = function()
					return if layout() == "Row" then ROW_POSITION else COLUMN_POSITION
				end,
			}),
		},
	})
end

mount(app, playerGui)

BlockPlacer.start()
