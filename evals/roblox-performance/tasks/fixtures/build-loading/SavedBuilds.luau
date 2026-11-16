--[[
	Saved builds. Stands in for the DataStore until saving ships: every player gets the same
	20,000-block test build, the size of the largest saves we expect.
]]

export type SavedBlock = {
	Type: string,
	-- Grid cell relative to the plot's corner, in whole cells.
	Cell: Vector3,
	-- Unix time the block was first placed.
	PlacedAt: number,
}

local BLOCK_TYPE_NAMES = { "Brick", "Dirt", "Grass", "Window", "Wood" }
local SIZE_X = 50
local SIZE_Y = 20
local SIZE_Z = 20
local FIRST_PLACED_AT = 1_760_000_000

local SavedBuilds = {}

function SavedBuilds.load(_userId: number): { SavedBlock }
	local blocks: { SavedBlock } = table.create(SIZE_X * SIZE_Y * SIZE_Z)
	for y = 0, SIZE_Y - 1 do
		for x = 0, SIZE_X - 1 do
			for z = 0, SIZE_Z - 1 do
				local index = #blocks + 1
				blocks[index] = {
					Type = BLOCK_TYPE_NAMES[(x + y + z) % #BLOCK_TYPE_NAMES + 1],
					Cell = Vector3.new(x, y, z),
					PlacedAt = FIRST_PLACED_AT + index,
				}
			end
		end
	end
	return blocks
end

return SavedBuilds
