--[[
	The block types players can place, in hotbar order. Server and client code both read this.
]]

export type BlockType = {
	Name: string,
	DisplayName: string,
	Color: Color3,
	Material: Enum.Material,
	Transparency: number,
}

-- Edge length of every block, in studs. Blocks snap to a grid of this size.
local BLOCK_SIZE = 4

local LIST: { BlockType } = table.freeze({
	table.freeze({
		Name = "Brick",
		DisplayName = "Brick",
		Color = Color3.fromRGB(163, 75, 60),
		Material = Enum.Material.Brick,
		Transparency = 0,
	}),
	table.freeze({
		Name = "Dirt",
		DisplayName = "Dirt",
		Color = Color3.fromRGB(110, 78, 52),
		Material = Enum.Material.Ground,
		Transparency = 0,
	}),
	table.freeze({
		Name = "Grass",
		DisplayName = "Grass",
		Color = Color3.fromRGB(88, 145, 62),
		Material = Enum.Material.Grass,
		Transparency = 0,
	}),
	table.freeze({
		Name = "Window",
		DisplayName = "Window",
		Color = Color3.fromRGB(170, 210, 230),
		Material = Enum.Material.Glass,
		Transparency = 0.6,
	}),
	table.freeze({
		Name = "Wood",
		DisplayName = "Wood",
		Color = Color3.fromRGB(150, 110, 70),
		Material = Enum.Material.WoodPlanks,
		Transparency = 0,
	}),
})

local byName: { [string]: BlockType } = {}
for _, blockType in LIST do
	byName[blockType.Name] = blockType
end

local BlockTypes = {
	BlockSize = BLOCK_SIZE,
	List = LIST,
	ByName = table.freeze(byName),
}

return table.freeze(BlockTypes)
