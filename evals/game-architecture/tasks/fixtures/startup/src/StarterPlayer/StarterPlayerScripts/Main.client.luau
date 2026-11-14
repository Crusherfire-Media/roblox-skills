--[[
	The one client script. Module Loader finds every module under the folders tagged LOAD_MODULE
	that reached this client, requires them, then runs their Init and Start. The client waits for
	the server to finish loading first.
]]

local ModuleLoader = require("@game/ReplicatedStorage/Packages/ModuleLoader")

ModuleLoader.ChangeSettings({ USE_COLLECTION_SERVICE = true, WAIT_FOR_SERVER = true })
ModuleLoader.Start()
