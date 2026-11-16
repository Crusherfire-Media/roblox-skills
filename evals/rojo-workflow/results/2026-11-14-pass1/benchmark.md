# Skill Benchmark: rojo-workflow

**Model**: claude-opus-5-5
**Date**: 2026-11-14T20:17:56Z
**Evals**: 1, 2, 3, 4 (3 runs each per configuration)

## Summary

| Metric | With Skill | Without Skill | Delta |
|--------|------------|---------------|-------|
| Pass Rate | 79% ± 27% | 95% ± 17% | -0.16 |
| Time | 154.1s ± 41.9s | 127.5s ± 75.0s | +26.6s |
| Tokens | 956118 ± 415468 | 651865 ± 601814 | +304253 |

## Trials

| Setup | Trials | Statuses | Target skill loaded | Tokens (mean ± sd) | Wall s (mean ± sd) | Cost $ (mean, total) |
|---|---|---|---|---|---|---|
| with_skill | 12 | ok 12 | 12/12 | 956118 ± 415468 | 154.1 ± 41.9 | 0.8568, 10.2821 |
| without_skill | 12 | ok 12 | 0/12 | 651865 ± 601814 | 127.5 ± 75.0 | 0.6104, 7.3245 |

Tokens count input, output, and cache reads and writes across every model the session used.

## Per trial

| Eval | Setup | Run | Status | Pass rate | Skills loaded | Tokens | Output tokens | Wall s | Cost $ |
|---|---|---|---|---|---|---|---|---|---|
| eval-1-move-rules | with_skill | 1 | ok | 0.5556 | roblox-dev:rojo-workflow, roblox-dev:game-architecture, roblox-dev:roblox-testing, roblox-dev:luau-style-guide, roblox-dev:code-comments | 1494022 | 14516 | 177.4 | 1.6342 |
| eval-1-move-rules | with_skill | 2 | ok | 0.5556 | roblox-dev:rojo-workflow, roblox-dev:game-architecture, roblox-dev:roblox-testing, roblox-dev:luau-style-guide, roblox-dev:code-comments | 946074 | 12069 | 149.7 | 0.8643 |
| eval-1-move-rules | with_skill | 3 | ok | 0.5556 | roblox-dev:rojo-workflow, roblox-dev:game-architecture, roblox-dev:roblox-testing, roblox-dev:luau-style-guide, roblox-dev:code-comments | 952481 | 12993 | 161.3 | 0.8951 |
| eval-1-move-rules | without_skill | 1 | ok | 1 | none | 418264 | 9888 | 107.7 | 0.5287 |
| eval-1-move-rules | without_skill | 2 | ok | 1 | none | 501937 | 9718 | 111.3 | 0.5629 |
| eval-1-move-rules | without_skill | 3 | ok | 1 | none | 318130 | 9011 | 100.9 | 0.4216 |
| eval-2-starter-kit | with_skill | 1 | ok | 1 | roblox-dev:rojo-workflow, roblox-dev:game-architecture, roblox-dev:luau-style-guide, roblox-dev:code-comments | 533621 | 8788 | 112.4 | 0.6297 |
| eval-2-starter-kit | with_skill | 2 | ok | 1 | roblox-dev:rojo-workflow, roblox-dev:game-architecture, roblox-dev:luau-style-guide, roblox-dev:code-comments | 828421 | 10626 | 133.8 | 0.7870 |
| eval-2-starter-kit | with_skill | 3 | ok | 1 | roblox-dev:rojo-workflow, roblox-dev:game-architecture, roblox-dev:luau-style-guide, roblox-dev:code-comments | 1459325 | 11202 | 170.7 | 0.9617 |
| eval-2-starter-kit | without_skill | 1 | ok | 1 | none | 264802 | 5504 | 85.9 | 0.3025 |
| eval-2-starter-kit | without_skill | 2 | ok | 1 | none | 233647 | 5341 | 72 | 0.2933 |
| eval-2-starter-kit | without_skill | 3 | ok | 1 | none | 267596 | 5818 | 80.1 | 0.3146 |
| eval-3-add-t | with_skill | 1 | ok | 1 | roblox-dev:rojo-workflow, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 946451 | 14377 | 177 | 0.9176 |
| eval-3-add-t | with_skill | 2 | ok | 1 | roblox-dev:rojo-workflow, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 1006516 | 11090 | 161.8 | 0.8246 |
| eval-3-add-t | with_skill | 3 | ok | 1 | roblox-dev:rojo-workflow, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 1244103 | 14817 | 188.5 | 0.9407 |
| eval-3-add-t | without_skill | 1 | ok | 1 | none | 371515 | 6713 | 81.9 | 0.4533 |
| eval-3-add-t | without_skill | 2 | ok | 1 | none | 366508 | 7056 | 84.5 | 0.4164 |
| eval-3-add-t | without_skill | 3 | ok | 1 | none | 507960 | 7657 | 91.1 | 0.5142 |
| eval-4-fix-project | with_skill | 1 | ok | 1 | roblox-dev:rojo-workflow | 1437830 | 17453 | 234.2 | 0.9888 |
| eval-4-fix-project | with_skill | 2 | ok | 0.4 | roblox-dev:rojo-workflow | 397746 | 7985 | 99.3 | 0.4347 |
| eval-4-fix-project | with_skill | 3 | ok | 0.4 | roblox-dev:rojo-workflow | 226822 | 7236 | 83.1 | 0.4036 |
| eval-4-fix-project | without_skill | 1 | ok | 1 | none | 843775 | 11876 | 152.9 | 0.8247 |
| eval-4-fix-project | without_skill | 2 | ok | 0.4 | none | 2152621 | 23392 | 294 | 1.5359 |
| eval-4-fix-project | without_skill | 3 | ok | 1 | none | 1575624 | 20052 | 268.2 | 1.1563 |

## Blind judge

| Eval | Pairs judged | with_skill wins | without_skill wins | Ties | Mean score with_skill | Mean score without_skill |
|---|---|---|---|---|---|---|
| eval-1-move-rules | 3/3 | 0 | 3 | 0 | 4 | 9.67 |
| eval-2-starter-kit | 3/3 | 0 | 3 | 0 | 8 | 8.93 |
| eval-3-add-t | 3/3 | 0 | 3 | 0 | 8.17 | 8.83 |
| eval-4-fix-project | 3/3 | 2 | 1 | 0 | 5.5 | 5.83 |
| **All** | 12/12 | 2 | 10 | 0 | 6.42 | 8.32 |

Judge runs: 12, mean 21793 tokens and 26.78 s each, $1.6978 in total.
