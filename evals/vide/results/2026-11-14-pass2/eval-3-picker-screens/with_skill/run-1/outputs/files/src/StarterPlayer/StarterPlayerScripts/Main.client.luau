local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BlockPicker = require(script.Parent.BlockPicker)
local BlockPlacer = require(script.Parent.BlockPlacer)
local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
local Screen = require(script.Parent.UI.Screen)
local Vide = require(ReplicatedStorage.Packages.Vide)
local scaledScreenGui = require(script.Parent.UI.scaledScreenGui)

local create = Vide.create
local derive = Vide.derive
local mount = Vide.mount
local source = Vide.source

local COLUMN_ANCHOR = Vector2.new(0, 0.5)
local COLUMN_POSITION = UDim2.new(0, 20, 0.5, 0)
local ROW_ANCHOR = Vector2.new(0.5, 1)
local EDGE_PADDING = 16
-- Keeps the Row layout's 52 pixel tiles at 44 or more, the smallest a thumb
-- hits reliably.
local MINIMUM_FIT_SCALE = 0.85

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local selected = source(BlockPlacer.getBlockType())
BlockPlacer.BlockTypeChanged:Connect(function(name: string)
	selected(name)
end)

local function blockPickerDock()
	local layout: () -> BlockPicker.Layout = derive(function(): BlockPicker.Layout
		return if Screen.isTouchLayout() then "Row" else "Column"
	end)

	local function designSize(): Vector2
		return BlockPicker.designSize(layout(), #BlockTypes.List)
	end

	local function room(): Vector2
		local usable = Screen.usableSize()
		local height = usable.Y - EDGE_PADDING * 2
		if layout() == "Row" then
			local span = Screen.bottomTouchSpan()
			return Vector2.new(span.Right - span.Left - EDGE_PADDING * 2, height)
		end
		return Vector2.new(usable.X - EDGE_PADDING * 2, height)
	end

	return create("Frame")({
		Name = "BlockPickerDock",
		BackgroundTransparency = 1,
		AnchorPoint = function()
			return if layout() == "Row" then ROW_ANCHOR else COLUMN_ANCHOR
		end,
		Position = function()
			if layout() == "Column" then
				return COLUMN_POSITION
			end
			-- Centered in the gap between the thumbstick and the jump button.
			local span = Screen.bottomTouchSpan()
			return UDim2.new(0, math.round((span.Left + span.Right) / 2), 1, -EDGE_PADDING)
		end,
		Size = function()
			local size = designSize()
			return UDim2.fromOffset(size.X, size.Y)
		end,

		create("UIScale")({
			Scale = function()
				return Screen.fitScale(designSize(), room(), MINIMUM_FIT_SCALE)
			end,
		}),

		BlockPicker.component({
			Layout = layout,
			Selected = selected,
			Select = BlockPlacer.setBlockType,
		}),
	})
end

local function app()
	return scaledScreenGui({
		Name = "BlockPickerGui",
		Children = { blockPickerDock() },
	})
end

mount(app, playerGui)

BlockPlacer.start()
