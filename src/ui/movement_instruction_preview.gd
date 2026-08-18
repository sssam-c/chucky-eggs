class_name MovementInstructionPreview
extends PanelContainer

@onready var _title: Label = %Title
@onready var _sequence: Label = %Sequence
@onready var _status: Label = %Status


func _ready() -> void:
	clear_preview()


func clear_preview() -> void:
	_title.text = "BELT INSTRUCTIONS"
	_sequence.text = "—"
	_status.text = "FOCUS A LEVER TO PREVIEW"
	accessibility_name = "Belt instruction preview"
	accessibility_description = "Focus a lever to preview its belt instructions."


func render_preview(preview: Dictionary) -> void:
	if preview.is_empty():
		clear_preview()
		return
	_title.text = "%s LEVER  •  LEFT → RIGHT" % String(
		preview.get("circuit_id", "")
	).to_upper()
	var instructions: Array[Dictionary] = []
	instructions.assign(preview.get("instructions", []))
	var outcomes: Array[String] = []
	outcomes.assign(preview.get("outcomes", []))
	var tokens: PackedStringArray = []
	var status_parts: PackedStringArray = []
	var active_jam_source := ""
	for instruction_index in range(instructions.size()):
		var instruction: Dictionary = instructions[instruction_index]
		var instruction_type := String(instruction.type)
		var outcome := outcomes[instruction_index]
		var token := _token(instruction_type)
		if outcome == "blocked":
			token = "×%s" % token
			status_parts.append("%s BLOCKS %s" % [
				active_jam_source.to_upper(),
				_source_label(String(instruction.source)).to_upper(),
			])
		elif instruction_type == "jam":
			active_jam_source = _source_label(String(instruction.source))
		tokens.append(token)
	_sequence.text = "  ".join(tokens)
	if int(preview.get("unused_jams", 0)) > 0:
		status_parts.append("%d JAM EXPIRES" % int(preview.unused_jams))
	_status.text = " • ".join(status_parts) if not status_parts.is_empty() else "ALL MOVEMENTS EXECUTE"
	accessibility_name = "%s belt instruction preview" % String(preview.circuit_id).capitalize()
	accessibility_description = "Instructions resolve left to right: %s. %s." % [
		_sequence.text, _status.text.capitalize(),
	]


func sequence_text() -> String:
	return _sequence.text


func status_text() -> String:
	return _status.text


func show_jam_count(count: int) -> void:
	_status.text = "GLOOPY JAM ×%d ARMED" % count


func show_cancellation(source: String, remaining_jams: int) -> void:
	_status.text = "GLOOPY BLOCKS %s  •  %d JAM LEFT" % [
		_source_label(source).to_upper(), remaining_jams,
	]


func show_expiry(count: int) -> void:
	_status.text = "%d UNUSED JAM %s" % [count, "EXPIRES" if count == 1 else "EXPIRE"]


func _token(instruction_type: String) -> String:
	match instruction_type:
		"forward":
			return "▶"
		"reverse":
			return "◀"
		"jam":
			return "⚙"
	return "?"


func _source_label(source: String) -> String:
	return "standard movement" if source == "normal" else source
