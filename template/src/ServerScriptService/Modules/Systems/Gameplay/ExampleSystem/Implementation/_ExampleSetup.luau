--!strict
--@author: Crusherfire
--@date: 11/13/26
--[[@description:
	Gives ExampleSystem this game's welcome message.
]]

------------------------------
-- DEPENDENCIES --
------------------------------
const ExampleSharedService = require("../SystemPackage/ExampleSharedService")

------------------------------
-- VARIABLES --
------------------------------
const GREETING = "Welcome to the game, {name}!"

local Module = {}

------------------------------
-- PUBLIC FUNCTIONS --
------------------------------

function Module:Init()
	ExampleSharedService:SetGreeting(GREETING)
end

return Module
