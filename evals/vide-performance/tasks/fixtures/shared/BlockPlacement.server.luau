--[[
	Places blocks for players. Clients fire PlaceBlock with a block type name and the position of
	the grid cell they want filled; the server checks both before placing anything.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)

local BLOCK_SIZE = BlockTypes.BlockSize
-- How far from the player's character a block may be placed, in studs.
local MAX_REACH = 64
-- Shortest time between two placements by one player, in seconds.
local MIN_INTERVAL = 0.1

local placeBlock = Instance.new("RemoteEvent")
placeBlock.Name = "PlaceBlock"
placeBlock.Parent = ReplicatedStorage

local blocksFolder = Instance.new("Folder")
blocksFolder.Name = "Blocks"
blocksFolder.Parent = Workspace

local lastPlacedAt: { [Player]: number } = {}
local occupied: { [Vector3]: boolean } = {}

local function snapAxis(value: number): number
	return math.floor(value / BLOCK_SIZE) * BLOCK_SIZE + BLOCK_SIZE / 2
end

local function snapToCell(position: Vector3): Vector3
	return Vector3.new(snapAxis(position.X), snapAxis(position.Y), snapAxis(position.Z))
end

local function onPlaceBlock(player: Player, blockTypeName: unknown, position: unknown)
	if typeof(blockTypeName) ~= "string" or typeof(position) ~= "Vector3" then
		return
	end
	-- NaN is the only value not equal to itself.
	if position ~= position then
		return
	end

	local blockType = BlockTypes.ByName[blockTypeName]
	if not blockType then
		return
	end

	local now = os.clock()
	if now - (lastPlacedAt[player] or 0) < MIN_INTERVAL then
		return
	end

	local character = player.Character
	local rootPart = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not rootPart or not rootPart:IsA("BasePart") then
		return
	end

	local cell = snapToCell(position)
	if cell.Y < 0 or occupied[cell] then
		return
	end
	if (cell - rootPart.Position).Magnitude > MAX_REACH then
		return
	end

	lastPlacedAt[player] = now
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
end

placeBlock.OnServerEvent:Connect(onPlaceBlock)

Players.PlayerRemoving:Connect(function(player: Player)
	lastPlacedAt[player] = nil
end)
