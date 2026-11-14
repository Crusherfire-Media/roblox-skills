--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BlockTypes = require(Shared:WaitForChild("BlockTypes"))
local PlacementRules = require(Shared:WaitForChild("PlacementRules"))

local MAX_BLOCKS_PER_PLAYER = 150
local PLACE_COOLDOWN = 0.1 -- seconds between PlaceBlock requests from one player

local placeBlockEvent = Instance.new("RemoteEvent")
placeBlockEvent.Name = "PlaceBlock"
placeBlockEvent.Parent = ReplicatedStorage

local removeBlockEvent = Instance.new("RemoteEvent")
removeBlockEvent.Name = "RemoveBlock"
removeBlockEvent.Parent = ReplicatedStorage

local blocksFolder = Instance.new("Folder")
blocksFolder.Name = "PlacedBlocks"
blocksFolder.Parent = workspace

-- Ownership lives on the server only, so a client can't claim a block by editing an attribute
local ownerOf: { [BasePart]: Player } = {}
local blocksOf: { [Player]: { [BasePart]: true } } = {}
local blockCount: { [Player]: number } = {}
local lastPlaceTime: { [Player]: number } = {}

local function forgetBlock(part: BasePart)
	local owner = ownerOf[part]
	if not owner then
		return
	end
	ownerOf[part] = nil
	local owned = blocksOf[owner]
	if owned and owned[part] then
		owned[part] = nil
		blockCount[owner] -= 1
	end
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
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	-- For the client/UI to read; the server never trusts it
	part:SetAttribute("OwnerUserId", owner.UserId)
	part.Parent = blocksFolder
	return part
end

placeBlockEvent.OnServerEvent:Connect(function(player: Player, blockType: unknown, position: unknown)
	local owned = blocksOf[player]
	if not owned then
		return -- player is leaving or hasn't been set up
	end

	local now = os.clock()
	local last = lastPlaceTime[player]
	if last and now - last < PLACE_COOLDOWN then
		return
	end
	lastPlaceTime[player] = now

	if blockCount[player] >= MAX_BLOCKS_PER_PLAYER then
		return
	end

	local ok, result = PlacementRules.validate(blockType, position, player.Character, blocksFolder)
	if not ok then
		return
	end

	local part = buildBlock(blockType :: BlockTypes.BlockType, result :: Vector3, player)
	ownerOf[part] = player
	owned[part] = true
	blockCount[player] += 1
	-- Keeps the tables and count right if the block is destroyed some other way
	part.Destroying:Connect(function()
		forgetBlock(part)
	end)
end)

removeBlockEvent.OnServerEvent:Connect(function(player: Player, part: unknown)
	if typeof(part) ~= "Instance" or not part:IsA("BasePart") then
		return
	end
	-- Parts the server didn't place have no owner entry, so this also rejects non-blocks
	if ownerOf[part] ~= player then
		return
	end
	forgetBlock(part)
	part:Destroy()
end)

local function onPlayerAdded(player: Player)
	blocksOf[player] = {}
	blockCount[player] = 0
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

Players.PlayerRemoving:Connect(function(player: Player)
	local owned = blocksOf[player]
	blocksOf[player] = nil
	blockCount[player] = nil
	lastPlaceTime[player] = nil
	if owned then
		for part in owned do
			ownerOf[part] = nil
			part:Destroy()
		end
	end
end)
