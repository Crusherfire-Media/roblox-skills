--!strict
export type BlockType = "Brick" | "Dirt" | "Grass" | "Window" | "Wood"

export type BlockStyle = {
	color: Color3,
	material: Enum.Material,
	transparency: number,
}

local BlockTypes = {}

BlockTypes.ORDER = { "Brick", "Dirt", "Grass", "Window", "Wood" } :: { BlockType }

BlockTypes.STYLES = {
	Brick = {
		color = Color3.fromRGB(151, 63, 46),
		material = Enum.Material.Brick,
		transparency = 0,
	},
	Dirt = {
		color = Color3.fromRGB(110, 76, 48),
		material = Enum.Material.Ground,
		transparency = 0,
	},
	Grass = {
		color = Color3.fromRGB(86, 140, 56),
		material = Enum.Material.Grass,
		transparency = 0,
	},
	Window = {
		color = Color3.fromRGB(170, 210, 230),
		material = Enum.Material.Glass,
		transparency = 0.5,
	},
	Wood = {
		color = Color3.fromRGB(150, 110, 70),
		material = Enum.Material.WoodPlanks,
		transparency = 0,
	},
} :: { [BlockType]: BlockStyle }

function BlockTypes.isBlockType(value: unknown): boolean
	return type(value) == "string" and BlockTypes.STYLES[value :: BlockType] ~= nil
end

return BlockTypes
