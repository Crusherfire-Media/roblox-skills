--!strict
--@author: Crusherfire
--@date: 2026-11-13
--[[@description:
	Server side of block placement. Creates the PlaceBlock and RemoveBlock
	remotes, places validated blocks into Workspace.PlacedBlocks, tracks who
	owns each block, and clears a player's blocks when they leave.
]]

------------------------------
-- SERVICES --
------------------------------
const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------------------
-- DEPENDENCIES --
------------------------------
const BlockTypes = require("@game/ReplicatedStorage/Shared/BlockTypes")
const PlacementRules = require("@game/ReplicatedStorage/Shared/PlacementRules")

------------------------------
-- TYPES --
------------------------------
type BlockType = BlockTypes.BlockType

------------------------------
-- VARIABLES --
------------------------------
const MAX_BLOCKS_PER_PLAYER = 150
const PLACE_COOLDOWN = 0.1 -- seconds

const placeBlockRemote = Instance.new("RemoteEvent")
placeBlockRemote.Name = "PlaceBlock"
placeBlockRemote.Parent = ReplicatedStorage

const removeBlockRemote = Instance.new("RemoteEvent")
removeBlockRemote.Name = "RemoveBlock"
removeBlockRemote.Parent = ReplicatedStorage

const blocksFolder = Instance.new("Folder")
blocksFolder.Name = "PlacedBlocks"
blocksFolder.Parent = workspace

-- Entries exist only between PlayerAdded and PlayerRemoving, so a request that
-- arrives after a player left cannot recreate their state.
local blocksByPlayer: { [Player]: { BasePart }? } = {}
local lastPlaceTimeByPlayer: { [Player]: number? } = {}

local ownerByBlock: { [BasePart]: Player? } = {}

------------------------------
-- PRIVATE FUNCTIONS --
------------------------------

local function createBlock(blockType: BlockType, center: Vector3): BasePart
	const style = BlockTypes.STYLES[blockType]

	local block = Instance.new("Part")
	block.Name = blockType
	block.Size = Vector3.one * PlacementRules.BLOCK_SIZE
	block.CFrame = CFrame.new(center)
	block.Anchored = true
	block.Color = style.color
	block.Material = style.material
	block.Transparency = style.transparency
	block.Parent = blocksFolder
	return block
end

local function onPlaceBlock(player: Player, blockType: unknown, position: unknown)
	local blocks = blocksByPlayer[player]
	if not blocks then
		return
	end

	const now = os.clock()
	local lastPlaceTime = lastPlaceTimeByPlayer[player]
	if lastPlaceTime and now - lastPlaceTime < PLACE_COOLDOWN then
		return
	end
	-- Only accepted requests reset the cooldown; otherwise a client firing
	-- slightly faster than the cooldown would be locked out for good.
	lastPlaceTimeByPlayer[player] = now

	if #blocks >= MAX_BLOCKS_PER_PLAYER then
		return
	end

	local isValid, result =
		PlacementRules.validate(blockType, position, player.Character, blocksFolder)
	if not isValid or typeof(result) ~= "Vector3" then
		return
	end

	local block = createBlock(blockType :: BlockType, result)
	table.insert(blocks, block)
	ownerByBlock[block] = player
end

local function onRemoveBlock(player: Player, block: unknown)
	if typeof(block) ~= "Instance" then
		return
	end

	-- Only parts this script placed are keys, so the lookup also rejects any
	-- other instance the client sends.
	const placedBlock = block :: BasePart
	if ownerByBlock[placedBlock] ~= player then
		return
	end

	local blocks = blocksByPlayer[player]
	if blocks then
		local index = table.find(blocks, placedBlock)
		if index then
			blocks[index] = blocks[#blocks]
			blocks[#blocks] = nil
		end
	end

	ownerByBlock[placedBlock] = nil
	placedBlock:Destroy()
end

local function onPlayerAdded(player: Player)
	blocksByPlayer[player] = {}
end

local function onPlayerRemoving(player: Player)
	local blocks = blocksByPlayer[player]
	if blocks then
		for _, block in blocks do
			ownerByBlock[block] = nil
			block:Destroy()
		end
	end

	blocksByPlayer[player] = nil
	lastPlaceTimeByPlayer[player] = nil
end

------------------------------
-- MAIN --
------------------------------
placeBlockRemote.OnServerEvent:Connect(onPlaceBlock)
removeBlockRemote.OnServerEvent:Connect(onRemoveBlock)

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end
