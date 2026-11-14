--!strict
--@author: Crusherfire
--@date: 11/13/26
--[[@description:
	Starts the Module Loader on the server. Every other server module is a
	ModuleScript the loader finds through the LOAD_MODULE tag.
]]

------------------------------
-- DEPENDENCIES --
------------------------------
const ModuleLoader = require("@game/ReplicatedStorage/Packages/ModuleLoader")

------------------------------
-- MAIN --
------------------------------
ModuleLoader.Start()
