# Current game rules

This file is the canonical player-facing rule truth. Keep it current and concise. Put rationale in `decision-log.md`, interpretation in `design-principles.md`, prototype scope in `vertical-slices.md`, and observations in `playtest-log.md`.

## Game promise

Choose which eggs deserve each spoon while every movement wears the conveyor down. Eggs that escape into the bin return in a new order with their cracks intact, so extracting more value from each paid belt movement matters as much as hatching the right eggs.

## Objective and end states

- The belt begins each day with 12 Condition. A movement operation that advances the belt one or more slots costs exactly 1 Condition; a movement of zero slots costs none.
- A day ends immediately after a resolved thwack meets Grandma's appetite. If the appetite remains unmet when Belt Condition reaches 0, the day fails. It can also end earlier when every daily egg has hatched and no eggs remain in the hopper, conveyor, or bin.
- Hatch eggs to meet Grandma's Appetite: 10 Satisfaction on Day 1 and 9 on each later day. Immediate and slow-release Yolk both become Satisfaction and fill the appetite meter from the left. Sulphurous suppression fills the same meter from the right and lowers the visible effective Appetite for that day.
- A day succeeds when Grandma's accumulated Satisfaction meets or exceeds her effective Appetite requirement and fails below it.
- Every successful day awards a fixed £3. Add it to the run's persistent cash balance.
- A failed day awards no cash.
- Whenever a day ends, all unhatched eggs left in the hopper, conveyor, or bin are discarded without scoring.

## Player loop

Inspect the five-slot conveyor, the next three eggs rising through the hopper lift, the hopper and bin counts, Grandma's appetite, and the belt's remaining Condition. The top preview is the next egg to exit sideways onto the conveyor. Click the hopper to inspect every egg it contains without revealing their other queue positions, or click the bin to inspect every stored egg. Choose a circuit by balancing the eggs it can damage against the position created by the paid belt movement. An empty impact can still advance the belt strategically, but it spends the same Condition as any other movement.

After a successful day, bank the fixed £3 payout and enter a dedicated bird-offer screen to choose one of three free birds. The offered birds may be any quality. Choosing one closes the offer and opens the separate shop, where the complete flock can be reviewed and at most one bird may be removed for £3 before the next flock loads. A failed day awards no cash, bird offer, or shop visit and is retried with the same flock and deterministic shuffle sequence; retry restores Belt Condition to its starting maximum.

## Setup and state

- Every day uses five ordered conveyor slots. Slot 1 receives eggs and slot 5 sits beside the collection bin.
- The starting flock has three Chicken producers, two Cuckoo producers, and three Sparrow producers.
- Every producer lays exactly one egg per day, so the starting flock produces a daily pool of eight eggs.
- Shuffle the complete daily pool and load its first five eggs across slots 1–5, or every egg when fewer than five were laid. Place only later eggs in the hopper.
- An unhatched egg that moves past slot 5 falls into the bin and retains its remaining toughness and every other egg fact.
- Whenever the hopper is empty, shuffle every egg currently in the bin into a new hopper, even while other eggs remain on the conveyor. This happens both before loading when no egg is waiting and immediately after the last waiting egg enters slot 1. An egg that falls from slot 5 on that thwack joins the reshuffle.
- A Chicken egg has 3 toughness and is worth 3 points when hatched.
- A Cuckoo egg has 4 toughness and is worth 1 point when hatched.
- A Sparrow egg has 1 toughness, is worth 1 point when hatched, and has no additional egg effect.
- A Plover egg has 6 toughness and is worth 4 points when hatched.
- A Spoonbill egg has 5 toughness, is worth 4 points when hatched, and takes 2 damage from a direct Pink strike instead of 1.
- A Quail egg has 2 toughness, is worth 1 immediate Yolk, and has Appetiser. It has no Double Yolker chance.
- A Maleo egg has 6 toughness, is worth 3 immediate Yolk, and is Sulphurous. It has a 1% Standard Double Yolker chance.
- An Ostrich egg has 7 toughness, is worth 3 immediate Yolk, and has Shockwave. It has a 1% Standard Double Yolker chance.
- A Kiwi egg has 3 toughness, produces no immediate Yolk, and has Deceptively Filling (8). It has no Double Yolker chance.
- Every starting bird is Standard quality. A bird received from a day-end offer may be Standard, Prize, Champion, or a numbered higher tier.
- Bird cards use no rarity colour for Standard, green for Prize, and blue for Champion and higher tiers. The written quality name remains visible, so rarity is not communicated by colour alone.
- Each quality tier multiplies that bird's exact egg score, exact maximum toughness, and exact Double Yolker chance by 1.5. Displayed and awarded scores and percentages round down; maximum toughness rounds up to the whole amount of damage required to hatch. Exact values are retained between tiers.
- Standard Chicken eggs have a 2% Double Yolker chance, Standard Sparrow eggs have 5%, and Standard Maleo and Ostrich eggs have 1%. Standard Cuckoo, Plover, Spoonbill, Quail, and Kiwi eggs have no Double Yolker chance, so quality multiplication alone does not create one.
- The pipe shows up to the next three hopper eggs in queue order. Clicking the hopper shows every remaining hopper egg as a non-positional collection; it does not reveal the order beyond the pipe preview. After each non-final thwack, slot 1 receives at most one egg. If no egg is waiting, the bin first becomes the new shuffled hopper; if that entry empties the hopper, the bin reshuffles immediately afterward to refill the pipe. Neither case waits for the conveyor to clear.
- The visible hopper throat meets the conveyor entrance. After slot 5, the conveyor curves into the inspectable bin; the curve is only the existing belt-end route and adds no extra slot or action.
- Clicking the bin shows every stored egg and its retained toughness. The bin's future return order remains unknown until its seeded reshuffle occurs.
- Egg toughness, Grandma's current Appetite, Satisfaction and active egg effects, Belt Condition, cash balance, hopper count, and bin count are always visible. A dedicated information rail to the right of the belt groups Grandma, her appetite meter, compact effect statuses, one labelled Belt Condition bar, and settings. Yolk fills the meter from the left; green Sulphurous suppression fills it from the right. The reduced numeric Appetite and written Sulphurous status remain visible so suppression is not communicated by colour alone. The hopper count is also displayed on its clickable top.
- Hovering an egg shows a compact information card aligned beside that egg, with its species and quality, points, and floored Double Yolker chance. The card includes only the effect categories that apply to that egg. Whether the egg's hidden roll actually made it a Double Yolker is not revealed before hatching.
- After every successful day, exactly three free bird candidates are generated from the nine current species. All nine are available immediately. Each offer identifies the animal and quality with a portrait, previews the one egg it lays each day, and states that egg's toughness, points, and effect.
- The player must choose exactly one offered bird on the dedicated bird-offer screen before entering the shop or starting the next day. Choosing it adds one bird and therefore one egg to each subsequent daily pool without spending cash.
- The separate shop is the complete flock overview and shows every owned bird individually. Selecting a bird there removes that exact flock entry for £3. Only one bird may be removed per shop visit; after that removal, every remaining removal action is unavailable until the next successful night. Removal is also unavailable when cash is insufficient or only one bird remains.
- The dedicated bird-offer screen and the later flock-overview shop both show the next day's appetite.
- Before each later day begins, the complete flock is shown loading one egg per bird into the new daily hopper.

## Actions and resolution

Each turn, the player must activate one spoon control:

- Red fires the spoons over slots 1 and 3.
- Blue fires the spoons over slots 2 and 4.
- Pink fires the spoon over slot 5.
- Each fired bowl normally deals 1 damage to the egg beneath it. Pink deals 2 direct damage to a Spoonbill. A bowl over an empty slot still fires but its damage is wasted.
- Every circuit remains available during an unlocked day, even when every bay beneath its spoons is empty. Spoon impacts do not have separate health or wear.

Eggs may carry reusable effects which resolve when they hatch:

- **Appetiser:** Add one charge. A charge doubles the immediate positive Yolk of the next later egg that hatches, then is consumed. Charges increase duration, not magnitude: two charges double the next two eligible eggs rather than making one egg worth four times as much. Appetiser ignores Deceptively Filling because its Yolk is released on later thwacks rather than awarded immediately when its egg hatches.
- **Sulphurous:** When this egg hatches, suppress 2 of Grandma's Appetite for the rest of the day. Each Sulphurous egg applies its suppression exactly once. Further Sulphurous eggs stack another 2 suppression, but effective Appetite cannot fall below 1. The base daily Appetite and accumulated Satisfaction do not change, and all suppression clears at the day boundary.
- **Shockwave:** After the egg hatches, fire each spoon at the immediately adjacent slots once. An empty or missing adjacent slot cannot take damage. These strikes inherit the circuit colour that ultimately caused the hatch, deal normal direct spoon damage, can trigger direct-hit reactions and further on-hatch effects, and may chain into another Shockwave. The complete chain causes no extra conveyor movement or Belt Condition loss.
- **Deceptively Filling (n):** Add `n` slow-release Yolk to Grandma's single Filling reserve. Beginning on the next thwack, release exactly 1 Yolk as Satisfaction and decrease the reserve by 1. Further activations extend the reserve's duration; they never increase its one-per-thwack release rate. An opening release that satisfies Grandma does not cancel the already committed thwack. The reserve expires at the day boundary.

Resolve the thwack in this order:

1. Apply beginning-of-thwack effects, including at most one Yolk released from Grandma's Deceptively Filling reserve.
2. Fire every spoon in the chosen circuit and apply direct damage plus resulting Cuckoo echoes as one complete batch.
3. Hatch every egg that reached 0 toughness in conveyor order, award its Yolk as Satisfaction, and resolve its on-hatch effects. An Appetiser may therefore affect a later hatch in the same batch but never an earlier one. Sulphurous suppression takes effect immediately when its egg hatches and can satisfy Grandma on that same completed thwack.
4. Resolve every Shockwave strike, resulting echo, conveyor-ordered hatch, and chained effect completely; then retreat each surviving directly struck Plover. Cuckoo echo damage does not create further echoes. A Cuckoo beside a Pink-struck Spoonbill takes 2 echo damage.
5. Advance every surviving conveyor egg one slot and move any unhatched egg that passes slot 5 into the bin without restoring its toughness.
6. If no hopper egg is waiting, immediately shuffle every egg in the bin into a new hopper. Load at most one egg into slot 1. If loading that egg empties the hopper, immediately shuffle the current bin afterward and refresh the visible pipe preview; do not load a second conveyor egg.
7. Because the belt moved, spend exactly 1 Belt Condition after the complete movement and refill. Several slots advanced by one movement operation would still cost only 1; a paused zero-slot movement would cost none.
8. If Satisfaction now meets the effective Appetite, end the day immediately, discard every remaining egg without scoring, and bank the fixed £3 payout. This success check takes precedence when Belt Condition reached 0 during the thwack.
9. Otherwise, if Belt Condition is 0, end the day as a failure.
10. End the day as a failure if no eggs remain in the hopper, conveyor, or bin. Otherwise, continue.

Hatching an egg never prevents the conveyor from advancing. Partially damaged eggs retain their remaining toughness until they hatch or the day ends, including while travelling through the bin and hopper.

## Exceptions and glossary

- **Thwack:** The player's single committed circuit action for a turn.
- **Spoon circuit:** A fixed group of one or more colour-matched spoons that always fire together.
- **Toughness:** The amount of further damage an egg needs before it hatches.
- **Adjacent:** Immediately ahead of or behind an egg in conveyor order.
- **Behind:** One slot closer to the pipe in conveyor order.
- **Echo damage:** Damage copied by a Cuckoo when an adjacent egg receives damage. Each damaged adjacent egg creates one echo on that Cuckoo; echo damage never echoes again.
- **Spark weakness:** The four-point spark on a Spoonbill matches Pink's circuit symbol. A direct Pink strike deals 2 damage to it; Red, Blue, and echo damage still deal their normal amounts.
- **Plover retreat:** A surviving Plover directly struck by a circuit swaps with the egg or empty bay immediately to its screen-left when one exists. Slot 1 has no leftward destination. Cuckoo echoes use the positions from before any retreat, and the normal conveyor advance still follows.
- **Bin:** The visible collection of unhatched eggs that have fallen from slot 5. Its eggs retain damage and are shuffled back into the hopper whenever the current hopper is empty, without waiting for the conveyor to clear.
- **Discarded:** Removed without hatching or awarding points when the day ends.
- **Producer:** A persistent flock member with a species and quality tier that lays exactly one fresh egg into the daily pool.
- **Hopper:** The current shuffled sequence of eggs waiting to enter slot 1.
- **Bird offer:** A dedicated post-success screen containing a mandatory choice of one free Chicken, Cuckoo, Sparrow, Plover, Spoonbill, Quail, Maleo, Ostrich, or Kiwi. The three candidates may have different quality tiers. Choosing one adds exactly one bird and one egg to each subsequent daily pool, closes the offer, and opens the shop.
- **Quality:** A bird tier: Standard, Prize, Champion, then numbered higher tiers. Each step compounds exact score, maximum toughness, and Double Yolker chance by 1.5.
- **Shop:** The post-success flock overview where the only current paid action is removing one selected bird for £3. At most one removal is allowed per visit, and leaving preserves unspent cash.
- **Belt Condition:** The conveyor's remaining movement capacity. It starts each day at 12 and loses exactly 1 whenever a movement operation advances one or more slots.
- **Yolk:** Positive food value produced by an egg. Most Yolk is awarded immediately when that egg hatches and can be doubled by Appetiser. Deceptively Filling instead banks slow-release Yolk which becomes Satisfaction one point per later thwack and is ignored by Appetiser.
- **Appetite:** Grandma's base daily Satisfaction requirement. Sulphurous can temporarily lower the effective completion threshold without changing this base value.
- **Satisfaction:** Progress actually applied toward Grandma's Appetite after egg and Grandma effects resolve. It includes both immediate and slow-release Yolk.
- **Cash:** Persistent whole-pound currency held for the current run, earned as a fixed £3 after each successful day, and currently spent only on optional bird removal.
