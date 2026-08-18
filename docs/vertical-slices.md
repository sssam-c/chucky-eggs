# Vertical slices

This file describes current implementation and learning scope. It does not override current rules.

## Branch experiment — Hopper-fed individual spoon combos

### Question

Does directly tapping one of five stationary eggs feel more tactile and strategically expressive when opening an egg routes the next visible hopper egg into that same coloured spoon position?

### Status

Branch-only prototype on `codex/hopper-tap-combos`. This is a design hypothesis and does not supersede the canonical conveyor rules unless a later playtest and deliberate decision accept it.

### End-to-end player path

- Begin with five occupied bays, five individually operated coloured spoons, a visible three-egg hopper preview, a small pool of spoon pulls, and Grandma's Appetite.
- Pull one lever to strike only the egg in its matching bay. Exact remaining toughness and Yolk stay visible.
- Resolve direct damage, Cuckoo echoes, hatches, and any positional response as one deterministic cascade.
- Keep every vacancy empty until that cascade finishes, then route hopper eggs into vacancies in hatch order; simultaneous hatches use bay order from left to right.
- Free reactions never spend another pull. After refill, choose the next individual spoon until Appetite is met, pulls run out, or no eggs remain.

### Hypotheses

- One lever per egg will make every input feel direct and let the player invest repeated taps deliberately.
- A visible hopper turns opening an egg into positional routing: the player chooses which spoon colour and neighbours the next egg inherits.
- Fixed spoon colours, Cuckoo adjacency, Spoonbill's Pink weakness, and Plover's surviving-hit swap provide enough initial combontronics without movement instructions or a conveyor.
- Short, resolver-authored cascades can feel powerful without becoming an incremental or idle loop.

### Settled rules preserved inside the experiment

- Five simultaneous egg positions, exact visible toughness, Yolk scoring, Grandma's Appetite, deterministic resolution, and a three-egg hopper preview.
- Chicken remains plain, Cuckoo copies damage from an adjacent directly struck egg, Spoonbill takes two direct damage from Pink, and a surviving directly struck Plover swaps left.
- Rule ownership remains in the domain; UI and animation only submit one spoon request and present its ordered events.

### Implementation conveniences, not rules

- The first build uses an authored egg order and fixed spoon colours to expose a reliable opening combination.
- Existing placeholder egg, lever, spoon, sound, and Appetite assets may be reused to shorten the learning loop.
- Initial Appetite and pull counts are tuning controls rather than accepted balance.

### Explicitly deferred

- Flock rewards, cash, removal, multiple days, random shuffles, the bin, recycling, automatic conveyor movement, paired circuits, movement eggs, production art, and permanent progression.
- New egg identities or multi-rule eggs beyond the existing compact interaction vocabulary.

### Exit evidence

- Domain specs prove one-spoon targeting, fixed spoon colour, direct and echo order, post-cascade vacancy refill, deterministic multi-vacancy routing, one paid pull per request, and end conditions.
- UI specs prove five individually operable levers, exact egg facts, three preview eggs, input locking, ordered damage/hatch/refill presentation, and restart.
- A muted running-game check at 1280×720 and 1024×576 verifies contact alignment, fast tactile feedback, readable colour-plus-symbol identity, and no stale input after cancellation.
- Play the authored opening without explanation and record whether the player notices that opening Pink's first egg deliberately routes the incoming Spoonbill under Pink.

## Active validation slice — Standard-species rewards and visible flock thinning

### Question

Do three free Standard producer choices create an interesting build direction under 12 Belt Condition, and does removing an exact producer for £3 provide enough control over compulsory flock growth?

### Status

The deterministic and player-visible path now opens a dedicated bird-offer screen after a successful day, presents three seeded candidates from eleven fixed Standard identities, and requires exactly one selection. Eight retain their species framing; Oily, Nostalgic, and Gloopy are deliberately plain prototype identities until their movement mechanics feel worthwhile. That selection closes the offer and opens a separate shop where every owned producer is its own £3 removal control in a scrollable flock overview, but only one can be removed during that visit. Quality tiers, rarity presentation, recruitment purchases, pairing, merge queues, egg upgrades, factory upgrades, Kiwi, and Deceptively Filling are removed from the current game. Failed attempts still retry without between-day progression.

### Settled rules preserved

- Every bird lays exactly one egg per day; the starting pool is three Chicken, two Cuckoo, and three Sparrow eggs.
- The belt starts each day with 12 Condition. Every committed thwack costs exactly 1 after its movement queue, even when Jam prevents all movement; success takes precedence if Condition reaches 0 during the target-reaching thwack. A successful day pays a fixed £3.
- Day 1 requires 10 points and each later day requires 9.
- Red strikes slots 1+3, Blue strikes 2+4, and Pink strikes slot 5. All three remain available during an unlocked day, including when their complete circuit is empty. Pink still deals 2 direct damage to Spoonbills.
- Cuckoo echoes, Plover retreat, simultaneous damage, hatch order, cash, retries, success-only shop access, and one request-to-resolver pathway remain unchanged.
- Every successful day opens a dedicated three-bird offer, exactly one must be chosen before the separate shop opens, and the only current shop action is removing at most one selected bird for £3.
- Daily randomness remains seeded and equal retries reproduce initial and recycled shuffles and hidden outcomes.

### Hypothesis

One stable track should let the player read circuits and egg movement immediately. Opening with up to five eggs makes the first paired-circuit choice meaningful. Moving an unhatched egg into a visible bin changes its future order without deleting its damage; immediate circulation when the hopper empties keeps that consequence relevant without requiring several low-agency clearing actions.

Keeping every circuit active should make conveyor position an intentional resource instead of letting occupancy silently choose the legal actions. An empty impact may improve the next alignment, but the resulting belt movement still spends 1 Condition.

Three one-hit Sparrows should make the complete hatch-and-score payoff legible during the opening pulls. Their 5% Double Yolker chance should introduce jackpots through the simplest possible shell, while their positions beside Cuckoos can teach that damaging one egg may also create an echo elsewhere. An eight-egg pool fills the five-slot opening and keeps three eggs in the pipe, so its increased scoring supply must compete with Belt Condition and positional congestion.

At a 10-point target, candidate routes include all three Chickens plus one Sparrow; two Chickens, both Cuckoos, and two Sparrows; or two Chickens, one Cuckoo, and all three Sparrows. These arithmetic routes are hypotheses rather than evidence that each route is equally achievable across shuffled positions.

Fixed Standard facts should isolate whether each current identity offers a useful tactical promise and whether compulsory flock growth creates interesting composition choices. Intrinsic Double Yolker chances retain a small jackpot without adding an upgrade axis.

### Implemented prototype scope

- One five-slot conveyor and the same three circuits on every day; the Day 3 hairpin and refit are removed.
- Every lever is usable throughout an unlocked day. A spoon over an empty bay still fires and the conveyor still advances, spending 1 Belt Condition without dealing damage.
- Visible hopper and bin counts at their physical containers. Clicking the hopper opens a non-positional egg collection without revealing queue order beyond the three pipe previews; clicking the bin opens every stored egg with retained toughness and states that return order will shuffle.
- Resolver events for an egg entering the bin, the complete bin reshuffling into an empty hopper, and the next egg entering slot 1.
- Binned eggs retain remaining toughness, score, Double Yolker result, and every other egg fact.
- The injected shuffler owns every recycle order, preserving deterministic retries.
- Existing hopper eggs feed normally. Whenever the hopper is empty, the bin reshuffles immediately and may rejoin eggs still travelling on the conveyor; at most one egg enters slot 1 per thwack.
- A dedicated reward screen shows three cards with species, fixed shell toughness, Yolk, effect, intrinsic Double Yolker chance, and one daily egg before selection. It contains no quality, rarity, shop, or removal controls.
- After selection, a separate shop screen shows the complete flock as individual species cards with fixed egg facts and £3 removal actions. After one removal, all remaining cards visibly report that the nightly removal was used. The last bird and unaffordable removals are also unavailable.
- Existing production loading shows the fixed egg laid by each bird.
- Every species uses one flat temporary colour across a generic egg and a simple bird silhouette throughout the belt, pipe, loading, reward, and flock-overview views. Species names sit outside the art. Occupied eggs use a magnifying-glass cursor to advertise inspection. A wrapped hover card top-aligns beside its egg, flips sides at the viewport edge, and presents the egg's name, prominent points and Double Yolker facts, and only its applicable effect sections. Generated raster experiments are excluded from the running game and exports; final production assets are deferred to an artist.
- The default flock contains three Chickens, two Cuckoos, and three Sparrows, with 12 starting Belt Condition, a 10-point Day 1 target, and a 9-point later target.
- One domain-owned Belt Condition value replaces individual spoon Integrity. Each committed thwack spends exactly 1 after its complete movement queue; Shockwave strikes add no instructions or cost, and reaching 0 fails unless the completed thwack already succeeded.
- A full-height information rail to the right presents the unchanged score and target as Grandma's appetite alongside settings, while one labelled Belt Condition bar sits directly on the conveyor housing. Awarded points fill a yolk meter proportionally, overflow remains numeric, reduced motion stops her placeholder idle animation, and the reusable scene reserves status and left-expanding dialogue regions without yet authoring dialogue behavior.
- The workshop spends its remaining area on the existing machine: a bottom-anchored hopper lift shares a deck line with the larger clickable bin, carries its clickable count on that loading deck, raises three preview eggs toward a short conveyor-height exit, and then pushes the top egg sideways into a lowered five-lane playfield with slightly larger eggs and taller stored spoons. Moving eggs show a readable backward lean followed by a damped counter-wobble and always settle upright. The conveyor curves once after slot five into the bin, the same three circuit controls occupy a compact bottom fascia, and no decorative yolk pipe or additional readout implies new functionality.

### Balancing constraints

- Recycling removes permanent belt loss without adding dead conveyor-clearing turns.
- Empty strikes create a positioning option, but their belt movement still costs 1 Condition and can accelerate eggs toward the bin without scoring.
- Five eggs fill the machine's natural opening capacity. The eight-egg daily pool carries more total score and keeps three eggs in the initial hopper.
- The starting flock contains 14 total base points and 20 total base toughness. Day 1's 10-point target leaves four points of composition slack.
- Sparrows provide one point per direct damage before positional waste, and a directly struck Sparrow can also cause adjacent Cuckoo echoes. Guard against their combination making the quickest route obvious across most seeds.
- A small flock cycles more often, but can still fail by hatching every available egg below the target.
- The fixed £3 success payout keeps the economy independent from current Belt Condition tuning. Guard against a deterministic retry that cannot reach the shop.

### Explicitly deferred

- Further target, Belt Condition, toughness, score, species weighting, and £3 removal-price tuning after playtest evidence.
- Bin capacity, player-controlled rerolls, selective retrieval, damage healing, or bin upgrades.
- Quality tiers, rarity, pairing, merging, egg upgrades, hybrid recipes, inherited effects, and authored hybrid art.
- Kiwi and slow-release Yolk. Any return needs a new slice that avoids turning future Belt Condition into low-agency Satisfaction and defines honest value at egg exhaustion.
- Paid recruitment, factory upgrades, a campaign map, reward rerolls, discounts, selling, elite conditions, and production art.
- A replacement for the removed Day 3 factory milestone or any positional spoon-upgrade ladder.

### Exit evidence

- Domain tests prove fixed identity facts, intrinsic Double Yolker odds, damage-preserving bin transfer, exact hopper-empty recycling, left-to-right movement programs, Jam stacking and expiry, one Belt Condition loss per thwack, indirect-hit exclusion, success precedence at zero, resolver event order, deterministic reshuffle, and slot-1 refill.
- Session tests prove the default eight-egg flock, 12 starting Belt Condition, fixed £3 payout, 10/9 targets, deterministic Standard-only three-choice offers drawn from eleven eligible identities, exact free selection, one £3 targeted removal per shop visit, and deterministic failure/retry behavior.
- UI tests prove reward and flock cards present species without quality or rarity controls, selecting a reward opens the separate shop, the whole flock appears there as individual removal controls, all removals disable after one selected bird disappears for £3, dynamic controls do not accumulate stale registrations, and cancellation/input-lock contracts still hold.
- The 2026-08-16 automated strategy probe predates Belt Condition and immediate bin circulation. Rerun exact and heuristic sweeps against the accepted eight-egg daily pool before using it as current balance evidence.
- A running-game check at 1280×720 and 1024×576 must verify the bin reads as the conveyor destination, the bin and hopper counts remain legible and clickable, both content inspectors fit and scroll, recycled eggs visibly return through the pipe, and no removed hairpin controls leave empty or overlapping space.
- Play one seeded run through at least three bird offers. Record which species are immediately attractive or dismissible, when the player first considers paying £3 to thin the flock, and whether removing from the full overview feels precise and trustworthy.

## Active mechanic slice — Direct-thwack movement eggs

### Question

Do a visible left-to-right instruction queue and three plain movement eggs create interesting positional choices without making Belt Condition or effect timing hard to read?

### Status

Implemented for feel testing. Oily, Nostalgic, and Gloopy are available in rewards and development setup under temporary mechanic names. Oily and Nostalgic use a neutral 3-toughness, 1-point baseline. Gloopy is deliberately an enabling cost rather than a scoring route: 2 toughness, −1 foul Yolk, and 0% Double Yolker. Their mythology, permanent species assignments, and final numerical balance remain hypotheses.

### Implemented prototype scope

- Capture movement instructions only from the eggs directly beneath the selected circuit's original spoons, before damage and hatches change the belt.
- Resolve those instructions in slot order from screen left to right, then append normal forward movement.
- Oily adds `▶`; Nostalgic adds `◀`; Gloopy adds one Jam that cancels the next movement. Jams stack and unused Jams expire at the thwack boundary.
- Hatching Gloopy subtracts 1 Satisfaction and may take the total below zero. Negative Yolk is never doubled and never consumes Appetiser.
- Nostalgic returns an egg crossing slot 1 to the front of the hopper and never retrieves from the bin. Each executed forward step uses the existing bin and refill rules.
- Every committed thwack spends exactly 1 Belt Condition after the queue, including a fully jammed thwack. Echo and Shockwave damage add no movement instructions or extra cost.
- A belt-mounted preview shows the selected circuit's symbols, blocked instructions, written Jam outcome, and left-to-right order before commitment. Resolver events drive forward, reverse, Jam, cancellation, hopper-return, and expiry playback through the existing presentation barrier.
- Status emblems and neutral status portraits distinguish the three eggs without inventing bird mythology.

### Balancing constraints and unknowns

- Test whether Oily's extra circulation is worth accelerating valuable eggs toward the bin, and whether 1 point is enough compensation for its positional risk.
- Test whether Nostalgic creates new targeting alignments rather than merely undoing normal movement in most layouts.
- Test whether two possible Jams justify Gloopy's −1 Yolk, whether players intentionally leave a one-toughness Gloopy unhatched, and whether mandatory offers make foul-egg dilution feel interesting rather than hopeless.
- Observe reward desirability before changing toughness, point values, offer weighting, or assigning permanent species.

### Exit evidence

- Domain tests cover instruction capture, left-to-right resolution, extra forward movement, reverse boundary behavior, Jam cancellation, stacking, expiry, one Condition per thwack, indirect-hit exclusion, negative Satisfaction below zero, Appetiser exclusion, and domain-authored previews.
- UI coverage checks instruction emblems, written preview results, reverse-before-forward playback, hopper return, cancellation without conveyor motion, foul `−1` payoff, negative Satisfaction display, and Condition presentation.
- Run human tests with mixed Oily/Nostalgic/Gloopy pairs and record whether the predicted queue matches the felt result without explanation.

## Implemented supporting slice — Current Grandma-facing egg effects

### Question

Can three reusable egg effects establish a coherent, deterministic vocabulary for Yolk, Satisfaction, and Appetite before the ten-day curve is balanced?

### Status

Accepted and implemented. Appetiser, Sulphurous, and Shockwave are reusable egg descriptors resolved by the canonical day resolver. Deceptively Filling was removed as premature when its future-thwack payoff conflicted with the Belt Condition clock and egg-exhaustion ending; ten-day balance remains deferred.

### Settled rules to preserve

- The belt begins a day with 12 Condition, each current thwack's movement spends 1, and the day ends immediately when a fully resolved thwack meets or exceeds its target.
- The five-slot conveyor, three fixed circuits, seeded egg order, recycling rule, visible information, and one-bird/one-egg relationship remain unchanged.
- Existing printed egg values remain the initial balance baseline. For the first test, food and score are numerically identical.
- Conveyor order remains the canonical order for resolving several eggs that open during the same damage batch.

### Implemented behavior

- Appetiser queues ×2 charges for future positive-Yolk eggs. Stacking adds eligible eggs of duration rather than increasing the multiplier; one charge is consumed per eligible egg.
- Each Sulphurous egg suppresses 2 Appetite exactly once when it hatches. Suppression stacks, persists for the rest of the day, cannot lower effective Appetite below 1, and clears at the day boundary.
- Shockwave emits resolver-owned left/right strike batches with inherited circuit identity, Cuckoo/Plover/Spoonbill composition, deterministic chains, and exactly-once hatch guards.
- All Grandma effects clear at day end and on retry. Compact statuses show Appetiser charges and total day-long Sulphurous suppression. The appetite bar fills Yolk from the left and green suppression from the right while its numeric denominator shows effective Appetite.

### Explicitly deferred

- Multiple recipients, rotating appetites, dislikes, allergies, personalities, authored dialogue triggers, and relationship progression. The Grandma scene reserves presentation space for later statuses and dialogue only.
- Bespoke production art, staged reward unlocks, a rebalance of the starting flock and targets, and ten-day effect tuning.
- Deciding whether eggs are narratively hatched, cracked, cooked, or otherwise prepared for the recipient.

### Exit evidence

- Domain coverage proves charge-based Appetiser duration, same-batch ordering, permanent fixed Sulphurous stacking and exactly-once activation, complete committed thwacks, Shockwave boundaries/chains/circuit inheritance, and exactly-once resolution.
- Session coverage proves retry clears active Grandma effects.
- UI coverage proves the compact status area exposes Appetiser charges and total Sulphurous Appetite suppression without adding another major panel; the appetite meter exposes suppression from the opposite direction with a numeric alternative to colour.

## Implemented supporting slice — Signature effect species

### Question

Can one permanent bird per current effect make the Grandma-facing vocabulary legible as flock-building choices without changing the opening flock?

### Status

Accepted and implemented. Quail, Maleo, and Ostrich are immediately available in the post-success reward pool alongside the five existing species. Kiwi was removed from the current roster with Deceptively Filling. The starting flock remains three Chickens, two Cuckoos, and three Sparrows.

### Implemented behavior

- Quail lays a 2-toughness, 1-Yolk Appetiser egg with no Double Yolker chance.
- Maleo lays a 6-toughness, 3-Yolk Sulphurous egg with a 1% Standard Double Yolker chance.
- Ostrich lays a 7-toughness, 3-Yolk Shockwave egg with a 1% Standard Double Yolker chance.
- Every signature species uses its fixed Standard toughness, Yolk, effect, and intrinsic Double Yolker chance.
- Reward, flock-overview, loading, conveyor, hopper, bin, and hover-card views reuse the existing species paths with distinct temporary colours, silhouettes, effect marks, and written effect descriptions.

### Explicitly deferred

- Ten-day Appetite tuning, reward weighting or staged unlocks, starting-flock changes, and bespoke final art.
- Playtest evidence about whether the eight-species reward pool is too dilute or whether any signature egg dominates its nearest existing alternative.
- Kiwi and Deceptively Filling remain deferred until they have a role that does not reward stalling or lose an advertised payload at egg exhaustion.

### Exit evidence

- Domain tests cover all three definitions, their built-in descriptors, permanent producer validation, intrinsic Double Yolker odds, and deterministic effect behavior.
- Session tests cover deterministic three-choice rewards drawn from the expanded permanent species list.
- UI tests cover distinct placeholder identities and complete reward-card explanations for every signature egg.

## Superseded foundational slice — Movement-linked Belt Condition

### Question

Does replacing per-spoon wear with one movement-linked Belt Condition clock create a clearer progression surface for pausing, bundled advancement, repair, armour, and damage?

### Status

This was the implemented foundation for the Belt Condition prototype, but its movement-linked cost rule is now superseded by the direct-thwack movement slice above. The single visible resource, 12-point starting value, complete-action timing, success precedence, and removal of spoon Integrity remain current; every committed thwack now costs 1 even when Jam prevents movement.

### Settled behavior

- At day start, load the first five shuffled eggs across slots 1–5, or every available egg when the daily pool contains fewer than five. Only eggs beyond those opening five remain in the hopper and pipe preview.
- Belt Condition starts at 12. Every circuit remains available until the day ends; spoons have no individual health, wear, or broken state.
- Historical foundation: each thwack advanced the belt once and a positive movement operation cost 1 after refill. D073 supersedes this with an ordered movement queue and exactly 1 Condition per committed thwack.
- Additional indirect strikes, including Shockwave chains, still add no movement instruction or extra Condition cost.
- The day fails when Belt Condition reaches 0 and Appetite remains unmet; success still takes precedence after the complete action.
- Soft-Shelled and its development-only test egg are removed.
- Debug setup can choose ordered eggs and set starting Belt Condition.
- Whenever the hopper is empty, immediately reshuffle the current bin into a new hopper even while other eggs remain on the conveyor. This check occurs both before entry and after the last waiting egg enters slot 1, so the pipe is reloaded within that thwack without loading a second conveyor egg.
- Successful days award a fixed £3, keeping the economy independent from current Belt Condition tuning.

### Explicitly deferred

- Further movement instructions, repair or armour for the belt, or direct Condition damage.
- Final starting-Condition tuning, Belt Condition progression, and production art for the new bar.

### Exit evidence

- Historical domain coverage proved one Condition loss after positive movement; current D073 coverage supersedes that assertion with one Condition loss per committed thwack. Shockwave cost, failure at zero, success precedence, five-egg opening order, and same-thwack bin circulation remain covered.
- Presentation coverage proves one labelled progress bar on the conveyor housing renders the resolved Condition value inside the existing input barrier, reduced motion resolves immediately, and cancellation restores stable transforms.
- Continue playtesting ordinary five-egg openings. Record whether 12 Condition gives enough room for deliberate bin circulation, whether free non-movement strikes are valuable without dominating, and which pause, multi-step, or repair egg should be the first content test.
