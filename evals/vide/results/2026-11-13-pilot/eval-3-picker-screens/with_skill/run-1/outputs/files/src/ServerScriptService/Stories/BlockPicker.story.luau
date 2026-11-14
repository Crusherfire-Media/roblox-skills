--!strict
--@author: Crusherfire
--@date: 2026-11-13
--[[@description:
	The block picker in its mouse-and-keyboard column and its touch row.
	Clicking a tile selects it, as in game.
]]

const BlockTypes = require("@game/ReplicatedStorage/Shared/BlockTypes")
const Vide = require("@game/ReplicatedStorage/Packages/Vide")

const BlockPicker = require("@game/StarterPlayer/StarterPlayerScripts/BlockPicker")

const source = Vide.source

type StoryProps = {
	controls: {
		IsTouchLayout: () -> boolean,
	},
	target: Frame,
}

const CONTROLS = {
	IsTouchLayout = false,
}

local function story(props: StoryProps)
	const selected = source(BlockTypes.List[1].Name)

	return BlockPicker({
		Layout = function(): BlockPicker.Layout
			return if props.controls.IsTouchLayout() then "Row" else "Column"
		end,
		Selected = selected,
		Select = function(name: string)
			selected(name)
		end,
	})
end

return {
	summary = "The block picker's column and touch row layouts.",
	vide = Vide,
	controls = CONTROLS,
	story = story,
}
