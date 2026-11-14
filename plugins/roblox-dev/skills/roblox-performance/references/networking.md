# Networking and replication

Byte-level packing is in `buffers-serialization.md`.

## Design decisions

The first five usually save the most. When bandwidth is the bottleneck, look for instances that
should not exist on the server and state sent too often before reaching for buffers.

1. **The server holds state. Clients build what players see.** Explosions, spell effects,
   tweens, projectile visuals, view models, pets, and coins need no server instance: the server
   decides the outcome and sends where and what, and each client creates the visuals. Everything
   created under a replicated container on the server is serialized to every client, and so is
   every later change to it. One game went from 135 KB/s to 5 KB/s for 15 enemies by moving
   their visuals to clients. `[docs]` `[reported]`
2. **Send the decision, not the motion.** "Pet 12 follows slot 3" or "coin 88 spawned at P" is
   sent once. A moving replicated part costs bytes for as long as it moves. Let clients simulate
   and interpolate. `[reported]`
3. **Send changes, at a rate you choose.** Remotes and property changes go out every server
   frame. State that clients interpolate rarely needs more than 10 to 20 updates a second, and
   an entity that did not change needs none. Dropping from 60 Hz to 10 Hz is a 6x cut on its
   own. `[docs]` `[reported]`
4. **Send to the players who need it.** Remotes have no interest management: `FireAllClients`
   goes to everyone. Use `FireClient` for players in range and lower the rate with distance.
   `[docs]`
5. **Enable instance streaming for large worlds.** It cuts join time, client memory, and server
   bandwidth for everything in `Workspace`. See "Streaming" below. `[docs]`
6. **Match reliability to the data.** All reliable remotes share one ordered stream, so a lost
   packet stalls everything behind it until it is resent. Put continuous, replaceable data
   (positions, aim) on `UnreliableRemoteEvent`: under 1,000 bytes per payload, numbered, and
   expected to drop and arrive out of order. Keep anything that must arrive on `RemoteEvent`.
   `[docs]`
7. **Do not move or tween replicated parts on the server every frame.** Each change is a
   replicated property: about 25 bytes per part per frame, and it looks jittery under latency.
   Send the motion parameters once and run the tween on each client. `[docs]` `[measured]`
8. **Keep what clients do not need off the client.** Everything in `ReplicatedStorage` is sent
   to every client at join, and that includes whatever sits under a module the loader relocates
   there. A system's assets stay with the system (the `game-architecture` skill's
   `references/assets-and-sounds.md` says where), with server-only assets under a server-only
   module. `[docs]`
9. **Replicate a summary, not the contents.** When clients only need "what is in this
   container" for a label, keep the contents on the server, replicate a small revision number
   that changes when they do, and send the summary on request, cached by revision. `[reported]`
10. **For a value that changes continuously, replicate (value, time, rate) when the rate
    changes** and let clients extrapolate, instead of replicating the value every frame.
    `[reported]`
11. **Keep renumbering out of replicated state.** An order field that is renumbered to stay
    gapless turns one removal into a write per remaining element: removing the first of 250
    items replicated about 3,000 attribute updates in one shipped game. Hand out increasing
    order values, never compact them, and sort on the client. `[reported]`
12. **Animate NPC crowds on clients.** A server-played animation is evaluated on the server and
    replicated as playback commands, not as joint positions. For many NPCs, create the
    `Animator` on each client and play locally, which also lets clients skip distant NPCs.
    Player characters already replicate their own animations. `[docs]`

## Costs to know

- **A remote call is about 9 bytes plus its arguments.** The table is in
  `buffers-serialization.md`, "Bytes on the wire". `[measured]`
- **One replicated change costs 18 to 25 bytes**: a `NumberValue` 18, a number attribute 24, an
  anchored part's `CFrame` 25. `[measured]`
- **Several writes to one property in a frame replicate as one.** Ten writes per frame cost the
  same as one. The cost is in changing it every frame. `[measured]`
- **An attribute change sends that attribute only**, not the instance's whole attribute map.
  Attribute, value object, and a one-number remote are within a few bytes of each other, so pick
  by fit: attributes and value objects reach every client that has the instance, a remote can
  target one player. `[measured]`
- **Replicated properties are sent reliably, first in, first out, with no priority.** A flood of
  cosmetic property changes delays the important ones for every client. `[docs]`
- **Client-to-server remotes throttle at about 500 calls per second per client**, shared across
  all `RemoteEvent`s, with a separate pool for unreliable events. Excess `RemoteEvent` calls are
  delayed; excess unreliable ones are dropped. `[docs]`
- **A remote with no listener queues, then drops.** A `RemoteEvent` queues until the queue
  fills; an `UnreliableRemoteEvent` drops at once. Connect handlers before the other side
  starts firing. `[docs]`
- **A `RemoteFunction` costs a round trip**, and `InvokeClient` can hang or throw on the server.
  Use events unless the reply is needed. `[docs]`
- **An instance passed through a remote can arrive as `nil`** when the instance has not
  replicated or streamed in yet. The remote and the instance travel separately. `[docs]`
- **There is no hard 50 KB/s cap.** That figure came from documentation removed years ago, and a
  Studio server sustained 440 KB/s to one client. Experienced developers still report queueing
  and throttled physics updates beyond about 50 KB/s received per client, so it works as a
  budget (`measuring.md`, "Budgets"). `[measured]` `[reported]`

## What does and does not replicate

- **`Transform` on `Motor6D` and `AnimationConstraint` does not replicate.** Written on the
  server, the server part moved and the client saw the rest pose. Drive procedural joint motion
  on each client and replicate only the target, through an attribute or an unreliable remote.
  `[measured]` `[docs]`
- **`IKControl` properties replicate from the server like any instance; the solve is local** and
  no joint data is sent. Changes made on a client stay on that client. Prefer creating and
  driving IK on the client, and replicate the target. `[docs]`
- **Server `Destroy()` replicates as a destroy.** `Parent = nil` on the server only unparents on
  clients and leaves their connections alive. `[docs]`
- **Tags replicate as a whole set** per instance. `[docs]`
- **`SetStateEnabled` on a Humanoid does not replicate.** Call it on the machine that simulates
  the Humanoid. `[docs]`
- **Instances parented under a `Camera` on the server do not replicate.** Shipped games use this
  to keep server-only physics proxies in `Workspace`. It is undocumented, so it can change.
  `[reported]`

## Instances over the network

- **Set properties, then `Parent`.** The instance then replicates once, fully configured
  (`instances-pooling.md`). `[docs]`
- **Creating or destroying a large tree at runtime is network-heavy** and lands in one frame as
  `ProcessPackets` on every client. Load maps in pieces across frames (`instances-pooling.md`).
  `[docs]`
- **Strip Animation Editor data from rigs that get cloned at runtime.** It replicates with
  every clone. `[docs]`

## Streaming

`[docs]`

- Settings to start from: `StreamingMinRadius` 64, `StreamingTargetRadius` 1024,
  `StreamOutBehavior` `Opportunistic`, `ModelStreamingBehavior` `Improved`,
  `StreamingIntegrityMode` `PauseOutsideLoadedArea`.
- Keep models under about 64 studs across so they stream in whole. Large moving assemblies
  stream in as one unit and can spike.
- `Persistent` models load at join and never leave memory. Use them for the few things scripts
  must always reach, not as a way around streaming.
- Every extra replication focus costs like an extra player.
- Streaming applies to `Workspace` only.
- Client code must handle instances that are not there yet. Turning streaming on in an existing
  place changes behavior, so propose it to the user rather than switching it on as a fix.

## Network ownership and physics replication

- Unanchored assemblies near a player are simulated by that player's client by default, which
  takes load off the server. `SetNetworkOwner(nil)` puts the cost back on the server. Anchored
  parts are always server-owned. `[docs]`
- Client ownership also lets that client move the part, so it is a security decision as well as
  a performance one. `[docs]`
- Physics replication is unreliable and prioritized by relevance, and it keeps a low update
  rate that receivers interpolate. Do not design around an exact rate. `[docs]`

## Diagnosing network problems

The byte-counting method and the tools are in `measuring.md`. Three checks are specific to
networking:

- Data ping far above network ping means the replication queue is backed up. Both are shown in
  the Performance Stats bar, which only the user can read, so ask for them. `[docs]`
- A MicroProfiler dump with network capture shows per-frame traffic split by kind. `[docs]`
- Studio's Print Join Size Breakdown (Studio Settings, Network) lists the largest instances and
  classes sent at join. The user has to turn it on. `[docs]`

## Myths

- **"One remote for everything saves bandwidth."** Routing by a string name costs more than the
  header it saves. `[reported]`
