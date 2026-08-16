class_name ThwackPresenter
extends Node

signal event_presented(event_type: String)
signal playback_finished
signal hammer_fired(slot_index: int)
signal hatch_payoff_started(slot_index: int, points_awarded: int)
signal score_committed(points_awarded: int, score: int)
signal _animation_step_released

@onready var _lever_player: AudioStreamPlayer = $Audio/Lever
@onready var _impact_player: AudioStreamPlayer = $Audio/Impact
@onready var _echo_player: AudioStreamPlayer = $Audio/Echo
@onready var _shuffle_player: AudioStreamPlayer = $Audio/Shuffle
@onready var _hatch_player: AudioStreamPlayer = $Audio/Hatch
@onready var _score_player: AudioStreamPlayer = $Audio/Score
@onready var _belt_player: AudioStreamPlayer = $Audio/Belt
@onready var _loss_player: AudioStreamPlayer = $Audio/Loss
@onready var _pipe_player: AudioStreamPlayer = $Audio/Pipe

var _belt_slots: Array[Button] = []
var _pipe_slots: Array[Button] = []
var _circuit_buttons: Array[Button] = []
var _hammers: Array[Control] = []
var _slot_hammer_indices: Array[int] = []
var _echo_trace: Control
var _hatch_payoff: Control
var _appetite_display: Control
var _thwacks_label: Label
var _bin_label: Label
var _generation := 0
var _busy := false
var _muted := false
var _reduced_motion := false
var _active_tween: Tween
var _active_step_id := 0
var _waiting_for_step := false


func _ready() -> void:
	_lever_player.stream = CrunchAudio.lever()
	_impact_player.stream = CrunchAudio.impact()
	_echo_player.stream = CrunchAudio.echo()
	_shuffle_player.stream = CrunchAudio.shuffle()
	_hatch_player.stream = CrunchAudio.hatch()
	_score_player.stream = CrunchAudio.score()
	_belt_player.stream = CrunchAudio.belt()
	_loss_player.stream = CrunchAudio.loss()
	_pipe_player.stream = CrunchAudio.pipe()


func configure(
	belt_slots: Array[Button],
	pipe_slots: Array[Button],
	circuit_buttons: Array[Button],
	hammers: Array[Control],
	echo_trace: Control,
	hatch_payoff: Control,
	appetite_display: Control,
	thwacks_label: Label,
	bin_label: Label
) -> void:
	_belt_slots = belt_slots
	_pipe_slots = pipe_slots
	_circuit_buttons = circuit_buttons
	_hammers = hammers
	_echo_trace = echo_trace
	_hatch_payoff = hatch_payoff
	_appetite_display = appetite_display
	_thwacks_label = thwacks_label
	_bin_label = bin_label


func set_slot_hammer_indices(indices: Array) -> void:
	_slot_hammer_indices.assign(indices)


func play_events(events: Array[Dictionary]) -> bool:
	_generation += 1
	var playback_generation := _generation
	_busy = true
	await get_tree().process_frame

	for event_index in range(events.size()):
		var event: Dictionary = events[event_index]
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
	for player: AudioStreamPlayer in [_lever_player, _impact_player, _echo_player, _shuffle_player, _hatch_player, _score_player, _belt_player, _loss_player, _pipe_player]:
		player.stop()
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
	_release_animation_step(_active_step_id)
	_reset_mechanisms()


func set_muted(muted: bool) -> void:
	_muted = muted
	if muted:
		for player: AudioStreamPlayer in [_lever_player, _impact_player, _echo_player, _shuffle_player, _hatch_player, _score_player, _belt_player, _loss_player, _pipe_player]:
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
		"circuit_fired":
			return await _present_circuit(event, playback_generation)
		"egg_damaged":
			return await _present_damage(event, playback_generation)
		"egg_hatched":
			return await _present_hatch(event, playback_generation)
		"eggs_swapped":
			return await _present_swap(event, playback_generation)
		"conveyor_advanced":
			return await _present_conveyor(event, playback_generation)
		"egg_binned":
			return await _present_bin(event, playback_generation)
		"thwack_spent":
			_thwacks_label.text = "THWACKS %d" % event.remaining_thwacks
		"egg_entered":
			return await _present_pipe_entry(event, playback_generation)
		"bin_reshuffled":
			return await _present_bin_reshuffle(event, playback_generation)
		"day_remainder_discarded":
			return await _present_day_discard(playback_generation)
		"day_ended":
			pass
	return true


func _present_damage(event: Dictionary, playback_generation: int) -> bool:
	var slot: Button = _belt_slots[event.slot_index]
	if event.get("cause", "spoon") == "cuckoo_echo":
		return await _present_echo_damage(slot, event, playback_generation)
	_play(_impact_player)
	slot.apply_damage(event.remaining_toughness)
	if _reduced_motion:
		return true
	var damage_amount: int = event.get("damage_amount", 1)
	var content: Control = slot.motion_content()
	content.pivot_offset = content.size * 0.5
	var impact := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	impact.tween_property(content, "scale", Vector2(1.20, 0.72) if damage_amount > 1 else Vector2(1.10, 0.84), 0.055 if damage_amount > 1 else 0.045)
	impact.parallel().tween_property(content, "rotation", -0.06 if damage_amount > 1 else -0.03, 0.055 if damage_amount > 1 else 0.045)
	if damage_amount > 1:
		impact.parallel().tween_property(content, "modulate", Color(1.0, 0.54, 0.88, 1.0), 0.055)
	impact.tween_property(content, "scale", Vector2.ONE, 0.09)
	impact.parallel().tween_property(content, "rotation", 0.0, 0.09)
	impact.parallel().tween_property(content, "modulate", Color.WHITE, 0.09)
	return await _run_tween(impact, playback_generation)


func _present_circuit(event: Dictionary, playback_generation: int) -> bool:
	var circuit_button := _circuit_button(String(event.circuit_id))
	if circuit_button == null:
		return false
	_play(_lever_player)
	var fired_hammers: Array[Control] = []
	var fired_hammer_indices: Array[int] = []
	for slot_index: int in event.slot_indices:
		var hammer_index := _slot_hammer_indices[slot_index]
		if hammer_index in fired_hammer_indices:
			continue
		fired_hammer_indices.append(hammer_index)
		fired_hammers.append(_hammers[hammer_index])
		hammer_fired.emit(hammer_index)

	if _reduced_motion:
		circuit_button.set_press_amount(1.0)
		for hammer: Control in fired_hammers:
			hammer.set_strike_amount(1.0)
		circuit_button.reset_pose()
		for hammer: Control in fired_hammers:
			hammer.reset_pose()
		return true

	var anticipation := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	anticipation.tween_property(circuit_button, "press_amount", 0.38, 0.055)
	for hammer: Control in fired_hammers:
		anticipation.parallel().tween_property(hammer, "strike_amount", -0.10, 0.055)
	if not await _run_tween(anticipation, playback_generation):
		return false
	# Every spoon now shares the authored landing strip. Its poses already contain
	# the acceleration, so give all line layouts the same linear 140 ms cadence.
	var strike_duration := 0.14
	var strike := create_tween()
	strike.tween_property(circuit_button, "press_amount", 1.0, strike_duration).set_trans(
		Tween.TRANS_QUAD
	).set_ease(Tween.EASE_IN)
	for hammer: Control in fired_hammers:
		var hammer_strike := strike.parallel().tween_property(
			hammer,
			"strike_amount",
			1.0,
			strike_duration
		)
		hammer_strike.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
	if not await _run_tween(strike, playback_generation):
		return false
	var recovery := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	recovery.tween_property(circuit_button, "press_amount", 0.0, 0.14)
	for hammer: Control in fired_hammers:
		recovery.parallel().tween_property(hammer, "strike_amount", 0.0, 0.14)
	return await _run_tween(recovery, playback_generation)


func _circuit_button(circuit_id: String) -> Button:
	for circuit_button: Button in _circuit_buttons:
		if circuit_button.circuit_id == circuit_id:
			return circuit_button
	return null


func _present_echo_damage(slot: Button, event: Dictionary, playback_generation: int) -> bool:
	_play(_echo_player)
	slot.apply_damage(event.remaining_toughness)
	if _reduced_motion:
		return true
	var source_slot: Button = _belt_slots[event.source_slot_index]
	_echo_trace.show_connection(source_slot.impact_global_position(), slot.impact_global_position())
	var content: Control = slot.motion_content()
	var damage_amount: int = event.get("damage_amount", 1)
	content.pivot_offset = content.size * 0.5
	var pulse := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pulse.tween_property(_echo_trace, "intensity", 1.0, 0.055)
	pulse.parallel().tween_property(content, "modulate", Color(0.48, 1.0, 0.96, 1.0), 0.055)
	pulse.parallel().tween_property(content, "scale", Vector2(1.17, 0.82) if damage_amount > 1 else Vector2(1.09, 0.90), 0.055)
	pulse.tween_property(_echo_trace, "intensity", 0.0, 0.12)
	pulse.parallel().tween_property(content, "modulate", Color.WHITE, 0.12)
	pulse.parallel().tween_property(content, "scale", Vector2.ONE, 0.12)
	var completed := await _run_tween(pulse, playback_generation)
	_echo_trace.clear_connection()
	return completed


func _present_hatch(event: Dictionary, playback_generation: int) -> bool:
	var slot: Button = _belt_slots[event.slot_index]
	var is_double_yolker := bool(event.get("double_yolker", false))
	var score_target: Vector2 = _appetite_display.score_target_global_position()
	_hatch_payoff.begin(
		slot.hatch_global_position(),
		score_target,
		event.points_awarded,
		String(event.get("kind", "chicken")),
		is_double_yolker
	)
	hatch_payoff_started.emit(event.slot_index, event.points_awarded)
	_play(_hatch_player)
	if _reduced_motion:
		slot.clear_visual()
		_commit_score(event)
		_hatch_payoff.reset_effect()
		return true

	var content: Control = slot.motion_content()
	content.pivot_offset = content.size * 0.5
	var anticipation := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	anticipation.tween_property(content, "scale", Vector2(0.88, 1.12), 0.075)
	anticipation.parallel().tween_property(content, "rotation", -0.045, 0.075)
	if not await _run_tween(anticipation, playback_generation):
		return false

	var burst := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	burst.tween_property(content, "scale", Vector2(1.82, 1.52) if is_double_yolker else Vector2(1.52, 1.28), 0.16 if is_double_yolker else 0.13)
	burst.parallel().tween_property(content, "rotation", 0.12, 0.13)
	burst.parallel().tween_property(content, "modulate:a", 0.0, 0.13)
	burst.parallel().tween_property(_hatch_payoff, "burst_progress", 0.66, 0.13)
	if not await _run_tween(burst, playback_generation):
		return false
	slot.clear_visual()

	var travel := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	travel.tween_property(_hatch_payoff, "travel_progress", 1.0, 0.38 if is_double_yolker else 0.30)
	travel.parallel().tween_property(_hatch_payoff, "burst_progress", 1.0, 0.38 if is_double_yolker else 0.30)
	if not await _run_tween(travel, playback_generation):
		return false

	_commit_score(event)
	var appetite_feedback: Control = _appetite_display.feedback_control()
	appetite_feedback.pivot_offset = appetite_feedback.size * 0.5
	var arrival := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	arrival.tween_property(_hatch_payoff, "arrival_progress", 1.0, 0.20)
	arrival.parallel().tween_property(appetite_feedback, "scale", Vector2(1.24, 1.24) if is_double_yolker else Vector2(1.12, 1.12), 0.075)
	arrival.parallel().tween_property(appetite_feedback, "modulate", Color(1.0, 0.88, 0.32, 1.0), 0.075)
	arrival.tween_property(appetite_feedback, "scale", Vector2.ONE, 0.125)
	arrival.parallel().tween_property(appetite_feedback, "modulate", Color.WHITE, 0.125)
	if not await _run_tween(arrival, playback_generation):
		return false
	_hatch_payoff.reset_effect()
	return true


func _commit_score(event: Dictionary) -> void:
	_appetite_display.render_appetite(event.score, event.get("target_score", 15))
	_play(_score_player)
	score_committed.emit(event.points_awarded, event.score)


func _present_swap(event: Dictionary, playback_generation: int) -> bool:
	_play(_shuffle_player)
	if _reduced_motion:
		_render_belt(event.slots)
		return true

	var from_slot: Button = _belt_slots[event.from_slot_index]
	var to_slot: Button = _belt_slots[event.to_slot_index]
	var plover_content: Control = from_slot.motion_content()
	var displaced_content: Control = to_slot.motion_content()
	var has_displaced_egg: bool = not to_slot.current_egg().is_empty()
	var route_step: Vector2 = to_slot.global_position - from_slot.global_position
	var sidestep: Vector2 = route_step.normalized().orthogonal() * 30.0
	var plover_origin := plover_content.position
	var displaced_origin := displaced_content.position
	plover_content.z_index = 4
	plover_content.pivot_offset = plover_content.size * 0.5
	displaced_content.z_index = 2
	displaced_content.pivot_offset = displaced_content.size * 0.5

	var shuffle := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	shuffle.tween_property(plover_content, "position", plover_origin + route_step * 0.48 + sidestep, 0.10)
	shuffle.parallel().tween_property(plover_content, "rotation", -0.10, 0.10)
	if has_displaced_egg:
		shuffle.parallel().tween_property(displaced_content, "position", displaced_origin - route_step * 0.52 - sidestep * 0.3, 0.10)
		shuffle.parallel().tween_property(displaced_content, "rotation", 0.08, 0.10)
	shuffle.tween_property(plover_content, "position", plover_origin + route_step, 0.11).set_trans(Tween.TRANS_BACK)
	shuffle.parallel().tween_property(plover_content, "rotation", 0.0, 0.11)
	if has_displaced_egg:
		shuffle.parallel().tween_property(displaced_content, "position", displaced_origin - route_step, 0.11)
		shuffle.parallel().tween_property(displaced_content, "rotation", 0.0, 0.11)
	if not await _run_tween(shuffle, playback_generation):
		return false
	_render_belt(event.slots)
	return true


func _present_conveyor(event: Dictionary, playback_generation: int) -> bool:
	_play(_belt_player)
	if _reduced_motion:
		_render_belt(event.slots)
		return true

	var move := create_tween().set_parallel(true)
	var has_motion := false
	var active_slot_count: int = mini(event.slots.size(), _belt_slots.size())
	for slot_index in range(active_slot_count):
		var slot: Button = _belt_slots[slot_index]
		if slot.current_egg().is_empty():
			continue
		has_motion = true
		var content: Control = slot.motion_content()
		var route_step := (
			_belt_slots[slot_index + 1].global_position - slot.global_position
			if slot_index < active_slot_count - 1
			else _bin_label.global_position + _bin_label.size * 0.5
				- (slot.global_position + slot.size * 0.5) + Vector2(0.0, 55.0)
		)
		var target := content.position + route_step
		_add_momentum_motion(move, content, content.position, target, 0.20, 0.12)
		if slot_index == active_slot_count - 1:
			move.tween_property(content, "modulate:a", 0.35, 0.20)
	if has_motion and not await _run_tween(move, playback_generation):
		return false
	_render_belt(event.slots)
	return true


func _present_bin(event: Dictionary, playback_generation: int) -> bool:
	_play(_pipe_player)
	_bin_label.text = "BIN %d" % int(event.bin_egg_count)
	if _reduced_motion:
		return true
	_bin_label.pivot_offset = _bin_label.size * 0.5
	var pulse := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pulse.tween_property(_bin_label, "scale", Vector2(1.24, 1.24), 0.08)
	pulse.parallel().tween_property(_bin_label, "modulate", Color(1.0, 0.75, 0.26, 1.0), 0.08)
	pulse.tween_property(_bin_label, "scale", Vector2.ONE, 0.13)
	pulse.parallel().tween_property(_bin_label, "modulate", Color.WHITE, 0.13)
	return await _run_tween(pulse, playback_generation)


func _present_bin_reshuffle(event: Dictionary, playback_generation: int) -> bool:
	_play(_shuffle_player)
	_bin_label.text = "BIN %d" % int(event.bin_egg_count)
	_render_pipe(event.pipe)
	if _reduced_motion:
		return true
	_bin_label.pivot_offset = _bin_label.size * 0.5
	var pulse := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	pulse.tween_property(_bin_label, "modulate", Color(0.4, 0.96, 0.9, 1.0), 0.08)
	pulse.parallel().tween_property(_bin_label, "scale", Vector2(0.88, 0.88), 0.08)
	pulse.tween_property(_bin_label, "modulate", Color.WHITE, 0.13)
	pulse.parallel().tween_property(_bin_label, "scale", Vector2.ONE, 0.13)
	return await _run_tween(pulse, playback_generation)


func _present_pipe_entry(event: Dictionary, playback_generation: int) -> bool:
	_play(_pipe_player)
	if _reduced_motion:
		_belt_slots[0].render_egg(event.egg, false, false)
		_render_pipe(event.pipe)
		return true

	var next_content: Control = _pipe_slots[0].motion_content()
	var next_origin := next_content.position
	var entry_step: Vector2 = (
		_belt_slots[0].hatch_global_position()
		- _pipe_slots[0].hatch_global_position()
	)
	# The lift first raises the queue to belt height. Only after that vertical
	# motion settles does the pusher hand the top egg sideways onto the track.
	var lift := create_tween().set_parallel(true)
	_add_momentum_motion(
		lift,
		next_content,
		next_origin,
		next_origin + Vector2(0.0, entry_step.y),
		0.15,
		0.10,
		1.0
	)
	for preview_index in range(1, _pipe_slots.size()):
		var content: Control = _pipe_slots[preview_index].motion_content()
		if _pipe_slots[preview_index].current_egg().is_empty():
			continue
		var queue_step := (
			_pipe_slots[preview_index - 1].global_position
			- _pipe_slots[preview_index].global_position
		)
		_add_momentum_motion(
			lift,
			content,
			content.position,
			content.position + queue_step,
			0.15,
			0.075,
			-1.0 if preview_index % 2 == 0 else 1.0
		)
	if not await _run_tween(lift, playback_generation):
		return false

	next_content.z_index = 5
	var feed := create_tween().set_parallel(true)
	_add_momentum_motion(
		feed,
		next_content,
		next_content.position,
		next_origin + entry_step,
		0.21,
		0.17
	)
	feed.tween_property(next_content, "modulate:a", 0.22, 0.21)
	if not await _run_tween(feed, playback_generation):
		return false
	_belt_slots[0].render_egg(event.egg, false, false)
	_render_pipe(event.pipe)
	return true


func _add_momentum_motion(
	tween: Tween,
	content: Control,
	origin: Vector2,
	target: Vector2,
	duration: float,
	sway_amount: float,
	fallback_direction := 1.0
) -> void:
	var route := target - origin
	var sway_direction := signf(route.x)
	if is_zero_approx(sway_direction):
		sway_direction = fallback_direction
	var motion := tween.tween_method(
		_apply_momentum_motion.bind(
			content,
			origin,
			target,
			content.rotation,
			sway_amount,
			sway_direction
		),
		0.0,
		1.0,
		duration
	)
	motion.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)


func _apply_momentum_motion(
	progress: float,
	content: Control,
	origin: Vector2,
	target: Vector2,
	origin_rotation: float,
	sway_amount: float,
	sway_direction: float
) -> void:
	if not is_instance_valid(content):
		return
	content.position = origin.lerp(target, progress)
	# Spend the first part of travel in a clear backward lean. During braking,
	# cross upright and wobble around it with rapidly diminishing amplitude.
	var lean_end := 0.58
	var rotation_offset := 0.0
	if progress < lean_end:
		var lean_progress := progress / lean_end
		rotation_offset = (
			-sway_direction * sway_amount * sin(lean_progress * PI)
		)
	else:
		var wobble_progress := (progress - lean_end) / (1.0 - lean_end)
		var damping := 1.0 - wobble_progress
		rotation_offset = (
			sway_direction
			* sway_amount
			* 0.72
			* sin(wobble_progress * TAU * 1.5)
			* damping
		)
	content.rotation = origin_rotation + rotation_offset


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
		var egg: Dictionary = slots[slot_index] if slot_index < slots.size() else {}
		_belt_slots[slot_index].render_egg(egg, false, false)


func _render_pipe(eggs: Array) -> void:
	for preview_index in range(_pipe_slots.size()):
		var egg: Dictionary = eggs[preview_index] if preview_index < eggs.size() else {}
		_pipe_slots[preview_index].render_egg(egg, false, true)


func _clear_all_eggs() -> void:
	for slot: Button in _belt_slots + _pipe_slots:
		slot.clear_visual()
	for circuit_button: Button in _circuit_buttons:
		circuit_button.set_available(false)


func _reset_mechanisms() -> void:
	if is_instance_valid(_echo_trace):
		_echo_trace.clear_connection()
	if is_instance_valid(_hatch_payoff):
		_hatch_payoff.reset_effect()
	if is_instance_valid(_appetite_display):
		var appetite_feedback: Control = _appetite_display.feedback_control()
		appetite_feedback.scale = Vector2.ONE
		appetite_feedback.modulate = Color.WHITE
	for circuit_button: Button in _circuit_buttons:
		if is_instance_valid(circuit_button):
			circuit_button.reset_pose()
	for hammer: Control in _hammers:
		if is_instance_valid(hammer):
			hammer.reset_pose()
	for slot: Button in _belt_slots + _pipe_slots:
		if is_instance_valid(slot):
			slot.reset_motion()


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
