--!strict

const Vide = require("@game/ReplicatedStorage/Packages/Vide")

const BlockTypes = require("@game/ReplicatedStorage/Shared/BlockTypes")
const Hotbar = require("@game/StarterPlayer/StarterPlayerScripts/Hotbar")

const create = Vide.create
const indexes = Vide.indexes
const source = Vide.source

const LONG_NAME = "Reinforced Stained Glass"

type BlockType = BlockTypes.BlockType

type StoryProps = {
	controls: {
		ShowKeyHints: () -> boolean,
		LongNames: () -> boolean,
	},
	target: Frame,
}

local function story(props: StoryProps)
	const selected = source(BlockTypes.List[1].Name)

	-- Keyed by LongNames, so toggling it rebuilds the hotbar with the new
	-- names.
	const hotbars = indexes(function()
		return { [props.controls.LongNames()] = true }
	end, function(_, hasLongNames: boolean)
		const blockTypes: { BlockType } = {}
		for _, blockType in BlockTypes.List do
			const copy = table.clone(blockType)
			if hasLongNames then
				copy.DisplayName = LONG_NAME
			end
			table.insert(blockTypes, copy)
		end

		return Hotbar({
			BlockTypes = blockTypes,
			Selected = selected,
			ShowKeyHints = props.controls.ShowKeyHints,
			Select = function(name: string)
				print(`Selected {name}`)
				selected(name)
			end,
		})
	end)

	return create("Frame")({
		Name = "HotbarStory",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,

		hotbars,
	})
end

return {
	summary = "The block hotbar. Click a slot to select it.",
	vide = Vide,
	controls = {
		ShowKeyHints = true,
		LongNames = false,
	},
	story = story,
}
