# Current game rules

This file is the canonical player-facing rule truth. Keep it current and concise. Put rationale in `decision-log.md`, interpretation in `design-principles.md`, prototype scope in `vertical-slices.md`, and observations in `playtest-log.md`.

## Game promise

Choose which eggs deserve the spoon while every thwack carries the whole conveyor closer to the edge. Crack enough eggs to meet the day's target, knowing that saving every egg is impossible.

## Objective and end states

- A day lasts exactly 20 thwacks.
- Hatch eggs to score at least 10 points by the end of the day.
- The day succeeds at 10 or more points and fails below 10 points.
- After the twentieth thwack resolves, all eggs left on the conveyor or in the pipe are discarded without scoring.

## Player loop

Inspect the five conveyor slots, the next three eggs in the pipe, the score, and the visible thwack countdown. Choose a spoon circuit, balancing the eggs it can damage against how close every egg is to the end.

## Setup and state

- The conveyor has five ordered slots. Slot 1 receives eggs and slot 5 is beside the drop.
- The day begins with one chicken egg in slot 1 and a fixed authored sequence of Chicken, Cuckoo, Plover, and Spoonbill eggs in the pipe.
- A Chicken egg has 3 toughness and is worth 3 points when hatched.
- A Cuckoo egg has 4 toughness and is worth 1 point when hatched.
- A Plover egg has 6 toughness and is worth 2 points when hatched.
- A Spoonbill egg has 5 toughness, is worth 4 points when hatched, and takes 2 damage from a direct Pink strike instead of 1.
- The pipe is continuously supplied from the same repeating authored sequence, always shows the next three eggs, and drops one into slot 1 after each non-final thwack.
- Egg toughness, current score, and remaining thwacks are always visible.

## Actions and resolution

Each turn, the player must activate one available spoon circuit:

- Red fires the spoons over slots 1 and 3.
- Blue fires the spoons over slots 2 and 4.
- Pink fires the spoon over slot 5.
- Each fired spoon normally deals 1 damage to the egg beneath it. Pink deals 2 direct damage to a Spoonbill. A spoon over an empty slot still fires but its damage is wasted.
- A circuit is available when at least one of its spoons is over an egg.

Resolve the thwack in this order:

1. Fire every spoon in the chosen circuit and reduce the toughness of every egg beneath those spoons by 1 as one simultaneous direct-damage batch.
2. For each directly damaged egg, reduce the toughness of every Cuckoo immediately ahead of or behind it by the same amount. A Cuckoo beside a Pink-struck Spoonbill therefore takes 2 echo damage.
3. Apply the entire damage batch before resolving hatches. Cuckoo echo damage does not create further echoes.
4. Hatch every egg that reached 0 toughness in conveyor order, remove it, and gain its points.
5. In conveyor order, each surviving directly struck Plover outside slot 1 swaps with the contents of the slot immediately behind it, toward the pipe.
6. Advance every surviving conveyor egg one slot.
7. Discard any egg that moves past slot 5 without scoring.
8. Spend one of the day's 20 thwacks.
9. If the day continues, drop the next pipe egg into slot 1 and refill the visible pipe preview.

Hatching an egg never prevents the conveyor from advancing. Partially damaged eggs retain their remaining toughness until they hatch or are discarded.

## Exceptions and glossary

- **Thwack:** The player's single action for a turn and the unit of day time.
- **Spoon circuit:** A fixed group of one or more colour-matched spoons that always fire together.
- **Toughness:** The number of further thwacks an egg needs before it hatches.
- **Adjacent:** Immediately ahead of or behind an egg in conveyor order. Visual proximity does not create adjacency.
- **Behind:** One slot closer to the pipe in conveyor order.
- **Echo damage:** Damage copied by a Cuckoo when an adjacent egg receives damage. Each damaged adjacent egg creates one echo on that Cuckoo; echo damage never echoes again.
- **Spark weakness:** The four-point spark on a Spoonbill matches Pink's circuit symbol. A direct Pink strike deals 2 damage to it; Red, Blue, and echo damage still deal their normal amounts.
- **Plover retreat:** A surviving Plover directly struck by a circuit outside slot 1 swaps with the egg or empty space immediately behind it. Cuckoo echoes use the positions from before any retreat. The normal conveyor advance still follows.
- **Discarded:** Removed without hatching or awarding points.
