# Decision log

This log is append-only. Later decisions may supersede earlier entries but never erase them.

## D000 — Separate rule truth, rationale, scope, and evidence

**Status:** accepted

**Decision:** Maintain distinct documents for current rules, design principles, decision history, vertical-slice scope, and playtest evidence. Follow the precedence in `contracts/documentation.md`.

**Reason:** Prototypes change quickly. Separating these knowledge types prevents a temporary implementation choice or one playtest observation from silently becoming permanent game truth.

## D001 — Make every thwack consume conveyor time

**Status:** accepted

**Decision:** The conveyor has five slots. The player may thwack any egg on it, reducing that egg's toughness by 1, and every thwack then advances all surviving eggs one slot. An egg that passes the end is discarded. A day lasts 20 thwacks, and all eggs remaining after the final thwack are discarded.

**Reason:** Free targeting gives the player agency, while shared conveyor movement makes damage a scarce resource. Every thwack helps one egg and endangers the rest, forcing deliberate sacrifice instead of allowing the player to clear everything.

## D002 — Teach sacrifice with one chicken egg type

**Status:** accepted

**Decision:** The first playable slice supplies one chicken egg per turn. Each chicken has 4 toughness, awards 1 point, and the day target is 3 points. The day begins with one chicken in slot 1, while a pipe previews the next three eggs and the remaining-thwack countdown stays visible.

**Reason:** A chicken needs four of its five available conveyor steps to hatch, so committing to one necessarily allows others to pass. Requiring 3 points uses 12 of 20 thwacks, leaving enough recovery room for an early player to make mistakes while still learning that not every egg can be saved. Using one egg type isolates that lesson from value comparisons and hatch-effect combinations.

## D003 — Give every conveyor slot a piano-key spoon hammer

**Status:** accepted

**Decision:** Present the five conveyor choices as five large foreground keys. Each key is mechanically linked to one fixed spoon hammer behind the belt; pressing it fires that spoon onto the top of the upright egg in the corresponding slot. Idle spoons show their convex backs and remain spatially paired with their keys and cups.

**Reason:** A one-to-one bank of physical controls makes targeting immediate while preserving the pleasure of a large mechanical spoon. The piano-hammer motion gives anticipation, impact, and reset a clear causal chain without obscuring egg faces or requiring a cursor-sized tool.

<!--
Copy for the next entry:

## D004 — Short decision title

**Status:** proposed | accepted | superseded

**Decision:** State the rule or constraint precisely.

**Reason:** Record the trade-off and evidence.

**Supersedes:** Name earlier entries when applicable.
-->
