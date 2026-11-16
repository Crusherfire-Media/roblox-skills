The HUD now changes its layout for mouse and keyboard, touch, and controller, and it switches as soon as the player starts using a different input. On PC it looks and behaves the same as before. Types, lint and formatting all pass, but I couldn't run it in Studio, so nothing has been tested on a phone, tablet or Xbox yet. Nothing is committed.

**How it detects input** (new file `InputMode.luau`): it watches the player's most recent input and switches to mouse/keyboard, touch or controller to match. Tiny mouse movements and thumbstick drift don't count, so a controller sitting on the desk won't make the HUD flicker between layouts. If the last controller is unplugged, it falls back to the device's normal mode, except on a console, where it stays in controller mode.

**PC:** the layout is fixed at the original numbers: 40px slots, the 1–0 key labels, the `[B]` and `[I]` hints, the hover tooltip and the coin counter all stay where they were. One small change: slots and buttons now respond to `Activated` instead of `MouseButton1Click`. That's the same mouse click, but it also works for taps and the controller's A button.

**Touch:**
- **Hotbar:** it sits between the default thumbstick and jump button, with slots at least 44px (the recommended minimum for touch). On narrow phones it becomes two rows of 5.
- **Buttons:** build mode is now a Build ON/OFF button, since phones have no B key. It's stacked with an Inventory button above the jump button. The positions copy Roblox's default thumbstick and jump button sizes rather than reading the real ones, so check them on a device.
- **Block name:** the selected block's name always shows above the hotbar, because there's no hover. The hover tooltip is turned off on touch, since a tap can leave it stuck on screen.

**Controller / TV:**
- **Size:** everything scales with screen height, to 1.5× at 1080p.
- **Edges:** everything stays at least 5% in from the screen edges, for TVs that crop.
- **Button pictures:** they come from Roblox, so they match Xbox or PlayStation controllers.
- **Block name:** the selected block's name shows above the hotbar.

**Controller buttons** (`Main.client.luau`):

| Action | Button |
|---|---|
| Previous / next block (wraps around) | LB / RB |
| Build mode on/off | Y |
| Open inventory | X |

**For the dev doing controller placement:** A (jump) and both triggers are still free. If they need Y or X, the bindings are in `Main.client.luau` and the matching button pictures are constants at the top of `Hud.luau`, so change both together.

**Known gaps:**
- **Portrait phones:** the hotbar moves up above the controls but can overlap the touch buttons. Roblox games are landscape on phones by default, so I left it.
- **Controller on PC:** a player using a controller on a PC monitor also gets the bigger TV layout. It's capped by window height, so a 720p window looks normal size.

**What to test on devices first:**
- **Small phone** (e.g. iPhone SE size): the two-row hotbar and the button stack shouldn't overlap the thumbstick or jump button.
- **Controller on PC:** pick it up mid-session and press a button; then move the mouse to switch back.
- **Real TV:** check the edge margin and that the button pictures show up.