---
name: implement-godot-rule
description: Implement or change deterministic Godot game rules and state transitions with GUT-based TDD while preserving repository contracts. Use for mechanics, scoring, phase resolution, legal actions, seeded randomness, time-dependent rules, regressions, or application wiring whose canonical behavior belongs in src/domain or src/game.
---

# Implement a Godot rule

1. Read the relevant rules, decision entries, active slice, `docs/contracts/architecture.md`, `docs/contracts/testing.md`, and the nearest `AGENTS.md` files.
2. Identify the current canonical owner, request entry point, and affected tests. Search `src/` and `tests/` before adding a new type or helper.
3. If ordering, phases, or playback are involved, read `docs/contracts/simulation-sequencing.md` and state why the design complies before editing.
4. Add or adjust a GUT spec for the observable behavior. Run it and confirm the intended failure before implementation.
5. Implement the smallest coherent rule in `src/domain/`. Inject RNG, time, persistence, and IDs through `src/core/`; do not call Godot node or rendering APIs from domain code.
6. Wire requests through `src/game/` when integration is required. Do not add a parallel resolver path from UI or presentation.
7. Run the focused spec, affected integration specs, and `sh scripts/test.sh`.
8. Update rule truth, principles, decisions, or slice scope according to `docs/contracts/documentation.md`.

Report the player-visible change, verification evidence, and any design uncertainty. Do not convert an implementation inference into a settled rule.
