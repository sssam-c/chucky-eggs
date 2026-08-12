# Documentation contract

The repository keeps five kinds of design knowledge separate.

## Authority

1. `game-rules.md` is the current player-facing rule truth.
2. `decision-log.md` records why deliberate decisions were made and which earlier decisions they supersede.
3. `design-principles.md` interprets the current rules but cannot override them.
4. `vertical-slices.md` describes current implementation and learning scope; it cannot establish permanent rules.
5. `playtest-log.md` records evidence. Observations do not become rules without a deliberate decision.

When sources conflict, stop and surface the conflict. Do not resolve it by choosing whichever text is most convenient for implementation.

## Change protocol

- Proposed idea: capture it in the active slice or discussion, clearly labeled as a hypothesis.
- Accepted rule: update `game-rules.md` and append the decision and rationale.
- Changed interpretation: update `design-principles.md`; append a decision if player behavior changes.
- Changed prototype scope: update `vertical-slices.md` only.
- Playtest result: append the observation, context, and limitations to `playtest-log.md`.

Never delete or rewrite an accepted decision to make history look cleaner. Append a new entry that names what it supersedes.
