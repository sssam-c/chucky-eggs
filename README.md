# Chucky Eggs

A tactile five-egg strategy game about deciding where each spoon tap creates the most useful chain reaction.

Five eggs sit in coloured cups on Grandma's table. Click one egg's spoon to damage it. Cuckoos copy damage dealt beside them, Plovers retreat left after surviving a direct tap, Spoonbills are vulnerable to Pink, and opened cups receive the next visible hopper eggs. Every five paid taps, Grandma's announced Hunger increase resolves and all five taps refresh. Hatch enough Yolk to reduce her Hunger to zero before the eggs run out.

The five-cup tabletop game is the authoritative version and the default project scene. The former conveyor, Belt Condition, flock, shop, and multi-day implementation remains in the repository as historical code while the new core loop is validated; it is not current rule truth.

## What is included

- A runnable Godot 4.7 project and vendored GUT 9.7.1 test runner.
- Deterministic five-tap Hunger rounds with explicit resolver-authored events.
- Five directly clickable spoons, large eggs in cups, and visible hopper-to-cup refills.
- A persistent Grandma sidebar that owns current Hunger, the next increase, and phase feedback.
- Engine-free `domain`, coordinating `game`, rendering `ui`, and animation `presentation` boundaries.
- Explicit architecture, documentation, testing, and simulation-sequencing contracts.

## Run

Open `project.godot` in Godot 4.7 or run:

```sh
godot --path .
```

Click any occupied spoon to tap the egg beneath it. Keyboard players can move focus with Tab and Shift+Tab, then press Enter. The interface always shows remaining shell toughness, Yolk value, the next three hopper eggs, available taps, Grandma's Hunger, and her announced next increase.

## Test

GUT is vendored so the suite works offline:

```sh
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot sh scripts/test.sh
```

The test script imports the project, syntax-checks every `test_*.gd` file, and runs the complete suite headlessly.

## Repository map

- `docs/game-rules.md`: current player-facing rule truth.
- `docs/design-principles.md`: current interpretation and design constraints.
- `docs/decision-log.md`: append-only history of deliberate decisions and supersession.
- `docs/vertical-slices.md`: current implementation scope and learning target.
- `docs/playtest-log.md`: observed evidence, separated from design intent.
- `docs/contracts/`: durable engineering and documentation contracts.
- `.agents/skills/`: reusable repository workflows discoverable by Codex.

See `AGENTS.md` before changing the project.
