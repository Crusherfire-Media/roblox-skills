local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BlockPicker = require(script.Parent.BlockPicker)
local BlockPlacer = require(script.Parent.BlockPlacer)
local PlacementPreview = require(script.Parent.PlacementPreview)
local Vide = require(ReplicatedStorage.Packages.Vide)

local create = Vide.create
local mount = Vide.mount
local source = Vide.source

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

-- Mirrors BlockPlacer's selection so the hotbar can bind to it.
local selected = source(BlockPlacer.getBlockType())
BlockPlacer.BlockTypeChanged:Connect(function(name: string)
	selected(name)
end)

local function app()
	return create("ScreenGui")({
		Name = "HotbarGui",

		BlockPicker({
			Selected = selected,
			Select = BlockPlacer.setBlockType,
		}),
	})
end

mount(app, playerGui)

PlacementPreview.start()
BlockPlacer.start()
