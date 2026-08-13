# Design principles

These principles interpret the current rules. They guide choices but do not override `game-rules.md`.

## Decisions before decoration

Prototype the smallest interaction that can answer a design question. Add content, polish, and abstraction only when they improve the learning signal or the player experience being tested.

## Consequences stay legible

Show the state, cost, and likely consequence needed for a meaningful choice. Do not conceal essential rules behind animation, flavor text, or uninspectable randomness.

Flock additions must show both the egg's gameplay properties and the producer's full daily yield. A frequent producer changes shuffle odds more than a rare one, so presenting only egg strength would hide part of the choice.

Show the next day's target on the producer draft. The player should evaluate flock growth against the demand it must answer rather than discovering that demand after committing.

Use the transition between days to demonstrate where the next hopper comes from. Showing each owned animal beside the eggs it contributes makes flock growth, dilution, and daily output physical consequences rather than spreadsheet facts.

## Rules resolve once

A game rule has one canonical owner. The domain resolves it and records ordered facts. UI and presentation explain those facts without recalculating them.

## Damage batches stay legible

When one action damages several eggs, apply and show the complete damage batch before resolving any hatch. Preserve conveyor order for simultaneous hatch effects so combinations remain predictable rather than depending on animation timing.

## Circuits turn position into the choice

The player chooses a fixed spoon circuit rather than an isolated target. Red alternates across slots 1 and 3, Blue across slots 2 and 4, and Pink offers a less efficient but precise final chance in slot 5. Show every connected spoon before commitment and let empty strikes remain visibly wasted.

Circuit-specific weaknesses should create a positional objective, not a universally superior button. Spoonbill rewards planning toward Pink's slot 5, where its concentrated double damage can equal Red or Blue's total output while giving up their distribution across two eggs.

## Conveyor relationships follow the route

Terms such as ahead, behind, and adjacent refer to conveyor order rather than screen distance. If the belt later folds or loops, presentation must show the route clearly enough that these relationships remain predictable.

Position-changing effects must expose their source, destination, and ordering relative to the standard conveyor advance. Their animation explains a resolver-authored move; it never chooses which eggs move.

## Determinism makes iteration faster

Seed randomness, inject time, and make state transitions replayable. A surprising playtest should be reproducible before it is tuned.

## Efficiency becomes future agency

End the day automatically once a fully resolved thwack meets the target, then convert every unused thwack into cash. This makes speed-to-target valuable without adding a separate cash-out decision or allowing failed-day farming. Keep the current balance and each payout visible so later shop choices can be understood as consequences of earlier play.

## Physicality follows causality

Motion, sound, and staging should clarify what caused what. Presentation may slow down or emphasize resolved events, but it must not become a hidden rules engine.

## Accessibility is part of the interaction

Keyboard focus, dismissal, readable type, and non-color-only states are design constraints, not a final polish pass.
