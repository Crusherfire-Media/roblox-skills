# Measurement

Funnels show where players drop off; playtests show why. Experiments settle a choice once a game
has enough players. API facts are as of October 2026.

## AnalyticsService

[standard] ([AnalyticsService](https://create.roblox.com/docs/reference/engine/classes/AnalyticsService)):

| Method | Use |
|---|---|
| `LogOnboardingFunnelStepEvent(player, step, stepName, customFields)` | The one-time first-session funnel |
| `LogFunnelStepEvent(player, funnelName, funnelSessionId, step, stepName, customFields)` | Funnels that repeat: opening a menu, a crafting flow |
| `LogCustomEvent(player, eventName, value, customFields)` | Counts and values that aren't a funnel; value defaults to 1 |
| `LogProgressionEvent` and `LogProgressionStart/Complete/FailEvent` | Levels, quests, stages |

- `FireCustomEvent`, `FireEvent`, `FireLogEvent`, and `FirePlayerProgressionEvent` are
  deprecated; no dates or replacements are named [standard].
- **Events are server-only and only work in published games**, not from the client or in Studio
  [standard] ([Funnel events](https://create.roblox.com/docs/production/analytics/funnel-events)).
  UI clicks happen on the client, so they reach the server by a RemoteEvent and the server checks
  them [inference].
- Funnels: up to 10 get dashboard tabs; saved steps expire after 180 days without events; only the
  10 most recent session IDs per player per funnel count; logging a later step completes skipped
  ones; only the first of a repeated step counts, but every call uses the unpublished rate limit
  [standard].
- Log onboarding step 1 in `Players.PlayerAdded`; keep step numbers stable across updates; check a
  client-sent step against the server's highest allowed step; after changing steps, start the
  dashboard's date range after the update [standard].
- Custom events: up to 100 per game; event names have a "much tighter cardinality limit" than
  custom fields, so use one event with a field; batch calls; data can take up to 24 hours to show
  [standard] ([Custom events](https://create.roblox.com/docs/production/analytics/custom-events)).

Instrumenting a menu [inference]: a funnel such as "SettingsMenu" with a new GUID session each time
it opens, and steps Open, Tab, Action, Confirm. A custom event with a field answers questions that
aren't a sequence, such as which tooltip players open.

## Experiments

[standard] ([Experiments](https://create.roblox.com/docs/en-us/production/experiments.md)):

- In-experience tests run on `ConfigService:GetConfigForPlayerAsync()`; the first `GetValue()`
  fixes enrollment, and `GetConfigAsync()` doesn't apply experiments. Up to 2 variants plus
  control. Matchmaking tests allow up to 3 variants, one running at a time.
- Tests run **14-60 days**, one active experiment per config key, and can target by country or
  player tenure.
- Reports cover D1 and D7 retention, playtime, and session time. Harm checks run in the first 24
  hours at a -10% playtime threshold, and harm decisions wait for 10,000 enrolled players. A
  result is significant when its confidence interval doesn't cross 0%.
- **Games under about 1,000 daily users "might struggle to get useful data."** Below that, use
  funnels and playtests.
- Roblox advises growing D1 retention and session time before driving traffic. Benchmarks
  (shown at 100+ daily users) compare against the 50th-90th percentile of similar top-1,000
  experiences; the docs' 12.4%-24.1% D1 range is an illustration [standard]
  ([Analytics](https://create.roblox.com/docs/production/analytics)). Retention by acquisition
  source arrived on 16 October 2025 [standard]. "D1 under 20% is critical" rules from third
  parties are [unverified].
- A UI experiment changes one thing (a tutorial step, HUD placement) and states the metric it
  expects to move before it starts [inference].

## Playtests

- Nielsen: **5 users find about 85% of problems** (N(1-(1-L)^n) with L about 31%). Three rounds of
  5 beat one round of 15; test 3-4 users per distinct group; about 20 users for numbers
  [standard/practitioner] ([NN/g](https://www.nngroup.com/articles/why-you-only-need-to-test-with-5-users/)).
  Faulkner's 2003 critique that 5-user samples vary widely wasn't retrieved [unverified].
- Test with **fresh players** who haven't seen the game [practitioner, Roblox staff].
- Give each tester a task ("get your first pet", "turn the music down") and watch: did they
  finish, how long did it take, where did they stop, what did they press that did nothing.
  Behavior carries the weight with children; questionnaires are weak for them [inference].
- Testing with children follows Hanna, Risden, and Alexander (1997): adapt methods to age and
  verbal ability [study, secondary]. Get a parent's consent and the child's own agreement
  [inference].
- Heuristic review: PLAY (built from 54 gamers rating games against 116 candidate heuristics)
  replaced HEP, whose 43 items were too long to remember [study]. The principles and checklist in
  this skill serve the same purpose for a quick pass.
- Questionnaires, if used: GUESS (9 subscales) and GUESS-18 are validated, though an adaptation
  with secondary-school students fit poorly [study]; PENS has a steadier structure than GEQ, whose
  structure failed to replicate [study].

## Studio checks before a playtest

- Device Emulator on a small phone, a tablet, 1080p, and a TV; the Controller Emulator; the Xbox
  emulator for the `TopbarSafeInsets` bug; the player text size at Largest [standard; inference].
- Studio can't fire analytics, so funnel checks need a published test place [inference].
