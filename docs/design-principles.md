# Design principles

These principles interpret the current rules. They guide choices but do not override `game-rules.md`.

## Tactility carries deliberate choice

The core action is pressing a large colour-and-shape button, seeing its neutral spoon fire, and watching one egg respond immediately. Preserve large eggs, generous button targets, fast impact feedback, visible cracking, and brief rebound. Tactility should make a meaningful choice pleasurable; it must not disguise a choice that has collapsed into repetitive tapping.

## Combontronics comes from position

Every cup simultaneously determines spoon colour, neighbours, and the destination of a future hopper egg. Prefer egg rules that change the value of those relationships over rules that merely increase a number. A strategically healthy tap may trade immediate Yolk for a better adjacency, colour match, or refill.

Keep one compact rule per egg identity where possible. Chicken and Sparrow establish the baseline; Cuckoo rewards neighbouring taps, Spoonbill values Pink, and Plover changes position. New eggs should interact with at least one existing positional axis without requiring a separate subsystem.

## Five taps make one tactical round

Treat five taps as renewable action economy, not a dwindling run-wide allowance. The player should be able to invest them across eggs, see a complete cascade after each choice, and understand when Grandma will respond.

Grandma's announced increase is enemy intent. Her response should create a round boundary and pressure efficient combinations, not merely interrupt the tapping rhythm. If defensive eggs are explored later, they should contest the announced increase directly rather than introduce another global survival meter.

## Same-tap combos turn setup into payoff

Reward a board of prepared eggs instead of charging the player to move between spoons. Every paid input must remain one physical tap; spatial commitment comes from weakening several eggs and arranging one strike that opens them together before Grandma responds.

The combo multiplier is the round's explosive payoff. Count only eggs opened by one tap, add their printed Yolk, and multiply once by that count. This makes the jackpot causally identical to the visible cascade and removes persistent score bookkeeping. Materialise those facts as one liquid Yolk ball where the eggs break: contributions merge into it, its number changes once through the multiplier, and the same object leaves for Grandma. Single breaks use that route briefly; misses do nothing; reserve the named callout and multiplier surge for multi-break taps. Watch for an authored route that becomes automatic, for Cuckoo becoming the only practical combo enabler, or for the flat multiplier making single breaks irrelevant.

## Grandma owns Hunger

Hunger is Grandma's changing condition, not an abstract score. Keep her portrait, Taps, current Hunger, next increase, and phase response together in one persistent sidebar. The playfield may briefly own the source of a change—the Yolk visibly produced by the eggs—but Grandma owns its destination and consequence.

Yolk lowers Hunger; Grandma's response raises it. Use one physicalised chain for scoring: hatch-position contributions merge into a numbered ball, the ball resolves any same-tap multiplier, it travels straight to Grandma, and Hunger changes on impact. Do not duplicate that fact in a sidebar score card or serialize tokens, unresolved arithmetic, resolved arithmetic, a replacement parcel, and repeated holds. The central ball is transient, never resting HUD state. Use the direction from eggs to Grandma consistently. Do not reintroduce Appetite, Satisfaction, Patience, or Belt Condition as aliases for the same current loop.

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

Keep the current authored round reproducible while its strategic texture is tested. Add randomness, content, and progression only when they answer a demonstrated problem. Production art can replace the existing placeholders without changing the scene's causal hierarchy: hopper on the left; eggs, cups, neutral spoons, controls, and transient Yolk at the centre; Grandma and persistent round status on the right. Until bespoke art is justified, use native shapes, panels, planks, light pools, and other inexpensive environmental cues to make negative space feel intentional.
