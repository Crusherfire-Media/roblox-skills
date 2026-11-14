--[[
	Places blocks for players. Clients fire PlaceBlock with a block type name and a position in
	the grid cell they want filled; the server checks both before placing anything.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local BlockTypes = require("@game/ServerScriptService/Modules/Catalogs/BlockTypes")
local Grid = require("@game/ServerScriptService/Modules/Utilities/Grid")
local PlacementNetwork = require("./PlacementNetwork")

local BLOCK_SIZE = BlockTypes.BlockSize
-- How far from the player's character a block may be placed, in studs.
local MAX_REACH = 64
-- Shortest time between two placements by one player, in seconds.
local MIN_INTERVAL = 0.1

local PlacementServerService = {}

local blockPlaced = Instance.new("BindableEvent")
local placementRejected = Instance.new("BindableEvent")

--[[
	Fires with (player, part) after a block is placed.
]]
PlacementServerService.BlockPlaced = blockPlaced.Event

--[[
	Fires with (player, reason) when a request is refused for a reason the player should see.
]]
PlacementServerService.PlacementRejected = placementRejected.Event

local blocksFolder: Folder? = nil
local lastPlacedAt: { [Player]: number } = {}
local occupied: { [Vector3]: boolean } = {}
local blockCounts: { [Player]: number } = {}
local buildAreas: { BasePart } = {}

local function isInBuildArea(cell: Vector3): boolean
	for _, area in buildAreas do
		local offset = area.CFrame:PointToObjectSpace(cell)
		local halfSize = area.Size / 2
		if math.abs(offset.X) <= halfSize.X and math.abs(offset.Z) <= halfSize.Z then
			return true
		end
	end
	return false
end

local function onPlaceBlock(player: Player, blockTypeName: unknown, position: unknown)
	if typeof(blockTypeName) ~= "string" or typeof(position) ~= "Vector3" then
		return
	end
	-- NaN is the only value not equal to itself.
	if position ~= position or not blocksFolder then
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

	local cell = Grid.snapToCell(position, BLOCK_SIZE)
	if cell.Y < 0 or occupied[cell] then
		return
	end
	if not isInBuildArea(cell) then
		placementRejected:Fire(player, "You can only build on a plot.")
		return
	end
	if (cell - rootPart.Position).Magnitude > MAX_REACH then
		placementRejected:Fire(player, "That spot is too far away.")
		return
	end

	lastPlacedAt[player] = now
	occupied[cell] = true
	blockCounts[player] = (blockCounts[player] or 0) + 1

	local part = Instance.new("Part")
	part.Name = blockType.Name
	part.Anchored = true
	part.Size = Vector3.one * BLOCK_SIZE
	part.CFrame = CFrame.new(cell)
	part.Color = blockType.Color
	part.Material = blockType.Material
	part.Transparency = blockType.Transparency
	part.Parent = blocksFolder

	blockPlaced:Fire(player, part)
end

--[[
	Returns how many blocks the player has placed this session.
]]
function PlacementServerService:GetBlockCount(player: Player): number
	return blockCounts[player] or 0
end

--[[
	Lets players build in the column above the area's footprint. Until an area is added, every
	placement is refused.
]]
function PlacementServerService:AddBuildArea(area: BasePart)
	table.insert(buildAreas, area)
end

--[[
	Removes every placed block.
]]
function PlacementServerService:ClearBlocks()
	if blocksFolder then
		blocksFolder:ClearAllChildren()
	end
	table.clear(occupied)
	table.clear(blockCounts)
end

function PlacementServerService:Init()
	local folder = Instance.new("Folder")
	folder.Name = "Blocks"
	folder.Parent = Workspace
	blocksFolder = folder

	PlacementNetwork.PlaceBlock.OnServerEvent:Connect(onPlaceBlock)
	Players.PlayerRemoving:Connect(function(player: Player)
		lastPlacedAt[player] = nil
		blockCounts[player] = nil
	end)
end

return PlacementServerService
