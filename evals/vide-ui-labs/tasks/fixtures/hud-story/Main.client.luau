local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local BlockPlacer = require(script.Parent.BlockPlacer)
local BuildModeHud = require(script.Parent.BuildModeHud)
local Vide = require(ReplicatedStorage.Packages.Vide)

local create = Vide.create
local mount = Vide.mount
local show = Vide.show
local source = Vide.source

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local isBuildMode = source(false)

local function app()
	return create("ScreenGui")({
		Name = "BuildModeGui",

		show(isBuildMode, BuildModeHud),
	})
end

mount(app, playerGui)

-- B toggles build mode: the HUD shows and clicks place blocks only while it is on.
UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
	if gameProcessedEvent or input.KeyCode ~= Enum.KeyCode.B then
		return
	end
	local isEntering = not isBuildMode()
	BlockPlacer.setEnabled(isEntering)
	isBuildMode(isEntering)
end)

BlockPlacer.setEnabled(false)
BlockPlacer.start()
