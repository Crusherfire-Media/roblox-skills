--[[
	Places blocks for players. Clients fire PlaceBlock with a block type name and the position of
	the grid cell they want filled. Each placement uses one block from the player's inventory.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BlockInventory = require(script.Parent.Inventory.BlockInventory)
local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)

local BLOCK_SIZE = BlockTypes.BlockSize
-- What every player starts with. Windows have to be crafted, so new players have none.
local STARTER_KIT = { Brick = 20, Dirt = 20, Grass = 10, Wood = 10 }

local placeBlock = Instance.new("RemoteEvent")
placeBlock.Name = "PlaceBlock"
placeBlock.Parent = ReplicatedStorage

local blocksFolder = Instance.new("Folder")
blocksFolder.Name = "Blocks"
blocksFolder.Parent = Workspace

local inventories: { [Player]: BlockInventory.Inventory } = {}
local occupied: { [Vector3]: boolean } = {}

local function snapToCell(position: Vector3): Vector3
	local function snapAxis(value: number): number
		return (math.floor(value / BLOCK_SIZE) + 0.5) * BLOCK_SIZE
	end
	return Vector3.new(snapAxis(position.X), snapAxis(position.Y), snapAxis(position.Z))
end

local function onPlaceBlock(player: Player, blockTypeName: unknown, position: unknown)
	if typeof(blockTypeName) ~= "string" or typeof(position) ~= "Vector3" then
		return
	end
	local blockType = BlockTypes.ByName[blockTypeName]
	local inventory = inventories[player]
	if not blockType or not inventory then
		return
	end

	local cell = snapToCell(position)
	if cell.Y < 0 or occupied[cell] then
		return
	end
	if not BlockInventory.take(inventory, blockType.Name, 1) then
		return
	end

	occupied[cell] = true
	local part = Instance.new("Part")
	part.Name = blockType.Name
	part.Anchored = true
	part.Size = Vector3.one * BLOCK_SIZE
	part.CFrame = CFrame.new(cell)
	part.Color = blockType.Color
	part.Material = blockType.Material
	part.Transparency = blockType.Transparency
	part.Parent = blocksFolder

	player:SetAttribute(blockType.Name, BlockInventory.count(inventory, blockType.Name))
end

local function onPlayerAdded(player: Player)
	local inventory = BlockInventory.new(STARTER_KIT)
	inventories[player] = inventory
	for _, blockType in BlockTypes.List do
		player:SetAttribute(blockType.Name, BlockInventory.count(inventory, blockType.Name))
	end
end

placeBlock.OnServerEvent:Connect(onPlaceBlock)
Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end
Players.PlayerRemoving:Connect(function(player: Player)
	inventories[player] = nil
end)
