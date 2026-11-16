local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local JestGlobals = require(ServerScriptService.Tests.Packages.JestGlobals)
local describe = JestGlobals.describe
local expect = JestGlobals.expect
local it = JestGlobals.it

local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)

describe("BlockTypes", function()
	it("gives every block type a unique name that ByName finds", function()
		local problems = {}
		local seen = {}
		for _, blockType in BlockTypes.List do
			if seen[blockType.Name] then
				table.insert(problems, `{blockType.Name} appears twice`)
			end
			seen[blockType.Name] = true
			if BlockTypes.ByName[blockType.Name] ~= blockType then
				table.insert(problems, `ByName misses {blockType.Name}`)
			end
		end

		expect(problems).toEqual({})
	end)
end)
