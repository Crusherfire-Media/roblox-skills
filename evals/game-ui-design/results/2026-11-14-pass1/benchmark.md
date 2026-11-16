# Skill Benchmark: game-ui-design

**Model**: claude-opus-5-5
**Date**: 2026-11-14T18:14:43Z
**Evals**: 1, 2, 3, 4 (3 runs each per configuration)

## Summary

| Metric | With Skill | Without Skill | Delta |
|--------|------------|---------------|-------|
| Pass Rate | 95% ± 6% | 77% ± 20% | +0.18 |
| Time | 773.0s ± 394.6s | 384.6s ± 147.8s | +388.4s |
| Tokens | 4936484 ± 3251180 | 1334708 ± 1043643 | +3601776 |

## Trials

| Setup | Trials | Statuses | Target skill loaded | Tokens (mean ± sd) | Wall s (mean ± sd) | Cost $ (mean, total) |
|---|---|---|---|---|---|---|
| with_skill | 12 | ok 12 | 12/12 | 4936484 ± 3251180 | 773.0 ± 394.6 | 3.7599, 45.1191 |
| without_skill | 12 | ok 12 | 0/12 | 1334709 ± 1043643 | 384.6 ± 147.8 | 1.5178, 18.2133 |

Tokens count input, output, and cache reads and writes across every model the session used.

## Per trial

| Eval | Setup | Run | Status | Pass rate | Skills loaded | Tokens | Output tokens | Wall s | Cost $ |
|---|---|---|---|---|---|---|---|---|---|
| eval-1-inventory-screen | with_skill | 1 | ok | 0.875 | roblox-dev:game-ui-design, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture, roblox-dev:vide-ui-labs | 4626601 | 71657 | 747 | 3.6058 |
| eval-1-inventory-screen | with_skill | 2 | ok | 0.875 | roblox-dev:game-ui-design, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:vide-ui-labs, roblox-dev:vide-performance, roblox-dev:code-comments, roblox-dev:game-architecture, roblox-dev:rojo-workflow | 5861096 | 82298 | 866.9 | 4.3521 |
| eval-1-inventory-screen | with_skill | 3 | ok | 1 | roblox-dev:game-ui-design, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture, roblox-dev:vide-ui-labs, roblox-dev:vide | 10066694 | 133131 | 1372.8 | 6.8712 |
| eval-1-inventory-screen | without_skill | 1 | ok | 0.875 | none | 1962591 | 49425 | 519.4 | 2.1115 |
| eval-1-inventory-screen | without_skill | 2 | ok | 1 | none | 3903031 | 56788 | 625.7 | 2.6982 |
| eval-1-inventory-screen | without_skill | 3 | ok | 0.625 | none | 1864448 | 50996 | 522.8 | 2.0602 |
| eval-2-hud-review | with_skill | 1 | ok | 1 | roblox-dev:game-ui-design | 378489 | 17432 | 193.8 | 0.9005 |
| eval-2-hud-review | with_skill | 2 | ok | 1 | roblox-dev:game-ui-design | 189556 | 17153 | 172.3 | 0.7987 |
| eval-2-hud-review | with_skill | 3 | ok | 1 | roblox-dev:game-ui-design | 302294 | 16515 | 176 | 0.7875 |
| eval-2-hud-review | without_skill | 1 | ok | 0.75 | none | 237959 | 17514 | 186.9 | 0.6711 |
| eval-2-hud-review | without_skill | 2 | ok | 0.75 | none | 188774 | 15792 | 166.2 | 0.6142 |
| eval-2-hud-review | without_skill | 3 | ok | 1 | none | 188597 | 15731 | 167.1 | 0.6117 |
| eval-3-hud-platforms | with_skill | 1 | ok | 1 | roblox-dev:game-ui-design, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture, roblox-dev:vide-ui-labs, roblox-dev:vide, roblox-dev:game-ui-design, roblox-dev:vide-ui-labs | 5350617 | 75267 | 834.8 | 4.0884 |
| eval-3-hud-platforms | with_skill | 2 | ok | 1 | roblox-dev:game-ui-design, roblox-dev:vide, roblox-dev:vide-ui-labs, roblox-dev:luau-style-guide, roblox-dev:game-architecture, roblox-dev:code-comments, roblox-dev:rojo-workflow, roblox-dev:vide, roblox-dev:vide-ui-labs | 7936653 | 95293 | 1078 | 5.2719 |
| eval-3-hud-platforms | with_skill | 3 | ok | 1 | roblox-dev:game-ui-design, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:vide-ui-labs, roblox-dev:code-comments, roblox-dev:game-architecture, roblox-dev:vide, roblox-dev:vide-ui-labs | 3486190 | 68449 | 754.6 | 3.4920 |
| eval-3-hud-platforms | without_skill | 1 | ok | 1 | none | 978995 | 33516 | 354.1 | 1.3090 |
| eval-3-hud-platforms | without_skill | 2 | ok | 0.8571 | none | 968668 | 36008 | 371.9 | 1.3953 |
| eval-3-hud-platforms | without_skill | 3 | ok | 0.8571 | none | 950358 | 42574 | 426.9 | 1.6257 |
| eval-4-settings-menu | with_skill | 1 | ok | 0.875 | roblox-dev:game-ui-design, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture, roblox-dev:vide-ui-labs, roblox-dev:vide, roblox-dev:vide-ui-labs | 6970775 | 91345 | 1005.3 | 4.9826 |
| eval-4-settings-menu | with_skill | 2 | ok | 0.875 | roblox-dev:game-ui-design, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture, roblox-dev:vide-ui-labs, roblox-dev:vide, roblox-dev:vide-ui-labs, roblox-dev:game-ui-design | 7016839 | 93377 | 1050 | 5.0437 |
| eval-4-settings-menu | with_skill | 3 | ok | 0.875 | roblox-dev:game-ui-design, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:vide-performance, roblox-dev:code-comments, roblox-dev:game-architecture, roblox-dev:vide-ui-labs, roblox-dev:vide | 7052005 | 90561 | 1024 | 4.9247 |
| eval-4-settings-menu | without_skill | 1 | ok | 0.625 | none | 1871202 | 41440 | 457.1 | 1.8716 |
| eval-4-settings-menu | without_skill | 2 | ok | 0.375 | none | 1170526 | 35795 | 380.6 | 1.4964 |
| eval-4-settings-menu | without_skill | 3 | ok | 0.5 | none | 1731353 | 40396 | 436.4 | 1.7482 |

## Blind judge

| Eval | Pairs judged | with_skill wins | without_skill wins | Ties | Mean score with_skill | Mean score without_skill |
|---|---|---|---|---|---|---|
| eval-1-inventory-screen | 3/3 | 3 | 0 | 0 | 8.17 | 7.33 |
| eval-2-hud-review | 3/3 | 3 | 0 | 0 | 8.67 | 7.17 |
| eval-3-hud-platforms | 3/3 | 3 | 0 | 0 | 8.2 | 6.43 |
| eval-4-settings-menu | 3/3 | 3 | 0 | 0 | 8 | 5.83 |
| **All** | 12/12 | 12 | 0 | 0 | 8.26 | 6.69 |

Judge runs: 12, mean 48124 tokens and 36.29 s each, $4.5492 in total.
