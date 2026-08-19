class_name HopperTapPresenter
extends Node

signal event_presented(event_type: String)
signal playback_finished
signal egg_drop_started(slot_index: int, origin: Vector2, destination: Vector2)
signal streak_announced(streak: int, callout: String, pooled_yolk: int)
signal yolk_delivery_started(total_yolk: int, origin: Vector2, destination: Vector2)
signal hunger_subtraction_presented(hunger_before: int, amount: int, hunger_after: int)

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
var _yolk_streak_display: Control
var _grandma_hunger_panel: Control
var _tap_pips_label: Label
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
	yolk_streak_display: Control,
	grandma_hunger_panel: Control,
	tap_pips_label: Label
) -> void:
	_slots = slots
	_pipe_slots = pipe_slots
	_spoon_buttons = spoon_buttons
	_spoons = spoons
	_hopper_drop_point = hopper_drop_point
	_yolk_streak_display = yolk_streak_display
	_grandma_hunger_panel = grandma_hunger_panel
	_tap_pips_label = tap_pips_label


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
	if _grandma_hunger_panel != null:
		_grandma_hunger_panel.set_reduced_motion(reduced)


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
		"yolk_delivered":
			return await _present_yolk_delivery(event, playback_generation)
		"break_streak_reset":
			return await _present_break_streak_reset(event, playback_generation)
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
	var yolk_origin: Vector2 = slot.hatch_global_position()
	var streak := int(event.break_streak)
	var base_yolk := int(event.base_yolk)
	var awarded_yolk := int(event.yolk)
	var callout_hold := 0.58 if streak > 1 else 0.40
	var result_hold := 0.48 if streak > 1 else 0.34
	_play(_hatch_player)
	if _reduced_motion:
		slot.clear_visual()
		_yolk_streak_display.add_hatch(base_yolk, streak, awarded_yolk)
		streak_announced.emit(
			streak, _yolk_streak_display.callout_text(),
			_yolk_streak_display.pooled_yolk()
		)
		if not await _pause(callout_hold, playback_generation):
			return false
		_yolk_streak_display.resolve_award(awarded_yolk)
		_play(_hunger_player)
		return await _pause(result_hold, playback_generation)
	var content: Control = slot.motion_content()
	content.pivot_offset = content.size * 0.5
	var burst := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	burst.tween_property(content, "scale", Vector2(1.48, 1.24), 0.10)
	burst.parallel().tween_property(content, "rotation", 0.10, 0.10)
	burst.parallel().tween_property(content, "modulate:a", 0.0, 0.10)
	if not await _run_tween(burst, playback_generation):
		return false
	slot.clear_visual()
	var token: Label = _yolk_streak_display.create_yolk_token(yolk_origin, base_yolk)
	var token_size := token.custom_minimum_size
	var target_position: Vector2 = (
		_yolk_streak_display.bowl_global_position() - token_size * 0.5
	)
	token.pivot_offset = token_size * 0.5
	var collect := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	collect.tween_property(token, "global_position", target_position, 0.26)
	collect.parallel().tween_property(token, "scale", Vector2(1.20, 1.20), 0.16)
	collect.parallel().tween_property(token, "rotation", 0.08, 0.26)
	if not await _run_tween(collect, playback_generation):
		return false
	token.queue_free()
	_yolk_streak_display.add_hatch(base_yolk, streak, awarded_yolk)
	streak_announced.emit(
		streak, _yolk_streak_display.callout_text(),
		_yolk_streak_display.pooled_yolk()
	)
	var award_panel: Control = _yolk_streak_display.award_control()
	award_panel.pivot_offset = award_panel.size * 0.5
	award_panel.scale = Vector2(0.82, 0.82)
	var callout := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	callout.tween_property(award_panel, "scale", Vector2(1.08, 1.08), 0.14)
	callout.tween_property(award_panel, "scale", Vector2.ONE, 0.12)
	if not await _run_tween(callout, playback_generation):
		return false
	if not await _pause(callout_hold, playback_generation):
		return false
	_yolk_streak_display.resolve_award(awarded_yolk)
	_play(_hunger_player)
	var calculation: Control = _yolk_streak_display.calculation_control()
	calculation.pivot_offset = calculation.size * 0.5
	calculation.scale = Vector2(0.72, 0.72)
	var resolve := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	resolve.tween_property(calculation, "scale", Vector2(1.24, 1.24), 0.13)
	resolve.tween_property(calculation, "scale", Vector2.ONE, 0.14)
	if not await _run_tween(resolve, playback_generation):
		return false
	return await _pause(result_hold, playback_generation)


func _present_yolk_delivery(event: Dictionary, playback_generation: int) -> bool:
	var total_yolk := int(event.total_yolk)
	var hunger_before := int(event.hunger_before)
	var hunger_after := int(event.hunger)
	var origin: Vector2 = _yolk_streak_display.bowl_global_position()
	var destination: Vector2 = _grandma_hunger_panel.delivery_global_position()
	yolk_delivery_started.emit(total_yolk, origin, destination)
	if _reduced_motion:
		_yolk_streak_display.finish_delivery()
		_grandma_hunger_panel.show_hunger_subtraction(
			hunger_before, total_yolk, hunger_after
		)
		hunger_subtraction_presented.emit(hunger_before, total_yolk, hunger_after)
		if not await _pause(0.48, playback_generation):
			return false
		_commit_hunger(event)
		if not await _pause(0.58, playback_generation):
			return false
		_grandma_hunger_panel.hide_hunger_subtraction()
		return true
	var parcel: Label = _yolk_streak_display.begin_delivery(total_yolk)
	var parcel_size := parcel.custom_minimum_size
	var parcel_destination := destination - parcel_size * 0.5
	var deliver := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	deliver.tween_property(parcel, "global_position", parcel_destination, 0.42)
	deliver.parallel().tween_property(parcel, "scale", Vector2(0.88, 0.88), 0.42)
	if not await _run_tween(deliver, playback_generation):
		return false
	parcel.queue_free()
	_yolk_streak_display.finish_delivery()
	_grandma_hunger_panel.show_hunger_subtraction(hunger_before, total_yolk, hunger_after)
	hunger_subtraction_presented.emit(hunger_before, total_yolk, hunger_after)
	var change_feedback: Control = _grandma_hunger_panel.hunger_change_control()
	change_feedback.pivot_offset = change_feedback.size * 0.5
	change_feedback.scale = Vector2(0.82, 0.82)
	var reveal := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	reveal.tween_property(change_feedback, "scale", Vector2(1.12, 1.12), 0.14)
	reveal.tween_property(change_feedback, "scale", Vector2.ONE, 0.12)
	if not await _run_tween(reveal, playback_generation):
		return false
	if not await _pause(0.32, playback_generation):
		return false
	_commit_hunger(event)
	var hunger_feedback: Control = _grandma_hunger_panel.feedback_control()
	hunger_feedback.pivot_offset = hunger_feedback.size * 0.5
	var hunger_pulse := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	hunger_pulse.tween_property(hunger_feedback, "scale", Vector2(1.16, 1.16), 0.14)
	hunger_pulse.tween_property(hunger_feedback, "scale", Vector2.ONE, 0.16)
	if not await _run_tween(hunger_pulse, playback_generation):
		return false
	if not await _pause(0.42, playback_generation):
		return false
	_grandma_hunger_panel.hide_hunger_subtraction()
	return true


func _present_break_streak_reset(event: Dictionary, playback_generation: int) -> bool:
	if String(event.reason) != "empty_tap":
		_yolk_streak_display.finish_reset()
		return true
	_yolk_streak_display.show_reset(int(event.previous_streak))
	if _reduced_motion:
		if not await _pause(0.72, playback_generation):
			return false
		_yolk_streak_display.finish_reset()
		return true
	var award_panel: Control = _yolk_streak_display.award_control()
	award_panel.pivot_offset = award_panel.size * 0.5
	var break_feedback := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	break_feedback.tween_property(award_panel, "rotation", -0.035, 0.06)
	break_feedback.tween_property(award_panel, "rotation", 0.035, 0.08)
	break_feedback.tween_property(award_panel, "rotation", 0.0, 0.06)
	if not await _run_tween(break_feedback, playback_generation):
		return false
	if not await _pause(0.55, playback_generation):
		return false
	var dismiss := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	dismiss.tween_property(award_panel, "modulate:a", 0.0, 0.20)
	if not await _run_tween(dismiss, playback_generation):
		return false
	_yolk_streak_display.finish_reset()
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
	_grandma_hunger_panel.set_hunger(int(event.hunger))
	_play(_impact_player)


func _present_hunger_phase_start(event: Dictionary, playback_generation: int) -> bool:
	_grandma_hunger_panel.show_phase(int(event.hunger_increase))
	var phase_panel: Control = _grandma_hunger_panel.phase_control()
	phase_panel.modulate.a = 1.0 if _reduced_motion else 0.0
	if _reduced_motion:
		return true
	var reveal := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	reveal.tween_property(phase_panel, "modulate:a", 1.0, 0.12)
	reveal.tween_interval(0.16)
	return await _run_tween(reveal, playback_generation)


func _present_hunger_increase(event: Dictionary, playback_generation: int) -> bool:
	_grandma_hunger_panel.set_hunger(int(event.hunger))
	_grandma_hunger_panel.show_phase(int(event.amount))
	_play(_impact_player)
	if _reduced_motion:
		return true
	var hunger_feedback: Control = _grandma_hunger_panel.feedback_control()
	hunger_feedback.pivot_offset = hunger_feedback.size * 0.5
	var pulse := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pulse.tween_property(hunger_feedback, "scale", Vector2(1.18, 1.18), 0.10)
	pulse.tween_property(hunger_feedback, "scale", Vector2.ONE, 0.14)
	return await _run_tween(pulse, playback_generation)


func _present_tap_phase_start(event: Dictionary, playback_generation: int) -> bool:
	_tap_pips_label.text = _tap_pips(
		int(event.taps_remaining), int(event.taps_per_phase)
	)
	_grandma_hunger_panel.set_next_increase(int(event.next_hunger_increase))
	var phase_panel: Control = _grandma_hunger_panel.phase_control()
	if _reduced_motion:
		_grandma_hunger_panel.hide_phase()
		return true
	var dismiss := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	dismiss.tween_property(phase_panel, "modulate:a", 0.0, 0.12)
	if not await _run_tween(dismiss, playback_generation):
		return false
	_grandma_hunger_panel.hide_phase()
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
	if _grandma_hunger_panel != null:
		_grandma_hunger_panel.reset_feedback()
	if _yolk_streak_display != null:
		_yolk_streak_display.reset_transient()
	for spoon_button: Button in _spoon_buttons:
		spoon_button.reset_pose()
	for spoon: Control in _spoons:
		spoon.reset_pose()
	for slot: Button in _slots:
		slot.reset_motion()


func _play(player: AudioStreamPlayer) -> void:
	if not _muted:
		player.play()


func _pause(duration: float, playback_generation: int) -> bool:
	var pause := create_tween()
	pause.tween_interval(duration)
	return await _run_tween(pause, playback_generation)


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
