local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local BlockPlacer = require(script.Parent.BlockPlacer)
local PlacedList = require(script.Parent.PlacedList)
local Vide = require(ReplicatedStorage.Packages.Vide)

local create = Vide.create
local mount = Vide.mount
local source = Vide.source

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local placed = source({} :: { PlacedList.PlacedBlock })
local isListOpen = source(false)
local nextId = 1

local function app()
	return create("ScreenGui")({
		Name = "PlacedListGui",

		PlacedList({
			Placed = placed,
			IsOpen = isListOpen,
		}),
	})
end

mount(app, playerGui)

-- L opens and closes the placed blocks list.
UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
	if gameProcessedEvent or input.KeyCode ~= Enum.KeyCode.L then
		return
	end
	isListOpen(not isListOpen())
end)

local blockPlaced = ReplicatedStorage:WaitForChild("BlockPlaced") :: RemoteEvent
blockPlaced.OnClientEvent:Connect(function(blockTypeName: string, position: Vector3)
	local nextPlaced = table.clone(placed())
	table.insert(nextPlaced, {
		Id = nextId,
		BlockTypeName = blockTypeName,
		Position = position,
		PlacedAt = os.clock(),
	})
	nextId += 1
	placed(nextPlaced)
end)

BlockPlacer.start()
