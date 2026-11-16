--!strict
--@author: Crusherfire
--@date: 2026-11-13
--[[@description:
	The block picker in both layouts. Clicking a tile selects it, as it would
	in game.
]]

const BlockPicker = require("@game/StarterPlayer/StarterPlayerScripts/BlockPicker")
const BlockTypes = require("@game/ReplicatedStorage/Shared/BlockTypes")
const Vide = require("@game/ReplicatedStorage/Packages/Vide")

const source = Vide.source

-- Plain values, since the project has no UI Labs utility package for ordered
-- or grouped controls.
const CONTROLS = {
	-- Off: the desktop column with names. On: the touch row.
	IsRowLayout = false,
}

type StoryProps = {
	controls: {
		IsRowLayout: () -> boolean,
	},
	target: Frame,
}

local function story(props: StoryProps)
	local selected = source(BlockTypes.List[1].Name)

	return BlockPicker({
		Selected = selected,
		Select = function(name: string)
			selected(name)
		end,
		Layout = function(): BlockPicker.Layout
			return if props.controls.IsRowLayout() then "Row" else "Column"
		end,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
	})
end

return {
	summary = "The block picker: a named column for desktop, a thumb-sized row for touch.",
	vide = Vide,
	controls = CONTROLS,
	story = story,
}
