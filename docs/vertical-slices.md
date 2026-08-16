# Vertical slices

This file describes current implementation and learning scope. It does not override current rules.

## Active validation slice — Free bird rewards and visible flock thinning

### Question

Does choosing one of three free, potentially high-quality birds after each successful day create an interesting build direction, and does removing an exact bird from the whole-flock overview for £3 provide enough control over compulsory flock growth?

### Status

The deterministic and player-visible path now opens a dedicated bird-offer screen after a successful day, presents three candidates with seeded species and quality facts, and requires exactly one selection. That selection closes the offer and opens a separate shop where every owned bird is its own £3 removal control in a scrollable flock overview, but only one bird can be removed during that visit. Standard cards have no rarity tint, Prize cards are green, and Champion-or-higher cards are blue with written tier names retained. Recruitment purchases, pairing, merge queues, and factory upgrades are removed. Failed attempts still retry without between-day progression. The next worthwhile work is a human run through several rewards to observe whether flock growth, quality variance, and removal pricing create meaningful tension.

### Settled rules preserved

- Every bird lays exactly one egg per day; the starting pool is three Chicken, two Cuckoo, and three Sparrow eggs.
- Days last at most 10 thwacks, end after the target-reaching thwack, and pay £1 for each unused thwack only on success.
- Day 1 requires 10 points and each later day requires 9.
- Red strikes slots 1+3, Blue strikes 2+4, and Pink strikes slot 5. All three remain available during an unlocked day, including when their complete circuit is empty. Pink still deals 2 direct damage to Spoonbills.
- Cuckoo echoes, Plover retreat, simultaneous damage, hatch order, cash, retries, success-only shop access, and one request-to-resolver pathway remain unchanged.
- Every successful day opens a dedicated three-bird offer, exactly one must be chosen before the separate shop opens, and the only current shop action is removing at most one selected bird for £3.
- Daily randomness remains seeded and equal retries reproduce initial and recycled shuffles and hidden outcomes.

### Hypothesis

One stable track should let the player read circuits and egg movement immediately. Moving an unhatched egg into a visible bin converts permanent loss into a tempo cost: the egg retains damage, but the player must clear both the hopper and conveyor and accept a new seeded order before seeing it again.

Keeping all three levers active should make conveyor position an intentional resource instead of letting occupancy silently choose the legal actions. An empty pull may improve the next alignment, but its full one-thwack cost must keep it from becoming free cycling.

Three one-hit Sparrows should make the complete hatch-and-score payoff legible during the opening pulls. Their 5% Double Yolker chance should introduce jackpots through the simplest possible shell, while their positions beside Cuckoos can teach that damaging one egg may also create an echo elsewhere. An eight-egg pool keeps the pipe active beyond one track capacity and delays recycling, so its increased scoring supply must compete with congestion and the ten-thwack limit.

At a 10-point target, candidate routes include all three Chickens plus one Sparrow; two Chickens, both Cuckoos, and two Sparrows; or two Chickens, one Cuckoo, and all three Sparrows. These arithmetic routes are hypotheses rather than evidence that each route is equally achievable across shuffled positions.

Offered quality should create occasional excitement without making high tiers routine. The current prototype independently gives each candidate a 25% chance to advance one tier, repeated until a roll fails. This geometric distribution has no fixed maximum, so every quality is possible while Standard remains common. The 25% continuation rate is an implementation hypothesis, not a settled rule; observe its results before tuning it into rule truth.

### Implemented prototype scope

- One five-slot conveyor and the same three circuits on every day; the Day 3 hairpin and refit are removed.
- Every visible lever is usable throughout an unlocked day. A completely empty circuit fires its linked spoons, advances the conveyor, and spends one thwack without damage.
- Visible hopper and bin counts at their physical containers. Clicking the hopper opens a non-positional egg collection without revealing queue order beyond the three pipe previews; clicking the bin opens every stored egg with retained toughness and states that return order will shuffle.
- Resolver events for an egg entering the bin, the complete bin reshuffling into an empty hopper, and the next egg entering slot 1.
- Binned eggs retain remaining toughness, tier, score, Double Yolker result, and every other egg fact.
- The injected shuffler owns every recycle order, preserving deterministic retries.
- Existing hopper eggs feed normally, but the bin cannot reshuffle until the conveyor is empty; a recycled wave never joins eggs still travelling from the previous wave.
- Quality uses exact `1.5^tier` multiplication for score, maximum toughness, and Double Yolker chance.
- Gameplay score and displayed percentages floor to whole numbers. Maximum toughness rounds up to the whole amount of damage actually required. Later tiers retain exact values.
- A dedicated reward screen shows three cards with species, quality, shell toughness, score, effect, and one daily egg before selection. It contains no shop or removal controls. Standard cards have no rarity tint, Prize cards use green, and Champion-or-higher cards use blue without replacing their text labels.
- After selection, a separate shop screen shows the complete flock as individual cards with species, quality, egg facts, and £3 removal actions. After one removal, all remaining cards visibly report that the nightly removal was used. The last bird and unaffordable removals are also unavailable.
- Existing production loading shows the scaled toughness of the egg each quality tier lays.
- Every species uses one flat temporary colour across a generic egg and a simple bird silhouette throughout the belt, pipe, loading, reward, and flock-overview views. Species names sit outside the art. Occupied eggs use a magnifying-glass cursor to advertise inspection. A wrapped hover card top-aligns beside its egg, flips sides at the viewport edge, and presents the egg's name, prominent points and Double Yolker facts, and only its applicable effect sections. Generated raster experiments are excluded from the running game and exports; final production assets are deferred to an artist.
- The default flock contains three Chickens, two Cuckoos, and three Sparrows, with ten starting thwacks, a 10-point Day 1 target, and a 9-point later target.

### Balancing constraints

- Recycling removes permanent belt loss but not the 10-thwack limit.
- Empty strikes create a positioning option, but each consumes 10% of the complete day budget and can accelerate eggs toward the bin without scoring.
- Five eggs remain the machine's natural capacity breakpoint. The eight-egg opening carries more total score and keeps the hopper active longer, but delays any recycled wave.
- The starting flock contains 14 total base points and 20 total base toughness. Day 1's 10-point target leaves four points of composition slack.
- Sparrows provide one point per direct damage before positional waste, and a directly struck Sparrow can also cause adjacent Cuckoo echoes. Guard against their combination making the quickest route obvious across most seeds.
- A small flock cycles more often, but can still fail by hatching every available egg below the target.
- Rounding makes some first-tier ratios uneven. A Prize Chicken requires 5 damage and awards 4 points from exact values of 4.5 and 4.5.
- A Prize Cuckoo currently requires 6 damage but remains worth 1 displayed point and has no Double Yolker chance. A free high-quality offer can therefore still be strategically unattractive; keep complete candidate facts visible.
- A Prize Sparrow currently requires 2 damage, remains worth 1 displayed point, and shows a 7% Double Yolker chance from an exact 7.5%. The offer must make that shell-for-odds trade legible rather than presenting quality as universally better.
- Positive feedback from efficient play into greater purchasing power remains intentional. Guard against a deterministic retry that cannot reach the shop.

### Explicitly deferred

- Further target, thwack, toughness, score, reward-quality distribution, and £3 removal-price tuning after playtest evidence.
- Bin capacity, player-controlled rerolls, selective retrieval, damage healing, or bin upgrades.
- Pairing, merging, hybrid recipes, inherited effects, and authored hybrid art.
- Paid recruitment, factory upgrades, a campaign map, reward rerolls, discounts, selling, elite conditions, and production art.
- A replacement for the removed Day 3 factory milestone or any positional spoon-upgrade ladder.

### Exit evidence

- Domain tests prove damage-preserving bin transfer, clear-conveyor recycle gating, empty-circuit advancement and thwack spending, resolver event order, deterministic reshuffle, slot-1 refill, quality toughness scaling, and whole required-damage rounding.
- Session tests prove the default eight-egg flock, ten-thwack budget, 10/9 targets, Sparrow probability, five slots and three circuits, deterministic three-bird offers, exact free selection, one £3 targeted removal per shop visit, and deterministic failure/retry behavior.
- UI tests prove the dedicated reward screen exposes free species-and-quality facts without flock controls, Standard/Prize/Champion cards carry neutral/green/blue rarity treatment, selecting a reward opens the separate shop, the whole flock appears there as individual removal controls, all removals disable after one selected bird disappears for £3, dynamic controls do not accumulate stale registrations, and cancellation/input-lock contracts still hold.
- The 2026-08-16 automated strategy probe supplies an exact-search and heuristic baseline for the superseded five-egg opening. Run the same exact and heuristic sweep against the eight-egg Sparrow opening at targets 9, 10, and 11 before using it as balance evidence.
- A running-game check at 1280×720 and 1024×576 must verify the bin reads as the conveyor destination, the bin and hopper counts remain legible and clickable, both content inspectors fit and scroll, recycled eggs visibly return through the pipe, and no removed hairpin controls leave empty or overlapping space.
- Play one seeded run through at least three bird offers. Record whether candidate quality is understood, whether a clearly stronger quality dominates species choice, when the player first considers paying £3 to thin the flock, and whether removing from the full overview feels precise and trustworthy.

## Candidate next validation slice — Feed a character, not a score

### Question

Does directing hatched eggs into one visible hungry character make the daily objective and egg effects more immediate, memorable, and readable without distracting from the conveyor-position puzzle?

### Status

Proposed hypothesis only. The current score target, hatch terminology, egg values, and egg effects remain canonical until this direction is deliberately accepted. Complete the active Sparrow-and-quality balance probe before treating this candidate as a replacement slice.

### Settled rules to preserve

- A day still has ten thwacks and ends immediately after a fully resolved thwack meets or exceeds its target.
- The five-slot conveyor, three fixed circuits, seeded egg order, recycling rule, visible information, and one-bird/one-egg relationship remain unchanged.
- Existing printed egg values remain the initial balance baseline. For the first test, food and score are numerically identical.
- Conveyor order remains the canonical order for resolving several eggs that open during the same damage batch.

### Hypothesis

A visible recipient gives the abstract score target a physical cause: opened eggs feed someone. The same character can visibly carry temporary states, allowing egg effects to read as reactions rather than unrelated arithmetic. An Appetiser is the smallest useful effect test because it asks the player to engineer hatch order using information and controls they already understand.

Candidate Appetiser wording: “Feeds 1. The next egg fed provides twice its printed food.” The bonus becomes active immediately, can be consumed by a later egg in the same thwack, doubles immediate printed food only, does not stack beyond 2×, and expires at day end.

### One playable path

Begin one controlled ten-thwack day with the normal conveyor and a visible hungry character beside a 10-food meter. Use a seeded pool containing ordinary known eggs and exactly one clearly marked Appetiser test egg. The player can inspect toughness, food, and the Appetiser effect before choosing a circuit. When it opens, the character visibly gains 1 food and displays a persistent “Next egg ×2” state. The next egg to resolve consumes that state, its immediate food animates into the character at double value, and the day otherwise succeeds, fails, pays out, and retries under the established rules.

### Implementation conveniences, not rules

- The recipient may use placeholder identity, art, reactions, and sound during the test.
- The Appetiser egg may be injected by a fixed test-day setup rather than added to day-end offers, flock persistence, or the permanent species catalogue.
- “Food” may reuse the exact current score value and target storage while the player-facing experiment uses feeding language.

### Explicitly deferred

- Multiple recipients, rotating appetites, dislikes, allergies, personalities, dialogue, and relationship progression.
- Slow feeding over several thwacks, Feeding Frenzy, effect stacking, effect inheritance through quality, and interactions between several new egg effects.
- A permanent new bird species, day-end reward offer, bespoke production art, or rebalance of the starting flock and targets.
- Deciding whether eggs are narratively hatched, cracked, cooked, or otherwise prepared for the recipient.

### Exit evidence

- Deterministic tests prove Appetiser activation, same-thwack conveyor-order consumption, 2× immediate food, non-stacking behavior, day-end expiry, and unchanged end-of-day timing.
- UI checks prove the character, current food, target, pending 2× state, source egg, and doubled result remain legible without obscuring the conveyor, pipe, bin, or thwack countdown.
- In a short comparison playtest, play the same seed once with abstract score presentation and once with the feeding-character presentation. Ask what the objective is, what Appetiser will do, which egg should follow it, and whether watching the character adds payoff or merely delays the machine.
- Advance this direction only if players understand the objective and predict Appetiser resolution at least as reliably as the current score model while reporting a stronger sense of consequence or attachment.
