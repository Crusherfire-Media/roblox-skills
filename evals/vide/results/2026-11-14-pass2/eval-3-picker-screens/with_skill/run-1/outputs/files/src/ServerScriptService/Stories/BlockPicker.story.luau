--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local BlockPicker = require(StarterPlayer.StarterPlayerScripts.BlockPicker)
local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
local Vide = require(ReplicatedStorage.Packages.Vide)

local create = Vide.create
local indexes = Vide.indexes
local source = Vide.source

local MAXIMUM_BLOCK_COUNT = 12

local CONTROLS = {
	-- The hotbar shown on touch screens and phone-sized windows.
	IsRow = false,
	-- Changing it starts the story over. Kept between 1 and 12.
	BlockCount = #BlockTypes.List,
	HasLongNames = false,
}

type StoryProps = {
	controls: {
		IsRow: () -> boolean,
		BlockCount: () -> number,
		HasLongNames: () -> boolean,
	},
	target: Frame,
}

type Sample = {
	Count: number,
	HasLongNames: boolean,
}

local function sampleBlockTypes(sample: Sample): { BlockTypes.BlockType }
	local list = {}
	for index = 1, sample.Count do
		local base = BlockTypes.List[(index - 1) % #BlockTypes.List + 1]
		list[index] = table.freeze({
			Name = `{base.Name}{index}`,
			DisplayName = if sample.HasLongNames
				then `Polished {base.DisplayName} Panel`
				else base.DisplayName,
			Color = base.Color,
			Material = base.Material,
			Transparency = base.Transparency,
		})
	end
	return list
end

local function story(props: StoryProps)
	local controls = props.controls

	local function layout(): BlockPicker.Layout
		return if controls.IsRow() then "Row" else "Column"
	end

	return create("Frame")({
		Name = "Preview",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,

		create("UIListLayout")({
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),

		indexes(function()
			local count = math.clamp(math.floor(controls.BlockCount()), 1, MAXIMUM_BLOCK_COUNT)
			local hasLongNames = controls.HasLongNames()
			return {
				[`{count}:{hasLongNames}`] = { Count = count, HasLongNames = hasLongNames },
			}
		end, function(sample: () -> Sample)
			local blockTypes = sampleBlockTypes(sample())
			local selected = source(blockTypes[1].Name)

			return BlockPicker.component({
				Layout = layout,
				BlockTypes = blockTypes,
				Selected = selected,
				Select = function(name: string)
					print(`Selected {name}`)
					selected(name)
				end,
			})
		end),
	})
end

return {
	summary = "The block picker in its desktop column and touch hotbar layouts.",
	vide = Vide,
	controls = CONTROLS,
	story = story,
}
