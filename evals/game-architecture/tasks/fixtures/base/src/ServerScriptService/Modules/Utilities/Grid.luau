--[[
	Grid math for blocks. Cells are cubes of a given edge length, aligned to the world origin.
]]

local Grid = {}

function Grid.snapAxis(value: number, cellSize: number): number
	return math.floor(value / cellSize) * cellSize + cellSize / 2
end

--[[
	Returns the center of the grid cell that contains the position.
]]
function Grid.snapToCell(position: Vector3, cellSize: number): Vector3
	return Vector3.new(
		Grid.snapAxis(position.X, cellSize),
		Grid.snapAxis(position.Y, cellSize),
		Grid.snapAxis(position.Z, cellSize)
	)
end

return table.freeze(Grid)
