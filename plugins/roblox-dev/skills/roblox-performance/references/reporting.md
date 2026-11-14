# Reporting

End a diagnosis with this report:

```
## Performance report: <system or symptom>

**Workload**: <how it was reproduced, where it was measured>
**Bottleneck**: <subsystem and cause, with the evidence>

| Metric | Before | After |
|---|---|---|
| <frame time, KB/s, MB, draw calls> | | |

**Changes**: <what was changed, highest level first>
**Behavior**: <unchanged, or the changes the user approved>
**Tried and reverted**: <changes that did not move the number>
**Left alone**: <what was not optimized and why>
**For you to verify**: <what needs the user's eyes, a real device, or a live server>
```

Studio numbers come from a desktop running the client and server together. Frame rate on phones,
client memory, and anything that depends on real network conditions need a published build on a
real device, so list those under "For you to verify".
