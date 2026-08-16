# Design principles

These principles interpret the current rules. They guide choices but do not override `game-rules.md`.

## Decisions before decoration

Prototype the smallest interaction that can answer a design question. Add content, polish, and abstraction only when they improve the learning signal or the player experience being tested.

## Consequences stay legible

Show the state, cost, and likely consequence needed for a meaningful choice. Do not conceal essential rules behind animation, flavor text, or uninspectable randomness.

Every producer contributes exactly one egg to the daily pool. Keep that one-bird, one-egg relationship visible so flock size, pool size, additions, removals, and shuffle odds can be reasoned about directly. Bird offers and flock cards must show the contributed egg's complete gameplay properties.

Begin with eight eggs: three Chickens, two Cuckoos, and three Sparrows. One-hit Sparrows establish the hatch-and-score payoff immediately and their elevated Double Yolker chance introduces visible jackpots early. The pool extending beyond the five-slot track keeps new eggs arriving while the player learns to weigh quick Sparrow points, durable Chicken value, and Cuckoo echoes.

Successful days now grow the flock by one bird. Preserve agency inside that compulsory growth by offering three legible alternatives on a dedicated reward screen. After that decision is complete, let the player enter the separate shop and spend £3 to remove an exact bird from the complete flock overview. Keeping reward and correction in distinct screens gives each decision one clear job; the overview should make the resulting daily pool understandable without routing removal through a separate species list.

Quality belongs to species-and-tier facts rather than named-bird progression. A day reward can arrive at any quality, so each candidate must expose its whole required damage, points, and percentage before commitment. Keep Standard visually neutral, accent Prize in green, and accent Champion and higher in blue while retaining written quality labels. Higher tiers continue to compound from exact internal values even though the player sees whole-number consequences.

Show whole-number consequences wherever the player makes or resolves a choice. Floor score values and displayed percentage chances, round maximum toughness up to the damage actually required, and compound later quality tiers from exact internal values. The interface should never imply that a displayed integer became the new mathematical base.

Show the next day's target with the bird reward and flock overview. Use the transition between days to demonstrate where the next hopper comes from: each owned bird contributes exactly one egg.

## Rules resolve once

A game rule has one canonical owner. The domain resolves it and records ordered facts. UI and presentation explain those facts without recalculating them.

## Damage batches stay legible

When one physical strike damages several eggs, apply and show its complete direct-and-echo batch before resolving any hatch. Preserve conveyor order for simultaneous hatch effects.

## One track makes position readable

Use the same five-slot route and the same Red 1+3, Blue 2+4, and Pink 5 circuits every day. The stable topology lets egg behavior, build composition, and timing create the changing problem. Show every connected position before commitment and keep every lever active during an unlocked day. Let an empty circuit act as a legible tempo choice: its spoons still fire, the conveyor advances, and the thwack is visibly spent without dealing damage.

All spoons share one authored bowl-first landing sequence. Present input as physical levers and put circuit colour into the belt sections beneath their targets. Pink's spark identifies both the final-slot control and the only circuit-specific weakness.

Circuit-specific weaknesses should create a positional objective, not a universally superior button. Spoonbill rewards planning toward Pink's single final-slot opportunity.

## Falling spends time rather than deleting strategy

An egg that leaves slot 5 enters a visible bin with its damage intact. Existing hopper eggs continue feeding slot 1 normally, but the bin waits until both hopper and conveyor are empty before becoming a new shuffled hopper. Falling therefore changes future order and spends limited thwacks without erasing prior damage.

Treat five eggs as the machine's natural capacity rather than a mandatory deck size. A larger flock adds scoring capacity but postpones the next recycled wave; a smaller flock clears sooner but sacrifices score slack, paired-strike coverage, and Cuckoo adjacency. Preserve that tension instead of imposing an arbitrary minimum flock size.

Keep hopper preview and bin count visible. The resolver owns bin transfer, reshuffle, and entry order; their animation explains facts already decided. Seed every shuffle so the same retry reproduces the same sequence.

## Determinism makes iteration faster

Seed randomness, inject time, and make state transitions replayable. A surprising playtest should be reproducible before it is tuned.

## Efficiency becomes future agency

End the day automatically once a fully resolved thwack meets the target, then convert every unused thwack into cash. The ten-thwack budget keeps the eight-egg opening tense and prevents the compact starting flock from generating the oversized payouts of the former twenty-thwack day. This makes speed-to-target valuable without adding a separate cash-out decision or allowing failed-day farming. Keep the current balance and each payout visible so later shop choices can be understood as consequences of earlier play.

Keep the current shop deliberately narrow: removing one selected bird costs £3, is limited to once per successful night, and can never remove the last bird. Saving remains a valid choice. This makes cash a measured correction to compulsory daily growth without allowing one rich visit to rebuild the whole flock, and avoids a second list that obscures which quality is being removed.

## Physicality follows causality

Motion, sound, and staging should clarify what caused what. Presentation may slow down or emphasize resolved events, but it must not become a hidden rules engine.
