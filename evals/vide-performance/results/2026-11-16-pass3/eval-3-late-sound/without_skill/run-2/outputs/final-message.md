I've changed the UI sound code so each cue plays an already-loaded sound, and wrote the note in `docs/perf/ui-sounds.md`. Nothing has been run in Studio or on a phone yet, so the timing fix is untested.

**Why the sounds were late:** every call to `UiSounds.play` created a brand-new `Sound`. A new `Sound` always starts with `IsLoaded = false` and has to load before it can make any noise, which takes 0.3–0.5 s on phones. The `PreloadAsync` call in `Main.client.luau` was given the id strings, so it only warmed the download cache, not the `Sound` objects that actually played. That's why `IsLoaded` was false even after the preload. The picker's open sound was late for the same reason: its `Sound` was only created when the picker appeared.

**What I changed:**
- **`UiSounds.luau`** keeps one loaded `Sound` per id and shares it across screens:
  - `UiSounds.use(ids)` keeps sounds loaded while a component is on screen; `UiSounds.retain(ids)` does the same and returns a release function.
  - When nothing is using a sound anymore, it is destroyed, but only after it finishes playing, so the close sound isn't cut off.
  - `play` restarts the already-loaded `Sound`. If a sound still isn't loaded, it waits up to 0.1 s and then skips the cue instead of playing it late. Studio prints a warning when that happens.
- **`Main.client.luau`:** the Build button keeps the click and picker-open sounds loaded. The open sound plays the instant the picker appears, so it has to be ready before the press. I removed the `PreloadAsync` block.
- **`BlockPicker.luau`:** the picker keeps the click and close sounds loaded while it's open. When it closes, it plays the close sound and then lets them go.

**What stays loaded:** the click stays loaded while any screen uses it. The close sound is only loaded while the picker is open. The open sound stays loaded as long as the Build button is on screen, since that button is how you enter build mode. Future screens that use the click only need to call `UiSounds.use({ SoundIds.Click })`.

**Things to know:**
- **Skipped sounds:** opening and immediately closing the picker in the first moment after joining can skip the close sound, because it may not have loaded yet. That's the trade for never playing it late. To always play it instead, the Build button could keep the close sound loaded too.
- **Testing:** a desktop running Studio loads sounds quickly, so the original lag is hard to reproduce there. The note explains how to watch the `Sound`s and their `IsLoaded` in Studio, but the real check is tapping Build and the tiles on a phone.
- **Not checked:** I didn't run a linter or type-checker. I also didn't list the project files from the shell: that command needed approval, and nobody could approve prompts in this session, so I used the file-search tools instead.