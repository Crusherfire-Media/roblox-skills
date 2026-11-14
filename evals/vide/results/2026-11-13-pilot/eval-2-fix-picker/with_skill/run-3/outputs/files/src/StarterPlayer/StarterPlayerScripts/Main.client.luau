local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local BlockPicker = require(script.Parent.BlockPicker)
local BlockPlacer = require(script.Parent.BlockPlacer)
local Vide = require(ReplicatedStorage.Packages.Vide)

Vide.strict = RunService:IsStudio()

local cleanup = Vide.cleanup
local create = Vide.create
local root = Vide.root
local source = Vide.source

local localPlayer = Players.LocalPlayer

local selected = source(BlockPlacer.getBlockType())
BlockPlacer.BlockTypeChanged:Connect(function(name: string)
	selected(name)
end)

local destroyPicker: (() -> ())? = nil

local function closePicker()
	if destroyPicker then
		destroyPicker()
		destroyPicker = nil
	end
end

local function openPicker()
	closePicker()

	local playerGui = localPlayer:WaitForChild("PlayerGui")
	destroyPicker = root(function()
		local gui = create("ScreenGui")({
			Name = "BlockPickerGui",
			Parent = playerGui,

			BlockPicker({
				Selected = selected,
				Select = BlockPlacer.setBlockType,
			}),
		})
		cleanup(gui)
		return gui
	end)
end

-- B toggles build mode: the picker shows and clicks place blocks only while it is on.
UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
	if gameProcessedEvent or input.KeyCode ~= Enum.KeyCode.B then
		return
	end

	local isEntering = not BlockPlacer.isEnabled()
	BlockPlacer.setEnabled(isEntering)
	if isEntering then
		openPicker()
	else
		closePicker()
	end
end)

BlockPlacer.setEnabled(false)
BlockPlacer.start()
