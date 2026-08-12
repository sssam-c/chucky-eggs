# Presentation guidance

`src/presentation/` owns visual and audio playback of already-resolved facts.

- Read `docs/contracts/simulation-sequencing.md` before editing.
- Presentation may acknowledge an event and report barrier completion; it may not choose results, targets, or event order.
- Treat awaited signals, tweens, deferred callbacks, cancellation, view replacement, and node lifetime as correctness concerns.
- A freed, cancelled, or replaced view must not submit duplicate or stale commands.
- Test observable order and completion behavior at the boundary.
