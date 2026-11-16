--!strict

const ExampleSharedService = require("../SystemPackage/ExampleSharedService")

const GREETING = "Welcome to the game, {name}!"

local Module = {}

function Module:Init()
	ExampleSharedService:SetGreeting(GREETING)
end

return Module
