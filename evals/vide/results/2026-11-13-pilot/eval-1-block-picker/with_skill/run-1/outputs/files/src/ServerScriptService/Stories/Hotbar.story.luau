--!strict
--@author: Crusherfire
--@date: 11/13/2026
--[[@description:
	The block hotbar with every block type. Pressing a slot selects it, as in
	game.
]]

const Vide = require("@game/ReplicatedStorage/Packages/Vide")

const source = Vide.source

const BlockTypes = require("@game/ReplicatedStorage/Shared/BlockTypes")
const Hotbar = require("@game/StarterPlayer/StarterPlayerScripts/Hotbar")

type StoryProps = {
	controls: {
		-- Off is how touch players see it.
		ShowKeyHints: () -> boolean,
	},
	target: Frame,
}

const CONTROLS = {
	ShowKeyHints = true,
}

local function story(props: StoryProps)
	const selectedName = source(BlockTypes.List[1].Name)

	return Hotbar({
		BlockTypes = BlockTypes.List,
		SelectedName = selectedName,
		ShowKeyHints = props.controls.ShowKeyHints,
		Select = function(name: string)
			selectedName(name)
		end,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
	})
end

return {
	summary = "The block hotbar. Press a slot to select it.",
	vide = Vide,
	controls = CONTROLS,
	story = story,
}
