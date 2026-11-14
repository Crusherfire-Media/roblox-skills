# CharmSync reference

Checked against CharmSync for Charm **0.11**. CharmSync copies Charm state from the server to each
client by sending only what changed (delta patches). The server decides which signals each player
receives; the client applies patches to its own signals, and UI reads those.

Place the server half, the client half, and the remotes by the project's architecture rules (with
`roblox-dev:game-architecture`: server code in the server service, client code in the client service, remotes
in the system's Network module).

## Server

```lua
const CharmSync = require(...)

-- Once, at startup: how patches reach a player.
CharmSync.server.connect(function(player, payloads)
    syncRemote:FireClient(player, payloads)
end)

-- When a player's client says it is ready:
CharmSync.server.addSignalsToClient(player, {
    RoundStatus = RoundService.getStatus,
    [`Inventory-{player.UserId}`] = Charm.computed(function()
        return InventoryService.getInventories()[player.UserId]
    end),
})

-- When the player leaves:
CharmSync.server.removeClient(player)
```

- `addSignalsToClient(player, getters)` accepts signal getters, computed getters, atoms, and Deep
  Charm proxies. Call it again to add more; `removeSignalsFromClient(player, ...keys)` removes
  some.
- A key names one signal for every player. Per-player data needs a key unique to that player (as
  above); two players with the same key but different signals trigger a warning.
- `connect(callback)` sends at `CharmSync.config.interval` seconds (default `0`, once per frame).
  `disconnect()` stops the automatic sends; `flush()` sends pending patches now.

## Client

```lua
local getRoundStatus, setRoundStatus = Charm.signal("Waiting")
local getInventory, setInventory = Charm.signal({})

CharmSync.client.addSignals({
    RoundStatus = setRoundStatus,
    [`Inventory-{Players.LocalPlayer.UserId}`] = setInventory,
})

syncRemote.OnClientEvent:Connect(function(payloads)
    CharmSync.client.patch(payloads)
end)

readyRemote:FireServer()
```

- `addSignals(setters)` takes setters, atoms, or Deep Charm proxies, with keys matching the server.
  `removeSignals(...keys)` stops updates and keeps the last values.
- The first payload holds the full state; later ones hold only changes. `patch` applies each
  payload inside `Charm.batch`, so bridged UI updates once per payload.
- Connect `OnClientEvent` before firing the ready remote, so the first payload is not missed.

## For UI

- The client's synced getters are what the UI bridges with `useSignalState`.
- The UI never sets a synced signal: the next patch overwrites it. Changes go to the server through
  a remote, and come back through the sync.
- `signalToAtom(getter, setter)` (from CharmSync) joins a getter and setter into one atom, so one
  shared table of atoms can feed both `addSignalsToClient` and `addSignals`.

## Payload caveats

- Removed values travel as a special `None` marker (`{ __none = "__none" }`); `CharmSync.isNone(v)`
  detects it. Code that inspects or serializes payloads must expect it.
- `config.fixArrays` (default `true`) rewrites sparse arrays so remotes do not drop entries. Turn it
  off when a networking library serializes payloads itself (Zap, ByteNet).
- `config.validatePatches` (default `true`) warns in strict mode about sparse arrays or mixed tables
  in synced state.
- `config.preserveHistory` (default `false`) sends every change since the last sync instead of only
  the latest value, at a performance cost.
