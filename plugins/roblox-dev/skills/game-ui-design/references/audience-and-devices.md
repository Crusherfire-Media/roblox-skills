# Audience and devices

Who plays Roblox, on what, and for how long, and what that means for UI. Figures are the latest
published as of October 2026.

## Age

- Q2 2026 shareholder letter: age-checked daily users split **35% under 13, 38% aged 13-17, 27%
  over 18** [standard] ([Q2 2026 letter](https://www.sec.gov/Archives/edgar/data/0001315098/000162828026051059/ex991-robloxq22026earnin.htm)).
  Only 57% of daily users had age-checked, Roblox calls the figures extrapolated and not
  comparable to the older self-reported data, and players who haven't checked probably skew
  young, so the real under-13 share may be higher [unverified inference].
- US adult daily users grew 32% year over year [standard], so the audience is widening, but
  minors still dominate.
- Age groups are under 9, 9-12, 13-15, 16-17, 18-20, and 21+. A facial age check has been required
  to chat worldwide since January 2026, and players chat by default only with nearby age groups
  [standard] ([Roblox newsroom](https://about.roblox.com/newsroom/2026/01/roblox-age-checks-required-to-chat)).
  Chat use had not recovered by Q2 2026, while preset Quick Words messages passed 5M a day
  [standard]. **UI can't count on chat to teach or coordinate players**; in-game prompts and
  preset pings carry that load [inference].
- Roblox Kids (ages 5-8) and Roblox Select (9-15) account types launched in June 2026, and only
  Minimal and Mild maturity experiences reach them [standard]
  ([Content maturity](https://create.roblox.com/docs/production/promotion/content-maturity)).

## Devices

- 2024: **80% of 82.9M daily users on mobile, 17% on PC, 3% on console** [standard, via trade
  press] ([PocketGamer.biz](https://www.pocketgamer.biz/80-of-roblox-users-are-on-mobile-contributing-46-of-robux-revenue/)).
  No 2025-2026 split has been published in text, and tablets and VR aren't broken out. The often
  repeated "72% of sessions on mobile" has no primary source [unverified].
- Many players switch devices: only 24% of players aged 10-65 play only on mobile [practitioner]
  (Newzoo, via [GameDev Reports](https://gamedevreports.substack.com/p/newzoo-roblox-as-a-platform-in-2025)).
  A player who learned the UI on a phone may open it on a PC or TV next.
- Roblox: "younger players are generally more likely to play on mobile or tablet devices" and
  "small screens can easily get overwhelmed with excessive buttons, screens, and text." It
  recommends a minimal mobile UI, Configs to switch UI per platform, and Experiments to test HUD
  layouts [standard] ([UI/UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design)).
- The platform must run "from low end mobile devices to high performance consoles and PCs"
  [standard]. Low-end phones lower the CanvasGroup memory cap (`platform.md`).

## Sessions

- Players averaged about 2.7 hours a day across all experiences in 2025 and played more than 24
  different experiences a month [standard] ([FY2025 10-K](https://www.sec.gov/Archives/edgar/data/1315098/000131509826000024/rblx-20251231.htm)).
  No official average session length is published.
- Roblox tells creators to get new players "into the fun part of your game as fast as possible"
  [standard] ([Engagement analytics](https://create.roblox.com/docs/production/analytics/engagement)).
  The "time to fun under 90 seconds" figure comes from a blog [unverified].
- The design consequence: a game is one of many a player samples, so each blocking popup or extra
  menu on the first screen is a likely exit [inference].

## Language

- Growth is mostly outside North America: in Q2 2026, Japan daily users grew 67% and India 64%,
  against 6% in the US and Canada [standard]. Roblox publishes no share of non-English players.
- Automatic translation covers **18 languages counting English** (Arabic, Chinese Simplified and
  Traditional, French, German, Hindi, Indonesian, Italian, Japanese, Korean, Polish, Portuguese,
  Russian, Spanish, Thai, Turkish, Vietnamese) [standard]
  ([Automatic translations](https://create.roblox.com/docs/en-us/production/localization/automatic-translations.md)).
  Region locales (pt-br, es-mx, fr-ca, en-gb) arrived in November 2025 [standard].
- Only text with `AutoLocalize` on is captured; **text inside images is never translated**; a
  TextBox captures only its `PlaceholderText` [standard].
- Labels that don't auto-size need 30-40% spare width for longer translations (a general rule of
  about 35% average expansion, not a Roblox figure) [practitioner]
  ([Transifex](https://www.transifex.com/?p=2608)). Thai, Arabic, and Hindi need fonts that cover
  them; check the font in each language [inference].

## How children use interfaces

NN/g ran three study rounds (2001, 2010, 2018) with 125 children aged 3-12 and wrote 156
guidelines [study] ([NN/g](https://www.nngroup.com/articles/childrens-websites-usability-issues/)):

- Design for at least three bands, **3-5, 6-8, and 9-12**, with teens separate. The youngest can't
  read, young children read tentatively, and older children scan.
- 14 pt text for young children, 12 pt for older ones. In 2018, children on Roblox skipped long
  instruction paragraphs.
- Young children avoid scrolling; older children scroll only when the design clearly shows more
  is there.
- Children "can't distinguish" ads from content, so promotional-looking panels read as noise or as
  the game.
- Redundant navigation (two routes to one place) is "very confusing" for children, against
  "slightly confusing" for adults.
- Children recover from errors by restarting, pressing Back, or leaving, not by troubleshooting.
- Familiar icons work: even 3-year-olds recognised video player controls.
- Until about age 9, children preferred touch to mouse and keyboard and did best with "large,
  simple actions"; they have poor mouse control and type slowly.

What follows for Roblox UI [inference]: icon plus one or two words on every button, instructions in
one line, one route per destination, a visible cue when a list scrolls, and error states with one
recovery button.

## Disability

- AbleGamers (2019): **26% of US players** have a disability that affects play; remapping (45%)
  and subtitles (41%) were the top requests [practitioner]
  ([PocketGamer.biz](https://www.pocketgamer.biz/devcom-2019-26-of-the-us-has-a-disability-that-affects-them-playing-games)).
- XAG cites about 2.9 billion people with some low vision [standard]. The "400 million disabled
  gamers" figure is [unverified]. There are no child- or Roblox-specific figures.
- Red-green color deficiency affects up to 8% of males of Northern European descent and about
  0.5% of females [study, via reviews]; Roblox's docs say "over 5%" of players [standard].
