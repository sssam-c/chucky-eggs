class_name EggContainerPopup
extends PopupPanel

const ROW_SCENE = preload("res://src/ui/egg_container_row.tscn")
const EGG_SLOT_SCENE = preload("res://src/ui/egg_slot.tscn")
const BIN_ROW_HEIGHT_WITH_GAP := 89
const HOPPER_TILE_HEIGHT_WITH_GAP := 146
const HOPPER_COLUMNS := 4
const MAX_CONTENT_HEIGHT := 340
const POPUP_CHROME_HEIGHT := 170

@onready var _heading_label: Label = %Heading
@onready var _guidance_label: Label = %Guidance
@onready var _hopper_eggs: HFlowContainer = %HopperEggs
@onready var _rows: VBoxContainer = %Rows
@onready var _scroll: ScrollContainer = %Scroll
@onready var _empty_label: Label = %Empty
@onready var _close_button: Button = %Close

var _container_kind := ""
var _eggs: Array[Dictionary] = []
var _return_focus: Control


func _ready() -> void:
	_close_button.pressed.connect(dismiss)
	close_requested.connect(dismiss)


func show_contents(kind: String, eggs: Array, return_focus: Control = null) -> void:
	assert(kind in ["hopper", "bin"], "Only the hopper and bin can be inspected.")
	_container_kind = kind
	_return_focus = return_focus
	_eggs.clear()
	for egg: Dictionary in eggs:
		_eggs.append(egg.duplicate(true))
	_rebuild_contents()
	var count := _eggs.size()
	_heading_label.text = "%s • %d %s" % [
		kind.to_upper(), count, "EGG" if count == 1 else "EGGS",
	]
	_guidance_label.text = (
		"" if kind == "hopper"
		else "COLLECTED EGGS  •  RETURN ORDER SHUFFLES"
	)
	_guidance_label.visible = not _guidance_label.text.is_empty()
	_empty_label.text = "THE %s IS EMPTY" % kind.to_upper()
	_empty_label.visible = count == 0
	_scroll.visible = count > 0
	var content_height := _content_height(count)
	_scroll.custom_minimum_size.y = content_height
	_empty_label.custom_minimum_size.y = content_height
	popup_centered_clamped(Vector2i(640, content_height + POPUP_CHROME_HEIGHT), 0.92)
	_close_button.grab_focus.call_deferred()


func dismiss() -> void:
	hide()
	if is_instance_valid(_return_focus) and _return_focus.is_visible_in_tree():
		_return_focus.grab_focus.call_deferred()


func container_kind() -> String:
	return _container_kind


func egg_count() -> int:
	return _eggs.size()


func egg_at(index: int) -> Dictionary:
	return _eggs[index].duplicate(true)


func egg_kinds() -> Array[String]:
	var kinds: Array[String] = []
	for egg: Dictionary in _eggs:
		kinds.append(String(egg.get("kind", "")))
	return kinds


func position_labels() -> Array[String]:
	var labels: Array[String] = []
	for row: Control in _rows.get_children():
		labels.append(row.position_text())
	return labels


func hopper_tile_count() -> int:
	return _hopper_eggs.get_child_count()


func heading_text() -> String:
	return _heading_label.text


func guidance_text() -> String:
	return _guidance_label.text


func empty_text() -> String:
	return _empty_label.text


func all_visible_text() -> String:
	var parts: Array[String] = [_heading_label.text, _guidance_label.text]
	if _empty_label.visible:
		parts.append(_empty_label.text)
	for row: Control in _rows.get_children():
		parts.append(row.visible_text())
	return "\n".join(parts)


func _rebuild_contents() -> void:
	for child: Node in _hopper_eggs.get_children():
		child.free()
	for child: Node in _rows.get_children():
		child.free()
	_hopper_eggs.visible = _container_kind == "hopper" and not _eggs.is_empty()
	_rows.visible = _container_kind == "bin" and not _eggs.is_empty()
	for egg_index in range(_eggs.size()):
		if _container_kind == "hopper":
			var tile := EGG_SLOT_SCENE.instantiate()
			tile.custom_minimum_size = Vector2(132.0, 138.0)
			_hopper_eggs.add_child(tile)
			tile.render_egg(_eggs[egg_index], false, true)
		else:
			var row := ROW_SCENE.instantiate()
			_rows.add_child(row)
			row.render_egg(_eggs[egg_index], "STORED %d" % (egg_index + 1))


func _content_height(count: int) -> int:
	if _container_kind == "hopper":
		var tile_rows := maxi(ceili(float(count) / float(HOPPER_COLUMNS)), 1)
		return mini(tile_rows * HOPPER_TILE_HEIGHT_WITH_GAP, MAX_CONTENT_HEIGHT)
	return mini(maxi(count, 1) * BIN_ROW_HEIGHT_WITH_GAP, MAX_CONTENT_HEIGHT)
