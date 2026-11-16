local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local BlockPlacer = require(script.Parent.BlockPlacer)
local Hud = require(script.Parent.UI.Hud)
local Vide = require(ReplicatedStorage.Packages.Vide)

local create = Vide.create
local mount = Vide.mount
local source = Vide.source

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local selected = source(BlockPlacer.getBlockType())
local buildMode = source(BlockPlacer.isEnabled())
local coins = source(250)

BlockPlacer.BlockTypeChanged:Connect(function(name: string)
	selected(name)
end)

local function setBuildMode(enabled: boolean)
	BlockPlacer.setEnabled(enabled)
	buildMode(enabled)
end

local function openInventory()
	-- The inventory screen is still being built.
	print("inventory opened")
end

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
	if gameProcessedEvent then
		return
	end
	if input.KeyCode == Enum.KeyCode.B then
		setBuildMode(not buildMode())
	elseif input.KeyCode == Enum.KeyCode.I then
		openInventory()
	end
end)

mount(function()
	return create("ScreenGui")({
		Name = "HudGui",

		Hud({
			Selected = selected,
			Select = BlockPlacer.setBlockType,
			BuildMode = buildMode,
			Coins = coins,
			OpenInventory = openInventory,
		}),
	})
end, playerGui)

BlockPlacer.start()
