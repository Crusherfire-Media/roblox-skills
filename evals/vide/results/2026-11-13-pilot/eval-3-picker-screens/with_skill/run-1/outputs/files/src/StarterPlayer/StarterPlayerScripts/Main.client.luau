const Players = game:GetService("Players")
const RunService = game:GetService("RunService")

const Vide = require("@game/ReplicatedStorage/Packages/Vide")

const BlockPicker = require("./BlockPicker")
const BlockPlacer = require("./BlockPlacer")
const Screen = require("./UI/Screen")
const screenGui = require("./UI/screenGui")

Vide.strict = RunService:IsStudio()

const mount = Vide.mount
const source = Vide.source

const localPlayer = Players.LocalPlayer
const playerGui = localPlayer:WaitForChild("PlayerGui")

const selected = source(BlockPlacer.getBlockType())
BlockPlacer.BlockTypeChanged:Connect(function(name: string)
	selected(name)
end)

local function pickerLayout(): BlockPicker.Layout
	return if Screen.isTouchLayout() then "Row" else "Column"
end

local function app()
	return screenGui({
		Name = "BlockPickerGui",
		Children = {
			BlockPicker({
				Layout = pickerLayout,
				Selected = selected,
				Select = BlockPlacer.setBlockType,
			}),
		},
	})
end

mount(app, playerGui)

BlockPlacer.start()
