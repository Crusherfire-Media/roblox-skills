--[[
	How many blocks of each type a player has left to place. The server keeps one inventory per
	player; placing a block takes one of its type, and breaking one gives it back.
]]

export type Inventory = {
	Counts: { [string]: number },
}

local BlockInventory = {}

-- Most blocks of one type an inventory can hold.
BlockInventory.MaxStack = 99

--[[
	Creates an inventory holding the given counts, for example { Brick = 20, Dirt = 10 }. Block
	types left out start at zero.
]]
function BlockInventory.new(counts: { [string]: number }?): Inventory
	local inventory: Inventory = { Counts = {} }
	if counts then
		for name, count in counts do
			inventory.Counts[name] = math.clamp(count, 0, BlockInventory.MaxStack)
		end
	end
	return inventory
end

function BlockInventory.count(inventory: Inventory, name: string): number
	return inventory.Counts[name] or 0
end

--[[
	Adds up to amount blocks of a type, stopping at MaxStack. Returns how many were added.
]]
function BlockInventory.add(inventory: Inventory, name: string, amount: number): number
	local current = inventory.Counts[name] or 0
	local added = math.clamp(amount, 0, BlockInventory.MaxStack - current)
	inventory.Counts[name] = current + added
	return added
end

--[[
	Takes amount blocks of a type when the inventory holds at least that many and returns true.
	Otherwise changes nothing and returns false.
]]
function BlockInventory.take(inventory: Inventory, name: string, amount: number): boolean
	local current = inventory.Counts[name]
	if current and current < amount then
		return false
	end
	inventory.Counts[name] = (current or 0) - amount
	return true
end

return BlockInventory
