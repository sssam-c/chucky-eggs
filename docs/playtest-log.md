# Playtest log

Append observed evidence. Keep observation, interpretation, and proposed response separate.

<!--
## YYYY-MM-DD — Build or slice name

**Question:** What was this session trying to learn?

**Context:** Who played, for how long, with what build and instructions?

**Observed:** What did the player actually do or say?

**Interpretation:** What might explain the observation? Label uncertainty.

**Proposed response:** What is the smallest next change or test?
-->

## 2026-08-13 — Three-egg opening-day build

**Question:** Does the five-slot opening day provide enough reward and freedom to explore Chicken, Cuckoo, and Plover decisions?

**Context:** Informal developer playtest of the current 20-thwack authored day with 4-toughness Chickens, adjacent Cuckoos, and 6-toughness Plovers.

**Observed:** The opening felt too constrained to experiment effectively, and the satisfying payoff of breaking an egg happened too rarely.

**Interpretation:** The former 4-toughness Chicken baseline consumes too many thwacks now that Day 1 also asks the player to explore two positional special eggs.

**Proposed response:** Prototype Chickens at 3 toughness while preserving their 3-point value, the 10-point target, the 20-thwack day, and all special-egg rules.

## 2026-08-13 — Plover payoff

**Question:** Does the Plover's hatch reward match the difficulty of managing it?

**Context:** Informal developer play of the current 6-toughness Plover with retreat behavior and a 2-point hatch value.

**Observed:** The Plover was described as a nightmare to manage in play, and its existing payoff felt too low for that commitment.

**Interpretation:** The positional disruption and six required damage make the Plover read as a high-commitment prize, while 2 points frames it as a low-value nuisance.

**Proposed response:** Test the accepted 4-point value while preserving toughness and retreat behavior.

## 2026-08-14 — Wrapped conveyor legibility

**Question:** Does the optional seven-bay return make conveyor growth and movement easy to reason about?

**Context:** Informal developer review of the running workshop and wrapped-conveyor build, followed by sketches comparing a small return with a full screen-width loop.

**Observed:** The seven-bay return was described as “quite hard to reason about.” Discussion also exposed that route-relative Plover retreat would appear to change screen direction when the conveyor turns.

**Interpretation:** The small return introduces a new movement direction without enough repeated spatial structure to teach it, and calling Plover's effect “back” couples an egg rule to route geometry that is already doing other explanatory work.

**Proposed response:** Test a universal eleven-bay Day 3 loop with repeated overhead columns, a three-bay Pink turn, explicit route arrows, and a literal screen-right Plover hop.

## 2026-08-14 — First eleven-bay composition

**Question:** Does the initial full-loop composition make the accepted topology feel like a coherent machine?

**Context:** Informal developer review of the first running 1280×720 Day 3 loop, with scaled-down eggs and spoons and the three circuit controls placed inside the return.

**Observed:** The composition was described as looking “terrible.” The centre controls crowded the route, the scaled station labels were difficult to read, and the overhead spoons collided visually with the persistent header.

**Interpretation:** The problem appears presentational rather than mechanical: too many high-contrast elements compete in the centre while the scale reduction weakens the eggs and physical spoons that should explain the machine.

**Proposed response:** Keep the eleven-bay rules, move controls below the loop, enlarge eggs and station labels, shrink and lower the overhead spoon silhouettes beneath the header, and reduce the paired-column linkages to secondary visual information.

## 2026-08-14 — Spoon reach on the compact loop

**Question:** Can the machine itself communicate the 4/4/3 circuit mapping without asking the player to trace abstract linkage lines?

**Context:** Informal developer review of the cleaned-up eleven-bay composition, with separated upper and lower casings and reduced overhead spoon silhouettes.

**Observed:** The suggested layout was to make Pink visibly form a `]`, let the upper and lower conveyors touch, and make every spoon large enough to visibly hit all slots it corresponds to.

**Interpretation:** The remaining comprehension cost comes from one small spoon standing in for several remote logical targets. Giving each physical assembly the correct number of visible heads turns circuit reach into an object silhouette, while touching casings make the route read as one double-decker machine.

**Proposed response:** Test four two-head Red/Blue column spoons and one three-head Pink bracket, with each head animating from a clear stored position to the exact centre of its target bay.

## 2026-08-14 — Remove the target from the bend

**Question:** Can the Day 3 machine retain the folded route without forcing a special spoon or egg holder at the turn?

**Context:** Iterative mockup review compared the three-bay Pink bracket with a simpler five-over-five hairpin whose bend contains no target.

**Observed:** The bracket and bucket-like holders were rejected as visually awkward and unlike the existing egg-and-spoon implementation. The ten-bay alternative—top 1–5, tight bend, bottom 6–10—was accepted as a better direction when the tracks touched, eggs sat directly on the belt, and the original spoon silhouette was enlarged rather than duplicated.

**Interpretation:** The bend does not need to carry circuit balance. Excluding it restores a repeated five-column grammar and preserves Pink's relative reach at two targets against Red and Blue's four.

**Proposed response:** Implement the universal Day 3 refit as a ten-bay hairpin with five enlarged single spoons, bare-belt eggs, a target-free bend, and literal screen-right Plover hops.

## 2026-08-15 — Single-track legibility reconsidered

**Question:** Is the wrapped Day 3 route adding more fun and readable planning than the original five-slot line?

**Context:** Informal developer assessment after iterating and playing the single-line and wrapped-conveyor versions.

**Observed:** The game was described as more fun and more legible when it used a single track.

**Interpretation:** The hairpin's additional route and control grammar may be spending comprehension on topology rather than strengthening egg-position decisions. Letting fallen eggs return could preserve time pressure and flock texture without doubling the visible machine.

**Proposed response:** Prototype one five-slot track on every day. Move unhatched fallen eggs into a visible bin with damage intact, and reshuffle the bin into the hopper whenever the hopper is empty. Test unchanged targets and thwack limits before tuning.

## 2026-08-16 — Immediate recycling makes Day 1 too easy

**Question:** Does the five-egg, ten-thwack opening make bin recovery costly enough?

**Context:** Informal playtest after changing the starting flock to three Chickens and two Cuckoos, reducing the day to ten thwacks, and setting the opening target to 8.

**Observed:** The smaller starting flock felt better, but Day 1 was still described as too easy to clear. Immediate bin-to-hopper recycling made it easy to cycle fallen eggs back into a conveyor that was still occupied, effectively returning them one at a time.

**Interpretation:** Hopper exhaustion alone does not create a strong enough tempo boundary. The live conveyor lets a recycled egg rejoin the same wave before the previous one has resolved.

**Proposed response:** Keep ordinary hopper feeding unchanged, but require both hopper and conveyor to be empty before reshuffling the bin into a new hopper. Test whether this creates a meaningful five-egg capacity breakpoint without making recovery irrelevant inside ten thwacks.

## 2026-08-16 — Automated all-lever strategy probe

**Question:** Does keeping every lever active create useful positional agency without making empty pulls dominant, and which Day 1 tuning lever best addresses the observed ease of the five-egg opening?

**Context:** Automated resolver-level study, not a human fun or comprehension test. Exact search evaluated every reachable action route across 50 seeds for each configuration. Four policies then played 2,000 seeded runs per configuration: an occupied-target greedy policy, random selection among occupied circuits, unrestricted random selection, and a two-ply tactical policy with perfect seed and hidden-outcome information. The configurations were the current 8-point/10-thwack Day 1, the same flock at a 9-point target, the four-egg post-Chicken-merge flock at 9 points, +1 toughness on every starting Chicken and Cuckoo at 8 points, and the current 8-point flock with 9 thwacks.

**Observed:**

| Configuration | Exact wins | Fastest-win range | Occupied greedy | Random occupied | Perfect-info two-ply |
| --- | ---: | ---: | ---: | ---: | ---: |
| Current Day 1: target 8, 10 thwacks | 50/50 | 6–8 pulls | 100.0% | 89.0% | 100.0% |
| Current shells: target 9, 10 thwacks | 50/50 | 6–9 pulls | 71.9% | 54.3% | 100.0% |
| Post-merge flock: target 9, 10 thwacks | 50/50 | 7–10 pulls | 66.4% | 51.4% | 100.0% |
| +1 starting toughness: target 8, 10 thwacks | 50/50 | 6–10 pulls | 17.4% | 11.6% | 50.7% |
| Current Day 1: target 8, 9 thwacks | 50/50 | 6–8 pulls | 80.7% | 65.2% | 100.0% |

Across all 250 exact seed/configuration cases, an empty pull never shortened the fastest win and was never required by every fastest route. It could appear in an equally fast route in 25/50 current Day 1 seeds, 30/50 target-9 seeds, 36/50 post-merge seeds, 14/50 tougher-shell seeds, and 25/50 nine-thwack seeds. Red's occupied opening was always at least tied for the fastest route; opening with empty Blue or Pink was never strictly better. Representative equal-speed routes used an empty pull to change alignment before creating later paired hits and Cuckoo echo batches. Unrestricted random play won only 7.9% of current Day 1 runs, confirming that repeated empty pulls consume the budget rapidly rather than creating free cycling.

The current Day 1 exact routes always retained at least two thwacks. At target 9, 23/50 fastest routes used nine pulls. In the post-merge case, 17/50 fastest routes required the final tenth pull. With +1 starting toughness, 32/50 fastest routes needed nine or ten pulls.

**Interpretation:** The always-active lever rule appears strategically safe in this sample. Empty pulls expand the set of viable routes but do not create a faster dominant strategy; their value is expressive and positional rather than economic. The opening choice remains weakly biased toward Red, so the rule does not by itself create a compelling first-turn dilemma.

The current 8-point opening is a forgiving tutorial and is consistent with the prior human observation that Day 1 feels easy. Raising every starting shell by one is likely the wrong response: it suppresses ordinary-policy success sharply and delays hatches, while the post-merge flock is already tight enough that one third of exact samples need all ten pulls. A 9-point target creates a stronger but still completely solvable puzzle with the existing hatch cadence. A 9-thwack opening is a gentler alternative that preserves both 8-point scoring routes, but giving the opening day less time than later days is harder to explain and causes successful tactical play to bypass recycling more often. These are balance and strategic-potential inferences; no automated policy establishes whether the choices feel fun or legible to a new player.

**Proposed response:** Keep all levers active and do not increase starting or merged-egg toughness. Human-test the current 8-point opening against a 9-point opening under the same ten-thwack budget, watching whether the higher target improves tension without collapsing the perceived scoring routes into “hatch all three Chickens.” If an immediate numeric prototype is needed, target 9 has stronger support than tougher shells; retain the 8-point version as the control.

## 2026-08-19 — Streak scoring readability

**Question:** Does the centre-stage break-streak celebration make the multiplied Yolk payoff satisfying and understandable?

**Context:** Informal playtest of the accepted five-cup Hunger game after adding consecutive-break multipliers, named “Double Yolker!” and higher callouts, a temporary Yolk pool, and delivery to Grandma.

**Observed:** The scoring felt good, but it advanced too quickly and was difficult to parse.

**Interpretation:** The mechanic's affective payoff is promising; the immediate problem is presentation bandwidth. Showing the streak, formula, countable pool, score, and delivery together makes several representations compete during a short cascade.

**Proposed response:** Keep the streak rule unchanged. Test a fixed streak badge and bowl, one formula resolving to one award, a compact final parcel, and an explicit subtraction on Grandma before Hunger updates.

## 2026-08-19 — Consolidated workshop interface

**Question:** Can the table remain tactile and celebratory while reducing permanent score clutter and making the dark workshop space feel intentional?

**Context:** Iterative visual mockups removed the title, moved Taps, streak arithmetic, Hunger, and response state into Grandma's sidebar, replaced clickable spoons with large shape-coded buttons, and added a hopper chute plus code-native workshop structure and lighting.

**Observed:** The consolidated sidebar was described as “a lot cleaner”; the warmer workshop treatment looked “MUCH better”; and the unique button colours and shapes “look great.” The final mockup was accepted with neutral spoon heads and approved for implementation.

**Interpretation:** Stable ownership matters more than keeping scoring physically central. Grandma's rail can contain the complete round state without feeling like an abstract HUD when the table preserves large eggs, physical cups, neutral spoon motion, and chunky controls. Environmental structure and warm light make negative space support the workshop rather than read as unfinished UI.

**Proposed response:** Implement the accepted composition without changing cascade rules, score timing, phase timing, or resolver ownership. Retain the unique Red Diamond, Blue Circle, Pink Star, Green Triangle, and Gold Square buttons and verify readability at both supported viewports.

## 2026-08-19 — Persistent scoring interrupts the tapping rhythm

**Question:** Did the consolidated score card solve readability without slowing the tactile loop?

**Context:** Informal playtest of the implemented workshop interface with the accepted cross-tap break streak, per-hatch equation, compact delivery, explicit subtraction, and locked presentation barrier.

**Observed:** The scoring was described as “too slow and unresponsive” and “quite interruptive.” A same-tap alternative—Double and Triple Yolker only when several eggs break from one tap—was proposed and accepted.

**Interpretation:** The earlier presentation solved simultaneous information competition by serializing every representation of the result. That made ordinary success remove control for much longer than the physical tap and gave single breaks nearly the same ceremony as jackpots. Counting only same-tap breaks makes the multiplier causally visible, removes persistent bookkeeping, and lets celebration frequency track event rarity.

**Proposed response:** Replace the persistent streak with a flat same-tap multiplier over combined printed Yolk. Give misses no scoring feedback, make single breaks update Hunger directly, and reserve one short resolved equation for multi-break taps. Measure the complete ordinary-break and two-break interaction paths and human-test whether Cuckoo supplies enough combo opportunities.

## 2026-08-19 — Same-tap scoring happens outside the action

**Question:** Does the compact same-tap score treatment make the result visible without interrupting the tapping rhythm?

**Context:** Informal developer playtest after replacing the cross-tap streak with same-tap Double and Triple Yolker results, while retaining the temporary arithmetic and delivery inside Grandma's sidebar.

**Observed:** The scores and named combo results were described as insufficiently visible in the centre of play and as happening “off screen.” A shimmering, gluey, semi-liquid numbered Yolk ball was proposed: Yolk from broken eggs would merge into it, it would grow and resolve the multiplier, then travel straight to Grandma and lower Hunger on arrival. The direction was accepted for implementation.

**Interpretation:** The short duration is no longer the main readability problem. The player's gaze remains on the cups and breaking eggs, while the score appears in a peripheral status rail. Keeping the result in that rail spatially disconnects cause from value even when the arithmetic is concise.

**Proposed response:** Materialise each scoring tap as one transient central Yolk ball. Animate resolver-authored hatch contributions into it, keep one crisp total on its face, reserve the surge and callout for multi-breaks, and make that same object the delivery to Grandma. Preserve a static reduced-motion equivalent and remove the obsolete sidebar score card.

## 2026-08-19 — Central Yolk needs more weight and value contrast

**Question:** Does the transient central Yolk ball make scoring sufficiently satisfying and readable?

**Context:** Informal developer playtest of the implemented hatch-to-ball-to-Grandma flow with a shimmering numbered liquid ball and same-tap multiplier surge.

**Observed:** The Yolk reveal and score still felt somewhat too speedy. Egg cracking could be more satisfying, and Yolk sizes were requested to reflect score strongly, ranging from tiny to massive.

**Interpretation:** Central placement repaired the causal path, but similar-sized awards give a 1 and an 8 too much of the same visual weight. The existing hatch's short scale-and-fade also removes the physical object before its failure can become a payoff. The desired extra duration belongs inside fracture, emergence, absorption, growth, and impact rather than after them.

**Proposed response:** Add a staged code-native shell rupture, map exact Yolk to a steep capped size curve, reveal each differently sized contribution before merging, and lengthen active motion modestly through multiplier growth and delivery. Verify tiny, ordinary, and combo values at both supported viewports before further timing changes.

## 2026-08-20 — Foundational round has tactical texture

**Question:** Does the five-tap Hunger round contain real decisions before content and progression are added?

**Context:** Player report after playtesting the current foundational round. The number of sessions, routes, and exact build were not supplied.

**Observed:** The player reported that the round “does have texture and real decisions in play.” No concrete tap sequence or decision example was recorded with the report.

**Interpretation:** This is sufficient directional evidence to stop treating progression as compensation for a weak tap decision, but it does not close the more specific questions about hopper-preview use, setup taps, or dominant authored routes.

**Proposed response:** Prototype one seeded two-round run with a single current-species egg reward and a harder second round. Continue collecting concrete examples of rejected immediate hatches, planned combos, and preview-driven choices.

## 2026-08-20 — Seeded two-round greedy-policy probe

**Question:** Do unrestricted seeded orders make the second round meaningfully harder, and do they expose obviously suspicious variance before human testing?

**Context:** Automated application-layer probe across seeds 20260800–20260899. One intentionally weak deterministic policy repeatedly tapped the occupied egg with the lowest remaining toughness. On a Round 1 win it chose one of the three offered eggs by `seed mod 3`, then applied the same policy to Round 2. This was not an exact solver or a human playtest.

**Observed:** The policy won 53 of 100 Round 1s and 8 of those 53 Round 2s.

**Interpretation:** Round 2 is materially harder for a policy that ignores adjacency, spoon colour, hopper order, and setup. The failures do not establish that any seed is unwinnable; they show that seed quality and the provisional 12 Hunger tuning cannot be validated by a naive policy.

**Proposed response:** Human-test at least three seeds and use a stronger tactical or exact search before curating seeds or changing Round 2 Hunger. Preserve unrestricted deterministic shuffles as prototype scope until evidence identifies hostile arrangements.
