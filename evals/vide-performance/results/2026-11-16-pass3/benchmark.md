# Skill Benchmark: vide-performance

**Model**: claude-opus-5-5
**Date**: 2026-11-16T16:04:50Z
**Evals**: 1, 2, 3, 4 (3 runs each per configuration)

## Summary

| Metric | With Skill | Without Skill | Delta |
|--------|------------|---------------|-------|
| Pass Rate | 96% ± 8% | 94% ± 11% | +0.01 |
| Time | 176.1s ± 49.2s | 138.3s ± 23.5s | +37.8s |
| Tokens | 1328204 ± 499981 | 530196 ± 185133 | +798008 |

## Trials

| Setup | Trials | Statuses | Target skill loaded | Tokens (mean ± sd) | Wall s (mean ± sd) | Cost $ (mean, total) |
|---|---|---|---|---|---|---|
| with_skill | 12 | ok 12 | 12/12 | 1328204 ± 499981 | 176.1 ± 49.2 | 1.1788, 14.1459 |
| without_skill | 12 | ok 12 | 0/12 | 530196 ± 185133 | 138.3 ± 23.5 | 0.6704, 8.0449 |

Tokens count input, output, and cache reads and writes across every model the session used.

## Per trial

| Eval | Setup | Run | Status | Pass rate | Skills loaded | Tokens | Output tokens | Wall s | Cost $ |
|---|---|---|---|---|---|---|---|---|---|
| eval-1-kept-pages | with_skill | 1 | ok | 1 | roblox-dev:vide-performance, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:vide-ui-labs, roblox-dev:code-comments | 1595884 | 22115 | 237.7 | 1.4649 |
| eval-1-kept-pages | with_skill | 2 | ok | 1 | roblox-dev:vide-performance, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:vide-ui-labs | 1838926 | 20088 | 225.9 | 1.4522 |
| eval-1-kept-pages | with_skill | 3 | ok | 1 | roblox-dev:vide-performance, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:vide-ui-labs | 1444528 | 18230 | 188 | 1.3079 |
| eval-1-kept-pages | without_skill | 1 | ok | 1 | none | 458711 | 13622 | 142.7 | 0.6447 |
| eval-1-kept-pages | without_skill | 2 | ok | 1 | none | 715920 | 16173 | 160.6 | 0.8445 |
| eval-1-kept-pages | without_skill | 3 | ok | 1 | none | 691766 | 13030 | 131 | 0.7191 |
| eval-2-placed-list | with_skill | 1 | ok | 1 | roblox-dev:vide-performance, roblox-dev:vide, roblox-dev:vide-ui-labs, roblox-dev:luau-style-guide, roblox-dev:roblox-performance, roblox-dev:code-comments, roblox-dev:game-architecture | 2051439 | 24461 | 244.4 | 1.5534 |
| eval-2-placed-list | with_skill | 2 | ok | 1 | roblox-dev:vide-performance, roblox-dev:vide, roblox-dev:vide-ui-labs, roblox-dev:luau-style-guide, roblox-dev:code-comments | 2213560 | 22444 | 238.3 | 1.5738 |
| eval-2-placed-list | with_skill | 3 | ok | 1 | roblox-dev:vide-performance, roblox-dev:vide, roblox-dev:vide-ui-labs, roblox-dev:roblox-performance, roblox-dev:luau-style-guide, roblox-dev:code-comments | 1224599 | 18301 | 174.5 | 1.2445 |
| eval-2-placed-list | without_skill | 1 | ok | 1 | none | 474499 | 13460 | 133.2 | 0.6224 |
| eval-2-placed-list | without_skill | 2 | ok | 1 | none | 681849 | 14748 | 144.8 | 0.7758 |
| eval-2-placed-list | without_skill | 3 | ok | 1 | none | 843412 | 16534 | 164.7 | 0.8907 |
| eval-3-late-sound | with_skill | 1 | ok | 0.8333 | roblox-dev:vide-performance, roblox-dev:luau-style-guide, roblox-dev:vide, roblox-dev:vide-ui-labs, roblox-dev:code-comments, roblox-dev:game-architecture | 1048746 | 12615 | 130.1 | 1.0320 |
| eval-3-late-sound | with_skill | 2 | ok | 0.8333 | roblox-dev:vide-performance, roblox-dev:luau-style-guide, roblox-dev:vide, roblox-dev:vide-ui-labs, roblox-dev:code-comments | 1142948 | 14658 | 156.2 | 1.0033 |
| eval-3-late-sound | with_skill | 3 | ok | 0.8333 | roblox-dev:vide-performance, roblox-dev:luau-style-guide, roblox-dev:vide, roblox-dev:vide-ui-labs, roblox-dev:code-comments | 681277 | 11077 | 113 | 0.7638 |
| eval-3-late-sound | without_skill | 1 | ok | 0.8333 | none | 291834 | 13850 | 129.9 | 0.5502 |
| eval-3-late-sound | without_skill | 2 | ok | 0.8333 | none | 228042 | 9031 | 93.2 | 0.3977 |
| eval-3-late-sound | without_skill | 3 | ok | 0.6667 | none | 373496 | 11309 | 109 | 0.5059 |
| eval-4-canvas-groups | with_skill | 1 | ok | 1 | roblox-dev:vide-performance, roblox-dev:vide, roblox-dev:vide-ui-labs, roblox-dev:luau-style-guide, roblox-dev:code-comments | 874475 | 11896 | 132.4 | 0.8951 |
| eval-4-canvas-groups | with_skill | 2 | ok | 1 | roblox-dev:vide-performance, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:vide-ui-labs, roblox-dev:code-comments | 886103 | 12889 | 142.5 | 0.9007 |
| eval-4-canvas-groups | with_skill | 3 | ok | 1 | roblox-dev:vide-performance, roblox-dev:vide, roblox-dev:vide-ui-labs, roblox-dev:luau-style-guide, roblox-dev:code-comments | 935962 | 12023 | 130.1 | 0.9544 |
| eval-4-canvas-groups | without_skill | 1 | ok | 1 | none | 619698 | 15417 | 157.8 | 0.7816 |
| eval-4-canvas-groups | without_skill | 2 | ok | 1 | none | 533019 | 12192 | 121.2 | 0.6205 |
| eval-4-canvas-groups | without_skill | 3 | ok | 1 | none | 450102 | 16303 | 171.5 | 0.6921 |

## Blind judge

| Eval | Pairs judged | with_skill wins | without_skill wins | Ties | Mean score with_skill | Mean score without_skill |
|---|---|---|---|---|---|---|
| eval-1-kept-pages | 3/3 | 3 | 0 | 0 | 9 | 7.5 |
| eval-2-placed-list | 3/3 | 3 | 0 | 0 | 8.5 | 8 |
| eval-3-late-sound | 3/3 | 3 | 0 | 0 | 7.83 | 5.33 |
| eval-4-canvas-groups | 3/3 | 3 | 0 | 0 | 8.83 | 5.67 |
| **All** | 12/12 | 12 | 0 | 0 | 8.54 | 6.63 |

Judge runs: 12, mean 19689 tokens and 32.61 s each, $2.0164 in total.
