--[[
	Places blocks for players. Clients fire PlaceBlock with a block type name and a position;
	PlacementRules decides whether the placement is allowed.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
local PlacementRules = require(script.Parent.Placement.PlacementRules)

local placeBlock = Instance.new("RemoteEvent")
placeBlock.Name = "PlaceBlock"
placeBlock.Parent = ReplicatedStorage

local blocksFolder = Instance.new("Folder")
blocksFolder.Name = "Blocks"
blocksFolder.Parent = Workspace

local occupied: { [Vector3]: boolean } = {}

local function onPlaceBlock(player: Player, blockTypeName: unknown, position: unknown)
	local character = player.Character
	local rootPart = if character then character:FindFirstChild("HumanoidRootPart") else nil
	local rootPosition = if rootPart and rootPart:IsA("BasePart") then rootPart.Position else nil

	local ok, result = PlacementRules.validate(blockTypeName, position, rootPosition, occupied)
	if not ok or typeof(result) ~= "Vector3" or typeof(blockTypeName) ~= "string" then
		return
	end

	local blockType = BlockTypes.ByName[blockTypeName]
	occupied[result] = true

	local part = Instance.new("Part")
	part.Name = blockType.Name
	part.Anchored = true
	part.Size = Vector3.one * BlockTypes.BlockSize
	part.CFrame = CFrame.new(result)
	part.Color = blockType.Color
	part.Material = blockType.Material
	part.Transparency = blockType.Transparency
	part.Parent = blocksFolder
end

placeBlock.OnServerEvent:Connect(onPlaceBlock)
