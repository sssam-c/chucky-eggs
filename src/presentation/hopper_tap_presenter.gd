class_name HopperTapPresenter
extends Node

signal event_presented(event_type: String)
signal playback_finished
signal egg_drop_started(slot_index: int, origin: Vector2, destination: Vector2)

const CrunchAudio = preload("res://src/presentation/crunch_audio.gd")

@onready var _lever_player: AudioStreamPlayer = $Audio/Lever
@onready var _impact_player: AudioStreamPlayer = $Audio/Impact
@onready var _echo_player: AudioStreamPlayer = $Audio/Echo
@onready var _hatch_player: AudioStreamPlayer = $Audio/Hatch
@onready var _hunger_player: AudioStreamPlayer = $Audio/Score
@onready var _pipe_player: AudioStreamPlayer = $Audio/Pipe

var _slots: Array[Button] = []
var _pipe_slots: Array[Button] = []
var _spoon_buttons: Array[Button] = []
var _spoons: Array[Control] = []
var _hopper_drop_point: Control
var _hunger_label: Label
var _tap_pips_label: Label
var _hunger_intent_label: Label
var _hunger_phase_panel: Control
var _hunger_phase_label: Label
var _generation := 0
var _busy := false
var _muted := false
var _reduced_motion := false
var _active_tween: Tween


func _ready() -> void:
	_lever_player.stream = CrunchAudio.lever()
	_impact_player.stream = CrunchAudio.impact()
	_echo_player.stream = CrunchAudio.echo()
	_hatch_player.stream = CrunchAudio.hatch()
	_hunger_player.stream = CrunchAudio.score()
	_pipe_player.stream = CrunchAudio.pipe()


func configure(
	slots: Array[Button],
	pipe_slots: Array[Button],
	spoon_buttons: Array[Button],
	spoons: Array[Control],
	hopper_drop_point: Control,
	hunger_label: Label,
	tap_pips_label: Label,
	hunger_intent_label: Label,
	hunger_phase_panel: Control,
	hunger_phase_label: Label
) -> void:
	_slots = slots
	_pipe_slots = pipe_slots
	_spoon_buttons = spoon_buttons
	_spoons = spoons
	_hopper_drop_point = hopper_drop_point
	_hunger_label = hunger_label
	_tap_pips_label = tap_pips_label
	_hunger_intent_label = hunger_intent_label
	_hunger_phase_panel = hunger_phase_panel
	_hunger_phase_label = hunger_phase_label


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
		event_presented.emit(String(event.type))
	_busy = false
	_reset_mechanisms()
	playback_finished.emit()
	return true


func cancel_playback() -> void:
	_generation += 1
	_busy = false
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
	for player: AudioStreamPlayer in [
		_lever_player, _impact_player, _echo_player,
		_hatch_player, _hunger_player, _pipe_player,
	]:
		player.stop()
	_reset_mechanisms()


func set_reduced_motion(reduced: bool) -> void:
	_reduced_motion = reduced


func set_muted(muted: bool) -> void:
	_muted = muted
	if muted:
		for player: AudioStreamPlayer in [
			_lever_player, _impact_player, _echo_player,
			_hatch_player, _hunger_player, _pipe_player,
		]:
			player.stop()


func is_busy() -> bool:
	return _busy


func _present_event(event: Dictionary, playback_generation: int) -> bool:
	match String(event.type):
		"spoon_fired":
			return await _present_spoon(int(event.slot_index), playback_generation)
		"egg_damaged":
			return await _present_damage(event, playback_generation)
		"egg_hatched":
			return await _present_hatch(event, playback_generation)
		"eggs_swapped":
			return await _present_swap(event, playback_generation)
		"egg_entered":
			return await _present_entry(event, playback_generation)
		"tap_spent":
			_tap_pips_label.text = _tap_pips(
				int(event.taps_remaining), int(event.taps_per_phase)
			)
		"tap_phase_ended":
			return await _present_hunger_phase_start(event, playback_generation)
		"hunger_increased":
			return await _present_hunger_increase(event, playback_generation)
		"tap_phase_started":
			return await _present_tap_phase_start(event, playback_generation)
	return true


func _present_spoon(slot_index: int, playback_generation: int) -> bool:
	_play(_lever_player)
	var spoon_button: Button = _spoon_buttons[slot_index]
	var spoon: Control = _spoons[slot_index]
	if _reduced_motion:
		spoon_button.set_press_amount(1.0)
		spoon.set_strike_amount(1.0)
		spoon_button.reset_pose()
		spoon.reset_pose()
		return true
	var anticipation := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	anticipation.tween_property(spoon_button, "press_amount", 0.35, 0.045)
	anticipation.parallel().tween_property(spoon, "strike_amount", -0.10, 0.045)
	if not await _run_tween(anticipation, playback_generation):
		return false
	var strike := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	strike.tween_property(spoon_button, "press_amount", 1.0, 0.105)
	strike.parallel().tween_property(spoon, "strike_amount", 1.0, 0.105)
	if not await _run_tween(strike, playback_generation):
		return false
	var recovery := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	recovery.tween_property(spoon_button, "press_amount", 0.0, 0.09)
	recovery.parallel().tween_property(spoon, "strike_amount", 0.0, 0.09)
	return await _run_tween(recovery, playback_generation)


func _present_damage(event: Dictionary, playback_generation: int) -> bool:
	var slot: Button = _slots[int(event.slot_index)]
	slot.apply_damage(int(event.remaining_toughness))
	_play(_echo_player if String(event.cause) == "cuckoo_echo" else _impact_player)
	if _reduced_motion:
		return true
	var content: Control = slot.motion_content()
	content.pivot_offset = content.size * 0.5
	var bounce := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	bounce.tween_property(content, "scale", Vector2(1.15, 0.76), 0.045)
	bounce.parallel().tween_property(content, "rotation", -0.045, 0.045)
	bounce.tween_property(content, "scale", Vector2.ONE, 0.075)
	bounce.parallel().tween_property(content, "rotation", 0.0, 0.075)
	return await _run_tween(bounce, playback_generation)


func _present_hatch(event: Dictionary, playback_generation: int) -> bool:
	var slot: Button = _slots[int(event.slot_index)]
	_play(_hatch_player)
	if _reduced_motion:
		slot.clear_visual()
		_commit_hunger(event)
		return true
	var content: Control = slot.motion_content()
	content.pivot_offset = content.size * 0.5
	var burst := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	burst.tween_property(content, "scale", Vector2(1.48, 1.24), 0.10)
	burst.parallel().tween_property(content, "rotation", 0.10, 0.10)
	burst.parallel().tween_property(content, "modulate:a", 0.0, 0.10)
	if not await _run_tween(burst, playback_generation):
		return false
	slot.clear_visual()
	_commit_hunger(event)
	return true


func _present_swap(event: Dictionary, _playback_generation: int) -> bool:
	var resolved_slots: Array = event.slots
	for slot_index in range(mini(_slots.size(), resolved_slots.size())):
		_slots[slot_index].render_egg(resolved_slots[slot_index], false)
	return true


func _present_entry(event: Dictionary, playback_generation: int) -> bool:
	var slot: Button = _slots[int(event.slot_index)]
	slot.render_egg(event.egg, false)
	_render_pipe(event.pipe)
	_play(_pipe_player)
	var content: Control = slot.motion_content()
	var origin: Vector2 = _hopper_drop_point.get_global_rect().get_center()
	var destination: Vector2 = slot.hatch_global_position()
	egg_drop_started.emit(int(event.slot_index), origin, destination)
	if _reduced_motion:
		return true
	var destination_position := content.position
	var destination_scale := content.scale
	var parent_inverse: Transform2D = content.get_parent().get_global_transform().affine_inverse()
	var origin_local: Vector2 = parent_inverse * origin
	content.position = origin_local - content.size * 0.5
	content.pivot_offset = content.size * 0.5
	content.scale = destination_scale * 0.68
	content.modulate.a = 0.72
	content.z_index = 12
	var hover_position := destination_position - Vector2(0.0, 92.0)
	var route := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	route.tween_property(content, "position", hover_position, 0.20)
	route.parallel().tween_property(content, "scale", destination_scale * 0.90, 0.20)
	route.parallel().tween_property(content, "modulate:a", 1.0, 0.12)
	if not await _run_tween(route, playback_generation):
		return false
	var drop := create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	drop.tween_property(content, "position", destination_position, 0.18)
	drop.parallel().tween_property(content, "scale", destination_scale, 0.15)
	if not await _run_tween(drop, playback_generation):
		return false
	content.z_index = 0
	return true


func _commit_hunger(event: Dictionary) -> void:
	_hunger_label.text = "HUNGER  %d" % int(event.hunger)
	_play(_hunger_player)


func _present_hunger_phase_start(event: Dictionary, playback_generation: int) -> bool:
	_hunger_phase_label.text = "GRANDMA'S HUNGER  +%d" % int(event.hunger_increase)
	_hunger_phase_panel.modulate.a = 1.0 if _reduced_motion else 0.0
	_hunger_phase_panel.visible = true
	if _reduced_motion:
		return true
	var reveal := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	reveal.tween_property(_hunger_phase_panel, "modulate:a", 1.0, 0.12)
	reveal.tween_interval(0.16)
	return await _run_tween(reveal, playback_generation)


func _present_hunger_increase(event: Dictionary, playback_generation: int) -> bool:
	_hunger_label.text = "HUNGER  %d" % int(event.hunger)
	_hunger_phase_label.text = "GRANDMA'S HUNGER  +%d" % int(event.amount)
	_play(_impact_player)
	if _reduced_motion:
		return true
	_hunger_label.pivot_offset = _hunger_label.size * 0.5
	var pulse := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pulse.tween_property(_hunger_label, "scale", Vector2(1.18, 1.18), 0.10)
	pulse.tween_property(_hunger_label, "scale", Vector2.ONE, 0.14)
	return await _run_tween(pulse, playback_generation)


func _present_tap_phase_start(event: Dictionary, playback_generation: int) -> bool:
	_tap_pips_label.text = _tap_pips(
		int(event.taps_remaining), int(event.taps_per_phase)
	)
	_hunger_intent_label.text = (
		"GRANDMA NEXT  +%d HUNGER" % int(event.next_hunger_increase)
	)
	if _reduced_motion:
		_hunger_phase_panel.visible = false
		_hunger_phase_panel.modulate.a = 1.0
		return true
	var dismiss := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	dismiss.tween_property(_hunger_phase_panel, "modulate:a", 0.0, 0.12)
	if not await _run_tween(dismiss, playback_generation):
		return false
	_hunger_phase_panel.visible = false
	_hunger_phase_panel.modulate.a = 1.0
	return true


func _tap_pips(remaining: int, total: int) -> String:
	var pips: Array[String] = []
	for tap_index in range(total):
		pips.append("●" if tap_index < remaining else "○")
	return "TAPS  %s" % " ".join(pips)


func _render_pipe(eggs: Array) -> void:
	for preview_index in range(_pipe_slots.size()):
		var egg: Dictionary = eggs[preview_index] if preview_index < eggs.size() else {}
		_pipe_slots[preview_index].render_egg(egg, false, true)


func _reset_mechanisms() -> void:
	if _hunger_phase_panel != null:
		_hunger_phase_panel.visible = false
		_hunger_phase_panel.modulate.a = 1.0
	if _hunger_label != null:
		_hunger_label.scale = Vector2.ONE
	for spoon_button: Button in _spoon_buttons:
		spoon_button.reset_pose()
	for spoon: Control in _spoons:
		spoon.reset_pose()
	for slot: Button in _slots:
		slot.reset_motion()


func _play(player: AudioStreamPlayer) -> void:
	if not _muted:
		player.play()


func _run_tween(tween: Tween, playback_generation: int) -> bool:
	_active_tween = tween
	while tween.is_valid() and tween.is_running():
		await get_tree().process_frame
		if playback_generation != _generation:
			if tween.is_valid():
				tween.kill()
			return false
	_active_tween = null
	return playback_generation == _generation
