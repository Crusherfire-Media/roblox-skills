I've made both fixes, but I couldn't test them. My shell commands were blocked in this session, so I couldn't run StyLua or start Rojo and a playtest. Nothing is committed.

## Admin list
The list reached players because `AdminSharedService` required `AdminList` so the client could check whether it was an admin. Shared modules are copied to ReplicatedStorage, so every client got a copy of the list.

- **`AdminList.meta.json`** (new): marks the list `RelocateToServerScriptService = true`, so it stays in ServerScriptService and is never copied to clients.
- **`AdminSharedService.luau`**: no longer requires `AdminList`. `IsAdmin` moved out of it into `AdminServerService.luau`.
- **`AdminNetwork/GetIsAdmin.model.json`** (new) adds a remote that the client calls to ask "am I an admin?". The server answers only for the player who called it, so a client never sees the list or who else is an admin.
- **`AdminClientService.luau`**: makes that call in the background when it starts, without holding up loading, and shows the announcement panel only if the answer is yes. If the call fails, no panel appears.
- The server still rejects announcements from non-admins, now using the server-side `IsAdmin`.

**The IDs already posted are still public.** Older published versions of the place, and anyone who saved a copy, still have the list. This fix protects future changes to it. Any power that relies on keeping those IDs secret should be reconsidered.

## HUD startup errors
- **`HudClientService.meta.json`**: `ClientOnly` was the text `"true"` rather than a real true/false value. It's now a real `true`, which removes the "is a string" warning.
- **`_HudClientSetup.meta.json`** (new): `_HudClientSetup` had no `ClientOnly` setting, so the server loaded it too. On the server there is no local player, which caused the `DisplayName` error. It now runs only on clients.

## To check
- Run a playtest and confirm the output has no `>> Failed` or `Loader attribute` lines.
- Join as an admin and as a non-admin: the admin should see the panel and the other player shouldn't.
- During the playtest, check that `AdminList` isn't under `ReplicatedStorage.RELOCATED_MODULES`.

I didn't change this, but the `SystemPackage` and `Implementation` folder settings write their colors in a short form (`"IconTint": [r, g, b]`) that Rojo 7.6 rejects. If Rojo errors on those files, the fix is `{ "Color3": [r, g, b] }`.