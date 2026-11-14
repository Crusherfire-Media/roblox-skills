--!strict
--@author: Crusherfire
--@date: 11/13/26
--[[@description:
	Checks how ExampleSharedService fills a player's name into the greeting.
]]

------------------------------
-- DEPENDENCIES --
------------------------------
const JestGlobals = require("@game/ServerScriptService/Tests/Packages/JestGlobals")
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const it = JestGlobals.it

const ExampleSharedService = require(
	"@game/ServerScriptService/Modules/Systems/Gameplay/ExampleSystem/SystemPackage/ExampleSharedService"
)

------------------------------
-- MAIN --
------------------------------
describe("ExampleSharedService", function()
	it("puts the player's name into the greeting", function()
		ExampleSharedService:SetGreeting("Hi, {name}!")

		local message = ExampleSharedService:FormatGreeting("Builderman")

		expect(message).toBe("Hi, Builderman!")
	end)

	it("keeps a percent sign in the name as written", function()
		ExampleSharedService:SetGreeting("Hi, {name}!")

		local message = ExampleSharedService:FormatGreeting("100%")

		expect(message).toBe("Hi, 100%!")
	end)
end)
