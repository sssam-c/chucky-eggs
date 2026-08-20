# Vertical slices

This file describes current implementation and learning scope. It does not override current rules.

## Current slice — Seeded two-round flock choice

### Question

Does a seeded opening followed by one flock choice and a harder second round make players adapt, feel ownership of the flock, and want to continue the run?

### Status

Accepted for prototype implementation on 2026-08-20 after informal play established that the foundational five-tap round contains real texture and meaningful decisions. This slice extends that baseline without adding new egg identities or an economy.

### End-to-end player path

- Begin Round 1 with 10 Hunger, five taps, a visible run seed, and the fixed twelve-egg flock shuffled deterministically into the cups and hopper.
- Play the complete accepted five-tap Hunger round with exact egg facts and a three-egg hopper preview.
- On success, choose one of three different, seed-derived current-species eggs.
- Add the chosen egg to the flock, show that Round 2 begins with 12 Hunger, and deterministically shuffle the thirteen eggs from the same run seed.
- Play Round 2 under otherwise unchanged rules. Success completes the run; failure offers a same-seed retry.
- Restarting the run preserves its seed. Starting a new seed changes the Round 1 order and its deterministic downstream offer and Round 2 order.

### Settled baseline

- All five-cup damage, Cuckoo, Plover, Spoonbill, hatch, combo, refill, five-tap phase, Hunger escalation, success-precedence, and presentation rules from the foundational slice.
- The Round 1 flock multiset remains three Chickens, three Cuckoos, two Sparrows, two Plovers, and two Spoonbills.
- One visible run seed deterministically owns Round 1 order, three unique reward offers, and Round 2 order.
- Winning Round 1 grants exactly one current-species egg, increasing the flock from twelve to thirteen.
- Round 1 begins at 10 Hunger; Round 2 provisionally begins at 12. Both retain five taps, a first response of +1, and +1 response growth.
- Retry preserves the seed and selected reward. New seed begins a different deterministic run.

### Open hypotheses

- Seeded orders will create replay variety without producing obviously trivial, automatic, or hostile openings.
- Shared white shells, species silhouettes layered behind toughness, contained Yolk values, and circuit colour reserved for colour-gated marks will make eggs quicker to parse without implying nonexistent colour rules.
- Players will adapt their early taps to the visible board and hopper rather than treating each seed as cosmetic.
- Reward choices will be situational rather than collapsing into one universally preferred species.
- The chosen thirteenth egg will visibly change at least one Round 2 plan.
- Twelve starting Hunger will make Round 2 harder without making a poor early phase feel unrecoverable.
- Completing Round 2 will leave players wanting another reward and round.

### Implementation conveniences, not permanent design commitments

- The initial prototype can advance to a new deterministic seed rather than requiring a typed seed browser or platform randomness.
- White placeholder shells and code-native bird silhouettes establish the current information syntax; they are not final egg or character art.
- Reward offers may use all five current identities with uniform frequency while their strategic value is observed.
- The +2 Round 2 Hunger increase is a first tuning probe, not a general difficulty formula.
- Generated orders may initially be drawn from a validated seed set if unrestricted shuffles produce poor openings.

### Explicitly deferred

- New egg identities, rarity, random egg stats, hidden quality, shops, cash, removals, upgrades, and permanent unlocks.
- A third round, endless play, save persistence, daily challenges, online seed sharing, and a full seed-entry interface.
- Changes to taps per phase, Grandma's escalation curve, combo arithmetic, egg tuning, or presentation timing.

### Exit evidence

- Game-layer specs prove equal seeds reproduce complete orders and offers, different seeds can vary them, reward selection is legal only after Round 1 success, exactly one offered egg is added, Round 2 begins at 12 Hunger with thirteen eggs, and same-seed retry preserves the chosen flock.
- UI specs prove the seed and round are visible, reward input is exclusive and exactly once, spoons remain unavailable during the transition, Round 2 difficulty is announced, and retry/new-seed actions preserve or change the seed as labelled.
- Muted running-game checks at 1280×720 and 1024×576 verify reward-card layout, keyboard focus, seed/round readability, the Round 2 transition, and the existing tap-presentation barrier.
- Play at least three seeds. Record whether the opening changes a plan, whether two reward choices appear plausible, how the chosen egg changes Round 2, whether 12 Hunger creates productive pressure, and whether the player wants a third round.

## Foundational baseline — Five-tap Hunger rounds

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
- Grandma's sidebar owns persistent taps, Hunger, next response, and phase feedback. Every hatch compresses, fractures, and bursts into shell fragments before its value emerges. Every scoring tap briefly creates one numbered liquid Yolk ball above the eggs; contribution and total sizes scale steeply with exact Yolk value, hatch contributions merge into it, a multi-break result grows through its callout and multiplier there, and the same ball travels directly to Grandma before Hunger changes. There is no sidebar score card, persistent streak state, or permanent centre-stage score object.
- One request-to-resolver path and resolver-authored event order; presentation owns only playback and its cancellation barrier.

### Open hypotheses

- Position, spoon colour, adjacency, and previewed refill order will create several plausible tap choices during one authored game.
- Players will sometimes delay immediate Yolk to construct a stronger later cascade.
- Players will distribute setup damage across positions, then choose one strike that converts several prepared eggs into a multiplied payoff.
- Same-tap “Double Yolker!” and higher callouts, attached to a shared liquid Yolk ball in the playfield, will make the multiplied payoff feel causally legible and exceptional rather than like remote score bookkeeping.
- Renewable five-tap phases will feel like tactical rounds, while Grandma's escalating response provides pressure without becoming an arbitrary countdown.
- Large eggs, staged shell rupture, value-scaled Yolk, shape-coded buttons, neutral spoons, cups, hopper travel, and Grandma's consolidated sidebar will make the complete causal chain understandable without explanation.
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
