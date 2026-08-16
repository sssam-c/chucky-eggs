# Vertical slices

This file describes current implementation and learning scope. It does not override current rules.

## Active validation slice — Small cycling flock and dense quality

### Question

Does a five-egg starting flock moving in clear-belt waves through one five-slot track create a short, legible positioning puzzle under a ten-thwack limit, and does 1.5× score-plus-toughness make merging a situational density choice rather than an automatic upgrade?

### Status

The complete deterministic and player-visible path is implemented and covered by the automated suite. The starting economy uses five eggs, ten thwacks, an 8-point opening target, and a 9-point later target. Bin recycling waits for the conveyor to clear instead of feeding missed eggs back into a live wave one at a time, and every lever remains active during unlocked day play. An automated strategy probe found every sampled current, target-9, and post-merge seed solvable; empty pulls sometimes belonged to equally fast routes but never improved or became mandatory for the fastest win. It also found the current opening forgiving and a blanket +1 starting-toughness increase excessively punitive. The next worthwhile work is a human A/B playtest of the 8- and 9-point openings. No human evidence yet establishes whether empty-pull agency, bin recovery, or tougher merged eggs feel fun and legible rather than merely solvable.

### Settled rules preserved

- Every bird lays exactly one egg per day; the starting pool is three Chicken and two Cuckoo eggs.
- Days last at most 10 thwacks, end after the target-reaching thwack, and pay £1 for each unused thwack only on success.
- Day 1 requires 8 points and each later day requires 9.
- Red strikes slots 1+3, Blue strikes 2+4, and Pink strikes slot 5. All three remain available during an unlocked day, including when their complete circuit is empty. Pink still deals 2 direct damage to Spoonbills.
- Cuckoo echoes, Plover retreat, simultaneous damage, hatch order, cash, retries, shop access, and one request-to-resolver pathway remain unchanged.
- Recruitment, retirement, merging, and factory upgrades share one post-success shop. A merge consumes two matching birds and cash equal to its output tier.
- Daily randomness remains seeded and equal retries reproduce initial and recycled shuffles and hidden outcomes.

### Hypothesis

One stable track should let the player read circuits and egg movement immediately. Moving an unhatched egg into a visible bin converts permanent loss into a tempo cost: the egg retains damage, but the player must clear both the hopper and conveyor and accept a new seeded order before seeing it again.

Keeping all three levers active should make conveyor position an intentional resource instead of letting occupancy silently choose the legal actions. An empty pull may improve the next alignment, but its full one-thwack cost must keep it from becoming free cycling.

A starting pool exactly as large as the track should make the complete composition learnable and force recycling to matter without the bookkeeping of a fifteen-egg hopper. The 8-point opening target permits either all three Chickens or two Chickens plus both Cuckoos; the 9-point later target remains reachable after merging two Chickens into one 4-point Prize Chicken. Ten thwacks should preserve urgency and keep unused-thwack cash proportional to the shorter puzzle.

Quality should make one egg denser rather than simply better. Two same-tier eggs become one next-tier egg with 1.5 times each input's exact score, maximum toughness, and Double Yolker chance. The output loses 25% of the pair's aggregate score, shell, and effect frequency, but its smaller flock cycles more quickly through the recycler.

### Implemented prototype scope

- One five-slot conveyor and the same three circuits on every day; the Day 3 hairpin and refit are removed.
- Every visible lever is usable throughout an unlocked day. A completely empty circuit fires its linked spoons, advances the conveyor, and spends one thwack without damage.
- A visible bin count beside the final slot.
- Resolver events for an egg entering the bin, the complete bin reshuffling into an empty hopper, and the next egg entering slot 1.
- Binned eggs retain remaining toughness, tier, score, Double Yolker result, and every other egg fact.
- The injected shuffler owns every recycle order, preserving deterministic retries.
- Existing hopper eggs feed normally, but the bin cannot reshuffle until the conveyor is empty; a recycled wave never joins eggs still travelling from the previous wave.
- Quality uses exact `1.5^tier` multiplication for score, maximum toughness, and Double Yolker chance.
- Gameplay score and displayed percentages floor to whole numbers. Maximum toughness rounds up to the whole amount of damage actually required. Later tiers retain exact values.
- Merge source and partner views show the output's points, shell toughness, Double Yolker percentage, fee, and projected flock size.
- Existing production loading shows the scaled toughness of the egg each quality tier lays.
- The default flock contains three Chickens and two Cuckoos, with ten starting thwacks, an 8-point Day 1 target, and a 9-point later target.

### Balancing constraints

- Recycling removes permanent belt loss but not the 10-thwack limit.
- Empty strikes create a positioning option, but each consumes 10% of the complete day budget and can accelerate eggs toward the bin without scoring.
- Five eggs form a natural capacity breakpoint. Larger flocks carry more total score but delay a recycled wave; smaller flocks clear sooner but give up score slack and simultaneous circuit or echo opportunities.
- The unmerged starting flock contains 11 total base points. Day 1's 8-point target supports two scoring routes; the later 9-point target leaves two points of composition slack.
- Merging two starting Chickens produces a 4-point Prize Chicken and reduces the flock's total displayed value to 9, exactly the later-day target before recruitment or retirement.
- A small flock cycles more often, but can still fail by hatching every available egg below the target.
- A merge converts pair totals of `2V` and `2T` into one egg at `1.5V` and `1.5T`, before visible rounding.
- Rounding makes some first-tier ratios uneven. A Prize Chicken requires 5 damage and awards 4 points from exact values of 4.5 and 4.5.
- A Prize Cuckoo currently requires 6 damage but remains worth 1 displayed point and has no Double Yolker chance. This may be an obvious trap unless faster cycling or later content supplies a strategic payoff; do not add a species exception without playtest evidence.
- Positive feedback from efficient play into greater purchasing power remains intentional. Guard against a deterministic retry that cannot reach the shop.

### Explicitly deferred

- Further target, thwack, toughness, score, merge-fee, recruitment-price, and retirement-price tuning after playtest evidence.
- Bin capacity, player-controlled rerolls, selective retrieval, damage healing, or bin upgrades.
- Hybrid and cross-species recipes, inherited effects, authored hybrid art, and merging unlike tiers.
- Random shop stock, a campaign map, shop rerolls, discounts, selling, elite conditions, and production art.
- A replacement for the removed Day 3 factory milestone or any positional spoon-upgrade ladder.

### Exit evidence

- Domain tests prove damage-preserving bin transfer, clear-conveyor recycle gating, empty-circuit advancement and thwack spending, resolver event order, deterministic reshuffle, slot-1 refill, quality toughness scaling, and whole required-damage rounding.
- Session tests prove the default five-egg flock, ten-thwack budget, 8/9 targets, five slots and three circuits, saved-cash shop progression, scaled merge offers, and deterministic failure/retry behavior.
- UI tests prove the starting flock counts and day budget are visible, all three levers remain available during unlocked day play, an empty strike fires both linked spoons and presents its ordered resolution, the bin is visible, the recycle sequence plays in resolver order, the returned egg keeps its cracks, merged shells show their required damage, Day 3 keeps the learned track, and cancellation/input-lock contracts still hold.
- The 2026-08-16 automated strategy probe supplies an exact-search and heuristic baseline for empty-pull value, current Day 1 ease, target-9 pressure, the post-merge flock, a nine-thwack alternative, and the rejected +1 starting-toughness direction. It is not human fun or comprehension evidence.
- A running-game check at 1280×720 and 1024×576 must verify the bin reads as the conveyor destination, the bin and hopper counts remain legible, recycled eggs visibly return through the pipe, and no removed hairpin controls leave empty or overlapping space.
- Play one seeded run through at least two shop decisions and Day 3. Record whether the player intentionally lets any egg recycle, whether they understand that cracks persist, which legal merges they accept or refuse, and whether a tougher merged egg feels concentrated or merely slower.
