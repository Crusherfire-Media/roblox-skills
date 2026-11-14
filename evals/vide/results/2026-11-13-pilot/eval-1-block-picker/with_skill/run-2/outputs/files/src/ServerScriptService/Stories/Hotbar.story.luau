--[[
	The block hotbar. Click a slot to select it, as a player would.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
local Hotbar = require(StarterPlayer.StarterPlayerScripts.Hotbar)
local Vide = require(ReplicatedStorage.Packages.Vide)

local create = Vide.create
local source = Vide.source

type StoryProps = {
	controls: {
		IsCompact: () -> boolean,
		ShowKeyHints: () -> boolean,
	},
	target: Frame,
}

local function story(props: StoryProps)
	local selected = source(BlockTypes.List[1].Name)

	return create("Frame")({
		Name = "Preview",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		AutomaticSize = Enum.AutomaticSize.XY,

		Hotbar.new({
			BlockTypes = BlockTypes.List,
			Selected = selected,
			OnSelect = function(name: string)
				print(`selected {name}`)
				selected(name)
			end,
			IsCompact = props.controls.IsCompact,
			ShowKeyHints = props.controls.ShowKeyHints,
		}),
	})
end

return {
	summary = "The block hotbar in its desktop and compact (touch) sizes.",
	vide = Vide,
	controls = {
		-- The touch layout, used on phones and whenever touch is the primary input.
		IsCompact = false,
		-- The number key labels, shown when touch is not the primary input.
		ShowKeyHints = true,
	},
	story = story,
}
