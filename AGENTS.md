# Agent Instructions (Godot + GDScript)

This repository is a Godot 4 game-design workspace. Preserve the distinction between settled rules, design hypotheses, implementation scope, and observed playtest evidence.

## Start here

Before editing, identify the relevant source of truth, code entry point, and existing tests.

- Read `docs/contracts/documentation.md` before changing game rules or design records.
- Read `docs/contracts/architecture.md` before moving ownership across source layers.
- Read `docs/contracts/testing.md` before changing deterministic behavior.
- Read `docs/contracts/simulation-sequencing.md` before changing timing, animation, phases, or event playback.
- Follow the nearest nested `AGENTS.md` when working under `src/` or `docs/`.

## Priorities

- Learn through the smallest coherent playable slice.
- Use TDD for deterministic rules, state transitions, and regressions.
- Keep deterministic game rules independent from Godot nodes.
- Preserve explicit command, resolver, event, and presentation boundaries.
- Use saved scenes for durable UI structure and reusable components.
- Prefer small, explicit state owners and one canonical implementation per rule.

## Change discipline

- Surface conflicts between source documents; never silently reconcile them.
- Treat unrecorded ideas as hypotheses, not settled rules.
- Prefer the smallest coherent, reversible change and preserve unrelated behavior.
- Search `src/` and `tests/` before adding another owner, helper, manager, or scene.
- Pause for a material rule choice, architecture trade-off, or scope expansion. Decide routine local details independently.
- Do not edit generated `.godot/` state. Treat `project.godot`, `.tscn`, and committed `.uid` files as reviewed source.

## Verification

Run checks proportionate to the change:

- deterministic behavior: relevant GUT specs, then the complete suite;
- UI or scene composition: GUT invariants plus an editor or running-game check;
- animation or timing: sequencing-contract review plus cancellation/replacement checks;
- project integration: headless import and test run with `sh scripts/test.sh`.

For a non-trivial handoff, report what changed for the player, what was verified, and remaining uncertainty.

## Documentation routing

- Update `docs/game-rules.md` when current player-facing rules change.
- Update `docs/design-principles.md` when the interpretation or design constraints change.
- Append `docs/decision-log.md` when a deliberate decision changes or supersedes a rule.
- Update `docs/vertical-slices.md` when current implementation scope changes.
- Append `docs/playtest-log.md` only with observed evidence; label interpretations separately.
