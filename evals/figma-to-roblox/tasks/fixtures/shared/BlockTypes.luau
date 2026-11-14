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
	table.freeze({
		Name = "Stone",
		DisplayName = "Stone",
		Color = Color3.fromRGB(125, 125, 130),
		Material = Enum.Material.Slate,
		Transparency = 0,
	}),
	table.freeze({
		Name = "Sand",
		DisplayName = "Sand",
		Color = Color3.fromRGB(220, 200, 140),
		Material = Enum.Material.Sand,
		Transparency = 0,
	}),
	table.freeze({
		Name = "Ice",
		DisplayName = "Ice",
		Color = Color3.fromRGB(180, 225, 245),
		Material = Enum.Material.Ice,
		Transparency = 0.2,
	}),
	table.freeze({
		Name = "Lamp",
		DisplayName = "Lamp",
		Color = Color3.fromRGB(255, 230, 150),
		Material = Enum.Material.Neon,
		Transparency = 0,
	}),
	table.freeze({
		Name = "Gold",
		DisplayName = "Gold",
		Color = Color3.fromRGB(230, 180, 50),
		Material = Enum.Material.Metal,
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
