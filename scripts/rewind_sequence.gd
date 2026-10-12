extends CanvasLayer

signal finished

const REVERSE_BGM_STREAM: AudioStream = preload("res://assets/audio/zero_hour_bgm_reverse.ogg")
const REWIND_NOISE_STREAM: AudioStream = preload("res://assets/audio/rewind_signal_noise.ogg")
const NOISE_SHADER: Shader = preload("res://shaders/rewind_noise.gdshader")
const SAMPLE_INTERVAL := 1.0 / 12.0
const MAX_HISTORY_FRAMES := 2400
const MIN_PLAYBACK_SECONDS := 2.0
const MAX_PLAYBACK_SECONDS := 5.0
const PLAYBACK_SECONDS_PER_SOURCE_SECOND := 3.0 / 160.0
const PLAYBACK_BASE_SECONDS := 1.25
const RESET_COVER_SECONDS := 0.22
const RESET_HOLD_SECONDS := 0.10

var overlay: Control
var wash: ColorRect
var noise: ColorRect
var rewind_group: Control
var death_group: Control
var death_title: Label
var death_rewind_prompt: Label
var death_exit_prompt: Label
var rewind_label: Label
var timecode_label: Label
var reverse_player: AudioStreamPlayer
var noise_player: AudioStreamPlayer
var history: Array[Dictionary] = []
var participants: Array[Node] = []
var sample_accumulator := 0.0
var current_sample_interval := SAMPLE_INTERVAL
var recorded_duration := 0.0
var playback_source_duration := 0.0
var armed := false
var playing := false
var splicing := false
var reset_emitted := false
var playback_elapsed := 0.0
var playback_duration := MIN_PLAYBACK_SECONDS
var splice_elapsed := 0.0
var original_bgm_position := 0.0
var original_bgm_length := 0.0
var rewound_bgm_position := 0.0
var source_bgm: AudioStreamPlayer
var source_rain: AudioStreamPlayer
var last_applied_index := -1
var preview_strength := 0.0

func _ready() -> void:
	layer = 76
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_overlay()
	reverse_player = AudioStreamPlayer.new()
	reverse_player.name = "ReverseBgmPlayer"
	var reverse_stream := REVERSE_BGM_STREAM.duplicate()
	if reverse_stream is AudioStreamOggVorbis:
		reverse_stream.loop = true
	reverse_player.stream = reverse_stream
	add_child(reverse_player)
	noise_player = AudioStreamPlayer.new()
	noise_player.name = "RewindNoisePlayer"
	var noise_stream := REWIND_NOISE_STREAM.duplicate()
	if noise_stream is AudioStreamOggVorbis:
		noise_stream.loop = true
	noise_player.stream = noise_stream
	noise_player.volume_db = -4.5
	add_child(noise_player)
	set_process(true)

func _process(delta: float) -> void:
	if splicing:
		_process_reset_splice(delta)
		return
	if not playing:
		if preview_strength > 0.0:
			_update_overlay(preview_strength)
		return
	playback_elapsed += delta
	var progress := clampf(playback_elapsed / maxf(playback_duration, 0.001), 0.0, 1.0)
	var history_index := clampi(int(round(lerpf(float(history.size() - 1), 0.0, progress))), 0, maxi(0, history.size() - 1))
	if history_index != last_applied_index and not history.is_empty():
		_apply_snapshot(history[history_index])
		last_applied_index = history_index
	_sync_reverse_audio(progress)
	_update_overlay(progress)
	if progress >= 1.0:
		_begin_reset_splice()

func reset_history() -> void:
	if playing or armed:
		cancel(false)
	history.clear()
	participants.clear()
	sample_accumulator = 0.0
	current_sample_interval = SAMPLE_INTERVAL
	recorded_duration = 0.0
	playback_source_duration = 0.0
	last_applied_index = -1

func capture(delta: float, player: Node, actors: Array, projectiles: Array, camera: Camera2D) -> void:
	if playing or armed or splicing or not is_instance_valid(player):
		return
	var elapsed_step := maxf(0.0, delta)
	recorded_duration += elapsed_step
	sample_accumulator += elapsed_step
	if history.is_empty():
		_capture_snapshot(player, actors, projectiles, camera)
	while sample_accumulator >= current_sample_interval:
		sample_accumulator -= current_sample_interval
		_capture_snapshot(player, actors, projectiles, camera)
	_compact_history_if_needed()

func arm_rewind(player: Node, actors: Array, projectiles: Array, camera: Camera2D, bgm: AudioStreamPlayer, rain: AudioStreamPlayer) -> bool:
	if playing or armed or splicing or not is_instance_valid(player):
		return false
	_capture_snapshot(player, actors, projectiles, camera)
	_compact_history_if_needed()
	if history.is_empty():
		return false
	participants.clear()
	for snapshot in history:
		var entries: Array = [snapshot["player"]]
		entries.append_array(snapshot["actors"])
		entries.append_array(snapshot["projectiles"])
		for entry in entries:
			var node = entry.get("node")
			if is_instance_valid(node) and not participants.has(node):
				participants.append(node)
	for node in participants:
		node.set_process(false)
		node.set_physics_process(false)
	armed = true
	preview_strength = 0.0
	playback_elapsed = 0.0
	playback_source_duration = maxf(0.0, float(history.back().get("timeline_time", recorded_duration)) - float(history.front().get("timeline_time", 0.0)))
	playback_duration = calculate_playback_duration(playback_source_duration)
	last_applied_index = history.size() - 1
	overlay.visible = true
	source_bgm = bgm
	source_rain = rain
	original_bgm_position = source_bgm.get_playback_position() if is_instance_valid(source_bgm) else 0.0
	original_bgm_length = source_bgm.stream.get_length() if is_instance_valid(source_bgm) and source_bgm.stream != null else REVERSE_BGM_STREAM.get_length()
	rewound_bgm_position = original_bgm_position
	_pause_forward_audio()
	_apply_snapshot(history[last_applied_index])
	_show_death_choice()
	return true

func start_rewind() -> bool:
	if not armed or playing or history.is_empty():
		return false
	armed = false
	playing = true
	splicing = false
	reset_emitted = false
	playback_elapsed = 0.0
	last_applied_index = history.size() - 1
	death_group.visible = false
	rewind_group.visible = true
	wash.color = Color(0.02, 0.08, 0.10, 0.23)
	_begin_reverse_audio()
	_apply_snapshot(history[last_applied_index])
	_update_overlay(0.0)
	return true

func begin_rewind(player: Node, actors: Array, projectiles: Array, camera: Camera2D, bgm: AudioStreamPlayer, rain: AudioStreamPlayer) -> bool:
	if not arm_rewind(player, actors, projectiles, camera, bgm, rain):
		return false
	return start_rewind()

func is_waiting_for_input() -> bool:
	return armed and not playing

func is_splicing_reset() -> bool:
	return splicing

func calculate_playback_duration(source_seconds: float) -> float:
	return clampf(PLAYBACK_BASE_SECONDS + maxf(0.0, source_seconds) * PLAYBACK_SECONDS_PER_SOURCE_SECOND, MIN_PLAYBACK_SECONDS, MAX_PLAYBACK_SECONDS)

func queue_recorded_nodes_for_cleanup() -> void:
	var recorded_nodes: Array[Node] = []
	for snapshot in history:
		var entries: Array = [snapshot["player"]]
		entries.append_array(snapshot["actors"])
		entries.append_array(snapshot["projectiles"])
		for entry in entries:
			var node = entry.get("node")
			if is_instance_valid(node) and not recorded_nodes.has(node):
				recorded_nodes.append(node)
	for node in recorded_nodes:
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			node.queue_free()

func _show_death_choice() -> void:
	wash.color = Color(0.005, 0.008, 0.012, 0.64)
	death_group.visible = true
	rewind_group.visible = false

func cancel(restore_audio: bool = true) -> void:
	if not playing and not armed and not overlay.visible:
		if restore_audio:
			_restore_forward_audio()
		return
	armed = false
	playing = false
	splicing = false
	reset_emitted = false
	splice_elapsed = 0.0
	preview_strength = 0.0
	overlay.visible = false
	if is_instance_valid(reverse_player):
		reverse_player.stop()
	if is_instance_valid(noise_player):
		noise_player.stop()
	if restore_audio:
		_restore_forward_audio()

func show_preview(progress: float = 0.46) -> void:
	preview_strength = clampf(progress, 0.0, 1.0)
	overlay.visible = true
	death_group.visible = false
	rewind_group.visible = true
	wash.color = Color(0.02, 0.08, 0.10, 0.23)
	_update_overlay(preview_strength)

func show_death_preview() -> void:
	overlay.visible = true
	_show_death_choice()

func hide_preview() -> void:
	preview_strength = 0.0
	if not playing and not armed:
		overlay.visible = false

func _capture_snapshot(player: Node, actors: Array, projectiles: Array, camera: Camera2D) -> void:
	var owner := get_parent()
	var snapshot := {
		"timeline_time": recorded_duration,
		"player": _capture_node(player),
		"actors": [],
		"projectiles": [],
		"owner_state": _capture_owner_state(owner),
		"camera_position": camera.position if is_instance_valid(camera) else Vector2.ZERO,
		"camera_offset": camera.offset if is_instance_valid(camera) else Vector2.ZERO
	}
	for actor in actors:
		if is_instance_valid(actor):
			snapshot["actors"].append(_capture_node(actor))
	for projectile in projectiles:
		if is_instance_valid(projectile):
			snapshot["projectiles"].append(_capture_node(projectile))
	history.append(snapshot)

func _compact_history_if_needed() -> void:
	while history.size() > MAX_HISTORY_FRAMES:
		var previous_history := history
		var compacted: Array[Dictionary] = []
		for index in range(0, previous_history.size(), 2):
			compacted.append(previous_history[index])
		if not previous_history.is_empty() and compacted.back() != previous_history.back():
			compacted.append(previous_history.back())
		history = compacted
		current_sample_interval *= 2.0

func _capture_node(node: Node) -> Dictionary:
	var data := {
		"node": node,
		"id": node.get_instance_id(),
		"position": node.global_position if node is Node2D else Vector2.ZERO,
		"visible": node.visible if node is CanvasItem else true
	}
	for property_name in [
		"velocity", "rotation", "facing", "alive", "animation_clock", "jump_animation_clock",
		"attack_time", "attack_cooldown", "dash_time", "dash_distance_remaining", "death_time",
		"windup", "action_clock", "alert", "state", "state_clock", "ranged_shot_clock",
		"ranged_shots_remaining", "reflected", "life", "health", "focus_energy", "hurt_flash"
	]:
		if property_name in node:
			data[property_name] = node.get(property_name)
	return data

func _capture_owner_state(owner: Node) -> Dictionary:
	var state: Dictionary = {}
	if not is_instance_valid(owner):
		return state
	for property_name in ["elapsed", "kills", "gate_open", "finale_kill_count", "finale_reflected_count"]:
		if property_name in owner:
			state[property_name] = owner.get(property_name)
	return state

func _apply_snapshot(snapshot: Dictionary) -> void:
	var present_ids: Dictionary = {}
	var entries: Array = [snapshot["player"]]
	entries.append_array(snapshot["actors"])
	entries.append_array(snapshot["projectiles"])
	for entry in entries:
		var node = entry.get("node")
		if not is_instance_valid(node):
			continue
		present_ids[int(entry.get("id", 0))] = true
		_apply_node_snapshot(node, entry)
	for node in participants:
		if is_instance_valid(node) and node is CanvasItem and not present_ids.has(node.get_instance_id()):
			node.visible = false
	var owner := get_parent()
	for property_name in snapshot.get("owner_state", {}):
		if is_instance_valid(owner) and property_name in owner:
			owner.set(property_name, snapshot["owner_state"][property_name])
	if is_instance_valid(owner) and "camera" in owner and is_instance_valid(owner.camera):
		owner.camera.position = Vector2(snapshot.get("camera_position", owner.camera.position))
		owner.camera.offset = Vector2(snapshot.get("camera_offset", Vector2.ZERO))

func _apply_node_snapshot(node: Node, data: Dictionary) -> void:
	if node is Node2D:
		node.global_position = Vector2(data.get("position", node.global_position))
	if node is CanvasItem:
		node.visible = bool(data.get("visible", true))
	for property_name in data.keys():
		if property_name in ["node", "id", "position", "visible"]:
			continue
		if property_name in node:
			node.set(property_name, data[property_name])
	if node.has_method("_sync_visual"):
		node.call("_sync_visual")
	elif node.has_method("_sync_rim_light"):
		node.call("_sync_rim_light")
	if node is CanvasItem:
		node.queue_redraw()

func _begin_reverse_audio() -> void:
	original_bgm_position = 0.0
	original_bgm_length = REVERSE_BGM_STREAM.get_length()
	if is_instance_valid(source_bgm):
		original_bgm_position = source_bgm.get_playback_position()
		if source_bgm.stream != null:
			original_bgm_length = source_bgm.stream.get_length()
		reverse_player.volume_db = source_bgm.volume_db + 1.0
	else:
		reverse_player.volume_db = -8.0
	var reverse_length := maxf(REVERSE_BGM_STREAM.get_length(), 0.001)
	var reverse_sync_position := fposmod(original_bgm_position, reverse_length)
	var reverse_start := fposmod(reverse_length - reverse_sync_position, reverse_length)
	rewound_bgm_position = fposmod(original_bgm_position - playback_source_duration + original_bgm_length, maxf(original_bgm_length, 0.001))
	if DisplayServer.get_name() != "headless":
		reverse_player.play(reverse_start)
		noise_player.play(0.0)

func _sync_reverse_audio(progress: float) -> void:
	if DisplayServer.get_name() == "headless" or not is_instance_valid(reverse_player) or not reverse_player.playing:
		return
	var original_length := maxf(original_bgm_length, 0.001)
	var reverse_length := maxf(REVERSE_BGM_STREAM.get_length(), 0.001)
	var original_at_progress := fposmod(original_bgm_position - playback_source_duration * progress + original_length, original_length)
	var reverse_target := fposmod(reverse_length - original_at_progress, reverse_length)
	reverse_player.seek(reverse_target)

func _pause_forward_audio() -> void:
	if is_instance_valid(source_bgm):
		source_bgm.stream_paused = true
	if is_instance_valid(source_rain):
		source_rain.stream_paused = true

func _restore_forward_audio() -> void:
	if is_instance_valid(source_bgm):
		source_bgm.stream_paused = false
		if DisplayServer.get_name() != "headless":
			source_bgm.play(rewound_bgm_position)
	if is_instance_valid(source_rain):
		source_rain.stream_paused = false

func _begin_reset_splice() -> void:
	playing = false
	splicing = true
	reset_emitted = false
	splice_elapsed = 0.0
	if not history.is_empty():
		_apply_snapshot(history[0])
	rewind_label.text = "<<  倒放"
	timecode_label.text = "录像拼接  //  返回起点"

func _process_reset_splice(delta: float) -> void:
	splice_elapsed += maxf(delta, 0.0)
	if not reset_emitted:
		var cover_progress := clampf(splice_elapsed / maxf(RESET_COVER_SECONDS, 0.001), 0.0, 1.0)
		_update_reset_cover(cover_progress)
		if cover_progress >= 1.0:
			reset_emitted = true
			splice_elapsed = 0.0
			reverse_player.stop()
			finished.emit()
		return
	_update_reset_cover(1.0)
	if splice_elapsed >= RESET_HOLD_SECONDS:
		_complete_reset_splice()

func _update_reset_cover(progress: float) -> void:
	overlay.visible = true
	death_group.visible = false
	rewind_group.visible = true
	wash.color = Color(0.0, 0.006, 0.009, lerpf(0.23, 1.0, progress))
	var material := noise.material as ShaderMaterial
	if is_instance_valid(material):
		material.set_shader_parameter("rewind_phase", 1.0 + progress * 0.25)
		material.set_shader_parameter("noise_strength", lerpf(0.72, 1.0, progress))
	rewind_label.modulate.a = 1.0 - smoothstep(0.30, 0.92, progress)
	timecode_label.modulate.a = 1.0 - smoothstep(0.48, 0.96, progress)

func _complete_reset_splice() -> void:
	splicing = false
	reset_emitted = false
	splice_elapsed = 0.0
	overlay.visible = false
	reverse_player.stop()
	noise_player.stop()
	_restore_forward_audio()
	rewind_label.text = "<<  倒放"
	rewind_label.modulate.a = 1.0
	timecode_label.modulate.a = 1.0

func _build_overlay() -> void:
	overlay = Control.new()
	overlay.name = "RewindOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.visible = false
	add_child(overlay)
	wash = ColorRect.new()
	wash.name = "RewindWash"
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wash.color = Color(0.02, 0.08, 0.10, 0.23)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(wash)
	death_group = Control.new()
	death_group.name = "DeathChoice"
	death_group.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	death_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(death_group)
	var death_kicker := Label.new()
	death_kicker.text = "录像停在死亡帧"
	death_kicker.position = Vector2(0.0, 184.0)
	death_kicker.size = Vector2(1280.0, 30.0)
	death_kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	death_kicker.add_theme_font_size_override("font_size", 14)
	death_kicker.add_theme_color_override("font_color", Color("9fb6ba"))
	death_group.add_child(death_kicker)
	death_title = Label.new()
	death_title.name = "DeathTitle"
	death_title.text = "已死亡"
	death_title.position = Vector2(0.0, 222.0)
	death_title.size = Vector2(1280.0, 90.0)
	death_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	death_title.add_theme_font_size_override("font_size", 56)
	death_title.add_theme_color_override("font_color", Color("fff0ed"))
	death_title.add_theme_constant_override("outline_size", 10)
	death_title.add_theme_color_override("font_outline_color", Color(0.16, 0.0, 0.01, 0.98))
	death_group.add_child(death_title)
	var death_rule := ColorRect.new()
	death_rule.position = Vector2(390.0, 326.0)
	death_rule.size = Vector2(500.0, 2.0)
	death_rule.color = Color("a42932")
	death_group.add_child(death_rule)
	death_rewind_prompt = Label.new()
	death_rewind_prompt.name = "DeathRewindPrompt"
	death_rewind_prompt.text = "R  //  倒放"
	death_rewind_prompt.position = Vector2(0.0, 356.0)
	death_rewind_prompt.size = Vector2(1280.0, 42.0)
	death_rewind_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	death_rewind_prompt.add_theme_font_size_override("font_size", 24)
	death_rewind_prompt.add_theme_color_override("font_color", Color("7feaff"))
	death_group.add_child(death_rewind_prompt)
	death_exit_prompt = Label.new()
	death_exit_prompt.name = "DeathExitPrompt"
	death_exit_prompt.text = "ESC  //  返回标题画面"
	death_exit_prompt.position = Vector2(0.0, 408.0)
	death_exit_prompt.size = Vector2(1280.0, 34.0)
	death_exit_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	death_exit_prompt.add_theme_font_size_override("font_size", 17)
	death_exit_prompt.add_theme_color_override("font_color", Color("b6c0c2"))
	death_group.add_child(death_exit_prompt)
	rewind_group = Control.new()
	rewind_group.name = "RewindPlayback"
	rewind_group.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rewind_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(rewind_group)
	noise = ColorRect.new()
	noise.name = "SignalNoise"
	noise.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	noise.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = NOISE_SHADER
	noise.material = material
	rewind_group.add_child(noise)
	var top_rule := ColorRect.new()
	top_rule.position = Vector2(0.0, 88.0)
	top_rule.size = Vector2(1280.0, 2.0)
	top_rule.color = Color(0.72, 0.96, 1.0, 0.54)
	rewind_group.add_child(top_rule)
	rewind_label = Label.new()
	rewind_label.name = "RewindIndicator"
	rewind_label.text = "<<  倒放"
	rewind_label.position = Vector2(0.0, 245.0)
	rewind_label.size = Vector2(1280.0, 92.0)
	rewind_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rewind_label.add_theme_font_size_override("font_size", 48)
	rewind_label.add_theme_color_override("font_color", Color("eaffff"))
	rewind_label.add_theme_constant_override("outline_size", 8)
	rewind_label.add_theme_color_override("font_outline_color", Color(0.0, 0.03, 0.05, 0.95))
	rewind_group.add_child(rewind_label)
	timecode_label = Label.new()
	timecode_label.name = "RewindTimecode"
	timecode_label.position = Vector2(870.0, 101.0)
	timecode_label.size = Vector2(350.0, 30.0)
	timecode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	timecode_label.add_theme_font_size_override("font_size", 15)
	timecode_label.add_theme_color_override("font_color", Color("a9dce2"))
	rewind_group.add_child(timecode_label)
	death_group.visible = false
	rewind_group.visible = false

func _update_overlay(progress: float) -> void:
	if not is_instance_valid(noise):
		return
	var intensity := 0.62 + sin(progress * TAU * 11.0) * 0.18
	var material := noise.material as ShaderMaterial
	material.set_shader_parameter("rewind_phase", progress)
	material.set_shader_parameter("noise_strength", intensity)
	rewind_label.modulate.a = clampf(0.72 + sin(progress * TAU * 17.0) * 0.24, 0.35, 1.0)
	var source_rewound := playback_source_duration * progress
	var playback_remaining := maxf(0.0, playback_duration * (1.0 - progress))
	I18n.set_formatted(timecode_label, "已回退 %05.1f 秒  //  剩余 %04.2f 秒", [source_rewound, playback_remaining])
