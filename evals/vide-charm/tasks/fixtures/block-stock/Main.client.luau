local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BlockPicker = require(script.Parent.BlockPicker)
local BlockPlacer = require(script.Parent.BlockPlacer)
local Vide = require(ReplicatedStorage.Packages.Vide)
local VideCharm = require(ReplicatedStorage.Packages.VideCharm)

local create = Vide.create
local mount = Vide.mount

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local function app()
	local selected = VideCharm.useSignalState(BlockPlacer.getBlockType)

	return create("ScreenGui")({
		Name = "HotbarGui",

		BlockPicker({
			Selected = selected,
			Select = BlockPlacer.setBlockType,
		}),
	})
end

mount(app, playerGui)

BlockPlacer.start()
