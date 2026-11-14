local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BlockPlacer = require(script.Parent.BlockPlacer)
local Hotbar = require(script.Parent.UI.Hotbar)
local Screen = require(script.Parent.UI.Screen)
local Vide = require(ReplicatedStorage.Packages.Vide)

local cleanup = Vide.cleanup
local create = Vide.create
local mount = Vide.mount
local source = Vide.source

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

mount(function()
	local selected = source(BlockPlacer.getBlockType())
	cleanup(BlockPlacer.BlockTypeChanged:Connect(function(name: string)
		selected(name)
	end))

	return create("ScreenGui")({
		Name = "GameGui",

		Screen.uiScale(),

		Hotbar({
			Selected = selected,
			Select = BlockPlacer.setBlockType,
		}),
	})
end, playerGui)

BlockPlacer.start()
