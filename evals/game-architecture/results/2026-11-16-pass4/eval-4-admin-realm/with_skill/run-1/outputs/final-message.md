I've made both fixes, but I haven't run them in a playtest. I don't have a Studio connection here, and my one attempt at a shell command for looking around the repo was blocked by permissions. Please play once and check the output for `>> Failed`, `Loader attribute` and `[SECURITY]` lines.

## Admin list leak
**Cause:** `AdminList` had no realm attribute, so the loader copied it to ReplicatedStorage. Clients could then read it. On top of that, `AdminSharedService` required it, so the client side used it too.

**What changed:**
- **`AdminList.meta.json` (new):** marks the list `RelocateToServerScriptService = true`, so it stays on the server and never gets copied to players. It also sets `IgnoreLoader = true`, since it's only data and the loader doesn't need to run it.
- **`AdminSharedService`:** no longer requires the list or contains `IsAdmin`. It only holds `MaxAnnouncementLength` now.
- **`AdminServerService`:** now has `IsAdmin` and is the only module that reads the list. `onAnnounce` still refuses anyone who isn't an admin, exactly as before.
- **New `CheckAccess` remote:** the client asks the server whether it's an admin and gets back only `true` or `false` about itself. No user IDs ever leave the server.
- **`AdminClientService:Start`:** asks the server first and only builds the panel if the answer is yes. The question runs in the background so it doesn't hold up the game's startup.

**Before you publish:**
- **Previous versions still leak.** Old builds of the game kept sending the list to players until you publish this one.
- **The IDs are already public.** The list posted on Discord stays out there, so treat those accounts as known admins.
- **Changing admins now takes a republish.** Adding or removing an admin means editing `AdminList.luau` and publishing again, same as before.

## HUD startup errors
- **"is a string, not a boolean":** `HudClientService.meta.json` had `"ClientOnly": "true"` (text). I changed it to a real `true`.
- **"attempt to index nil with 'DisplayName'":** `_HudClientSetup` had no realm attribute, so the server ran it too. The server has no local player, so it crashed. I added `_HudClientSetup.meta.json` with `ClientOnly = true` so only players' clients run it.

None of this is committed yet.