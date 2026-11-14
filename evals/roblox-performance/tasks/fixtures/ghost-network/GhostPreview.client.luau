--[[
	Reports the cell under the mouse and the selected block type to the server every frame, so
	everyone's ghost preview follows the builder's cursor.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local BlockPlacer = require(script.Parent.BlockPlacer)
local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)

local RAY_LENGTH = 512
local BLOCK_SIZE = BlockTypes.BlockSize

local localPlayer = Players.LocalPlayer
local moveGhost = ReplicatedStorage:WaitForChild("MoveGhost") :: RemoteEvent

local function snapAxis(value: number): number
	return math.floor(value / BLOCK_SIZE) * BLOCK_SIZE + BLOCK_SIZE / 2
end

local function getCursorCell(): Vector3?
	local camera = Workspace.CurrentCamera
	if not camera then
		return nil
	end

	local mousePosition = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mousePosition.X, mousePosition.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { Workspace:WaitForChild("Ghosts"), localPlayer.Character }
	local result = Workspace:Raycast(ray.Origin, ray.Direction * RAY_LENGTH, params)
	if not result then
		return nil
	end

	local point = result.Position + result.Normal * (BLOCK_SIZE / 2)
	return Vector3.new(snapAxis(point.X), snapAxis(point.Y), snapAxis(point.Z))
end

RunService.RenderStepped:Connect(function()
	if not BlockPlacer.isEnabled() then
		moveGhost:FireServer(nil, nil)
		return
	end
	moveGhost:FireServer(BlockPlacer.getBlockType(), getCursorCell())
end)
