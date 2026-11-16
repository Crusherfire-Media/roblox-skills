--[[
	Server side of the admin tools: sends an admin's announcement to every player.
]]

local Players = game:GetService("Players")

local AdminNetwork = require("./AdminNetwork")
local AdminSharedService = require("./AdminSharedService")
local NotificationServerService = require(
	"@game/ServerScriptService/Modules/Systems/Core/NotificationSystem/SystemPackage/NotificationServerService"
)

local AdminServerService = setmetatable({}, AdminSharedService)

local function onAnnounce(player: Player, message: unknown)
	if not AdminServerService:IsAdmin(player.UserId) then
		return
	end
	if typeof(message) ~= "string" or message == "" then
		return
	end
	if utf8.len(message) == nil or #message > AdminSharedService.MaxAnnouncementLength then
		return
	end

	for _, target in Players:GetPlayers() do
		NotificationServerService:Notify(target, `{player.DisplayName}: {message}`)
	end
end

function AdminServerService:Init()
	AdminNetwork.Announce.OnServerEvent:Connect(onAnnounce)
end

return AdminServerService
