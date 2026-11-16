--!strict
--[[@description:
	Validates and applies clients' PlaceBlock and RemoveBlock requests.
]]

------------------------------
-- SERVICES --
------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------------------
-- TYPES --
------------------------------
type BlockStyle = {
	color: Color3,
	material: Enum.Material,
	transparency: number,
}

------------------------------
-- VARIABLES --
------------------------------
-- Keep in sync with GRID_SIZE in PlacementClient
local GRID_SIZE = 4

local MAX_HEIGHT = 200

local MAX_REACH = 24 -- studs, from the HumanoidRootPart to the block's center

local MAX_BLOCKS_PER_PLAYER = 200

-- Must stay below the client's 0.2 s click repeat, or held clicks drop blocks
local PLACE_COOLDOWN = 0.15

-- stylua: ignore
local BLOCK_STYLES: { [string]: BlockStyle } = {
	Brick  = { color = Color3.fromRGB(151, 63, 46),   material = Enum.Material.Brick,       transparency = 0 },
	Dirt   = { color = Color3.fromRGB(110, 76, 48),   material = Enum.Material.Ground,      transparency = 0 },
	Grass  = { color = Color3.fromRGB(86, 140, 56),   material = Enum.Material.Grass,       transparency = 0 },
	Window = { color = Color3.fromRGB(170, 210, 230), material = Enum.Material.Glass,       transparency = 0.5 },
	Wood   = { color = Color3.fromRGB(150, 110, 70),  material = Enum.Material.WoodPlanks,  transparency = 0 },
}

local placeBlock = Instance.new("RemoteEvent")
placeBlock.Name = "PlaceBlock"
placeBlock.Parent = ReplicatedStorage

local removeBlock = Instance.new("RemoteEvent")
removeBlock.Name = "RemoveBlock"
removeBlock.Parent = ReplicatedStorage

local blocksFolder = Instance.new("Folder")
blocksFolder.Name = "PlacedBlocks"
blocksFolder.Parent = workspace

local lastPlaceTimes: { [Player]: number } = {}
local blockCounts: { [Player]: number } = {}

------------------------------
-- PRIVATE FUNCTIONS --
------------------------------

local function isFiniteNumber(value: number): boolean
	-- value == value is false only for NaN, which passes every range check
	return value == value and math.abs(value) ~= math.huge
end

local function snapToGrid(position: Vector3): Vector3
	return Vector3.new(
		(math.floor(position.X / GRID_SIZE) + 0.5) * GRID_SIZE,
		(math.floor(position.Y / GRID_SIZE) + 0.5) * GRID_SIZE,
		(math.floor(position.Z / GRID_SIZE) + 0.5) * GRID_SIZE
	)
end

local function isOccupied(center: Vector3): boolean
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { blocksFolder }

	-- Shrink the box so blocks that only share a face don't count as overlapping
	local size = Vector3.one * (GRID_SIZE - 0.1)
	return #workspace:GetPartBoundsInBox(CFrame.new(center), size, params) > 0
end

local function onPlaceBlock(player: Player, blockType: unknown, position: unknown)
	local now = os.clock()
	if now - (lastPlaceTimes[player] or 0) < PLACE_COOLDOWN then
		return
	end
	lastPlaceTimes[player] = now

	if type(blockType) ~= "string" then
		return
	end
	local style = BLOCK_STYLES[blockType]
	if not style then
		return
	end

	if typeof(position) ~= "Vector3" then
		return
	end
	if
		not (
			isFiniteNumber(position.X)
			and isFiniteNumber(position.Y)
			and isFiniteNumber(position.Z)
		)
	then
		return
	end

	local center = snapToGrid(position)
	if center.Y < 0 or center.Y > MAX_HEIGHT then
		return
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end

	-- One extra cell of tolerance: the server's copy of the character lags the client's
	if (root.Position - center).Magnitude > MAX_REACH + GRID_SIZE then
		return
	end

	if (blockCounts[player] or 0) >= MAX_BLOCKS_PER_PLAYER then
		return
	end

	if isOccupied(center) then
		return
	end

	local block = Instance.new("Part")
	block.Name = blockType
	block.Anchored = true
	block.Size = Vector3.one * GRID_SIZE
	block.Position = center
	block.Color = style.color
	block.Material = style.material
	block.Transparency = style.transparency
	block:SetAttribute("OwnerId", player.UserId)
	block.Parent = blocksFolder

	blockCounts[player] = (blockCounts[player] or 0) + 1
end

local function onRemoveBlock(player: Player, block: unknown)
	if typeof(block) ~= "Instance" or not block:IsA("BasePart") then
		return
	end
	-- The client can send any instance, so check it's one of ours and theirs
	if block.Parent ~= blocksFolder or block:GetAttribute("OwnerId") ~= player.UserId then
		return
	end

	block:Destroy()
	blockCounts[player] = math.max((blockCounts[player] or 1) - 1, 0)
end

local function onPlayerRemoving(player: Player)
	-- TODO: save each player's blocks with DataStoreService so they persist between sessions
	for _, block in blocksFolder:GetChildren() do
		if block:GetAttribute("OwnerId") == player.UserId then
			block:Destroy()
		end
	end

	lastPlaceTimes[player] = nil
	blockCounts[player] = nil
end

------------------------------
-- MAIN --
------------------------------
placeBlock.OnServerEvent:Connect(onPlaceBlock)
removeBlock.OnServerEvent:Connect(onRemoveBlock)
Players.PlayerRemoving:Connect(onPlayerRemoving)
