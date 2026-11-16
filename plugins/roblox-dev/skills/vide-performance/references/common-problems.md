# Common problems

Symptoms in Vide UI performance work, their cause, and the fix.

| Symptom | Cause | Fix |
|---|---|---|
| A page or tab stalls every time it is shown | Keyed by the current key only, so the old one is destroyed | Key by a visited map and keep pages |
| A kept page's text is missing until its panel reopens | Automatically sized text measured during a grow-in from near 0 and not measured again while its page was hidden (the full trigger was not isolated) | Give the page a `UIScale` of 1 while shown and 1.0001 while hidden |
| A kept page appears in place on its first visit | Its presence flag started true | Start it false and set it true after the build |
| A reused view does not animate in on return | Its springs are already at rest | A visit counter that snaps them to the entrance's start |
| A list's grow-in is slow even with off-window rows hidden | Hidden UI is still laid out | Unparent off-window rows through per-row Folders |
| A closed panel still costs script time every frame | Per-frame connections not tied to a showing flag | Route them through the panel's showing scope |
| A UI sound plays late, the first time or every time | Nothing kept it cached, so it loads its asset when cued | Hold the screen's sounds while it can play them |
| UI flickers or goes blank at low graphics quality | Too many CanvasGroups for the budget | Make each exist only while drawn |
| An element blinks white for one frame as it appears or goes away | A CanvasGroup made or removed while its own `GroupTransparency` is low | Hold `GroupTransparency` near 1 for its first two drawn frames and before removal |
| Frames slow while a panel scales, with size listeners in the profile | Listeners write on every scale step | Feed a scale-free `derive` |
| A label's text changes several times per drawn frame | Its clock runs on `Heartbeat`, which can fire several times per drawn frame | Drive UI clocks from `PreRender` |
