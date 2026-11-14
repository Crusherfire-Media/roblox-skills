--[[
	Remotes for notifications. Each remote is a child of this module, so it reaches clients
	together with the module.
]]

local NotificationNetwork = {
	-- Server to client: (message: string)
	Notify = script:WaitForChild("Notify") :: RemoteEvent,
}

return table.freeze(NotificationNetwork)
