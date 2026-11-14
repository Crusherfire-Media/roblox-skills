--[[
	The blocks the local player has placed this session, oldest first, kept in Charm so the build
	HUD can show them. The server fires BlockPlaced(blockTypeName) after each placement.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Charm = require(ReplicatedStorage.Packages.Charm)

local PlacedBlocks = {}

local getHistory, setHistory = Charm.signal({} :: { string })
local getLastPlaced, setLastPlaced = Charm.signal(nil :: string?)
local hasStarted = false

-- Block type names in the order they were placed.
PlacedBlocks.getHistory = getHistory
-- The block type placed most recently, or nil before the first placement.
PlacedBlocks.getLastPlaced = getLastPlaced
PlacedBlocks.getCount = Charm.computed(function(): number
	return #getHistory()
end)

local function onBlockPlaced(blockTypeName: string)
	setLastPlaced(blockTypeName)

	local history = getHistory()
	table.insert(history, blockTypeName)
	setHistory(history)
end

--[[
	Forgets every placed block. The HUD's Clear button calls it.
]]
function PlacedBlocks.clear()
	local history = getHistory()
	table.clear(history)
	setHistory(history)
	setLastPlaced(nil)
end

--[[
	Starts listening for placements. Yields until the server's BlockPlaced remote exists.
]]
function PlacedBlocks.start()
	if hasStarted then
		return
	end
	hasStarted = true

	local remote = ReplicatedStorage:WaitForChild("BlockPlaced")
	assert(remote:IsA("RemoteEvent"), "BlockPlaced must be a RemoteEvent")
	remote.OnClientEvent:Connect(onBlockPlaced)
end

return PlacedBlocks
