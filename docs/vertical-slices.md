# Vertical slices

This file describes current implementation and learning scope. It does not override current rules.

## Active slice — Bootstrap

### Question

Can the repository open, run, and execute tests before game-specific design work begins?

### Player-visible path

Launch the project and see the starter screen.

### In scope

- Runnable Godot project.
- Headless GUT test path.
- Design records, contracts, agent guidance, and skills.

### Outside this slice

- Any settled game mechanic, content, balance target, or visual identity.

### Exit evidence

- The project imports without errors.
- The starter scene runs.
- `sh scripts/test.sh` passes.
- The first game-specific slice replaces this bootstrap scope.
