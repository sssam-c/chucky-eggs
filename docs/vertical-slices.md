# Vertical slices

This file describes current implementation and learning scope. It does not override current rules.

## Active slice — Plover displacement

### Question

Does a Plover's backward swap create an intentional sacrifice, or does the extra movement make the belt harder to read?

### Settled rules preserved

- The player may thwack any occupied position on the five-slot conveyor through its corresponding piano key and spoon hammer.
- A day lasts 20 thwacks, every thwack advances all survivors once, and eggs pushed beyond slot 5 are discarded.
- The pipe previews the next three eggs.
- Chicken eggs have 3 toughness and award 3 points.
- Cuckoo eggs have 4 toughness and award 1 point.
- Every Cuckoo copies damage once per damaged egg immediately ahead of or behind it in conveyor order. Echo damage never creates another echo.
- Plover eggs have 6 toughness and award 2 points.
- A directly thwacked Plover that survives swaps with the contents immediately behind it before the standard conveyor advance. It cannot retreat from slot 1.
- Apply the complete damage batch before hatching zero-toughness eggs in conveyor order.
- The day target is 10 points.

### Hypothesis

Three-hit Chickens will provide frequent, dependable hatches and enough spare actions to explore the special eggs. A six-toughness Plover will then make players value belt position as something they can spend over several turns: sometimes preserving it by repeatedly shoving less important eggs toward the drop, while abandoning that commitment when it would destroy a valuable Chicken or useful Cuckoo pairing.

### Player-visible path

Start with a three-hit Chicken on the belt and see both a blue-speckled Cuckoo and olive-chevron Plover in the next-three preview. Hatch dependable Chickens frequently, then use the resulting action room to explore Cuckoo adjacency. When the Plover reaches a position with another egg behind it, strike it: after the crack, it chirps and hops toward the pipe while shoving the other egg forward. The whole belt then advances, leaving the Plover where it began and sending the displaced egg two effective positions toward the drop. Reach or miss 10 points in 20 thwacks, then restart the same day to test a different sacrifice.

### In scope

- Deterministic Chicken, Cuckoo, and Plover egg definitions and a repeatable authored supply.
- Adjacent per-damaged-egg Cuckoo echo damage with non-recursive batching.
- Conveyor-ordered hatch resolution after all damage in the batch.
- Direct-hit-only surviving Plover swaps after hatches and before conveyor advance.
- Distinct shell color and markings, name, value, tooltip, echo motion, echo audio, and a source-to-target adjacency trace for the Cuckoo.
- Distinct olive shell, backward chevrons, tooltip, shuffle audio, and hop-and-shove motion for the Plover.
- Shell-printed toughness, brass hatch-score seals, and integrated effect emblems on both belt eggs and the pipe preview, with a persistent legend and non-visual descriptions on the corresponding piano keys.
- A 10-point success target and current score display.
- Existing piano-key thwack, crunchy impact, conveyor, pipe, input barrier, mute, and reduced-motion presentation.

### Implementation conveniences

- Repeat a short queue pattern that normally keeps no more than one Cuckoo and one Plover on the five-slot belt; this exact frequency is a tuning convenience, not a permanent content-distribution rule.
- Give Chickens 3 toughness so three baseline hatches produce 9 points in 9 direct hits, reserving room for experimentation while requiring a special egg to meet the target.
- Give the Plover 6 toughness so the slice tests whether repeated retreat earns a meaningful commitment rather than an easy secondary hatch.
- Reuse the existing slot scene and resolver-event presenter with data-driven visual variants.

### Outside this slice

- Goose, Duck, Peacock, Ostrich, Quail, Magpie, or other additional egg types.
- The folded conveyor loop, paired-position spoons, belt expansion, upgrades, or progression.
- Random supply generation, seeded or otherwise.
- Final balance, production sprites, broad audio variation, and unrelated environmental polish.

### Exit evidence

- Domain tests prove the authored opening, values, target, three-hit Chicken hatch, Cuckoo batching, a surviving Plover's backward swap, the slot-1 boundary, hatch-before-retreat order, success, and failure.
- UI tests prove both special eggs are identified in the preview, shell seals and emblems expose points and effects before an egg enters, actionable keys carry full accessibility descriptions without hover text, each special event precedes belt movement, input remains locked, and audio/reduced-motion paths remain valid.
- A running-game capture at 1280×720 shows the Plover reading distinctly in the pipe and on the belt, then clearly hopping backward while the displaced egg is shoved forward before both follow the standard belt advance.
- A short playtest asks: "When you hit the Plover, did you understand which egg paid for its retreat—and did that change your choice?"
