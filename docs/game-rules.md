# Current game rules

This file is the canonical player-facing rule truth. Keep it current and concise. Put rationale in `decision-log.md`, interpretation in `design-principles.md`, prototype scope in `vertical-slices.md`, and observations in `playtest-log.md`.

## Game promise

Choose which eggs deserve the spoon while every thwack carries the whole conveyor closer to the edge. Crack enough eggs to meet the day's target, knowing that saving every egg is impossible.

## Objective and end states

- A day lasts exactly 20 thwacks.
- Hatch chicken eggs to score at least 3 points by the end of the day.
- The day succeeds at 3 or more points and fails below 3 points.
- After the twentieth thwack resolves, all eggs left on the conveyor or in the pipe are discarded without scoring.

## Player loop

Inspect the five conveyor slots, the next three eggs in the pipe, the score, and the visible thwack countdown. Choose any egg on the conveyor to thwack, balancing its remaining toughness against how close every egg is to the end.

## Setup and state

- The conveyor has five ordered slots. Slot 1 receives eggs and slot 5 is beside the drop.
- The day begins with one chicken egg in slot 1 and the next three chicken eggs visible in the pipe.
- A chicken egg has 4 toughness and is worth 1 point when hatched.
- The pipe is continuously supplied with chicken eggs, always shows the next three, and drops one into slot 1 after each non-final thwack.
- Egg toughness, current score, and remaining thwacks are always visible.

## Actions and resolution

Each turn, the player must thwack any one egg currently on the conveyor. Resolve the thwack in this order:

1. Reduce the chosen egg's toughness by 1.
2. If its toughness reaches 0, hatch and remove it, then gain 1 point.
3. Advance every surviving conveyor egg one slot.
4. Discard any egg that moves past slot 5 without scoring.
5. Spend one of the day's 20 thwacks.
6. If the day continues, drop the next pipe egg into slot 1 and refill the visible pipe preview.

Hatching an egg never prevents the conveyor from advancing. Partially damaged eggs retain their remaining toughness until they hatch or are discarded.

## Exceptions and glossary

- **Thwack:** The player's single action for a turn and the unit of day time.
- **Toughness:** The number of further thwacks an egg needs before it hatches.
- **Discarded:** Removed without hatching or awarding points.
