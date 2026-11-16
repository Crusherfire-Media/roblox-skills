--!strict
-- Catalog of block types players can place. Shared by server and client.

export type BlockType = {
	Name: string,
	Color: Color3,
	Material: Enum.Material,
	Transparency: number,
}

local BlockCatalog: { [string]: BlockType } = {
	Brick = table.freeze({
		Name = "Brick",
		Color = Color3.fromRGB(151, 0, 0),
		Material = Enum.Material.Brick,
		Transparency = 0,
	}),
	Dirt = table.freeze({
		Name = "Dirt",
		Color = Color3.fromRGB(110, 80, 50),
		Material = Enum.Material.Ground,
		Transparency = 0,
	}),
	Grass = table.freeze({
		Name = "Grass",
		Color = Color3.fromRGB(75, 151, 75),
		Material = Enum.Material.Grass,
		Transparency = 0,
	}),
	Window = table.freeze({
		Name = "Window",
		Color = Color3.fromRGB(200, 230, 255),
		Material = Enum.Material.Glass,
		Transparency = 0.5,
	}),
	Wood = table.freeze({
		Name = "Wood",
		Color = Color3.fromRGB(160, 110, 60),
		Material = Enum.Material.WoodPlanks,
		Transparency = 0,
	}),
}

return table.freeze(BlockCatalog)
