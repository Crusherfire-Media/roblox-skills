local ServerScriptService = game:GetService("ServerScriptService")

local JestGlobals = require(ServerScriptService.Tests.Packages.JestGlobals)
local describe = JestGlobals.describe
local expect = JestGlobals.expect
local it = JestGlobals.it

local PlacementRules = require(ServerScriptService.Placement.PlacementRules)

describe("PlacementRules", function()
	it("refuses an unknown block type", function()
		local ok = PlacementRules.validate("Lava", Vector3.new(1, 1, 1), Vector3.new(2, 2, 2), {})

		expect(ok).toBe(false)
	end)

	it("refuses a cell beyond the player's reach", function()
		local ok = PlacementRules.validate("Brick", Vector3.new(2, 2, 61), Vector3.new(2, 2, 2), {})

		expect(ok).toBe(false)
	end)

	it("accepts a free cell in reach and returns its center", function()
		local ok, center =
			PlacementRules.validate("Brick", Vector3.new(5, 1, -3), Vector3.new(2, 2, 2), {})

		expect(ok).toBe(true)
		expect(center).toBe(Vector3.new(6, 2, -2))
	end)
end)
