--!strict
--[[
	Mounts the block hotbar and keeps it in sync with BlockPlacer, whichever
	of the hotbar or the number keys changes the selection.
]]

const Vide = require("@game/ReplicatedStorage/Packages/Vide")

const BlockPlacer = require("./BlockPlacer")
const BlockTypes = require("@game/ReplicatedStorage/Shared/BlockTypes")
const Hotbar = require("./Hotbar")
const Screen = require("./Screen")

const cleanup = Vide.cleanup
const create = Vide.create
const mount = Vide.mount
const source = Vide.source

local Module = {}

local function hotbarScreen(): ScreenGui
	const selected = source(BlockPlacer.getBlockType())

	cleanup(BlockPlacer.BlockTypeChanged:Connect(function(name: string)
		selected(name)
	end))

	const gui = create("ScreenGui")({
		Name = "HotbarScreen",

		create("UIScale")({ Scale = Screen.uiScale }),

		Hotbar({
			BlockTypes = BlockTypes.List,
			Selected = selected,
			ShowKeyHints = function()
				return not Screen.isTouch()
			end,
			Select = function(name: string)
				BlockPlacer.setBlockType(name)
				-- BlockTypeChanged is deferred, so update now rather than a
				-- frame late.
				selected(BlockPlacer.getBlockType())
			end,
		}),
	})
	-- Destroying the mount scope leaves its root instance parented.
	cleanup(gui)

	return gui
end

--[[
	Builds the hotbar under the given PlayerGui. Returns a function that
	removes it.
]]
function Module.mount(playerGui: Instance): () -> ()
	return mount(hotbarScreen, playerGui)
end

return Module
