--[[
	A see-through ghost block that shows where the selected block would go, in the selected block
	type's color. It follows the mouse on the Baseplate grid.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local BlockPlacer = require(script.Parent.BlockPlacer)
local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)

local RAY_LENGTH = 512
local GHOST_TRANSPARENCY = 0.7
local BLOCK_SIZE = BlockTypes.BlockSize

local PlacementPreview = {}

local hasStarted = false
local ghost: Part? = nil

local function snapAxis(value: number): number
	return math.floor(value / BLOCK_SIZE) * BLOCK_SIZE + BLOCK_SIZE / 2
end

local function applyBlockType(name: string)
	local blockType = BlockTypes.ByName[name]
	if ghost and blockType then
		ghost.Color = blockType.Color
		ghost.Material = blockType.Material
	end
end

local function follow()
	local camera = Workspace.CurrentCamera
	if not ghost or not camera then
		return
	end

	ghost.Transparency = if BlockPlacer.isEnabled() then GHOST_TRANSPARENCY else 1

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local exclude: { Instance } = { ghost }
	local character = Players.LocalPlayer.Character
	if character then
		table.insert(exclude, character)
	end
	params.FilterDescendantsInstances = exclude

	local mouse = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mouse.X, mouse.Y)
	local result = Workspace:Raycast(ray.Origin, ray.Direction * RAY_LENGTH, params)
	if not result then
		ghost.Transparency = 1
		return
	end

	local position = result.Position + result.Normal * (BLOCK_SIZE / 2)
	ghost.CFrame = CFrame.new(snapAxis(position.X), snapAxis(position.Y), snapAxis(position.Z))
end

function PlacementPreview.start()
	if hasStarted then
		return
	end
	hasStarted = true

	local part = Instance.new("Part")
	part.Name = "PlacementPreview"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CastShadow = false
	part.Size = Vector3.one * BLOCK_SIZE
	part.Transparency = 1
	part.Parent = Workspace
	ghost = part

	applyBlockType(BlockPlacer.getBlockType())
	BlockPlacer.BlockTypeChanged:Connect(applyBlockType)
	RunService.RenderStepped:Connect(follow)
end

return PlacementPreview
