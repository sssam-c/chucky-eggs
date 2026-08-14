class_name DoubleSpoonFrame
extends Resource

@export var near_offset := Vector2.ZERO
@export var far_offset := Vector2.ZERO
@export var near_track_x := 0.0
@export var far_track_x := 0.0
@export var near_radii := Vector2(24.0, 34.0)
@export var far_radii := Vector2(24.0, 34.0)
@export_range(0.0, 1.0) var tipped_amount := 0.0
@export_range(0.0, 1.0) var foreground_handle_visibility := 1.0
@export var near_collar_direction := Vector2.DOWN
@export var far_collar_direction := Vector2.DOWN
