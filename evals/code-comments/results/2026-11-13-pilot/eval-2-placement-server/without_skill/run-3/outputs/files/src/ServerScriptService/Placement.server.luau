--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BlockTypes = require(Shared:WaitForChild("BlockTypes"))
local PlacementRules = require(Shared:WaitForChild("PlacementRules"))

local MAX_BLOCKS_PER_PLAYER = 150
local PLACE_COOLDOWN = 0.1 -- seconds

local placeBlockEvent = Instance.new("RemoteEvent")
placeBlockEvent.Name = "PlaceBlock"
placeBlockEvent.Parent = ReplicatedStorage

local removeBlockEvent = Instance.new("RemoteEvent")
removeBlockEvent.Name = "RemoveBlock"
removeBlockEvent.Parent = ReplicatedStorage

local blocksFolder = Instance.new("Folder")
blocksFolder.Name = "PlacedBlocks"
blocksFolder.Parent = workspace

-- Ownership lives on the server only. The OwnerUserId attribute on each part is for the
-- client UI and is never trusted here.
local ownerByBlock: { [BasePart]: Player } = {}
local blocksByPlayer: { [Player]: { [BasePart]: true } } = {}
local blockCount: { [Player]: number } = {}
local lastPlaceTime: { [Player]: number } = {}

local function getPlayerBlocks(player: Player): { [BasePart]: true }
	local blocks = blocksByPlayer[player]
	if not blocks then
		blocks = {}
		blocksByPlayer[player] = blocks
	end
	return blocks
end

local function forgetBlock(block: BasePart)
	local owner = ownerByBlock[block]
	if not owner then
		return
	end
	ownerByBlock[block] = nil
	local blocks = blocksByPlayer[owner]
	if blocks and blocks[block] then
		blocks[block] = nil
		blockCount[owner] = math.max((blockCount[owner] or 1) - 1, 0)
	end
end

local function createBlock(
	blockType: BlockTypes.BlockType,
	center: Vector3,
	owner: Player
): BasePart
	local style = BlockTypes.STYLES[blockType]
	local part = Instance.new("Part")
	part.Name = blockType
	part.Size = Vector3.one * PlacementRules.BLOCK_SIZE
	part.CFrame = CFrame.new(center)
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Color = style.color
	part.Material = style.material
	part.Transparency = style.transparency
	part:SetAttribute("BlockType", blockType)
	part:SetAttribute("OwnerUserId", owner.UserId)

	ownerByBlock[part] = owner
	getPlayerBlocks(owner)[part] = true
	blockCount[owner] = (blockCount[owner] or 0) + 1

	-- Keep the bookkeeping right if the block is destroyed by anything other than RemoveBlock
	part.Destroying:Connect(function()
		forgetBlock(part)
	end)

	part.Parent = blocksFolder
	return part
end

placeBlockEvent.OnServerEvent:Connect(
	function(player: Player, blockType: unknown, position: unknown)
		local now = os.clock()
		local last = lastPlaceTime[player]
		if last and now - last < PLACE_COOLDOWN then
			return
		end
		lastPlaceTime[player] = now

		if (blockCount[player] or 0) >= MAX_BLOCKS_PER_PLAYER then
			return
		end

		local ok, result =
			PlacementRules.validate(blockType, position, player.Character, blocksFolder)
		if not ok then
			-- Rejections are routine (out of reach, occupied cell), so keep this quiet
			return
		end

		createBlock(blockType :: BlockTypes.BlockType, result :: Vector3, player)
	end
)

removeBlockEvent.OnServerEvent:Connect(function(player: Player, block: unknown)
	if typeof(block) ~= "Instance" or not block:IsA("BasePart") then
		return
	end
	-- Only blocks this script created are in ownerByBlock, so this also rejects arbitrary parts
	if ownerByBlock[block] ~= player then
		return
	end
	forgetBlock(block)
	block:Destroy()
end)

Players.PlayerRemoving:Connect(function(player: Player)
	local blocks = blocksByPlayer[player]
	if blocks then
		for block in blocks do
			ownerByBlock[block] = nil
			block:Destroy()
		end
	end
	blocksByPlayer[player] = nil
	blockCount[player] = nil
	lastPlaceTime[player] = nil
end)
