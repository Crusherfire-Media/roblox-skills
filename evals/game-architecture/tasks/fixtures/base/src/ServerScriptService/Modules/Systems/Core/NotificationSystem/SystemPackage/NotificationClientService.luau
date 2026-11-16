--[[
	Shows the messages the server sends as Roblox notifications.
]]

local StarterGui = game:GetService("StarterGui")

local NotificationNetwork = require("./NotificationNetwork")

local NOTIFICATION_SECONDS = 3

local NotificationClientService = {}

local function show(message: string)
	-- SetCore errors until the core scripts register SendNotification, early in a session.
	pcall(StarterGui.SetCore, StarterGui, "SendNotification", {
		Title = "Notice",
		Text = message,
		Duration = NOTIFICATION_SECONDS,
	})
end

function NotificationClientService:Init()
	NotificationNetwork.Notify.OnClientEvent:Connect(show)
end

return NotificationClientService
