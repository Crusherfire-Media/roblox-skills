--[[
	Tells players why a block they tried to place was refused.
]]

local NotificationServerService = require(
	"@game/ServerScriptService/Modules/Systems/Core/NotificationSystem/SystemPackage/NotificationServerService"
)
local PlacementServerService = require("../SystemPackage/PlacementServerService")

local PlacementNotificationMediator = {}

function PlacementNotificationMediator:Init()
	PlacementServerService.PlacementRejected:Connect(function(player: Player, reason: string)
		NotificationServerService:Notify(player, reason)
	end)
end

return PlacementNotificationMediator
