--[[
	Remotes for block placement. Each remote is a child of this module, so it reaches clients
	together with the module.
]]

local PlacementNetwork = {
	-- Client to server: (blockTypeName: string, position: Vector3)
	PlaceBlock = script:WaitForChild("PlaceBlock") :: RemoteEvent,
}

return table.freeze(PlacementNetwork)
