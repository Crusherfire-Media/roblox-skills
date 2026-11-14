local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local JestGlobals = require(ServerScriptService.Tests.Packages.JestGlobals)
local describe = JestGlobals.describe
local expect = JestGlobals.expect
local it = JestGlobals.it
local jest = JestGlobals.jest

local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
local PlacementRules = require(ReplicatedStorage.Shared.PlacementRules)

local occupied: { [Vector3]: boolean } = {}

describe("PlacementRules", function()
	describe("snap", function()
		it("snaps positions to cell centers", function()
			local size = BlockTypes.BlockSize
			local samples = {
				Vector3.new(1, 1, 1),
				Vector3.new(5, 9, -3),
				Vector3.new(-7, 2, 13),
			}
			for _, position in samples do
				local expected = Vector3.new(
					(math.floor(position.X / size) + 0.5) * size,
					(math.floor(position.Y / size) + 0.5) * size,
					(math.floor(position.Z / size) + 0.5) * size
				)
				expect(PlacementRules.snap(position)).toEqual(expected)
			end
		end)

		it.each({
			{ X = 1, Y = 1, Z = 1, CenterX = 2, CenterY = 2, CenterZ = 2 },
			{ X = 2, Y = 2, Z = 2, CenterX = 2, CenterY = 2, CenterZ = 2 },
			{ X = 0, Y = 0, Z = 0, CenterX = 2, CenterY = 2, CenterZ = 2 },
			{ X = 3.9, Y = 0, Z = 0, CenterX = 2, CenterY = 2, CenterZ = 2 },
			{ X = 4, Y = 0, Z = 0, CenterX = 6, CenterY = 2, CenterZ = 2 },
			{ X = -0.1, Y = 0, Z = 0, CenterX = -2, CenterY = 2, CenterZ = 2 },
		})("snaps ($X, $Y, $Z) to ($CenterX, $CenterY, $CenterZ)", function(row)
			local center = PlacementRules.snap(Vector3.new(row.X, row.Y, row.Z))

			expect(center).toEqual(Vector3.new(row.CenterX, row.CenterY, row.CenterZ))
		end)
	end)

	describe("_isFinite", function()
		it("rejects NaN", function()
			expect(PlacementRules._isFinite(0 / 0)).toBe(false)
		end)

		it("rejects infinity", function()
			expect(PlacementRules._isFinite(math.huge)).toBe(false)
		end)

		it("accepts zero", function()
			expect(PlacementRules._isFinite(0)).toBe(true)
		end)
	end)

	describe("validate", function()
		local blockTypeRows = {}
		for _, blockType in BlockTypes.List do
			table.insert(blockTypeRows, { Name = blockType.Name })
		end

		it.each(blockTypeRows)("accepts a $Name block", function(row)
			local ok = PlacementRules.validate(
				row.Name,
				Vector3.new(1, 1, 1),
				Vector3.new(2, 2, 10),
				occupied
			)

			expect(ok).toBe(true)
		end)

		it("rejects an unknown block type", function()
			local ok, reason =
				PlacementRules.validate("Lava", Vector3.new(1, 1, 1), Vector3.new(2, 2, 2), {})

			expect(ok).toBe(false)
			expect(reason).toBe("unknown block type")
		end)

		it("rejects a position that isn't a Vector3", function()
			local ok, reason = PlacementRules.validate(
				"Brick",
				{ 1, 1, 1 },
				Vector3.new(2, 2, 2),
				{}
			)

			expect(ok):toBe(false)
			expect(reason):toBe("position is not a Vector3")
		end)

		it("rejects NaN positions", function()
			local ok, reason =
				PlacementRules.validate("Brick", Vector3.new(0 / 0, 1, 1), Vector3.new(2, 2, 2), {})

			expect(ok).toBe(false)
			expect(reason).toBe("position is not finite")
		end)

		it("returns the snapped center", function()
			local position = Vector3.new(5, 1, -3)

			local ok, center = PlacementRules.validate("Brick", position, Vector3.new(2, 2, 2), {})

			expect(ok).toBe(true)
			expect(center).toEqual(PlacementRules.snap(position))
		end)

		it("calls snap exactly once", function()
			local snapSpy = jest.spyOn(PlacementRules, "snap")

			PlacementRules.validate("Brick", Vector3.new(1, 1, 1), Vector3.new(2, 2, 2), {})

			expect(snapSpy).toHaveBeenCalledTimes(1)
			snapSpy.mockRestore()
		end)

		it.each({
			{ Y = -0.1, Accepted = false },
			{ Y = 0, Accepted = true },
			{ Y = 196, Accepted = true },
			{ Y = 200, Accepted = false },
		})("height: Y = $Y accepted is $Accepted", function(row)
			local ok = PlacementRules.validate(
				"Brick",
				Vector3.new(1, row.Y, 1),
				Vector3.new(2, row.Y, 2),
				{}
			)

			expect(ok).toBe(row.Accepted)
		end)

		it.each({
			{ Z = 21, Distance = 20, Accepted = true },
			{ Z = 25, Distance = 24, Accepted = true },
			{ Z = 29, Distance = 28, Accepted = false },
		})("reach: a cell $Distance studs away accepted is $Accepted", function(row)
			local ok, reason =
				PlacementRules.validate("Brick", Vector3.new(2, 2, row.Z), Vector3.new(2, 2, 2), {})

			expect(ok).toBe(row.Accepted)
			if not row.Accepted then
				expect(reason).toBe("out of reach")
			end
		end)

		it("rejects a cell that is already occupied", function()
			occupied[Vector3.new(2, 2, 2)] = true

			local ok, reason = PlacementRules.validate(
				"Brick",
				Vector3.new(1, 1, 1),
				Vector3.new(2, 2, 2),
				occupied
			)

			expect(ok).toBe(false)
			expect(reason).toBe("cell is occupied")
		end)

		it("rejects placing twice in the same cell", function()
			local ok = PlacementRules.validate(
				"Dirt",
				Vector3.new(3, 3, 3),
				Vector3.new(2, 2, 2),
				occupied
			)

			expect(ok).toBe(false)
		end)

		it("doesn't mark the cell occupied", function()
			local cells = {}

			PlacementRules.validate("Brick", Vector3.new(1, 1, 1), Vector3.new(2, 2, 2), cells)

			local count = 0
			for _ in cells do
				count += 1
			end
			expect(count).toBeFalsy()
		end)
	end)

	describe("BlockTypes", function()
		it("has the right block types", function()
			expect(#BlockTypes.List).toBe(5)
			expect(BlockTypes.List[1].Name).toBe("Brick")
			expect(BlockTypes.List[1].Color).toEqual(Color3.fromRGB(163, 75, 60))
			expect(BlockTypes.List[1].Material).toBe(Enum.Material.Brick)
			expect(BlockTypes.List[2].Name).toBe("Dirt")
			expect(BlockTypes.List[2].Color).toEqual(Color3.fromRGB(110, 78, 52))
			expect(BlockTypes.List[3].Name).toBe("Grass")
			expect(BlockTypes.List[3].Color).toEqual(Color3.fromRGB(88, 145, 62))
			expect(BlockTypes.List[4].Name).toBe("Window")
			expect(BlockTypes.List[4].Transparency).toBe(0.6)
			expect(BlockTypes.List[5].Name).toBe("Wood")
			expect(BlockTypes.List[5].Material).toBe(Enum.Material.WoodPlanks)
		end)
	end)
end)
