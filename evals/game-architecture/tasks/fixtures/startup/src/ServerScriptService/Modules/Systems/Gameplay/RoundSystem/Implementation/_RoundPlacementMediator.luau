--[[
	Clears the blocks at the end of every round.
]]

local PlacementServerService = require(
	"@game/ServerScriptService/Modules/Systems/Gameplay/PlacementSystem/SystemPackage/PlacementServerService"
)
local RoundServerService = require("../SystemPackage/RoundServerService")

local RoundPlacementMediator = {}

function RoundPlacementMediator:Init()
	RoundServerService.RoundEnded:Connect(function()
		PlacementServerService:ClearBlocks()
	end)
end

return RoundPlacementMediator
