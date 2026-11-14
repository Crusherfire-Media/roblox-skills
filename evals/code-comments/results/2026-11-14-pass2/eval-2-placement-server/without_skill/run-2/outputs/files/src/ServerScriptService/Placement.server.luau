--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BlockTypes = require(Shared:WaitForChild("BlockTypes"))
local PlacementRules = require(Shared:WaitForChild("PlacementRules"))

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

-- Ownership lives on the server only, so a client can't claim a block by editing its copy
local ownerOf: { [BasePart]: Player } = {}
local blockCount: { [Player]: number } = {}
local lastPlaceTime: { [Player]: number } = {}

local function buildBlock(blockType: BlockTypes.BlockType, center: Vector3, owner: Player): Part
	local style = BlockTypes.STYLES[blockType]
	local part = Instance.new("Part")
	part.Name = blockType
	part.Size = Vector3.one * PlacementRules.BLOCK_SIZE
	part.CFrame = CFrame.new(center)
	part.Anchored = true
	part.Color = style.color
	part.Material = style.material
	part.Transparency = style.transparency
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	-- Lets the client UI tell which blocks it can remove; not trusted by the server
	part:SetAttribute("OwnerUserId", owner.UserId)
	return part
end

local function trackBlock(part: BasePart, owner: Player)
	ownerOf[part] = owner
	blockCount[owner] = (blockCount[owner] or 0) + 1

	-- Covers every way a block can disappear, including other scripts destroying it
	part.Destroying:Once(function()
		if ownerOf[part] ~= owner then
			return
		end
		ownerOf[part] = nil
		local count = blockCount[owner]
		if count then
			blockCount[owner] = math.max(count - 1, 0)
		end
	end)
end

placeBlock.OnServerEvent:Connect(function(player: Player, blockType: unknown, position: unknown)
	local now = os.clock()
	local last = lastPlaceTime[player]
	if last and now - last < PLACE_COOLDOWN then
		return
	end
	lastPlaceTime[player] = now

	if (blockCount[player] or 0) >= MAX_BLOCKS_PER_PLAYER then
		return
	end

	local ok, result = PlacementRules.validate(blockType, position, player.Character, blocksFolder)
	if not ok then
		warn(`Rejected placement from {player.Name}: {result}`)
		return
	end

	local part = buildBlock(blockType :: BlockTypes.BlockType, result :: Vector3, player)
	trackBlock(part, player)
	part.Parent = blocksFolder
end)

removeBlock.OnServerEvent:Connect(function(player: Player, block: unknown)
	if typeof(block) ~= "Instance" or not block:IsA("BasePart") then
		return
	end
	if ownerOf[block] ~= player then
		return
	end
	block:Destroy()
end)

Players.PlayerRemoving:Connect(function(player: Player)
	for part, owner in ownerOf do
		if owner == player then
			part:Destroy()
		end
	end
	blockCount[player] = nil
	lastPlaceTime[player] = nil
end)
