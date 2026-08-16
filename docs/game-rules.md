# Current game rules

This file is the canonical player-facing rule truth. Keep it current and concise. Put rationale in `decision-log.md`, interpretation in `design-principles.md`, prototype scope in `vertical-slices.md`, and observations in `playtest-log.md`.

## Game promise

Choose which eggs deserve the spoon while every thwack carries the conveyor closer to the bell. Eggs that escape into the bin will return in a new order with their cracks intact, but recovering them costs precious time.

## Objective and end states

- A day lasts at most 10 thwacks and ends immediately after a resolved thwack meets the score target. It can also end earlier when every daily egg has hatched and no eggs remain in the hopper, conveyor, or bin.
- Hatch eggs to meet the current day's target: 10 points on Day 1 and 9 points on each later day.
- A day succeeds at or above its target and fails below it.
- When a successful day ends, gain £1 for each unused thwack remaining after the target-reaching thwack is spent. Add it to the run's persistent cash balance.
- A failed day awards no cash.
- Whenever a day ends, all unhatched eggs left in the hopper, conveyor, or bin are discarded without scoring.

## Player loop

Inspect the five-slot conveyor, the next three eggs in the pipe, the hopper and bin counts, the score, and the visible thwack countdown. Click the hopper to inspect every egg it contains without revealing their queue positions, or click the bin to inspect every stored egg. Choose any spoon control, balancing the eggs it can damage against their current positions and the time required to cycle missed eggs back through the hopper. An empty circuit can be used to advance the belt, but still costs one of the day's thwacks.

After a successful day, bank the unused-thwack payout and enter a dedicated bird-offer screen to choose one of three free birds. The offered birds may be any quality. Choosing one closes the offer and opens the separate shop, where the complete flock can be reviewed and at most one bird may be removed for £3 before the next flock loads. A failed day awards no cash, bird offer, or shop visit and is retried with the same flock and deterministic shuffle sequence.

## Setup and state

- Every day uses five ordered conveyor slots. Slot 1 receives eggs and slot 5 sits beside the collection bin.
- The starting flock has three Chicken producers, two Cuckoo producers, and three Sparrow producers.
- Every producer lays exactly one egg per day, so the starting flock produces a daily pool of eight eggs.
- Shuffle the complete daily pool and load its first egg into slot 1. Place the rest in the hopper.
- An unhatched egg that moves past slot 5 falls into the bin and retains its remaining toughness and every other egg fact.
- When both the hopper and conveyor are empty, shuffle every egg currently in the bin into a new hopper before loading. A non-empty conveyor prevents the bin from recycling, even when the hopper is empty.
- A Chicken egg has 3 toughness and is worth 3 points when hatched.
- A Cuckoo egg has 4 toughness and is worth 1 point when hatched.
- A Sparrow egg has 1 toughness, is worth 1 point when hatched, and has no additional egg effect.
- A Plover egg has 6 toughness and is worth 4 points when hatched.
- A Spoonbill egg has 5 toughness, is worth 4 points when hatched, and takes 2 damage from a direct Pink strike instead of 1.
- Every starting bird is Standard quality. A bird received from a day-end offer may be Standard, Prize, Champion, or a numbered higher tier.
- Bird cards use no rarity colour for Standard, green for Prize, and blue for Champion and higher tiers. The written quality name remains visible, so rarity is not communicated by colour alone.
- Each quality tier multiplies that bird's exact egg score, exact maximum toughness, and exact Double Yolker chance by 1.5. Displayed and awarded scores and percentages round down; maximum toughness rounds up to the whole amount of damage required to hatch. Exact values are retained between tiers.
- Standard Chicken eggs have a 2% Double Yolker chance and Standard Sparrow eggs have a 5% chance. Standard Cuckoo, Plover, and Spoonbill eggs currently have no Double Yolker chance, so quality multiplication alone does not create one.
- The pipe shows up to the next three hopper eggs in queue order. Clicking the hopper shows every remaining hopper egg as a non-positional collection; it does not reveal the order beyond the pipe preview. After each non-final thwack, slot 1 receives the next existing hopper egg when one is available. The bin only becomes a new hopper after the existing hopper and conveyor have both cleared.
- Clicking the bin shows every stored egg and its retained toughness. The bin's future return order remains unknown until its seeded reshuffle occurs.
- Egg toughness, current score, cash balance, remaining thwacks, hopper count, and bin count are always visible. The hopper count is also displayed on its clickable top.
- Hovering an egg shows a compact information card aligned beside that egg, with its species and quality, points, and floored Double Yolker chance. The card includes only the effect categories that apply to that egg. Whether the egg's hidden roll actually made it a Double Yolker is not revealed before hatching.
- After every successful day, exactly three free bird candidates are generated from the five current species. Each offer identifies the animal and quality with a portrait, previews the one egg it lays each day, and states that egg's toughness, points, and effect.
- The player must choose exactly one offered bird on the dedicated bird-offer screen before entering the shop or starting the next day. Choosing it adds one bird and therefore one egg to each subsequent daily pool without spending cash.
- The separate shop is the complete flock overview and shows every owned bird individually. Selecting a bird there removes that exact flock entry for £3. Only one bird may be removed per shop visit; after that removal, every remaining removal action is unavailable until the next successful night. Removal is also unavailable when cash is insufficient or only one bird remains.
- The dedicated bird-offer screen and the later flock-overview shop both show the next day's target.
- Before each later day begins, the complete flock is shown loading one egg per bird into the new daily hopper.

## Actions and resolution

Each turn, the player must activate one spoon control:

- Red fires the spoons over slots 1 and 3.
- Blue fires the spoons over slots 2 and 4.
- Pink fires the spoon over slot 5.
- Each fired bowl normally deals 1 damage to the egg beneath it. Pink deals 2 direct damage to a Spoonbill. A bowl over an empty slot still fires but its damage is wasted.
- All three controls remain available during an unlocked day, even when every linked bay is empty. An empty circuit still fires, advances the conveyor, and spends one thwack.

Resolve the thwack in this order:

1. Fire every spoon in the chosen circuit and apply their direct damage as one simultaneous batch.
2. Apply each resulting Cuckoo echo, hatch every egg that reached 0 toughness in conveyor order, then retreat each surviving directly struck Plover.
3. Cuckoo echo damage does not create further echoes. A Cuckoo beside a Pink-struck Spoonbill takes 2 echo damage.
4. Advance every surviving conveyor egg one slot.
5. Move any unhatched egg that passes slot 5 into the bin without restoring its toughness.
6. Spend one of the day's thwacks.
7. If the score now meets or exceeds the target, end the day immediately, discard every remaining egg without scoring, and bank £1 for each unused thwack.
8. Otherwise, if thwacks remain, drop the next existing hopper egg into slot 1. If the hopper is empty, wait until the conveyor is also empty before shuffling the bin into a new hopper, loading its next egg, and refilling the visible pipe preview.
9. End the day as a failure if no eggs remain in the hopper, conveyor, or bin. Otherwise, continue until the final thwack.

Hatching an egg never prevents the conveyor from advancing. Partially damaged eggs retain their remaining toughness until they hatch or the day ends, including while travelling through the bin and hopper.

## Exceptions and glossary

- **Thwack:** The player's single action for a turn and the unit of day time.
- **Spoon circuit:** A fixed group of one or more colour-matched spoons that always fire together.
- **Toughness:** The amount of further damage an egg needs before it hatches.
- **Adjacent:** Immediately ahead of or behind an egg in conveyor order.
- **Behind:** One slot closer to the pipe in conveyor order.
- **Echo damage:** Damage copied by a Cuckoo when an adjacent egg receives damage. Each damaged adjacent egg creates one echo on that Cuckoo; echo damage never echoes again.
- **Spark weakness:** The four-point spark on a Spoonbill matches Pink's circuit symbol. A direct Pink strike deals 2 damage to it; Red, Blue, and echo damage still deal their normal amounts.
- **Plover retreat:** A surviving Plover directly struck by a circuit swaps with the egg or empty bay immediately to its screen-left when one exists. Slot 1 has no leftward destination. Cuckoo echoes use the positions from before any retreat, and the normal conveyor advance still follows.
- **Bin:** The visible collection of unhatched eggs that have fallen from slot 5. Its eggs retain damage and are shuffled back into the hopper only when both the current hopper and conveyor are empty.
- **Discarded:** Removed without hatching or awarding points when the day ends.
- **Producer:** A persistent flock member with a species and quality tier that lays exactly one fresh egg into the daily pool.
- **Hopper:** The current shuffled sequence of eggs waiting to enter slot 1.
- **Bird offer:** A dedicated post-success screen containing a mandatory choice of one free Chicken, Cuckoo, Sparrow, Plover, or Spoonbill. The three candidates may have different quality tiers. Choosing one adds exactly one bird and one egg to each subsequent daily pool, closes the offer, and opens the shop.
- **Quality:** A bird tier: Standard, Prize, Champion, then numbered higher tiers. Each step compounds exact score, maximum toughness, and Double Yolker chance by 1.5.
- **Shop:** The post-success flock overview where the only current paid action is removing one selected bird for £3. At most one removal is allowed per visit, and leaving preserves unspent cash.
- **Cash:** Persistent whole-pound currency held for the current run, earned from unused thwacks, and currently spent only on optional bird removal.
