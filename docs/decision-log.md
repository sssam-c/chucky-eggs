# Decision log

This log is append-only. Later decisions may supersede earlier entries but never erase them.

## D000 — Separate rule truth, rationale, scope, and evidence

**Status:** accepted

**Decision:** Maintain distinct documents for current rules, design principles, decision history, vertical-slice scope, and playtest evidence. Follow the precedence in `contracts/documentation.md`.

**Reason:** Prototypes change quickly. Separating these knowledge types prevents a temporary implementation choice or one playtest observation from silently becoming permanent game truth.

## D001 — Make every thwack consume conveyor time

**Status:** accepted

**Decision:** The conveyor has five slots. The player may thwack any egg on it, reducing that egg's toughness by 1, and every thwack then advances all surviving eggs one slot. An egg that passes the end is discarded. A day lasts 20 thwacks, and all eggs remaining after the final thwack are discarded.

**Reason:** Free targeting gives the player agency, while shared conveyor movement makes damage a scarce resource. Every thwack helps one egg and endangers the rest, forcing deliberate sacrifice instead of allowing the player to clear everything.

## D002 — Teach sacrifice with one chicken egg type

**Status:** accepted

**Decision:** The first playable slice supplies one chicken egg per turn. Each chicken has 4 toughness, awards 1 point, and the day target is 3 points. The day begins with one chicken in slot 1, while a pipe previews the next three eggs and the remaining-thwack countdown stays visible.

**Reason:** A chicken needs four of its five available conveyor steps to hatch, so committing to one necessarily allows others to pass. Requiring 3 points uses 12 of 20 thwacks, leaving enough recovery room for an early player to make mistakes while still learning that not every egg can be saved. Using one egg type isolates that lesson from value comparisons and hatch-effect combinations.

## D003 — Give every conveyor slot a piano-key spoon hammer

**Status:** accepted

**Decision:** Present the five conveyor choices as five large foreground keys. Each key is mechanically linked to one fixed spoon hammer behind the belt; pressing it fires that spoon onto the top of the upright egg in the corresponding slot. Idle spoons show their convex backs and remain spatially paired with their keys and cups.

**Reason:** A one-to-one bank of physical controls makes targeting immediate while preserving the pleasure of a large mechanical spoon. The piano-hammer motion gives anticipation, impact, and reset a clear causal chain without obscuring egg faces or requiring a cursor-sized tool.

## D004 — Introduce Cuckoo collateral damage

**Status:** accepted

**Decision:** Add Cuckoo eggs to a fixed authored supply. Chicken eggs remain at 4 toughness but now award 3 points; Cuckoo eggs have 4 toughness and award 1 point. Whenever another egg receives damage, every Cuckoo receives the same amount once per damaged egg. Apply the entire direct-and-echo damage batch before resolving hatches in conveyor order. Echo damage cannot create further echoes. The current mixed-egg day target is 10 points.

**Reason:** Cuckoos turn damage to valuable eggs into collateral progress, creating a reason to plan across the whole belt rather than evaluating only the chosen target. Their low value tests whether incidental scoring can be strategically useful without replacing the Chicken as the reliable baseline. Batch resolution also establishes deterministic semantics for future multi-position spoons.

**Supersedes:** D002's chicken-only supply, 1-point Chicken value, and 3-point target. The five-slot teaching structure, 4-toughness Chicken, 20-thwack day, and three-egg preview remain.

## D005 — Restrict Cuckoo echoes to adjacent eggs

**Status:** accepted

**Decision:** A Cuckoo copies damage only when the damaged egg is immediately ahead of or behind it in conveyor order. It continues to echo once per damaged adjacent egg, and echo damage remains non-recursive. Visual proximity does not make eggs adjacent.

**Reason:** Global echo damage made Cuckoos too generous and required little positional planning. Adjacency creates short, visible opportunities that the player must cultivate while remaining unambiguous when the conveyor eventually folds into multiple rows.

**Supersedes:** D004's global echo range. D004's egg values, damage batching, hatch order, authored supply, and 10-point target remain.

## D006 — Let Plover eggs retreat through the belt

**Status:** accepted

**Decision:** Add 4-toughness Plover eggs worth 2 points to the authored supply. When a directly thwacked Plover survives the complete damage and hatch resolution, it swaps with the contents of the slot immediately behind it, toward the pipe. A Plover in slot 1 cannot retreat. Cuckoo adjacency resolves before the swap, and the standard conveyor advance still follows it.

**Reason:** The Plover lets a player spend damage to preserve one egg's conveyor position only by accelerating another egg toward the drop. This turns belt position itself into a manipulable cost, creates and breaks future Cuckoo pairings, and deepens sacrifice without adding another player control.

## D007 — Make the Plover a longer commitment

**Status:** accepted

**Decision:** Increase Plover toughness from 4 to 6. Its 2-point value and retreat behavior remain unchanged.

**Reason:** Retreating lets a Plover preserve its conveyor position repeatedly, so a higher toughness makes that positional privilege demand a sustained commitment and more displaced eggs rather than making it an easy secondary hatch.

**Supersedes:** D006's 4-toughness Plover value only.

## D008 — Make Chickens a faster baseline reward

**Status:** accepted

**Decision:** Reduce Chicken toughness from 4 to 3. Its 3-point value remains unchanged; the day still lasts 20 thwacks and requires 10 points.

**Reason:** Four-hit Chickens consumed too much of the opening day's action budget once Cuckoo adjacency and Plover displacement were added. Three-hit Chickens produce the satisfying hatch payoff more often and let three reliable hatches reach 9 points in 9 direct hits, leaving room to experiment while still requiring a special-egg contribution for the final point.

**Supersedes:** D004's 4-toughness Chicken value. D004's 3-point Chicken value remains.

## D009 — Replace direct targeting with three spoon circuits

**Status:** accepted

**Decision:** Replace the five one-slot controls with three fixed colour-coded spoon circuits. Red fires slots 1 and 3, Blue fires slots 2 and 4, and Pink fires slot 5. Every fired spoon deals 1 damage. All spoons in a chosen circuit fire together, including spoons over empty slots; a circuit is available when at least one linked slot contains an egg. Direct damage resolves as one batch before Cuckoo echoes, hatches, surviving directly struck Plover retreats, and the standard conveyor advance.

**Reason:** Circuit choice makes conveyor position the object of every decision. Red and Blue offer efficient distributed damage that couples alternating belt positions, while Pink sacrifices efficiency for one precise final chance beside the drop. Fixed coloured relationships preserve the machine's physical causality and create intentional wasted strikes, Cuckoo sandwich opportunities, and Plover rescues without adding another action type.

**Supersedes:** D001's free choice of any individual egg and D003's one-key-to-one-spoon control mapping. The five fixed conveyor slots, five spatially paired spoons, one-thwack conveyor advance, and all current egg rules remain.

## D010 — Give Pink a Spoonbill specialty

**Status:** accepted

**Decision:** Add Spoonbill eggs to the authored supply. A Spoonbill has 5 toughness, awards 4 points, and takes 2 direct damage from Pink instead of 1. Its shell carries the same four-point spark used by Pink's control and slot-5 spoon. If an adjacent Cuckoo copies that Pink strike, it copies the full 2 damage. Red, Blue, and echo damage against a Spoonbill retain their normal amounts.

**Reason:** Pink normally trades the two distributed strikes of Red or Blue for one precise final-slot strike. Spoonbill makes that precision proactively valuable without making Pink universally stronger: the player must preserve and prepare a high-value egg until slot 5, where Pink can deliver two concentrated damage. Five toughness allows one earlier circuit opportunity to be spent elsewhere, while the full Cuckoo echo creates a visible high-payoff slot-4/slot-5 pairing.

## D011 — Generate a finite daily pool from producers

**Status:** accepted

**Decision:** The starting flock contains five Chicken producers that each lay two eggs per day, three Cuckoo producers that each lay one, and two Plover producers that each lay one. Shuffle those 15 fresh eggs once at the beginning of the day, load the first onto the conveyor, and use the remainder as a finite hopper with a three-egg preview. Do not reshuffle. A day ends after its twentieth thwack or earlier when both hopper and conveyor are empty.

**Reason:** Producer yield lets flock composition express both egg quality and frequency. A finite shuffled pool makes additions capable of diluting complementary combinations, giving future removal, thwack, belt, and hopper upgrades a shared strategic purpose. Ending on exhaustion avoids empty mandatory actions when the initial pool clears before the thwack cap.

**Supersedes:** D004's fixed authored supply and D010's inclusion of Spoonbill in that authored opening supply. All established egg behavior, Spoonbill behavior, circuit rules, and the 20-thwack maximum remain.

## D012 — Raise the Plover payoff

**Status:** accepted

**Decision:** Increase the Plover's hatch value from 2 points to 4. Its 6 toughness and retreat behavior remain unchanged.

**Reason:** The Plover demands sustained circuit commitment while repeatedly displacing neighbouring eggs. Four points makes completing that difficult positional problem feel like a prize without exceeding the Spoonbill's special-egg payoff.

**Supersedes:** D007's 2-point Plover value only.

## D013 — Add one producer after each successful day

**Status:** accepted

**Decision:** After a successful day, offer three distinct producers drawn from the established Chicken, Cuckoo, Plover, and Spoonbill species. Show each producer's daily yield and egg properties, and require the player to add exactly one before beginning the next day. Chicken producers add two eggs to every subsequent daily pool; the other established producers add one. A failed day offers no producer and retries with the same flock and shuffle.

**Reason:** Mandatory growth turns every success into a build decision while preserving the dilution pressure that gives future removal and machine-capacity upgrades value. Three legible choices provide agency without exposing the full catalogue, and success-only rewards preserve the meaning of the daily target.

## D014 — Show animals producing the next hopper

**Status:** accepted

**Decision:** Identify every producer offer with a species portrait, its full daily yield, and a visual preview of every egg it contributes. After the player adds a producer and before the next day becomes playable, show the complete flock loading its resolver-authored daily output into the hopper. Keep input locked until that presentation completes, and allow cancellation or replacement to prevent stale next-day presentation.

**Reason:** Yield is part of a producer's strategic identity, and text alone undersells how strongly a two-egg Chicken changes the pool. Repeating the bird-to-egg relationship during hopper loading makes flock composition, dilution, and the origin of the shuffled daily pool immediately visible without moving production ownership into animation.

<!--
Copy for the next entry:

## D015 — Short decision title

**Status:** proposed | accepted | superseded

**Decision:** State the rule or constraint precisely.

**Reason:** Record the trade-off and evidence.

**Supersedes:** Name earlier entries when applicable.
-->
