--[[
	Client side of block placement: keeps track of the selected block type and asks the server to
	place it where the player clicks or taps in the world. Number keys 1 to 5 select a block type.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)

local RAY_LENGTH = 512
local NUMBER_KEYS = {
	Enum.KeyCode.One,
	Enum.KeyCode.Two,
	Enum.KeyCode.Three,
	Enum.KeyCode.Four,
	Enum.KeyCode.Five,
}

local BlockPlacer = {}

local selectedName = BlockTypes.List[1].Name
local isEnabled = true
local hasStarted = false
local placeBlock: RemoteEvent? = nil
local blockTypeChanged = Instance.new("BindableEvent")

--[[
	Fires with the new block type's name whenever the selected block type changes.
]]
BlockPlacer.BlockTypeChanged = blockTypeChanged.Event

function BlockPlacer.getBlockType(): string
	return selectedName
end

function BlockPlacer.setBlockType(name: string)
	assert(BlockTypes.ByName[name], `unknown block type {name}`)
	if name == selectedName then
		return
	end
	selectedName = name
	blockTypeChanged:Fire(name)
end

function BlockPlacer.isEnabled(): boolean
	return isEnabled
end

--[[
	Turns placing on or off. While off, clicks and taps in the world place nothing.
]]
function BlockPlacer.setEnabled(enabled: boolean)
	isEnabled = enabled
end

local function placeAt(screenPosition: Vector2)
	local camera = Workspace.CurrentCamera
	if not isEnabled or not placeBlock or not camera then
		return
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local character = Players.LocalPlayer.Character
	if character then
		params.FilterDescendantsInstances = { character }
	end

	-- ScreenPointToRay takes positions below the topbar inset, as input positions are.
	local ray = camera:ScreenPointToRay(screenPosition.X, screenPosition.Y)
	local result = Workspace:Raycast(ray.Origin, ray.Direction * RAY_LENGTH, params)
	if not result then
		return
	end

	local cellPosition = result.Position + result.Normal * (BlockTypes.BlockSize / 2)
	placeBlock:FireServer(selectedName, cellPosition)
end

local function onInputBegan(input: InputObject, gameProcessedEvent: boolean)
	if gameProcessedEvent then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		placeAt(Vector2.new(input.Position.X, input.Position.Y))
		return
	end

	local index = table.find(NUMBER_KEYS, input.KeyCode)
	if index and BlockTypes.List[index] then
		BlockPlacer.setBlockType(BlockTypes.List[index].Name)
	end
end

local function onTouchTapInWorld(position: Vector2, processedByUI: boolean)
	if processedByUI then
		return
	end
	placeAt(position)
end

--[[
	Connects input and finds the server's PlaceBlock remote. Yields until the remote exists, so
	call it after any UI is mounted or from its own thread.
]]
function BlockPlacer.start()
	if hasStarted then
		return
	end
	hasStarted = true

	UserInputService.InputBegan:Connect(onInputBegan)
	UserInputService.TouchTapInWorld:Connect(onTouchTapInWorld)

	local remote = ReplicatedStorage:WaitForChild("PlaceBlock")
	assert(remote:IsA("RemoteEvent"), "PlaceBlock must be a RemoteEvent")
	placeBlock = remote
end

return BlockPlacer
