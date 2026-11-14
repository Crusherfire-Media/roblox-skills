--!strict
local Vide = require("@game/ReplicatedStorage/Packages/Vide")

local source = Vide.source

local BlockHotbar = require("@game/StarterPlayer/StarterPlayerScripts/BlockHotbar")
local BlockTypes = require("@game/ReplicatedStorage/Shared/BlockTypes")

local CONTROLS = {
	-- Off shows the hotbar as a touch player sees it.
	ShowKeyHints = true,
}

type StoryProps = {
	controls: {
		ShowKeyHints: () -> boolean,
	},
	target: Frame,
}

local function story(props: StoryProps)
	local selected = source(BlockTypes.List[1].Name)

	return BlockHotbar({
		BlockTypes = BlockTypes.List,
		Selected = selected,
		Select = function(name: string)
			print(`selected {name}`)
			selected(name)
		end,
		ShowKeyHints = props.controls.ShowKeyHints,
	})
end

return {
	summary = "The block hotbar. Press a slot to select it.",
	vide = Vide,
	controls = CONTROLS,
	story = story,
}
