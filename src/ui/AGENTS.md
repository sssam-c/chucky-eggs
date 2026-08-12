# UI guidance

`src/ui/` owns `Control` scenes and view adapters.

- Render state and submit commands; never mutate domain state directly.
- Prefer saved `.tscn` scenes for durable hierarchy and reusable components.
- Use signals or explicit interfaces at scene composition boundaries.
- Define player input in the Input Map and reference named actions.
- Verify keyboard focus, dismissal behavior, readable states, and non-color-only meaning.
- Do not let scene-tree order or UI timing decide gameplay order.
