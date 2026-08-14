# Vertical slices

This file describes current implementation and learning scope. It does not override current rules.

## Active slice — Universal Day 3 hairpin

### Question

Does a mandatory ten-bay hairpin with five independent double-bowled wall spoons make Day 3 feel like meaningful factory growth while keeping route direction and target ownership understandable at a glance?

### Settled rules preserved

- The starting machine has five slots and the established Red 1+3, Blue 2+4, Pink 5 circuits.
- Cash is earned only from unused thwacks after meeting a day's target.
- A successful day still requires one producer choice, and the complete flock still visibly loads the next hopper before play resumes.
- Egg damage, effects, hatch order, conveyor advance, target completion, and presentation barriers remain resolver-owned.
- Cuckoo adjacency and conveyor motion follow route order; Plover's left retreat is an explicit screen-space effect.

### Hypothesis

Folding the conveyor into two touching five-bay runs before Day 3 should turn flock growth into a visible factory milestone without forcing the player to evaluate foundational topology as a shop upgrade. Replacing the three shared circuits with five independent double-bowled wall spoons should make each lever's two targets physically obvious, retain the starting line's maximum two direct hits per thwack, and create five future whole-utensil engine-building sockets. Literal screen-left Plover retreats may remain intuitive across both rows if route arrows clearly distinguish them from normal belt travel.

### Player-visible path

Complete Days 1 and 2 on the five-bay line. After the Day 2 producer choice, see the workshop announce a free mandatory refit. Start Day 3 and read the route as 1→5 across the top, through a tight target-free bend, then 6→10 returning left to the drop. Pull Red 1+10, Blue 2+9, Green 3+8, Purple 4+7, or Pink 5+6. Watch one wall-hinged utensil tip both of its bowls onto the two egg crowns, with the farther clink arriving just before the nearer one. Strike surviving Plovers on both rows and compare their screen-left retreat with the belt's subsequent route movement.

### In scope

- A session-owned, exactly-once mandatory refit when Day 3 starts, with explicit resolved slot-count and circuit facts and no cash cost.
- The established workshop phase between producer selection and next-day flock loading.
- Persistent five- or ten-slot day construction with resolver-authored control maps.
- Ten saved-scene bays arranged into touching upper and lower runs, joined by an untargetable right-hand bend and ending at a left-side drop.
- Five wall-hinged double-bowled spoons mapped by aligned screen columns to ten logical strike positions, with one continuous handle and two simultaneous bowls per utensil and no buckets or bend targets.
- Five independent hairpin levers and conduits replacing the starting machine's three shared circuit controls.
- Resolver-owned screen-left Plover destinations for both top and bottom rows, including no retreat from slots 1 and 10.
- Route-vector presentation for rightward, downward, and leftward conveyor movement and Plover swaps without moving rule ownership out of the resolver.
- Ten-slot damage, adjacency, movement, discard, input locking, accessibility, and presentation playback through existing owners.

### Implementation conveniences

- The refit occurs immediately on the Day 3 transition without a dedicated construction animation.
- Day 3 retains the current 20-point later-day target; hairpin-specific difficulty tuning waits for playtest evidence.
- The upper and lower conveyor casings touch as a compact double-decker machine. Five colour-and-symbol levers sit directly beneath their spoons, eggs sit directly on the belt, and each double-bowled utensil visibly contacts both egg crowns in its paired column. A presentation-only two-clink cue gives the farther bowl a slight lead without splitting the damage batch.

### Outside this slice

- Further conveyor shapes, branches, additional extensions, or later machine milestones.
- New spoon types, movable spoons, circuit rewiring, or upgraded damage.
- Producer removal, shop stock, refunds, resale, discounts, or persistence outside the run.
- Final prices, target scaling, upgrade rarity, and economy pacing.

### Exit evidence

- Domain tests prove the exact five-slot circuit and ten-slot paired-column maps, full Plover screen-left topology, damage order, adjacency, movement, and discard.
- Session tests prove Days 1–2 remain at five slots, the workshop reports the due refit, Day 3 installs it exactly once for free, and resolved refit facts precede the new day.
- UI tests prove all ten saved bays form two aligned rows, exactly five double-bowled wall spoons and five levers exist, every utensil has one continuous handle, exposes two aligned crown-contact points, keeps its stored bowls clear of the eggs, and layers only its bowls in front at impact; every hairpin bay uses the bare-belt presentation, accessibility exposes all five paired mappings, a hairpin Red press fires its one physical utensil once, and input unlocks after playback.
- A 1280×720 running-game render verifies the continuous hairpin, visible right/down/left route arrows, target-free bend, below-machine controls, left drop, and lack of overlap with the persistent HUD. A 1024×576 window check verifies the project's reference-canvas scaling path without clipping.
- A short playtest asks: “Could you predict where each egg would move, see each spoon reach both rows, and tell where a Plover would retreat on either row?”

## Completed slice — Unused-thwack payout

### Question

Does automatically converting the thwacks left when the target is reached into visible persistent cash make speed-to-target valuable enough to support a future shop economy?

### Settled rules preserved

- The target-reaching thwack resolves completely and is spent, then the day ends before another egg enters the conveyor.
- Day 1 requires 15 points, and Day 2 and each later day currently require 20.
- A successful day awards £1 per remaining thwack; a failed day awards no cash.
- Banked cash persists through producer selection, later days, and failed-day retry.
- The established success draft and failure retry rules remain unchanged.

### Hypothesis

A small, explicit payout will give efficient scoring a consequence beyond the current day's result. Ending immediately at the target, showing the remaining thwacks convert into cash, and keeping the balance visible should make the reward feel like saved capacity rather than an arbitrary stipend and create anticipation for later shops.

### Player-visible path

Start Day 1 with £0 visible. Meet the 15-point target while eggs and thwacks remain. After the scoring thwack finishes, see the day end immediately and each unused thwack banked at £1 before choosing a producer. Begin Day 2 with the balance preserved. Fail a replayable day to confirm that it awards nothing and does not erase previously banked cash.

### In scope

- Session-owned persistent whole-pound cash and the most recent successful payout.
- Resolver-owned target completion after the full scoring thwack, with no refill before its day-end facts.
- Resolver-authored remaining thwacks on day completion followed by an explicit, exactly-once cash-awarded fact from the run session.
- A permanently visible cash balance and success/failure payout summary.
- Success-only payout, no failed-day farming, and balance preservation across progression and retry.

### Implementation conveniences

- Use the pound sign and whole numbers; denominations and localisation are not implied by this prototype.
- Reuse the existing end-of-day playback barrier and result overlay without adding a coin animation.

### Outside this slice

- Shops, prices, producer removal, machine upgrades, purchases, refunds, and insufficient-funds handling.
- Bonus income, interest, debt, score conversion, streaks, or alternative cash sources.
- Manual cash-out or continuing to play after the target has been reached.
- Final payout rate or economy pacing.

### Exit evidence

- Domain and session tests prove the target-reaching thwack is spent before immediate completion, no refill follows it, success awards exactly £1 per remainder once, failure awards nothing, and cash persists into Day 2 and through retry.
- UI tests prove the balance starts at £0, updates from resolver/session facts after playback, remains accessible without colour, and success and failure overlays explain the payout.
- A 1280×720 running-game check inspects the header at £0 and a £9 deterministic success payout without title, overlay, or producer-card clipping.
- A short playtest asks: "Did the cash make you care about finishing with spare thwacks, and did the payout feel large enough to anticipate spending?"

## Completed slice — Producer draft under rising targets

### Question

Does choosing one of three legible producer additions create an understandable build decision that helps the player answer Day 2's higher target?

### Settled rules preserved

- Day 1 requires 15 points; Day 2 and each later day currently require 20 points within the same 20-thwack limit.
- All conveyor, circuit, egg, hopper, scoring-resolution, and day-ending rules remain unchanged.
- A successful day offers three distinct Chicken, Cuckoo, Plover, or Spoonbill producers and requires exactly one selection.
- Chicken producers contribute two eggs per day; Cuckoo, Plover, and Spoonbill producers contribute one.
- A failed day offers no producer and retries the same day with the same flock and shuffle.

### Hypothesis

Showing each animal, its yield, and literal previews of every egg it lays will make dilution visible enough for the player to distinguish volume from concentration. Showing the 20-point Day 2 target before commitment should give that comparison a concrete purpose, while watching the complete flock load its resolver-authored output should connect the strategic draft to the following tactical day.

### Player-visible path

Score at least 15 points on Day 1 and reach a draft showing three illustrated producer cards alongside Day 2's 20-point target. Compare each animal, its egg behaviour, and the number and appearance of the eggs it adds per day. Choose one, then watch the complete expanded flock lay its eggs into the hopper before Day 2 appears with the flock larger by one producer, the hopper larger by that producer's yield, and the score plate demanding 20. Fail a day to confirm that no draft appears and retry preserves the same target, flock, and opening shuffle.

### In scope

- Deterministic, distinct three-producer offers from the four established species.
- Resolver-owned targets of 15 for Day 1 and 20 for Day 2 and later, including target-preserving retry and explicit next-target facts.
- Session-owned day, reward, and failed phases; offered-choice validation; persistent flock growth; and a new seeded shuffle for the next numbered day.
- A durable keyboard-focusable producer-choice control showing a species portrait, literal yield-sized egg preview, toughness, points, and effect without hover text.
- A cancellable production-loading barrier that renders every resolver-authored producer and yield, animates egg waves into the hopper, supports reduced motion, and only then reveals Day 2.
- Success draft, flock/output summary, mandatory selection, Day 2 setup, and failure retry presentation.
- The next day's target shown before producer commitment and the current target rendered from resolver-authored state and events.

### Implementation conveniences

- Derive reward and day seeds deterministically from the run's initial seed and day number.
- Reuse the existing result overlay for both the success draft and failed-day retry.
- Keep the established four species equally available; rarity is not implied by this prototype.
- Hold Day 3 and later at 20 points until a broader run curve is deliberately designed.

### Outside this slice

- Producer removal, skipping, rerolls, rarity, currency, shops, and reward weighting.
- Thwack upgrades, longer belts, additional hoppers, hopper choice, and other machine upgrades.
- Run completion, further target escalation, persistence outside the current session, and loss of the overall run.
- Final balance of targets, yields, producer offers, and the growing daily pool.

### Exit evidence

- Domain and session tests prove the 15/20 target schedule, target-authored success and failure, target-preserving retry, producer yields, three distinct deterministic offers, rejection of unoffered choices, mandatory success progression, and Day 2 flock/output growth.
- UI tests prove the next target appears before selection, all three cards expose matching animal portraits and yield-sized egg previews without hover text, first-choice keyboard focus, no retry bypass on success, failure-only retry, complete production facts, cancellation safety, and the selected yield and 20-point target appearing on Day 2.
- A 1280×720 running-game check inspects the complete illustrated draft, keyboard traversal, flock-loading scene, hopper count, and Day 2 opening without clipping or stale result state.
- A short playtest asks before selection, "Which producer best prepares you for 20, and why?" After Day 2, ask, "Where did your chosen producer change a circuit decision, if anywhere?"

## Completed slice — Shuffled producer hopper

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
