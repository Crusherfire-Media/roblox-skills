local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local BlockPicker = require(StarterPlayer.StarterPlayerScripts.BlockPicker)
local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
local UILabs = require(ReplicatedStorage.Packages.UILabs)
local Vide = require(ReplicatedStorage.Packages.Vide)

local blockNames = {}
for _, blockType in BlockTypes.List do
	table.insert(blockNames, blockType.Name)
end

local controls = {
	Block = UILabs.Ordered(
		UILabs.ControlGroup({
			Selected = UILabs.Ordered(UILabs.Choose(blockNames), 1),
		}),
		1
	),
	Look = UILabs.Ordered(
		UILabs.ControlGroup({
			ShowNames = UILabs.Ordered(true, 1),
		}),
		2
	),
}

local function story(props: any)
	return BlockPicker({
		ShowNames = props.controls.Look.ShowNames(),
		Selected = props.controls.Selected,
		Select = function(name: string)
			print(`Selected {name}`)
		end,
	})
end

return {
	summary = "The build mode block picker.",
	vide = Vide,
	controls = controls,
	story = story,
}
