# Chucky Eggs

A tactical conveyor game about choosing which eggs deserve the spoon. Every thwack fires a fixed coloured spoon circuit, Cuckoos copy damage dealt to neighboring eggs, Plovers retreat to the left after surviving a direct hit, and every survivor moves closer to the drop.

The current playable slice is a multi-day, 20-thwack producer-flock run. Three-hit Chickens award 3 points; four-hit Cuckoos award 1 while copying damage from neighboring eggs. Four-point Plovers take six damage and swap one bay to screen-left when directly struck and left alive. Five-hit Spoonbills award 4 points and take double direct damage from Pink. Day 1 requires 15 points; Day 2 and later days currently require 20. A day ends as soon as a resolved thwack reaches its target, then banks £1 for each unused thwack. Days 1–2 use the five-bay line; every run receives a free ten-bay hairpin refit before Day 3.

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

Foreground levers fire fixed spoon controls. The starting line uses three circuits: Red 1+3, Blue 2+4, and Pink 5. The Day 3 hairpin retains Red 1+3 and Blue 2+4 on the upper run, mirrors Green 7+9 and Purple 8+10 across the lower return, and lets Pink resolve lower slot 6 before upper slot 5. Five neutral wall spoons use target-dependent reach; Pink alone makes both contacts during one thwack. The tight right-hand bend is not an egg bay. Every connected position fires, so an empty position wastes that strike. Keyboard players can move focus with Tab and Shift+Tab, then press Enter. Every shell shows its remaining toughness, hatch score seal, and any effect emblem, including the next three eggs in the left pipe; score, cash, remaining thwacks, mute, and reduced-motion controls stay visible.

### Development start

In a debug run, press `F3` at any time to replace the current run with a fresh Day 3 session. Restart then remains on Day 3. To launch there directly from the command line, pass the user argument after `--`:

```sh
godot --path . -- --dev-day=3
```

The shortcut and launch argument are ignored by release builds.

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
