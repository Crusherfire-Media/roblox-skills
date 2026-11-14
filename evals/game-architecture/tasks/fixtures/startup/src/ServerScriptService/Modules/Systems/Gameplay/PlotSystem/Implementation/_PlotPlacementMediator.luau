--[[
	Lets players build on the plots.
]]

local PlacementServerService = require(
	"@game/ServerScriptService/Modules/Systems/Gameplay/PlacementSystem/SystemPackage/PlacementServerService"
)
local PlotServerService = require("../SystemPackage/PlotServerService")

local PlotPlacementMediator = {}

function PlotPlacementMediator:Init()
	for _, plot in PlotServerService:GetPlots() do
		PlacementServerService:AddBuildArea(plot)
	end
end

return PlotPlacementMediator
