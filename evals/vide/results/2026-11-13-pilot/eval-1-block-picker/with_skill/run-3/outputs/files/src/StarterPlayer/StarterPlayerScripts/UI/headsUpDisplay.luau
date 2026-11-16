--!strict
--@author: Crusherfire
--@date: 2026-11-13
--[[@description:
	The in-game HUD: the block hotbar, wired to BlockPlacer. Selecting a slot
	sets BlockPlacer's block type, and any change there (number keys included)
	moves the highlight, so BlockPlacer stays the one owner of the selection.
]]

const Vide = require("@game/ReplicatedStorage/Packages/Vide")

const cleanup = Vide.cleanup
const create = Vide.create
const source = Vide.source

const BlockTypes = require("@game/ReplicatedStorage/Shared/BlockTypes")

const BlockPlacer = require("../BlockPlacer")
const hotbar = require("./hotbar")
const Screen = require("./Screen")

-- Desktop sits at the bottom center. Touch moves to the top center, clear of
-- the thumbstick region (lower left) and the jump button (lower right).
const DESKTOP_ANCHOR = Vector2.new(0.5, 1)
const DESKTOP_POSITION = UDim2.new(0.5, 0, 1, -16)
const TOUCH_ANCHOR = Vector2.new(0.5, 0)
const TOUCH_POSITION = UDim2.new(0.5, 0, 0, 8)

local function headsUpDisplay(): ScreenGui
	const selectedName = source(BlockPlacer.getBlockType())
	cleanup(BlockPlacer.BlockTypeChanged:Connect(function(name: string)
		selectedName(name)
	end))

	return create("ScreenGui")({
		Name = "HeadsUpDisplay",

		create("UIScale")({ Scale = Screen.uiScale }),

		hotbar({
			BlockTypes = BlockTypes.List,
			SelectedName = selectedName,
			Select = BlockPlacer.setBlockType,
			IsCompact = Screen.isTouchLayout,
			ShowsKeyHints = Screen.isKeyboard,
			AnchorPoint = function()
				return if Screen.isTouchLayout() then TOUCH_ANCHOR else DESKTOP_ANCHOR
			end,
			Position = function()
				return if Screen.isTouchLayout() then TOUCH_POSITION else DESKTOP_POSITION
			end,
		}),
	})
end

return headsUpDisplay
