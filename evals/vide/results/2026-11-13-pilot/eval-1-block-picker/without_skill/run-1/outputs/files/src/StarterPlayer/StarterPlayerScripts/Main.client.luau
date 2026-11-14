local Players = game:GetService("Players")

local BlockPlacer = require(script.Parent.BlockPlacer)
local Hotbar = require(script.Parent.Hotbar)

local localPlayer = Players.LocalPlayer
print(`client started for {localPlayer.Name}`)

-- Mount UI before BlockPlacer.start(), which yields until the server's remote exists.
Hotbar.mount(localPlayer:WaitForChild("PlayerGui"))

BlockPlacer.start()
