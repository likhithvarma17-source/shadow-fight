extends "res://scripts/game.gd"

const InteriorArt = preload("res://scripts/interior_art.gd")
const DialogueTypewriter = preload("res://scripts/dialogue_typewriter.gd")

const INTERIOR_WIDTH := 1280.0
const INTERIOR_HEIGHT := 3475.0
const INTERIOR_FLOOR_Y: Array[float] = [3350.0, 2650.0, 1950.0, 1250.0, 550.0]
const PLAYER_START := Vector2(145.0, 3349.0)
const EXIT_TRIGGER := Vector2(1110.0, 549.0)
const TOTAL_INTERIOR_ENEMIES := 14

var floor_groups: Array[Array] = []
var floor_alerted: Array[bool] = []
var floor_chatter_started: Array[bool] = []
var active_floor_index := -1
var interior_dialogue_active := false
var dialogue_typewriter: Node
var active_dialogue_bubble: Label
var active_dialogue_hint: Label
var active_dialogue_target: Node
var auto_advance_dialogue := false
var skip_floor_dialogue := false
var ambient_dialogue_generation := 0

func _ready() -> void:
	super._ready()
	dialogue_typewriter = DialogueTypewriter.new()
	dialogue_typewriter.name = "InteriorDialogueTypewriter"
	add_child(dialogue_typewriter)
	objective_label.text = "第二关  //  从底层向上突破"
	hint_label.text = "敌人尚未警觉  •  利用局促空间突进与弹反"

func _build_background() -> void:
	world_art = InteriorArt.new()
	world_art.name = "AkaiHideoutInterior"
	add_child(world_art)

func _build_world() -> void:
	platforms.clear()
	for floor_y in INTERIOR_FLOOR_Y:
		_add_platform(Rect2(0.0, floor_y, INTERIOR_WIDTH, 48.0))
	for platform_rect in [
		Rect2(930.0, 3175.0, 260.0, 30.0), Rect2(650.0, 3000.0, 250.0, 30.0), Rect2(350.0, 2825.0, 250.0, 30.0),
		Rect2(90.0, 2475.0, 260.0, 30.0), Rect2(390.0, 2300.0, 250.0, 30.0), Rect2(690.0, 2125.0, 260.0, 30.0),
		Rect2(930.0, 1775.0, 260.0, 30.0), Rect2(650.0, 1600.0, 250.0, 30.0), Rect2(350.0, 1425.0, 250.0, 30.0),
		Rect2(90.0, 1075.0, 260.0, 30.0), Rect2(390.0, 900.0, 250.0, 30.0), Rect2(690.0, 725.0, 260.0, 30.0)
	]:
		_add_platform(platform_rect)
	_add_wall(Rect2(-30.0, 0.0, 30.0, INTERIOR_HEIGHT))
	_add_wall(Rect2(INTERIOR_WIDTH, 0.0, 30.0, INTERIOR_HEIGHT))
	_add_wall(Rect2(0.0, INTERIOR_HEIGHT, INTERIOR_WIDTH, 40.0))
	environment_art = world_art
	world_art.set_platforms(platforms)

func _init_rain() -> void:
	rain_drops.clear()
	rain_splashes.clear()

func _update_rain(_delta: float, _time_scale: float) -> void:
	pass

func _update_storm(_delta: float) -> void:
	pass

func _apply_camera_distance() -> void:
	if not is_instance_valid(camera):
		return
	var zoom_value := 1.0 + TuningStore.get_value("parry_zoom_amount") * _parry_zoom_weight()
	camera.zoom = Vector2(zoom_value, zoom_value)

func _start_room() -> void:
	if is_instance_valid(rewind_sequence):
		rewind_sequence.reset_history()
	_reset_parry_feedback()
	state = RunState.PLAYING
	gate_open = false
	boss_transition_requested = false
	_clear_all_enemy_barks()
	elapsed = 0.0
	kills = 0
	floor_groups.clear()
	floor_alerted = []
	floor_chatter_started = []
	for _floor_index in range(INTERIOR_FLOOR_Y.size()):
		floor_alerted.append(false)
		floor_chatter_started.append(false)
	active_floor_index = -1
	interior_dialogue_active = false
	ambient_dialogue_generation += 1
	status_label.text = "潜入中  //  尚未暴露"
	objective_label.text = "第二关  //  从底层向上突破"
	hint_label.text = "敌人尚未警觉  •  利用局促空间突进与弹反"
	_spawn_player()
	player.position = PLAYER_START
	player.set_drop_through_floor_y(INTERIOR_FLOOR_Y[0] - 8.0)
	_spawn_interior_group(0, [
		{"kind": "blade", "x": 720.0},
		{"kind": "gunner", "x": 1060.0, "y": 3174.0, "patrol": 90.0},
	])
	_spawn_interior_group(1, [
		{"kind": "blade", "x": 560.0},
		{"kind": "blade", "x": 860.0},
		{"kind": "gunner", "x": 220.0, "y": 2474.0, "patrol": 90.0},
	])
	_spawn_interior_group(2, [
		{"kind": "blade", "x": 350.0},
		{"kind": "gunner", "x": 760.0, "y": 2124.0, "patrol": 95.0},
		{"kind": "gunner", "x": 1060.0},
	])
	_spawn_interior_group(3, [
		{"kind": "gunner", "x": 1060.0, "y": 1774.0, "patrol": 95.0},
		{"kind": "blade", "x": 590.0},
		{"kind": "gunner", "x": 980.0},
	])
	_spawn_interior_group(4, [
		{"kind": "blade", "x": 330.0},
		{"kind": "gunner", "x": 520.0, "y": 899.0, "patrol": 95.0},
		{"kind": "gunner", "x": 1010.0},
	])
	if is_instance_valid(world_art):
		world_art.alerted_floors.clear()
		world_art.set_exit_open(false)
	_capture_rewind_frame(0.0)

func _spawn_interior_group(floor_index: int, members: Array) -> void:
	while floor_groups.size() <= floor_index:
		floor_groups.append([])
	var floor_y := INTERIOR_FLOOR_Y[floor_index] - 1.0
	for member_index in range(members.size()):
		var member: Dictionary = members[member_index]
		var x := float(member["x"])
		var y := float(member.get("y", floor_y))
		var patrol_half_width := float(member.get("patrol", 65.0))
		_spawn_enemy(String(member["kind"]), Vector2(x, y), x - patrol_half_width, x + patrol_half_width)
		var enemy: Node = enemies[-1]
		enemy.remove_meta("story_bark")
		enemy.set_meta("interior_floor", floor_index)
		enemy.set_meta("interior_member", member_index)
		enemy.set_resting(true, -1.0 if member_index % 2 == 0 else 1.0)
		floor_groups[floor_index].append(enemy)

func _process(delta: float) -> void:
	super._process(delta)
	if state != RunState.PLAYING or not is_instance_valid(player):
		return
	_update_visible_floor_chatter()
	_update_floor_triggers()
	if gate_open:
		objective_label.text = "顶层已肃清  //  穿过橙色闸门"
		if player.global_position.y <= EXIT_TRIGGER.y + 50.0 and player.global_position.x >= EXIT_TRIGGER.x:
			_complete_run()

func _update_floor_triggers() -> void:
	if interior_dialogue_active or state != RunState.PLAYING:
		return
	var next_floor := -1
	if not floor_alerted[0] and player.global_position.x >= 390.0 and player.global_position.y > INTERIOR_FLOOR_Y[0] - 300.0:
		next_floor = 0
	else:
		for floor_index in range(1, INTERIOR_FLOOR_Y.size()):
			if floor_alerted[floor_index] or not floor_alerted[floor_index - 1]:
				continue
			if player.global_position.y <= INTERIOR_FLOOR_Y[floor_index] + 110.0:
				next_floor = floor_index
				break
	if next_floor >= 0:
		floor_alerted[next_floor] = true
		active_floor_index = next_floor
		call_deferred("_run_floor_wakeup", next_floor)

func _run_floor_wakeup(floor_index: int) -> void:
	if interior_dialogue_active or state != RunState.PLAYING:
		return
	if floor_index > 0:
		_activate_floor_group(floor_index)
		return
	interior_dialogue_active = true
	player.set_control_enabled(false)
	player.set_forced_idle_visual(true)
	_set_combat_simulation(false)
	status_label.visible = false
	I18n.set_formatted(status_label, "第 %d 层  //  敌人尚未警觉", (floor_index + 1))
	if skip_floor_dialogue:
		auto_advance_dialogue = true
	await _play_interior_scene("interior_floor_%d" % (floor_index + 1), floor_index)
	_activate_floor_group(floor_index)
	interior_dialogue_active = false
	player.set_forced_idle_visual(false)
	player.set_control_enabled(true)
	_set_combat_simulation(true)

func _activate_floor_group(floor_index: int) -> void:
	for enemy in floor_groups[floor_index]:
		if is_instance_valid(enemy) and enemy.alive:
			enemy.set_resting(false)
			enemy.alert = 0.72
			enemy.action_clock = 0.18 + float(enemy.get_meta("interior_member", 0)) * 0.12
	if is_instance_valid(world_art):
		world_art.set_floor_alerted(floor_index)
	status_label.visible = true
	I18n.set_formatted(status_label, "第 %d 层  //  警报", (floor_index + 1))
	_status_flash(Color("ff5b50"))

func _play_ambient_floor_dialogue(floor_index: int, generation: int) -> void:
	for entry in StoryStore.get_scene("interior_floor_%d" % (floor_index + 1)):
		if generation != ambient_dialogue_generation or state != RunState.PLAYING:
			return
		var target := _resolve_floor_target(floor_index, String(entry.get("target", "")))
		if not is_instance_valid(target) or not target.alive:
			continue
		_show_ambient_npc_bubble(target, entry)
		await get_tree().create_timer(minf(0.65, maxf(0.30, float(entry.get("duration", 2.4)) * 0.25))).timeout

func _update_visible_floor_chatter() -> void:
	if interior_dialogue_active or not is_instance_valid(camera):
		return
	var visible_size := get_camera_visible_world_size()
	var visible_rect := Rect2(camera.position - visible_size * 0.5, visible_size)
	for floor_index in range(1, floor_groups.size()):
		if floor_chatter_started[floor_index] or not floor_alerted[floor_index - 1]:
			continue
		for enemy in floor_groups[floor_index]:
			if is_instance_valid(enemy) and enemy.alive and visible_rect.has_point(enemy.global_position + Vector2(0.0, -48.0)):
				floor_chatter_started[floor_index] = true
				status_label.visible = true
				I18n.set_formatted(status_label, "第 %d 层  //  尚未警觉", (floor_index + 1))
				call_deferred("_play_ambient_floor_dialogue", floor_index, ambient_dialogue_generation)
				break

func _show_ambient_npc_bubble(target: Node, entry: Dictionary) -> void:
	_clear_enemy_bark(target)
	var bubble := Label.new()
	bubble.name = "AmbientNpcDialogue"
	bubble.text = String(entry.get("text", ""))
	bubble.position = Vector2(-150.0, -264.0)
	bubble.size = Vector2(300.0, 100.0)
	bubble.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bubble.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble.add_theme_font_size_override("font_size", 16)
	bubble.add_theme_color_override("font_color", Color("f6f8f7"))
	bubble.add_theme_constant_override("outline_size", 6)
	bubble.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.96))
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	target.add_child(bubble)
	enemy_bark_bubbles[target] = {
		"label": bubble,
		"remaining": maxf(0.45, float(entry.get("duration", 2.4)))
	}

func _play_interior_scene(scene_id: String, floor_index: int) -> void:
	for entry in StoryStore.get_scene(scene_id):
		var target := _resolve_floor_target(floor_index, String(entry.get("target", "")))
		if not is_instance_valid(target):
			continue
		_show_interior_bubble(target, entry)
		await dialogue_typewriter.play_line(
			active_dialogue_bubble,
			active_dialogue_hint,
			active_dialogue_bubble.text,
			34.0,
			auto_advance_dialogue
		)
		_clear_interior_bubble()

func _resolve_floor_target(floor_index: int, target_id: String) -> Node:
	if target_id == "player":
		return player
	if not target_id.begins_with("member_") or floor_index < 0 or floor_index >= floor_groups.size():
		return null
	var member_index := int(target_id.trim_prefix("member_"))
	if member_index < 0 or member_index >= floor_groups[floor_index].size():
		return null
	return floor_groups[floor_index][member_index]

func _show_interior_bubble(target: Node, entry: Dictionary) -> void:
	_clear_interior_bubble()
	active_dialogue_target = target
	active_dialogue_bubble = Label.new()
	active_dialogue_bubble.name = "InteriorDialogue"
	var speaker := String(entry.get("speaker", ""))
	active_dialogue_bubble.text = (speaker + "\n" if not speaker.is_empty() else "") + String(entry.get("text", ""))
	active_dialogue_bubble.position = Vector2(-190.0, -300.0)
	active_dialogue_bubble.size = Vector2(380.0, 128.0)
	active_dialogue_bubble.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	active_dialogue_bubble.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	active_dialogue_bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	active_dialogue_bubble.add_theme_font_size_override("font_size", 17)
	active_dialogue_bubble.add_theme_color_override("font_color", Color("f4f7f5"))
	active_dialogue_bubble.add_theme_constant_override("outline_size", 6)
	active_dialogue_bubble.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.98))
	active_dialogue_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	target.add_child(active_dialogue_bubble)
	active_dialogue_hint = Label.new()
	active_dialogue_hint.name = "InteriorDialogueAdvanceHint"
	active_dialogue_hint.text = "J  //  继续"
	active_dialogue_hint.position = Vector2(-90.0, -170.0)
	active_dialogue_hint.size = Vector2(180.0, 24.0)
	active_dialogue_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	active_dialogue_hint.add_theme_font_size_override("font_size", 12)
	active_dialogue_hint.add_theme_color_override("font_color", Color("80d6d0"))
	active_dialogue_hint.add_theme_constant_override("outline_size", 5)
	active_dialogue_hint.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.98))
	active_dialogue_hint.visible = false
	active_dialogue_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	target.add_child(active_dialogue_hint)

func _clear_interior_bubble() -> void:
	if is_instance_valid(dialogue_typewriter):
		dialogue_typewriter.reset()
	if is_instance_valid(active_dialogue_bubble):
		active_dialogue_bubble.queue_free()
	if is_instance_valid(active_dialogue_hint):
		active_dialogue_hint.queue_free()
	active_dialogue_bubble = null
	active_dialogue_hint = null
	active_dialogue_target = null

func _set_combat_simulation(enabled: bool) -> void:
	if is_instance_valid(player):
		player.set_physics_process(enabled)
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.set_physics_process(enabled)
	for shot in projectiles:
		if is_instance_valid(shot):
			shot.set_process(enabled)

func _update_camera() -> void:
	if not is_instance_valid(camera) or not is_instance_valid(player):
		return
	var half_height := get_camera_visible_world_size().y * 0.5
	camera.position.x = INTERIOR_WIDTH * 0.5
	camera.position.y = clampf(player.global_position.y - 105.0, half_height, INTERIOR_HEIGHT - half_height)

func _projectile_world_bounds() -> Rect2:
	return Rect2(-100.0, -100.0, INTERIOR_WIDTH + 200.0, INTERIOR_HEIGHT + 200.0)

func _on_viewport_changed() -> void:
	if is_instance_valid(camera):
		camera.limit_left = 0
		camera.limit_right = int(INTERIOR_WIDTH)
		camera.limit_top = 0
		camera.limit_bottom = int(INTERIOR_HEIGHT)
	if hint_label:
		hint_label.visible = get_viewport_rect().size.x >= 1000.0

func _update_hud() -> void:
	super._update_hud()
	if not is_instance_valid(player):
		return
	var floor_number := 1
	for floor_index in range(1, INTERIOR_FLOOR_Y.size()):
		var midpoint := (INTERIOR_FLOOR_Y[floor_index - 1] + INTERIOR_FLOOR_Y[floor_index]) * 0.5
		if player.global_position.y <= midpoint:
			floor_number = floor_index + 1
	I18n.set_formatted(enemies_label, "第 %d 层  //  敌人 %02d", [floor_number, _living_enemy_count()])

func _complete_run() -> void:
	if state != RunState.PLAYING:
		return
	_reset_parry_feedback()
	_apply_camera_distance()
	state = RunState.COMPLETE
	player.set_control_enabled(false)
	player.set_forced_idle_visual(true)
	status_label.text = "据点突破  //  守门人在上层"
	boss_transition_requested = true
	if auto_boss_scene_change:
		call_deferred("_enter_boss_battle")

func _enter_boss_battle() -> void:
	boss_transition_requested = false
	get_tree().change_scene_to_file("res://scenes/boss_battle.tscn")

func _update_audio_tuning() -> void:
	super._update_audio_tuning()
	if is_instance_valid(rain_audio_player):
		rain_audio_player.volume_db = minf(rain_audio_player.volume_db, -24.0)

func _unhandled_input(event: InputEvent) -> void:
	if not interior_dialogue_active:
		return
	if event is InputEventKey and not event.echo and event.pressed and (event.keycode == KEY_J or event.physical_keycode == KEY_J):
		if is_instance_valid(dialogue_typewriter):
			dialogue_typewriter.request_advance()
		get_viewport().set_input_as_handled()
