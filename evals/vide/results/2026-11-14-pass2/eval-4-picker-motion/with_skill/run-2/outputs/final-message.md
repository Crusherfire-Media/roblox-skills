The picker now slides in and out, one highlight glides to the tile you pick, and tiles sink when pressed. The type check, selene and stylua all pass with no issues, but I haven't run it in Studio, so none of the motion has been seen yet.

**Slide in and out** (`BlockPicker.luau`, `Main.client.luau`)
- The picker's position springs between a shown spot and a spot below the bottom edge of the screen. It's smooth, with no overshoot, and takes about 0.4 s.
- When build mode turns off, the picker stays around for that 0.4 s while it slides down, then goes away.
- Spamming B or the Build button is safe. I checked Vide 0.4.1's source: turning build mode back on while the picker is sliding away cancels its removal and sends that same picker back up from wherever it is. No duplicates, no jumps.
- While it slides away, its tiles ignore presses, so you can't pick a block on the way out. Placing is already off at that point anyway.

**Gliding highlight**
- The yellow outline is now one frame that springs to the selected tile in about 0.25 s, instead of each tile changing its own outline. It also follows the number keys 1 to 5.
- When the picker opens, the highlight starts on the current tile rather than gliding there.
- Each tile keeps its thin grey outline.

**Pressing tiles**
- A tile's colored face shrinks a little when you press it with a mouse or touch, and bounces back when you let go, even if you let go somewhere else.
- Only the face shrinks. The clickable area keeps its full size, so the tile doesn't flicker when you press near its edge.
- Gamepad presses don't get this effect; they still select normally.

**Other changes**
- `BlockPicker` now returns `{ new, ExitDuration }` instead of a bare function, and `Main.client.luau` is updated to match.
- The project doesn't have UI Labs, so I didn't add a story for the picker.
- Vide's strict mode isn't turned on anywhere. Adding `Vide.strict = RunService:IsStudio()` where Vide is first required would catch Vide mistakes during development.

**What to check in a playtest**
- The picker slides up and back down, and no edge stays visible at the bottom once it's down.
- Hammering B in and out never leaves two pickers or a stuck one.
- The highlight glides when you click tiles and when you press 1 to 5.
- The press bounce feels right, both by mouse and on a phone in the device emulator.
- You can change the timings and the press depth with the constants at the top of `BlockPicker.luau`.