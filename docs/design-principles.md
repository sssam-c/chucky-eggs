# Design principles

These principles interpret the current rules. They guide choices but do not override `game-rules.md`.

## Decisions before decoration

Prototype the smallest interaction that can answer a design question. Add content, polish, and abstraction only when they improve the learning signal or the player experience being tested.

## Consequences stay legible

Show the state, cost, and likely consequence needed for a meaningful choice. Do not conceal essential rules behind animation, flavor text, or uninspectable randomness.

Every producer contributes exactly one egg to the daily pool. Keep that one-bird, one-egg relationship visible so flock size, pool size, additions, removals, and shuffle odds can be reasoned about directly. Producer offers must show the contributed egg's complete gameplay properties.

Flock growth must be chosen rather than awarded compulsorily. Recruiting another bird should compete with merging or retiring birds, strengthening the factory, or saving cash, so a larger daily pool reflects the player's build direction rather than unavoidable accumulation.

Quality belongs to interchangeable species-and-tier groups, not named individuals. A merge must expose both what improves and what is consumed: two matching daily eggs become one egg with 1.5 times their exact individual value. Queue merges until the player leaves the shop so a newly produced bird cannot immediately feed another tier and erase the decision cadence.

Show whole-number consequences wherever the player makes or resolves a choice. Floor score values and displayed percentage chances, but compound future quality tiers and roll randomness from the exact internal values. The interface should never imply that the displayed integer became the new mathematical base.

Show the next day's target whenever recruitment is offered. The player should evaluate flock growth against the demand it must answer rather than discovering that demand after committing.

Use the transition between days to demonstrate where the next hopper comes from. Showing each owned animal beside the eggs it contributes makes flock growth, dilution, and daily output physical consequences rather than spreadsheet facts.

## Rules resolve once

A game rule has one canonical owner. The domain resolves it and records ordered facts. UI and presentation explain those facts without recalculating them.

## Damage batches stay legible

When one physical strike damages several eggs, apply and show its complete direct-and-echo batch before resolving any hatch. Preserve conveyor order for simultaneous hatch effects. A mechanism with explicitly ordered strikes may resolve between contacts, but that order must be a visible resolver-authored rule rather than animation timing.

## Circuits turn position into the choice

The player chooses a fixed spoon control rather than an isolated egg. Red and Blue alternate across the starting line and remain in those positions on the hairpin's upper run: Red 1+3 and Blue 2+4. Green 7+9 and Purple 8+10 mirror that rhythm across the lower return, while Pink alone bridges the bend at 5+6. An egg therefore changes circuit ownership repeatedly as it travels instead of remaining in one screen column's control. Every action retains a two-target ceiling. Show every connected position before commitment and let empty strikes remain visibly wasted.

All line layouts share one authored spoon-landing sequence: the upright bowl foreshortens to a narrow brass-edged band, reveals its dark underside, and lands bowl-first while egg occlusion tucks the shaft behind the shell. Day 3 preserves one bowl per column and adds a visibly segmented handle whose reach is selected before the throw.

On the hairpin, restore the established five single-spoon silhouette. In the first four columns, an upper-run circuit fires the column's spoon once at its short reach, while a lower-return circuit extends that same spoon and fires it once at its long reach. There is never a second parked bowl or a second impact from one ordinary spoon. Pink is the deliberate exception: its fifth spoon extends to lower slot 6, resolves that contact completely, returns and retracts, then makes a second bowl-first throw onto upper slot 5. This unique two-stage motion makes the unique sequential rule inspectable. Empty contacts still thwack visibly. Do not put eggs in buckets, and keep the conveyor casings touching so both rows read as one compact machine.

Present input as physical levers rather than labelled button faces. Put circuit colour into the belt sections beneath the targets, not the spoons or separate pads: the coloured conveyor bays show ownership at both rows, while neutral utensils honestly communicate that one physical spoon may serve an upper and a lower circuit. Lever mappings expose which two spaces a circuit selects. Pink's spark identifies both the bend control and the only circuit-specific weakness. The shared upright resting language and Pink's complete two-stage motion should make the operated machinery feel causally connected.

Circuit-specific weaknesses should create a positional objective, not a universally superior button. Spoonbill rewards planning toward Pink: one final-slot chance on the starting line becomes the paired bend positions 5+6 on the hairpin. Pink's double damage remains species-specific while every hairpin lever has the same two-bay reach.

## Conveyor relationships follow the route

Terms such as ahead, behind, and adjacent refer to conveyor order rather than screen distance. The full belt travels right through slots 1–5, through an untargetable bend, and left through slots 6–10, so its route arrows, slot numbers, overhead columns, and drop must make that ordering unmistakable.

Plover is the deliberate exception: “left” means screen-left, not backward along the route. Its top-row and bottom-row retreats therefore use different route directions, and the leftmost bay of each row has no retreat destination. Position-changing effects must expose their source, destination, and ordering relative to the standard conveyor advance. Their animation explains a resolver-authored move; it never chooses which eggs move.

## Determinism makes iteration faster

Seed randomness, inject time, and make state transitions replayable. A surprising playtest should be reproducible before it is tuned.

## Efficiency becomes future agency

End the day automatically once a fully resolved thwack meets the target, then convert every unused thwack into cash. This makes speed-to-target valuable without adding a separate cash-out decision or allowing failed-day farming. Keep the current balance and each payout visible so later shop choices can be understood as consequences of earlier play.

Use one shop for optional run progression. Cash remains the shared opportunity cost for recruitment, retirement, and factory upgrades; matching birds themselves pay for merges. Permit multiple legal actions and allow the player to leave with unspent cash. Positive feedback is an intended roguelike reward, but a merge should remain a real quantity-versus-quality choice: it reduces flock size and daily effect frequency while concentrating the surviving egg's value. Guard against universally dominant actions and genuinely unwinnable retry states rather than flattening successful builds.

## Machine growth preserves its grammar

Let flock growth create visible pressure on the original machine, then answer it with a universal physical milestone the player can inspect before the next hopper loads. Fold the conveyor into two touching five-bay runs rather than shrinking a longer straight line into the old footprint. Preserve the learned alternating Red and Blue rhythm, mirror it with Green and Purple on the return, and give Pink the unique bend-spanning role. Capacity grows while maximum direct reach remains two eggs per thwack. Machine changes this consequential should not compete with ordinary shop stock.

## Physicality follows causality

Motion, sound, and staging should clarify what caused what. Presentation may slow down or emphasize resolved events, but it must not become a hidden rules engine.

## Accessibility is part of the interaction

Keyboard focus, dismissal, readable type, and non-color-only states are design constraints, not a final polish pass.
