--!strict
--[[
	The in-game HUD. Connects the hotbar to BlockPlacer, so it follows number
	key switches and its slots select the block type BlockPlacer places.
]]

const Vide = require("@game/ReplicatedStorage/Packages/Vide")

const cleanup = Vide.cleanup
const create = Vide.create
const source = Vide.source

const BlockPlacer = require("./BlockPlacer")
const BlockTypes = require("@game/ReplicatedStorage/Shared/BlockTypes")
const hotbar = require("./Hotbar")
const Screen = require("./Screen")

const HOTBAR_ANCHOR = Vector2.new(0.5, 1)
const DESKTOP_BOTTOM_MARGIN = 16
const COMPACT_BOTTOM_MARGIN = 8

local function hud(): ScreenGui
	const selected = source(BlockPlacer.getBlockType())
	cleanup(BlockPlacer.BlockTypeChanged:Connect(function(name: string)
		selected(name)
	end))

	return create("ScreenGui")({
		Name = "Hud",
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,

		create("UIScale")({ Scale = Screen.uiScale }),

		hotbar({
			BlockTypes = BlockTypes.List,
			Selected = selected,
			Select = function(name: string)
				-- Set here too, so the highlight moves on this frame instead of
				-- after the deferred BlockTypeChanged event.
				selected(name)
				BlockPlacer.setBlockType(name)
			end,
			IsCompact = Screen.isPhone,
			ShowKeyHints = Screen.isKeyboardAndMouse,
			AnchorPoint = HOTBAR_ANCHOR,
			Position = function()
				const margin = if Screen.isPhone()
					then COMPACT_BOTTOM_MARGIN
					else DESKTOP_BOTTOM_MARGIN
				return UDim2.new(0.5, 0, 1, -margin)
			end,
		}),
	})
end

return hud
