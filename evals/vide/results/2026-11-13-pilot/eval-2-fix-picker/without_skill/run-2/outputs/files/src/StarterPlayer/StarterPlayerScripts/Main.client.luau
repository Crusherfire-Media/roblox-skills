local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local BlockPicker = require(script.Parent.BlockPicker)
local BlockPlacer = require(script.Parent.BlockPlacer)
local Vide = require(ReplicatedStorage.Packages.Vide)

local cleanup = Vide.cleanup
local create = Vide.create
local root = Vide.root
local source = Vide.source

local localPlayer = Players.LocalPlayer

local selected = source(BlockPlacer.getBlockType())
BlockPlacer.BlockTypeChanged:Connect(function(name: string)
	selected(name)
end)

-- Wait here rather than inside root(): Vide scopes must not yield.
local playerGui = localPlayer:WaitForChild("PlayerGui")

local destroyPicker: (() -> ())? = nil

local function openPicker()
	if destroyPicker then
		return
	end

	destroyPicker = root(function()
		local gui = create("ScreenGui")({
			Name = "BlockPickerGui",
			ResetOnSpawn = false,

			BlockPicker({
				Selected = selected,
				Select = BlockPlacer.setBlockType,
			}),
		})
		-- Vide does not destroy instances it created when a root is destroyed, so do it here.
		cleanup(gui)
		gui.Parent = playerGui
		return gui
	end)
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
