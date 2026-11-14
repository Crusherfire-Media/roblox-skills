--[[
	Remotes for the admin tools. Each remote is a child of this module, so it reaches clients
	together with the module.
]]

local AdminNetwork = {
	-- Client to server: (message: string)
	Announce = script:WaitForChild("Announce") :: RemoteEvent,
}

return table.freeze(AdminNetwork)
