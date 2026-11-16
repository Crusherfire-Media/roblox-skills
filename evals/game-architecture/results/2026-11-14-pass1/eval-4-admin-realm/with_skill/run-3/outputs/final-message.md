The admin list now stays on the server, and both HUD errors should be gone. I couldn't run a playtest here (no Studio connection), so none of this has been run in-game yet.

**Admin list leak**
- **Cause:** `AdminList` was a plain module in `SystemPackage` with no realm attribute, and `AdminSharedService` required it on both sides. The loader therefore copied it to every client, where anyone could read it.
- **Fix:** I moved the list to `AdminServerService/_AdminList.luau`, nested inside `AdminServerService`, which has `RelocateToServerScriptService = true`. Nested modules go wherever their parent goes, so the list can't end up on clients through a missing attribute. `IsAdmin` now lives only in `AdminServerService`, and `AdminSharedService` keeps just `MaxAnnouncementLength`.
- **Announcement panel:** there's a new `AdminNetwork.IsAdmin` RemoteFunction. At startup the client asks the server, in a background thread so startup isn't blocked, and shows the panel only if the answer is `true`. The server answers only for the player asking, so a client can't learn about anyone else.
- **Server check:** unchanged. `onAnnounce` still drops anything from a player who isn't an admin, so a modified client can show itself the panel but can't send an announcement.

**HUD errors**
- `HudClientService.meta.json` had `"ClientOnly": "true"` as a string. It's now a real boolean, which clears the warning.
- `_HudClientSetup` had no realm attribute, so the server also ran it, where `Players.LocalPlayer` is nil. That was the `DisplayName` error. I added `_HudClientSetup.meta.json` with `ClientOnly: true`.

**Still to do:**
- **Playtest:** check the output for `>> Failed` or `Loader attribute` lines, confirm an admin sees the panel and others don't, and run the relocation check in the dev place.
- **The leaked IDs:** treat them as public now. They can't be used to send announcements, but people now know which accounts are admins and could target them for phishing. They also remain in the git history.
- **Folder colours:** every `init.meta.json` writes `IconTint` as a bare array. Rojo 7.6 rejects that format, which may stop it syncing those folders. I didn't change these; the fix is to write it as `{ "Color3": [r, g, b] }`.
- **Blocked command:** my first combined command (meant to list git status and print every file in both systems) was blocked by the permission check. I read the files individually instead, and the old files were removed with a plain `rm`.