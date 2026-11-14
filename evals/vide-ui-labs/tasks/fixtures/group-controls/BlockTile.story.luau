local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local BlockTile = require(StarterPlayer.StarterPlayerScripts.BlockTile)
local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
local UILabs = require(ReplicatedStorage.Packages.UILabs)
local Vide = require(ReplicatedStorage.Packages.Vide)

local create = Vide.create
local source = Vide.source

local blockNames = {}
for _, blockType in BlockTypes.List do
	table.insert(blockNames, blockType.Name)
end

local CONTROLS = {
	HighlightThickness = UILabs.Slider(3, 1, 8, 1),
	Locked = false,
	Backdrop = Color3.fromRGB(40, 40, 46),
	Block = UILabs.Choose(blockNames),
	TileSize = UILabs.Slider(64, 32, 128, 1),
	ShowCount = true,
	-- Empty shows the block type's own display name.
	NameOverride = "",
	CornerRadius = UILabs.Slider(8, 0, 32, 1),
	Count = UILabs.Slider(20, 0, 999, 1),
	Centered = true,
	HighlightColor = Color3.fromRGB(255, 200, 60),
	ShowName = true,
	Selected = false,
}

type StoryProps = {
	controls: {
		HighlightThickness: () -> number,
		Locked: () -> boolean,
		Backdrop: () -> Color3,
		Block: () -> string,
		TileSize: () -> number,
		ShowCount: () -> boolean,
		NameOverride: () -> string,
		CornerRadius: () -> number,
		Count: () -> number,
		Centered: () -> boolean,
		HighlightColor: () -> Color3,
		ShowName: () -> boolean,
		Selected: () -> boolean,
	},
	target: Frame,
}

local function story(props: StoryProps)
	local controls = props.controls
	local clicks = source(0)

	local function blockType(): BlockTypes.BlockType
		return BlockTypes.ByName[controls.Block()]
	end

	return create("Frame")({
		Name = "Backdrop",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = controls.Backdrop,

		create("Frame")({
			Name = "Holder",
			AnchorPoint = function()
				return if controls.Centered() then Vector2.new(0.5, 0.5) else Vector2.zero
			end,
			Position = function()
				return if controls.Centered()
					then UDim2.fromScale(0.5, 0.5)
					else UDim2.fromOffset(16, 16)
			end,
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,

			BlockTile({
				Name = function()
					local override = controls.NameOverride()
					return if override ~= "" then override else blockType().DisplayName
				end,
				Color = function()
					return blockType().Color
				end,
				Count = controls.Count,
				ShowName = controls.ShowName,
				ShowCount = controls.ShowCount,
				IsSelected = controls.Selected,
				IsLocked = controls.Locked,
				Size = controls.TileSize,
				CornerRadius = controls.CornerRadius,
				HighlightColor = controls.HighlightColor,
				HighlightThickness = controls.HighlightThickness,
				Select = function()
					clicks(clicks() + 1)
					print(`Tile clicked {clicks()} times`)
				end,
			}),
		}),
	})
end

return {
	summary = "One hotbar tile in every state.",
	vide = Vide,
	controls = CONTROLS,
	story = story,
}
