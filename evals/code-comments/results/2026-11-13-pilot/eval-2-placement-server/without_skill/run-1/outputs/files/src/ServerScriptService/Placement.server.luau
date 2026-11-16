--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
local PlacementRules = require(ReplicatedStorage.Shared.PlacementRules)

local MAX_BLOCKS_PER_PLAYER = 150
local PLACE_COOLDOWN = 0.1 -- seconds

local placeBlock = Instance.new("RemoteEvent")
placeBlock.Name = "PlaceBlock"
placeBlock.Parent = ReplicatedStorage

local removeBlock = Instance.new("RemoteEvent")
removeBlock.Name = "RemoveBlock"
removeBlock.Parent = ReplicatedStorage

local blocksFolder = Instance.new("Folder")
blocksFolder.Name = "PlacedBlocks"
blocksFolder.Parent = workspace

type PlayerBlocks = {
	parts: { [BasePart]: true },
	count: number,
}

local blocksByPlayer: { [Player]: PlayerBlocks } = {}
local ownerByPart: { [BasePart]: Player } = {}
local lastPlaceTime: { [Player]: number } = {}

local function getPlayerBlocks(player: Player): PlayerBlocks
	local entry = blocksByPlayer[player]
	if not entry then
		entry = { parts = {}, count = 0 }
		blocksByPlayer[player] = entry
	end
	return entry
end

local function buildBlock(blockType: BlockTypes.BlockType, center: Vector3, owner: Player): BasePart
	local style = BlockTypes.STYLES[blockType]
	local part = Instance.new("Part")
	part.Name = blockType
	part.Size = Vector3.one * PlacementRules.BLOCK_SIZE
	part.CFrame = CFrame.new(center)
	part.Anchored = true
	part.Color = style.color
	part.Material = style.material
	part.Transparency = style.transparency
	-- Lets clients tell block types and owners apart without asking the server
	part:SetAttribute("BlockType", blockType)
	part:SetAttribute("OwnerUserId", owner.UserId)
	part.Parent = blocksFolder
	return part
end

local function destroyBlock(part: BasePart)
	local owner = ownerByPart[part]
	if owner then
		ownerByPart[part] = nil
		local entry = blocksByPlayer[owner]
		if entry and entry.parts[part] then
			entry.parts[part] = nil
			entry.count -= 1
		end
	end
	part:Destroy()
end

placeBlock.OnServerEvent:Connect(function(player: Player, blockType: unknown, position: unknown)
	-- With deferred signals a request can still be handled after the player has left
	if player.Parent ~= Players then
		return
	end

	-- The cooldown counts from the last request that got past it, so a client that
	-- spams still gets one attempt every PLACE_COOLDOWN seconds
	local now = os.clock()
	local last = lastPlaceTime[player]
	if last and now - last < PLACE_COOLDOWN then
		return
	end
	lastPlaceTime[player] = now

	local entry = getPlayerBlocks(player)
	if entry.count >= MAX_BLOCKS_PER_PLAYER then
		return
	end

	local ok, result = PlacementRules.validate(blockType, position, player.Character, blocksFolder)
	if not ok then
		warn(`Rejected PlaceBlock from {player.Name}: {result}`)
		return
	end

	local part = buildBlock(blockType :: BlockTypes.BlockType, result :: Vector3, player)
	entry.parts[part] = true
	entry.count += 1
	ownerByPart[part] = player
end)

removeBlock.OnServerEvent:Connect(function(player: Player, part: unknown)
	if typeof(part) ~= "Instance" or not part:IsA("BasePart") then
		return
	end
	-- Only parts this script placed are in ownerByPart, so this also rejects the
	-- Baseplate and anything else outside PlacedBlocks
	if ownerByPart[part] ~= player then
		return
	end
	destroyBlock(part)
end)

Players.PlayerRemoving:Connect(function(player: Player)
	local entry = blocksByPlayer[player]
	if entry then
		for part in entry.parts do
			ownerByPart[part] = nil
			part:Destroy()
		end
	end
	blocksByPlayer[player] = nil
	lastPlaceTime[player] = nil
end)
