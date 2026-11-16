# Evidence: myths and open gaps

Popular claims that fail against their sources, and what nobody has published. Correct a myth when
a user or a document relies on it, and say plainly when a number they want doesn't exist.

## Myths

| Myth | Correction | Label |
|---|---|---|
| "Menus should have 7±2 items (Miller)" | Miller's seven was a rough figure; working memory holds about 4 chunks, and it limits what must be remembered, not what's visible | [study] [Cowan 2001](https://www.cambridge.org/core/journals/behavioral-and-brain-sciences/article/magical-number-4-in-shortterm-memory-a-reconsideration-of-mental-storage-capacity/44023F1147D4A1D44BDC0AD226838496) |
| "Doherty threshold: productivity soars under 400 ms" | No primary quote of 400 ms found; the paper's emphasis is about 1 s. Use NN/g's 0.1 / 1 / 10 s limits | [unverified] / [standard] [NN/g](https://www.nngroup.com/articles/response-times-3-important-limits/) |
| "Unfinished tasks are remembered better (Zeigarnik)" | Failed a 2025 meta-analysis; only the tendency to resume (Ovsiankina) holds | [study] [Ghibellini & Meier 2025](https://ideas.repec.org/a/pal/palcom/v12y2025i1d10.1057_s41599-025-05000-w.html) |
| "Fingertips are 8-10 mm (MIT)" | MIT figures cited by NN/g are 16-20 mm fingertips; about 10 mm is Parhi's target size | [practitioner] [NN/g](https://www.nngroup.com/articles/touch-target-size/) |
| "The thumb-zone diagram is the standard" | Portrait, non-game data from 2012-13; its author disowns it as the only standard | [study, secondary] |
| "TouchEnabled means a phone" | True on touch laptops and handhelds; use `PreferredInput` | [standard] |
| "IsTenFootInterface detects console" | Deprecated; use `ViewportDisplaySize` | [standard] |
| "The top bar is 36 px" (or 58) | 36 before 2023, 58 reserved since, "may vary"; read `TopbarInset` | [standard] |
| "TextScaled keeps text consistent" | Sizes vary with string length and ignore `PreferredTextSize` | [practitioner; standard] |
| "IgnoreGuiInset is deprecated" | Not deprecated; a legacy toggle mapped onto `ScreenInsets` | [standard] |
| "Gate social links with PolicyService" | `AllowedExternalLinkReferences` always returns empty; off-platform links in UI are prohibited | [standard] |
| "Diegetic UI is better" | The one study's winner was also next to where players looked; proximity and numbers are the lesson | [study] |
| "Every game needs a tutorial" | Tutorials helped only the complex one of three games tested | [study] |
| "Hick's law says hide options" | It models choice among known options and warns against oversimplifying | [study, via secondary] |
| "72% of sessions are mobile" / "90 s time to fun" | No primary source; the published figure is 80% of daily users on mobile (2024) | [unverified] |
| "ScreenGuis curve in VR" | No official source; Roblox has no curvature property | [unverified] |
| "Three menu levels at most" | No source; the verified rule is to start playing without several menu levels | [unverified] |

## Open gaps

Roblox publishes none of these as of October 2026:

- A TV-safe margin, a 10-foot text size, a fixed top bar height, or a per-platform map of core UI
  placement.
- VR panel distance, curvature, size, or text size.
- A 2025-2026 device split (phone vs tablet, Quest share) or a non-English player share.
- Reading-level guidance.
- Pixel growth per `PreferredTextSize` step; release dates for `PreferredTransparency` and
  `ReducedMotionEnabled`; full release of UI Styling and the Input Action System.
- Funnel and custom-event rate limits.
- How a game's `ButtonB` binding orders against Roblox's built-in B that exits UI navigation, and
  whether gamepad selection scrolls a `ScrollingFrame` to the selected item on its own.

Nobody has published, as far as this research found:

- An age-banded children's touch target in millimetres, or a landscape reach study with children.
- A controlled study of inventory grids against lists, toast limits, cooldown styles, ghost bars,
  or damage numbers.
- A Roblox postmortem with a measured retention gain from an onboarding change. Treat any "change
  X raised D1 by Y%" without a primary link as [unverified].

The Apple HIG 44 pt, Material 48 dp, and WCAG 2.5.5 values weren't re-read from their primary
pages; they're widely cited, so check before quoting them as exact.
