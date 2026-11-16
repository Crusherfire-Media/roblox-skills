--!strict
-- Catalog of block types players can place. Shared by server and client.

export type BlockType = {
	Name: string,
	Color: Color3,
	Material: Enum.Material,
	Transparency: number,
}

local function block(name: string, color: Color3, material: Enum.Material, transparency: number): BlockType
	return table.freeze({
		Name = name,
		Color = color,
		Material = material,
		Transparency = transparency,
	})
end

local BlockCatalog: { [string]: BlockType } = {
	Brick = block("Brick", Color3.fromRGB(151, 0, 0), Enum.Material.Brick, 0),
	Dirt = block("Dirt", Color3.fromRGB(110, 80, 50), Enum.Material.Ground, 0),
	Grass = block("Grass", Color3.fromRGB(75, 151, 75), Enum.Material.Grass, 0),
	Window = block("Window", Color3.fromRGB(200, 230, 255), Enum.Material.Glass, 0.5),
	Wood = block("Wood", Color3.fromRGB(160, 110, 60), Enum.Material.WoodPlanks, 0),
}

return table.freeze(BlockCatalog)
