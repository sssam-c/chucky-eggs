# Vertical slices

This file describes current implementation and learning scope. It does not override current rules.

## Active slice — Alternating spoon circuits

### Question

Does choosing between efficient alternating circuits and a precise final-slot rescue make conveyor position more strategically meaningful than direct egg targeting?

### Settled rules preserved

- The conveyor has five ordered slots, advances after every thwack, and discards eggs pushed beyond slot 5.
- A day lasts 20 thwacks, the pipe previews the next three eggs, and the target remains 10 points while circuit balance is evaluated.
- Red fires slots 1 and 3, Blue fires slots 2 and 4, and Pink fires slot 5; each spoon deals 1 damage.
- Every spoon in the chosen circuit fires. Empty strikes waste damage, and a circuit is available when at least one linked slot contains an egg.
- Direct circuit damage is one batch. Cuckoo echoes, conveyor-ordered hatches, surviving directly struck Plover retreats, conveyor advance, time spend, and pipe refill retain their established order.
- Current Chicken, Cuckoo, and Plover toughness, score values, effects, shell information, and authored supply remain unchanged for the first comparison.

### Hypothesis

Alternating Red and Blue positions will make players plan where damage lands across multiple eggs instead of treating the belt as five independent targets. Pink's single slot-5 spoon will then create an explicit sacrifice: give up the second point of efficient circuit damage for one precise chance to hatch or retreat the egg about to fall.

### Player-visible path

Begin with only Red available and watch both Red spoons fire even though the slot-3 strike is empty. As eggs fill the belt, alternate Red and Blue to damage separated positions, including a Cuckoo between both active spoons. When a valuable or retreating egg reaches slot 5, choose whether to spend the less efficient Pink thwack to rescue it or use Red or Blue elsewhere and let it fall. Complete the 20-thwack day, then replay the same supply with different circuit choices.

### In scope

- Deterministic circuit requests and resolver-authored target sets.
- Simultaneous direct damage to every occupied linked slot and visibly wasted empty strikes.
- Per-damaged-egg Cuckoo echoes from the pre-retreat positions.
- Conveyor-ordered retreat of every surviving directly struck Plover.
- Three durable, keyboard-focusable Red, Blue, and Pink controls with non-colour symbols and connected-spoon descriptions.
- Five colour- and symbol-matched spoons that animate together from the resolver-authored circuit event.
- Existing egg information, pipe, score, result, audio, reduced-motion, cancellation, and input-barrier behavior.

### Implementation conveniences

- Keep the current egg numbers, 20-thwack length, 10-point target, and authored queue long enough to isolate whether the control grammar is understandable; none are assumed balanced for doubled Red and Blue damage opportunities.
- Keep the existing five hammer scenes and event presenter, extending them to consume circuit-authored target lists.

### Outside this slice

- Permanent balance changes to toughness, points, target, day length, or supply distribution.
- Changing circuit assignments during a day, upgrades, progression, additional circuits, or player-authored wiring.
- New egg types, folded conveyors, production art, and unrelated polish.

### Exit evidence

- Domain tests prove circuit availability, fixed target sets, wasted empty strikes, simultaneous paired damage, double Cuckoo echoes between a pair, Pink slot-5 damage, Plover rescue, ordering, success, and failure.
- UI tests prove there are exactly three controls and five spoons, each circuit identifies its connected positions without colour alone, all connected spoons animate once, input remains locked, and restart cancels playback safely.
- A running-game check at 1280×720 shows Red firing slots 1 and 3 with one empty strike, Blue firing slots 2 and 4, and Pink clearly reading as the precise slot-5 circuit.
- A short playtest asks: "Did you choose Pink because the final egg was worth giving up a second spoon strike—and could you predict what Red or Blue would hit?"
