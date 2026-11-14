--!strict
--[[
	Connects the block hotbar to BlockPlacer and mounts it, so the hotbar
	shows selections made with the number keys and slot presses select a block.
]]

local Vide = require("@game/ReplicatedStorage/Packages/Vide")

local cleanup = Vide.cleanup
local create = Vide.create
local mount = Vide.mount
local source = Vide.source

local BlockHotbar = require("./BlockHotbar")
local BlockPlacer = require("./BlockPlacer")
local BlockTypes = require("@game/ReplicatedStorage/Shared/BlockTypes")
local Screen = require("./Screen")

local Module = {}

local function hotbarGui(): ScreenGui
	local selected = source(BlockPlacer.getBlockType())
	cleanup(BlockPlacer.BlockTypeChanged:Connect(function(name: string)
		selected(name)
	end))

	return create("ScreenGui")({
		Name = "Hotbar",

		create("UIScale")({ Scale = Screen.uiScale }),
		BlockHotbar({
			BlockTypes = BlockTypes.List,
			Selected = selected,
			Select = BlockPlacer.setBlockType,
			ShowKeyHints = function()
				return not Screen.isTouch()
			end,
		}),
	})
end

--[[
	Builds the hotbar under the given PlayerGui for the rest of the session.
	Returns the function that destroys its Vide scope.
]]
function Module.mount(playerGui: Instance): () -> ()
	return mount(hotbarGui, playerGui)
end

return Module
