--!strict
--@author: Crusherfire
--@date: 11/13/26
--[[@description:
	Starts the Module Loader on the client. It loads the modules the server
	relocated to ReplicatedStorage.
]]

------------------------------
-- DEPENDENCIES --
------------------------------
const ModuleLoader = require("@game/ReplicatedStorage/Packages/ModuleLoader")

------------------------------
-- MAIN --
------------------------------
ModuleLoader.Start()
