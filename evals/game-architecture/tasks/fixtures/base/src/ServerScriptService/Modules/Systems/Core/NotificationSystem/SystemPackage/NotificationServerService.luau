--[[
	Sends short on-screen messages to players.
]]

local NotificationNetwork = require("./NotificationNetwork")

local NotificationServerService = {}

--[[
	Shows a message to one player for a few seconds.
]]
function NotificationServerService:Notify(player: Player, message: string)
	NotificationNetwork.Notify:FireClient(player, message)
end

return NotificationServerService
