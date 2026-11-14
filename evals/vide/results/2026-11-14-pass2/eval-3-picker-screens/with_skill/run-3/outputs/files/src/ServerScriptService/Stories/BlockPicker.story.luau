--!strict

local Vide = require("@game/ReplicatedStorage/Packages/Vide")

local BlockPicker = require("@game/StarterPlayer/StarterPlayerScripts/BlockPicker")
local BlockTypes = require("@game/ReplicatedStorage/Shared/BlockTypes")

local source = Vide.source

local CENTER = Vector2.new(0.5, 0.5)
local SCREEN_CENTER = UDim2.fromScale(0.5, 0.5)

-- Plain controls, so the story needs no UI Labs utility package.
local CONTROLS = {
	-- Off is the desktop column, on is the touch row.
	IsRowLayout = false,
	ShowKeyHints = true,
}

type StoryProps = {
	controls: {
		IsRowLayout: () -> boolean,
		ShowKeyHints: () -> boolean,
	},
	target: Frame,
}

local function story(props: StoryProps)
	local controls = props.controls
	local selected = source(BlockTypes.List[1].Name)

	return BlockPicker({
		Selected = selected,
		Select = function(name: string)
			print(`Selected {name}`)
			selected(name)
		end,
		Layout = function(): BlockPicker.Layout
			return if controls.IsRowLayout() then "Row" else "Column"
		end,
		ShowKeyHints = controls.ShowKeyHints,
		AnchorPoint = CENTER,
		Position = SCREEN_CENTER,
	})
end

return {
	summary = "The block picker in its desktop column and touch row layouts.",
	vide = Vide,
	controls = CONTROLS,
	story = story,
}
