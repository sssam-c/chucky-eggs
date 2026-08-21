# UI visual targets

Status: **design hypothesis**, not settled rule truth or implementation scope.

These generated mockups explore a more cohesive presentation direction for the existing game. They preserve the current player loop and should be read alongside `docs/game-rules.md`, which remains authoritative whenever a visual detail conflicts with a rule.

The current build intentionally does not use these mockups or any generated raster as production art. Birds are temporary geometric silhouettes; eggs use one generic temporary shell; each species shares one flat colour across both and is named outside the art. These images remain composition references only, while final asset style and execution are reserved for the commissioned artist.

## Targets

- `day-1-gameplay-ui.png`: the five-bay Day 1 machine, redesigned as one integrated brass, enamel, cast-iron, and dark-timber cabinet.
- `general-store-ui.png`: a superseded multi-action shop composition retained only as visual-history reference. Its recruitment, pairing, and factory controls no longer describe the current rules; only its workshop material language remains relevant to the separate bird-reward and flock-overview screens.
- `effect-trigger-syntax-storyboard-v1.png`: a superseded trigger-equation exploration retained as visual history. Its timing comparison remains useful, but its large composed badges do not represent the preferred clean egg-face syntax.
- `effect-trigger-syntax-icon-board-v1.png`: a superseded trigger-equation exploration retained as visual history. Its trigger silhouettes remain useful, but its separate trigger and instruction plaques are too large and its broken main On Hatch egg must not be read as the intended resting state.
- `egg-symbology-roster-concept-v1.png`: a superseded fixed-zone exploration retained as visual history. It correctly grounds the symbols in the current roster, but separates Yolk payout from other effects that resolve at the same crack moment and leaves little room for effects to develop.
- `egg-symbology-roster-concept-v2.png`: a superseded two-lane exploration retained as visual history. It establishes the shared crack payload successfully, but places Tap sigils below toughness and leaves an unnecessary Tap-lane mark on plain eggs.
- `egg-symbology-roster-concept-v3.png`: a superseded temporal-hierarchy exploration retained as visual history. Its top/middle/base ordering is sound, but the spoon-notch and cracked-shell category marks repeat information already communicated by position.
- `egg-symbology-roster-concept-v4.png`: the source hierarchy for the current egg-face syntax, retained with superseded species-coloured shells and bird-icon placement. The large central toughness number is the sole temporal divider: optional Tap effects appear directly above it, a large translucent species silhouette sits behind it, and Yolk plus any additional On Break instructions form a frameless payload row at the base. Each Yolk value is contained inside its drop. Woodpecker is the first implemented On Break instruction, using a spoon-plus-right-arrow mark beside its Yolk. The implemented placeholder shells are uniformly white, and circuit colour is reserved for genuinely colour-gated marks.

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
