--!strict
-- Catalog of the block types players can place. Shared by server and client.
-- Every table here is frozen; treat the catalog as read-only.

export type BlockTypeId = "Brick" | "Dirt" | "Grass" | "Window" | "Wood"

export type BlockType = {
	id: BlockTypeId,
	displayName: string,
	color: Color3,
	material: Enum.Material,
	transparency: number,
}

local function define(blockType: BlockType): BlockType
	return table.freeze(blockType)
end

-- Display order (for the build UI later).
local list: { BlockType } = table.freeze({
	define({
		id = "Brick",
		displayName = "Brick",
		color = Color3.fromRGB(151, 61, 46),
		material = Enum.Material.Brick,
		transparency = 0,
	}),
	define({
		id = "Dirt",
		displayName = "Dirt",
		color = Color3.fromRGB(110, 78, 52),
		material = Enum.Material.Ground,
		transparency = 0,
	}),
	define({
		id = "Grass",
		displayName = "Grass",
		color = Color3.fromRGB(76, 145, 64),
		material = Enum.Material.Grass,
		transparency = 0,
	}),
	define({
		id = "Window",
		displayName = "Window",
		color = Color3.fromRGB(175, 215, 235),
		material = Enum.Material.Glass,
		transparency = 0.5,
	}),
	define({
		id = "Wood",
		displayName = "Wood",
		color = Color3.fromRGB(160, 112, 70),
		material = Enum.Material.WoodPlanks,
		transparency = 0,
	}),
})

local byId: { [string]: BlockType } = {}
for _, blockType in list do
	byId[blockType.id] = blockType
end
table.freeze(byId)

local BlockTypes = {
	list = list,
	byId = byId,
}

-- Looks up a block type by id. Returns nil for unknown ids, so the server can
-- use it to validate ids sent by clients.
function BlockTypes.get(id: unknown): BlockType?
	if typeof(id) ~= "string" then
		return nil
	end
	return byId[id]
end

return table.freeze(BlockTypes)
