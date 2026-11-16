# Motion and feedback

How much to animate, for how long, and what every press and reward should do. How to tween in
code is in the `roblox-dev:vide` skill (`spring`, `TweenService`); this file sets the targets.

## How much juice

- Kao (2020): **medium and high juice beat both none and extreme** on player experience,
  motivation, play time, and performance [study]
  ([survey summary](https://arxiv.org/pdf/2011.09201)). The effect is an inverted U.
- Juul and Begy (2016, preliminary): heavy juice raised ratings but lowered performance [study,
  preliminary]. Vibration added to feedback can improve experience [study].
- Animation pulls attention, which is a reason to keep idle UI still while the player is playing
  [study, cited by NN/g]. A pulsing button competes with the game.
- Roblox: use animated cues (particles, wiggling buttons, arrows) "in moderation" [standard]
  ([UI/UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design)).

## Timings

| Animation | Duration | Label |
|---|---|---|
| Press or hover feedback | About 100 ms; a visible state change within 100 ms | [practitioner; inference from NN/g limits] |
| Modal or panel entering | 200-300 ms, ease out | [practitioner] |
| Large moves across the screen | Up to 400 ms | [practitioner] |
| Anything | Under 500 ms ("feels like a drag") | [practitioner] |
| Exits | Shorter than entrances (300 ms in, 200-250 ms out), ease in | [practitioner] |

Source: [NN/g animation duration](https://www.nngroup.com/articles/animation-duration/). The more
often a player sees an animation, the shorter it should be [practitioner]. A menu opened twenty
times a session gets the short end.

Swink's "Game Feel" millisecond thresholds weren't verified [unverified]. The "400 ms Doherty
threshold" doesn't trace back to its paper (`evidence.md`).

## Press feedback

- Every press changes state visibly within 100 ms (scale down a few percent, darken, or move a
  pixel or two) and plays a short sound where sound fits the screen [inference]. Console menus add
  sounds for selection and movement [standard] (Roblox console guidelines).
- A press that starts something slow shows a busy state on the button itself past 1 s [standard,
  NN/g].
- A press that can't succeed (locked, not enough of something) still responds: a short shake or
  a message that says why, never silence [inference].

## Reward moments

- Roblox calls milestones "moments of joy" and recommends ending onboarding on one [standard]
  ([Onboarding](https://create.roblox.com/docs/production/game-design/onboarding)).
- Layer two or three channels for rewards (a scale pop, a sound, particles) and keep routine
  actions to one or two [inference from the inverted U].
- Keep particles and screen shake away from text and from the play focus during moments of skill
  [inference]. A celebration over the place the player needs to look is a penalty.
- A reward that interrupts play (a full-screen card) is dismissible with one press and doesn't
  queue behind other cards; stack several rewards into one summary [inference].

## Reduced motion and comfort

- `GuiService.ReducedMotionEnabled`: set tween time to 0 or fade instead of moving [standard].
  Every animation in a spec has its reduced-motion version written down.
- Three flashes a second or fewer [standard] (WCAG 2.3.1). No full-screen flashes; avoid flicker,
  background motion, and sudden movement [practitioner, GAG].
- Screen shake and camera effects tied to UI respect reduced motion too [inference].
- In VR, nothing in the UI moves the camera, and menus don't lock to the head (Meta) [standard].
