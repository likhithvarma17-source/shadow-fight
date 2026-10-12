class_name ShadowDialogueTypewriter
extends Node

const TYPE_TICK: AudioStream = preload("res://assets/audio/dialogue_type_tick.ogg")
const DEFAULT_CHARS_PER_SECOND := 34.0
const TICK_EVERY_CHARACTERS := 2

var active_label: Label
var active_hint: CanvasItem
var full_text := ""
var visible_characters := 0.0
var typing := false
var advance_requested := false
var cue_count := 0
var _last_tick_character := 0
var _tick_player: AudioStreamPlayer
var characters_per_second := DEFAULT_CHARS_PER_SECOND

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_tick_player = AudioStreamPlayer.new()
	_tick_player.name = "DialogueTypeTick"
	_tick_player.stream = TYPE_TICK
	_tick_player.volume_db = -13.0
	add_child(_tick_player)

func begin_line(label: Label, hint: CanvasItem, text: String, speed: float = DEFAULT_CHARS_PER_SECOND) -> void:
	active_label = label
	active_hint = hint
	full_text = text
	characters_per_second = speed
	visible_characters = 0.0
	_last_tick_character = 0
	advance_requested = false
	typing = true
	active_label.text = full_text
	active_label.visible_characters = 0
	if is_instance_valid(active_hint):
		active_hint.visible = false

func play_line(label: Label, hint: CanvasItem, text: String, speed: float = DEFAULT_CHARS_PER_SECOND, auto_advance: bool = false) -> void:
	begin_line(label, hint, text, speed)
	if auto_advance:
		_finish_typing()
		advance_requested = false
		return
	while typing and is_instance_valid(active_label):
		if advance_requested:
			advance_requested = false
			_finish_typing()
			break
		visible_characters += characters_per_second * get_process_delta_time()
		var next_visible := mini(active_label.get_total_character_count(), int(visible_characters))
		if next_visible != active_label.visible_characters:
			active_label.visible_characters = next_visible
			_maybe_play_tick(next_visible)
		if next_visible >= active_label.get_total_character_count():
			_finish_typing()
			break
		await get_tree().process_frame
	advance_requested = false
	while not advance_requested and is_instance_valid(active_label):
		await get_tree().process_frame
	advance_requested = false

func request_advance() -> void:
	advance_requested = true

func reveal_immediately() -> void:
	if typing:
		_finish_typing()

func reset() -> void:
	typing = false
	advance_requested = false
	full_text = ""
	visible_characters = 0.0
	active_label = null
	if is_instance_valid(active_hint):
		active_hint.visible = false
	active_hint = null
	if is_instance_valid(_tick_player):
		_tick_player.stop()

func _finish_typing() -> void:
	typing = false
	if is_instance_valid(active_label):
		active_label.visible_characters = -1
	if is_instance_valid(active_hint):
		active_hint.visible = true

func _maybe_play_tick(character_count: int) -> void:
	if character_count <= 0 or character_count - _last_tick_character < TICK_EVERY_CHARACTERS:
		return
	_last_tick_character = character_count
	var visible_text := String(TranslationServer.translate(full_text)).left(character_count)
	var last_character := visible_text.right(1)
	if last_character in [" ", "\n", "，", "。", "！", "？", "…", ".", ",", "!", "?"]:
		return
	cue_count += 1
	if DisplayServer.get_name() == "headless" or not is_instance_valid(_tick_player):
		return
	_tick_player.pitch_scale = 0.96 + float(cue_count % 5) * 0.018
	_tick_player.play()
