const Players = game:GetService("Players")
const RunService = game:GetService("RunService")

const Vide = require("@game/ReplicatedStorage/Packages/Vide")

const BlockPicker = require("./BlockPicker")
const BlockPlacer = require("./BlockPlacer")
const Screen = require("@game/ReplicatedStorage/Shared/UI/Screen")
const gameScreenGui = require("@game/ReplicatedStorage/Shared/UI/gameScreenGui")

Vide.strict = RunService:IsStudio()

const mount = Vide.mount
const source = Vide.source

-- Desktop: the column hugs the left edge, centered vertically.
const COLUMN_ANCHOR = Vector2.new(0, 0.5)
const COLUMN_POSITION = UDim2.new(0, 20, 0.5, 0)
-- Touch: the row sits in the top right, clear of the thumbstick (left 40
-- percent, lower two thirds) and the jump button (lower right).
const ROW_ANCHOR = Vector2.new(1, 0)
const ROW_POSITION = UDim2.new(1, -12, 0, 12)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local selected = source(BlockPlacer.getBlockType())
BlockPlacer.BlockTypeChanged:Connect(function(name: string)
	selected(name)
end)

local function pickerLayout(): BlockPicker.Layout
	return if Screen.isTouchLayout() then "Row" else "Column"
end

local function app()
	return gameScreenGui({
		Name = "BlockPickerGui",
		Children = {
			BlockPicker({
				Selected = selected,
				Select = BlockPlacer.setBlockType,
				Layout = pickerLayout,
				AnchorPoint = function()
					return if pickerLayout() == "Row" then ROW_ANCHOR else COLUMN_ANCHOR
				end,
				Position = function()
					return if pickerLayout() == "Row" then ROW_POSITION else COLUMN_POSITION
				end,
			}),
		},
	})
end

mount(app, playerGui)

BlockPlacer.start()
