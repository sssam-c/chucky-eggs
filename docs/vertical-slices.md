# Vertical slices

This file describes current implementation and learning scope. It does not override current rules.

## Active slice — Cuckoo collateral

### Question

Does copied Cuckoo damage create deliberate prioritisation, or does the Cuckoo merely feel like free incidental scoring?

### Settled rules preserved

- The player may thwack any occupied position on the five-slot conveyor through its corresponding piano key and spoon hammer.
- A day lasts 20 thwacks, every thwack advances all survivors once, and eggs pushed beyond slot 5 are discarded.
- The pipe previews the next three eggs.
- Chicken eggs have 4 toughness and award 3 points.
- Cuckoo eggs have 4 toughness and award 1 point.
- Every Cuckoo copies damage once per damaged egg immediately ahead of or behind it in conveyor order. Echo damage never creates another echo.
- Apply the complete damage batch before hatching zero-toughness eggs in conveyor order.
- The day target is 10 points.

### Hypothesis

A low-value egg that cracks when a neighboring egg takes damage will create brief positional opportunities. Players will cultivate useful Chicken–Cuckoo pairings as the belt moves, while direct Cuckoo hits remain an occasional rescue rather than the default plan.

### Player-visible path

Start with a Chicken on the belt and see a blue-speckled Cuckoo among the next three eggs. As the Cuckoo enters beside a Chicken, compare its 1-point value with the Chicken's 3 points. Strike that neighboring Chicken: a cyan trace connects the pair, then the Cuckoo makes a sympathetic crack and loses one toughness before anything hatches or the belt advances. Strike a non-neighboring egg and see no echo. Plan across the authored sequence, reach or miss 10 points in 20 thwacks, then restart the same day to try another prioritisation pattern.

### In scope

- Deterministic Chicken and Cuckoo egg definitions and a repeatable authored supply.
- Adjacent per-damaged-egg Cuckoo echo damage with non-recursive batching.
- Conveyor-ordered hatch resolution after all damage in the batch.
- Distinct shell color and markings, name, value, tooltip, echo motion, echo audio, and a source-to-target adjacency trace for the Cuckoo.
- A 10-point success target and current score display.
- Existing piano-key thwack, crunchy impact, conveyor, pipe, input barrier, mute, and reduced-motion presentation.

### Implementation conveniences

- Repeat a short queue pattern that normally keeps no more than one Cuckoo on the five-slot belt; this exact frequency is a tuning convenience, not a permanent content-distribution rule.
- Keep both current egg types at 4 toughness so this slice isolates the echo decision from toughness valuation.
- Reuse the existing slot scene and resolver-event presenter with data-driven visual variants.

### Outside this slice

- Goose, Duck, Peacock, Ostrich, Quail, Magpie, or other egg types.
- The folded conveyor loop, paired-position spoons, belt expansion, upgrades, or progression.
- Random supply generation, seeded or otherwise.
- Final balance, production sprites, broad audio variation, and unrelated environmental polish.

### Exit evidence

- Domain tests prove the authored opening, values, target, one echo per damaged adjacent egg, no non-adjacent or recursive echoes, full damage before hatch, conveyor-ordered simultaneous hatches, success, and failure.
- UI tests prove a Cuckoo is visibly identified in the preview, echo damage is presented before belt movement, input remains locked, and audio/reduced-motion paths remain valid.
- A running-game capture at 1280×720 shows the Cuckoo reading distinctly in the pipe and on the belt, plus an ordinary strike followed by a clear secondary echo reaction.
- A short playtest asks: "Did you plan to keep useful eggs beside the Cuckoo, and was there ever a reason to hit it directly?"
