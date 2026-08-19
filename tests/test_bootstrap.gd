extends GutTest


func test_main_scene_can_be_instantiated() -> void:
	var main_scene_path := String(ProjectSettings.get_setting("application/run/main_scene"))
	assert_eq(main_scene_path, "res://src/ui/hopper_tap_main.tscn")
	var packed_scene := load(main_scene_path) as PackedScene
	assert_not_null(packed_scene)

	var main := packed_scene.instantiate()
	add_child_autofree(main)
	assert_eq(main.name, "HopperTapGame")
	assert_not_null(main.get_node_or_null("GrandmaSidebar"))
	assert_not_null(main.get_node_or_null("Hopper/Preview/Next1"))
	assert_not_null(main.get_node_or_null("Stage/Bays/Slot1"))
	assert_not_null(main.get_node_or_null("Stage/Spoons/Spoon1"))
	assert_not_null(main.get_node_or_null("Stage/SpoonControls/SpoonButton1"))
	assert_not_null(main.get_node_or_null("TapPresenter"))
