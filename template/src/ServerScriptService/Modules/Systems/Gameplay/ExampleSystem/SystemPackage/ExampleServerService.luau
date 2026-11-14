--!strict

const Players = game:GetService("Players")

const ExampleSharedService = require("./ExampleSharedService")

local Module = setmetatable({}, ExampleSharedService)

local function onPlayerAdded(player: Player)
	print(Module:FormatGreeting(player.DisplayName))
end

function Module:Start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

return Module
