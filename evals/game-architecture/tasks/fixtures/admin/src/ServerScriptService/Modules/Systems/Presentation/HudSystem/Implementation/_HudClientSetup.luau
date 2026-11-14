--[[
	Fills in this game's HUD.
]]

local Players = game:GetService("Players")

local HudClientService = require("../SystemPackage/HudClientService")

local HudClientSetup = {}

function HudClientSetup:Init()
	HudClientService:SetTitle(`Block Builder - {Players.LocalPlayer.DisplayName}`)
end

return HudClientSetup
