--[[
	The one server script. Module Loader finds every module under the folders tagged LOAD_MODULE,
	requires them, then runs their Init and Start.
]]

local ModuleLoader = require("@game/ReplicatedStorage/Packages/ModuleLoader")

ModuleLoader.ChangeSettings({ USE_COLLECTION_SERVICE = true })
ModuleLoader.Start()
