--[[
	Player builds. Each player gets a plot when they join and their saved build is loaded into it.
	Players place blocks with PlaceBlock and remove their own blocks with RemoveBlock. A player's
	plot and blocks are removed when they leave.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
local SavedBuilds = require(script.Parent.SavedBuilds)

local BLOCK_SIZE = BlockTypes.BlockSize
local MAX_PLOTS = 8
-- Distance between plot corners along X, in studs. A full saved build is 200 studs wide.
local PLOT_SPACING = 256
-- How far from the player's character a block may be placed or removed, in studs.
local MAX_REACH = 64
-- Shortest time between two placements by one player, in seconds.
local MIN_INTERVAL = 0.1

local placeBlock = Instance.new("RemoteEvent")
placeBlock.Name = "PlaceBlock"
placeBlock.Parent = ReplicatedStorage

local removeBlock = Instance.new("RemoteEvent")
removeBlock.Name = "RemoveBlock"
removeBlock.Parent = ReplicatedStorage

local plotsFolder = Instance.new("Folder")
plotsFolder.Name = "Plots"
plotsFolder.Parent = Workspace

local occupied: { [Vector3]: boolean } = {}
local lastPlacedAt: { [Player]: number } = {}
local plotSlots: { [number]: Player } = {}
local plotFolders: { [Player]: Folder } = {}

local function snapAxis(value: number): number
	return math.floor(value / BLOCK_SIZE) * BLOCK_SIZE + BLOCK_SIZE / 2
end

local function snapToCell(position: Vector3): Vector3
	return Vector3.new(snapAxis(position.X), snapAxis(position.Y), snapAxis(position.Z))
end

local function getReachableRoot(player: Player, position: Vector3): BasePart?
	local character = player.Character
	local rootPart = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not rootPart or not rootPart:IsA("BasePart") then
		return nil
	end
	if (position - rootPart.Position).Magnitude > MAX_REACH then
		return nil
	end
	return rootPart
end

local function createBlock(
	parent: Instance,
	blockType: BlockTypes.BlockType,
	cell: Vector3,
	ownerId: number,
	placedAt: number
): Part
	local part = Instance.new("Part", parent)
	part.Name = blockType.Name
	part.Anchored = true
	part.Size = Vector3.one * BLOCK_SIZE
	part.CFrame = CFrame.new(cell)
	part.Color = blockType.Color
	part.Material = blockType.Material
	part.Transparency = blockType.Transparency

	local owner = Instance.new("StringValue")
	owner.Name = "Owner"
	owner.Value = tostring(ownerId)
	owner.Parent = part

	local placedAtValue = Instance.new("NumberValue")
	placedAtValue.Name = "PlacedAt"
	placedAtValue.Value = placedAt
	placedAtValue.Parent = part

	return part
end

local function loadBuild(player: Player, plotFolder: Folder, plotCorner: Vector3)
	local savedBlocks = SavedBuilds.load(player.UserId)
	for _, savedBlock in savedBlocks do
		local blockType = BlockTypes.ByName[savedBlock.Type]
		if blockType then
			local cell = snapToCell(plotCorner + savedBlock.Cell * BLOCK_SIZE)
			if not occupied[cell] then
				occupied[cell] = true
				createBlock(plotFolder, blockType, cell, player.UserId, savedBlock.PlacedAt)
			end
		end
	end
end

local function onPlayerAdded(player: Player)
	local slot = nil
	for index = 1, MAX_PLOTS do
		if not plotSlots[index] then
			slot = index
			break
		end
	end
	if not slot then
		warn(`no free plot for {player.Name}`)
		return
	end
	plotSlots[slot] = player

	local plotFolder = Instance.new("Folder")
	plotFolder.Name = tostring(player.UserId)
	plotFolder.Parent = plotsFolder
	plotFolders[player] = plotFolder

	loadBuild(player, plotFolder, Vector3.new((slot - 1) * PLOT_SPACING, 0, 0))
end

local function onPlayerRemoving(player: Player)
	lastPlacedAt[player] = nil

	for slot, owner in plotSlots do
		if owner == player then
			plotSlots[slot] = nil
		end
	end

	local plotFolder = plotFolders[player]
	if not plotFolder then
		return
	end
	plotFolders[player] = nil
	for _, block in plotFolder:GetChildren() do
		if block:IsA("BasePart") then
			occupied[block.Position] = nil
		end
	end
	plotFolder:Destroy()
end

local function onPlaceBlock(player: Player, blockTypeName: unknown, position: unknown)
	if typeof(blockTypeName) ~= "string" or typeof(position) ~= "Vector3" then
		return
	end
	-- NaN is the only value not equal to itself.
	if position ~= position then
		return
	end
	local blockType = BlockTypes.ByName[blockTypeName]
	local plotFolder = plotFolders[player]
	if not blockType or not plotFolder then
		return
	end

	local now = os.clock()
	if now - (lastPlacedAt[player] or 0) < MIN_INTERVAL then
		return
	end

	local cell = snapToCell(position)
	if cell.Y < 0 or occupied[cell] or not getReachableRoot(player, cell) then
		return
	end

	lastPlacedAt[player] = now
	occupied[cell] = true
	createBlock(plotFolder, blockType, cell, player.UserId, os.time())
end

local function onRemoveBlock(player: Player, block: unknown)
	if typeof(block) ~= "Instance" or not block:IsA("BasePart") then
		return
	end
	if not block:IsDescendantOf(plotsFolder) then
		return
	end
	local owner = block:FindFirstChild("Owner")
	if not owner or not owner:IsA("StringValue") or owner.Value ~= tostring(player.UserId) then
		return
	end
	if not getReachableRoot(player, block.Position) then
		return
	end

	occupied[block.Position] = nil
	block:Destroy()
end

placeBlock.OnServerEvent:Connect(onPlaceBlock)
removeBlock.OnServerEvent:Connect(onRemoveBlock)
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end
