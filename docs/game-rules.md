# Current game rules

This file is the canonical player-facing rule truth. Keep it current and concise. Put rationale in `decision-log.md`, interpretation in `design-principles.md`, prototype scope in `vertical-slices.md`, and observations in `playtest-log.md`.

## Game promise

Choose which eggs deserve the spoon while every thwack carries the whole conveyor closer to the edge. Crack enough eggs to meet the day's target, knowing that saving every egg is impossible.

## Objective and end states

- A day lasts at most 20 thwacks and ends immediately after a resolved thwack meets the score target. It can also end earlier when no eggs remain in either the hopper or conveyor.
- Hatch eggs to meet the current day's target: 15 points on Day 1 and 20 points on each later day.
- A day succeeds at or above its target and fails below it.
- When a successful day ends, gain £1 for each unused thwack remaining after the target-reaching thwack is spent. Add it to the run's persistent cash balance.
- A failed day awards no cash.
- Whenever a day ends, all eggs left on the conveyor or in the hopper are discarded without scoring.

## Player loop

Inspect the current conveyor route, the next three eggs in the pipe, the score, and the visible thwack countdown. Choose an available spoon control, balancing the eggs it can damage against how close every egg is to the end.

After a successful day, bank the unused-thwack payout, inspect three distinct producer offers, and add exactly one to the flock. Then visit the workshop before the expanded flock loads the next day's newly shuffled pool. A failed day awards no cash or producer and is retried with the same flock and shuffle.

## Setup and state

- Days 1 and 2 use five ordered conveyor slots. Slot 1 receives eggs and slot 5 begins beside the drop.
- Before Day 3, every run receives an automatic, free factory refit. It is a progression milestone rather than a shop purchase and remains installed for later days.
- The refitted conveyor has ten ordered slots in a tight screen-width hairpin. Slots 1–5 travel left-to-right across the upper run, the untargetable bend carries eggs downward, and slots 6–10 return right-to-left underneath. The drop is beside slot 10.
- The hairpin has five independent wall-hinged telescoping spoons, one per screen column. After its lever is pulled, each ordinary single bowl extends while upright on the wall, slams onto the lower, visually nearer bay, returns upright, retracts on the wall, then slams onto the aligned upper, visually farther bay. Eggs sit directly on the two touching conveyor runs; the bend contains no egg bay.
- The starting flock has ten Chicken producers, three Cuckoo producers, and two Plover producers.
- Every producer lays exactly one egg per day, so the starting flock produces a daily pool of 15 eggs.
- Shuffle the complete daily pool once, load its first egg into slot 1, and place the rest in the finite hopper. Do not reshuffle during the day.
- A Chicken egg has 3 toughness and is worth 3 points when hatched.
- A Cuckoo egg has 4 toughness and is worth 1 point when hatched.
- A Plover egg has 6 toughness and is worth 4 points when hatched.
- A Spoonbill egg has 5 toughness, is worth 4 points when hatched, and takes 2 damage from a direct Pink strike instead of 1.
- The pipe shows up to the next three hopper eggs. After each non-final thwack, the next hopper egg drops into slot 1 if one remains.
- Egg toughness, current score, cash balance, remaining thwacks, and the number of eggs left in the hopper are always visible.
- Producer offers identify the animal with a portrait, preview the one egg it lays each day, and state that egg's toughness, points, and effect before selection.
- A producer draft shows the next day's target before selection.
- Before each later day begins, the complete flock is shown loading one egg per bird into the new daily hopper.

## Actions and resolution

Each turn, the player must activate one available spoon control:

- On the starting line, Red fires the spoons over slots 1 and 3, Blue fires over slots 2 and 4, and Pink fires over slot 5.
- On the ten-bay hairpin, five independent levers fire paired screen columns: Red fires slots 1 and 10, Blue fires 2 and 9, Green fires 3 and 8, Purple fires 4 and 7, and Pink fires 5 and 6.
- Each fired bowl normally deals 1 damage to the egg beneath it. Pink deals 2 direct damage to a Spoonbill. A bowl over an empty slot still fires but its damage is wasted.
- A control is available when at least one of its linked bays contains an egg.

Resolve the thwack in this order:

1. On the starting line, fire every spoon in the chosen circuit and apply their direct damage as one simultaneous batch. Apply each resulting Cuckoo echo, hatch every egg that reached 0 toughness in conveyor order, then retreat each surviving directly struck Plover.
2. On the hairpin, extend the chosen spoon to the lower, visually nearer bay. Apply that direct damage and its Cuckoo echoes, resolve all resulting hatches, then retreat a surviving directly struck Plover. Retract the same bowl to the upper, visually farther bay and repeat the complete sequence using the live state left by the first hit. Both taps occur even when their bay is empty, and reaching the target on the first hit never skips the second.
3. Cuckoo echo damage does not create further echoes. A Cuckoo beside a Pink-struck Spoonbill takes 2 echo damage.
4. Advance every surviving conveyor egg one slot.
5. Discard any egg that moves past the machine's final slot without scoring.
6. Spend one of the day's 20 thwacks.
7. If the score now meets or exceeds the target, end the day immediately, discard every remaining egg without scoring, and bank £1 for each unused thwack.
8. Otherwise, if thwacks remain, drop the next hopper egg into slot 1 if one remains and refill the visible pipe preview.
9. End the day as a failure if no eggs remain in either the hopper or conveyor. Otherwise, continue until the twentieth thwack.

Hatching an egg never prevents the conveyor from advancing. Partially damaged eggs retain their remaining toughness until they hatch or are discarded.

## Exceptions and glossary

- **Thwack:** The player's single action for a turn and the unit of day time.
- **Spoon circuit:** A fixed group of one or more colour-matched spoons that always fire together.
- **Telescoping spoon:** One Day 3 wall-hinged spoon with one bowl and an extending handle. Pulling its lever hits the near bay, fully resolves it, returns and retracts on the wall, then hits the far bay.
- **Toughness:** The number of further thwacks an egg needs before it hatches.
- **Adjacent:** Immediately ahead of or behind an egg in conveyor order. Visual proximity does not create adjacency.
- **Behind:** One slot closer to the pipe in conveyor order.
- **Echo damage:** Damage copied by a Cuckoo when an adjacent egg receives damage. Each damaged adjacent egg creates one echo on that Cuckoo; echo damage never echoes again.
- **Spark weakness:** The four-point spark on a Spoonbill matches Pink's circuit symbol. A direct Pink strike deals 2 damage to it; Red, Blue, and echo damage still deal their normal amounts.
- **Plover retreat:** A surviving Plover directly struck by a circuit swaps with the egg or empty bay immediately to its screen-left when one exists. This is intentionally a screen-space rule, not an ahead/behind rule: it moves toward lower slot numbers across the five-bay line and hairpin's upper run, but toward higher slot numbers across the lower return. Slots 1 and 10 at the left edges have no leftward destination. Cuckoo echoes use the positions from before any retreat, and the normal conveyor advance still follows.
- **Discarded:** Removed without hatching or awarding points.
- **Producer:** A persistent flock member that lays exactly one fresh egg into the daily pool.
- **Hopper:** The finite shuffled sequence of eggs that have not yet entered the conveyor.
- **Producer offer:** One of three distinct Chicken, Cuckoo, Plover, or Spoonbill producers offered after a successful day. Exactly one must be added before the next day.
- **Cash:** Persistent whole-pound currency held for the current run and earned from unused thwacks. The current slice exposes the balance but does not yet offer shop stock.
- **Hairpin refit:** The universal, free ten-bay machine installed before Day 3. It is not a purchasable upgrade.
