I've moved the admin list onto the server only and fixed the HUD errors. I couldn't run a playtest, StyLua, Selene or the loader's relocation check in this session, so none of this has been run yet.

**Admin list**
The leak happened because `AdminList` sat in `SystemPackage` and was loaded by `AdminSharedService`, so the whole list was copied to every client.
- **The IDs now live only on the server.** They're in a new file, `AdminSystem/Implementation/_AdminServerSetup.luau`, which is marked server-only so it is never copied to players. It hands the list to `AdminServerService:AddAdmins()` at startup.
- **The admin check is now server-only.** `IsAdmin` moved out of `AdminSharedService` into `AdminServerService`. The shared service now holds only `MaxAnnouncementLength`.
- **Admins still see the panel.** I added a `GetIsAdmin` RemoteFunction to `AdminNetwork`. At startup each client asks the server whether it is an admin, and the server answers only for that player. If the answer is yes, the panel is created. The server starts answering only after the list is loaded, so an admin can't be told "no" during startup.
- **The server still refuses announcements from anyone else.** It checks against the same server-side list. The message checks are unchanged.

**HUD errors**
- `HudClientService.meta.json` had `"ClientOnly": "true"` (text) instead of `true`. I changed it to a real boolean, which removes the warning.
- `_HudClientSetup` had no `ClientOnly` flag, so it also ran on the server, where there is no local player. That's the `attempt to index nil with 'DisplayName'` error. I added `_HudClientSetup.meta.json` with `ClientOnly: true`.

**Things you need to do**
1. **Delete `AdminSystem/SystemPackage/AdminList.luau`.** This session wasn't allowed to delete files. I replaced its contents with an empty table so no IDs reach clients in the meantime, and nothing loads it any more.
2. **Treat those three IDs as public.** Players who already joined have them, and they stay in git history. The fix only protects them from now on.
3. **Do a playtest.** As an admin you should see the panel and be able to announce. As anyone else you shouldn't see a panel, and the output should have no `>> Failed` or `Loader attribute` lines.

The tint files (`init.meta.json`) in both systems write `IconTint` as a bare array, which Rojo 7.6 and later reject. You might need `{ "Color3": [...] }` instead. I didn't change those files.