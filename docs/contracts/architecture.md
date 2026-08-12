# Architecture contract

Dependencies point inward toward deterministic rules.

- `src/domain/`: pure rules, state, commands, transitions, and resolver-authored events.
- `src/core/`: injected seams such as RNG, clocks, persistence interfaces, and IDs.
- `src/game/`: application services that accept requests, invoke domain behavior, and coordinate presentation requests.
- `src/ui/`: Godot scenes and adapters that render state and submit commands.
- `src/presentation/`: animation, audio, and visual playback of resolved events.

## Hard boundaries

- Domain code has no Godot node, scene-tree, input, tween, animation, rendering, persistence, or wall-clock dependency.
- UI never mutates domain state directly.
- Presentation never invents gameplay facts or chooses event order.
- Randomness and time are injected and replaceable by deterministic fakes.
- Cross-layer data is explicit. Avoid autoloads, groups, and deep node paths as substitutes for ownership.

Shared behavior has one canonical implementation. Extract only when repeated code shares the same invariant, policy, lifecycle, and reason to change.
