# Godot Game Design Starter

A small Godot 4 repository for taking a game from uncertain design ideas to tested vertical slices, with explicit boundaries between design truth, deterministic rules, application flow, and presentation.

## What is included

- A runnable Godot 4.7 project and vendored GUT 9.7.1 test runner.
- Engine-free `domain`, injected `core`, coordinating `game`, rendering `ui`, and animation `presentation` boundaries.
- Explicit architecture, documentation, testing, and simulation-sequencing contracts.
- Root and directory-scoped `AGENTS.md` guidance for Codex.
- Repository-local skills for shaping a vertical slice, implementing a deterministic rule, and verifying presentation work.
- Living templates for rules, principles, decisions, slice scope, and playtest evidence.

## Start a game

1. Rename the project in `project.godot` and replace this README introduction.
2. Write the smallest currently settled rules in `docs/game-rules.md`.
3. Record why those rules were chosen in `docs/decision-log.md`.
4. Define one playable learning goal in `docs/vertical-slices.md`.
5. Implement deterministic behavior test-first in `src/domain/`.
6. Connect it to Godot through `src/game/`, then build scenes in `src/ui/` and playback in `src/presentation/`.
7. Record observed playtest evidence in `docs/playtest-log.md`.

Do not fill every document before prototyping. Write only enough durable context to keep rules, hypotheses, and implementation scope from being confused.

## Run

Open `project.godot` in Godot 4.7 or run:

```sh
godot --path .
```

## Test

GUT is vendored so the initial suite works offline:

```sh
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot sh scripts/test.sh
```

The test script imports the project, syntax-checks every `test_*.gd` file, and then runs the complete suite headlessly.

## Repository map

- `docs/game-rules.md`: current player-facing rule truth.
- `docs/design-principles.md`: current interpretation and design constraints.
- `docs/decision-log.md`: append-only history of deliberate decisions and supersession.
- `docs/vertical-slices.md`: current prototype scope and learning target.
- `docs/playtest-log.md`: observed evidence, separated from design intent.
- `docs/contracts/`: durable engineering and documentation contracts.
- `.agents/skills/`: reusable repository workflows discoverable by Codex.

See `AGENTS.md` before changing the project.
