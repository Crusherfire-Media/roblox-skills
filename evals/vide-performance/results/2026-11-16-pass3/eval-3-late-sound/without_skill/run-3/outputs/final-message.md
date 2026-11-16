The UI sounds should now play on time, but I couldn't run anything here (no Studio), so this is untested until you try it.

**Why they were late:** `UiSounds.play` made a brand-new `Sound` on every play. A new `Sound` has to load its asset before it can make any noise, which is why `IsLoaded` was `false` and why phones were worst. The startup `PreloadAsync` only took the id strings, so it warmed the download cache but never gave the game an already-loaded `Sound` to play.

**What I changed:**
- **`UiSounds.luau`:** new `UiSounds.use(soundId)`. You call it while building a screen. It keeps one `Sound` per id in `SoundService`, preloads it, and counts how many screens are using it. When the last screen that uses it closes, the `Sound` is deleted, after it finishes playing if it's playing. So the click can be shared by future screens, and nothing stays loaded once no UI needs it.
- **`UiSounds.play`:** now replays the already-loaded `Sound` from the start. If nothing called `use` for that id, it falls back to the old late behaviour and prints a warning in Studio.
- **`BlockPicker.luau`:** now returns `{ Sounds, new }`, where `Sounds` lists the three sounds it plays (click, open, close). The picker calls `use` on them itself. The close sound is set up to start before the picker lets go of its sounds, so it isn't cut off.
- **`Main.client.luau`:** the Build button calls `use` on the click and the picker's sounds. The open sound plays the instant the picker appears, so it has to be loaded by whatever opens the picker. I removed the old `PreloadAsync`, and the picker is now created with `BlockPicker.new`.

**Decision for you:** the Build button is always on screen today, so the picker sounds effectively stay loaded for the whole session. The only way to keep them unloaded would be to wait for the Build press, and that would make the open sound late again. If the button later moves into a screen that isn't always shown, the sounds will be unloaded along with it.

`docs/perf/ui-sounds.md` has the summary and Studio checks:
- The three Sounds should stay in `SoundService` with `IsLoaded` true.
- Clicks should play on the press, and there should be no "not in use" warning.
- You can test again with added network lag.
- There's a way to check that sounds are unloaded. Deleting the ScreenGui alone won't unload them; you have to call the function `mount` returns.

My first shell command (to list the files) was blocked because this session can't approve commands. I used the file-reading tools instead.