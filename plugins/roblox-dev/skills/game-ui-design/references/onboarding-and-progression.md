# Onboarding and progression

The first session, tutorials and hints, goals, and what's fair to do with them when most players
are children. Measuring them is in `measurement.md`.

## What the evidence says about tutorials

- Andersen et al. (CHI 2012) tested eight tutorial designs on about **45,000 players** in three
  games. Tutorials raised play time by up to 29% and progress by up to 75% **only in the most
  complex game** (Foldit), with negligible effect in the two simpler games. Just-in-time
  instructions beat an up-front manual (+16% play time, +40% progress) in Foldit only.
  Restricting player freedom showed no learning benefit, and on-demand help hurt engagement in
  one game. The authors suggest tutorial investment "may not be justified" for games learnable by
  experimenting [study] ([project page](https://grail.cs.washington.edu/projects/game-abtesting/chi2012/)).
- No study covers tutorials for children aged 8-12.

## Roblox's onboarding guidance

[standard] ([Onboarding](https://create.roblox.com/docs/production/game-design/onboarding)):

- Onboarding is the first few minutes, and players decide "within minutes" (no seconds figure is
  given).
- **Teach the essentials**: movement, interaction controls, and the core loop, including why it
  matters. **Get to the fun quickly. Leave players wanting more.**
- A/B test individual steps, "such as a shorter dialogue sequence versus a guided arrow".
- Familiar inputs (number keys to equip) may not be obvious to newcomers [standard]
  ([UI/UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design)).

Roblox staff funnel example (DevForum, July 2024): only **29.52% of players went from "In Farm" to
"Plant Seed"**, and under 3% reached step 9. The fix was a world-space icon over the pots, not
more text; no before-and-after numbers were published [practitioner, staff post]
([Improving onboarding](https://devforum.roblox.com/t/improving-onboarding-through-funnel-events/3064458)).
The same post names five causes of drop-off (boredom, confusion, frustration or blockage, bugs,
edge cases) and says to fix the largest, earliest drop first.

## Designing the first session

For most Roblox games, where controls are standard and the loop is simple [inference]:

- **Teach in the world.** A beam or arrow to the first goal, a highlight on the next thing to use,
  and a prompt of one line, shown when the player needs it.
- **No front-loaded text.** No welcome popup, no paragraph of rules, no multi-page tutorial before
  play. Young readers skip paragraphs anyway [study, NN/g].
- **Show, then name.** The player does the action once, then the UI names it ("You planted a
  seed!") so the word and the action link up.
- **Let players skip.** Skippable tutorials are untested, but restricting freedom showed no
  benefit, so a skip carries little risk. Hide the skip from nobody, and put the hint back if the
  player stalls.
- **Watch for stalls instead of timing out.** Re-show the hint when the player hasn't done the
  step after a while, rather than closing it after a fixed time.
- **Don't teach through chat.** Chat is age-gated and quieter since 2026 (`audience-and-devices.md`).
- **End on a moment of joy** [standard]: the first reward lands within the first session's
  minutes and is celebrated (`motion-and-feedback.md`).

## Progression and goal UI

- Kivetz, Urminsky, and Zheng (2006): **people speed up as a reward gets closer**, ease off right
  after one ("post-reward resetting"), and even **illusory progress produces acceleration** and
  predicts retention [study]
  ([paper](https://business.columbia.edu/sites/default/files-efs/pubfiles/1200/goalgradient.pdf)).
  Nunes and Drèze's endowed-progress effect points the same way [study, secondary].
- Roblox recommends low early level thresholds tuned live with Configs; short-, mid-, and
  long-term goals shown "prominently in the game world or UI"; and celebrations at milestones
  [standard].
- The Zeigarnik memory advantage failed a 2025 meta-analysis, though people do tend to resume
  interrupted tasks (Ovsiankina) [study]. An unfinished tracker invites a return; it doesn't make
  players remember better.

Defaults [inference]:

- Always show the next goal with a count ("3/5 seeds"), in the objective tracker zone.
- Make the first goals small enough that the bar visibly moves in the first session.
- Set a fresh near goal right after each reward, so the post-reward dip is short.
- A level-up or unlock reveal names what's new and where to find it, in one line.

## Fair to children

The same research that makes progress bars work can manipulate. For a young audience:

- ICO Standard 13 forbids nudging children toward weaker privacy and allows nudges that support
  wellbeing, such as break prompts and pause-and-save [standard]
  ([ICO Standard 13](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/childrens-information/childrens-code-guidance-and-resources/age-appropriate-design-a-code-of-practice-for-online-services/13-nudge-techniques/)).
- The FTC's 2022 dark-patterns report covered children's apps (read through law-firm summaries)
  [standard, secondary]. One cited pattern is a "next level" button that unexpectedly changes
  meaning: **a progression button never changes what it does** [standard, secondary].
- A CHI 2025 paper calls deceptive design "a gray area unaddressed in Roblox's safety standards"
  [study] ([ACM](https://dl.acm.org/doi/10.1145/3706598.3713170)). In May 2026 advocacy groups
  filed an FTC complaint alleging manipulative engagement design on Roblox; these are allegations
  with no outcome yet [unverified].
- No Roblox developer rule on dark patterns was found, so ICO Standard 13 and the FTC report are
  the working bar [inference].

Rules that follow [inference]:

- Endowed or illusory progress only where it reflects real progress.
- No streak-loss threats, "come back or lose it" dailies, or countdowns that pressure a return.
- No guilt or fear wording in buttons ("No, I don't want rewards").
- Break reminders and pause-and-save are welcome; locking progress behind return visits is not.
