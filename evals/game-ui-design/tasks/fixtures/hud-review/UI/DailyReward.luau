--[[
	The daily reward popup: a row of seven days, the streak, and a claim button. Main opens it as
	soon as the player joins.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.Vide)

local create = Vide.create

local DAY_COUNT = 7
local DAY_SIZE = 48
local DAY_GAP = 8
local PANEL_SIZE = Vector2.new(520, 340)
local PANEL_COLOR = Color3.fromRGB(240, 240, 240)
local TITLE_COLOR = Color3.fromRGB(255, 170, 0)
local BODY_COLOR = Color3.fromRGB(150, 150, 150)
local CLAIMED_COLOR = Color3.fromRGB(130, 130, 130)
local TODAY_COLOR = Color3.fromRGB(80, 200, 90)
local FUTURE_COLOR = Color3.fromRGB(200, 200, 200)
local DIM_COLOR = Color3.fromRGB(0, 0, 0)

export type DailyRewardProps = {
	-- Days already claimed in the current streak; today is the day after them.
	StreakDays: () -> number,
	-- Seconds left before today's reward expires and the streak resets.
	SecondsLeft: () -> number,
	Claim: () -> (),
	Close: () -> (),
}

local function formatTime(seconds: number): string
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

local function dayTile(day: number, streakDays: () -> number): Frame
	return create("Frame")({
		Name = `Day{day}`,
		LayoutOrder = day,
		Size = UDim2.fromOffset(DAY_SIZE, DAY_SIZE),
		BackgroundColor3 = function()
			local claimed = streakDays()
			if day <= claimed then
				return CLAIMED_COLOR
			elseif day == claimed + 1 then
				return TODAY_COLOR
			end
			return FUTURE_COLOR
		end,

		create("UICorner")({ CornerRadius = UDim.new(0, 6) }),

		create("TextLabel")({
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextScaled = true,
			TextColor3 = Color3.new(1, 1, 1),
			Text = tostring(day),
		}),
	})
end

local function dailyReward(props: DailyRewardProps): Frame
	local days = {}
	for day = 1, DAY_COUNT do
		days[day] = dayTile(day, props.StreakDays)
	end

	return create("Frame")({
		Name = "DailyReward",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = DIM_COLOR,
		BackgroundTransparency = 0.4,
		Active = true,
		ZIndex = 10,

		create("Frame")({
			Name = "Panel",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(PANEL_SIZE.X, PANEL_SIZE.Y),
			BackgroundColor3 = PANEL_COLOR,
			ZIndex = 10,

			create("UICorner")({ CornerRadius = UDim.new(0, 12) }),

			create("TextLabel")({
				Name = "Title",
				Position = UDim2.fromOffset(20, 16),
				Size = UDim2.new(1, -40, 0, 48),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBlack,
				TextScaled = true,
				TextColor3 = TITLE_COLOR,
				Text = "DAILY REWARD!",
				ZIndex = 10,
			}),

			create("TextButton")({
				Name = "Close",
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -8, 0, 8),
				Size = UDim2.fromOffset(24, 24),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				TextScaled = true,
				TextColor3 = BODY_COLOR,
				Text = "X",
				ZIndex = 11,

				MouseButton1Click = props.Close,
			}),

			create("Frame")({
				Name = "Days",
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 84),
				Size = UDim2.fromOffset(DAY_COUNT * DAY_SIZE + (DAY_COUNT - 1) * DAY_GAP, DAY_SIZE),
				BackgroundTransparency = 1,
				ZIndex = 10,

				create("UIListLayout")({
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = UDim.new(0, DAY_GAP),
				}),

				days,
			}),

			create("TextLabel")({
				Name = "Streak",
				Position = UDim2.fromOffset(20, 152),
				Size = UDim2.new(1, -40, 0, 64),
				BackgroundTransparency = 1,
				Font = Enum.Font.Gotham,
				TextScaled = true,
				TextWrapped = true,
				TextColor3 = BODY_COLOR,
				Text = function()
					return `Claim in {formatTime(props.SecondsLeft())} or lose your {props.StreakDays()}-day streak! Come back every day so you don't lose your progress.`
				end,
				ZIndex = 10,
			}),

			create("TextButton")({
				Name = "Claim",
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, 0, 1, -20),
				Size = UDim2.fromOffset(120, 36),
				BackgroundColor3 = TODAY_COLOR,
				Font = Enum.Font.GothamBold,
				TextScaled = true,
				TextColor3 = Color3.new(1, 1, 1),
				Text = "CLAIM",
				ZIndex = 10,

				MouseButton1Click = props.Claim,

				create("UICorner")({ CornerRadius = UDim.new(0, 8) }),
			}),
		}),
	})
end

return dailyReward
