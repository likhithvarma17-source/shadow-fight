extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main_path := ProjectSettings.get_setting("application/run/main_scene", "") as String
	assert(not main_path.is_empty())
	var scene := load(main_path) as PackedScene
	assert(scene != null)
	var instance := scene.instantiate()
	root.add_child(instance)
	await process_frame
	assert(instance != null)
	instance.free()
	var interior_scene := load("res://scenes/interior_level.tscn") as PackedScene
	assert(interior_scene != null)
	var interior = interior_scene.instantiate()
	interior.entrance_transition_duration = 0.0
	interior.auto_boss_scene_change = false
	root.add_child(interior)
	await process_frame
	assert(interior.enemies.size() == interior.TOTAL_INTERIOR_ENEMIES)
	for audio_node in interior.find_children("*", "AudioStreamPlayer", true, false):
		var audio := audio_node as AudioStreamPlayer
		audio.stop()
		audio.stream = null
	await create_timer(0.15).timeout
	interior.free()
	interior = null
	interior_scene = null
	scene = null
	instance = null
	await create_timer(0.20).timeout
	print("[PCK_BOOT_PASS] main scene and vertical interior booted: " + main_path)
	quit(0)
