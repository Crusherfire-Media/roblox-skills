# Estimating

The unit costs that step 2 of "Designing a system" in `SKILL.md` multiplies by count and rate.

## Unit costs

Measured on a desktop in Studio. Phones run roughly 3x to 4x slower, so multiply before
comparing with the 16.67 ms frame budget (which is shared with the engine and every other
script).

| Operation | Cost |
|---|---|
| Read or write a Luau table field | about 10 ns |
| Read an instance property / an attribute | 55 ns / 100 ns |
| Write a property / an attribute on a parented instance | 0.6 us / 1.5 us |
| Move one part by `CFrame` | 3 us |
| Move one welded model by its root | about 1 us per part in it |
| `task.spawn` a function | 1.7 us |
| One engine spatial query with a small volume | about 2 us |
| Create, configure, and parent one `Part` | 15 to 20 us |
| `Destroy` plus `Clone` one `Part` | 30 us |
| One standing Humanoid, per frame | 8 us on the machine simulating it |
| Re-lay out one `TextLabel` after its `Text` changes | 7 us fixed size, 20 us `TextScaled` |
| One remote call | 9 bytes plus arguments (number 9, `Vector3` 13, `CFrame` 14 to 20) |
| One replicated property or attribute change | 18 to 25 bytes |
| Memory per instance | 0.6 KB for the smallest, 3 to 6 KB per `Part` |

Example: 200 pets of 12 welded parts each, moved every frame, is 200 x 12 us = 2.4 ms on a
desktop and 7 to 10 ms on a phone. That is over the 5% line, so it earns a design decision (move
them on the client, and not every pet every frame), and still no micro-optimization.
