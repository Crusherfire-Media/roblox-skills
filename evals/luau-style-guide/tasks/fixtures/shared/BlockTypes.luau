--!strict
-- The five block types players can place, in hotbar order, and how each one looks.

export type BlockType = "Brick" | "Dirt" | "Grass" | "Window" | "Wood"

export type BlockStyle = {
	Color: Color3,
	Material: Enum.Material,
	Transparency: number,
}

local BlockTypes = {}

-- Edge length of every block, in studs. Blocks snap to a grid of this size.
BlockTypes.BlockSize = 4

BlockTypes.Order = { "Brick", "Dirt", "Grass", "Window", "Wood" } :: { BlockType }

BlockTypes.Styles = {
	Brick = {
		Color = Color3.fromRGB(151, 63, 46),
		Material = Enum.Material.Brick,
		Transparency = 0,
	},
	Dirt = {
		Color = Color3.fromRGB(110, 76, 48),
		Material = Enum.Material.Ground,
		Transparency = 0,
	},
	Grass = {
		Color = Color3.fromRGB(86, 140, 56),
		Material = Enum.Material.Grass,
		Transparency = 0,
	},
	Window = {
		Color = Color3.fromRGB(170, 210, 230),
		Material = Enum.Material.Glass,
		Transparency = 0.5,
	},
	Wood = {
		Color = Color3.fromRGB(150, 110, 70),
		Material = Enum.Material.WoodPlanks,
		Transparency = 0,
	},
} :: { [BlockType]: BlockStyle }

function BlockTypes.isBlockType(value: unknown): boolean
	return type(value) == "string" and BlockTypes.Styles[value :: BlockType] ~= nil
end

return BlockTypes
