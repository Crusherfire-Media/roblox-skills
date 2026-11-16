I've fixed the admin list leak and both HUD startup errors. luau-lsp, selene and stylua all pass, but I haven't run any of it in Studio.

## Admin list leak

**What was happening:** `Systems/init.meta.json` sets `RelocateToReplicatedStorage` on the whole `Systems` folder, so every module under it gets copied into `ReplicatedStorage.RELOCATED_MODULES`, where clients can read it. `AdminList` had nothing to stop that, and the client needed it anyway: `AdminSharedService` required it so `AdminClientService` could call `IsAdmin` to decide whether to show the panel. Anyone could open that module on their own client and read the IDs.

**What I changed** (all in `Tooling/AdminSystem/SystemPackage`):
- **`AdminList.meta.json` (new):** sets `RelocateToServerScriptService: true`, which keeps the module out of that copy-to-clients rule. It stays in ServerScriptService and is marked server-only.
- **`AdminSharedService.luau`:** no longer requires `AdminList` and no longer has `IsAdmin`. It now holds only `MaxAnnouncementLength`, and a comment warns not to put admin data back in it.
- **`AdminServerService.luau`:** now owns `IsAdmin` and requires `AdminList` directly. Both modules stay in ServerScriptService, so the require still works. Announcements are still rejected unless the sender is an admin, with the same type and length checks as before.
- **`AdminNetwork/GetIsAdmin.model.json` (new RemoteFunction):** the server's handler answers only "is the player calling this an admin?". A client learns its own status and nothing about anyone else.
- **`AdminClientService.luau`:** in `Start`, the client asks the server through `GetIsAdmin` and builds the panel only if the answer is `true`. The call runs in its own thread so the round trip doesn't hold up other modules starting. The panel code still ships to every client, which is fine: showing the panel is just for convenience, and the server checks every announcement itself.

Two things this can't fix:
- The IDs that were posted are already public. If you want them to stop meaning anything, rotate who's on the admin list.
- Live servers keep the old version until you publish this change, so publish soon.

## HUD startup errors
- **`HudClientService.meta.json`:** `"ClientOnly": "true"` was a string, so the loader warned. It's now the boolean `true`.
- **`Implementation/_HudClientSetup.meta.json` (new):** `ClientOnly: true`. This module had no realm restriction, so the server loaded it too. Its `Init` reads `Players.LocalPlayer.DisplayName`, and `LocalPlayer` is nil on the server, which caused the "attempt to index nil" error. It now runs only on clients, next to the `HudClientService` it sets up.

To confirm in Studio, start a test with an admin and a non-admin account:
- `AdminList` should not appear anywhere under `ReplicatedStorage.RELOCATED_MODULES`.
- Only the admin should get the panel.
- The server output shouldn't show the HUD warning or the HUD error.