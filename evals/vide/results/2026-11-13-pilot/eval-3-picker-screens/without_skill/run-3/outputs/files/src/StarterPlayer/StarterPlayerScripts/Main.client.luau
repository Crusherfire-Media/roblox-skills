local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BlockPicker = require(script.Parent.BlockPicker)
local BlockPlacer = require(script.Parent.BlockPlacer)
local Screen = require(script.Parent.UI.Screen)
local Vide = require(ReplicatedStorage.Packages.Vide)

local mount = Vide.mount
local source = Vide.source

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local selected = source(BlockPlacer.getBlockType())
BlockPlacer.BlockTypeChanged:Connect(function(name: string)
	selected(name)
end)

local function app()
	return Screen({
		Name = "BlockPickerGui",
		Children = {
			BlockPicker({
				Selected = selected,
				Select = BlockPlacer.setBlockType,
			}),
		},
	})
end

mount(app, playerGui)

BlockPlacer.start()
