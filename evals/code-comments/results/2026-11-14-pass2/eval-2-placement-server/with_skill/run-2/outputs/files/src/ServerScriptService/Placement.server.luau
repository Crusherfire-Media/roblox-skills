--!strict
const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")

const BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
const PlacementRules = require(ReplicatedStorage.Shared.PlacementRules)

const MAX_BLOCKS_PER_PLAYER = 150
const PLACE_COOLDOWN = 0.1 -- seconds

local blockOwners: { [BasePart]: Player? } = {}
local blockCounts: { [Player]: number? } = {}
local lastPlaceTimes: { [Player]: number? } = {}

local function createRemote(name: string): RemoteEvent
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = ReplicatedStorage
	return remote
end

const placeBlockRemote = createRemote("PlaceBlock")
const removeBlockRemote = createRemote("RemoveBlock")

const blocksFolder = Instance.new("Folder")
blocksFolder.Name = "PlacedBlocks"
blocksFolder.Parent = workspace

local function buildBlock(blockType: BlockTypes.BlockType, center: Vector3, owner: Player): Part
	local style = BlockTypes.STYLES[blockType]
	local block = Instance.new("Part")
	block.Name = blockType
	block.Anchored = true
	block.Size = Vector3.one * PlacementRules.BLOCK_SIZE
	block.CFrame = CFrame.new(center)
	block.Color = style.color
	block.Material = style.material
	block.Transparency = style.transparency
	block:SetAttribute("OwnerUserId", owner.UserId)
	block.Parent = blocksFolder
	return block
end

local function removeBlock(block: BasePart)
	local owner = blockOwners[block]
	if owner then
		blockOwners[block] = nil
		blockCounts[owner] = (blockCounts[owner] or 1) - 1
	end
	block:Destroy()
end

local function onPlaceBlock(player: Player, blockType: unknown, position: unknown)
	-- A request queued just before the player left would otherwise leave
	-- entries behind after onPlayerRemoving cleared them
	if player.Parent ~= Players then
		return
	end

	const now = os.clock()
	const lastPlaceTime = lastPlaceTimes[player]
	if lastPlaceTime and now - lastPlaceTime < PLACE_COOLDOWN then
		return
	end
	lastPlaceTimes[player] = now

	const count = blockCounts[player] or 0
	if count >= MAX_BLOCKS_PER_PLAYER then
		return
	end

	const isValid, result =
		PlacementRules.validate(blockType, position, player.Character, blocksFolder)
	if not isValid or typeof(result) ~= "Vector3" then
		return
	end

	const block = buildBlock(blockType :: BlockTypes.BlockType, result, player)
	blockOwners[block] = player
	blockCounts[player] = count + 1
end

local function onRemoveBlock(player: Player, block: unknown)
	if typeof(block) ~= "Instance" or not block:IsA("BasePart") then
		return
	end
	if blockOwners[block] ~= player then
		return
	end

	removeBlock(block)
end

local function onPlayerRemoving(player: Player)
	for block, owner in blockOwners do
		if owner == player then
			removeBlock(block)
		end
	end
	blockCounts[player] = nil
	lastPlaceTimes[player] = nil
end

placeBlockRemote.OnServerEvent:Connect(onPlaceBlock)
removeBlockRemote.OnServerEvent:Connect(onRemoveBlock)
Players.PlayerRemoving:Connect(onPlayerRemoving)
