# UI visual targets

Status: **design hypothesis**, not settled rule truth or implementation scope.

These generated mockups explore a more cohesive presentation direction for the existing game. They preserve the current player loop and should be read alongside `docs/game-rules.md`, which remains authoritative whenever a visual detail conflicts with a rule.

## Targets

- `day-1-gameplay-ui.png`: the five-bay Day 1 machine, redesigned as one integrated brass, enamel, cast-iron, and dark-timber cabinet.
- `general-store-ui.png`: the current recruitment, merging, retirement, factory-upgrade, and leave-shop choices reorganized as an in-world store counter.

## Direction being tested

- Treat HUD plates, controls, and overlays as parts of the same physical workshop.
- Use characterful display type for titles, readable UI type for decisions, and tabular numerals for counters.
- Reserve circuit colour for target ownership and interaction feedback.
- Give machinery firm, weighted movement; eggs elastic movement; and UI panels restrained transitions.
- Reduce permanent instructional copy by putting mappings on their controls and using compact graphical keys.
- Preserve visible keyboard focus, non-colour symbols, mute, and reduced-motion controls.

## Implementation guardrails

- Do not copy generated typography or small raster text directly into the game; rebuild durable UI structure in `.tscn` scenes and theme resources.
- Presentation may animate resolver-authored facts but may not determine results, targets, or event order.
- `ThwackPresenter` and `ProductionLoader` remain the playback-completion owners. `Main` retains the input lock until the active presentation barrier completes.
- Verify the implemented result at 1280×720 and at a materially constrained viewport before treating the direction as successful.
