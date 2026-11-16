I've built the settings menu with Vide under `src/StarterPlayer/StarterPlayerScripts/UI/`, and `Main.client.luau` now starts it before `BlockPlacer.start()`. StyLua and selene both pass on the new code. I haven't run it in Studio, so it's untested on a real phone, PC and controller.

**What's in it**
- **Open button**: a "Settings" button on the left edge, halfway down the screen. That spot stays clear of the phone thumbstick and jump button, the chat window and the player list.
- **Music and sound effects volume**: each has a bar you can drag or tap, a percentage readout, and − / + buttons that change it by 10%. Changes go straight to the `GameAudio` setters.
- **Delete all my blocks**: since the server can't undo it, the first press asks "Delete every block you built? You can't get them back." with Cancel and Delete. On a controller, the selection lands on Cancel, so mashing A won't delete anything. After deleting, it shows "Your blocks were deleted." Closing the menu cancels the question.

**For the players who reported problems**
- **Too see-through**: the panel is fully solid, not partly transparent. The world behind it is dimmed, and text is large (18–28px) and light on dark.
- **Motion sickness**: nothing slides, fades or springs. The menu and hover highlights change instantly.

**Phones, PC and controller**
- **Phones**: everything you tap is at least 48px, and the volume bar can be grabbed anywhere along the full row height. The panel stays clear of the notch and top bar, shrinks to fit small screens, and scrolls if the screen is too short.
- **PC**: if the mouse is locked (first person or shift lock), opening the menu frees it.
- **Controller**: Y (triangle on PlayStation) opens and closes the menu, and B closes it. The buttons show the right Xbox or PlayStation icon. The selection moves into the menu when it opens and can't leave it. When the menu closes the selection is let go, so A goes back to controlling the character.
- **Volume on a controller**: you change it with the − / + buttons rather than the bar.
- **Block placement**: paused while the menu is open, then put back to how it was.

**Things to know**
- **Y and B are taken over**: Y is bound all the time, and B is bound while the menu is open. Nothing in the game uses them yet, but a future feature on either button would clash.
- **Delete pressed very early**: if someone presses Delete in the first moment after joining, before the client has found the server's delete event, nothing is deleted but the message still says it was. `BlockPlacer` has no way to tell the menu it's ready, so fixing this would mean adding one.
- **Saving settings**: when you add saving later, it fits in `setMusic` / `setEffects` in `SettingsMenu.luau`.
- **Tools I couldn't run**: StyLua's auto-fix command was blocked here, so I made its two line-wrapping changes by hand and re-ran the check. I also couldn't run luau-lsp to type-check.

**Files**, all in `UI/`:
- `init.luau`: mounts the menu.
- `SettingsMenu.luau`: the menu, the open button and the controller bindings.
- `VolumeSetting.luau`: one volume control.
- `ClearBlocksSetting.luau`: the delete button and its confirmation.
- `Button.luau`: the shared button.
- `InputMode.luau`: tracks whether the player is on a controller.
- `Theme.luau`: colours, fonts and sizes.