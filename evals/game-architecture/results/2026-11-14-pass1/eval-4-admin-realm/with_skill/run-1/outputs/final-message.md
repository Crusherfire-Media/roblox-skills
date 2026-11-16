I've made the changes, but I couldn't playtest: shell commands that needed approval were blocked in this session. StyLua passes on the changed files. Nothing is committed.

## Admin list kept off clients

**The leak:** `AdminSharedService` required `AdminList` so both sides could call `IsAdmin`. Shared modules get copied to ReplicatedStorage, so the list went to every client along with them.

**What changed:**
- **`AdminList.luau`** now has an `AdminList.meta.json` with `RelocateToServerScriptService = true`, so the loader keeps it on the server, and `IgnoreLoader = true` because it's only data. Ideally it would sit inside `AdminServerService` as a private child module, but moving files from the shell was blocked. The meta file gives the same protection without a move.
- **`AdminSharedService`** no longer requires the list or has `IsAdmin`. It only holds the announcement length limit.
- **`AdminServerService`** now owns `IsAdmin` and is the only module that reads the list. It still rejects `Announce` from anyone who isn't an admin, and it answers a new `IsAdmin` remote function (added in `AdminNetwork`).
- **`AdminClientService`** asks the server whether the local player is an admin and builds the panel only if the answer is `true`. The call runs on its own thread so it doesn't hold up loading, and an error just means no panel.

**Already out:** the three IDs are in git history and in that Discord post, so this only stops new leaks. Players can still tell who the admins are when they announce, because announcements show the admin's display name.

## HUD startup errors
- **`HudClientService.meta.json`:** `ClientOnly` was the string `"true"`. It's now a real boolean, which stops the "is a string" warning.
- **`_HudClientSetup`:** it had no realm flag, so the server ran it too. On the server `Players.LocalPlayer` is nil, which caused the `DisplayName` error. I added `_HudClientSetup.meta.json` with `ClientOnly = true`.

## Before you ship
1. With Rojo synced, start a playtest. The output should have no `Loader attribute` or `>> Failed` lines.
2. Check that `AdminList` isn't anywhere under `ReplicatedStorage.RELOCATED_MODULES` on the client.
3. Check that an admin sees the panel and a non-admin doesn't.

**Separate problem:** every system's `SystemPackage` and `Implementation` `init.meta.json` writes `IconTint` as a bare array, like `[1, 0, 0]`. Rojo 7.6 and later reject that and want `{ "Color3": [1, 0, 0] }`, and this project uses Rojo 7.7. I left those files alone because they weren't part of this request. Tell me if you want them fixed.