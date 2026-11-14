--[[
	Admin command: typing /clearblocks in chat removes every placed block within reach of the
	speaker. Only the place owner can use it.
]]

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local Workspace = game:GetService("Workspace")

local PlacementRules = require("@game/ServerScriptService/Placement/PlacementRules")

local REACH_SCALE = 2

local command = Instance.new("TextChatCommand")
command.Name = "ClearBlocksCommand"
command.PrimaryAlias = "/clearblocks"
command.Parent = TextChatService

command.Triggered:Connect(function(textSource: TextSource)
	local player = Players:GetPlayerByUserId(textSource.UserId)
	if not player or player.UserId ~= game.CreatorId then
		return
	end
	local character = player.Character
	local rootPart = if character then character:FindFirstChild("HumanoidRootPart") else nil
	local blocks = Workspace:FindFirstChild("Blocks")
	if not rootPart or not rootPart:IsA("BasePart") or not blocks then
		return
	end

	local center = PlacementRules.snap(rootPart.Position)
	local radius = (script.Parent.Placement.PlacementRules:GetAttribute("MaxReach") :: number)
		* REACH_SCALE
	for _, part in blocks:GetChildren() do
		if part:IsA("BasePart") and (part.Position - center).Magnitude <= radius then
			part:Destroy()
		end
	end
end)
