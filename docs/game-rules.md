# Current game rules

This file is the canonical player-facing rule truth. Keep it current and concise. Put rationale in `decision-log.md`, interpretation in `design-principles.md`, implementation scope in `vertical-slices.md`, and observations in `playtest-log.md`.

## Game promise

Invest five tactile spoon taps across a table of interacting eggs. Open cups route visible hopper eggs into new colours and neighbourhoods, so a good tap creates more value than its one point of shell damage.

## Objective and end states

- Grandma begins with 10 Hunger. Hatch eggs to reduce Hunger to zero.
- A successful round ends immediately after a complete tap cascade reduces Hunger to zero. Grandma does not take another Hunger phase.
- The game fails if every egg has been opened while Grandma still has Hunger remaining.
- Restart restores the authored egg order, 10 Hunger, five taps, and the first Hunger phase.

## Setup and visible state

- Five ordered cups sit on Grandma's table. At the start, the first five eggs occupy those cups and every later egg waits in the hopper.
- The authored current egg order is Chicken, Cuckoo, Sparrow, Plover, Chicken, Spoonbill, Cuckoo, Sparrow, Chicken, Spoonbill, Plover, Cuckoo.
- The hopper shows its total waiting count and previews its next three eggs in order.
- Each cup has one directly clickable spoon. From left to right, their fixed colours are Red, Blue, Pink, Red, and Blue.
- The interface always shows each egg's remaining toughness, Yolk value, applicable effect emblem, current position, available taps, Grandma's current Hunger, and her announced next Hunger increase.
- Grandma, her waiting bowl, Hunger, next increase, and Hunger-phase feedback occupy one persistent right-hand sidebar.

## Eggs

- A **Chicken** has 3 toughness, provides 3 Yolk, and has no additional effect.
- A **Cuckoo** has 4 toughness and provides 1 Yolk. When an egg immediately beside a Cuckoo is directly tapped, that Cuckoo takes the same amount of damage.
- A **Sparrow** has 1 toughness, provides 1 Yolk, and has no additional effect.
- A **Plover** has 6 toughness and provides 4 Yolk. After surviving a direct tap, it swaps with the egg or vacancy immediately to its left when one exists.
- A **Spoonbill** has 5 toughness and provides 4 Yolk. A direct Pink tap deals 2 damage to it instead of 1.
- Current eggs have no Double Yolker rolls, hidden quality, or additional hatch effects.

## Tap phases

- Each Tap phase begins with five paid taps.
- Clicking an occupied spoon spends exactly one tap after its complete damage, hatch, movement, and refill cascade.
- A spoon above an empty cup cannot be selected.
- Free Cuckoo reactions and other resolver-authored consequences never spend another tap.
- If Hunger remains above zero after the fifth tap, Grandma's Hunger phase adds the amount announced throughout that Tap phase.
- The first Hunger phase adds 1. Each later phase adds 1 more than the previous phase: +2, then +3, and so on.
- After Grandma's response, a new Tap phase begins with five taps and displays its new announced increase.

## Tap resolution

Resolve one selected spoon in this order:

1. Fire the selected spoon and deal its direct damage to the egg in that cup.
2. Damage each adjacent Cuckoo by the same amount as the direct tap.
3. After the complete damage batch, open every zero-toughness egg from left to right. Each opened egg reduces Grandma's Hunger by its Yolk, never below zero.
4. If the directly tapped egg is a surviving Plover, swap it one cup to the left when possible.
5. Keep opened cups vacant until the complete cascade is resolved. Then fill vacancies from the hopper in hatch order; simultaneous vacancies therefore refill from left to right.
6. Spend one paid tap.
7. End successfully at zero Hunger, fail if no eggs remain, or resolve Grandma's response after the fifth paid tap.

All damage, hatches, movement, refill destinations, phase changes, and end states are resolver-authored facts. Animation and interface timing do not choose or reorder them.

## Current scope

- The authoritative game is one authored tabletop round. It has no conveyor movement, bin, Belt Condition, Patience, circuits that strike several starting targets, flock generation, shop, cash, multiple days, egg quality, or permanent progression.
- The former conveyor implementation is retained as historical code and test coverage, not as current player-facing rule truth.

## Keywords

- **Adjacent:** The cup immediately to an egg's left or right.
- **Direct tap:** Damage from the spoon the player selected, excluding copied Cuckoo damage.
- **Hunger:** Grandma's remaining need. Yolk lowers it; her response raises it.
- **Tap phase:** Five paid player taps followed, when necessary, by one announced Grandma response.
- **Yolk:** The amount an opened egg subtracts from Hunger.
