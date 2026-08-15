# Design principles

These principles interpret the current rules. They guide choices but do not override `game-rules.md`.

## Decisions before decoration

Prototype the smallest interaction that can answer a design question. Add content, polish, and abstraction only when they improve the learning signal or the player experience being tested.

## Consequences stay legible

Show the state, cost, and likely consequence needed for a meaningful choice. Do not conceal essential rules behind animation, flavor text, or uninspectable randomness.

Every producer contributes exactly one egg to the daily pool. Keep that one-bird, one-egg relationship visible so flock size, pool size, additions, removals, and shuffle odds can be reasoned about directly. Producer offers must show the contributed egg's complete gameplay properties.

Show the next day's target on the producer draft. The player should evaluate flock growth against the demand it must answer rather than discovering that demand after committing.

Use the transition between days to demonstrate where the next hopper comes from. Showing each owned animal beside the eggs it contributes makes flock growth, dilution, and daily output physical consequences rather than spreadsheet facts.

## Rules resolve once

A game rule has one canonical owner. The domain resolves it and records ordered facts. UI and presentation explain those facts without recalculating them.

## Damage batches stay legible

When one physical strike damages several eggs, apply and show its complete direct-and-echo batch before resolving any hatch. Preserve conveyor order for simultaneous hatch effects. A mechanism with explicitly ordered strikes may resolve between contacts, but that order must be a visible resolver-authored rule rather than animation timing.

## Circuits turn position into the choice

The player chooses a fixed spoon control rather than an isolated egg. On the starting line, Red and Blue alternate while Pink concentrates damage at the edge: Red 1+3, Blue 2+4, and Pink 5. On the hairpin, the refit deliberately replaces those shared circuits with five independent paired columns: Red 1+10, Blue 2+9, Green 3+8, Purple 4+7, and Pink 5+6. Every hairpin action therefore retains a two-target ceiling while gaining more positional precision. Show every connected position before commitment and let empty strikes remain visibly wasted.

All line layouts share one authored spoon-landing sequence: the upright bowl foreshortens to a narrow brass-edged band, reveals its dark underside, and lands bowl-first while egg occlusion tucks the shaft behind the shell. Day 3 extends that familiar single-bowl language with a visibly segmented handle rather than introducing a second utensil silhouette.

On the hairpin, use one familiar spoon per screen column. The spoon is pinned to the wall at its handle base and tips straight toward the player. Pull the lever first, then visibly telescope the still-upright spoon on the wall. It slams onto the lower, visually nearer row and holds while that contact resolves completely. It then performs a full return to the wall, retracts while upright, and makes a second complete bowl-first throw onto the upper, visually farther row. This repeated wall-to-egg action makes both rule timing and physical identity inspectable: the player sees one bowl perform two distinct thwacks, never a bowl sliding between eggs or two disconnected spoons. Empty contacts still thwack visibly. Do not put eggs in buckets. Keep the upper and lower conveyor casings touching so the return reads as one compact machine rather than two remote rows.

Present input as physical levers rather than labelled button faces. Days 1–2 use the three established circuit levers. The hairpin places five levers directly beneath their spoons and gives each a separate coloured conduit and symbol. Green and Purple currently distinguish column controls rather than promising additional damage rules; Pink's spark remains the only circuit-specific weakness. Spatial alignment and the two complete wall-to-egg slams should make the operated machinery feel causally connected.

Circuit-specific weaknesses should create a positional objective, not a universally superior button. Spoonbill rewards planning toward Pink: one final-slot chance on the starting line becomes the paired bend positions 5+6 on the hairpin. Pink's double damage remains species-specific while every hairpin lever has the same two-bay reach.

## Conveyor relationships follow the route

Terms such as ahead, behind, and adjacent refer to conveyor order rather than screen distance. The full belt travels right through slots 1–5, through an untargetable bend, and left through slots 6–10, so its route arrows, slot numbers, overhead columns, and drop must make that ordering unmistakable.

Plover is the deliberate exception: “left” means screen-left, not backward along the route. Its top-row and bottom-row retreats therefore use different route directions, and the leftmost bay of each row has no retreat destination. Position-changing effects must expose their source, destination, and ordering relative to the standard conveyor advance. Their animation explains a resolver-authored move; it never chooses which eggs move.

## Determinism makes iteration faster

Seed randomness, inject time, and make state transitions replayable. A surprising playtest should be reproducible before it is tuned.

## Efficiency becomes future agency

End the day automatically once a fully resolved thwack meets the target, then convert every unused thwack into cash. This makes speed-to-target valuable without adding a separate cash-out decision or allowing failed-day farming. Keep the current balance and each payout visible so later shop choices can be understood as consequences of earlier play.

## Machine growth preserves its grammar

Let flock growth create visible pressure on the original machine, then answer it with a universal physical milestone the player can inspect before the next hopper loads. Fold the conveyor into two touching five-bay runs rather than shrinking a longer straight line into the old footprint. Preserve the five learned spoon columns and keep the bend free of targets. Make the refit's control change physical by replacing shared buses with five independent spoon conduits: capacity grows while maximum direct reach remains two eggs per thwack. Treat each complete utensil as one future tool socket; replacing upper and lower bowls independently is outside the current positional grammar. Machine changes this consequential should not compete with ordinary shop stock.

## Physicality follows causality

Motion, sound, and staging should clarify what caused what. Presentation may slow down or emphasize resolved events, but it must not become a hidden rules engine.

## Accessibility is part of the interaction

Keyboard focus, dismissal, readable type, and non-color-only states are design constraints, not a final polish pass.
