# Design principles

These principles interpret the current rules. They guide choices but do not override `game-rules.md`.

## Tactility carries deliberate choice

The core action is clicking a physical spoon and seeing one egg respond immediately. Preserve large eggs, generous spoon targets, fast impact feedback, visible cracking, and brief rebound. Tactility should make a meaningful choice pleasurable; it must not disguise a choice that has collapsed into repetitive tapping.

## Combontronics comes from position

Every cup simultaneously determines spoon colour, neighbours, and the destination of a future hopper egg. Prefer egg rules that change the value of those relationships over rules that merely increase a number. A strategically healthy tap may trade immediate Yolk for a better adjacency, colour match, or refill.

Keep one compact rule per egg identity where possible. Chicken and Sparrow establish the baseline; Cuckoo rewards neighbouring taps, Spoonbill values Pink, and Plover changes position. New eggs should interact with at least one existing positional axis without requiring a separate subsystem.

## Five taps make one tactical round

Treat five taps as renewable action economy, not a dwindling run-wide allowance. The player should be able to invest them across eggs, see a complete cascade after each choice, and understand when Grandma will respond.

Grandma's announced increase is enemy intent. Her response should create a round boundary and pressure efficient combinations, not merely interrupt the tapping rhythm. If defensive eggs are explored later, they should contest the announced increase directly rather than introduce another global survival meter.

## Break streaks turn setup into payoff

Reward a route of prepared breaks instead of charging the player to move between spoons. Every paid input must remain one physical tap; spatial commitment comes from preserving the break streak, ordering valuable eggs late, and avoiding a zero-break tap.

The streak multiplier is the round's explosive payoff. It may produce deliberately large jackpots, but it must remain possible to understand which egg advanced the streak and how much multiplied Yolk it contributed. Watch for an authored route that becomes automatic or for base Yolk values that make every non-streak break irrelevant.

## Grandma owns Hunger

Hunger is Grandma's changing condition, not an abstract score. Keep her portrait, bowl, current Hunger, next increase, and phase response together in one persistent sidebar. Keep Taps visually separate as the player's current opportunity.

Yolk lowers Hunger; Grandma's response raises it. Let resolved Yolk collect above the table before moving as one readable payload to Grandma, so the player sees both the combo calculation and its recipient. Use that directional language consistently. Do not reintroduce Appetite, Satisfaction, Patience, or Belt Condition as aliases for the same current loop.

## Consequences stay legible

Show the information needed to make a positional plan: exact remaining toughness, Yolk, spoon colour, applicable effects, occupied cups, and the next three hopper eggs. Visible cracks and animation reinforce those facts but do not replace them.

The current game favours competence over universal uncertainty. If lottery sensation is introduced, confine it to a specific egg or reward so the player can still reason about the surrounding combo. Do not hide every egg's toughness while positioning and tap investment are the main strategic skills.

## Refill is a routing decision

An opened cup remains visibly empty until its complete damage and hatch cascade ends. Then the next hopper egg travels from the hopper into that exact vacancy. Several openings refill in hatch order, which is left-to-right for the current simultaneous damage batch.

The movement must communicate a resolver-authored destination. Animation never chooses a cup, changes queue order, or makes an egg available before the presentation barrier completes.

## Cascades resolve once

The domain owns direct damage, Cuckoo copies, hatch order, Plover movement, Yolk, refills, paid taps, Hunger phases, and end states. UI submits one spoon request. Presentation plays the ordered facts, locks further input until completion, and cancels cleanly on restart or replacement.

Free reactions create efficiency but never spend hidden taps. Each egg opens at most once, each vacancy receives at most one hopper egg, and success after a complete cascade takes precedence over Grandma's response.

## Pressure must create drama, not inevitability

Escalating Hunger prevents endless setup, but it also punishes a player who is already behind. Tune it so a poor phase creates urgency without making the remaining result feel predetermined. Watch for players mentally conceding once Hunger rises above its starting value.

Do not add progression, economies, or a large species roster to compensate for a weak tap decision. First establish that players sometimes reject the best immediate hatch to construct a stronger later position.

## Decisions before decoration

Keep the current authored round reproducible while its strategic texture is tested. Add randomness, content, and progression only when they answer a demonstrated problem. Production art can replace the existing placeholders without changing the scene's causal hierarchy: hopper on the left, eggs and spoons at the centre, Grandma and Hunger on the right.
