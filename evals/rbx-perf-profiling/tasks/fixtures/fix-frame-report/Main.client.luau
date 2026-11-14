local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
print(`client started for {localPlayer.Name}`)

if RunService:IsStudio() then
	local FpsOverlay = require(ReplicatedStorage.Shared.Dev.FpsOverlay)
	FpsOverlay.start()
end
