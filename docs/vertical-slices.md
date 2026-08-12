# Vertical slices

This file describes current implementation and learning scope. It does not override current rules.

## Active slice — Crunchy thwack

### Question

Does striking a chicken egg feel crunchy, physical, and satisfying enough that the player wants to perform all 20 thwacks?

### Settled rules preserved

- The player may thwack any egg in one of five conveyor slots.
- A thwack reduces the chosen egg's toughness by 1, resolves a hatch at 0, and advances all surviving eggs once.
- Eggs pushed beyond slot 5 are discarded.
- A day lasts 20 thwacks; 3 points are required, and all remaining eggs are discarded at the end.
- Chicken eggs have 4 toughness and award 1 point.
- The pipe previews the next three eggs.

### Presentation direction

- Five large foreground keys correspond one-to-one with five upright eggs, cups, and fixed spoon hammers. Pressing a key depresses it toward the player, draws its visible copper linkage, and swings the paired spoon from its rear hinge onto the egg's crown. Idle spoons show their convex backs rather than open bowls. The system pointer remains conventional.
- Use a dark, warm industrial-barn stage with timber, iron, copper, a cyan three-egg supply pipe, cream eggs, and an amber/cyan HUD. Strong silhouettes, chunky outlines, restrained highlights, and limited colors should evoke the pixel-art concept while keeping all game state live rather than baking it into a background.
- Impact should feel dry, brittle, and percussive: metal striking shell, escalating visible cracks, sharp fragments, and weighty movement. It should not feel wet or gory.
- Damage, hatch, conveyor movement, belt-end loss, pipe refill, and day end play in resolver-authored order.
- Input remains locked until the complete presentation sequence reports its barrier complete.

### Hypothesis

A short anticipatory spoon motion, immediate impact response, persistent crack stages, layered crunchy audio, and clearly staged belt consequences will make the repeated action pleasurable while strengthening understanding of what each thwack caused.

### Player-visible path

Inspect the upright eggs and the next three in the left pipe. Click the large key in front of any occupied cup, or focus it with Tab and press Enter. The key sinks, its linked rear spoon winds back and strikes the egg's top. Hear metal and shell layers, and see the egg compress and gain a crack stage. If the egg hatches, see the shell burst and hear a distinct payoff before surviving eggs slide, a doomed egg falls, and the next egg drops and settles from the pipe. Regain control only when every resolved consequence is presented. Complete and restart the same 20-thwack day.

### In scope

- Five fixed key, linkage, cup, and spoon-hammer stations with stable one-to-one spatial mapping.
- Key depression plus spoon anticipation, strike, impact, and recovery.
- Industrial-barn staging that approaches the approved pixel-art composition with live Godot controls and procedural visuals.
- Four visually distinct chicken-shell states.
- Layered damage, hatch, movement, drop, and loss sounds.
- Ordered animation of damage, hatch, belt movement, belt-end loss, and pipe refill.
- Input locking, cancellation/replacement safety, and exactly-once barrier completion.
- Reduced-motion and mute controls or equivalent accessible fallbacks.
- Live tuning at the target 1280×720 viewport.

### Implementation conveniences

- Reuse the current chicken-only deterministic day and resolver events.
- Use one authored sound set before considering randomized variants.
- Use simple shell fragments and motion paths sufficient to judge impact rather than building a general particle framework.
- Keep an ordinary pointer throughout and a clear focus indication on available keys.
- Empty-slot keys remain visibly present but cannot submit requests.

### Outside this slice

- New egg types, point values, hatch effects, layers, or laying schedules.
- Random content generation, progression, upgrades, economy, or persistence.
- Large audio-variation libraries, music, environmental ambience, and final mix/mastering.
- Production-wide visual polish unrelated to thwack causality.

### Exit evidence

- Tests prove one input submits one request, input stays locked throughout playback, resolver events play in order, and cancellation or replacement cannot submit stale commands or complete the barrier twice.
- UI checks prove every key maps to exactly one belt slot and fixed rear spoon, idle spoon backs face the player, and conventional pointer and keyboard behavior remain usable.
- A running-game capture demonstrates ordinary damage, hatch, belt-end loss, pipe refill, day end, restart, reduced motion, and mute at 1280×720.
- Audio inspection confirms impact, shell, hatch, movement, and loss cues remain distinguishable without excessive clipping or harsh repetition.
- A short playtest asks: "Did you ever want to click before the previous thwack finished, and did the impact still feel good on the twentieth hit?"
