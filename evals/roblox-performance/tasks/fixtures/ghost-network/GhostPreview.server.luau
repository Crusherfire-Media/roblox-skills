--[[
	Ghost previews: every player sees a see-through copy of the block each builder is about to
	place, in the cell under that builder's mouse. Clients report their cursor cell through
	MoveGhost; the server keeps one ghost part per player in Workspace.Ghosts.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)

local GHOST_TRANSPARENCY = 0.6

local moveGhost = Instance.new("RemoteEvent")
moveGhost.Name = "MoveGhost"
moveGhost.Parent = ReplicatedStorage

local ghostsFolder = Instance.new("Folder")
ghostsFolder.Name = "Ghosts"
ghostsFolder.Parent = Workspace

local ghosts: { [Player]: Part } = {}

local function getGhost(player: Player): Part
	local ghost = ghosts[player]
	if ghost then
		return ghost
	end

	ghost = Instance.new("Part")
	ghost.Name = player.Name
	ghost.Anchored = true
	ghost.CanCollide = false
	ghost.CanQuery = false
	ghost.CanTouch = false
	ghost.CastShadow = false
	ghost.Size = Vector3.one * BlockTypes.BlockSize
	ghost.Parent = ghostsFolder
	ghosts[player] = ghost
	return ghost
end

local function onMoveGhost(player: Player, blockTypeName: unknown, cellPosition: unknown)
	local ghost = getGhost(player)

	-- The client sends nil when its mouse isn't over anything it could build on.
	if cellPosition == nil then
		ghost.Transparency = 1
		return
	end
	if typeof(blockTypeName) ~= "string" or typeof(cellPosition) ~= "Vector3" then
		return
	end
	local blockType = BlockTypes.ByName[blockTypeName]
	if not blockType then
		return
	end

	ghost.CFrame = CFrame.new(cellPosition)
	ghost.Color = blockType.Color
	ghost.Material = blockType.Material
	ghost.Transparency = GHOST_TRANSPARENCY
end

moveGhost.OnServerEvent:Connect(onMoveGhost)

Players.PlayerRemoving:Connect(function(player: Player)
	local ghost = ghosts[player]
	if ghost then
		ghost:Destroy()
		ghosts[player] = nil
	end
end)
