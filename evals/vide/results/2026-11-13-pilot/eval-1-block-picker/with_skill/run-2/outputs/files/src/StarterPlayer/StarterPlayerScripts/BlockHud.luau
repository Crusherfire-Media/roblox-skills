--[[
	The block placement HUD: connects the hotbar to BlockPlacer and places it along the bottom
	of the screen, between Roblox's thumbstick region and jump button when those are showing.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BlockPlacer = require(script.Parent.BlockPlacer)
local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
local Hotbar = require(script.Parent.Hotbar)
local Screen = require(script.Parent.Screen)
local Vide = require(ReplicatedStorage.Packages.Vide)

local cleanup = Vide.cleanup
local create = Vide.create
local source = Vide.source

local BOTTOM_MARGIN = 12
local EDGE_PADDING = 8

-- Default PlayerModule touch controls, in real pixels. The dynamic thumbstick takes presses
-- across the left 40 percent of the screen, and the jump button's left edge sits this far from
-- the right edge, by whether the screen's short side is over 500.
local THUMBSTICK_REGION_WIDTH = 0.4
local SMALL_TOUCH_SHORT_SIDE = 500
local SMALL_JUMP_BUTTON_LEFT = 95
local LARGE_JUMP_BUTTON_LEFT = 170

local BlockHud = {}

--[[
	Horizontal center of the hotbar in UI units, so it sits in the free span between the
	thumbstick region and the jump button, or in the middle of the screen without them.
]]
local function hotbarCenterX(hotbarWidth: number): number
	local viewport = Screen.viewport()
	if not Screen.isTouch() then
		return math.floor(viewport.X / 2)
	end

	local scale = Screen.uiScale()
	local realShortSide = math.min(viewport.X, viewport.Y) * scale
	local jumpButtonLeft = if realShortSide > SMALL_TOUCH_SHORT_SIDE
		then LARGE_JUMP_BUTTON_LEFT
		else SMALL_JUMP_BUTTON_LEFT
	local freeLeft = viewport.X * THUMBSTICK_REGION_WIDTH
	local freeRight = viewport.X - jumpButtonLeft / scale
	local center = (freeLeft + freeRight) / 2

	local halfWidth = hotbarWidth / 2
	local minimum = halfWidth + EDGE_PADDING
	local maximum = math.max(minimum, viewport.X - halfWidth - EDGE_PADDING)
	return math.floor(math.clamp(center, minimum, maximum))
end

function BlockHud.new(): ScreenGui
	local selected = source(BlockPlacer.getBlockType())
	cleanup(BlockPlacer.BlockTypeChanged:Connect(function(name: string)
		selected(name)
	end))

	return create("ScreenGui")({
		Name = "BlockHud",

		create("UIScale")({ Scale = Screen.uiScale }),

		create("Frame")({
			Name = "HotbarDock",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 1),
			Position = function()
				local size = Hotbar.size(Screen.isTouchLayout(), #BlockTypes.List)
				return UDim2.new(0, hotbarCenterX(size.X), 1, -BOTTOM_MARGIN)
			end,
			AutomaticSize = Enum.AutomaticSize.XY,

			Hotbar.new({
				BlockTypes = BlockTypes.List,
				Selected = selected,
				OnSelect = BlockPlacer.setBlockType,
				IsCompact = Screen.isTouchLayout,
				ShowKeyHints = function()
					return not Screen.isTouch()
				end,
			}),
		}),
	})
end

return BlockHud
