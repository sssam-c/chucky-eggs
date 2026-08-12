# Testing contract

## Deterministic behavior

Use red-green-refactor:

1. Express the missing observable rule or regression in a failing GUT spec.
2. Run the narrow spec and confirm it fails for the intended reason.
3. Implement the smallest coherent change at the canonical owner.
4. Run the narrow spec, affected integration specs, and then the full suite.
5. Refactor only while the behavior remains covered.

Inject RNG and time. A test must be able to replay the same inputs and receive the same state and ordered events.

## Presentation behavior

Automate stable observable invariants: command submission count, focus, enabled state, resolved order, barrier completion, and scene structure. Do not lock tests to incidental node internals or animation frame values unless those values are the actual contract.

Define a concrete visual verification path for layout, motion, audio, or composition changes. Inspect at the target viewport and any materially constrained viewport.

## Integration

A passing focused test is not sufficient when a shared owner or boundary changed. Run `sh scripts/test.sh` before handoff unless the environment cannot run Godot; report that limitation explicitly.
