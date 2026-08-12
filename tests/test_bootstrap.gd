extends GutTest


func test_main_scene_can_be_instantiated() -> void:
	var packed_scene := load("res://src/ui/main.tscn") as PackedScene
	assert_not_null(packed_scene)

	var main := packed_scene.instantiate()
	add_child_autofree(main)
	assert_eq(main.name, "Main")
	assert_not_null(main.get_node_or_null("Content/Title"))
