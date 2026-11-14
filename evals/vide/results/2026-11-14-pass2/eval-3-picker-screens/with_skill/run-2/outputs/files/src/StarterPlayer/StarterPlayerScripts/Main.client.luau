--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.Vide)

local BlockPicker = require(script.Parent.BlockPicker)
local BlockPlacer = require(script.Parent.BlockPlacer)
local ScaledScreenGui = require(script.Parent.ScaledScreenGui)
local Screen = require(script.Parent.Screen)

local derive = Vide.derive
local mount = Vide.mount
local source = Vide.source

local COLUMN_EDGE_MARGIN = 20
local ROW_EDGE_MARGIN = 12
local COLUMN_ANCHOR = Vector2.new(0, 0.5)
local COLUMN_POSITION = UDim2.new(0, COLUMN_EDGE_MARGIN, 0.5, 0)
-- Top right keeps touch rows out of the thumbstick's region (the left 40
-- percent, lower two thirds) and above the jump button.
local ROW_ANCHOR = Vector2.new(1, 0)
local ROW_POSITION = UDim2.new(1, -ROW_EDGE_MARGIN, 0, ROW_EDGE_MARGIN)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local selected = source(BlockPlacer.getBlockType())
BlockPlacer.BlockTypeChanged:Connect(function(name: string)
	selected(name)
end)

local function pickerLayout(): BlockPicker.Layout
	if Screen.isPhone() then
		return "CompactRow"
	elseif Screen.isTouch() then
		return "Row"
	else
		return "Column"
	end
end

local function app()
	-- Derived, so placement reruns when the layout flips and not on every
	-- pixel of a window resize.
	local layout = derive(pickerLayout)
	local function isColumn()
		return layout() == "Column"
	end

	return ScaledScreenGui({
		Name = "BlockPickerGui",
		Children = {
			BlockPicker({
				Selected = selected,
				Select = BlockPlacer.setBlockType,
				Layout = layout,
				AnchorPoint = function()
					return if isColumn() then COLUMN_ANCHOR else ROW_ANCHOR
				end,
				Position = function()
					return if isColumn() then COLUMN_POSITION else ROW_POSITION
				end,
			}),
		},
	})
end

mount(app, playerGui)

BlockPlacer.start()
