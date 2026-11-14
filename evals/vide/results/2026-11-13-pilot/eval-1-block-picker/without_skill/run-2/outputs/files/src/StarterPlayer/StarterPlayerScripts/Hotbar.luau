--[[
	Hotbar UI built with Vide: one slot per block type in BlockTypes, with the selected one
	highlighted. Clicking or tapping a slot selects that block type. The selection is read from
	BlockPlacer and kept in sync when it changes elsewhere, for example by the number keys.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
local Vide = require(ReplicatedStorage.Packages.Vide)
local BlockPlacer = require(script.Parent.BlockPlacer)

local create = Vide.create
local source = Vide.source
local derive = Vide.derive
local cleanup = Vide.cleanup
local spring = Vide.spring

-- Slot edge length in pixels. Never below 44 so slots stay easy to tap on phones.
local MIN_SLOT_SIZE = 44
local MAX_SLOT_SIZE = 64
local SLOT_GAP = 6
local BOTTOM_MARGIN = 12

local SLOT_COLOR = Color3.fromRGB(30, 30, 34)
local SELECTED_STROKE_COLOR = Color3.fromRGB(255, 255, 255)
local STROKE_COLOR = Color3.fromRGB(80, 80, 88)

local function Slot(props: {
	index: number,
	blockType: BlockTypes.BlockType,
	selected: () -> boolean,
	size: () -> number,
})
	local blockType = props.blockType
	local selected = props.selected
	local emphasis = spring(function()
		return if selected() then 1 else 0
	end, 0.15)

	return create("TextButton")({
		Name = blockType.Name,
		LayoutOrder = props.index,
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = SLOT_COLOR,
		BackgroundTransparency = function()
			return 0.45 - emphasis() * 0.3
		end,
		Size = function()
			local size = props.size()
			return UDim2.fromOffset(size, size)
		end,
		Activated = function()
			BlockPlacer.setBlockType(blockType.Name)
		end,

		create("UICorner")({ CornerRadius = UDim.new(0, 8) }),
		create("UIStroke")({
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = function()
				return if selected() then SELECTED_STROKE_COLOR else STROKE_COLOR
			end,
			Thickness = function()
				return 1 + emphasis() * 2
			end,
		}),

		-- Block swatch.
		create("Frame")({
			Name = "Swatch",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.45),
			Size = function()
				local scale = 0.5 + emphasis() * 0.08
				return UDim2.fromScale(scale, scale)
			end,
			BackgroundColor3 = blockType.Color,
			BackgroundTransparency = blockType.Transparency * 0.6,
			create("UICorner")({ CornerRadius = UDim.new(0, 4) }),
			create("UIStroke")({ Color = Color3.new(0, 0, 0), Transparency = 0.6 }),
		}),

		-- Block name.
		create("TextLabel")({
			Name = "Label",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -2),
			Size = UDim2.fromScale(0.95, 0.22),
			BackgroundTransparency = 1,
			Text = blockType.DisplayName,
			TextScaled = true,
			Font = Enum.Font.GothamMedium,
			TextColor3 = Color3.new(1, 1, 1),
		}),

		-- Number key hint.
		create("TextLabel")({
			Name = "KeyHint",
			Position = UDim2.fromOffset(4, 2),
			Size = UDim2.fromOffset(12, 12),
			BackgroundTransparency = 1,
			Text = tostring(props.index),
			TextScaled = true,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Color3.fromRGB(200, 200, 200),
		}),
	})
end

--[[
	Builds the hotbar. Call inside a Vide root (for example with Vide.mount); the BlockPlacer
	connection is cleaned up when that root is destroyed.
]]
local function Hotbar()
	local selectedName = source(BlockPlacer.getBlockType())
	local connection = BlockPlacer.BlockTypeChanged:Connect(selectedName)
	cleanup(function()
		connection:Disconnect()
	end)

	-- Size slots to the screen so all five fit on small phones without dropping below a tappable size.
	local camera = Workspace.CurrentCamera
	local viewportSize = source(camera.ViewportSize)
	local viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		viewportSize(camera.ViewportSize)
	end)
	cleanup(function()
		viewportConnection:Disconnect()
	end)

	local slotSize = derive(function()
		local count = #BlockTypes.List
		local fitting = (viewportSize().X * 0.6 - SLOT_GAP * (count - 1)) / count
		return math.floor(math.clamp(fitting, MIN_SLOT_SIZE, MAX_SLOT_SIZE))
	end)

	local slots = {}
	for index, blockType in BlockTypes.List do
		slots[index] = Slot({
			index = index,
			blockType = blockType,
			selected = function()
				return selectedName() == blockType.Name
			end,
			size = slotSize,
		})
	end

	return create("ScreenGui")({
		Name = "Hotbar",
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,

		create("Frame")({
			Name = "Slots",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -BOTTOM_MARGIN),
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,

			create("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Bottom,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, SLOT_GAP),
			}),

			slots,
		}),
	})
end

return Hotbar
