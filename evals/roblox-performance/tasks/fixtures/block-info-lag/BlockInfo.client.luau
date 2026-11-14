--[[
	Two building aids on the client: a panel in the top right corner that counts the placed blocks
	of each type, and a selection box on the placed block under the mouse, with its type shown
	under the counts.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)

-- How far from the point under the mouse a block's center may be and still count as hovered.
local HOVER_RADIUS = BlockTypes.BlockSize
local RAY_LENGTH = 512

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local blocksFolder = Workspace:WaitForChild("Blocks")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BlockInfo"
screenGui.ResetOnSpawn = false

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.new(1, -16, 0, 16)
panel.Size = UDim2.fromOffset(180, 150)
panel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
panel.BackgroundTransparency = 0.3
panel.Parent = screenGui

local countsLabel = Instance.new("TextLabel")
countsLabel.Size = UDim2.new(1, -16, 1, -16)
countsLabel.Position = UDim2.fromOffset(8, 8)
countsLabel.BackgroundTransparency = 1
countsLabel.Font = Enum.Font.GothamMedium
countsLabel.TextSize = 16
countsLabel.TextColor3 = Color3.new(1, 1, 1)
countsLabel.TextXAlignment = Enum.TextXAlignment.Left
countsLabel.TextYAlignment = Enum.TextYAlignment.Top
countsLabel.Parent = panel

screenGui.Parent = playerGui

local selectionBox = Instance.new("SelectionBox")
selectionBox.LineThickness = 0.05
selectionBox.Color3 = Color3.fromRGB(255, 220, 80)
selectionBox.Parent = Workspace

local function findHoveredBlock(): BasePart?
	local camera = Workspace.CurrentCamera
	if not camera then
		return nil
	end

	local mousePosition = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mousePosition.X, mousePosition.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	if localPlayer.Character then
		params.FilterDescendantsInstances = { localPlayer.Character }
	end
	local result = Workspace:Raycast(ray.Origin, ray.Direction * RAY_LENGTH, params)
	if not result then
		return nil
	end

	local nearest: BasePart? = nil
	local nearestDistance = HOVER_RADIUS
	for _, block in blocksFolder:GetChildren() do
		if block:IsA("BasePart") then
			local distance = (block.Position - result.Position).Magnitude
			if distance < nearestDistance then
				nearest = block
				nearestDistance = distance
			end
		end
	end
	return nearest
end

RunService.RenderStepped:Connect(function()
	local counts: { [string]: number } = {}
	for _, blockType in BlockTypes.List do
		counts[blockType.Name] = 0
	end
	for _, block in blocksFolder:GetChildren() do
		if counts[block.Name] then
			counts[block.Name] += 1
		end
	end

	local hovered = findHoveredBlock()
	selectionBox.Adornee = hovered

	local text = ""
	for _, blockType in BlockTypes.List do
		text = text .. blockType.DisplayName .. ": " .. counts[blockType.Name] .. "\n"
	end
	text = text .. "Total: " .. #blocksFolder:GetChildren()
	if hovered then
		local blockType = BlockTypes.ByName[hovered.Name]
		text = text
			.. "\nPointing at: "
			.. (if blockType then blockType.DisplayName else hovered.Name)
	end
	countsLabel.Text = text
end)
