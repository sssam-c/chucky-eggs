# Current game rules

This file is the canonical player-facing rule truth. Keep it current and concise. Put rationale in `decision-log.md`, interpretation in `design-principles.md`, implementation scope in `vertical-slices.md`, and observations in `playtest-log.md`.

## Game promise

Invest five tactile spoon taps across a table of interacting eggs. Prepare several eggs to break in one tap and multiply their combined Yolk, route visible hopper eggs into new colours and neighbourhoods, then add one egg to adapt that flock for a harder second round.

## Objective and end states

- A run contains two rounds. Grandma begins Round 1 with 10 Hunger and Round 2 with 12 Hunger. Hatch eggs to reduce Hunger to zero in each round.
- A successful round ends immediately after a complete tap cascade reduces Hunger to zero. Grandma does not take another Hunger phase.
- Winning Round 1 opens one egg-reward choice. Winning Round 2 completes the run.
- A round fails if every egg has been opened while Grandma still has Hunger remaining.
- Retrying reproduces the same run seed, round order, reward offers, and chosen reward. Starting a new seed begins a different deterministic run.

## Setup and visible state

- Five ordered cups sit on Grandma's table. At the start of each round, the first five eggs occupy those cups and every later egg waits in the hopper.
- Round 1 shuffles a fixed twelve-egg flock from a visible, replayable run seed: three Chickens, three Cuckoos, two Sparrows, two Plovers, and two Spoonbills.
- Round 2 derives another deterministic order from the same run seed after adding the chosen reward egg to that flock.
- The hopper shows its total waiting count and previews its next three eggs in order.
- Each cup has one neutral spoon operated by the large colour-and-shape button beneath it. From left to right, the fixed button identities are Red Diamond, Blue Circle, Pink Star, Green Triangle, and Gold Square.
- The interface always shows each egg's remaining toughness, Yolk value, applicable effect emblem, current position, available taps, Grandma's current Hunger, and her announced next Hunger increase.
- Grandma's portrait, available taps, Hunger, next increase, and Hunger-phase feedback occupy one persistent right-hand sidebar.
- The interface shows the current round and run seed. A new-seed action changes the deterministic run; a retry action preserves it.
- Every scoring tap briefly creates one numbered liquid Yolk ball above the eggs. Its physical size reflects its exact Yolk value, ranging from tiny low-value drops to massive combo totals. Contributions merge into it from their hatch positions, then that same ball travels directly to Grandma and changes Hunger on impact.
- When one tap breaks two or more eggs, the playfield briefly shows one Double Yolker, Triple Yolker, or higher callout and multiplier surge. A single break uses the same short delivery without a combo callout. No score object remains between taps.

## Eggs

- A **Chicken** has 3 toughness, provides 3 Yolk, and has no additional effect.
- A **Cuckoo** has 4 toughness and provides 1 Yolk. When an egg immediately beside a Cuckoo is directly tapped, that Cuckoo takes the same amount of damage.
- A **Sparrow** has 1 toughness, provides 1 Yolk, and has no additional effect.
- A **Plover** has 6 toughness and provides 4 Yolk. After surviving a direct tap, it swaps with the egg or vacancy immediately to its left when one exists.
- A **Spoonbill** has 5 toughness and provides 4 Yolk. A direct Pink tap deals 2 damage to it instead of 1.
- A **Woodpecker** has 4 toughness and provides 2 Yolk. It is available only as a between-round reward. When it opens, it fires the spoon immediately to its right once for free if that cup is occupied. That spoon uses its own colour and resolves a complete tap, including Cuckoo copies, Spoonbill weakness, Plover movement, further openings, and further Woodpecker taps. A Woodpecker at the right edge, or with an empty cup immediately to its right, fires nothing.
- Current eggs have no intrinsic Double Yolker rolls or hidden quality. “Double Yolker” and higher callouts describe how many eggs one paid tap's complete cascade broke, not a hidden property of an egg.

## Tap phases

- Each Tap phase begins with five paid taps.
- Pressing the button beneath an occupied cup spends exactly one tap after its complete damage, hatch, movement, and refill cascade.
- The button beneath an empty cup cannot be selected.
- Free Cuckoo reactions, Woodpecker taps, and other resolver-authored consequences never spend another tap.
- Every tap begins with a combo count of zero. Count every egg opened by that tap's complete cascade, add their printed Yolk, then multiply the combined Yolk by the number opened. One opened egg therefore has a ×1 multiplier.
- Breaks on separate taps never contribute to the same combo. A paid tap that opens no eggs has no combo result or reset ceremony.
- If Hunger remains above zero after the fifth tap, Grandma's Hunger phase adds the amount announced throughout that Tap phase.
- The first Hunger phase adds 1. Each later phase adds 1 more than the previous phase: +2, then +3, and so on.
- After Grandma's response, a new Tap phase begins with five taps and displays its new announced increase.

## Between rounds

- Winning Round 1 presents three different egg rewards drawn deterministically from the six current reward identities, including Woodpecker.
- The player chooses exactly one offered egg. That egg is added to the fixed flock, increasing Round 2 from twelve eggs to thirteen.
- The chosen egg, its complete known rules, and Round 2's 12 starting Hunger are shown before Round 2 begins.
- Reward selection spends no tap and changes no completed Round 1 result.
- There is no reward after Round 2.

## Tap resolution

Resolve one selected button in this order:

1. Fire that cup's spoon and deal its direct damage to the egg in that cup.
2. Damage each adjacent Cuckoo by the same amount as the direct tap.
3. After the complete damage batch, open every zero-toughness egg from left to right. If the directly tapped egg is a surviving Plover, swap it one cup to the left when possible.
4. For each Woodpecker in that opened batch from left to right, fire the occupied spoon immediately to its right. Resolve each free fire sequentially through the same damage, Cuckoo, opening, Plover, and Woodpecker rules until no follow-up fire remains. Keep every opening in the original paid tap's cascade.
5. Add the printed Yolk of every egg opened by the complete cascade, multiply by the number opened, deliver the one complete result to Grandma, and reduce Hunger by that amount, never below zero. If no egg opened, deliver nothing.
6. Keep opened cups vacant until every free fire is resolved. Then fill vacancies from the hopper in hatch order; simultaneous vacancies therefore refill from left to right.
7. Spend one paid tap. Free fires spend none.
8. End successfully at zero Hunger, fail if no eggs remain, or resolve Grandma's response after the fifth paid tap.

All damage, hatches, movement, refill destinations, phase changes, and end states are resolver-authored facts. Animation and interface timing do not choose or reorder them.

For a scoring tap, each opened egg's printed Yolk visibly merges into one numbered liquid Yolk ball above the eggs. A multi-break ball then displays the tap's multiplier and final total with a Double Yolker, Triple Yolker, or higher callout. The completed ball travels directly to Grandma and the visible Hunger number changes on impact. A single break uses the same brief ball-and-delivery path without a combo callout; no Yolk ball remains between taps.

## Current scope

- The authoritative game is one seeded two-round tabletop run with one between-round egg addition and one reward-only hatch-effect identity, Woodpecker. It has no conveyor movement, bin, Belt Condition, Patience, circuits that strike several starting targets, shop, cash, additional new egg identities, egg quality, or permanent progression.
- The former conveyor implementation is retained as historical code and test coverage, not as current player-facing rule truth.

## Keywords

- **Adjacent:** The cup immediately to an egg's left or right.
- **Direct tap:** Damage from the spoon the player selected, excluding copied Cuckoo damage.
- **Free tap:** A resolver-authored spoon fire caused by an egg effect. It resolves the spoon and egg rules normally but spends no player tap.
- **Break combo:** Every egg opened by one paid tap's complete cascade. Add their printed Yolk and multiply it by the number opened.
- **Hunger:** Grandma's remaining need. Yolk lowers it; her response raises it.
- **Tap phase:** Five paid player taps followed, when necessary, by one announced Grandma response.
- **Yolk:** An egg's printed base value. The complete tap's combo result is what subtracts from Hunger.
