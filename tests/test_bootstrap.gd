extends GutTest


func test_main_scene_can_be_instantiated() -> void:
	var packed_scene := load("res://src/ui/main.tscn") as PackedScene
	assert_not_null(packed_scene)

	var main := packed_scene.instantiate()
	add_child_autofree(main)
	assert_eq(main.name, "Main")
	assert_null(main.get_node_or_null("Content/Header"))
	assert_not_null(main.get_node_or_null("Content/HUD/GrandmaScorer"))
	assert_not_null(main.get_node_or_null(
		"Content/HUD/GrandmaScorer/Layout/Appetite/Score"
	))
	assert_not_null(main.get_node_or_null("Content/Stage/Belt/BeltCondition"))
	assert_not_null(main.get_node_or_null("Content/Stage/Belt/BeltCondition/BeltConditionBar"))
	var belt_condition = main.get_node("Content/Stage/Belt/BeltCondition")
	assert_eq(belt_condition.get_parent(), main.get_node("Content/Stage/Belt"))
	assert_eq(belt_condition.mount_bolt_count(), 4)
	assert_not_null(main.get_node_or_null("Content/HUD/Settings"))
	assert_not_null(main.get_node_or_null("Content/Stage/Belt/Slots/Slot1"))
	assert_not_null(main.get_node_or_null("Content/Stage/Pipe/Preview/Next1"))
	assert_not_null(main.get_node_or_null("Content/Stage/HammerBank/Hammer1"))
	assert_not_null(main.get_node_or_null("Content/Stage/CircuitBank/RedCircuit"))
	assert_not_null(main.get_node_or_null("Presentation"))
