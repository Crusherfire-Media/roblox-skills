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
local mount = Vide.mount
local source = Vide.source

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local selected = source(BlockPlacer.getBlockType())
BlockPlacer.BlockTypeChanged:Connect(function(name: string)
	selected(name)
end)

local destroyPicker: (() -> ())? = nil

local function pickerGui()
	local gui = create("ScreenGui")({
		Name = "BlockPickerGui",

		BlockPicker({
			Selected = selected,
			Select = BlockPlacer.setBlockType,
		}),
	})
	-- Destroying a mount's scope leaves its root instance parented.
	cleanup(gui)

	return gui
end

local function openPicker()
	if destroyPicker then
		return
	end
	destroyPicker = mount(pickerGui, playerGui)
end

local function closePicker()
	if destroyPicker then
		destroyPicker()
		destroyPicker = nil
	end
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
