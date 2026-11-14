--!strict
const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")

const BlockTypes = require("@game/ReplicatedStorage/Shared/BlockTypes")
const PlacementRules = require("@game/ReplicatedStorage/Shared/PlacementRules")

const MAX_BLOCKS_PER_PLAYER = 150
const PLACE_INTERVAL = 0.1 -- seconds

const placeBlockRemote = Instance.new("RemoteEvent")
placeBlockRemote.Name = "PlaceBlock"
placeBlockRemote.Parent = ReplicatedStorage

const removeBlockRemote = Instance.new("RemoteEvent")
removeBlockRemote.Name = "RemoveBlock"
removeBlockRemote.Parent = ReplicatedStorage

const placedBlocks = Instance.new("Folder")
placedBlocks.Name = "PlacedBlocks"
placedBlocks.Parent = workspace

const ownerByBlock: { [Instance]: Player? } = {}
const blocksByPlayer: { [Player]: { [BasePart]: true }? } = {}
const blockCounts: { [Player]: number? } = {}
const lastPlaceTimes: { [Player]: number? } = {}

local function buildBlock(blockType: BlockTypes.BlockType, center: Vector3): BasePart
	const style = BlockTypes.STYLES[blockType]
	const block = Instance.new("Part")
	block.Name = blockType
	block.Anchored = true
	block.Size = Vector3.one * PlacementRules.BLOCK_SIZE
	block.Position = center
	block.Color = style.color
	block.Material = style.material
	block.Transparency = style.transparency
	return block
end

local function onPlaceBlock(player: Player, blockType: unknown, position: unknown)
	const now = os.clock()
	const lastPlaceTime = lastPlaceTimes[player]
	if lastPlaceTime and now - lastPlaceTime < PLACE_INTERVAL then
		return
	end
	-- Set only by requests that get past the throttle, so a client firing
	-- faster than the interval still gets one request through per interval
	lastPlaceTimes[player] = now

	const blockCount = blockCounts[player] or 0
	if blockCount >= MAX_BLOCKS_PER_PLAYER then
		return
	end

	const isValid, result =
		PlacementRules.validate(blockType, position, player.Character, placedBlocks)
	if not isValid or typeof(result) ~= "Vector3" then
		return
	end

	const block = buildBlock(blockType :: BlockTypes.BlockType, result)
	block:SetAttribute("OwnerUserId", player.UserId)
	block.Parent = placedBlocks

	ownerByBlock[block] = player
	blockCounts[player] = blockCount + 1
	const ownedBlocks = blocksByPlayer[player] or {}
	blocksByPlayer[player] = ownedBlocks
	ownedBlocks[block] = true
end

local function onRemoveBlock(player: Player, block: unknown)
	if
		typeof(block) ~= "Instance"
		or ownerByBlock[block] ~= player
		or not block:IsA("BasePart")
	then
		return
	end

	ownerByBlock[block] = nil
	blockCounts[player] = (blockCounts[player] or 1) - 1
	const ownedBlocks = blocksByPlayer[player]
	if ownedBlocks then
		ownedBlocks[block] = nil
	end
	block:Destroy()
end

local function onPlayerRemoving(player: Player)
	const ownedBlocks = blocksByPlayer[player]
	if ownedBlocks then
		for block in ownedBlocks do
			ownerByBlock[block] = nil
			block:Destroy()
		end
	end

	blocksByPlayer[player] = nil
	blockCounts[player] = nil
	lastPlaceTimes[player] = nil
end

placeBlockRemote.OnServerEvent:Connect(onPlaceBlock)
removeBlockRemote.OnServerEvent:Connect(onRemoveBlock)
Players.PlayerRemoving:Connect(onPlayerRemoving)
