# Vertical slices

This file describes current implementation and learning scope. It does not override current rules.

## Current foundational slice — Five-tap Hunger rounds

### Question

Does preparing and sustaining a break streak across five tactile taps create expressive setup-versus-payoff routes, rather than collapsing into one automatic spoon sequence?

### Status

Accepted as the authoritative game baseline on 2026-08-19. `res://src/ui/hopper_tap_main.tscn` is the default project scene. This supersedes the conveyor, Belt Condition, multi-day flock, shop, and progression slices as current scope; their history remains in `docs/decision-log.md`, `docs/playtest-log.md`, and Git history.

### End-to-end player path

- Begin with five occupied cups, five directly clickable coloured spoons, a visible three-egg hopper preview, five available taps, and Grandma visibly owning 10 Hunger and her announced next increase.
- Choose one occupied spoon. Resolve direct damage, adjacent Cuckoo copies, left-to-right hatches, multiplied Yolk pooling and delivery, surviving Plover movement, then visible hopper-to-cup refills as one deterministic cascade.
- Every broken egg advances the current streak and multiplies its printed Yolk. A tap with no break ends the streak.
- Spend one tap only after the complete cascade. Free reactions never spend another tap.
- If Hunger reaches zero, satisfy Grandma immediately and skip her response.
- Otherwise, after the fifth paid tap, add Grandma's announced Hunger, increase her next response, refresh all five taps, and continue.
- Fail if every egg is exhausted above zero Hunger. Restart replays the authored opening.

### Settled baseline

- Five fixed cups and one spoon per cup: Red, Blue, Pink, Red, Blue.
- Exact visible toughness, Yolk, positional effects, current Hunger, taps, and the next three hopper eggs.
- Chicken is plain, Sparrow is quick, Cuckoo copies adjacent direct damage, Spoonbill takes two direct damage from Pink, and a surviving directly tapped Plover swaps left.
- Opened cups refill only after the cascade and receive hopper eggs in hatch order.
- Five taps per phase, 10 starting Hunger, a first response of +1, and +1 growth after every response.
- A phase-local break streak that increases per egg, multiplies that egg's Yolk, resets on a zero-break tap, and resets before Grandma's response.
- Resolver-authored Yolk pools accumulate above the eggs and travel to Grandma before Hunger changes visibly.
- One request-to-resolver path and resolver-authored event order; presentation owns only playback and its cancellation barrier.

### Open hypotheses

- Position, spoon colour, adjacency, and previewed refill order will create several plausible tap choices during one authored game.
- Players will sometimes delay immediate Yolk to construct a stronger later cascade.
- Players will distribute setup damage across positions, then choose an ordered run of breaks that keeps the streak alive and places valuable eggs late.
- “Double Yolker!” and higher centre-stage callouts will make the multiplied payoff feel legible and celebratory rather than like hidden score arithmetic.
- Renewable five-tap phases will feel like tactical rounds, while Grandma's escalating response provides pressure without becoming an arbitrary countdown.
- Large eggs, clickable spoons, cups, hopper travel, and Grandma's sidebar will make the complete causal chain understandable without explanation.
- The current exact information can support competence while later egg-specific uncertainty supplies lottery sensation without obscuring every plan.

### Implementation conveniences, not permanent design commitments

- The current twelve-egg order is authored to expose reliable Cuckoo, Pink Spoonbill, Plover, refill, and Hunger-phase interactions.
- Existing placeholder egg, spoon, sound, and Grandma art shortens the learning loop; it is not final production art.
- The current numeric tuning is authoritative for this build but remains a balance lever after human playtest evidence.
- The former conveyor implementation and its tests remain in the repository as historical reference while this replacement stabilises.

### Explicitly deferred

- Defensive Hunger effects, hidden toughness across the whole roster, manual early phase ending, random daily order, additional egg identities, and multi-rule eggs.
- Flocks, rewards, cash, shops, multiple days, the bin, recycling, conveyor movement, paired circuits, and permanent progression.
- Production character art, authored Grandma dialogue, and final sound or animation polish.

### Exit evidence

- Domain specs prove one-spoon targeting, fixed colours, direct and copied damage order, per-egg streak multiplication, zero-break and phase resets, pooled Yolk reducing Hunger, post-cascade refill, one paid tap per request, victory before Grandma's response, explicit fifth-tap phase order, escalating Hunger, tap refresh, exhaustion failure, and restart.
- UI specs prove five spoon targets, large eggs in cups, exact visible facts, three previews, five tap indicators, centre-stage streak wording and Yolk pooling, delivery to Grandma-owned Hunger, input locking, ordered playback, exact hopper destinations, cancellation, and restart.
- Muted running-game checks at 1280×720 and 1024×576 verify cup seating, spoon hit targets, hopper travel, Grandma's sidebar, Hunger-phase feedback, and readable composition.
- Play the authored opening without explanation. Record whether the player finds at least two plausible moves on several taps, deliberately makes a setup tap, changes a decision because of the hopper preview, anticipates the fifth-tap response, and can explain a resulting cascade.

## Historical slices

The former conveyor, Belt Condition, direct-thwack movement, Grandma-effect, flock, reward, and shop slices are no longer current implementation scope. Their accepted and superseded decisions remain append-only in `docs/decision-log.md`; observed evidence remains in `docs/playtest-log.md`; their last complete implementation is preserved in Git history and in the retained historical code paths.
