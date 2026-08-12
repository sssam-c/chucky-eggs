# Domain guidance

`src/domain/` owns pure, deterministic rules and state transitions.

- Do not depend on `Node`, `Control`, `SceneTree`, `Input`, tweens, animation, rendering, file IO, wall-clock time, or unseeded randomness.
- Inject randomness and time through `src/core/` seams.
- Write or adjust a failing GUT spec before implementation.
- Test observable rules and invariants rather than private structure.
- Emit explicit facts or events for presentation; do not encode animation instructions.
- Keep one canonical owner for each rule and state transition.
