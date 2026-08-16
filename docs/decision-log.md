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

## D015 — Set a 15-to-20 target step

**Status:** accepted

**Decision:** Day 1 requires 15 points. Day 2 and each later day currently require 20 points. The producer draft shows the next day's target before the player selects an addition. A failed later day retries with the same target, flock, and shuffle.

**Reason:** Fifteen points makes the opening day demand a deliberate set of hatches rather than granting progression after a minimal score. Raising the next day to 20 gives the mandatory producer addition an immediate problem to solve, while showing that target before selection keeps the build decision informed. Holding later days at 20 bounds this first pressure test without pretending that a complete difficulty curve has been designed.

**Supersedes:** D004 and D008's 10-point target. Their egg values, toughness changes, and other rules remain.

## D016 — Bank unused thwacks as cash

**Status:** accepted

**Decision:** After a successful day ends through the established twentieth-thwack or egg-exhaustion rules, award £1 for each remaining thwack and add it to a persistent run cash balance. A failed day awards no cash, and retry preserves the previously banked balance. Do not add an early cash-out action.

**Reason:** Unused thwacks turn efficient hatching and deliberate discarding into future purchasing power. Success-only banking prevents failed-day farming, while preserving the natural end condition avoids making immediate cash-out the dominant action once the score target is met. The first implementation exposes earning and balance only; shop prices, removal, and upgrades need separate evidence.

## D017 — End the day when its target is met

**Status:** accepted

**Decision:** After a thwack's damage, hatches, retreats, conveyor advance, and thwack spend resolve, end the day immediately if the score meets or exceeds its target. Discard every remaining egg without scoring, award £1 for each then-unused thwack, and proceed to the established producer draft. A day that exhausts its twentieth thwack or all available eggs below target still fails and awards no cash.

**Reason:** Cash is intended to reward how few thwacks the player needs to satisfy the day's demand. Automatic completion makes the remainder an exact speed-to-target reward, removes purposeless play after success is assured, and avoids adding a dominant manual cash-out action. Finishing the scoring thwack before checking the target preserves the established causal order and makes the payout unambiguous.

**Supersedes:** D016's requirement that a successful day continue until twentieth-thwack or egg exhaustion. D016's £1 rate, persistent balance, success-only award, and lack of a manual cash-out action remain.

## D018 — Offer a symmetric two-bay line extension

**Status:** accepted

**Decision:** After the player chooses the producer earned from Day 1, open a workshop before Day 2's flock production begins. Offer an optional persistent two-bay conveyor extension. The extended line has seven slots: Red fires over slots 1, 3, and 5; Blue fires over slots 2, 4, and 6; Pink and the drop move to slot 7. The player may keep the five-slot line instead. The current prototype offers the module once for £8.

**Reason:** Producer growth already makes the daily egg pool physically larger. Letting saved thwacks buy a visibly larger machine connects that pressure, the new currency, and progression in one causal loop. Two bays preserve Red/Blue alternation and Pink's final-position specialty; a single bay would break that grammar or require another control at the same time. Keeping the purchase optional exposes its strategic value, while isolating layout expansion from new spoon behavior makes the playtest signal readable.

**Supersedes:** D009's five-slot circuit mapping only when the extension has been purchased. The starting five-slot machine, three circuit controls, shared movement, and all egg-resolution rules remain.

## D019 — Fold the extended conveyor into a return

**Status:** accepted

**Decision:** Present the seven-slot extension as a horseshoe rather than compressing all seven stations into one straight run. Slots 1–5 retain their established size and left-to-right upper route. After slot 5 the belt turns downward; slot 6 sits below slot 5, slot 7 continues left beneath the upper run, and Pink and the drop move to that return leg's leftward end. Mount the slot-6 and slot-7 spoons beneath the return belt so their stored poses remain outside the egg route.

**Reason:** A folded return makes the purchase read as added factory floor and preserves the physical scale of the original machine. Compressing seven stations into the old width looked like a denser interface rather than a larger mechanism. Route arrows, numbering, the visible bend, and inverted lower spoons make conveyor order legible despite screen-space adjacency no longer matching sequence.

**Supersedes:** D018's straight-line presentation only. D018's seven-slot rules, circuit mappings, workshop timing, price, persistence, and optional purchase remain.

## D020 — Keep the return module available until purchased

**Status:** accepted

**Decision:** Offer the £8 two-bay return in every workshop until it is installed. Keeping the current line postpones the purchase rather than permanently declining it. Once purchased, the module remains installed for the run and cannot be bought again.

**Reason:** A one-workshop deadline was not communicated by the interface and made saved cash misleading: a player could reach a later workshop with enough money while the visible module unexpectedly reported that no upgrades were available. Letting the player defer preserves the meaningful cash decision without turning an uninformed first skip into an irreversible loss.

**Supersedes:** D018's once-only offer and first-workshop-only timing. Its price, optional purchase, persistence, seven-slot rules, and circuit mappings remain.

## D021 — Make the full loop a universal Day 3 refit

**Status:** accepted

**Decision:** Days 1 and 2 retain the five-bay line. Before Day 3, every run automatically and freely refits to an eleven-bay loop: slots 1–5 travel right across the upper run, slot 6 turns downward, and slots 7–11 return left to the drop. Five overhead spoons remain. Red covers slots 1, 3, 9, and 11; Blue covers 2, 4, 8, and 10; Pink covers the full right-hand turn at 5, 6, and 7. A surviving directly struck Plover now hops one bay to screen-right when one exists; slots 5–7 therefore offer no Plover hop. Normal conveyor advance and route-relative adjacency are unchanged.

**Reason:** The smaller optional return made a major spatial rule hard to reason about while also asking the player to value it as shop stock. A full loop gives the route an immediately recognisable upper run, turn, and lower return; paired overhead columns preserve Red/Blue balance at four targets each, and Pink's three-bay corner creates a distinct hot zone. Making this a universal milestone lets the game teach one shared topology and reserves currency choices for less foundational changes such as producer removal and upgrades. Defining Plover as literally moving right preserves the character of the effect without pretending that “back” has one screen direction on a folded belt.

**Supersedes:** D006's route-relative Plover retreat and D018–D020's optional paid seven-bay extension. The starting five-bay circuit map, the between-day workshop boundary, persistent cash, and all unrelated egg-resolution rules remain.

## D022 — Exclude the hairpin bend from targeting

**Status:** accepted

**Decision:** Keep the universal free refit before Day 3, but install a ten-bay hairpin instead of the eleven-bay loop. Slots 1–5 travel right across the upper run, an untargetable bend carries eggs downward, and slots 6–10 return left underneath. Five enlarged single spoons remain aligned above the five screen columns and each strikes both bays beneath it. Red covers 1, 3, 8, and 10; Blue covers 2, 4, 7, and 9; Pink covers 5 and 6. Eggs sit directly on two touching conveyor casings without buckets or raised bay furniture. Plovers still hop literally screen-right; slots 5 and 6 have no rightward destination.

**Reason:** Putting a target on the bend forced the route, Pink balance, and physical spoon into one awkward shape. Mockups with a three-bay Pink bracket, duplicate spoon heads, and bucket-like holders made the machine harder to read and visually unlike the established implementation. Removing the bend bay restores five repeated columns, gives Red and Blue four targets each and Pink two—the doubled form of the starting line's 2/2/1 reach—and lets one familiar enlarged spoon represent each column.

**Supersedes:** D021's eleven-slot count, targetable turn, 4/4/3 circuit map, and multi-head spoon presentation. D021's mandatory free Day 3 timing, folded route, screen-right Plover rule, and all unrelated progression and resolution rules remain.

## D023 — Make Plover retreat literally left

**Status:** accepted

**Decision:** A surviving directly struck Plover swaps one bay to screen-left when that bay exists. On the five-bay line and the hairpin's upper run this moves toward lower slot numbers; on the hairpin's lower return it moves toward higher slot numbers. Slots 1 and 10 have no leftward destination. Cuckoo echoes still resolve before the swap and normal conveyor advance still follows. In the Day 3 hairpin presentation, each single spoon extends during its thwack so its bowl visibly contacts the aligned lower bay while its shaft crosses the upper run.

**Reason:** A literal left retreat restores the Plover's original visual character without making “back” depend on conveyor direction. The previous enlarged spoons communicated column ownership while idle but their contact stopped on the upper row, making the lower strike look purely abstract. Extending the same handle and bowl to the second row preserves one physical spoon per column and makes the paired hit causal on screen.

**Supersedes:** D021 and D022's literal screen-right Plover rule, and D022's presentation in which the spoon only contacted the upper bay. All circuit maps, Day 3 refit timing, damage order, and other hairpin rules remain.

## D024 — Give every hairpin column its own paired spoon tower

**Status:** accepted

**Decision:** Days 1 and 2 retain the established Red 1+3, Blue 2+4, and Pink 5 circuits. The universal Day 3 hairpin refit replaces them with five independent column levers: Red strikes slots 1 and 10, Blue strikes 2 and 9, Green strikes 3 and 8, Purple strikes 4 and 7, and Pink strikes 5 and 6. Each lever drives one upright rigid carriage with two linked spoon bowls, and both bowls strike their aligned eggs simultaneously as one direct-damage batch. One pull still spends one thwack and advances the conveyor once. Pink remains the only Spoonbill weakness.

**Reason:** The single extending spoon made the lower hit visible only by turning a familiar utensil into a long rod, while its shaft crossed rather than convincingly thwacked the upper egg. Five paired tower mechanisms make both contact points literal and connect every control directly to one screen column. Independent levers trade the old Red and Blue four-target hairpin volleys for greater precision while retaining a two-target maximum, preventing the doubled belt from also doubling direct damage per action. The five towers also create clear physical sockets for later engine-building upgrades without making those upgrades part of this slice.

**Supersedes:** D022's 4/4/2 hairpin circuit map and single-spoon-per-column presentation, and D023's extending-spoon presentation. D009's three starting-line circuits, D023's literal screen-left Plover rule, the Day 3 refit timing, the ten-bay route, Pink's Spoonbill weakness, and all unrelated resolution rules remain.

## D025 — Replace paired towers with double-bowled wall spoons

**Status:** accepted

**Decision:** Keep the five independent Day 3 column levers and their 1+10, 2+9, 3+8, 4+7, and 5+6 mappings. Replace each paired tower with one familiar spoon pinned to the wall at its handle base. Two bowls sit at different distances along the same continuous rigid handle. At rest both face the player above the aligned eggs; on a thwack the utensil pivots outward and the convex undersides contact the upper and lower egg crowns. The farther bowl clinks a fraction before the nearer bowl as presentational depth feedback, while both hits remain one simultaneous direct-damage batch. The complete utensil is one future positional tool socket.

**Reason:** The paired towers made both contact points literal but introduced a new gantry-and-side-arm language that looked less forceful and less like the established spoons. A double-bowled version preserves the familiar base hinge, bowl-first throw, and direct lever alignment while solving the two-row contact problem. A short sequence of authored whole-utensil poses keeps the shared shaft visibly joined to both bowls throughout the fall, avoiding the gaps and shape drift produced by independently interpolated parts. The utensil foreshortens straight toward the player: the bowls briefly overlap edge-on, while perspective scale, draw order, and a brass collar keep the original far bowl trackable as it becomes the larger lower/front impact bowl. The bowls retain their upright proportions until late in the throw, and egg occlusion returns the shaft behind them for the final contact pose. Treating the slight clink offset as feedback preserves the fun of a two-stage impact without making animation timing a hidden rule.

**Supersedes:** D024's paired carriage and tower presentation only. D024's five independent levers, column mappings, two-target ceiling, simultaneous damage batch, Day 3 timing, and future whole-column tool sockets remain.

## D026 — Preserve spoon identity across the hairpin fall

**Status:** accepted

**Decision:** In each Day 3 double-spoon mechanism, the lower stored spoon continues to the lower, farther conveyor and the upper stored spoon lands on the upper conveyor. The authored poses may briefly overlap edge-on, but the two visible spoon identities must not cross. The shared shaft follows the outermost bowl throughout the fall. Both contacts remain one simultaneous direct-damage batch.

**Reason:** Sending the upper stored spoon past the lower one made the final geometry impossible to reconcile with the resting mechanism, even when foreshortening communicated depth. Direct spatial correspondence makes both destinations predictable and lets the player read one continuous physical action.

**Supersedes:** D025's presentation in which the original far/upper stored bowl became the lower/front impact bowl. D025's double-bowled wall mechanism, authored fall, paired mappings, clink feedback, and simultaneous resolver behaviour remain.

## D027 — Map the lower wall spoon to the farther belt

**Status:** accepted

**Decision:** In each Day 3 double-spoon mechanism, the lower spoon on the wall contacts the upper, visually farther conveyor. The upper wall spoon travels the longer projected arc to the lower, visually nearer conveyor. The shared shaft continues to the outermost bowl during the fall, and both contacts remain one simultaneous direct-damage batch.

**Reason:** “Farther conveyor” describes scene depth, not the lower row's greater screen-space distance from the hinge. The lower wall spoon has the shorter physical arc and therefore belongs to the farther belt; reversing that relationship makes the mechanism impossible to reconcile spatially.

**Supersedes:** D026's wall-spoon-to-belt correspondence. D025's original correspondence is restored; all paired mappings, authored-frame presentation, clink feedback, and resolver behaviour remain.

## D028 — Make both hairpin spoons traceable

**Status:** accepted

**Decision:** Present each Day 3 column as two wall spoons on adjacent shafts sharing one pivot rather than two bowls on one continuous shaft. Slightly offset both shafts and bowl centres through the edge-on pose, then converge them onto their aligned egg crowns. The shorter lower-wall spoon contacts the upper, visually farther belt around the first clink while the longer upper-wall spoon is still travelling to the lower, visually nearer belt. Both hits remain one simultaneous direct-damage batch, and the complete paired mechanism remains one future positional tool socket.

**Reason:** Swapping internal bowl identities did not change the visible silhouette: the renderer drew the same two unmarked bowls, collapsed them onto one edge-on centre, and exposed only one shaft. Two persistent shaft tracks make the wall-to-belt correspondence mechanically inspectable, while a brief first-contact cue turns the existing clink order into visible depth feedback.

**Supersedes:** D025 and D027's single continuous-shaft presentation only. D027's lower-wall-to-farther-belt mapping, all paired circuit mappings, the two-target ceiling, clink feedback, and simultaneous resolver behaviour remain.

## D029 — Resolve one telescoping spoon near first, then far

**Status:** accepted

**Decision:** Keep the universal Day 3 hairpin, five independent column levers, and their 1+10, 2+9, 3+8, 4+7, and 5+6 mappings. Replace each two-spoon mechanism with one ordinary single-bowl spoon pinned to the wall on a telescoping handle. A pull first extends the still-upright spoon on the wall, then tips it onto the lower, visually nearer bay. Resolve its direct damage, Cuckoo echoes, hatches, and surviving Plover retreat completely. The spoon then returns fully upright, retracts on the wall, and performs a second complete throw onto the upper, visually farther bay, resolving that hit against the resulting live state. Both contacts occur even when empty. Only after both contacts does the belt advance once and the action spend one thwack; meeting the score target on the near hit does not skip the far hit.

**Reason:** The paired and double-bowled versions repeatedly made the resting and falling geometry difficult to reconcile and left tool identity ambiguous. One familiar bowl has a stable silhouette and preserves the forceful Days 1–2 landing. Its visible extension and retraction explain both reach and timing, while full resolution between contacts creates a readable two-stage interaction with useful engine-building potential.

**Supersedes:** D024–D028's paired/double-spoon presentation and simultaneous Day 3 damage batch, and restores D023's extending single-spoon direction with explicit near-first/far-second timing. The hairpin route, five independent mappings, two-target ceiling, Pink weakness, Plover screen-left rule, one conveyor advance, and one-thwack cost remain.

## D030 — Make every bird contribute one egg

**Status:** accepted

**Decision:** Every producer lays exactly one egg per day. The starting flock contains ten Chicken producers, three Cuckoo producers, and two Plover producers, preserving the existing daily pool of ten Chicken, three Cuckoo, and two Plover eggs. Every producer selected after a successful day adds one bird and therefore exactly one egg to each subsequent daily pool.

**Reason:** A direct one-bird, one-egg relationship makes flock size, daily output, reward weight, removal, and shuffle probability easier to reason about as the flock becomes the run's deck. Doubling the starting Chickens preserves the existing 15-egg opening composition while removing Chicken's exceptional two-egg producer rule, so this structural simplification does not also rebalance the opening pool.

**Supersedes:** D011's five two-yield Chicken producers and D013's two-egg Chicken reward. D011's starting egg composition, finite once-shuffled pool, preview, and exhaustion rules remain; D013's three distinct offers, mandatory selection, established species pool, and failure behavior remain.

## D031 — Make flock growth optional

**Status:** accepted

**Decision:** A successful day no longer requires adding a producer. The flock grows only when the player deliberately chooses a recruitment opportunity. When a producer is recruited, it still adds exactly one bird and therefore one egg to every subsequent daily pool. Failed days grant no recruitment or other between-day build opportunity.

**Reason:** Compulsory recruitment makes the flock expand regardless of the intended build, while a separate removal option can then feel like spending a reward merely to undo forced growth. Optional recruitment lets adding, improving, or thinning the flock become genuine competing directions and keeps the one-bird, one-egg relationship strategically meaningful.

**Supersedes:** D013's mandatory post-success producer selection and D030's implication that every success adds a producer. D013's established species pool and offer legibility remain; D030's one-bird, one-egg production rule and starting flock remain.

## D032 — Unify optional progression in one cash shop

**Status:** accepted

**Decision:** After each successful day banks its unused-thwack payout, open one unified shop before the next flock loads. Recruiting one bird, retiring one bird, improving a species' base score or Double Yolker chance, and installing optional factory upgrades are all shop transactions that cost cash. The player may make any number of affordable purchases or leave and preserve the balance. A failed day grants no cash or shop visit. The universal free Day 3 hairpin refit remains outside the shop.

**Reason:** Cash already measures efficient play and can supply the opportunity cost directly. One shop lets flock composition, species specialisation, and machine power compete in a single legible economy without an additional destination-choice layer or an oversized permanent Retirement Home option. Allowing several purchases makes an unusually successful run's compounding power an intentional roguelike reward, while saving remains a meaningful choice.

**Supersedes:** D031's single between-day build opportunity, while preserving its optional recruitment and failure restrictions. It also replaces the proposed Farm Store, Retirement Home, and Factory Shop destination split; stock composition, prices, and final upgrade ladders remain prototype questions.

## D033 — Replace species investment with pair merging

**Status:** accepted

**Decision:** In the unified post-success shop, two birds of the same species and quality tier may be queued for merging into one bird of the next tier without spending cash. All queued merges resolve when the player leaves, before the next flock loads, and their outputs cannot become inputs during the same shop visit. Each quality tier multiplies the bird's exact egg base score and exact Double Yolker chance by 1.5, with chance capped at 100%. Gameplay awards and every player-facing score or percentage round down to whole numbers, while later tiers and hidden rolls use the unfloored values. Quality is visible, but whether an egg is actually a Double Yolker remains hidden until it hatches. Hybrids are deferred.

**Reason:** Pair merging turns duplicate recruitment into both a build investment and a way to thin the flock without introducing named-bird XP or species-wide incremental upgrades. Because two daily eggs become one egg worth only 1.5 times as much, the action trades aggregate score and effect frequency for concentration instead of being a free numerical improvement. Delayed resolution prevents one shop visit from collapsing a large flock through several generations before the player experiences the intermediate build. Exact internal arithmetic preserves honest compounding, while floored displays keep play readable.

**Supersedes:** D032's species-wide score and Double Yolker investments and its requirement that every shop transaction spend cash. D032's unified shop, optional recruitment and retirement, cash-funded factory progression, multiple actions, saving, failure restriction, and free Day 3 refit remain.

## D034 — Mirror the starting circuits across the Day 3 hairpin

**Status:** accepted

**Decision:** From Day 3 onward, Red retains slots 1+3 and Blue retains 2+4 across the upper run. Green fires slots 7+9 and Purple fires 8+10 as mirrored alternating circuits across the lower return. Each of those four circuits uses two ordinary spoons and resolves both direct hits as one simultaneous batch. Pink alone bridges the bend at slots 5+6 with one telescoping spoon: it strikes and completely resolves lower slot 6, returns and retracts, then strikes upper slot 5 against the resulting live state. Every lever still has at most two targets, spends one thwack, and advances the conveyor once; Pink remains the only Spoonbill weakness.

**Reason:** Aligned column pairs made an egg remain under the same control relationship at two distant points in its journey. Mirroring the learned alternating circuits makes circuit ownership change repeatedly as an egg advances, creating more positional planning while reusing a pattern the player already understands. The four inverted lower spoons make the return leg physically distinct, and reserving the extender and sequential resolution for Pink gives the bend a unique strategic and presentational identity instead of making all five controls behave alike.

**Supersedes:** D024–D029's five aligned 1+10, 2+9, 3+8, 4+7, and 5+6 column mappings and D029's sequential resolution for every hairpin control. D029's single-bowl Pink extender order, the ten-bay hairpin route, two-target ceiling, Pink weakness, Plover screen-left rule, one conveyor advance, and one-thwack cost remain.

## D035 — Keep every Day 3 spoon on the rear wall

**Status:** accepted

**Decision:** Preserve D034's circuit mappings and resolution, but present all eight ordinary spoons as upright rear-wall mechanisms using the established bowl, handle, hinge, fall, and impact language. Each of the first four screen columns holds two adjacent spoons of different colours: Red with Purple, Blue with Green, Red with Purple, and Blue with Green. Same-coloured spoons across separate columns form the simultaneous gameplay circuits; physical neighbours do not. The single Pink spoon remains the only telescoping mechanism and the only utensil that reaches both rows.

**Reason:** Floor-mounted upward-facing spoons made the return row mechanically literal but abandoned the game's strongest established visual identity and crowded the foreground controls. Adjacent differently coloured wall spoons preserve the more interesting misaligned circuit map while keeping every utensil in the familiar workshop plane. Their repeated colour-and-symbol badges communicate the cross-column pairings, and Pink remains visually exceptional for the same reason that its resolution is exceptional.

**Supersedes:** D034's inverted lower-spoon presentation only. D034's Red 1+3, Blue 2+4, Green 7+9, Purple 8+10, Pink 6→5 resolution, timing, and all gameplay consequences remain.

## D036 — Restore single spoons with target-dependent reach

**Status:** accepted

**Decision:** Preserve D034's circuit mappings and D035's rear-wall placement, but restore exactly one single-bowl telescoping spoon in each of the five screen columns. In columns 1–4, selecting Red or Blue gives the relevant spoon zero extension and one upper-run impact; selecting Green or Purple gives that same physical spoon full extension and one lower-return impact. Pink retains its resolver-authored lower-then-upper sequence and is the only control that uses both reaches during one action.

**Reason:** The desired earlier design was the single spoon whose segmented handle changed length according to its target, not either a paired-head or overlaid-head mechanism. Reusing one physical spoon for the two circuits that cross each column preserves the original five-spoon layout while changing only which target each lever selects.

**Supersedes:** D035's eight-ordinary-spoon presentation. D034's circuit ownership and simultaneous ordinary resolution remain unchanged; Pink's unique sequential two-target action remains unchanged.

## D037 — Put circuit colour into the belt sections

**Status:** accepted

**Decision:** Colour the conveyor belt section beneath every target according to its resolver-authored circuit and render all five physical spoons with neutral brass markings. Do not add a separate coloured pad around the egg. This applies to both the starting five-slot line and the Day 3 hairpin. Levers retain their colour-and-symbol identities.

**Reason:** A Day 3 spoon can serve different circuits at its short and long reach, so colouring the utensil falsely implies that it belongs to only one control. Colouring the belt communicates the positional rule directly and makes the circuit layout part of the machine, rather than an overlay placed beneath each egg. It keeps both rows readable while the spoons are idle and preserves the restored five-single-spoon silhouette.

**Supersedes:** Circuit-coloured spoon markings in D035–D036 and earlier presentation. Circuit mappings, target-dependent reach, lever identity, and resolution are unchanged.

## D038 — Charge for a deliberately selected merge pair

**Status:** accepted

**Decision:** In the unified shop, first choose an owned species-and-quality group, then choose from the partner groups that are currently eligible. Every owned group remains listed; a group with no valid partner is visibly unavailable. For now, only another bird of the same species and quality is eligible. Queueing one pair immediately reserves both birds and spends cash equal to the output tier: £1 for Prize, £2 for Champion, then £3 for Tier 3 and so on. Insufficient cash rejects the request without changing cash or reservations. Outputs still resolve only when the player leaves and cannot chain into another merge during the same visit.

**Reason:** A tier-scaled fee makes merging participate in the shop's shared opportunity cost without overwhelming the existing quantity and effect-frequency sacrifice. Separating the chosen bird group from its eligible partners keeps unavailable possibilities legible and gives future partner rules a clear presentation boundary without inventing named individual birds now.

**Supersedes:** D033's cash-free merge rule and direct presentation of a complete pair as one shop action. D033's exact 1.5 quality multiplier, exact internal arithmetic, delayed output resolution, same-visit chaining restriction, hidden Double Yolker result, and deferral of hybrids remain.

## D039 — Recycle fallen eggs through one permanent track

**Status:** accepted

**Decision:** Use the original five-slot conveyor and its Red 1+3, Blue 2+4, and Pink 5 circuits on every day. An unhatched egg that leaves slot 5 enters a visible bin with its remaining damage and other egg facts intact. Whenever slot 1 needs a new egg and the hopper is empty, shuffle the complete bin into a new hopper before loading. Eggs that hatch leave the day's pool. Seed every initial and recycled shuffle, include the bin in exhaustion and end-of-day cleanup, and keep the existing 20-thwack limit and targets for the first prototype.

**Reason:** The single line is more fun and easier to read than the wrapped route. Recycling preserves the positional consequence of falling as lost time and changed order without permanently erasing an egg or prior damage. It also makes the flock behave as a cycling deck while the thwack limit prevents infinite recovery.

**Supersedes:** D011's finite once-shuffled pool, permanent belt-end discard, and no-reshuffle rule; D021–D029 and D034–D037's Day 3 loop or hairpin topology, extra circuits, refit, and associated spoon presentation. The original five-slot mappings, seeded retries, egg effects, damage order, targets, cash payout, and shop progression remain.

## D040 — Let quality multiply maximum toughness

**Status:** accepted

**Decision:** Each quality tier multiplies an egg's exact maximum toughness by the same 1.5 factor already applied to exact score and Double Yolker chance. Round maximum toughness up to the whole amount of damage required to hatch, while later tiers compound from the exact unrounded value. Show the resulting required damage in merge previews and every laid-egg view. Recycled eggs retain their current damage against that scaled maximum.

**Reason:** Recycling makes a smaller flock cycle concentrated eggs more frequently. Scaling both value and shell keeps merging a density trade-off: two eggs with aggregate score and toughness of 2× become one at 1.5×, rather than producing an equally easy high-value egg. Rounding up makes the displayed toughness truthfully equal the damage the player must deal.

**Supersedes:** D033's restriction of the 1.5 quality multiplier to score and Double Yolker chance, plus the active slice's former statement that merging never changes toughness. D033 and D038's pair requirements, exact compounding, score and percentage flooring, fee, reservations, delayed resolution, and same-visit chaining restriction remain.

## D041 — Start with one track's worth of eggs

**Status:** accepted

**Decision:** Start each run with three Standard Chicken producers and two Standard Cuckoo producers. A day begins with 10 thwacks. Day 1 requires 8 points and each later day requires 9 points. The unused-thwack cash rule and all egg values remain unchanged.

**Reason:** A five-egg starting pool matches the five-slot machine, exposes the complete opening composition, and makes the recycler relevant without a long hidden hopper. At 8 points, Day 1 can be won by hatching all three Chickens or by hatching two Chickens and both Cuckoos. The later 9-point target remains mathematically reachable after the obvious first Chicken merge: one 4-point Prize Chicken, one 3-point Standard Chicken, and two 1-point Cuckoos total 9. Reducing the budget alongside the pool prevents the smaller puzzle from producing the oversized cash payouts of a twenty-thwack day.

**Supersedes:** D003's 20-thwack day length, D016's 15-point Day 1 and 20-point later targets, D030's ten-Chicken, three-Cuckoo, two-Plover starting flock, and D039's temporary preservation of those targets and thwack limit. One bird still lays one egg per day, and recruitment remains the route by which Plovers and Spoonbills enter the flock.

## D042 — Recycle only after the conveyor clears

**Status:** accepted

**Decision:** Existing hopper eggs continue loading into slot 1 after non-final thwacks. When the hopper is empty, eggs in the bin remain there until the conveyor is also empty. Only then shuffle the complete bin into a new hopper and load its next egg. Include the waiting bin in exhaustion checks exactly as before.

**Reason:** Recycling as soon as the hopper emptied let missed eggs join a still-moving conveyor one at a time, making the five-egg opening too easy to cycle and weakening the time cost of falling. Requiring a clear conveyor creates distinct waves while preserving the initial stream, paired spoon targets, and Cuckoo adjacency. It also makes five eggs a natural machine-capacity breakpoint: larger flocks delay recycling, while smaller flocks trade score slack and circuit density for a quicker clear.

**Supersedes:** D039's instruction to recycle whenever slot 1 needs an egg and the hopper is empty. D039's visible bin, retained damage, seeded reshuffle, five-slot track, exhaustion rules, and all other behavior remain.

## D043 — Keep every lever active during the day

**Status:** accepted

**Decision:** During an unlocked day, Red, Blue, and Pink remain available even when none of their linked bays contains an egg. Activating a completely empty circuit emits the normal circuit strike, fires every linked spoon, advances the conveyor once, and spends one thwack without dealing damage. Invalid controls, post-day requests, and requests made while presentation is locked remain unavailable or rejected.

**Reason:** Occupancy-based disabling let the machine choose the player's legal actions and hid a useful positional cost. An always-active lever bank makes it possible to spend time deliberately to change future alignment, while the ten-thwack limit and normal conveyor movement keep an empty pull costly: it consumes 10% of the day and can push eggs closer to the bin without scoring.

**Supersedes:** D009's requirement that a circuit contain at least one egg before it is available. D009's fixed circuit mappings, simultaneous direct-damage batch, empty-bowl waste, and resolution order remain.

<!--
Copy for the next entry:

## D044 — Short decision title

**Status:** proposed | accepted | superseded

**Decision:** State the rule or constraint precisely.

**Reason:** Record the trade-off and evidence.

**Supersedes:** Name earlier entries when applicable.
-->
