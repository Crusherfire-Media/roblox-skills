---
name: game-ui-design
description: Designing Roblox game UI for the players who use it - what a HUD, menu, inventory, settings screen, dialog, notification, or onboarding flow shows, where it sits, and how it reads and responds on phones, tablets, PCs, consoles, and VR for a mostly young audience, with evidence-graded thresholds. Load it before designing, planning, or reviewing any player-facing screen or HUD; when critiquing a UI screenshot or mockup; when UI is cluttered, hard to read, hard to reach with thumbs, or broken on gamepad; when adding accessibility options, a tutorial, or progression UI; and when measuring UI with funnels, experiments, or playtests.
---

# Game UI design

Roblox players are mostly young and mostly on phones. In Q2 2026, 35% of age-checked daily users
were under 13 and 38% were 13-17 [standard], and the last published split put 80% of daily users on
mobile, 17% on PC, and 3% on console (2024) [standard]. Every default below follows from that:
short words beside icons, big targets kept out of the thumb corners, play on the first screen, and
layouts built on the engine's live signals instead of hardcoded numbers.

This skill decides **what** the UI shows, **where** it sits, and **how** it behaves for each input.
Building it is other skills' job: `roblox-dev:vide` writes the code (its `references/screens.md` owns the
screen module, the root `UIScale`, and the touch control measurements), `roblox-dev:figma-to-roblox` ports a
design, and `roblox-dev:roblox-performance` (`references/ui.md`) owns what UI costs. Shops, purchase prompts,
and anything sold for Robux are out of scope.

## Evidence labels

Every claim in this skill and its references carries one label. Keep the label when you repeat a
claim to the user, and never upgrade it.

| Label | Meaning |
|---|---|
| `[study]` | Controlled or peer-reviewed research |
| `[standard]` | Roblox docs, API reference, or staff posts; platform and standards bodies (XAG, WCAG, Meta) |
| `[practitioner]` | Community posts, design systems, talks, studio write-ups, the Game Accessibility Guidelines |
| `[unverified]` | Secondary, anecdotal, or not confirmed against a primary source |
| `[inference]` | This skill's synthesis from the labeled facts around it |

Evidence on specific game components is thin. Treat the component defaults as hypotheses a
playtest or funnel can overturn, and say so when you recommend one.

| Read | Before |
|---|---|
| [references/audience-and-devices.md](references/audience-and-devices.md) | Deciding reading level, text density, device priority, or localization room |
| [references/platform.md](references/platform.md) | Placing UI near the top bar, core UI, or screen edges; choosing per-device layouts; text and fonts; world-space UI; VR or console; any text a player wrote or a link |
| [references/input-and-accessibility.md](references/input-and-accessibility.md) | Sizing touch targets, planning gamepad focus, VR panels, contrast, color, text size, or motion settings |
| [references/components.md](references/components.md) | Designing or reviewing a HUD, menu, tabs, inventory, settings, dialog, notification, tooltip, loading or error state, or number format |
| [references/motion-and-feedback.md](references/motion-and-feedback.md) | Choosing tween timings, press feedback, reward moments, sound, or reduced motion |
| [references/onboarding-and-progression.md](references/onboarding-and-progression.md) | Designing a first session, tutorial, hints, goals, quest trackers, or level-ups |
| [references/measurement.md](references/measurement.md) | Instrumenting a funnel, running an Experiment, or planning a playtest |
| [references/evidence.md](references/evidence.md) | Citing a UX law or a popular number, or when a claim sounds too neat |

## Steps

1. **Name the player and the moment.** Write down who sees this UI (assume a reader aged 6-12
   unless the game targets older players), which device you design first (a landscape phone,
   unless the game says otherwise), and what the player is doing when it appears: mid-action, in a
   lobby, or right after joining. Done when the spec states all three.

2. **Cut to what the moment needs.** List every element with its job and how often the player
   needs it: always, when relevant, or on request. Move "when relevant" items to contextual
   prompts (a `ProximityPrompt` or a cue that appears in the world) and "on request" items behind
   one button. Done when every element on screen has a job and a frequency, and nothing persistent
   is there only because other games show it.

3. **Place it.** Give each element a zone on a phone, a tablet, a PC, and a TV by the zone map
   below. Done when no element falls in a thumb corner or under the top bar on any of the four.

4. **Specify every state and every input.** For each interactive element, list its states
   (normal, hover, pressed, focused, disabled or locked, selected, empty, loading, error) and how
   each action is done with touch, mouse, keyboard, gamepad, and the VR laser pointer. Done when
   every action has a path for every input and no information is reachable only by hovering.

5. **Pass accessibility.** Run the accessibility rows of the checklist at the end. Done when every
   row passes or the spec names the exception and why.

6. **Add feedback and motion.** Give every press a visible change within 100 ms, and rewards two
   or three channels, by `references/motion-and-feedback.md`. Done when every animation has a
   duration, an easing, and a reduced-motion version.

7. **Verify.** Hand the build to `roblox-dev:vide` and its story check. Then look at the screen in the
   Device Emulator on a small phone, a tablet, 1080p, and the Xbox emulator, with the player text
   size at Largest. Done when each screenshot shows nothing clipped, overlapping, or out of reach,
   and the open questions are written down as playtest or funnel tasks
   (`references/measurement.md`).

## Zone map

Landscape phone first. The bottom-left and bottom-right corners belong to the thumbstick and jump
button [standard]. With default movement, the thumbstick can appear anywhere in the left 40% and
lower two thirds of the screen (`roblox-dev:vide` `references/screens.md`).

| Zone | Use for |
|---|---|
| Top strip, inside `GuiService.TopbarInset` | Small status that fits beside Roblox's own buttons; read the inset live |
| Top and upper middle | Currency, objective tracker, toasts, timers |
| Center | Only what the player must act on now: a modal, a reward moment, a reticle |
| Near the character or reticle | Short-lived, urgent state: low health, "can interact", ammo |
| Left or right edge, middle height | A short rail of menu buttons on phones; reachable on phones, not on tablets |
| Bottom corners | Nothing on touch; Roblox's controls and the player's thumbs |
| Bottom middle | A hotbar on PC and console; on touch only if it clears both thumb regions |

A button 40% down from the top is reachable on a phone and almost unreachable on a tablet
[standard], so a tablet layout moves side rails down or toward the corners' edges, not into them.

## Principles, in priority order

When two principles conflict, the earlier one wins.

1. **Play comes first.** The first screen after joining shows play, not a menu or a popup. Players
   try 24 or more experiences a month and decide "within minutes" [standard]. Each extra persistent
   element, popup, or step needs a job that beats a second of play [inference].
2. **Design for a young reader.** Children skip paragraphs, avoid scrolling, can't tell ad-like
   clutter from content, find redundant navigation "very confusing", and recover from errors by
   leaving [study]. Use an icon with one or two words, one-line instructions, one route to each
   place, and a single recovery button ("Try again", "Back to lobby").
3. **Phones and thumbs set the sizes.** Tap targets at least 10 mm, primary actions 15-20 mm, hit
   areas larger than the graphic, single taps instead of holds or gestures. Children aged 7-11
   miss targets 46% of the time against adults' 32% [study]. Details are in
   `references/input-and-accessibility.md`.
4. **Read the engine instead of hardcoding.** `ScreenInsets = CoreUISafeInsets` for anything
   interactive, `GuiService.TopbarInset` for the top bar (36 px before 2023, 58 px reserved since,
   and it "may vary"), `UserInputService.PreferredInput` to pick a touch or gamepad layout, and
   `GuiService.ViewportDisplaySize` to detect a TV [standard]. `TouchEnabled` is true on touch
   laptops, and `IsTenFootInterface` is deprecated [standard].
5. **Every action works with every input.** Buttons fire on `Activated`, every screen works with a
   D-pad plus select and back, every screen opens with a default selection, B or Back always backs
   out, and hover only previews what focus or a tap also shows [standard; inference].
6. **Readable over anything.** Text and icons over the 3D world get a backplate or a two-tone
   outline, measured against the least contrasting part of the scene: 4.5:1 for text, 3:1 for
   large text and inactive items [standard]. Color never carries meaning alone [standard]. Text
   stays live (never baked into images) so it translates and honors the player's text size
   [standard].
7. **Be consistent.** The same control sits in the same place on every screen, the same button
   does the same thing everywhere (A select, B back, LB/RB tabs) [standard], and a progression
   button never changes what it does [standard].
8. **Respond at once, celebrate in moderation.** A press changes state within 100 ms [inference
   from standard]. Medium juice beats none and beats extreme [study]. Idle UI stays still during
   play, because motion pulls the eye [study].
9. **Respect the player.** Confirm only serious, irreversible actions, and prefer undo
   [practitioner]. No streak-loss threats, countdown pressure, or fake progress aimed at children
   (ICO Standard 13 is the working bar) [standard; inference]. No links, handles, or QR codes that
   lead off Roblox [standard]. Filter all text a player wrote before showing it to anyone
   [standard].
10. **Measure instead of assuming.** Funnels show where players drop, playtests with about five
    fresh players show why, and Experiments need roughly 1,000 daily users to say anything
    [standard]. Recommend the test with the change.

## Defaults

| Item | Default | Label |
|---|---|---|
| Touch target | 10 mm minimum, 15-20 mm for primary actions, about 2 mm gaps | [study; practitioner] |
| Thumb button in `roblox-dev:vide`'s UI units | 44 or more (its floor); primary actions larger | [practitioner] |
| Text, console | 26 px body height at 1080p, 52 px at 4K | [standard] XAG 101 |
| Text, PC and VR | 18 px at 1080p | [standard] XAG 101 |
| Text scaling | Layout survives `PreferredTextSize` Largest without loss | [standard; inference] |
| Contrast | 4.5:1 text and key icons; 3:1 large text and inactive; 7:1 high contrast | [standard] XAG 102 |
| Line length | 80 characters (40 CJK) or fewer, sentence case | [standard] XAG 101 |
| Localization room | 30-40% spare width on labels that don't auto-size | [practitioner] |
| Press feedback | Visible within 100 ms | [inference] |
| UI tweens | 100 ms feedback; 200-300 ms modal in; under 500 ms; exits shorter | [practitioner] NN/g |
| Toast | One at a time, at least 6 s, longer for more words | [practitioner; inference] |
| Flashing | 3 flashes per second or fewer | [standard] WCAG 2.3.1 |
| Busy state | Spinner past 1 s; progress and cancel past 10 s | [standard] NN/g |

## Output formats

**Design review** (of a screenshot, a mockup, or a running screen):

1. One line naming what was reviewed and on which device and state. Then list what one image
   can't show (other devices, other states, motion, gamepad focus) and review those from the code
   or ask for them.
2. Findings ranked by harm to play. Each finding gives the element, what goes wrong and for whom,
   the principle number, the evidence label, and a concrete fix with sizes or API names.
3. What works, in one or two lines, so a fix doesn't remove it.
4. The questions only a playtest or funnel can answer.

**Screen spec** (before building): the player and moment from step 1; the element list with job
and frequency; a zone per element per device; states and the input path per action; the motion
list; the accessibility exceptions; the analytics events to log. Save it where the project keeps
design docs, or where the user says.

## Checklist

- [ ] The first screen after joining shows play, with no blocking popup.
- [ ] Every persistent element has a job; contextual items appear only when relevant.
- [ ] Nothing interactive sits in the thumb corners or under the top bar on phone or tablet.
- [ ] Interactive ScreenGuis use `CoreUISafeInsets`; top-bar UI reads `TopbarInset` live.
- [ ] Layout choice reads `PreferredInput` and `ViewportDisplaySize`, never `TouchEnabled` or
      `IsTenFootInterface`.
- [ ] Every tap target meets the touch size; primary actions are larger.
- [ ] Every action has a touch, mouse, keyboard, gamepad, and VR pointer path; buttons use
      `Activated`.
- [ ] Every screen has a default gamepad selection; modals trap focus; Back always backs out.
- [ ] No information is reachable only by hover.
- [ ] Text meets the size floors, passes contrast over the worst background, and fits at
      Largest text size and in a 35% longer translation.
- [ ] Color never carries meaning alone; locked, rare, and missing states have a second cue.
- [ ] Backgrounds honor `PreferredTransparency`; motion honors `ReducedMotionEnabled`.
- [ ] Labels are icon plus short word; instructions fit one line; each error offers one recovery.
- [ ] Destructive actions name the item and outcome, use verb buttons, and default to the safe
      option.
- [ ] No off-platform links or handles; player-written text is filtered.
- [ ] Every press responds within 100 ms; every animation has a reduced-motion version.
- [ ] The questions the design can't settle are written as playtest or funnel tasks.
