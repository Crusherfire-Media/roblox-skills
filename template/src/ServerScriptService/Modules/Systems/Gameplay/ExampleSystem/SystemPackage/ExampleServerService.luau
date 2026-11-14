--!strict
--@author: Crusherfire
--@date: 11/13/26
--[[@description:
	Welcomes each player in the server's output when they join.
]]

------------------------------
-- SERVICES --
------------------------------
const Players = game:GetService("Players")

------------------------------
-- DEPENDENCIES --
------------------------------
const ExampleSharedService = require("./ExampleSharedService")

------------------------------
-- VARIABLES --
------------------------------
local Module = setmetatable({}, ExampleSharedService)

------------------------------
-- PRIVATE FUNCTIONS --
------------------------------

local function onPlayerAdded(player: Player)
	print(Module:FormatGreeting(player.DisplayName))
end

------------------------------
-- PUBLIC FUNCTIONS --
------------------------------

function Module:Start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

return Module
