# Chucky Eggs

> **Branch prototype:** `codex/hopper-tap-combos` launches a branch-only five-bay experiment. Each bay has one individually operated coloured spoon; opening an egg refills that same position from the visible hopper after the complete tap cascade. The canonical conveyor game remains available at `res://src/ui/main.tscn` and its settled rules are unchanged pending playtest evidence.

A tactical conveyor game about choosing which eggs deserve the spoon. Every thwack fires a fixed coloured spoon circuit, Cuckoos copy damage dealt to neighboring eggs, Plovers retreat to the left after surviving a direct hit, and every survivor moves closer to the recycling bin.

The current playable slice is a multi-day producer-flock run on one five-slot track. Grandma starts each day with 10 Patience and every resolved thwack costs 1 Patience. The starting flock has three Chickens, two Cuckoos, and three Sparrows. Three-hit Chickens award 3 points; four-hit Cuckoos award 1 while copying damage from neighbouring eggs; one-hit Sparrows award 1 and have a 5% Double Yolker chance. Four-point Plovers take six damage and swap one bay to screen-left when directly struck and left alive. Five-hit Spoonbills award 4 points and take double direct damage from Pink. Unhatched eggs that leave slot 5 enter a visible bin with their cracks intact; once both the hopper and conveyor are empty, the bin is shuffled back into the hopper. Day 1 requires 10 points; Day 2 and later days require 9. A day ends as soon as a resolved thwack meets Grandma's appetite, then banks £1 for each remaining point of Patience.

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

Foreground levers fire three fixed spoon controls on every day: Red 1+3, Blue 2+4, and Pink 5. Every lever remains active during an unlocked day and every connected position fires; pulling a completely empty circuit still advances the belt and costs 1 Patience. Keyboard players can move focus with Tab and Shift+Tab, then press Enter. Every shell shows its remaining toughness, hatch score seal, and any effect emblem, including the next three eggs in the left pipe; hopper and bin counts, Grandma's appetite and Patience, cash, mute, and reduced-motion controls stay visible.

### Development start

In a debug run, press `F3` at any time to replace the current run with a fresh Day 3 session. Restart then remains on Day 3. Open **Settings → Choose Starting Eggs** (or press `F4`) to add eggs, arrange their exact entry order, and increase starting Patience before launching a fresh Day 3 session. Restart preserves that setup. This developer action and menu entry are unavailable in release builds.

To launch Day 3 directly from the command line, pass the user argument after `--`:

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
