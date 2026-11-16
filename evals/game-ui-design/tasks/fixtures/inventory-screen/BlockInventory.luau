--[[
	The local player's block inventory: how many of each block type they hold, and which types are
	still locked behind a player level. It holds sample numbers until the server sync is written.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)

-- Player level each block type unlocks at. Types not listed are unlocked from level 1.
local UNLOCK_LEVELS: { [string]: number } = {
	Ice = 4,
	Lamp = 6,
	Gold = 10,
}

local SAMPLE_LEVEL = 3
local SAMPLE_COUNTS: { [string]: number } = {
	Brick = 48,
	Dirt = 120,
	Grass = 64,
	Window = 0,
	Wood = 35,
	Stone = 999,
	Sand = 12,
	Ice = 0,
	Lamp = 0,
	Gold = 0,
}

local BlockInventory = {}

local level = SAMPLE_LEVEL
local counts: { [string]: number } = table.clone(SAMPLE_COUNTS)
local changed = Instance.new("BindableEvent")

--[[
	Fires with no arguments whenever a count or the player's level changes.
]]
BlockInventory.Changed = changed.Event

function BlockInventory.getLevel(): number
	return level
end

function BlockInventory.getCount(name: string): number
	assert(BlockTypes.ByName[name], `unknown block type {name}`)
	return counts[name] or 0
end

--[[
	The player level the block type unlocks at; 1 for types every player starts with.
]]
function BlockInventory.getUnlockLevel(name: string): number
	assert(BlockTypes.ByName[name], `unknown block type {name}`)
	return UNLOCK_LEVELS[name] or 1
end

function BlockInventory.isUnlocked(name: string): boolean
	return level >= BlockInventory.getUnlockLevel(name)
end

function BlockInventory.setCount(name: string, count: number)
	assert(BlockTypes.ByName[name], `unknown block type {name}`)
	counts[name] = count
	changed:Fire()
end

function BlockInventory.setLevel(newLevel: number)
	level = newLevel
	changed:Fire()
end

return BlockInventory
