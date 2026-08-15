class_name MotionTokens
extends RefCounted

# UI motion follows three cadences: immediate mechanical response, a short
# recovery, and a deliberate panel/content reveal. Gameplay animation keeps
# its resolver-authored sequencing and may use longer physical timings.
const SNAP := 0.07
const SETTLE := 0.16
const REVEAL := 0.24
const STAGGER := 0.035

const PRESS_SCALE := Vector2(0.975, 0.975)
const FOCUS_SCALE := Vector2(1.018, 1.018)
const VALUE_SCALE := Vector2(1.10, 1.10)
