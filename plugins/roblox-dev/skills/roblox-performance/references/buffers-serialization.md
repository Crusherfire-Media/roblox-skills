# Buffers, serialization, and compression

## Design decisions

- **A buffer is a memory and bytes tool, not a speed tool.** It was no faster than parallel
  arrays: 1.2x to 1.6x slower to read and write in index order, interpreted or native (table in
  `luau.md`, "Data layout"). Choose it for the reasons below, and expect the code to get harder
  to read. `[measured]`
- **Use a buffer when** the data is large, numeric, and uniform, and one of these holds:
  - Memory matters: 1 to 8 bytes per value against 16 in an array and 32 in a dictionary. Four
    fields per entity took 16 bytes in an `f32` buffer and 192 as a table. `[measured]`
  - It lives for a long time and is large: the collector scans every slot of a table and skips a
    buffer's contents. `[docs]`
  - It is a wire or storage format: buffers go through remotes and DataStores, and the engine
    compresses them. `[docs]`
- **Leave everything else in tables.** Gameplay state that code reads by name is not buffer
  material.
- **On the network, reduce what is sent before packing it.** Send less, less often, to fewer
  players (`networking.md`). One shipped game cut bandwidth 60x in three steps: about 9x from a
  lower rate and leaving out what clients could derive, 3.5x from narrower integers, and 2x from
  bit packing. `[reported]`
- **A buffer saves bytes only when the encoding gets narrower.** 100 doubles cost 912 bytes as
  an array and 801 in a buffer. As `f32` they cost 402, and quantized to `u16` they cost 214.
  A `Vector3` argument is already three 32-bit floats (13 bytes), so putting it in a buffer
  saves one byte. `[measured]`
- **Do not compress what the platform compresses.** Remotes compress large buffers, and
  DataStores compress every value (details under "Storage and cross-server limits"). `[docs]`

## Working with buffers

- A buffer has a fixed size, is zero-filled, and throws on out-of-range access. To grow, create
  a larger one (double the size) and `buffer.copy` into it. `[docs]`
- **One module owns each layout.** Name the offsets and sizes as constants, expose an encode and
  a decode function, and keep every read and write of that format inside the module. A wrong
  offset silently corrupts the neighboring field, so propose a round-trip spec (encode, decode,
  compare) through the `roblox-testing` skill.
- `f32` storage rounds values. Use `f64`, or scaled integers, where precision matters. `[docs]`
- **Quantize when you control the range.** Store `math.round(value / range * 65535)` in a `u16`
  and reverse it on read. Positions inside a known area, angles, and percentages rarely need 32
  or 64 bits. Quantizing loses precision, which is a behavior change to raise with the user.
- **Pack flags and small fields with `bit32`, then do one whole write** (`writeu8`, `writeu16`,
  `writeu32`). `buffer.readbits` and `buffer.writebits` are convenient and slower, since each
  call checks bounds. Eight booleans fit in one byte. `[docs]`
- Use `buffer.copy` and `buffer.fill` for bulk work instead of byte loops. `[docs]`
- Annotate parameters as `buffer` in functions marked `@native`, so reads and writes compile to
  direct memory access. `[docs]`
- Use buffers instead of `string.pack` and `string.unpack` for new binary formats. `[docs]`
- A buffer cannot be an attribute and cannot be shared between Actors (sending one copies it).
  `[docs]`

## Bytes on the wire

Measured from a playtest server to one client. `[measured]`

| Remote payload | Bytes per call |
|---|---|
| No arguments | 9 |
| `true` | 11 |
| One number | 18 |
| 10-character string | 21 |
| `Vector3` | 22 |
| `CFrame`, axis-aligned / rotated | 23 / 29 |
| Record as a dictionary (`Position`, `Health`, `Name`) | 59 |
| Same record as an array | 38 |
| Same record as three plain arguments | 36 |
| Same record packed into a 16-byte buffer | 28 |
| Array of 100 random numbers | 912 |
| Buffer of 100 `f64` / `f32` / quantized `u16` | 801 / 402 / 214 |
| Buffer of 1,000 zero bytes | 30 |
| Buffer of 1,000 bytes in a repeating pattern | 38 |

Rules that follow, for remotes a measurement shows are heavy (a low-rate remote keeps its
readable payload):

- **Every call costs about 9 bytes before any argument.** 100 one-number calls cost 1,800 bytes;
  one call with a 100-number array costs 912. Send the messages a system produces in one frame
  as one call. Do not queue events to send later in a bigger batch, which adds latency. Lowering
  the update rate of replaceable state (`networking.md`) is different: old values are dropped,
  not queued.
- **Dictionary keys are sent as strings on every call.** A fixed-order array or plain arguments
  took the same record from 59 bytes to 36.
- **A number is always 9 bytes**, whatever its value. Small integers shrink only inside a buffer.
- **Large buffers are compressed for you** (zstd). Repetitive data nearly disappears. Send the
  buffer itself, not `buffer.tostring`, and merge small buffers into one. `[docs]`
- **Tiny buffers lose.** A buffer carries its own header of at least 2 bytes. A boolean is
  cheaper as a plain argument. `[docs]`
- **The engine's `CFrame` encoding is already compact**: 1 byte for an axis-aligned rotation,
  about 6 for any other. A custom transform encoding wins only by shrinking the position.
  `[reported]`
- **Validate buffers that come from clients** like any client input: check the length before
  reading, and call `EncodingService:GetDecompressedBufferSize` before decompressing anything a
  client sent, since a small compressed buffer can declare a huge output. `[docs]`

## Networking libraries

Schema-based buffer libraries (Blink, Zap, ByteNet, Packet) pay off for frequent, structured,
numeric traffic, such as entity state sent many times a second. They do not shrink strings,
instance references, or the per-call header, and they add a schema to maintain, an ID byte per
message, and encode and decode time. `[reported]`

- Keep plain remotes for low-rate events: UI, purchases, round state.
- A widely quoted "1,000x less bandwidth" benchmark sends identical data 1,000 times per frame,
  which compression erases. On data that changes, expect the gains in the table above.
  `[reported]`
- Adopting a networking library in a place is the user's decision.

## Storage and cross-server limits

`[docs]`

| Limit | Value |
|---|---|
| DataStore value | 4,194,304 characters of serialized JSON per key |
| DataStore per-key throughput | 4 MB written and 25 MB read per minute |
| MemoryStore value | 32 KB |
| MessagingService message | 1 KB, about 700 bytes when sent as a buffer |
| `UnreliableRemoteEvent` payload | 1,000 bytes |

- **Do not compress DataStore values to save space.** Storage is measured after Roblox's own
  compression, so compressing first costs CPU and can make the stored result bigger. The one
  reason to compress first is a single key that would exceed 4 MB, because that limit is checked
  before storage compression.
- **A buffer in a DataStore grows by a third** (it is stored as base64, after compression when
  that helps). Keep a stored buffer under about 3 MB uncompressed.
- **Save the buffer value, never `buffer.tostring`.** The string form usually contains bytes
  that are not valid UTF-8, and the write fails.
- **`EncodingService`** provides native zstd (`CompressBuffer`, `DecompressBuffer`) and Base64.
  It replaces Luau LZW, zlib, deflate, and Base64 modules, which are far slower.
- **Compression has a floor.** Small, random, or already compressed data comes out the same size
  or larger and still costs the CPU time.
