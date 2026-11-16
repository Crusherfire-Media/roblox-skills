--[[
	The in-game HUD: the coin counter, the menu buttons with their tooltips, the community banner,
	and the toast that announces rewards.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Vide = require(ReplicatedStorage.Packages.Vide)

local cleanup = Vide.cleanup
local create = Vide.create
local show = Vide.show
local source = Vide.source

local IS_MOBILE = UserInputService.TouchEnabled
local BUTTON_SIZE = if IS_MOBILE then 36 else 32
local BUTTON_GAP = 6
local PULSE_SPEED = 6
local PULSE_AMOUNT = 0.08
local HUD_TEXT_COLOR = Color3.fromRGB(255, 255, 255)
local BUTTON_COLOR = Color3.fromRGB(255, 170, 0)
local TOOLTIP_COLOR = Color3.fromRGB(20, 20, 24)

-- Icon art is uploaded later; the menu reads these ids.
local MENU_BUTTONS = {
	{ Name = "Inventory", Icon = "rbxassetid://0" },
	{ Name = "Settings", Icon = "rbxassetid://0" },
	{ Name = "Rewards", Icon = "rbxassetid://0" },
}

export type HudProps = {
	Coins: () -> number,
	-- Text of the toast on screen, or nil when none is showing.
	Toast: () -> string?,
	OpenMenu: (name: string) -> (),
}

local function menuButton(
	name: string,
	icon: string,
	layoutOrder: number,
	hovered: Vide.Source<string?>,
	open: (name: string) -> ()
): ImageButton
	local scale = source(1)
	if name == "Rewards" then
		-- Draws the eye to unclaimed rewards.
		cleanup(RunService.Heartbeat:Connect(function()
			scale(1 + PULSE_AMOUNT * math.sin(os.clock() * PULSE_SPEED))
		end))
	end

	return create("ImageButton")({
		Name = name,
		LayoutOrder = layoutOrder,
		Size = UDim2.fromOffset(BUTTON_SIZE, BUTTON_SIZE),
		BackgroundColor3 = BUTTON_COLOR,
		Image = icon,

		MouseEnter = function()
			hovered(name)
		end,
		MouseLeave = function()
			if hovered() == name then
				hovered(nil)
			end
		end,
		MouseButton1Click = function()
			open(name)
		end,

		create("UICorner")({ CornerRadius = UDim.new(0, 6) }),
		create("UIScale")({ Scale = scale }),
	})
end

local function hud(props: HudProps): { Instance }
	local hovered: Vide.Source<string?> = source(nil :: string?)

	local buttons = {}
	for index, button in MENU_BUTTONS do
		buttons[index] = menuButton(button.Name, button.Icon, index, hovered, props.OpenMenu)
	end

	return {
		create("TextLabel")({
			Name = "Coins",
			Position = UDim2.fromOffset(8, 8),
			Size = UDim2.fromOffset(140, 32),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextScaled = true,
			TextColor3 = HUD_TEXT_COLOR,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = function()
				return `Coins: {props.Coins()}`
			end,
		}),

		create("Frame")({
			Name = "Menu",
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -12, 1, -12),
			Size = UDim2.fromOffset(BUTTON_SIZE, #MENU_BUTTONS * BUTTON_SIZE + 2 * BUTTON_GAP),
			BackgroundTransparency = 1,

			create("UIListLayout")({
				FillDirection = Enum.FillDirection.Vertical,
				Padding = UDim.new(0, BUTTON_GAP),
			}),

			buttons,
		}),

		show(function()
			return hovered() ~= nil
		end, function()
			return create("TextLabel")({
				Name = "Tooltip",
				AnchorPoint = Vector2.new(1, 1),
				Position = UDim2.new(1, -BUTTON_SIZE - 20, 1, -12),
				Size = UDim2.fromOffset(110, 26),
				BackgroundColor3 = TOOLTIP_COLOR,
				Font = Enum.Font.Gotham,
				TextScaled = true,
				TextColor3 = HUD_TEXT_COLOR,
				Text = function()
					return hovered() or ""
				end,
			})
		end),

		create("TextLabel")({
			Name = "Community",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -4),
			Size = UDim2.fromOffset(420, 20),
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			TextScaled = true,
			TextColor3 = HUD_TEXT_COLOR,
			Text = "Join our Discord for free codes! discord.gg/blockbuilders",
		}),

		show(function()
			return props.Toast() ~= nil
		end, function()
			return create("TextLabel")({
				Name = "Toast",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.4),
				Size = UDim2.fromOffset(200, 40),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBlack,
				TextScaled = true,
				TextColor3 = BUTTON_COLOR,
				Text = function()
					return props.Toast() or ""
				end,
			})
		end),
	}
end

return hud
