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
