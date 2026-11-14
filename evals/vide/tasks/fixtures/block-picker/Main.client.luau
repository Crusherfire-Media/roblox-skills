local Players = game:GetService("Players")

local BlockPlacer = require(script.Parent.BlockPlacer)

local localPlayer = Players.LocalPlayer
print(`client started for {localPlayer.Name}`)

BlockPlacer.start()
