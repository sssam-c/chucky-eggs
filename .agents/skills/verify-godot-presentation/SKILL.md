---
name: verify-godot-presentation
description: Build, change, or verify Godot scenes, UI interaction, animation, audio, and resolver-event playback while preserving gameplay ownership and lifetime safety. Use for .tscn composition, reusable controls, focus and overlays, tweens, AnimationPlayer, visual feedback, input locking, presentation barriers, or UI regressions.
---

# Verify Godot presentation

1. Read `docs/contracts/architecture.md`, `docs/contracts/simulation-sequencing.md`, `docs/contracts/testing.md`, and the nearest `AGENTS.md` files.
2. State whether the proposal complies with the Simulation Sequencing Contract. Name the resolved fact or ordered event being presented and the barrier-completion owner.
3. Inspect the existing scene, adapter, presentation owner, and tests. Reuse the canonical component when its contract and lifecycle match.
4. Keep durable hierarchy in `.tscn` files. Use runtime code for state-derived or repeated content when that makes ownership clearer.
5. Render state and submit commands through explicit signals or interfaces. Never calculate a gameplay result, select a target, or mutate domain state in UI or animation code.
6. Handle cancellation, replacement, freed nodes, awaited signals, input locks, and exactly-once command submission explicitly.
7. Add stable behavior or structure tests. Define a concrete running-game check for layout, motion, audio, focus, and constrained viewports.
8. Run focused tests, `sh scripts/test.sh`, and the visual/editor verification path.

Report what the player now sees or can do, the checked viewport and interaction path, and any unverified perceptual risk.
