class_name ThwackPresenter
extends Node

signal event_presented(event_type: String)
signal playback_finished
signal _animation_step_released

@onready var _impact_player: AudioStreamPlayer = $Audio/Impact
@onready var _echo_player: AudioStreamPlayer = $Audio/Echo
@onready var _hatch_player: AudioStreamPlayer = $Audio/Hatch
@onready var _belt_player: AudioStreamPlayer = $Audio/Belt
@onready var _loss_player: AudioStreamPlayer = $Audio/Loss
@onready var _pipe_player: AudioStreamPlayer = $Audio/Pipe

var _belt_slots: Array[Button] = []
var _pipe_slots: Array[Button] = []
var _keys: Array[Button] = []
var _hammers: Array[Control] = []
var _echo_trace: Control
var _score_label: Label
var _thwacks_label: Label
var _drop_label: Label
var _generation := 0
var _busy := false
var _muted := false
var _reduced_motion := false
var _active_tween: Tween
var _active_step_id := 0
var _waiting_for_step := false


func _ready() -> void:
	_impact_player.stream = CrunchAudio.impact()
	_echo_player.stream = CrunchAudio.echo()
	_hatch_player.stream = CrunchAudio.hatch()
	_belt_player.stream = CrunchAudio.belt()
	_loss_player.stream = CrunchAudio.loss()
	_pipe_player.stream = CrunchAudio.pipe()


func configure(
	belt_slots: Array[Button],
	pipe_slots: Array[Button],
	keys: Array[Button],
	hammers: Array[Control],
	echo_trace: Control,
	score_label: Label,
	thwacks_label: Label,
	drop_label: Label
) -> void:
	_belt_slots = belt_slots
	_pipe_slots = pipe_slots
	_keys = keys
	_hammers = hammers
	_echo_trace = echo_trace
	_score_label = score_label
	_thwacks_label = thwacks_label
	_drop_label = drop_label


func play_events(events: Array[Dictionary]) -> bool:
	_generation += 1
	var playback_generation := _generation
	_busy = true
	await get_tree().process_frame

	for event: Dictionary in events:
		if playback_generation != _generation:
			return false
		var completed := await _present_event(event, playback_generation)
		if not completed or playback_generation != _generation:
			return false
		event_presented.emit(event.type)

	_busy = false
	_reset_mechanisms()
	if is_instance_valid(_echo_trace):
		_echo_trace.clear_connection()
	playback_finished.emit()
	return true


func cancel_playback() -> void:
	_generation += 1
	_busy = false
	for player: AudioStreamPlayer in [_impact_player, _echo_player, _hatch_player, _belt_player, _loss_player, _pipe_player]:
		player.stop()
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
	_release_animation_step(_active_step_id)
	_reset_mechanisms()


func set_muted(muted: bool) -> void:
	_muted = muted
	if muted:
		for player: AudioStreamPlayer in [_impact_player, _echo_player, _hatch_player, _belt_player, _loss_player, _pipe_player]:
			player.stop()


func is_muted() -> bool:
	return _muted


func set_reduced_motion(reduced: bool) -> void:
	_reduced_motion = reduced


func is_reduced_motion() -> bool:
	return _reduced_motion


func is_busy() -> bool:
	return _busy


func _present_event(event: Dictionary, playback_generation: int) -> bool:
	match event.type:
		"egg_damaged":
			return await _present_damage(event, playback_generation)
		"egg_hatched":
			return await _present_hatch(event, playback_generation)
		"conveyor_advanced":
			return await _present_conveyor(event, playback_generation)
		"egg_discarded":
			return await _present_loss(playback_generation)
		"thwack_spent":
			_thwacks_label.text = "THWACKS %d" % event.remaining_thwacks
		"egg_entered":
			return await _present_pipe_entry(event, playback_generation)
		"day_remainder_discarded":
			return await _present_day_discard(playback_generation)
		"day_ended":
			pass
	return true


func _present_damage(event: Dictionary, playback_generation: int) -> bool:
	var slot: Button = _belt_slots[event.slot_index]
	if event.get("cause", "spoon") == "cuckoo_echo":
		return await _present_echo_damage(slot, event, playback_generation)
	var key: Button = _keys[event.slot_index]
	var hammer: Control = _hammers[event.slot_index]
	if _reduced_motion:
		key.set_press_amount(1.0)
		hammer.set_strike_amount(1.0)
		_play(_impact_player)
		slot.apply_damage(event.remaining_toughness)
		key.reset_pose()
		hammer.reset_pose()
		return true

	var anticipation := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	anticipation.tween_property(key, "press_amount", 0.38, 0.055)
	anticipation.parallel().tween_property(hammer, "strike_amount", -0.10, 0.055)
	if not await _run_tween(anticipation, playback_generation):
		return false

	var strike := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	strike.tween_property(key, "press_amount", 1.0, 0.075)
	strike.parallel().tween_property(hammer, "strike_amount", 1.0, 0.075)
	if not await _run_tween(strike, playback_generation):
		return false

	_play(_impact_player)
	slot.apply_damage(event.remaining_toughness)
	var content: Control = slot.motion_content()
	content.pivot_offset = content.size * 0.5
	var recovery := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	recovery.tween_property(hammer, "strike_amount", 0.86, 0.045)
	recovery.parallel().tween_property(content, "scale", Vector2(1.12, 0.82), 0.045)
	recovery.parallel().tween_property(content, "rotation", -0.035, 0.045)
	recovery.tween_property(hammer, "strike_amount", 0.0, 0.135)
	recovery.parallel().tween_property(key, "press_amount", 0.0, 0.135)
	recovery.parallel().tween_property(content, "scale", Vector2.ONE, 0.105)
	recovery.parallel().tween_property(content, "rotation", 0.0, 0.105)
	return await _run_tween(recovery, playback_generation)


func _present_echo_damage(slot: Button, event: Dictionary, playback_generation: int) -> bool:
	_play(_echo_player)
	slot.apply_damage(event.remaining_toughness)
	if _reduced_motion:
		return true
	var source_slot: Button = _belt_slots[event.source_slot_index]
	_echo_trace.show_connection(source_slot.impact_global_position(), slot.impact_global_position())
	var content: Control = slot.motion_content()
	content.pivot_offset = content.size * 0.5
	var pulse := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pulse.tween_property(_echo_trace, "intensity", 1.0, 0.055)
	pulse.parallel().tween_property(content, "modulate", Color(0.48, 1.0, 0.96, 1.0), 0.055)
	pulse.parallel().tween_property(content, "scale", Vector2(1.09, 0.90), 0.055)
	pulse.tween_property(_echo_trace, "intensity", 0.0, 0.12)
	pulse.parallel().tween_property(content, "modulate", Color.WHITE, 0.12)
	pulse.parallel().tween_property(content, "scale", Vector2.ONE, 0.12)
	var completed := await _run_tween(pulse, playback_generation)
	_echo_trace.clear_connection()
	return completed


func _present_hatch(event: Dictionary, playback_generation: int) -> bool:
	var slot: Button = _belt_slots[event.slot_index]
	_score_label.text = "SCORE %d / %d" % [event.score, event.get("target_score", 10)]
	_play(_hatch_player)
	if _reduced_motion:
		slot.clear_visual()
		return true

	var content: Control = slot.motion_content()
	content.pivot_offset = content.size * 0.5
	var burst := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	burst.tween_property(content, "scale", Vector2(1.42, 1.24), 0.12)
	burst.parallel().tween_property(content, "rotation", 0.10, 0.12)
	burst.tween_property(content, "scale", Vector2(0.2, 0.2), 0.10)
	burst.parallel().tween_property(content, "modulate:a", 0.0, 0.10)
	if not await _run_tween(burst, playback_generation):
		return false
	slot.clear_visual()
	return true


func _present_conveyor(event: Dictionary, playback_generation: int) -> bool:
	_play(_belt_player)
	if _reduced_motion:
		_render_belt(event.slots)
		return true

	var stride := _belt_slots[1].global_position.x - _belt_slots[0].global_position.x
	var move := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	var has_motion := false
	for slot_index in range(_belt_slots.size()):
		var slot: Button = _belt_slots[slot_index]
		if slot.current_egg().is_empty():
			continue
		has_motion = true
		var content: Control = slot.motion_content()
		var target := content.position + Vector2(stride, 52.0 if slot_index == _belt_slots.size() - 1 else 0.0)
		move.parallel().tween_property(content, "position", target, 0.17)
		if slot_index == _belt_slots.size() - 1:
			move.parallel().tween_property(content, "rotation", 0.14, 0.17)
			move.parallel().tween_property(content, "modulate:a", 0.35, 0.17)
	if has_motion and not await _run_tween(move, playback_generation):
		return false
	_render_belt(event.slots)
	return true


func _present_loss(playback_generation: int) -> bool:
	_play(_loss_player)
	if _reduced_motion:
		return true
	_drop_label.pivot_offset = _drop_label.size * 0.5
	var pulse := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pulse.tween_property(_drop_label, "scale", Vector2(1.24, 1.24), 0.08)
	pulse.parallel().tween_property(_drop_label, "modulate", Color(1.0, 0.27, 0.12, 1.0), 0.08)
	pulse.tween_property(_drop_label, "scale", Vector2.ONE, 0.13)
	pulse.parallel().tween_property(_drop_label, "modulate", Color.WHITE, 0.13)
	return await _run_tween(pulse, playback_generation)


func _present_pipe_entry(event: Dictionary, playback_generation: int) -> bool:
	_play(_pipe_player)
	_belt_slots[0].render_egg(event.egg, false, false)
	for preview_index in range(_pipe_slots.size()):
		var egg: Dictionary = event.pipe[preview_index] if preview_index < event.pipe.size() else {}
		_pipe_slots[preview_index].render_egg(egg, false, true)
	if _reduced_motion:
		return true

	var drop := create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	var entry_content: Control = _belt_slots[0].motion_content()
	entry_content.position.y -= 34.0
	drop.parallel().tween_property(entry_content, "position:y", 0.0, 0.16)
	for preview: Button in _pipe_slots:
		var content: Control = preview.motion_content()
		content.position.y -= 12.0
		drop.parallel().tween_property(content, "position:y", 0.0, 0.16)
	return await _run_tween(drop, playback_generation)


func _present_day_discard(playback_generation: int) -> bool:
	_play(_loss_player)
	if _reduced_motion:
		_clear_all_eggs()
		return true

	var fade := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	var any_visible := false
	for slot: Button in _belt_slots + _pipe_slots:
		if slot.current_egg().is_empty():
			continue
		any_visible = true
		var content: Control = slot.motion_content()
		fade.parallel().tween_property(content, "position:y", content.position.y + 34.0, 0.16)
		fade.parallel().tween_property(content, "modulate:a", 0.0, 0.16)
	if any_visible and not await _run_tween(fade, playback_generation):
		return false
	_clear_all_eggs()
	return true


func _render_belt(slots: Array) -> void:
	for slot_index in range(_belt_slots.size()):
		_belt_slots[slot_index].render_egg(slots[slot_index], false, false)
		_keys[slot_index].set_available(not slots[slot_index].is_empty())


func _clear_all_eggs() -> void:
	for slot: Button in _belt_slots + _pipe_slots:
		slot.clear_visual()
	for key: Button in _keys:
		key.set_available(false)


func _reset_mechanisms() -> void:
	if is_instance_valid(_echo_trace):
		_echo_trace.clear_connection()
	for key: Button in _keys:
		if is_instance_valid(key):
			key.reset_pose()
	for hammer: Control in _hammers:
		if is_instance_valid(hammer):
			hammer.reset_pose()


func _play(player: AudioStreamPlayer) -> void:
	if not _muted:
		player.stop()
		player.play()


func _run_tween(tween: Tween, playback_generation: int) -> bool:
	_active_tween = tween
	_active_step_id += 1
	var step_id := _active_step_id
	_waiting_for_step = true
	tween.finished.connect(func() -> void: _release_animation_step(step_id), CONNECT_ONE_SHOT)
	await _animation_step_released
	return playback_generation == _generation


func _release_animation_step(step_id: int) -> void:
	if not _waiting_for_step or step_id != _active_step_id:
		return
	_waiting_for_step = false
	_active_tween = null
	_animation_step_released.emit()
