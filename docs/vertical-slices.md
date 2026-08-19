# Vertical slices

This file describes current implementation and learning scope. It does not override current rules.

## Current foundational slice — Five-tap Hunger rounds

### Question

Does preparing several eggs for one multi-break tap create expressive setup-versus-payoff routes, rather than collapsing into one automatic spoon sequence?

### Status

Accepted as the authoritative game baseline on 2026-08-19. `res://src/ui/hopper_tap_main.tscn` is the default project scene. This supersedes the conveyor, Belt Condition, multi-day flock, shop, and progression slices as current scope; their history remains in `docs/decision-log.md`, `docs/playtest-log.md`, and Git history.

### End-to-end player path

- Begin with five occupied cups, five neutral spoons, five large colour-and-shape buttons, a visible three-egg hopper chute, and Grandma visibly owning five available taps, 10 Hunger, and her announced next increase.
- Choose one occupied cup's button. Resolve its spoon's direct damage, adjacent Cuckoo copies, left-to-right hatches, multiplied Yolk calculation and delivery, surviving Plover movement, then visible hopper-to-cup refills as one deterministic cascade.
- Every egg broken by one tap joins that tap's combo. Add their printed Yolk and multiply once by the number broken; separate taps never combine.
- Spend one tap only after the complete cascade. Free reactions never spend another tap.
- If Hunger reaches zero, satisfy Grandma immediately and skip her response.
- Otherwise, after the fifth paid tap, add Grandma's announced Hunger, increase her next response, refresh all five taps, and continue.
- Fail if every egg is exhausted above zero Hunger. Restart replays the authored opening.

### Settled baseline

- Five fixed cups with one neutral spoon and one button each: Red Diamond, Blue Circle, Pink Star, Green Triangle, and Gold Square.
- Exact visible toughness, Yolk, positional effects, current Hunger, taps, and the next three hopper eggs.
- Chicken is plain, Sparrow is quick, Cuckoo copies adjacent direct damage, Spoonbill takes two direct damage from Pink, and a surviving directly tapped Plover swaps left.
- Opened cups refill only after the cascade and receive hopper eggs in hatch order.
- Five taps per phase, 10 starting Hunger, a first response of +1, and +1 growth after every response.
- A tap-local break combo that multiplies the combined printed Yolk by the number of eggs opened in that tap's complete cascade.
- Grandma's sidebar owns persistent taps, Hunger, next response, and phase feedback. Every scoring tap briefly creates one numbered liquid Yolk ball above the eggs; hatch contributions merge into it, a multi-break result surges through its callout and multiplier there, and the same ball travels directly to Grandma before Hunger changes. There is no sidebar score card, persistent streak state, or permanent centre-stage score object.
- One request-to-resolver path and resolver-authored event order; presentation owns only playback and its cancellation barrier.

### Open hypotheses

- Position, spoon colour, adjacency, and previewed refill order will create several plausible tap choices during one authored game.
- Players will sometimes delay immediate Yolk to construct a stronger later cascade.
- Players will distribute setup damage across positions, then choose one strike that converts several prepared eggs into a multiplied payoff.
- Same-tap “Double Yolker!” and higher callouts, attached to a shared liquid Yolk ball in the playfield, will make the multiplied payoff feel causally legible and exceptional rather than like remote score bookkeeping.
- Renewable five-tap phases will feel like tactical rounds, while Grandma's escalating response provides pressure without becoming an arbitrary countdown.
- Large eggs, shape-coded buttons, neutral spoons, cups, hopper travel, and Grandma's consolidated sidebar will make the complete causal chain understandable without explanation.
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

- Domain specs prove one-spoon targeting, fixed colours, direct and copied damage order, flat same-tap combo multiplication, no cross-tap state, combined Yolk reducing Hunger, post-cascade refill, one paid tap per request, victory before Grandma's response, explicit fifth-tap phase order, escalating Hunger, tap refresh, exhaustion failure, and restart.
- UI specs prove five large shape-coded button targets, neutral spoons, large eggs in cups, exact visible facts, three previews, five tap indicators, no miss ceremony, one transient numbered Yolk ball, hatch-to-ball merges, one same-tap multiplier surge, direct delivery to Grandma, explicit subtraction, input locking, ordered playback, exact hopper destinations, cancellation, and restart.
- Muted running-game checks at 1280×720 and 1024×576 verify cup seating, button hit targets, neutral spoon feedback, hopper travel, central Yolk-ball legibility, same-tap combo emphasis, direct single-break delivery, Grandma's subtraction, Hunger-phase feedback, and readable warm-workshop composition.
- Play the authored opening without explanation. Record whether the player finds at least two plausible moves on several taps, deliberately makes a setup tap, changes a decision because of the hopper preview, anticipates the fifth-tap response, and can explain a resulting cascade.

## Historical slices

The former conveyor, Belt Condition, direct-thwack movement, Grandma-effect, flock, reward, and shop slices are no longer current implementation scope. Their accepted and superseded decisions remain append-only in `docs/decision-log.md`; observed evidence remains in `docs/playtest-log.md`; their last complete implementation is preserved in Git history and in the retained historical code paths.
