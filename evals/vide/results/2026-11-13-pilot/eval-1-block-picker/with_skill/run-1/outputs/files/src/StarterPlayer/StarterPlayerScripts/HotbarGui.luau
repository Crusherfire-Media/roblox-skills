--!strict
--@author: Crusherfire
--@date: 11/13/2026
--[[@description:
	The hotbar ScreenGui: connects the hotbar to BlockPlacer, so it shows the
	selected block type however it was chosen and selects the slot pressed.
]]

const Vide = require("@game/ReplicatedStorage/Packages/Vide")

const cleanup = Vide.cleanup
const create = Vide.create
const source = Vide.source

const BlockPlacer = require("./BlockPlacer")
const BlockTypes = require("@game/ReplicatedStorage/Shared/BlockTypes")
const Hotbar = require("./Hotbar")
const Screen = require("./Screen")

const BOTTOM_CENTER = Vector2.new(0.5, 1)
const HOTBAR_POSITION = UDim2.new(0.5, 0, 1, -16)

local function hotbarGui(): ScreenGui
	const selectedName = source(BlockPlacer.getBlockType())

	cleanup(BlockPlacer.BlockTypeChanged:Connect(function(name: string)
		selectedName(name)
	end))

	return create("ScreenGui")({
		Name = "Hotbar",

		create("UIScale")({ Scale = Screen.uiScale }),

		Hotbar({
			BlockTypes = BlockTypes.List,
			SelectedName = selectedName,
			ShowKeyHints = function()
				return not Screen.isTouch()
			end,
			Select = BlockPlacer.setBlockType,
			AnchorPoint = BOTTOM_CENTER,
			Position = HOTBAR_POSITION,
		}),
	})
end

return hotbarGui
