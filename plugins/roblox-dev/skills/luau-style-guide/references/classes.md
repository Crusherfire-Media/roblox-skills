# Classes, data, and metatables

How to pick the shape of new state or a new kind of object, how a class is
built, and the two uses metatables are limited to.

## Classes and data

Choose a shape for each thing from what it needs, not from habit:

- A class when the thing has behavior and a lifetime of its own: it is
  created, reacts to events, and is torn down, such as a door or an enemy's
  controller.
- Plain typed tables and functions when the data is stored, sent over the
  network, or held in Charm. Metatables are lost through RemoteEvents and
  DataStores, and Charm state changes by replacing tables, not by calling
  methods.
- Arrays of plain data processed by one loop (data-oriented design) when many
  similar things update in bulk, such as projectiles or crops. One loop over
  plain data is cheaper and easier to follow than thousands of objects, each
  with its own methods and connections.
- An entity component system when many entities mix and match behaviors.
  Adding an ECS library to a place is the user's call.

Build classes by composition: a class holds the objects it uses ("has a",
"uses a", "can do") instead of extending a base class. In a game laid out by
the `roblox-dev:game-architecture` skill, the one inheritance is a system's
Server and Client services extending its Shared service.

```lua
local self = {
	Health = HealthPool.new(MAX_HEALTH),
	Mover = PathMover.new(model),
}
```

Anything that creates things can tear them down. A class that connects
events, starts threads, or creates instances has a `Destroy` method that
disconnects, cancels, and destroys all of them. Track each one as it is made
(a Trove works well) so `Destroy` cannot miss any. Vide UI follows its own
`cleanup` rule instead (see the `roblox-dev:vide` skill).

## Metatables

Metatables can change what operators do, chain table lookups, and hook into
parts of a table's lifecycle. Limit them to two uses:

- Prototype-based classes.
- Weak tables.

Leave out operator and call metamethods (`__add`, `__call`, and the like):
they surprise readers and never show up in autocomplete. A class may add
`__tostring` (see Optional additions below). Enums are string-literal types,
not metatables (see Types in SKILL.md).

### Prototype-based classes

Use this shape for every class. The type checker understands it, so the
declared instance type tells readers how the class is meant to be used, and
the editor flags code that strays from it.

```lua
local Module = {}
-- Instances look up missing keys here, so methods live on Module and are
-- shared by every instance.
Module.__index = Module

export type Backpack = typeof(setmetatable(
	{} :: {
		Owner: Player,
		Capacity: number,
		Items: { string },
		SelectedIndex: number?,
	},
	Module
))

function Module.new(owner: Player, capacity: number): Backpack
	local self = {
		Owner = owner,
		Capacity = capacity,
		Items = {},
		SelectedIndex = nil,
	}

	return setmetatable(self, Module)
end

function Module:HasRoom(): boolean
	return #self.Items < self.Capacity
end

function Module.AddItem(self: Backpack, itemId: string)
	assert(#self.Items < self.Capacity, "Backpack is full")
	table.insert(self.Items, itemId)
end

return Module
```

What each part is for:

- **`Module.__index = Module`.** The class table is also the metatable of
  every instance. A key missing from an instance, such as a method name, is
  looked up on `Module`.
- **The exported type.** It lists every instance field. Fields appear twice,
  in the type and in `new`, and the checker reports it when the two stop
  matching. Export it only when other modules need it.
- **`new`.** The constructor sets every field the type lists, including ones
  that start as `nil`, so the instance shape is visible in one place.
- **Methods.** Declare them with a colon (`HasRoom`). When the checker needs
  `self` typed explicitly, declare the method with a dot and annotate `self`
  (`AddItem`). It is still a method: it keeps `PascalCase` and callers still
  use a colon.

From another script, the required module is named after its instance:

```lua
const Backpack = require("./Backpack")

local backpack = Backpack.new(player, 12)
backpack:AddItem("Torch") -- found on Backpack through the metatable
print(#backpack.Items) -- 1, read straight from the instance table
```

Optional additions:

- A `__tostring` metamethod, so printing an instance shows something useful
  while debugging.
- A helper that tells instances apart from other tables:

  ```lua
  function Module.isBackpack(value: unknown): boolean
  	return type(value) == "table" and getmetatable(value) == Module
  end
  ```

Private members follow Naming in SKILL.md: a leading underscore.

### Weak tables

A weak table lets the garbage collector drop an entry once nothing else
references it. Use `__mode = "k"` for a cache keyed by objects, so each entry
dies with its key. Cast the empty table to the cache's type so the old type
solver keeps it:

```lua
local boundsCache = setmetatable({} :: { [Shape]: Bounds? }, { __mode = "k" })
```

Weak references follow plain tables, including class instances built from
tables. **A weak table cannot track a Roblox Instance.** The engine keeps the
instance outside the Luau VM, so the collector works on the Luau reference
alone: it can drop an entry while the instance is still in the DataModel, and
collecting the reference never destroys the instance
([Creator Docs: metatables](https://create.roblox.com/docs/luau/metatables)).
Give an Instance-keyed cache explicit eviction tied to the instance's
lifetime, through `Destroying`, ancestry changes, or the owning system's
teardown:

```lua
local partData: { [BasePart]: PartData? } = {}

local function track(part: BasePart, data: PartData)
	partData[part] = data
	part.Destroying:Once(function()
		partData[part] = nil
	end)
end
```
