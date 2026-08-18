# Vertical slices

This file describes current implementation and learning scope. It does not override current rules.

## Active validation slice — Free bird rewards and visible flock thinning

### Question

Does choosing one of three free, potentially high-quality birds after each successful day create an interesting build direction, and does removing an exact bird from the whole-flock overview for £3 provide enough control over compulsory flock growth?

### Status

The deterministic and player-visible path now opens a dedicated bird-offer screen after a successful day, presents three candidates with seeded species and quality facts, and requires exactly one selection. That selection closes the offer and opens a separate shop where every owned bird is its own £3 removal control in a scrollable flock overview, but only one bird can be removed during that visit. Standard cards have no rarity tint, Prize cards are green, and Champion-or-higher cards are blue with written tier names retained. Recruitment purchases, pairing, merge queues, and factory upgrades are removed. Failed attempts still retry without between-day progression. The next worthwhile work is a human run through several rewards to observe whether flock growth, quality variance, and removal pricing create meaningful tension.

### Settled rules preserved

- Every bird lays exactly one egg per day; the starting pool is three Chicken, two Cuckoo, and three Sparrow eggs.
- The belt starts each day with 12 Condition. Any movement operation that advances one or more slots costs exactly 1; success takes precedence if Condition reaches 0 during the target-reaching thwack. A successful day pays a fixed £3.
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

Offered quality should create occasional excitement without making high tiers routine. The current prototype independently gives each candidate a 25% chance to advance one tier, repeated until a roll fails. This geometric distribution has no fixed maximum, so every quality is possible while Standard remains common. The 25% continuation rate is an implementation hypothesis, not a settled rule; observe its results before tuning it into rule truth.

### Implemented prototype scope

- One five-slot conveyor and the same three circuits on every day; the Day 3 hairpin and refit are removed.
- Every lever is usable throughout an unlocked day. A spoon over an empty bay still fires and the conveyor still advances, spending 1 Belt Condition without dealing damage.
- Visible hopper and bin counts at their physical containers. Clicking the hopper opens a non-positional egg collection without revealing queue order beyond the three pipe previews; clicking the bin opens every stored egg with retained toughness and states that return order will shuffle.
- Resolver events for an egg entering the bin, the complete bin reshuffling into an empty hopper, and the next egg entering slot 1.
- Binned eggs retain remaining toughness, tier, score, Double Yolker result, and every other egg fact.
- The injected shuffler owns every recycle order, preserving deterministic retries.
- Existing hopper eggs feed normally. Whenever the hopper is empty, the bin reshuffles immediately and may rejoin eggs still travelling on the conveyor; at most one egg enters slot 1 per thwack.
- Quality uses exact `1.5^tier` multiplication for score, maximum toughness, and Double Yolker chance.
- Gameplay score and displayed percentages floor to whole numbers. Maximum toughness rounds up to the whole amount of damage actually required. Later tiers retain exact values.
- A dedicated reward screen shows three cards with species, quality, shell toughness, score, effect, and one daily egg before selection. It contains no shop or removal controls. Standard cards have no rarity tint, Prize cards use green, and Champion-or-higher cards use blue without replacing their text labels.
- After selection, a separate shop screen shows the complete flock as individual cards with species, quality, egg facts, and £3 removal actions. After one removal, all remaining cards visibly report that the nightly removal was used. The last bird and unaffordable removals are also unavailable.
- Existing production loading shows the scaled toughness of the egg each quality tier lays.
- Every species uses one flat temporary colour across a generic egg and a simple bird silhouette throughout the belt, pipe, loading, reward, and flock-overview views. Species names sit outside the art. Occupied eggs use a magnifying-glass cursor to advertise inspection. A wrapped hover card top-aligns beside its egg, flips sides at the viewport edge, and presents the egg's name, prominent points and Double Yolker facts, and only its applicable effect sections. Generated raster experiments are excluded from the running game and exports; final production assets are deferred to an artist.
- The default flock contains three Chickens, two Cuckoos, and three Sparrows, with 12 starting Belt Condition, a 10-point Day 1 target, and a 9-point later target.
- One domain-owned Belt Condition value replaces individual spoon Integrity. Each current thwack advances once and spends exactly 1 after movement and refill; Shockwave strikes add no movement cost, and reaching 0 fails unless the completed thwack already succeeded.
- A full-height information rail to the right of the belt presents the unchanged score and target as Grandma's appetite, alongside one labelled Belt Condition bar and settings. Awarded points fill a yolk meter proportionally, overflow remains numeric, reduced motion stops her placeholder idle animation, and the reusable scene reserves status and left-expanding dialogue regions without yet authoring dialogue behavior.
- The workshop spends its remaining area on the existing machine: a bottom-anchored hopper lift shares a deck line with the larger clickable bin, carries its clickable count on that loading deck, raises three preview eggs toward a short conveyor-height exit, and then pushes the top egg sideways into a lowered five-lane playfield with slightly larger eggs and taller stored spoons. Moving eggs show a readable backward lean followed by a damped counter-wobble and always settle upright. The conveyor curves once after slot five into the bin, the same three circuit controls occupy a compact bottom fascia, and no decorative yolk pipe or additional readout implies new functionality.

### Balancing constraints

- Recycling removes permanent belt loss without adding dead conveyor-clearing turns.
- Empty strikes create a positioning option, but their belt movement still costs 1 Condition and can accelerate eggs toward the bin without scoring.
- Five eggs fill the machine's natural opening capacity. The eight-egg daily pool carries more total score and keeps three eggs in the initial hopper.
- The starting flock contains 14 total base points and 20 total base toughness. Day 1's 10-point target leaves four points of composition slack.
- Sparrows provide one point per direct damage before positional waste, and a directly struck Sparrow can also cause adjacent Cuckoo echoes. Guard against their combination making the quickest route obvious across most seeds.
- A small flock cycles more often, but can still fail by hatching every available egg below the target.
- Rounding makes some first-tier ratios uneven. A Prize Chicken requires 5 damage and awards 4 points from exact values of 4.5 and 4.5.
- A Prize Cuckoo currently requires 6 damage but remains worth 1 displayed point and has no Double Yolker chance. A free high-quality offer can therefore still be strategically unattractive; keep complete candidate facts visible.
- A Prize Sparrow currently requires 2 damage, remains worth 1 displayed point, and shows a 7% Double Yolker chance from an exact 7.5%. The offer must make that shell-for-odds trade legible rather than presenting quality as universally better.
- The fixed £3 success payout keeps the economy independent from current Belt Condition tuning. Guard against a deterministic retry that cannot reach the shop.

### Explicitly deferred

- Further target, Belt Condition, toughness, score, reward-quality distribution, and £3 removal-price tuning after playtest evidence.
- Bin capacity, player-controlled rerolls, selective retrieval, damage healing, or bin upgrades.
- Pairing, merging, hybrid recipes, inherited effects, and authored hybrid art.
- Paid recruitment, factory upgrades, a campaign map, reward rerolls, discounts, selling, elite conditions, and production art.
- A replacement for the removed Day 3 factory milestone or any positional spoon-upgrade ladder.

### Exit evidence

- Domain tests prove damage-preserving bin transfer, exact hopper-empty recycling, empty-impact paid advancement, one Belt Condition loss per positive movement operation, free non-movement Shockwaves, success precedence at zero, resolver event order, deterministic reshuffle, slot-1 refill, quality toughness scaling, and whole required-damage rounding.
- Session tests prove the default eight-egg flock, 12 starting Belt Condition, fixed £3 payout, 10/9 targets, Sparrow probability, five slots and three circuits, deterministic three-bird offers, exact free selection, one £3 targeted removal per shop visit, and deterministic failure/retry behavior.
- UI tests prove the dedicated reward screen exposes free species-and-quality facts without flock controls, Standard/Prize/Champion cards carry neutral/green/blue rarity treatment, selecting a reward opens the separate shop, the whole flock appears there as individual removal controls, all removals disable after one selected bird disappears for £3, dynamic controls do not accumulate stale registrations, and cancellation/input-lock contracts still hold.
- The 2026-08-16 automated strategy probe predates Belt Condition and immediate bin circulation. Rerun exact and heuristic sweeps against the accepted eight-egg daily pool before using it as current balance evidence.
- A running-game check at 1280×720 and 1024×576 must verify the bin reads as the conveyor destination, the bin and hopper counts remain legible and clickable, both content inspectors fit and scroll, recycled eggs visibly return through the pipe, and no removed hairpin controls leave empty or overlapping space.
- Play one seeded run through at least three bird offers. Record whether candidate quality is understood, whether a clearly stronger quality dominates species choice, when the player first considers paying £3 to thin the flock, and whether removing from the full overview feels precise and trustworthy.

## Implemented supporting slice — First Grandma-facing egg effects

### Question

Can four reusable egg effects establish a coherent, deterministic vocabulary for Yolk, Satisfaction, Appetite, and future-thwack timing before the ten-day curve is balanced?

### Status

Accepted and implemented. Appetiser, Sulphurous, Shockwave, and Deceptively Filling are reusable egg descriptors resolved by the canonical day resolver. A subsequent supporting slice assigned them to permanent reward species; ten-day balance remains deferred.

### Settled rules to preserve

- The belt begins a day with 12 Condition, each current thwack's movement spends 1, and the day ends immediately when a fully resolved thwack meets or exceeds its target.
- The five-slot conveyor, three fixed circuits, seeded egg order, recycling rule, visible information, and one-bird/one-egg relationship remain unchanged.
- Existing printed egg values remain the initial balance baseline. For the first test, food and score are numerically identical.
- Conveyor order remains the canonical order for resolving several eggs that open during the same damage batch.

### Implemented behavior

- Appetiser queues ×2 charges for future positive-Yolk eggs. Stacking adds eligible eggs of duration rather than increasing the multiplier; one charge is consumed per eligible egg.
- Each Sulphurous egg suppresses 2 Appetite exactly once when it hatches. Suppression stacks, persists for the rest of the day, cannot lower effective Appetite below 1, and clears at the day boundary.
- Shockwave emits resolver-owned left/right strike batches with inherited circuit identity, Cuckoo/Plover/Spoonbill composition, deterministic chains, and exactly-once hatch guards.
- Deceptively Filling adds slow-release Yolk to one shared reserve. The reserve releases exactly 1 Yolk at the start of each later thwack, so additional activations extend duration rather than increasing the release rate; a release cannot cancel a committed action.
- All Grandma effects clear at day end and on retry. Compact statuses show Appetiser charges, total day-long Sulphurous suppression, and the remaining Filling reserve. The appetite bar fills Yolk from the left and green suppression from the right while its numeric denominator shows effective Appetite.

### Explicitly deferred

- Multiple recipients, rotating appetites, dislikes, allergies, personalities, authored dialogue triggers, and relationship progression. The Grandma scene reserves presentation space for later statuses and dialogue only.
- Bespoke production art, staged reward unlocks, a rebalance of the starting flock and targets, and ten-day effect tuning.
- Deciding whether eggs are narratively hatched, cracked, cooked, or otherwise prepared for the recipient.

### Exit evidence

- Domain coverage proves charge-based Appetiser duration, same-batch ordering, immediate-Yolk-only eligibility, permanent fixed Sulphurous stacking and exactly-once activation, one-per-thwack Filling release from an additive reserve, complete committed thwacks, Shockwave boundaries/chains/circuit inheritance, and exactly-once resolution.
- Session coverage proves retry clears active Grandma effects.
- UI coverage proves the compact status area exposes Appetiser charges, total Sulphurous Appetite suppression, and the remaining Filling reserve without adding another major panel; the appetite meter exposes suppression from the opposite direction with a numeric alternative to colour.

## Implemented supporting slice — Signature effect species

### Question

Can one permanent bird per effect make the Grandma-facing vocabulary legible as flock-building choices without changing the opening flock?

### Status

Accepted and implemented. Quail, Maleo, Ostrich, and Kiwi are immediately available in the post-success reward pool alongside the five existing species. The starting flock remains three Chickens, two Cuckoos, and three Sparrows.

### Implemented behavior

- Quail lays a 2-toughness, 1-Yolk Appetiser egg with no Double Yolker chance.
- Maleo lays a 6-toughness, 3-Yolk Sulphurous egg with a 1% Standard Double Yolker chance.
- Ostrich lays a 7-toughness, 3-Yolk Shockwave egg with a 1% Standard Double Yolker chance.
- Kiwi lays a 3-toughness, 0-immediate-Yolk Deceptively Filling (8) egg with no Double Yolker chance.
- Quality scales toughness, immediate Yolk, and non-zero Double Yolker chance by the existing exact ×1.5 rule. Signature effects do not scale with quality.
- Reward, flock-overview, loading, conveyor, hopper, bin, and hover-card views reuse the existing species paths with distinct temporary colours, silhouettes, effect marks, and written effect descriptions.

### Explicitly deferred

- Ten-day Appetite tuning, reward weighting or staged unlocks, starting-flock changes, and bespoke final art.
- Playtest evidence about whether the expanded nine-species reward pool is too dilute or whether any signature egg dominates its nearest existing alternative.

### Exit evidence

- Domain tests cover all four definitions, their built-in descriptors, permanent producer validation, Double Yolker odds, quality composition, and deterministic effect behavior.
- Session tests cover deterministic three-choice rewards drawn from the expanded permanent species list.
- UI tests cover distinct placeholder identities and complete reward-card explanations for every signature egg.

## Accepted foundational slice — Belt Condition as the unified day clock

### Question

Does replacing per-spoon wear with one movement-linked Belt Condition clock create a clearer progression surface for pausing, bundled advancement, repair, armour, and damage?

### Status

Accepted and implemented as the authoritative daily-pressure system. A single highly visible Belt Condition bar replaces spoon Integrity and Soft-Shelled protection. The cost belongs to movement rather than the lever press: a movement operation that advances one or more slots costs exactly 1, while zero-slot movement costs none. The current base thwack advances one slot; pause, multi-slot advance, repair, armour, and damage effects remain future content.

### Settled behavior

- At day start, load the first five shuffled eggs across slots 1–5, or every available egg when the daily pool contains fewer than five. Only eggs beyond those opening five remain in the hopper and pipe preview.
- Belt Condition starts at 12. Every circuit remains available until the day ends; spoons have no individual health, wear, or broken state.
- Each current thwack advances the belt once. The complete movement and refill resolve before 1 Condition is spent.
- A single movement operation costs 1 if it advances any positive number of slots and costs none if it advances zero. Additional strikes without movement, including Shockwave chains, cost no extra Condition.
- The day fails when Belt Condition reaches 0 and Appetite remains unmet; success still takes precedence after the complete action.
- Soft-Shelled and its development-only test egg are removed.
- Debug setup can choose ordered eggs and set starting Belt Condition.
- Whenever the hopper is empty, immediately reshuffle the current bin into a new hopper even while other eggs remain on the conveyor. This check occurs both before entry and after the last waiting egg enters slot 1, so the pipe is reloaded within that thwack without loading a second conveyor egg.
- Successful days award a fixed £3, keeping the economy independent from current Belt Condition tuning.

### Explicitly deferred

- Egg effects that pause movement, bundle several movement steps into one paid operation, repair or armour the belt, or damage its Condition.
- Final starting-Condition tuning, Belt Condition progression, and production art for the new bar.

### Exit evidence

- Domain coverage proves one Condition loss after positive movement, no extra cost for Shockwave strikes, failure at zero, success precedence at zero, five-egg opening order, and same-thwack bin circulation.
- Presentation coverage proves one labelled progress bar renders the resolved Condition value inside the existing input barrier, reduced motion resolves immediately, and cancellation restores stable transforms.
- Continue playtesting ordinary five-egg openings. Record whether 12 Condition gives enough room for deliberate bin circulation, whether free non-movement strikes are valuable without dominating, and which pause, multi-step, or repair egg should be the first content test.
