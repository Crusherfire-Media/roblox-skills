I fixed both problems in the files, but nothing has been playtested: I had no Studio connection here, so I couldn't sync with Rojo or run the relocation check.

## Admin list leak
`AdminList` sat in a folder that gets copied to every player's client. It was also required by `AdminSharedService`, which runs on both server and client. So any player could read the full list of admin IDs.

- **`AdminList.meta.json` (new):** marks the list `RelocateToServerScriptService = true`, so the loader keeps it on the server and never copies it to ReplicatedStorage.
- **`AdminSharedService.luau`:** no longer requires the list. It only holds `MaxAnnouncementLength`.
- **`AdminServerService.luau`:** now owns `IsAdmin`, which checks the list. It answers a new `GetIsAdmin` RemoteFunction with whether the player asking is an admin. A player can only ever learn their own status.
- **`AdminNetwork/GetIsAdmin.model.json` (new):** the RemoteFunction itself, listed in `AdminNetwork/init.luau`.
- **`AdminClientService.luau`:** in `Start`, the client asks the server in a separate thread, so loading isn't held up, and only builds the panel if the answer is `true`. If the call fails, no panel is shown.

Announcements are still refused from non-admins. `onAnnounce` checks `IsAdmin` on the server before anything else, as it did before, so faking the client reply doesn't let anyone announce.

## HUD startup errors
- **`HudClientService.meta.json`:** `ClientOnly` is now the boolean `true` instead of the string `"true"`, which clears the warning.
- **`_HudClientSetup.meta.json` (new):** sets `ClientOnly = true`. This was the real cause of the crash. The setup had no realm attribute, so the server also ran its `Init`. On the server `Players.LocalPlayer` is nil, so reading `.DisplayName` errored.

## Before you ship
1. Sync with Rojo.
2. Run the relocation check from the loader docs (`references/module-loader.md` in the game-architecture skill). It should report no problems.
3. Start a playtest and check:
   - There is no `ReplicatedStorage.RELOCATED_MODULES.Systems.Tooling.AdminSystem.SystemPackage.AdminList`.
   - Admins see the panel and other players don't.
   - The log has no `>> Failed` or `Loader attribute` lines.

The leaked IDs are already public, and moving the list doesn't change that. The admin accounts themselves can't be swapped, but you may want to watch them for targeting, or move admin checks to a group rank later.