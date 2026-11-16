I've changed the code so UI sounds should play on time, but I haven't run it. My first shell command (listing the project files) was blocked by the permission system, so I worked only with the file tools. Nothing has been through a linter or Studio yet.

**Why the sounds were late:** `UiSounds.play` made a new `Sound` for every cue. A new `Sound` always starts with `IsLoaded = false`, and `Play()` on it waits until the sound loads, which is the 0.3–0.5 s delay you saw. `PreloadAsync` with the ID strings only fills the download cache. It doesn't make a newly created `Sound` loaded, so it didn't help.

**What I changed:**
- **`UiSounds.luau`**: new `UiSounds.hold(ids)` keeps one loaded `Sound` per ID in SoundService and returns a function that releases it. Holds are counted, so several screens can share one click sound, and it's destroyed when the last one lets go.
- **How `play` behaves now:**
  - It reuses the held `Sound` instead of making a new one.
  - If the sound is still loading, it plays only if loading finishes within 80 ms. Otherwise that cue is skipped rather than played late.
  - If nothing holds the sound, it's skipped and you get a warning in Studio.
- **`Main.client.luau`**:
  - The HUD holds the click sound for as long as it's on screen. Future screens should hold it the same way: `cleanup(UiSounds.hold({ SoundIds.Click }))`.
  - The picker's open and close sounds are held only around build mode. They start loading when the pointer goes over the Build button or presses it, stay loaded during build mode, and are released 30 s after you leave it. That delay lets the close sound finish and avoids reloading when you toggle quickly.
  - I removed the old startup `PreloadAsync` call.
- **`BlockPicker.luau`**: only a header comment, saying whoever shows the picker must hold its sounds.

**One limit:** pressing **B** gives no warning before build mode opens. So the first time (or after the 30 s release), the open sound may be skipped if it doesn't load within 80 ms. It won't play late.

**Note:** `docs/perf/ui-sounds.md` has these changes and the Studio steps:
- Watch the `Sound`s in SoundService appear when you hover the Build button.
- Check that clicking doesn't add a new `Sound` each time.
- Check that the picker sounds go away about 30 s after you leave build mode.
- Test with taps in the Device emulator.
- Repeat your `IsLoaded` check with a temporary `print` in `play`. It should now show `true` for every click and open/close sound.