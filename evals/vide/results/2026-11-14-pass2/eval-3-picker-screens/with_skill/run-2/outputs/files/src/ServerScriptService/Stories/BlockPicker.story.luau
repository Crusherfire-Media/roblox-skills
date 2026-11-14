--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
local Vide = require(ReplicatedStorage.Packages.Vide)

local BlockPicker = require(StarterPlayer.StarterPlayerScripts.BlockPicker)

local source = Vide.source

local CENTER = Vector2.new(0.5, 0.5)
local PREVIEW_CENTER = UDim2.fromScale(0.5, 0.5)

-- Plain values, since the project has no UI Labs utility package for
-- ordered or choice controls. The game picks the layout by the same rule:
-- IsPhone wins over IsTouch, and neither gives Column.
local CONTROLS = {
	IsPhone = false,
	IsTouch = false,
}

type StoryProps = {
	controls: {
		IsPhone: () -> boolean,
		IsTouch: () -> boolean,
	},
	target: Frame,
}

local function story(props: StoryProps)
	local selected = source(BlockTypes.List[1].Name)

	return BlockPicker({
		Selected = selected,
		Select = function(name: string)
			print(`Selected {name}`)
			selected(name)
		end,
		Layout = function(): BlockPicker.Layout
			if props.controls.IsPhone() then
				return "CompactRow"
			elseif props.controls.IsTouch() then
				return "Row"
			else
				return "Column"
			end
		end,
		AnchorPoint = CENTER,
		Position = PREVIEW_CENTER,
	})
end

return {
	summary = "The block picker in its Column, Row, and CompactRow layouts.",
	vide = Vide,
	controls = CONTROLS,
	story = story,
}
