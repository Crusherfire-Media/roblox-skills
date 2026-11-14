local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local BlockPlacer = require(script.Parent.BlockPlacer)
local BuildHud = require(script.Parent.BuildHud)
local PlacedBlocks = require(script.Parent.PlacedBlocks)
local Vide = require(ReplicatedStorage.Packages.Vide)

local create = Vide.create
local mount = Vide.mount
local show = Vide.show
local source = Vide.source

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local isHudVisible = source(true)

local function app()
	return create("ScreenGui")({
		Name = "BuildHudGui",

		show(isHudVisible, BuildHud),
	})
end

mount(app, playerGui)

-- H hides and shows the build HUD.
UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
	if gameProcessedEvent or input.KeyCode ~= Enum.KeyCode.H then
		return
	end
	isHudVisible(not isHudVisible())
end)

task.spawn(PlacedBlocks.start)
BlockPlacer.start()
