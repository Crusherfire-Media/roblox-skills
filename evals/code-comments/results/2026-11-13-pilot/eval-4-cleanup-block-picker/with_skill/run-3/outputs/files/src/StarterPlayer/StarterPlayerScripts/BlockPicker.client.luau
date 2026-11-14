--!strict
--# selene: allow(mixed_table)
--[[@description:
	The block picker: one button per block type along the bottom of the screen.
	The player picks with a click, a tap, or the number keys 1 to 5.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Vide = require(ReplicatedStorage.Packages.Vide)

local create = Vide.create
local source = Vide.source
local mount = Vide.mount

local BLOCK_ORDER = { "Brick", "Dirt", "Grass", "Window", "Wood" }

-- By index into BLOCK_ORDER
local HOTKEYS =
	{ Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five }

local BLOCK_COLORS: { [string]: Color3 } = {
	Brick = Color3.fromRGB(151, 63, 46),
	Dirt = Color3.fromRGB(110, 76, 48),
	Grass = Color3.fromRGB(86, 140, 56),
	Window = Color3.fromRGB(170, 210, 230),
	Wood = Color3.fromRGB(150, 110, 70),
}

local BUTTON_SIZE = 72
local BUTTON_GAP = 8

local localPlayer = Players.LocalPlayer

local selected = source("Grass")

local function selectBlock(name: string)
	selected(name)
	-- PlacementController reads this attribute; keep the name in sync with it
	localPlayer:SetAttribute("SelectedBlock", name)
end

local function BlockButton(name: string, order: number)
	return create("TextButton")({
		Name = name,
		LayoutOrder = order,
		Size = UDim2.fromOffset(BUTTON_SIZE, BUTTON_SIZE),
		BackgroundColor3 = BLOCK_COLORS[name],
		Text = tostring(order), -- show the hotkey number
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 20,
		FontFace = Font.fromEnum(Enum.Font.GothamBold),

		-- Activated also fires for touch and gamepad; MouseButton1Click doesn't
		Activated = function()
			selectBlock(name)
		end,

		create("UICorner")({
			CornerRadius = UDim.new(0, 8),
		}),
		create("UIStroke")({
			Color = Color3.new(1, 1, 1),
			Thickness = function()
				return if selected() == name then 3 else 0
			end,
		}),
	})
end

local function BlockPicker()
	local buttons = {}
	for index, name in BLOCK_ORDER do
		table.insert(buttons, BlockButton(name, index))
	end

	return create("ScreenGui")({
		Name = "BlockPicker",
		ResetOnSpawn = false,

		create("Frame")({
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -24),
			Size = UDim2.fromOffset(0, BUTTON_SIZE),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,

			create("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, BUTTON_GAP),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			buttons,
		}),
	})
end

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	-- Skip keys typed into a TextBox, such as chat
	if gameProcessed then
		return
	end

	local index = table.find(HOTKEYS, input.KeyCode)
	if index then
		selectBlock(BLOCK_ORDER[index])
	end
end)

-- TODO: let gamepad players cycle blocks with the shoulder buttons

mount(BlockPicker, localPlayer:WaitForChild("PlayerGui"))

-- Give PlacementController a value from the start
selectBlock(selected())
