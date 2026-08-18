# Design principles

These principles interpret the current rules. They guide choices but do not override `game-rules.md`.

## Decisions before decoration

Prototype the smallest interaction that can answer a design question. Add content, polish, and abstraction only when they improve the learning signal or the player experience being tested.

## Consequences stay legible

Show the state, cost, and likely consequence needed for a meaningful choice. Do not conceal essential rules behind animation, flavor text, or uninspectable randomness.

Every producer contributes exactly one egg to the daily pool. Keep that one-bird, one-egg relationship visible so flock size, pool size, additions, removals, and shuffle odds can be reasoned about directly. Bird offers and flock cards must show the contributed egg's complete gameplay properties.

Begin with eight eggs: three Chickens, two Cuckoos, and three Sparrows. One-hit Sparrows establish the hatch-and-score payoff immediately and their elevated Double Yolker chance introduces visible jackpots early. The pool extending beyond the five-slot track keeps new eggs arriving while the player learns to weigh quick Sparrow points, durable Chicken value, and Cuckoo echoes.

Successful days now grow the flock by one bird. Preserve agency inside that compulsory growth by offering three legible alternatives on a dedicated reward screen. After that decision is complete, let the player enter the separate shop and spend £3 to remove an exact bird from the complete flock overview. Keeping reward and correction in distinct screens gives each decision one clear job; the overview should make the resulting daily pool understandable without routing removal through a separate species list.

Use one fixed set of egg facts per species while the first balance baseline is being learned. Bird rewards should compare species, effects, shell toughness, Yolk, and intrinsic Double Yolker chance without quality tiers, merge arithmetic, or rarity framing. Reintroduce numerical progression only when it has a demonstrated job that the species-and-flock choices do not already perform.

Show the next day's appetite with the bird reward and flock overview. Use the transition between days to demonstrate where the next hopper comes from: each owned bird contributes exactly one egg.

Give the abstract daily target a visible recipient. Present awarded egg points as proportional progress toward Grandma's appetite, while retaining the exact numeric value for overflow and non-colour readability. Group Grandma, appetite progress, and settings in one right-hand machine rail, but mount the prominent Belt Condition bar on the conveyor housing whose wear it represents. These controls own only presentation: the session remains the canonical owner of score, target, Belt Condition, and day-end resolution. Reserve Grandma's portrait area for replaceable animation, status, and dialogue without letting those timings decide gameplay.

Keep Yolk, Satisfaction, Appetite, and Belt Condition separate in the domain even where the interface can stay compact. Appetiser modifies Yolk only when a later egg hatches. Sulphurous suppression permanently lowers effective Appetite for the current day without becoming Satisfaction, while conveyor movement spends Belt Condition. Show the food distinction spatially: Yolk fills the appetite meter from the left and green suppression fills it from the right, with the reduced numeric denominator and written status carrying the same fact without relying on colour. This vocabulary lets effects compose without using an unrelated number as an implementation shortcut.

Give each current reusable hatch effect one signature permanent species so a reward communicates both a bird identity and a tactical promise. Keep the original eight-bird starting flock unchanged. Movement-effect eggs may remain plainly named Oily, Nostalgic, and Gloopy while their feel is being learned; do not spend fiction or species design before the interaction earns it.

Spend the workshop's permanent screen area on existing play objects rather than decorative machinery or invented readouts. Give the three-egg hopper preview, five spoon lanes, and inspectable bin enough physical presence to explain the machine at a glance. Treat the hopper as a bottom-anchored lift on the same deck line as the bin: put its inspection control on the bottom loading deck, raise previews toward the upper exit, then push the top egg sideways onto the conveyor. Give moving eggs a clearly readable backward lean followed by a damped counter-wobble before they settle upright. The track curves only after slot five into the bin. This routing and motion visualize existing facts without suggesting another slot or score-delivery system.

## Rules resolve once

A game rule has one canonical owner. The domain resolves it and records ordered facts. UI and presentation explain those facts without recalculating them.

## Damage batches stay legible

When one physical strike damages several eggs, apply and show its complete direct-and-echo batch before resolving any hatch. Preserve conveyor order for simultaneous hatch effects.

Treat secondary strikes as resolver-authored damage batches. Carry their originating circuit identity, finish every resulting hatch and chain before belt movement, and guard every egg's on-hatch resolution exactly once.

## One track makes position readable

Use the same five-slot route and the same Red 1+3, Blue 2+4, and Pink 5 circuits every day. The stable topology lets egg behavior, build composition, and timing create the changing problem. Show every connected position before commitment and keep every lever active during an unlocked day. Let an empty circuit act as a legible tempo choice: its spoons still fire, the conveyor advances, and the thwack is visibly spent without dealing damage.

All spoons share one authored bowl-first landing sequence. Present input as physical levers and put circuit colour into the belt sections beneath their targets. Pink's spark identifies both the final-slot control and the only circuit-specific weakness.

Circuit-specific weaknesses should create a positional objective, not a universally superior button. Spoonbill rewards planning toward Pink's single final-slot opportunity.

## Falling changes order rather than deleting strategy

An egg that leaves slot 5 enters a visible bin with its damage intact. Existing hopper eggs continue feeding slot 1 normally; as soon as that hopper empties—including when its last egg has just entered the conveyor—the bin becomes a new shuffled hopper even while other eggs remain on the conveyor. Falling therefore changes future order without forcing several low-agency clearing actions. It can refill the pipe immediately, but never creates extra movement or a free strike.

Treat five eggs as the machine's natural opening capacity rather than a mandatory deck size. Begin with up to five shuffled eggs already on the track so the first lever choice exposes its paired positions. A larger flock adds scoring capacity and a longer initial hopper; a smaller flock sacrifices score slack, paired-strike coverage, and Cuckoo adjacency.

Keep hopper preview and bin count visible. The resolver owns bin transfer, reshuffle, and entry order; their animation explains facts already decided. Seed every shuffle so the same retry reproduces the same sequence.

## Determinism makes iteration faster

Seed randomness, inject time, and make state transitions replayable. A surprising playtest should be reproducible before it is tuned.

## Belt movement becomes future agency

End the day automatically once a fully resolved thwack meets the target and pay a fixed £3. Keep economy tuning separate from the combat-loop question until Belt Condition progression has enough content to support a performance-sensitive reward. One highly visible Condition bar is the unified day clock, and each committed thwack costs 1 after every movement instruction resolves. Charging the action rather than displacement lets Gloopy change position without becoming free time, while Oily and Nostalgic can reshape the belt without multiplying the Condition cost.

Treat movement effects as a short visible program. Capture instructions only from the original direct targets, read them left to right, append normal movement, and let the domain resolve every Jam and boundary crossing. Show both the symbols and their written cancellation result before commitment; presentation may animate that authored queue but never reconstruct it.

Keep Gloopy an enabler rather than a scoring route. Its thin shell limits how often one egg can hold the belt, while its foul negative Yolk makes a Gloopy-heavy flock move away from victory. Allow Satisfaction to fall below zero so resolving foul eggs early cannot erase their cost. Appetiser remains a positive-Yolk effect and should neither improve nor consume itself on foul Yolk.

Keep the current shop deliberately narrow: removing one selected bird costs £3, is limited to once per successful night, and can never remove the last bird. Saving remains a valid choice. This makes cash a measured correction to compulsory daily growth without allowing one rich visit to rebuild the whole flock.

## Physicality follows causality

Motion, sound, and staging should clarify what caused what. Presentation may slow down or emphasize resolved events, but it must not become a hidden rules engine.
