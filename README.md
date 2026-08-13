# Chucky Eggs

A tactical conveyor game about choosing which eggs deserve the spoon. Every thwack fires a fixed coloured spoon circuit, Cuckoos copy damage dealt to neighboring eggs, Plovers retreat by shoving other eggs forward, and every survivor moves closer to the drop.

The current playable slice is a 20-thwack day with a fixed Chicken, Cuckoo, Plover, and Spoonbill supply. Three-hit Chickens award 3 points; four-hit Cuckoos award 1 while copying damage from neighboring eggs. Two-point Plovers take six damage and swap one slot toward the pipe when directly struck and left alive. Five-hit Spoonbills award 4 points and take double direct damage from Pink. Score 10 points before the final bell.

## What is included

- A runnable Godot 4.7 project and vendored GUT 9.7.1 test runner.
- Engine-free `domain`, injected `core`, coordinating `game`, rendering `ui`, and animation `presentation` boundaries.
- Explicit architecture, documentation, testing, and simulation-sequencing contracts.
- Root and directory-scoped `AGENTS.md` guidance for Codex.
- Repository-local skills for shaping a vertical slice, implementing a deterministic rule, and verifying presentation work.
- Living templates for rules, principles, decisions, slice scope, and playtest evidence.

## Run

Open `project.godot` in Godot 4.7 or run:

```sh
godot --path .
```

Three large foreground controls fire fixed spoon circuits: Red strikes slots 1 and 3, Blue strikes slots 2 and 4, and Pink strikes slot 5. Every connected spoon fires, so an empty position wastes that strike. Keyboard players can move focus with Tab and Shift+Tab, then press Enter. Every shell shows its remaining toughness, hatch score seal, and any effect emblem, including the next three eggs in the left pipe; score, remaining thwacks, mute, and reduced-motion controls stay visible.

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
