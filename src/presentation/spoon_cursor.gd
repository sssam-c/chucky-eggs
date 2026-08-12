extends TextureRect

const HEAD_OFFSET := Vector2(75.0, 286.0)
const HANDLE_OFFSET := Vector2(333.0, 23.0)
const SHAFT_VECTOR := HEAD_OFFSET - HANDLE_OFFSET
const SHAFT_LENGTH := 368.5
const PARK_ANGLE_TOP := -0.16
const PARK_ANGLE_BOTTOM := -0.38
const HOVER_TOP := 180.0
const HOVER_BOTTOM := 560.0
const POSITION_RESPONSE := 18.0
const ANGLE_RESPONSE := 15.0

var _following := true
var _rest_rotation := 0.0
var _hover_initialized := false
var _hover_pivot_x := 0.0
var _hover_swing := 0.0
var swing_offset := 0.0:
	set(value):
		swing_offset = value
		rotation = _rest_rotation + swing_offset


func _ready() -> void:
	pivot_offset = HANDLE_OFFSET
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	if _following and visible:
		var pointer := get_global_mouse_position()
		var target_swing := _hover_angle(pointer.y)
		if not _hover_initialized:
			_hover_pivot_x = pointer.x
			_hover_swing = target_swing
			_hover_initialized = true
		else:
			var position_weight := 1.0 - exp(-POSITION_RESPONSE * delta)
			var angle_weight := 1.0 - exp(-ANGLE_RESPONSE * delta)
			_hover_pivot_x = lerpf(_hover_pivot_x, pointer.x, position_weight)
			_hover_swing = lerp_angle(_hover_swing, target_swing, angle_weight)
		_apply_hover_pose()


func move_head_to(target_global_position: Vector2) -> void:
	var desired_pivot := target_global_position + Vector2.DOWN * SHAFT_LENGTH
	_place_between(target_global_position, desired_pivot, 1.0)


func move_pointer_to(pointer_global_position: Vector2) -> void:
	_hover_pivot_x = pointer_global_position.x
	_hover_swing = _hover_angle(pointer_global_position.y)
	_hover_initialized = true
	_apply_hover_pose()


func _hover_angle(pointer_y: float) -> float:
	var vertical_progress := clampf(inverse_lerp(HOVER_TOP, HOVER_BOTTOM, pointer_y), 0.0, 1.0)
	return lerpf(PARK_ANGLE_TOP, PARK_ANGLE_BOTTOM, vertical_progress)


func _apply_hover_pose() -> void:
	var viewport_bottom := get_viewport_rect().size.y - 2.0
	var desired_pivot := Vector2(_hover_pivot_x, viewport_bottom)
	var target_head := desired_pivot + Vector2.UP * SHAFT_LENGTH
	_place_between(target_head, desired_pivot, 1.0, _hover_swing)


func prepare_strike(target_global_position: Vector2) -> void:
	var parked_offset := swing_offset
	var desired_pivot := target_global_position + Vector2.DOWN * SHAFT_LENGTH
	_place_between(target_global_position, desired_pivot, 1.0, parked_offset)


func _place_between(
	head_position: Vector2,
	handle_position: Vector2,
	uniform_scale: float,
	initial_swing := 0.0
) -> void:
	scale = Vector2.ONE * uniform_scale
	_rest_rotation = (head_position - handle_position).angle() - SHAFT_VECTOR.angle()
	swing_offset = initial_swing
	var correction := handle_position - pivot_global_position()
	global_position += correction


func head_global_position() -> Vector2:
	return get_global_transform() * HEAD_OFFSET


func pivot_global_position() -> Vector2:
	return get_global_transform() * HANDLE_OFFSET


func set_swing_offset(offset: float) -> void:
	swing_offset = offset


func set_following(enabled: bool) -> void:
	if enabled == _following:
		return
	_following = enabled
	if enabled:
		_hover_pivot_x = pivot_global_position().x
		_hover_swing = swing_offset
		_hover_initialized = true


func reset_pose() -> void:
	swing_offset = 0.0
	scale = Vector2.ONE
	modulate = Color.WHITE
	set_following(true)
