---
name: shape-vertical-slice
description: Turn a Godot game idea, mechanic proposal, or broad feature into the smallest coherent playable slice that can answer one design question. Use when defining prototype scope, selecting the next slice, separating settled rules from hypotheses, or revising docs/vertical-slices.md after a design discussion or playtest.
---

# Shape a vertical slice

1. Read `docs/contracts/documentation.md`, `docs/game-rules.md`, `docs/design-principles.md`, the latest relevant decisions, and the active slice.
2. State the single design question the slice must answer. If the request contains several independent questions, recommend an order and scope only the first coherent learning loop.
3. Separate inputs into:
   - settled rules that the slice must preserve;
   - hypotheses the slice is intended to test;
   - implementation conveniences that must not become rules;
   - explicitly deferred work.
4. Surface any source conflict or material rule choice before treating it as settled.
5. Describe one end-to-end player-visible path. Include the initial state, meaningful decision, resolved consequence, and replay or end condition.
6. Define exit evidence that can actually answer the question: deterministic tests, observable UI behavior, and a short playtest prompt where applicable.
7. Update `docs/vertical-slices.md`. Update rule truth or append a decision only when the user deliberately accepts a rule change.

Keep the slice small enough to implement and learn from without scaffolding speculative systems. Do not disguise a content list, architecture migration, or polish backlog as a vertical slice.
