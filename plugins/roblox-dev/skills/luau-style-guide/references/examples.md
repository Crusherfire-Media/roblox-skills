# Examples and reasons

Good / Bad examples and the reasons behind SKILL.md's rules, under the same
section names, plus the rules for the less common cases those sections point
here for.

## Requires

### Grouping requires into blocks

Group requires into blocks that follow the project's folders, in this order,
leaving out any block that would be empty:

1. Every imported package.
2. Members taken out of those packages, split again by subfolder when that
   helps.
3. The project's own modules, split again by subfolder when that helps.

Within that layout:

- Order the blocks alphabetically by the subfolder each one stands for, and
  the lines inside a block by module name.
- Requires that share a subfolder get a block of their own.

### Requiring libraries

A library hands out one top-level table, and that table requires the
library's own modules. Callers depend on the table, so the files behind it
can move or change without breaking them.

- Code inside the library requires its sibling modules, public or private,
  by relative path:

  ```lua
  -- in Pathfinding/Grid
  const Heap = require("./Heap")
  ```

- Code outside the library requires the top-level table and takes public
  modules from it:

  ```lua
  const Pathfinding = require("@game/ReplicatedStorage/Pathfinding")
  const Grid = Pathfinding.Grid
  ```

### Example

With this layout:

```
ShopSystem
|- Catalog
|  |- Prices
|  |- Stock
|- ShopController
|- Packages
   |- Currency
      |- Coins
      |- Gems
```

`ShopController` starts like this:

```lua
-- Packages first, each required through its top-level table.
const Currency = require("./Packages/Currency")

-- Then the members this script uses from those packages.
const Coins = Currency.Coins
const Gems = Currency.Gems

-- Then this project's modules, a block per subfolder.
const Prices = require("./Catalog/Prices")
const Stock = require("./Catalog/Stock")
```

## Blocks

- Conditions go without parentheses; Luau's `then`, `do`, and `until`
  already mark where a condition ends:

  ```lua
  if stock > 0 then
  	restockLabel.Visible = false
  end

  while #pendingOrders > 0 do
  	processOrder(table.remove(pendingOrders, 1))
  end

  repeat
  	placed = tryPlaceBlock(position)
  until placed
  ```

- `== nil` where `false` is a meaningful value and only `nil` means "not
  set":

  ```lua
  if settings.AutoSell == nil then
  	settings.AutoSell = DEFAULT_AUTO_SELL
  end
  ```

- A `do` block with `do` on the same line as the declaration it feeds (the
  Roblox guide gives `do` its own line):

  ```lua
  local nextOrderId do
  	local orderCount = 0
  	nextOrderId = function(): string
  		orderCount += 1
  		return `order-{orderCount}`
  	end
  end
  ```

## Literals

Double quotes are the default for two reasons:

- English text is full of apostrophes, and each one inside single quotes
  needs a backslash.
- An empty string written with two single quotes can look like one double
  quote in some fonts; `""` is unmistakable.

Good: `print("You don't have enough coins")`
Bad: `print('You don\'t have enough coins')`

## Tables

- A table with both array entries and dictionary keys has no single loop
  that walks it cleanly, and its length operator ignores half of it.
- Generalized iteration visits an array's entries in index order, as `ipairs`
  does, and the type checker infers `key` and `value` from the table's type.
- Trailing commas let any line move up or down without editing its
  neighbors, and an added entry shows up as a single new line in the diff:

  ```lua
  local unlockedBiomes = {
  	Desert = true,
  	Forest = true,
  	Tundra = true,
  }
  ```

## Functions

- Readable call sites:

  Good:
  ```lua
  spawnEnemy(position, "Elite")
  createPart(size, { Anchored = true })
  ```
  Bad:
  ```lua
  spawnEnemy(position, true)
  createPart(size, nil, nil, true)
  ```

- Keeping calculation apart from loading means the calculation can run on
  any data, including in a test.

- Calls always use parentheses. Luau accepts a call on a bare string or
  table literal, but the missing parentheses make the line read like
  something other than a call.

  Good:
  ```lua
  local icon = getIcon("Sword")
  local slot = makeSlot({ Index = 1, Size = 64 })
  ```
  Bad:
  ```lua
  local icon = getIcon "Sword"
  local slot = makeSlot{ Index = 1, Size = 64 }
  ```
  The table form is popular in some Lua code and is the easier of the two to
  read, but this style uses parentheses everywhere so every call looks the
  same.

- Function-prefix syntax, with non-member functions `local`.

  Good:
  ```lua
  local function getStackCount(item: Item): number
  	return math.min(item.Quantity, MAX_STACK)
  end
  ```
  Bad:
  ```lua
  -- Without local, this creates a global.
  function getStackCount(item: Item): number
  	return math.min(item.Quantity, MAX_STACK)
  end

  local getStackCount = function(item: Item): number
  	return math.min(item.Quantity, MAX_STACK)
  end
  ```
  The one exception is a function whose body depends on a condition known
  when the script starts:
  ```lua
  local playPlaceSound

  if IS_TOUCH_DEVICE then
  	function playPlaceSound()
  		-- Short click that reads well on phone speakers
  	end
  else
  	function playPlaceSound()
  		-- Full thud with reverb tail
  	end
  end
  ```

- Functions in tables choose `.` or `:` to match the intended calling
  convention: methods for a module that owns a system (mimicking Roblox
  services), dot functions for a library of helpers (mimicking `task` and
  `table`), and `.new` for constructors.

  Good:
  ```lua
  -- Called as Backpack.new(player)
  function Backpack.new(player: Player)
  	return setmetatable({ Owner = player, Items = {} }, Backpack)
  end

  -- Called as backpack:Open()
  function Backpack:Open()
  	self.IsOpen = true
  end
  ```
  Bad:
  ```lua
  -- A dot with an untyped self: write a colon. The dot form exists only to
  -- annotate self's type, and then the name keeps method casing.
  function Backpack.close(self)
  	self.IsOpen = false
  end

  Backpack.create = function(player)
  	return setmetatable({ Owner = player, Items = {} }, Backpack)
  end
  ```

- The same number of values from every path:

  ```lua
  local function getAmmo(inventory: Inventory): number?
  	local weapon = inventory.SelectedWeapon
  	if not weapon or weapon.Kind ~= "Gun" then
  		return nil
  	end

  	return weapon.Ammo
  end
  ```

- Builtins through their library: Luau already makes the direct call fast,
  and an alias leaves the reader unsure whether `insert` is a builtin or a
  custom function.

## Types

These rules decide where annotations go and how to shape types so the
checker catches bugs.

- A fully typed public function:

  ```lua
  function Module.dealDamage(humanoid: Humanoid, damage: number): number
  ```

- A map read with keys that may be missing:

  ```lua
  local points: { [Player]: number? } = {}

  local function givePoints(player: Player, amount: number)
  	local current = points[player]
  	points[player] = (current or 0) + amount
  end
  ```

### Enums

With an enum as exported string literals, a typo is a type error, and the
values autocomplete.

When a branch must handle every member, end the `if` chain with
`exhaustiveMatch`. An unhandled member reaches its `never` parameter and the
checker reports it. Keep one copy of the helper in a shared utility library:

```lua
local function exhaustiveMatch(value: never): never
	error(`Unhandled enum value: {value}`)
end

local function getDropChance(rarity: Rarity): number
	if rarity == "Common" then
		return 0.7
	elseif rarity == "Rare" then
		return 0.25
	elseif rarity == "Epic" then
		return 0.05
	else
		return exhaustiveMatch(rarity)
	end
end
```

### Values from clients

Anything a client sends arrives unchecked, whatever the handler's annotations
say. Type every argument after `player` in an `OnServerEvent` or
`OnServerInvoke` handler as `unknown`, then narrow it with `typeof` and range
checks, returning early when a check fails. An annotation such as
`slot: number` makes the checker trust the client; `unknown` makes it refuse
every use until the value is checked. Every comparison with NaN is false, so
shape range checks to reject it (`slot ~= math.floor(slot)` below does):

```lua
EquipRemote.OnServerEvent:Connect(function(player: Player, slot: unknown)
	if
		typeof(slot) ~= "number"
		or slot ~= math.floor(slot)
		or slot < 1
		or slot > MAX_SLOTS
	then
		return
	end

	equipSlot(player, slot)
end)
```

## Comments

- Several line comments for a note over several lines:

  ```lua
  -- Blocks placed in the same frame as a plot reset would land on the old
  -- grid, so placement waits for the reset to finish.
  if plot:IsResetting() then
  	plot.ResetFinished:Wait()
  end
  ```

- A block comment above a function:

  ```lua
  --[[
  	Refunds every block on the plot at its full price.

  	Only the server calls this, after the owner leaves, because a refund
  	during play would let a player sell and rebuy blocks for free.
  ]]
  local function refundPlot(plot: Plot)
  end
  ```

- Explain why, not what.

  Good:
  ```lua
  -- Stock restocks on the server clock, so a client with a skewed clock
  -- still sees the same restock time as everyone else.
  local restockAt = workspace:GetServerTimeNow() + RESTOCK_SECONDS
  ```
  Bad:
  ```lua
  -- Get the server time and add the restock seconds.
  local restockAt = workspace:GetServerTimeNow() + RESTOCK_SECONDS
  ```

## Naming

- Full words cost a few keystrokes once and save the reader a guess every
  time the name appears.
- Roblox's older `camelCase` API names are mostly deprecated, though they
  still run.
- The `Async` suffix is there because yielding explains why (see Yielding).
- The returned table is named `Module` because the instance name already
  says what the module is.
- `RGB` in `hexToRGB` keeps its capitals because each letter names a
  separate channel (red, green, blue), not a word squeezed into an acronym.
- Luau enforces no privacy on table members, so the leading underscore is
  the only signal that outside code is reaching where it should not.

ModuleScript `ShopCatalog`:

```lua
const SALE_DISCOUNT = 0.2

local Module = {}

Module.RestockSeconds = 300

function Module.getSalePrice(price: number): number
	return math.floor(price * (1 - SALE_DISCOUNT))
end

return Module
```

## Yielding

Roblox lets any function yield without the caller writing coroutine code,
which keeps calls simple. The price is that a yield in the middle of a
function lets other code run and change shared state before the function
resumes, and those races are hard to reproduce. A callback is enough to
cause one:

```lua
local stock = 10

local function sellOne(onSold: (number) -> ())
	local remaining = stock - 1
	onSold(remaining) -- a yield in onSold lets another sale read the old stock
	stock = remaining
end
```

Use a Promise or Future where it earns its place: chaining several async
steps, racing or canceling them, or sharing one pending result with several
callers. A single yielding call stays a plain `Async` function.

## Error handling

```lua
local function purchaseItem(player: Player, itemId: string): (boolean, string?)
	assert(itemId ~= "", "itemId must not be empty")

	local price = Prices.get(itemId)
	if not price then
		return false, "UnknownItem"
	end

	if not Wallet.trySpend(player, price) then
		return false, "NotEnoughCoins"
	end

	return true, nil
end
```

- Throwing has real benefits: an error the caller ignores still travels up
  the stack, and it arrives with a stack trace attached.
- It also has costs. A thrown error is usually a plain string, so callers
  cannot easily tell one failure from another, and nothing in the signature
  warns that the function can fail. A `success, result` return makes every
  caller decide what to do about failure.

Calling code that throws:

```lua
local saved, saveError = pcall(saveMoney, player, 100)

local loaded, data = pcall(function()
	return dataStore:GetAsync(key)
end)
```

### Assertions

- The message stays a constant string because `assert` evaluates its message
  argument on every call, pass or fail, so building it there costs work even
  when nothing is wrong. When it needs values:

  ```lua
  if gold < price then
  	error(`Player has {gold} gold but needs {price}`)
  end
  ```

- `assert` stays out of hot paths because every call costs a little even when
  it passes, and that adds up over thousands of calls per frame (the
  `roblox-dev:roblox-performance` skill has the numbers).
