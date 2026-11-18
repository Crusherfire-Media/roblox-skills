--!strict

const ModuleLoader = require("@game/ReplicatedStorage/Packages/ModuleLoader")

-- Systems are found by their LOAD_MODULE tag, and the loader reads tags only with this setting on.
ModuleLoader.ChangeSettings({ USE_COLLECTION_SERVICE = true })
ModuleLoader.Start()
