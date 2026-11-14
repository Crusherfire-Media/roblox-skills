--!strict
--@author: Crusherfire
--@date: 11/13/2026
--[[@description:
	UI Labs storybook for the game's UI. Studio-only: nothing in the game
	requires this folder.
]]

const ServerScriptService = game:GetService("ServerScriptService")

return {
	name = "Game UI",
	storyRoots = { ServerScriptService.Stories },
}
