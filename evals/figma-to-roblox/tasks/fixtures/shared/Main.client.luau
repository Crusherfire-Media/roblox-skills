local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BlockPlacer = require(script.Parent.BlockPlacer)
local Screen = require(script.Parent.UI.Screen)
local Vide = require(ReplicatedStorage.Packages.Vide)

local create = Vide.create
local mount = Vide.mount

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

mount(function()
	return create("ScreenGui")({
		Name = "GameGui",

		Screen.uiScale(),
	})
end, playerGui)

BlockPlacer.start()
