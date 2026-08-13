# Vertical slices

This file describes current implementation and learning scope. It does not override current rules.

## Active slice — Shuffled producer hopper

### Question

Does a finite shuffled pool of producer-laid eggs preserve short-term tactical legibility while making flock composition a meaningful foundation for future builds?

### Settled rules preserved

- The conveyor, circuits, egg behavior, damage ordering, 10-point target, and 20-thwack maximum remain unchanged.
- The starting flock has five two-yield Chicken producers, three one-yield Cuckoo producers, and two one-yield Plover producers, creating 15 eggs per day.
- The daily pool is shuffled once, previews its next three eggs, never reshuffles, and ends the day early when both hopper and conveyor are empty.
- Plovers retain 6 toughness and retreat behavior but now award 4 points.

### Hypothesis

A finite randomized pool will make each preview tactically useful without turning the whole day into an authored spatial puzzle. Showing only the next three eggs preserves local planning, while the known producer roster gives future additions and removals predictable effects on build concentration.

### Player-visible path

Begin with one shuffled starting-flock egg on the conveyor and three more visible in the pipe. Choose circuits using the familiar preview and conveyor information while the hopper supplies at most one fresh egg per thwack. Continue until the twentieth thwack or until the finite pool and conveyor are empty, then restart to replay the same seed while the shuffle and exhaustion rules are verified.

### In scope

- A persistent-domain representation of the 10 starting producers and their daily yields.
- Seeded once-per-day shuffling, a finite hopper, a three-egg preview, and resolver-owned exhaustion ending.
- Four-point Plover state, hatch events, shell information, and score payoff.
- Deterministic setup seams that keep established Cuckoo, Plover, and Spoonbill interaction tests independent from the production opening pool.

### Implementation conveniences

- Use one fixed seed for the standalone restartable prototype so a reported sequence can be replayed exactly.
- Preserve the existing `pipe` presentation field as the visible view of the first three hopper eggs.

### Outside this slice

- Adding a producer after each day, choosing between producer rewards, removal, persistence across multiple days, and campaign failure.
- Thwack upgrades, longer belts, additional hoppers, hopper choice, and other machine upgrades.
- Adding Spoonbill producers to the starting flock or implementing later reward pools and rarity.
- Final tuning of producer yields, target score, flock composition, or Plover value.

### Exit evidence

- Domain tests prove starting producer counts and yields, the exact 15-egg composition, finite preview behavior, early exhaustion, the 20-thwack cap, and the Plover's 4-point value.
- Core and session tests prove equal seeds reproduce equal shuffles without changing pool contents and restart through the canonical request pathway.
- UI tests prove shuffled starting-flock eggs render, the remaining hopper count updates, Plover information shows 4 points, exhaustion shows the result, and deterministic injected sessions preserve established resolver-event playback.
- A running-game check at 1280×720 follows the preview until it shrinks, confirms no replacement eggs appear, and observes either exhaustion or the thwack cap ending the day.
- A short playtest asks: "Did the shuffled preview give enough information to make plans, and did knowing the flock composition make the order feel strategically fair?"

## Completed slice — Spoonbill spark weakness

### Question

Does preparing a Spoonbill for Pink in slot 5 make Pink a proactive strategic choice rather than only an emergency rescue?

### Settled rules preserved

- Red fires slots 1 and 3, Blue fires slots 2 and 4, and Pink fires slot 5; every thwack still advances the conveyor and spends one of the day's 20 actions.
- A Spoonbill has 5 toughness, awards 4 points, and takes 2 direct damage from Pink. Other direct and echo damage against it remains normal.
- A Cuckoo adjacent to a Pink-struck Spoonbill copies the full resolver-authored 2 damage; the complete damage batch still precedes conveyor-ordered hatches.
- The 10-point target, existing egg rules, hatch payoff, input barrier, and cancellation behavior remain unchanged.

### Hypothesis

The Spoonbill's visible spark weakness will turn slot 5 into a planned destination. Because Pink's two concentrated damage equals the total output of Red or Blue but cannot be distributed, the best circuit remains situational. Five toughness lets a player deliberately skip one earlier opportunity and spend it on another egg before cashing the Spoonbill out with Pink.

### Player-visible path

See a 5-toughness, 4-point Spoonbill with a four-point spark in the initial pipe preview. Damage it on selected Red and Blue positions while allowing one circuit opportunity to serve another egg. When it reaches slot 5 beside a Cuckoo in slot 4, activate Pink: the Spoonbill takes 2 direct damage, the Cuckoo copies 2, and both can burst and score in conveyor order. Replay and choose whether the high-value pairing justified foregoing a distributed circuit elsewhere.

### In scope

- Deterministic Spoonbill stats, authored supply placement, Pink double damage, and full adjacent Cuckoo echo.
- Resolver-authored `damage_amount` on every damage fact.
- A distinct Spoonbill shell palette, four-point spark emblem, readable preview, accessible description, and stronger feedback for a 2-damage strike.
- Existing hatch burst and score travel using the Spoonbill's resolved 4-point value.

### Implementation conveniences

- Place Spoonbill in the initial three-egg preview and follow it with a Cuckoo so the first day exposes the intended slot-4/slot-5 experiment.
- Reuse the current egg renderer, event presenter, circuit symbols, and deterministic authored supply.

### Outside this slice

- Further circuit weaknesses, resistances, random supply, balance changes to other eggs, target-score tuning, progression, and upgrades.
- Special Spoonbill hatch behavior beyond its value and Pink weakness.

### Exit evidence

- Domain tests prove Spoonbill stats, Pink's 2 direct damage, normal damage from other sources, full 2-damage Cuckoo echo, batch order, hatch value, and day completion.
- UI tests prove the initial preview exposes the spark weakness without colour alone and the Pink payoff presents the resolver-authored results once.
- A running-game check at 1280×720 follows the first Spoonbill from preview to a Pink strike in slot 5 beside a Cuckoo.
- A short playtest asks: "Did seeing the Spoonbill change which circuits you chose before it reached Pink—and was the slot-5 payoff worth what you gave up?"

## Completed slice — Hatch payoff

### Question

Does carrying each resolved point visibly from an exploding egg into the score display make hatching feel like the turn's payoff?

### Settled rules preserved

- Egg toughness, point values, hatch order, circuit damage, conveyor movement, and the 10-point target remain unchanged.
- The resolver-authored `egg_hatched` event remains the sole source of the awarded points and resulting score.
- Input stays locked until the complete ordered event sequence has been presented, and restart cancels presentation without committing stale visuals.
- Reduced motion still communicates both the hatch and the score change without requiring travel animation.

### Hypothesis

A brief compression and shell burst will make the hatch itself feel more forceful. Holding the old score until a large `+N` token reaches the score plate, then landing the new total with a distinct chime and counter punch, will connect the egg's printed value to the reward more clearly than changing the counter before the egg disappears.

### Player-visible path

Damage the opening Chicken until it reaches zero toughness. The egg compresses, bursts into shell and yolk debris, and releases its resolved `+3`. The token arcs from the emptied cup to the score plate; only on arrival does the counter change from 0 to 3 and punch forward with a separate reward sound. The conveyor then continues through the resolver-authored events. Replay with a 1-point Cuckoo or 2-point Plover to confirm the payoff reflects the event rather than the egg type's presentation.

### In scope

- One reusable presentation overlay for deterministic shell fragments, yolk sparks, an expanding impact ring, and a non-colour `+N` token.
- Delayed score-label commitment until the token reaches the existing score plate.
- A distinct short score-arrival sound layered after the existing hatch crack.
- Exactly-once hatch playback, reduced-motion behavior, mute behavior, and restart cancellation.

### Implementation conveniences

- Use authored deterministic fragment directions rather than a particle simulation or physics bodies.
- Reuse the existing egg artwork, score label, presenter barrier, procedural audio system, and resolver event fields.

### Outside this slice

- Scoring balance, combo multipliers, streaks, screen shake, controller rumble, camera work, new egg art, and egg-specific hatch creatures.
- Changes to damage, hatch ordering, point values, target score, or the end-of-day result.

### Exit evidence

- UI tests prove hatch presentation receives the resolver-authored point value, the old score remains visible when the burst starts, the counter commits exactly once before `egg_hatched` presentation completes, reduced motion commits immediately, and restart clears an interrupted payoff.
- The reusable overlay exposes the current `+N` text and returns to an inactive clean state after completion or cancellation.
- A running-game check at 1280×720 inspects the opening Chicken at compression, full burst, point travel, and score arrival.
- A short playtest asks: "When the egg burst, did the points feel as though they came out of that egg—and did the score landing feel worth watching?"

## Completed slice — Alternating spoon circuits

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
- Three durable, keyboard-focusable Red, Blue, and Pink controls with non-colour symbols and connected-spoon descriptions. Pink uses a four-point spark as its non-colour identifier.
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
