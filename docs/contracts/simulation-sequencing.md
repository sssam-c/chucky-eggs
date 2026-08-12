# Simulation Sequencing Contract

This contract applies whenever gameplay unfolds across phases, queued effects, animation barriers, signals, tweens, or deferred callbacks.

## Hard rules

- The domain resolver owns gameplay-event ordering.
- The request processor is the only request-to-resolver pathway.
- Phase boundaries are explicit, observable, and covered by tests.
- Resolver output contains the ordered facts presentation needs; presentation does not infer missing gameplay decisions.
- `AnimationPlayer`, tweens, signals, timers, and UI timing never decide gameplay-event order.
- Presentation may report that the current barrier completed. It never skips, duplicates, substitutes, or reorders resolver entries.
- Input remains unable to submit stale or duplicate commands while a blocking sequence is unresolved.

## Change check

Before implementing a timing- or animation-related change, state whether the proposal complies with this contract and identify:

1. the player request;
2. the canonical resolver entry point;
3. the ordered events or facts it produces;
4. the presentation barrier, if any;
5. cancellation and replacement behavior;
6. the tests that observe order and exactly-once completion.

If the proposal requires UI timing to choose or reorder gameplay, do not implement it as proposed. Offer a resolver-owned design or request an explicit contract change.
