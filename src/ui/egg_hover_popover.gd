class_name EggHoverPopover
extends PanelContainer

const EDGE_MARGIN := 8.0
const EGG_GAP := 12.0

@onready var _card: Control = %Card

var _egg: Dictionary = {}
var _target: Control
var _show_request := 0


func configure(egg: Dictionary) -> void:
	_egg = egg.duplicate(true)
	if is_node_ready():
		_card.configure(_egg)


func show_for(target: Control) -> void:
	if _egg.is_empty() or not is_instance_valid(target) or not target.is_visible_in_tree():
		hide()
		return
	_target = target
	_card.configure(_egg)
	_card.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_show_request += 1
	_place_and_show.call_deferred(_show_request)


func cancel() -> void:
	_show_request += 1
	_target = null
	hide()


func popup_rect() -> Rect2:
	return get_global_rect()


func _place_and_show(request: int) -> void:
	if request != _show_request or not is_instance_valid(_target):
		return
	if not _target.is_visible_in_tree() or _egg.is_empty():
		return
	var viewport_rect := _target.get_viewport().get_visible_rect()
	var target_rect := _target.get_global_rect()
	var initial_minimum := _card.get_combined_minimum_size().ceil()
	var initial_size := Vector2i(
		maxi(1, int(initial_minimum.x)), maxi(1, int(initial_minimum.y))
	)
	var initial_bounds := _bounds_for(target_rect, viewport_rect, initial_size)
	size = Vector2(initial_bounds.size)
	global_position = Vector2(initial_bounds.position)
	show()

	# Give the transparent card one visible layout pass, then reveal the fitted result.
	await get_tree().process_frame
	if request != _show_request or not is_instance_valid(_target):
		return
	if not _target.is_visible_in_tree() or _egg.is_empty():
		return
	viewport_rect = _target.get_viewport().get_visible_rect()
	target_rect = _target.get_global_rect()
	var settled_minimum := _card.get_combined_minimum_size().ceil()
	var settled_size := Vector2i(
		maxi(1, int(settled_minimum.x)), maxi(1, int(settled_minimum.y))
	)
	_card.size = settled_minimum
	var settled_bounds := _bounds_for(target_rect, viewport_rect, settled_size)
	size = Vector2(settled_bounds.size)
	global_position = Vector2(settled_bounds.position)
	_card.modulate = Color.WHITE


func _bounds_for(target_rect: Rect2, viewport_rect: Rect2, popup_size: Vector2i) -> Rect2i:
	var right_x := target_rect.end.x + EGG_GAP
	var left_x := target_rect.position.x - float(popup_size.x) - EGG_GAP
	var max_x := viewport_rect.end.x - float(popup_size.x) - EDGE_MARGIN
	var x := right_x if right_x <= max_x else left_x
	x = clampf(x, viewport_rect.position.x + EDGE_MARGIN, max_x)

	var max_y := viewport_rect.end.y - float(popup_size.y) - EDGE_MARGIN
	var y := clampf(
		target_rect.position.y,
		viewport_rect.position.y + EDGE_MARGIN,
		max_y
	)
	return Rect2i(Vector2i(roundi(x), roundi(y)), popup_size)
