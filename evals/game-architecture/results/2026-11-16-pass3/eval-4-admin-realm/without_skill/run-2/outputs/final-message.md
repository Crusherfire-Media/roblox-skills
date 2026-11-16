The admin list now stays on the server. I haven't tested this in Studio or run any tests, so do a quick playtest before publishing.

## Admin list leak

**Cause:** `Systems/init.meta.json` sets `RelocateToReplicatedStorage: true`. That setting cascades to every module under `Systems`, so `AdminList` was copied to `ReplicatedStorage.RELOCATED_MODULES`, where every client can read it. On top of that, `AdminSharedService` required `AdminList` so the client could run `IsAdmin` itself.

**Fix:**
- **New `AdminList.meta.json`:** sets `RelocateToReplicatedStorage: false` and `ServerOnly: true`. A setting on the module itself overrides the folder's cascade, so the module stays in ServerScriptService and never replicates.
- **`AdminSharedService.luau`:** no longer requires `AdminList`. It now only holds the max announcement length, which both sides use.
- **`AdminServerService.luau`:** now owns `IsAdmin`. It also answers a new `GetIsAdmin` request, which only tells the asking player whether *they* are an admin.
- **New `AdminNetwork/GetIsAdmin.model.json`:** the remote for that request, listed in `AdminNetwork/init.luau`.
- **`AdminClientService.luau`:** at Start, the client asks the server and builds the panel only if the answer is `true`. It asks in a separate thread so the wait doesn't hold up other modules.

The server still checks `IsAdmin` on every `Announce` call, so announcements from anyone else are still refused.

**Two things to keep in mind:**
- Any live server running the old build still sends the list to clients until you republish.
- The leaked IDs are already public. Treat that list as known.

## HUD startup errors

- **`HudClientService.meta.json`:** `ClientOnly` was the string `"true"`. It's now the boolean `true`.
- **New `_HudClientSetup.meta.json`:** marks the module `ClientOnly`. It had no realm restriction, so the server loaded it. On the server `Players.LocalPlayer` is `nil`, which caused the `DisplayName` error.

Two of my shell commands were blocked by the permission system (a `git status` with extra flags and a loop to print the meta files). I read the files with the search tools instead, so nothing was skipped.