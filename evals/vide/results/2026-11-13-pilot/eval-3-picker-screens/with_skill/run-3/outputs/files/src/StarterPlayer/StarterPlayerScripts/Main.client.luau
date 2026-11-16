local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BlockPickerScreen = require(script.Parent.BlockPickerScreen)
local BlockPlacer = require(script.Parent.BlockPlacer)
local Vide = require(ReplicatedStorage.Packages.Vide)

local mount = Vide.mount
local source = Vide.source

Vide.strict = RunService:IsStudio()

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local selected = source(BlockPlacer.getBlockType())
BlockPlacer.BlockTypeChanged:Connect(function(name: string)
	selected(name)
end)

mount(function()
	return BlockPickerScreen({
		Selected = selected,
		Select = BlockPlacer.setBlockType,
	})
end, playerGui)

BlockPlacer.start()
