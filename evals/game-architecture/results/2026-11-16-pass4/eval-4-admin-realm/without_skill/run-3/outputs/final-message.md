The admin list no longer goes to players' clients, and both HUD startup errors are fixed. The type checker, selene and stylua all come back clean. I haven't run it in Studio, so neither the loader behaviour nor the panel has been seen working in a live game.

## Admin list leak

**Why it leaked:** the `Systems` folder has `RelocateToReplicatedStorage = true`, so every module inside it moves to `ReplicatedStorage`, where clients can read it. That included `AdminList`, and `AdminSharedService` (also sent to clients) required it so clients could check `IsAdmin` for themselves.

**What changed:**
- **`AdminList.meta.json`** (new): sets `RelocateToServerScriptService = true` on `AdminList`. That takes it out of the `ReplicatedStorage` move and keeps it in `ServerScriptService`, the same flag `AdminServerService` already uses.
- **`AdminSharedService.luau`**: no longer requires `AdminList` or defines `IsAdmin`. A comment now warns that it must never require the list.
- **`AdminServerService.luau`**: `IsAdmin` lives here now, server only. The announcement check works as before, so the server still refuses announcements from non-admins.
- **New `CheckAccess` remote** in `AdminNetwork`: the client asks the server "am I an admin?" and gets back only true or false about itself. It can't learn about anyone else.
- **`AdminClientService.luau`**: asks `CheckAccess` and shows the panel only if the answer is `true`. If the request fails, no panel appears.

## HUD errors
- **`HudClientService.meta.json`**: `"ClientOnly": "true"` (text) is now `true` (a real true/false value). That removes the warning.
- **`_HudClientSetup.meta.json`** (new): marks the module `ClientOnly`. It had no flag, so the server loaded it too, and on the server `Players.LocalPlayer` is nil. That was the `DisplayName` error.

The three admin user IDs that were already posted are public now, and this change can't take them back. Because the server checks admin status on every announcement, knowing the IDs gives nobody admin rights. But if you'd rather they weren't tied to admin, you'd have to change who your admins are.