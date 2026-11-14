--!strict
--@author: Crusherfire
--@date: 2026-11-13
--[[@description:
	Server side of block placement. Creates the PlaceBlock and RemoveBlock
	remotes, builds validated blocks in Workspace.PlacedBlocks, lets players
	remove only their own blocks, and clears a player's blocks when they leave.
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
type PlayerState = {
	blocks: { [BasePart]: true },
	blockCount: number,
	lastPlaceTime: number,
}

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

const placedBlocks = Instance.new("Folder")
placedBlocks.Name = "PlacedBlocks"
placedBlocks.Parent = workspace

-- Handlers ignore players with no state, because with deferred signals a
-- remote event can still run after PlayerRemoving has cleaned up.
const playerStates: { [Player]: PlayerState? } = {}
const blockOwners: { [BasePart]: Player? } = {}

------------------------------
-- PRIVATE FUNCTIONS --
------------------------------

local function createBlock(blockType: BlockTypes.BlockType, center: Vector3): BasePart
	const style = BlockTypes.STYLES[blockType]
	const block = Instance.new("Part")
	block.Name = blockType
	block.Size = Vector3.one * PlacementRules.BLOCK_SIZE
	block.CFrame = CFrame.new(center)
	block.Anchored = true
	block.Color = style.color
	block.Material = style.material
	block.Transparency = style.transparency
	block.Parent = placedBlocks
	return block
end

local function onPlaceBlock(player: Player, blockType: unknown, position: unknown)
	const state = playerStates[player]
	if not state then
		return
	end

	const now = os.clock()
	if now - state.lastPlaceTime < PLACE_COOLDOWN then
		return
	end
	state.lastPlaceTime = now

	if state.blockCount >= MAX_BLOCKS_PER_PLAYER then
		return
	end

	const isValid, result =
		PlacementRules.validate(blockType, position, player.Character, placedBlocks)
	if not isValid then
		return
	end

	const block = createBlock(blockType :: BlockTypes.BlockType, result :: Vector3)
	state.blocks[block] = true
	state.blockCount += 1
	blockOwners[block] = player
end

local function onRemoveBlock(player: Player, block: unknown)
	const state = playerStates[player]
	if not state then
		return
	end
	if typeof(block) ~= "Instance" or not block:IsA("BasePart") then
		return
	end
	if blockOwners[block] ~= player then
		return
	end

	blockOwners[block] = nil
	state.blocks[block] = nil
	state.blockCount -= 1
	block:Destroy()
end

local function onPlayerAdded(player: Player)
	playerStates[player] = {
		blocks = {},
		blockCount = 0,
		lastPlaceTime = -math.huge,
	}
end

local function onPlayerRemoving(player: Player)
	const state = playerStates[player]
	if not state then
		return
	end

	playerStates[player] = nil
	for block in state.blocks do
		blockOwners[block] = nil
		block:Destroy()
	end
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
